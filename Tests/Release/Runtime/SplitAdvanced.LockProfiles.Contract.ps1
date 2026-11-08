# Originale öffentliche Skripte gegen eine eigene fremde Sitzungssperre prüfen.
# Bestehende Status-/Fehlerorakel werden quellgebunden wiederverwendet.
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'SplitAdvanced.LifecycleProfiles.Contract.ps1') @(
 'Get-SplitLifecycleState','Assert-SplitLifecycleDenied','Assert-SplitLifecycleAbsent')){. $block}
function Assert-SplitLockHeld($Lease,[int]$WorkerSpid){
 $rows=@(Invoke-ReleaseSql $Lease "SELECT @@SPID Spid,APPLOCK_MODE(N'public',N'toolbelt.deploy.toolbelt.string.split-advanced',N'Session') Mode;" -Rows)
 if($rows.Count-ne1-or$rows[0].Spid-le0-or$rows[0].Spid-eq$WorkerSpid-or$rows[0].Mode-cne'Exclusive'){
  throw 'SPLIT_LOCK_SEPARATE_EXCLUSIVE_LEASE_REQUIRED'
 }
 return [int]$rows[0].Spid
}
function Invoke-SplitLockProfiles($Db,[string]$Mode){
 $deploy=Get-SplitLockText $Mode
 $uninstall=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.string.split-advanced/Deployment/Uninstall.sql')).Replace('$(ConfirmNoExternalConsumers)','1')
 $worker=@(Invoke-ReleaseSql $Db 'SELECT @@SPID Spid;' -Rows)
 if($worker.Count-ne1-or$worker[0].Spid-le0){throw 'SPLIT_LOCK_WORKER_ID_REQUIRED'}
 $lease=Open-ReleaseConnection $Db.Database
 $receipt=[ordered]@{mode=$Mode;workerSession=[int]$worker[0].Spid;leaseSession=$null;acquired=$false;heldAfterDenials=$false;released=$false}
 $ledger.lockReceipts+=@($receipt);Save-ReleaseJournal
 try{
  $result=@(Invoke-ReleaseSql $lease "DECLARE @R int;EXEC @R=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.string.split-advanced',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';SELECT @R Result;" -Rows)
  if($result.Count-ne1-or$result[0].Result-lt0){throw 'SPLIT_LOCK_LEASE_ACQUIRE_FAILED'}
  $receipt.leaseSession=Assert-SplitLockHeld $lease $receipt.workerSession
  $receipt.acquired=$true;Save-ReleaseJournal
  Assert-SplitLifecycleDenied $Db $deploy 51677 'deploy-blocked-by-separate-session'
  Assert-SplitLifecycleDenied $Db $uninstall 51677 'uninstall-blocked-by-separate-session'
  if((Assert-SplitLockHeld $lease $receipt.workerSession)-ne$receipt.leaseSession){throw 'SPLIT_LOCK_SESSION_CHANGED'}
  $receipt.heldAfterDenials=$true;Save-ReleaseJournal
 }finally{
  try{
   if($receipt.acquired){
    $result=@(Invoke-ReleaseSql $lease "DECLARE @R int;EXEC @R=sys.sp_releaseapplock @Resource=N'toolbelt.deploy.toolbelt.string.split-advanced',@LockOwner=N'Session',@DbPrincipal=N'public';SELECT @R Result,APPLOCK_MODE(N'public',N'toolbelt.deploy.toolbelt.string.split-advanced',N'Session') Mode;" -Rows)
    if($result.Count-ne1-or$result[0].Result-lt0-or$result[0].Mode-cne'NoLock'){throw 'SPLIT_LOCK_LEASE_RELEASE_UNVERIFIED'}
    $receipt.released=$true;Save-ReleaseJournal
   }
  }finally{$lease.Dispose()}
 }
 # Nachgewiesene Freigabe ist ein neuer Sperrzustand, kein erneuter Full-Repeat.
 if(-not$receipt.released){throw 'SPLIT_LOCK_RELEASE_REQUIRED_BEFORE_RECOVERY'}
 $before=Get-SplitLifecycleState $Db
 Invoke-ReleaseBatches $Db $deploy
 if((Get-SplitLifecycleState $Db)-cne$before){throw 'SPLIT_LOCK_RELEASED_DEPLOY_DRIFT'}
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='deploy-after-verified-release';passed=$true});Save-ReleaseJournal
 Invoke-ReleaseBatches $Db $uninstall
 Assert-SplitLifecycleAbsent $Db $false
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='uninstall-after-verified-release';passed=$true});Save-ReleaseJournal
}
