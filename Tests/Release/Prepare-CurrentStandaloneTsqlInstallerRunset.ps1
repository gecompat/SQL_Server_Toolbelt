[CmdletBinding()]
param([Parameter(Mandatory)][string]$EvidenceDirectory,[switch]$ValidateOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$sourcePath=Join-Path $PSScriptRoot 'Prepare-StandaloneTsqlInstallerRunset.ps1'
if((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -cne '1F1EDA10AB0E67CE7B1E4912C51B3F5429D24937025C5E8899BC71C80A84426D'){
    throw 'SSIS_V2_TSQL_FROZEN_V1_PREPARER_CHANGED'
}
$text=[IO.File]::ReadAllText($sourcePath)
$replacements=@(
    [pscustomobject]@{old="'Invoke-StandaloneTsqlInstallerLab.ps1'";new="'Invoke-CurrentStandaloneTsqlInstallerLab.ps1'";count=1},
    [pscustomobject]@{old="'Prepare-StandaloneTsqlInstallerRunset.ps1'";new="'Prepare-CurrentStandaloneTsqlInstallerRunset.ps1'";count=1},
    [pscustomobject]@{old='Releases/1.0.0/SSIS-INSTALL-TSQL.sql';new='Releases/1.0.0/SSIS-INSTALL-TSQL-CURRENT.sql';count=1},
    [pscustomobject]@{old='Releases/1.0.0/ssis-standalone-installer.json';new='Releases/1.0.0/ssis-current-standalone-installer.json';count=1},
    [pscustomobject]@{old='SSIS-Debug-1.0.0-Install-Windows.zip';new='SSIS-Debug-Current-Install-Windows.zip';count=3},
    [pscustomobject]@{old='LookupRoles.InstallPackage.20261025.json';new='Current.InstallPackage.20261029.json';count=1}
)
foreach($replacement in $replacements){
    $count=([regex]::Matches($text,[regex]::Escape($replacement.old))).Count
    if($count -ne $replacement.count){throw 'SSIS_V2_TSQL_PREPARER_ANCHOR_MISSING_OR_AMBIGUOUS'}
    $text=$text.Replace($replacement.old,$replacement.new)
}
$text=$text.Replace('Invoke-ApiCases.ps1','Invoke-CurrentCases.ps1')
$parseErrors=$null
$tree=[Management.Automation.Language.Parser]::ParseInput($text,[ref]$null,[ref]$parseErrors)
if($parseErrors.Count){throw 'SSIS_V2_TSQL_ADAPTED_PREPARER_PARSE'}
$nodes=@($tree.FindAll({param($node)$node -is [Management.Automation.Language.VariableExpressionAst] -and $node.VariablePath.UserPath -ceq 'PSScriptRoot'},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)
if(-not $nodes.Count){throw 'SSIS_V2_TSQL_PREPARER_ROOT_BINDING_MISSING'}
$literal="'"+$PSScriptRoot.Replace("'","''")+"'"
foreach($node in $nodes){$text=$text.Substring(0,$node.Extent.StartOffset)+$literal+$text.Substring($node.Extent.EndOffset)}
$parseErrors=$null
[void][Management.Automation.Language.Parser]::ParseInput($text,[ref]$null,[ref]$parseErrors)
if($parseErrors.Count){throw 'SSIS_V2_TSQL_ADAPTED_PREPARER_SYNTAX'}
if($ValidateOnly){'PASS SSIS_V2_TSQL_PREPARER_VALIDATED; no SQL';return}
& ([scriptblock]::Create($text)) -EvidenceDirectory $EvidenceDirectory
