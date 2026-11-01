# Historische Installer-/GUI-Methode bleibt bytegenau erhalten.
$oldHook=Join-Path $PSScriptRoot 'ClientGuiHook.ps1'
if((Get-FileHash $oldHook).Hash-cne 'FB44D94E6EF2781941B5B03ABEA8980E5F4A1C9F52C690B44B5C81F6548933D7'){throw 'SSMS_ORIGINAL_HOOK_CHANGED'}
$hook=[IO.File]::ReadAllText($oldHook).Replace("`r`n","`n")
function Replace-SsmsHookOnce([string]$Text,[string]$Old,[string]$New){
 if(($Text.Split($Old).Count-1)-ne 1){throw 'SSMS_GUI_ADAPTER_ANCHOR'}
 return $Text.Replace($Old,$New)
}
$begin=$hook.IndexOf(' $ssmsPath=[string]$plan.ssms',[StringComparison]::Ordinal)
$end=$hook.IndexOf("`n Save-ClientPrivate (`$JournalPath+'.gui-ready.json')",[StringComparison]::Ordinal)
if($begin-lt 0 -or $end-le $begin){throw 'SSMS_GUI_REUSE_ANCHOR'}
$hook=$hook.Substring(0,$begin)+@'
 $app=$script:ssmsTargetApp;$appStarted=$script:ssmsTargetStarted
 if(-not $app -or $app.HasExited){throw 'SSMS_PREFLIGHT_INSTANCE_NOT_RUNNING'}
 $guiSeconds=[Math]::Max(0,((Get-SsmsDeadline)-[datetimeoffset]::UtcNow).TotalSeconds-120)
'@+$hook.Substring($end)
$hook=Replace-SsmsHookOnce $hook 'deadlineSeconds=900' 'deadlineSeconds=$guiSeconds'
$hook=Replace-SsmsHookOnce $hook '$clock.Elapsed.TotalSeconds-lt 900' '$clock.Elapsed.TotalSeconds-lt $guiSeconds'
. ([scriptblock]::Create($hook))
function Get-SsmsDeadline {
 [datetimeoffset]::Parse((Get-Content $BudgetPath -Raw|ConvertFrom-Json -DateKind String).ceilingUtc)
}
function Get-SsmsWitnessSql {
 "CONVERT(varchar(64),HASHBYTES('SHA2_256',CONCAT(CONVERT(nvarchar(128),SERVERPROPERTY('MachineName')),N'|',CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')),N'|',CONVERT(nvarchar(32),SERVERPROPERTY('ProcessID')),N'|',CONVERT(nvarchar(33),(SELECT sqlserver_start_time FROM sys.dm_os_sys_info),126))),2)"
}
function Get-SsmsPreflightSql([string]$Witness){
 if($Witness-cnotmatch '^[A-F0-9]{64}$'){throw 'SSMS_TARGET_WITNESS_INVALID'}
 $sql="-- SSIS: Windows-Anmeldung am gebundenen Labziel, vor jeder Testdatenbank.`nUSE master;`n"
 $sql+="IF "+(Get-SsmsWitnessSql)+"<>N'"+$Witness+"' THROW 51000,N'WRONG_LAB_TARGET',1;`n"
 $sql+="IF CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) NOT IN(N'NTLM',N'KERBEROS') THROW 51000,N'WINDOWS_AUTH_REQUIRED',1;`n"
 $sql+="IF NOT EXISTS(SELECT 1 FROM sys.dm_exec_connections WHERE session_id=@@SPID AND encrypt_option=N'TRUE') THROW 51000,N'ENCRYPTED_CONNECTION_REQUIRED',1;`n"
 $sql+="IF APP_NAME() NOT LIKE N'Microsoft SQL Server Management Studio%' THROW 51000,N'SSMS_REQUIRED',1;`nSELECT N'SSMS_LAB_WINDOWS_PREFLIGHT_PASS' AS Result,CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) AS AuthScheme,CONVERT(nvarchar(32),SERVERPROPERTY('ProductUpdateLevel')) AS Patch;`n"
 return $sql
}
function Invoke-SsmsTargetPreflight {
 $witness=[string](Query-Client $master ('SELECT '+(Get-SsmsWitnessSql)+' AS W;')).Rows[0].W
 $script:ssmsTargetWitness=$witness
 $sql=Get-SsmsPreflightSql $witness
 $path=$JournalPath+'.00-Lab-Login.sql';[IO.File]::WriteAllText($path,$sql,[Text.UTF8Encoding]::new($true))
 if((Get-FileHash $plan.ssms).Hash-cne $plan.ssmsSha256){throw 'SSMS_EXECUTABLE_CHANGED'}
 $start=[Diagnostics.ProcessStartInfo]::new([string]$plan.ssms)
 $start.UseShellExecute=$false;$start.WindowStyle=[Diagnostics.ProcessWindowStyle]::Maximized
 foreach($a in @($path,'-S',$builder.DataSource,'-d','master','-N','Mandatory','-dn','SSIS-LAB-QUALIFICATION','-nosplash')){$start.ArgumentList.Add($a)}
 if($builder.TrustServerCertificate){$start.ArgumentList.Add('-C')}
 $script:ssmsTargetApp=[Diagnostics.Process]::Start($start)
 $script:ssmsTargetStarted=$script:ssmsTargetApp.StartTime.ToUniversalTime().ToString('o')
 Save-ClientPrivate ($JournalPath+'.preflight-ready.json') @{state='SSMS_TARGET_PREFLIGHT';ssmsPid=$script:ssmsTargetApp.Id;sqlPath=$path;querySha256=(Get-ClientHash $path);visualPath=($JournalPath+'.preflight-visual.json');displayName='SSIS-LAB-QUALIFICATION';database='master';databaseNotCreated=$true}
 $journal.state='WAITING_FOR_TARGET_PREFLIGHT';Save
 $limit=[datetimeoffset]::UtcNow.AddSeconds(600)
 if($limit-gt (Get-SsmsDeadline).AddSeconds(-600)){$limit=(Get-SsmsDeadline).AddSeconds(-600)}
 while([datetimeoffset]::UtcNow-lt $limit){
  if($script:ssmsTargetApp.HasExited){throw 'SSMS_PREFLIGHT_CLOSED'}
  if(Test-Path ($JournalPath+'.preflight-visual.json')){
   $v=Get-Content ($JournalPath+'.preflight-visual.json') -Raw|ConvertFrom-Json -DateKind String
   Check ($v.result-ceq 'PASS' -and $v.querySha256-ceq (Get-ClientHash $path) -and $v.targetMatched-is [bool] -and $v.targetMatched -and $v.windowsAuth-is [bool] -and $v.windowsAuth -and $v.encrypted-is [bool] -and $v.encrypted) 'VISIBLE_SSMS_TARGET_PREFLIGHT'
   $journal.preflight=@{targetMatched=$true;windowsAuthentication=$true;encrypted=$true;sameOwnedSsmsInstance=$true};Save
   return
  }
  Start-Sleep -Milliseconds 500
 }
 throw 'SSMS_TARGET_PREFLIGHT_NOT_COMPLETED'
}
