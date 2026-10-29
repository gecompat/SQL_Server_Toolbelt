[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunsetPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedRunsetSha256,
    [Parameter(Mandatory)][ValidateRange(0,3)][int]$CaseIndex,
    [switch]$AuditOnly,
    [switch]$ValidateOnly,
    [switch]$ReadOnlyPreflight
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'SSIS_V2_TSQL_POWERSHELL_7_REQUIRED'}
$sourcePath=Join-Path $PSScriptRoot 'Invoke-StandaloneTsqlInstallerLab.ps1'
$sourceHash='A87FD76C819CA0BCCE3CFC5F0C33C2867E89EE31D622327DD256C047E039602D'
if((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -cne $sourceHash){throw 'SSIS_V2_TSQL_FROZEN_V1_HARNESS_CHANGED'}
$v2Package='Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-Current-Install-Windows.zip'
$v2Qualification='Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.InstallPackage.20261029.json'
$v2Output='Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT.sql'
$v2Report='Releases/1.0.0/ssis-current-standalone-installer.json'
$v2PackagePath=Join-Path (Join-Path $PSScriptRoot '../..') $v2Package
$v2QualificationPath=Join-Path (Join-Path $PSScriptRoot '../..') $v2Qualification
if((Test-Path -LiteralPath $v2PackagePath -PathType Leaf) -and (Test-Path -LiteralPath $v2QualificationPath -PathType Leaf)){
    $script:v2PackageSha256=(Get-FileHash -LiteralPath $v2PackagePath -Algorithm SHA256).Hash.ToUpperInvariant()
    $script:v2QualificationSha256=(Get-FileHash -LiteralPath $v2QualificationPath -Algorithm SHA256).Hash.ToUpperInvariant()
}elseif($ValidateOnly){$script:v2PackageSha256=('0'*64);$script:v2QualificationSha256=('0'*64)}
else{throw 'SSIS_V2_TSQL_PACKAGE_OR_QUALIFICATION_MISSING'}
$text=[IO.File]::ReadAllText($sourcePath)
$replacements=@(
    [pscustomobject]@{old='Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/LookupRoles.InstallPackage.20261025.json';new=$v2Qualification},
    [pscustomobject]@{old='Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip';new=$v2Package},
    [pscustomobject]@{old='Releases/1.0.0/SSIS-INSTALL-TSQL.sql';new=$v2Output},
    [pscustomobject]@{old='Releases/1.0.0/ssis-standalone-installer.json';new=$v2Report},
    [pscustomobject]@{old="'A256929FF32DAEE4087DC61C70BB8D4DFFEBB55772878BE53C658088F4E33049'";new='$script:v2PackageSha256'},
    [pscustomobject]@{old="'6FBF48508A1F13BB9F629353BBCE8908DC729C9AD2E7779B3C689DBFB62A692F'";new='$script:v2QualificationSha256'},
    [pscustomobject]@{old="'a256929ff32daee4087dc61c70bb8d4dffebb55772878be53c658088f4e33049'";new='$script:v2PackageSha256.ToLowerInvariant()'}
)
foreach($replacement in $replacements){
    $old=$replacement.old
    $count=([regex]::Matches($text,[regex]::Escape($old))).Count
    if($count -lt 1){throw 'SSIS_V2_TSQL_ADAPTATION_ANCHOR_MISSING'}
    if($old -like '*sha256*' -and $count -ne 1){throw 'SSIS_V2_TSQL_ADAPTATION_ANCHOR_AMBIGUOUS'}
    $text=$text.Replace($old,$replacement.new)
}
$apiCall="        & (Join-Path `$repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-ApiCases.ps1') -Connection `$connection | Out-Null"
$apiCallCount=([regex]::Matches($text,[regex]::Escape($apiCall))).Count
if($apiCallCount -ne 1){throw 'SSIS_V2_TSQL_API_HOOK_ANCHOR'}
$text=$text.Replace($apiCall,$apiCall.Replace('Invoke-ApiCases.ps1','Invoke-CurrentCases.ps1'))
$text=$text.Replace('Invoke-ApiCases.ps1','Invoke-CurrentCases.ps1')
$fixtureAnchor="(Join-Path `$repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/synthetic-8.dtsx'),"
if(([regex]::Matches($text,[regex]::Escape($fixtureAnchor))).Count -ne 1){throw 'SSIS_CURRENT_TSQL_FIXTURE_PIN_ANCHOR'}
$text=$text.Replace($fixtureAnchor,$fixtureAnchor+"`n        (Join-Path `$repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/components-v2-rowcount.dtsx'),`n        (Join-Path `$repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/components-v2-flatfile.dtsx'),")
if(([regex]::Matches($text,' -ne 20\b')).Count -ne 4){throw 'SSIS_CURRENT_TSQL_PIN_COUNT_ANCHOR'}
$text=[regex]::Replace($text,' -ne 20\b',' -ne 22')
$runsetChanges=@(
    [pscustomobject]@{old='$script:runset.cases.Count -ne 2';new='$script:runset.cases.Count -ne 4';count=1},
    [pscustomobject]@{old='$script:runset.native.caseInvocations -ne 2';new='$script:runset.native.caseInvocations -ne 4';count=1},
    [pscustomobject]@{old='$script:runset.native.auditInvocations -ne 2';new='$script:runset.native.auditInvocations -ne 4';count=1},
    [pscustomobject]@{old='$script:runset.native.maximumAttempts -ne 4';new='$script:runset.native.maximumAttempts -ne 8';count=1},
    [pscustomobject]@{old='foreach($index in 0..1){';new='foreach($index in 0..3){$expectedCaseKey=@(''2022/150'',''2022/160'',''2025/150'',''2025/160'')[$index];';count=1}
)
foreach($change in $runsetChanges){
    if(([regex]::Matches($text,[regex]::Escape($change.old))).Count -ne $change.count){throw 'SSIS_CURRENT_MATRIX_RUNSET_ANCHOR'}
    $text=$text.Replace($change.old,$change.new)
}
$caseScopePattern='\$case\.patch -cne ''base'' -or \$version -cnotin @\(''2019'',''2025''\) -or\s+\$case\.cl -ne @\{2019=150;2025=170\}\[\[int\]\$version\]\)\{throw ''SSIS_TSQL_RUNSET_CASE_SCOPE''\}'
$caseScope=[regex]::Match($text,$caseScopePattern)
if(-not $caseScope.Success -or [regex]::Matches($text,$caseScopePattern).Count -ne 1){throw 'SSIS_CURRENT_MATRIX_CASE_SCOPE_ANCHOR'}
$newCaseScope='$case.patch -cne ''base'' -or $case.version -isnot [string] -or ($case.cl -isnot [int] -and $case.cl -isnot [long]) -or "$version/$($case.cl)" -cne $expectedCaseKey){throw ''SSIS_TSQL_RUNSET_CASE_SCOPE''}'
$text=$text.Replace($caseScope.Value,$newCaseScope)
$majorAnchor='@{2019=15;2025=17}'
if(([regex]::Matches($text,[regex]::Escape($majorAnchor))).Count -ne 2){throw 'SSIS_CURRENT_MATRIX_MAJOR_VERSION_ANCHOR'}
$text=$text.Replace($majorAnchor,'@{2019=15;2022=16;2025=17}')
$text=$text.Replace("(Join-Path `$PSScriptRoot 'Prepare-StandaloneTsqlInstallerRunset.ps1')","(Join-Path `$PSScriptRoot 'Prepare-CurrentStandaloneTsqlInstallerMatrixRunset.ps1')")
$text=$text.Replace("(Join-Path `$PSScriptRoot 'Invoke-StandaloneTsqlInstallerLab.ps1')","(Join-Path `$PSScriptRoot 'Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1')")
function Bind-StandaloneV2AutomaticVariables([string]$ScriptText,[string]$Root,[string]$CommandPath){
    $parseErrors=$null
    $tree=[Management.Automation.Language.Parser]::ParseInput($ScriptText,[ref]$null,[ref]$parseErrors)
    if($parseErrors.Count){throw 'SSIS_V2_TSQL_ADAPTED_SOURCE_PARSE'}
    foreach($binding in @(@{name='PSScriptRoot';value=$Root},@{name='PSCommandPath';value=$CommandPath})){
        $parseErrors=$null
        $tree=[Management.Automation.Language.Parser]::ParseInput($ScriptText,[ref]$null,[ref]$parseErrors)
        if($parseErrors.Count){throw 'SSIS_V2_TSQL_ADAPTED_SOURCE_PARSE'}
        $nodes=@($tree.FindAll({param($node)$node -is [Management.Automation.Language.VariableExpressionAst] -and $node.VariablePath.UserPath -ceq $binding.name},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)
        if(-not $nodes.Count){throw 'SSIS_V2_TSQL_AUTOMATIC_VARIABLE_MISSING'}
        $literal="'"+$binding.value.Replace("'","''")+"'"
        foreach($node in $nodes){$ScriptText=$ScriptText.Substring(0,$node.Extent.StartOffset)+$literal+$ScriptText.Substring($node.Extent.EndOffset)}
    }
    return $ScriptText
}
$adapted=Bind-StandaloneV2AutomaticVariables -ScriptText $text -Root $PSScriptRoot -CommandPath $PSCommandPath
$errors=$null
[void][Management.Automation.Language.Parser]::ParseInput($adapted,[ref]$null,[ref]$errors)
if($errors.Count){throw ('SSIS_V2_TSQL_ADAPTED_SYNTAX line='+$errors[0].Extent.StartLineNumber+' column='+$errors[0].Extent.StartColumnNumber+' id='+$errors[0].ErrorId)}
if($ValidateOnly){
    $prepErrors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Prepare-CurrentStandaloneTsqlInstallerMatrixRunset.ps1'),[ref]$null,[ref]$prepErrors)
    if($prepErrors.Count){throw 'SSIS_V2_TSQL_PREPARER_SYNTAX'}
    if($adapted -notlike "*'$v2Package'*" -or $adapted -notlike "*'$v2Output'*" -or $adapted -notlike "*'$v2Report'*"){throw 'SSIS_V2_TSQL_ADAPTATION_BINDING_MISSING'}
    'PASS SSIS_V2_TSQL_ADAPTER_AND_PREPARER_VALIDATED; no SQL';return
}
$invoke=@{RunsetPath=$RunsetPath;ExpectedRunsetSha256=$ExpectedRunsetSha256;CaseIndex=$CaseIndex}
if($AuditOnly){$invoke.AuditOnly=$true}
if($ReadOnlyPreflight){$invoke.ReadOnlyPreflight=$true}
& ([scriptblock]::Create($adapted)) @invoke
