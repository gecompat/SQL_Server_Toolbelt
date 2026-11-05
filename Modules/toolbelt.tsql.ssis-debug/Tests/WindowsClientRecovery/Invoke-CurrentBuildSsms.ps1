#Requires -Version 7.5
# Fresh visible SSMS/SQLCMD coordinator using the qualified current 40-parameter DLL.
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
$prior=Join-Path $PSScriptRoot 'Invoke-SsmsSqlcmd.ps1'
if((Get-FileHash $prior).Hash -cne 'B15F2C7ED9CD14F8FBCCB1A280B6018AF915FAEB16F5B4B022231C58BF06A5EF'){throw 'SSIS_CURRENT_SSMS_METHOD_CHANGED'}
$source=[IO.File]::ReadAllText($prior)
function Replace-CurrentSsmsOnce([string]$Old,[string]$New){
 if($script:source.Split($Old,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_CURRENT_SSMS_METHOD_ANCHOR'}
 $script:source=$script:source.Replace($Old,$New)
}
$anchor='$files+=@(''Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-SsmsSqlcmd.ps1'','
$replacement=@'
$files+=@('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-CurrentBuildSsms.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/CurrentBuildArtifacts.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.Build.20261104.json',
 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.Build.Native.20261104.json',
 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-SsmsSqlcmd.ps1',
'@
Replace-CurrentSsmsOnce $anchor $replacement
$anchor='. (Join-Path $PSScriptRoot ''SsmsSqlcmdHook.ps1'')'
$replacement=@'
$text=Replace-Once $text ".Rows[0].N-eq 38) 'CURRENT_INSTALLED_API'" ".Rows[0].N-eq 40) 'CURRENT_INSTALLED_API'"
$fixtureAnchor='. (Join-Path '+$literal+" 'RecoveryFixture.ps1')"
$text=Replace-Once $text $fixtureAnchor ($fixtureAnchor+"`n. (Join-Path "+$literal+" 'CurrentBuildArtifacts.ps1')")
. (Join-Path $PSScriptRoot 'SsmsSqlcmdHook.ps1')
'@
Replace-CurrentSsmsOnce $anchor $replacement
# Native launcher and fresh child audit must return to this adapter, not its predecessor.
$selfLine=@($source.Split("`n")|Where-Object {$_.StartsWith('$self=',[StringComparison]::Ordinal)})
if($selfLine.Count -ne 1){throw 'SSIS_CURRENT_SSMS_SELF_ANCHOR'}
$literal="'"+$PSCommandPath.Replace("'","''")+"'"
$source=$source.Replace($selfLine[0],('$self='+"'"+$literal.Replace("'","''")+"'"))
$currentSsmsSourceRoot=$PSScriptRoot
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_CURRENT_SSMS_COMPOSED_SYNTAX'}
foreach($variable in @($tree.FindAll({param($n)$n -is [Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -ceq 'PSScriptRoot'},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)){
 $source=$source.Substring(0,$variable.Extent.StartOffset)+'$currentSsmsSourceRoot'+$source.Substring($variable.Extent.EndOffset)
}
. ([scriptblock]::Create($source)) @PSBoundParameters
