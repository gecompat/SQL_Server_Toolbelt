[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
    [string]$Patch='base',
    [Parameter(Mandatory)][ValidateSet('local','central')][string]$Mode,
    [Parameter(Mandatory)][ValidateSet(150,160,170)][int]$CompatibilityLevel,
    [Parameter(Mandatory)][string]$JournalDirectory,
    [Parameter(Mandatory)][string]$ExpectedTargetKey,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
    [string]$SsisReleaseDirectory,
    [string]$ParserReleaseDirectory,
    [string]$InstallationPackageRoot,
    [string]$SsisPredecessorReleaseDirectory,
    [switch]$ExtendedExpressions,
    [switch]$ComponentsOnly,
    [switch]$FocusedVariablePlans,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$CasesExpectedSha256,
    [string]$InputManifestPath,
    [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedInputManifestSha256,
    [ValidateSet('Latin1_General_100_BIN2','Latin1_General_100_CS_AS','Latin1_General_100_CI_AS_SC_UTF8')][string]$DatabaseCollation='Latin1_General_100_BIN2',
    [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'SSIS_V2_POWERSHELL_7_REQUIRED'}
if($FocusedVariablePlans -and -not $ComponentsOnly){throw 'SSIS_V2_FOCUSED_VARIABLE_REQUIRES_COMPONENTS_ONLY'}
if($InstallationPackageRoot){
    if($SsisReleaseDirectory -or $ParserReleaseDirectory){throw 'SSIS_V2_PACKAGE_EXTERNAL_RELEASE_FORBIDDEN'}
}elseif(-not $SsisReleaseDirectory -or -not $ParserReleaseDirectory){throw 'SSIS_V2_RELEASE_DIRECTORIES_REQUIRED'}
# Preserve the previously qualified harness and its historical source pins.
# Only the extra case invocation is inserted inside its existing owned-database
# try/finally. Discovery, trust, configuration, deadlines and cleanup are reused.
$original=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
$cases=Join-Path $PSScriptRoot 'Invoke-ComponentsV2Cases.ps1'
if((Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){
    throw 'SSIS_V2_ORIGINAL_HARNESS_CHANGED'
}
if((Get-FileHash -LiteralPath $cases -Algorithm SHA256).Hash -cne $CasesExpectedSha256){throw 'SSIS_V2_CASES_CHANGED'}
if($InputManifestPath){
    if(-not $ExpectedInputManifestSha256 -or (Get-FileHash -LiteralPath $InputManifestPath -Algorithm SHA256).Hash -cne $ExpectedInputManifestSha256){throw 'SSIS_V2_INPUT_MANIFEST_CHANGED'}
    $inputManifest=Get-Content -LiteralPath $InputManifestPath -Raw | ConvertFrom-Json -Depth 16
    if($inputManifest.schemaVersion -ne 1 -or $inputManifest.profile -cne 'ssis-debug-components-v2' -or -not $inputManifest.files.Count){throw 'SSIS_V2_INPUT_MANIFEST_SCHEMA'}
    $repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($entry in $inputManifest.files){
        if([string]$entry.sha256 -cnotmatch '^[0-9A-F]{64}$'){throw 'SSIS_V2_INPUT_HASH_FORMAT'}
        $file=[IO.Path]::GetFullPath((Join-Path $repository ([string]$entry.path)))
        if(-not $file.StartsWith($repository+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($file)){throw 'SSIS_V2_INPUT_PATH'}
        if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne [string]$entry.sha256){throw 'SSIS_V2_EXECUTION_INPUT_CHANGED'}
    }
    foreach($required in @($PSCommandPath,$original,$cases)){
        if(-not $seen.Contains([IO.Path]::GetFullPath($required))){throw 'SSIS_V2_INPUT_REQUIRED_FILE_MISSING'}
    }
}elseif(-not $ValidateOnly){throw 'SSIS_V2_INPUT_MANIFEST_REQUIRED'}
$caseErrors=$null
[void][Management.Automation.Language.Parser]::ParseFile($cases,[ref]$null,[ref]$caseErrors)
if($caseErrors.Count){throw 'SSIS_V2_CASES_SYNTAX'}
function Bind-ComponentsV2ScriptRoot([string]$Text,[string]$Root){
    # A newly created scriptblock has an empty automatic PSScriptRoot. Bind
    # only actual variable AST nodes, never textual lookalikes or SQL content.
    $parseErrors=$null
    $tree=[Management.Automation.Language.Parser]::ParseInput($Text,[ref]$null,[ref]$parseErrors)
    if($parseErrors.Count){throw 'SSIS_V2_ROOT_BIND_SYNTAX'}
    $variables=@($tree.FindAll({param($node)$node -is [Management.Automation.Language.VariableExpressionAst] -and $node.VariablePath.UserPath -ceq 'PSScriptRoot'},$true) | Sort-Object {$_.Extent.StartOffset} -Descending)
    if(-not $variables.Count){throw 'SSIS_V2_ROOT_BIND_MISSING'}
    $literal="'"+$Root.Replace("'","''")+"'"
    foreach($variable in $variables){
        $Text=$Text.Substring(0,$variable.Extent.StartOffset)+$literal+$Text.Substring($variable.Extent.EndOffset)
    }
    return $Text
}
$text=[IO.File]::ReadAllText($original)
$anchor="    `$phase=`$mode+'-api'; & (Join-Path `$PSScriptRoot 'Invoke-ApiCases.ps1') -Connection `$connection"
if(([regex]::Matches($text,[regex]::Escape($anchor))).Count -ne 1){throw 'SSIS_V2_CASE_HOOK_NOT_UNIQUE'}
$insertion=$anchor+"`n    `$phase=`$mode+'-components-v2'; & (Join-Path `$PSScriptRoot 'Invoke-ComponentsV2Cases.ps1') -Connection `$connection -CrossDatabase `$clientDatabase -FixtureModuleRoot `$moduleRoot"
if($ExtendedExpressions -or $FocusedVariablePlans){$insertion+=' -ExtendedExpressions'}
if($FocusedVariablePlans){$insertion+=' -FocusedVariablePlans'}
$adapted=$text.Replace($anchor,$insertion)
if($ComponentsOnly){
    # Focused development retries have separate evidence; they cannot stand in
    # for the full legacy baseline in the final native qualification matrix.
    foreach($line in @($text -split "`n" | Where-Object {
        $_ -match 'Invoke-(CoreContract|ApiCases|ReleaseRightsCases|LifecycleCases)\.ps1'
    })){
        if(([regex]::Matches($adapted,[regex]::Escape($line))).Count -ne 1){throw 'SSIS_V2_FOCUSED_HOOK_NOT_UNIQUE'}
        $adapted=$adapted.Replace($line,'')
    }
    Write-Output 'SSIS_V2_COMPONENTS_ONLY; legacy baseline not executed'
}
if($InstallationPackageRoot){
    $packageAnchor="`$package.packageName -cne 'SSIS-Debug-1.0.0-Install-Windows'"
    if(([regex]::Matches($adapted,[regex]::Escape($packageAnchor))).Count -ne 1){throw 'SSIS_V2_PACKAGE_HOOK_NOT_UNIQUE'}
    $adapted=$adapted.Replace($packageAnchor,"`$package.packageName -cne 'SSIS-Debug-ComponentsV2-1.0.0-Install-Windows'")
    $packageCases=Join-Path $InstallationPackageRoot 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-ComponentsV2Cases.ps1'
    if((Get-FileHash -LiteralPath $packageCases -Algorithm SHA256).Hash -cne $CasesExpectedSha256){throw 'SSIS_V2_PACKAGE_CASES_CHANGED'}
}
if($SsisPredecessorReleaseDirectory){
    # The frozen legacy harness predates the last shipped Lookup-role build.
    # Extend its exact predecessor pin only from that immutable native record;
    # self-consistent caller-supplied manifests are insufficient authority.
    $repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
    $recordPath=Join-Path $repository 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/LookupRoles.Windows.CL.20261025.json'
    if((Get-FileHash -LiteralPath $recordPath -Algorithm SHA256).Hash -cne 'B6D88F62AFBBA738E7EF758EC171482B129675E6DDB51C1B351EA5592966F254'){throw 'SSIS_V2_PREDECESSOR_RECORD_CHANGED'}
    $record=Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    $oldBinary=Join-Path $SsisPredecessorReleaseDirectory 'Toolbelt.Tsql.SsisDebug.dll'
    if($record.result -cne 'PASS' -or $record.publication_authorized -ne $false -or
       $record.product_source_commit -cne 'd228163a945678044032d3868dd11425f5f6a457' -or
       (Get-FileHash -LiteralPath $oldBinary -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.qualified_assembly_sha256 -or
       (Get-FileHash -LiteralPath (Join-Path $SsisPredecessorReleaseDirectory 'Deploy.WithAssembly.sql') -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.qualified_deploy_sql_sha256 -or
       (Get-FileHash -LiteralPath (Join-Path $SsisPredecessorReleaseDirectory 'Toolbelt.Tsql.SsisDebug.trust-manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.qualified_release_manifest_sha256){throw 'SSIS_V2_PREDECESSOR_NOT_ORIGINALLY_QUALIFIED'}
    $oldAnchor="`$oldQualified='84BA992E7482B644B5EE8B4EBBC1AFF537CD690A9D3D4366A0B037FE10E5BD3AD40352DC16C7D643B5180185D011E83AD7411EF359CB3FFC3F75E046B46E66FC'"
    if(([regex]::Matches($adapted,[regex]::Escape($oldAnchor))).Count -ne 1){throw 'SSIS_V2_PREDECESSOR_PIN_HOOK_NOT_UNIQUE'}
    $adapted=$adapted.Replace($oldAnchor,"`$oldQualified='"+(Get-FileHash -LiteralPath $oldBinary -Algorithm SHA512).Hash+"'")
}
$adapted=Bind-ComponentsV2ScriptRoot -Text $adapted -Root $PSScriptRoot
$errors=$null
[void][Management.Automation.Language.Parser]::ParseInput($adapted,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_V2_ADAPTED_HARNESS_SYNTAX'}
if($ValidateOnly){'SSIS_V2_LAB_ADAPTER_VALIDATED; no SQL';return}
$invoke=@{
    Version=$Version;Patch=$Patch;Modes=@($Mode);CompatibilityLevel=$CompatibilityLevel
    Full=$true;ReleaseRights=$true;JournalDirectory=$JournalDirectory;ExpectedTargetKey=$ExpectedTargetKey
    ExpectedContractSha256=$ExpectedContractSha256;SsisReleaseDirectory=$SsisReleaseDirectory
    ParserReleaseDirectory=$ParserReleaseDirectory;QualifiedProviderSha512=$QualifiedProviderSha512
    DatabaseCollation=$DatabaseCollation;InstallationPackageRoot=$InstallationPackageRoot
    SsisPredecessorReleaseDirectory=$SsisPredecessorReleaseDirectory
}
& ([scriptblock]::Create($adapted)) @invoke
