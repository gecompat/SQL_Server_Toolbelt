[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunsetPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedRunsetSha256,
    [Parameter(Mandatory)][ValidateRange(0,1)][int]$CaseIndex,
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
$v2Package='Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-ComponentsV2-1.0.0-Install-Windows.zip'
$v2Qualification='Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/ComponentsV2.InstallPackage.20261028.json'
$v2Output='Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL.sql'
$v2Report='Releases/1.0.0/ssis-components-v2-standalone-installer.json'
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
$text=$text.Replace("(Join-Path `$PSScriptRoot 'Prepare-StandaloneTsqlInstallerRunset.ps1')","(Join-Path `$PSScriptRoot 'Prepare-ComponentsV2StandaloneTsqlInstallerRunset.ps1')")
$text=$text.Replace("(Join-Path `$PSScriptRoot 'Invoke-StandaloneTsqlInstallerLab.ps1')","(Join-Path `$PSScriptRoot 'Invoke-ComponentsV2StandaloneTsqlInstallerLab.ps1')")
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
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Prepare-ComponentsV2StandaloneTsqlInstallerRunset.ps1'),[ref]$null,[ref]$prepErrors)
    if($prepErrors.Count){throw 'SSIS_V2_TSQL_PREPARER_SYNTAX'}
    if($adapted -notlike "*'$v2Package'*" -or $adapted -notlike "*'$v2Output'*" -or $adapted -notlike "*'$v2Report'*"){throw 'SSIS_V2_TSQL_ADAPTATION_BINDING_MISSING'}
    'PASS SSIS_V2_TSQL_ADAPTER_AND_PREPARER_VALIDATED; no SQL';return
}
$invoke=@{RunsetPath=$RunsetPath;ExpectedRunsetSha256=$ExpectedRunsetSha256;CaseIndex=$CaseIndex}
if($AuditOnly){$invoke.AuditOnly=$true}
if($ReadOnlyPreflight){$invoke.ReadOnlyPreflight=$true}
& ([scriptblock]::Create($adapted)) @invoke
