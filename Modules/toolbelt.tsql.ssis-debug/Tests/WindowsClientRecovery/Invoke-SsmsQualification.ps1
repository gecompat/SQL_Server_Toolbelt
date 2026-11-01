#Requires -Version 7.5
# Ein neuer, quellgebundener GUI-Test: Zielnachweis vor der Datenbankanlage.
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
$original=Join-Path $PSScriptRoot 'Invoke-WindowsClient.ps1'
if((Get-FileHash $original).Hash-cne '15D323FFEAC488C835CFA46751721AF4D9A78FD61981DCB46C332FED973B9F36'){throw 'SSMS_ORIGINAL_DRIVER_CHANGED'}
$code=[IO.File]::ReadAllText($original).Replace("`r`n","`n")
function Replace-SsmsOnce([string]$Text,[string]$Old,[string]$New){
 if(($Text.Split($Old).Count-1)-ne 1){throw 'SSMS_DRIVER_ADAPTER_ANCHOR'}
 return $Text.Replace($Old,$New)
}
$code=Replace-SsmsOnce $code "`$files+=@('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-WindowsClient.ps1'," @'
$files+=@('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-SsmsQualification.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/SsmsGuiHook.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-WindowsClient.ps1',
'@
$code=Replace-SsmsOnce $code ". (Join-Path `$PSScriptRoot 'ClientGuiHook.ps1')" @'
$text=Replace-Once $text ' $prepare=[IO.File]::ReadAllText' (" Invoke-SsmsTargetPreflight`n"+' $prepare=[IO.File]::ReadAllText')
. (Join-Path $PSScriptRoot 'SsmsGuiHook.ps1')
if($script:ssmsDescribeOnly){
 [ordered]@{canonical=$text;gui=(Get-Command Invoke-ClientGui).Definition;preflightQuery=(Get-SsmsPreflightSql ('A'*64))}|ConvertTo-Json -Depth 3
 return
}
'@
# Der dynamische Adapter besitzt absichtlich die eindeutige eigene Self-Datei.
$self="'"+$PSCommandPath.Replace("'","''")+"'"
$code=$code.Replace('$PSCommandPath',$self)
$rootReplacement='$text=$text.Replace(''$PSScriptRoot'',$literal)'
$code=Replace-SsmsOnce $code $rootReplacement '__SSMS_CANONICAL_ROOT_REPLACEMENT__'
$ssmsAdapterSourceRoot=$PSScriptRoot
$code=$code.Replace('$PSScriptRoot','$ssmsAdapterSourceRoot').Replace('__SSMS_CANONICAL_ROOT_REPLACEMENT__',$rootReplacement)
$script:ssmsDescribeOnly=[bool]$DescribeOnly
$arguments=@{};foreach($key in $PSBoundParameters.Keys){if($key-cne 'DescribeOnly'){$arguments[$key]=$PSBoundParameters[$key]}}
try{. ([scriptblock]::Create($code)) @arguments}
finally{
 if($Mode-ceq 'Run' -and -not $ValidateOnly -and (Get-Variable ssmsTargetApp -Scope Script -ErrorAction SilentlyContinue)){
  $app=$script:ssmsTargetApp
  if($app -and -not $app.HasExited){
   if($app.StartTime.ToUniversalTime().ToString('o')-cne $script:ssmsTargetStarted){throw 'SSMS_PREFLIGHT_PROCESS_DRIFT'}
   $app.Kill();[void]$app.WaitForExit(10000)
  }
 }
}
