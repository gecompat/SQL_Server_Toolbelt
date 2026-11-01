#Requires -Version 7.5
<#
Vorhandene Windows-Labidentität, echter öffentlicher Installer und eigene SSMS-
Instanz. Launch verwendet einen explizit gebundenen nativen Lab-Testhelper;
dieser verbraucht seine geschützte vorhandene Windows-Anmeldung intern.
#>
[CmdletBinding()]
param(
 [ValidateSet('Prepare','Launch','Run','Audit')][string]$Mode='Prepare',
 [Parameter(Mandatory)][string]$PlanPath,
 [string]$ExpectedPlanSha256,
 [string]$JournalPath,
 [string]$ExpectedJournalSha256,
 [string]$SsisReleaseDirectory,
 [string]$ParserReleaseDirectory,
 [string]$SqlcmdPath,
 [string]$SsmsPath,
 [string]$BudgetPath,
 [string]$LabHostClientLauncher,
 [string]$ExpectedLabHostClientSha256,
 [string]$LabModuleFile,
 [string]$ExpectedLabCommit,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$PlanPath=[IO.Path]::GetFullPath($PlanPath)
if($JournalPath){$JournalPath=[IO.Path]::GetFullPath($JournalPath)}
if($BudgetPath){$BudgetPath=[IO.Path]::GetFullPath($BudgetPath)}
$base=Join-Path $PSScriptRoot 'Invoke-TransportRecovery.ps1'
if((Get-FileHash $base).Hash-cne '88964A64E0FA6DC0C897CD6253B30018838BE1365A872A4F4F4A2365F60C0A4F'){throw 'SSIS_WINDOWS_CANONICAL_METHOD_CHANGED'}
$text=[IO.File]::ReadAllText($base).Replace("`r`n","`n")
function Replace-Once([string]$InputText,[string]$Old,[string]$New){
 if(($InputText.Split($Old).Count-1)-ne 1){throw 'SSIS_WINDOWS_ADAPTER_ANCHOR'}
 $InputText.Replace($Old,$New)
}
$text=$text.Replace('ssis-sql-hard-transport-run/1','ssis-windows-client-run/1').Replace('ssis-sql-hard-transport/1','ssis-windows-client/1')
$text=Replace-Once $text 'function Private([string]$Path)' @'
$files+=@('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-WindowsClient.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/ClientGuiHook.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Examples/Installation/Install-Local.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Deployment/Add-TrustedAssembly.sql',
 'Modules/toolbelt.tsql.script-parser/Deployment/Add-TrustedAssembly.sql')
function Private([string]$Path)
'@
$begin=$text.IndexOf(' $hashes=@(',[StringComparison]::Ordinal)
$end=$text.IndexOf(' Check ((Query-Client $connection',[StringComparison]::Ordinal)
if($begin-lt 0 -or $end-le $begin){throw 'SSIS_WINDOWS_PUBLIC_INSTALLER_ANCHOR'}
$text=$text.Substring(0,$begin)+" Invoke-ClientInstallation`n"+$text.Substring($end)
$begin=$text.IndexOf(' $blocker=Open-ClientSql',[StringComparison]::Ordinal)
$end=$text.IndexOf("`n}catch{`n `$failure=",[StringComparison]::Ordinal)
if($begin-lt 0 -or $end-le $begin){throw 'SSIS_WINDOWS_GUI_HOOK_ANCHOR'}
$text=$text.Substring(0,$begin)+" Invoke-ClientGui"+$text.Substring($end)
$text=$text.Replace('Open-ClientSql $target','Open-ClientSql $target -Windows')
$text=Replace-Once $text ' $bytes=Get-RecoveryPackage' ' $bytes=Get-ClientGuiPackage'
$text=Replace-Once $text '$journal.cases.Count-ne 2' '$journal.cases.Count-ne 1'
$text=$text.Replace('SSIS_SQL_HARD_TRANSPORT_PASS cases=2','SSIS_WINDOWS_CLIENT_PASS cases=1')
$text=$text.Replace('; own clients terminated and all state restored','; public Windows installer and visible SSMS; all own state restored')
# SourceRoot ist ein bereits geprüfter lokaler Operatorpfad, keine Exportangabe.
$literal="'"+$PSScriptRoot.Replace("'","''")+"'"
$text=$text.Replace('$PSScriptRoot',$literal)
. (Join-Path $PSScriptRoot 'ClientGuiHook.ps1')
if($Mode-ceq 'Launch'){
 if(-not $ExpectedPlanSha256 -or (Get-FileHash $PlanPath).Hash-cne $ExpectedPlanSha256){throw 'SSIS_WINDOWS_LAUNCH_PLAN_CHANGED'}
 & ([scriptblock]::Create($text)) -Mode Run -PlanPath $PlanPath -ExpectedPlanSha256 $ExpectedPlanSha256 -ValidateOnly
 if($ValidateOnly){'SSIS_WINDOWS_LAUNCH_VALIDATED; no dialog, SQL or credential access';return}
 foreach($path in @($JournalPath,$BudgetPath)){
  if(-not $path -or -not $path.StartsWith((Join-Path $root '.runtime')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_WINDOWS_PRIVATE_LAUNCH_PATH_REQUIRED'}
 }
 $launchPath=$JournalPath+'.launch.json'
 if(Test-Path $launchPath){throw 'SSIS_WINDOWS_LAUNCH_ALREADY_RESERVED_NO_REPLAY'}
 if(-not $ExpectedLabHostClientSha256 -or (Get-FileHash -LiteralPath $LabHostClientLauncher).Hash-cne $ExpectedLabHostClientSha256){throw 'SSIS_WINDOWS_EXPLICIT_LAB_LAUNCHER_CHANGED'}
 . (Join-Path $PSScriptRoot 'LabClientCommon.ps1')
 $lab=Read-ClientLab;$entry=Select-ClientTarget $lab '2025' 'CU8'
 $clientPlan=Get-Content $PlanPath -Raw|ConvertFrom-Json -DateKind String
 if($entry.key-cne $clientPlan.key -or (Get-ClientHash $lab.Path)-cne $clientPlan.contractSha256){throw 'SSIS_WINDOWS_LAUNCH_TARGET_CHANGED'}
 Save-ClientPrivate $launchPath @{state='BOUND_LAB_CLIENT_DISPATCH';credentialReturned=$false;automaticRetry=$false}
 $arguments=@('-Mode','Run','-PlanPath',$PlanPath,'-ExpectedPlanSha256',$ExpectedPlanSha256,'-JournalPath',$JournalPath,'-BudgetPath',$BudgetPath)
 $result=& $LabHostClientLauncher -LabModuleFile $LabModuleFile -ExpectedLabCommit $ExpectedLabCommit -RunId ([guid]$entry.runId) -InstanceId $entry.instanceId -ScriptPath $PSCommandPath -ExpectedScriptSha256 (Get-FileHash $PSCommandPath).Hash -ScriptArguments $arguments -OutputDirectory ($JournalPath+'.lab-client')
 $result|Add-Member NoteProperty launcherSha256 $ExpectedLabHostClientSha256
 $result|Add-Member NoteProperty labSourceCommit $ExpectedLabCommit
 Save-ClientPrivate $launchPath $result
 'SSIS_WINDOWS_BOUND_LAB_CLIENT_DISPATCHED; authentication must be proven by the client';return
}
if($Mode-cne 'Prepare'){
 $clientPlan=Get-Content $PlanPath -Raw|ConvertFrom-Json -DateKind String
 if((Split-Path -Leaf $clientPlan.ssms)-ine 'SSMS.exe' -or (Get-FileHash $clientPlan.ssms).Hash-cne $clientPlan.ssmsSha256){throw 'SSIS_WINDOWS_SSMS_EXECUTABLE_CHANGED'}
}
$invoke=@{Mode=$Mode;PlanPath=$PlanPath;ExpectedPlanSha256=$ExpectedPlanSha256;JournalPath=$JournalPath;ExpectedJournalSha256=$ExpectedJournalSha256;SsisReleaseDirectory=$SsisReleaseDirectory;ParserReleaseDirectory=$ParserReleaseDirectory;SqlcmdPath=$SqlcmdPath;BudgetPath=$BudgetPath;ValidateOnly=$ValidateOnly}
# Dot-Scope erhält die canonicalen Scriptvariablen und deren Check-/Save-Funktionen.
. ([scriptblock]::Create($text)) @invoke
if($Mode-ceq 'Prepare'){
 $plan=Get-Content $PlanPath -Raw|ConvertFrom-Json -DateKind String
 $plan|Add-Member NoteProperty ssms ([IO.Path]::GetFullPath($SsmsPath))
 $plan|Add-Member NoteProperty ssmsSha256 (Get-FileHash $SsmsPath).Hash
 Save-ClientPrivate $PlanPath $plan
 return
}
if($Mode-ceq 'Run' -and -not $ValidateOnly){
 $seal=(Get-FileHash $JournalPath).Hash
 $info=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh.exe).Source)
 $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
 foreach($a in @('-NoProfile','-File',$PSCommandPath,'-Mode','Audit','-PlanPath',$PlanPath,'-ExpectedPlanSha256',$ExpectedPlanSha256,'-JournalPath',$JournalPath,'-ExpectedJournalSha256',$seal,'-BudgetPath',$BudgetPath)){$info.ArgumentList.Add($a)}
 $audit=[Diagnostics.Process]::Start($info);$out=$audit.StandardOutput.ReadToEndAsync();$err=$audit.StandardError.ReadToEndAsync()
 if(-not $audit.WaitForExit(60000)){$audit.Kill();throw 'SSIS_WINDOWS_FRESH_AUDIT_TIMEOUT'}
 [IO.File]::WriteAllText($JournalPath+'.audit-process.log',$out.Result+"`n"+$err.Result,[Text.UTF8Encoding]::new($false))
 if($audit.ExitCode-ne 0){throw 'SSIS_WINDOWS_FRESH_AUDIT_FAILED'}
 'SSIS_WINDOWS_CLIENT_AND_FRESH_AUDIT_PASS; own state restored'
}
