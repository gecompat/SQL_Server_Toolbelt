#Requires -Version 7.5
# Visible SSMS/SQLCMD coordinator bound to the qualified Copy Column ZIP.
[CmdletBinding()]
param(
 [ValidateSet('Prepare','Launch','Run','Audit')][string]$Mode='Prepare',
 [Parameter(Mandatory)][string]$PlanPath,[string]$ExpectedPlanSha256,
 [string]$JournalPath,[string]$ExpectedJournalSha256,
 [string]$SsisReleaseDirectory,[string]$ParserReleaseDirectory,
 [string]$SqlcmdPath,[string]$SsmsPath,[string]$BudgetPath,
 [string]$LabHostClientLauncher,[string]$ExpectedLabHostClientSha256,
 [string]$LabModuleFile,[string]$ExpectedLabCommit,[switch]$ValidateOnly,[switch]$DescribeOnly
)
$ErrorActionPreference='Stop'
$prior=Join-Path $PSScriptRoot 'Invoke-CurrentBuildSsms.ps1'
if((Get-FileHash -LiteralPath $prior).Hash -cne '7F3F60DBCA3AF23657BCEC397AD74962ED04B1B6CBB0D6BBBFF0C04049889B17'){throw 'SSIS_COPY_SSMS_METHOD_CHANGED'}
$source=[IO.File]::ReadAllText($prior)
if($source.Split('CurrentBuildArtifacts.ps1',[StringSplitOptions]::None).Count -ne 3){throw 'SSIS_COPY_SSMS_ARTIFACT_ANCHOR'}
$source=$source.Replace('CurrentBuildArtifacts.ps1','CopyColumnArtifacts.ps1')
$anchor="$"+"files+=@('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-CurrentBuildSsms.ps1',"
if($source.Split($anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_COPY_SSMS_SOURCE_ANCHOR'}
$replacement=@'
$files+=@('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-CopyColumnSsms.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-CurrentBuildSsms.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.V1.20261114.json',
 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.Delivery.20261115.json',
'@
$source=$source.Replace($anchor,$replacement)
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_COPY_SSMS_COMPOSED_SYNTAX'}
foreach($variable in @($tree.FindAll({param($n)$n -is [Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -cin @('PSScriptRoot','PSCommandPath')},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)){
 $value=if($variable.VariablePath.UserPath -ceq 'PSScriptRoot'){$PSScriptRoot}else{$PSCommandPath}
 $literal="'"+$value.Replace("'","''")+"'"
 $source=$source.Substring(0,$variable.Extent.StartOffset)+$literal+$source.Substring($variable.Extent.EndOffset)
}
. ([scriptblock]::Create($source)) @PSBoundParameters
