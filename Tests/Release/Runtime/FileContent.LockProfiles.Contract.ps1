# Originale öffentliche Skripte gegen eine eigene fremde Sitzungssperre prüfen.
# Bestehende Status-/Fehlerorakel werden quellgebunden wiederverwendet.
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'LifecycleProfiles.Contract.ps1') @(
 'Get-FileLifecycleState','Assert-FileLifecycleDenied','Assert-FileLifecycleAbsent')){. $block}
function Assert-FileLockHeld($Lease,[int]$WorkerSpid){
 $rows=@(Invoke-ReleaseSql $Lease "SELECT @@SPID Spid,APPLOCK_MODE(N'public',N'toolbelt.deploy.toolbelt.file.content',N'Session') Mode;" -Rows)
 if($rows.Count-ne1-or$rows[0].Spid-le0-or$rows[0].Spid-eq$WorkerSpid-or$rows[0].Mode-cne'Exclusive'){
  throw 'FILE_LOCK_SEPARATE_EXCLUSIVE_LEASE_REQUIRED'
 }
 return [int]$rows[0].Spid
}
function Invoke-FileLockProfiles($Db,[string]$Mode){
 $deploy=Get-FileLockText $Mode
 $uninstall=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.file.content/Deployment/Uninstall.sql'))
 $worker=@(Invoke-ReleaseSql $Db 'SELECT @@SPID Spid;' -Rows)
 if($worker.Count-ne1-or$worker[0].Spid-le0){throw 'FILE_LOCK_WORKER_ID_REQUIRED'}
 $lease=Open-ReleaseConnection $Db.Database
 $receipt=[ordered]@{mode=$Mode;workerSession=[int]$worker[0].Spid;leaseSession=$null;acquired=$false;heldAfterDenials=$false;released=$false}
 $ledger.lockReceipts+=@($receipt);Save-ReleaseJournal
 try{
  $result=@(Invoke-ReleaseSql $lease "DECLARE @R int;EXEC @R=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.content',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';SELECT @R Result;" -Rows)
  if($result.Count-ne1-or$result[0].Result-lt0){throw 'FILE_LOCK_LEASE_ACQUIRE_FAILED'}
  $receipt.leaseSession=Assert-FileLockHeld $lease $receipt.workerSession
  $receipt.acquired=$true;Save-ReleaseJournal
  Assert-FileLifecycleDenied $Db $deploy 51277 'deploy-blocked-by-separate-session'
  Assert-FileLifecycleDenied $Db $uninstall 51277 'uninstall-blocked-by-separate-session'
  if((Assert-FileLockHeld $lease $receipt.workerSession)-ne$receipt.leaseSession){throw 'FILE_LOCK_SESSION_CHANGED'}
  $receipt.heldAfterDenials=$true;Save-ReleaseJournal
 }finally{
  try{
   if($receipt.acquired){
    $result=@(Invoke-ReleaseSql $lease "DECLARE @R int;EXEC @R=sys.sp_releaseapplock @Resource=N'toolbelt.deploy.toolbelt.file.content',@LockOwner=N'Session',@DbPrincipal=N'public';SELECT @R Result,APPLOCK_MODE(N'public',N'toolbelt.deploy.toolbelt.file.content',N'Session') Mode;" -Rows)
    if($result.Count-ne1-or$result[0].Result-lt0-or$result[0].Mode-cne'NoLock'){throw 'FILE_LOCK_LEASE_RELEASE_UNVERIFIED'}
    $receipt.released=$true;Save-ReleaseJournal
   }
  }finally{$lease.Dispose()}
 }
 # Nachgewiesene Freigabe ist ein neuer Sperrzustand, kein erneuter Full-Repeat.
 if(-not$receipt.released){throw 'FILE_LOCK_RELEASE_REQUIRED_BEFORE_RECOVERY'}
 $before=Get-FileLifecycleState $Db
 Invoke-ReleaseBatches $Db $deploy
 if((Get-FileLifecycleState $Db)-cne$before){throw 'FILE_LOCK_RELEASED_DEPLOY_DRIFT'}
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='deploy-after-verified-release';unchanged=$true});Save-ReleaseJournal
 Invoke-ReleaseBatches $Db $uninstall
 Assert-FileLifecycleAbsent $Db $false
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='uninstall-after-verified-release';unchanged=$true});Save-ReleaseJournal
}
