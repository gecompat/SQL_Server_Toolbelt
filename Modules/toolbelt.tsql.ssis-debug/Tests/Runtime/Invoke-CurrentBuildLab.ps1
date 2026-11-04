#Requires -Version 7.5
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('Run','Audit')][string]$Action,
 [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
 [Parameter(Mandatory)][ValidatePattern('^CU[0-9]+$')][string]$Patch,
 [Parameter(Mandatory)][ValidateSet(150,160,170)][int]$CompatibilityLevel,
 [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
 [Parameter(Mandatory)][string]$ExpectedTargetKey,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [Parameter(Mandatory)][string]$SsisReleaseDirectory,
 [Parameter(Mandatory)][string]$ParserReleaseDirectory,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][hashtable]$ExecutionInputSha256,
 [ValidateSet('Full','Functional','ProcedureBoundary')][string]$QualificationPhase='Full',
 [string]$InstallationPackageRoot,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedPackageManifestSha256,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$privateRoot=Join-Path $repo '.runtime'
$journal=[IO.Path]::GetFullPath($JournalDirectory)
if(-not $journal.StartsWith($privateRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_BUILD_JOURNAL_SCOPE'}
if($CompatibilityLevel -gt (@{'2019'=150;'2022'=160;'2025'=170}[$Version])){throw 'SSIS_BUILD_UNSUPPORTED_CL'}
if($InstallationPackageRoot){
 $InstallationPackageRoot=[IO.Path]::GetFullPath($InstallationPackageRoot)
 if(-not $InstallationPackageRoot.StartsWith($privateRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
    -not $ExpectedPackageManifestSha256 -or (Get-FileHash -LiteralPath (Join-Path $InstallationPackageRoot 'PACKAGE-MANIFEST.json')).Hash -cne $ExpectedPackageManifestSha256){throw 'SSIS_BUILD_PACKAGE_BINDING'}
}
if(-not $ValidateOnly){
 $selectedSsis=if($InstallationPackageRoot){Join-Path $InstallationPackageRoot 'Modules/toolbelt.tsql.ssis-debug/Artifacts'}else{$SsisReleaseDirectory}
 $selectedParser=if($InstallationPackageRoot){Join-Path $InstallationPackageRoot 'Modules/toolbelt.tsql.script-parser/Artifacts'}else{$ParserReleaseDirectory}
 $manifest=Get-Content -LiteralPath (Join-Path $selectedSsis 'Toolbelt.Tsql.SsisDebug.trust-manifest.json') -Raw|ConvertFrom-Json
 foreach($input in @(@{File=(Join-Path $selectedSsis 'Toolbelt.Tsql.SsisDebug.dll');Hash=$QualifiedProviderSha512},@{File=(Join-Path $selectedParser 'Toolbelt.Tsql.ScriptParser.dll');Hash=$manifest.parserSha512},@{File=(Join-Path $selectedParser 'Microsoft.SqlServer.TransactSql.ScriptDom.dll');Hash=$manifest.scriptDomSha512})){
  if((Get-FileHash -LiteralPath $input.File -Algorithm SHA512).Hash -cne $input.Hash){throw 'SSIS_BUILD_BINARY_INPUT_DRIFT'}
 }
}
$required=@('Invoke-CurrentBuildLab.ps1','Invoke-CurrentBuildCases.ps1','Invoke-ProcedureBoundaryCases.ps1',
 'Invoke-LabContract.ps1','Invoke-ComponentsV2Audit.ps1','Invoke-CurrentQualificationLab.ps1',
 'Invoke-CurrentQualificationAllCases.ps1','Invoke-CurrentCases.ps1','Invoke-CurrentQualificationCases.ps1',
 'Invoke-CurrentQualificationBoundaryCases.ps1','Invoke-CurrentQualificationSafetyCases.ps1',
 'Invoke-ComponentsV2DomainCases.ps1','Invoke-ComponentsV2ExpressionCases.ps1','Invoke-ComponentsV2VariableCases.ps1',
 'Invoke-ApiCases.ps1','Invoke-ReleaseRightsCases.ps1','Invoke-LifecycleCases.ps1','Invoke-ProcedureDefinitionCases.ps1')
foreach($path in $ExecutionInputSha256.Keys){
 $resolved=[IO.Path]::GetFullPath((Join-Path $repo $path))
 if(-not $resolved.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
    (Get-FileHash -LiteralPath $resolved).Hash -cne $ExecutionInputSha256[$path]){throw 'SSIS_BUILD_INPUT_DRIFT'}
}
foreach($name in $required){if(-not $ExecutionInputSha256.ContainsKey('Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/'+$name)){throw 'SSIS_BUILD_INPUT_CLOSURE'}}
foreach($file in Get-ChildItem (Join-Path $PSScriptRoot '../Fixtures') -File){
 $relative='Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/'+$file.Name
 if(-not $ExecutionInputSha256.ContainsKey($relative)){throw 'SSIS_BUILD_FIXTURE_CLOSURE'}
}
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-CurrentQualificationLab.ps1'),[ref]$null,[ref]$errors)
$binder=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Bind-CurrentScriptRoot'},$true))
if($errors.Count -or $binder.Count -ne 1){throw 'SSIS_BUILD_BINDER'}
. ([scriptblock]::Create($binder[0].Extent.Text))
& (Join-Path $PSScriptRoot 'Invoke-CurrentBuildCases.ps1') -CompatibilityLevel $CompatibilityLevel -DeploymentMode $DeploymentMode -GeneratorDatabase 'ToolbeltSsis_0000000000000000_central' -ValidateOnly | Out-Null
$arguments=@{Version=$Version;Patch=$Patch;ExpectedTargetKey=$ExpectedTargetKey;ExpectedContractSha256=$ExpectedContractSha256}
if($Action -ceq 'Audit'){
 # Der etablierte frische Audit prüft DB/Trust/Config und zusätzlich den
 # vorher intent-journalisierten, exakt benannten Lowpriv-Login.
 $audit=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionLab.ps1'))
 $anchor="Version='2025';Patch='CU8'"
 if($audit.Split($anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_BUILD_AUDIT_ANCHOR'}
 $audit=$audit.Replace($anchor,("Version='"+$Version+"';Patch='"+$Patch+"'"))
 $closure=@{}
 foreach($file in @('Invoke-ProcedureDefinitionCases.ps1','Invoke-CurrentCases.ps1','../Fixtures/procedure-8.dtsx')){$closure[$file]=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $file)).Hash}
 $arguments=@{Mode='Audit';ExpectedTargetKey=$ExpectedTargetKey;ExpectedContractSha256=$ExpectedContractSha256;JournalDirectory=$journal;CaseInputSha256=$closure;ValidateOnly=$ValidateOnly}
 & ([scriptblock]::Create((Bind-CurrentScriptRoot -Text $audit -Root $PSScriptRoot))) @arguments
 return
}
$original=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
if((Get-FileHash -LiteralPath $original).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){throw 'SSIS_BUILD_HARNESS_CHANGED'}
$text=[IO.File]::ReadAllText($original)
if($InstallationPackageRoot){$text=$text.Replace("'SSIS-Debug-1.0.0-Install-Windows'","'SSIS-Debug-Qualified-Install-Windows'")}
foreach($line in @($text -split "`n"|Where-Object {$_ -match 'Invoke-(CoreContract|ApiCases|ReleaseRightsCases|LifecycleCases)\.ps1'})){
 if($text.Split($line,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_BUILD_HARNESS_ANCHOR'}
 $text=$text.Replace($line,'')
}
$anchor="    `$phase=`$mode+'-uninstall';"
$insert=@'
    $phase=$mode+'-current-build'
    & (Join-Path $PSScriptRoot 'Invoke-CurrentBuildCases.ps1') -Connection $connection -Master $master -AdminConnectionString $builder.ConnectionString -RunId $runId -IdentityJournal (Join-Path $journalRoot 'identity.private.json') -CompatibilityLevel $CompatibilityLevel -DeploymentMode $mode -CrossDatabase $clientDatabase -FixtureModuleRoot $moduleRoot -GeneratorDatabase $database -QualificationPhase '@PHASE@'
'@
$insert=$insert.Replace('@PHASE@',$QualificationPhase)
if($text.Split($anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_BUILD_HARNESS_HOOK'}
$text=$text.Replace($anchor,$insert+"`n"+$anchor)
$bound=Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot
$errors=$null
[void][Management.Automation.Language.Parser]::ParseInput($bound,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_BUILD_HARNESS_SYNTAX'}
if($ValidateOnly){'SSIS_CURRENT_BUILD_INPUTS_PASS; no SQL';return}
$arguments.Modes=@($DeploymentMode)
$arguments.CompatibilityLevel=$CompatibilityLevel
$arguments.Full=$true
if($InstallationPackageRoot){$arguments.InstallationPackageRoot=$InstallationPackageRoot}
else{$arguments.SsisReleaseDirectory=$SsisReleaseDirectory;$arguments.ParserReleaseDirectory=$ParserReleaseDirectory}
$arguments.QualifiedProviderSha512=$QualifiedProviderSha512
$arguments.JournalDirectory=$journal
& ([scriptblock]::Create($bound)) @arguments
