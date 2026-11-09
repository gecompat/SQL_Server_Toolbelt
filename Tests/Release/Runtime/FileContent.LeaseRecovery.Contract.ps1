# Nur eine eigene ruhende AppLock-Haltersitzung beenden; keine Mutation unterbrechen.
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'LifecycleProfiles.Contract.ps1') @(
 'Get-FileLifecycleState','Assert-FileLifecycleAbsent')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'FileContent.LockProfiles.Contract.ps1') @('Assert-FileLockHeld')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @(
 'Read-Scalar','Get-ExternalSessionState','Get-ContenderStateSamples','Test-ExternalSessionIdle','Test-ContenderStateIdle')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Assert-FileRecoveryIdentity($Observed,$Worker){
 $guid=[guid]::Empty
 # Die DMV-Abfrage kann im eigenen lesenden Statement XACT_STATE()=1 zeigen,
 # obwohl kein BEGIN TRANSACTION vorliegt. Benutzertransaktionen bleiben durch
 # @@TRANCOUNT und danach extern open_transaction_count=0/keinen Request ausgeschlossen.
 if(@($Observed).Count-ne1-or$Observed[0].DatabaseId-ne$Worker.DatabaseId-or$Observed[0].TranCount-ne0-or
    $Observed[0].XactState-notin@(0,1)-or-not[guid]::TryParse([string]$Observed[0].ConnectionId,[ref]$guid)-or$guid-eq[guid]::Empty){
  throw 'FILE_RECOVERY_IDLE_CONNECTION_REQUIRED'
 }
}
function Get-FileRecoveryKillSql([int]$LeaseSpid,[int]$WorkerSpid,[int]$DatabaseId){
 if($LeaseSpid-le50-or$WorkerSpid-le50-or$LeaseSpid-eq$WorkerSpid-or$DatabaseId-le4){throw 'FILE_RECOVERY_OWN_SEPARATE_SESSION_REQUIRED'}
 # SPID/DB-ID sind typisierte positive Zahlen. GUID und Zufallstag bleiben Parameter.
 # Die letzte serverseitige Prüfung schließt fremde, aktive und transaktionale Sitzungen aus.
 return @"
IF @@SPID=$LeaseSpid OR NOT EXISTS(
 SELECT 1 FROM sys.dm_exec_sessions s JOIN sys.dm_exec_connections c ON c.session_id=s.session_id
 WHERE s.session_id=$LeaseSpid AND s.database_id=$DatabaseId AND s.is_user_process=1
 AND c.connection_id=TRY_CONVERT(uniqueidentifier,@ConnectionId)
 AND s.context_info=@OwnerTag AND s.open_transaction_count=0
 AND NOT EXISTS(SELECT 1 FROM sys.dm_exec_requests r WHERE r.session_id=s.session_id))
 THROW 52099,N'Owned idle lease identity changed; termination refused.',1;
KILL $LeaseSpid;
"@
}
function Invoke-FileRecoveryProfiles($Db,[string]$Mode){
 $worker=@(Invoke-ReleaseSql $Db 'SELECT @@SPID Spid,DB_ID() DatabaseId;' -Rows)
 if($worker.Count-ne1){throw 'FILE_RECOVERY_WORKER_REQUIRED'}
 foreach($operation in @('deploy','uninstall')){
  $before=Get-FileLifecycleState $Db
  $lease=Open-ReleaseConnection $Db.Database
  $receipt=[ordered]@{mode=$Mode;operation=$operation;workerSession=[int]$worker[0].Spid;leaseSession=$null;connectionId=$null;
   acquired=$false;idleIdentityVerified=$false;killed=$false;originalConnectionGone=$false;lockAvailable=$false;recovered=$false}
  $ledger.recoveryReceipts+=@($receipt);Save-ReleaseJournal
  try{
   $token=[guid]::NewGuid().ToByteArray()
   Invoke-ReleaseSql $lease 'SET CONTEXT_INFO @OwnerTag;' @{'@OwnerTag'=$token}
   $identity=@(Invoke-ReleaseSql $lease "SELECT @@SPID Spid,DB_ID() DatabaseId,@@TRANCOUNT TranCount,XACT_STATE() XactState,CONVERT(nvarchar(36),connection_id) ConnectionId FROM sys.dm_exec_connections WHERE session_id=@@SPID;" -Rows)
   $receipt['identityObservation']=@($identity);Save-ReleaseJournal
   Assert-FileRecoveryIdentity $identity $worker[0]
   $kill=Get-FileRecoveryKillSql $identity[0].Spid $worker[0].Spid $worker[0].DatabaseId
   $acquired=@(Invoke-ReleaseSql $lease "DECLARE @R int;EXEC @R=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.content',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';SELECT @R Result;" -Rows)
   if($acquired.Count-ne1-or$acquired[0].Result-lt0){throw 'FILE_RECOVERY_ACQUIRE_FAILED'}
   $receipt.acquired=$true;$receipt.leaseSession=Assert-FileLockHeld $lease $receipt.workerSession
   $receipt.connectionId=$identity[0].ConnectionId
   if((Get-FileLifecycleState $Db)-cne$before){throw 'FILE_RECOVERY_LEASE_MUTATED_PRODUCT'}
   $available=@(Invoke-ReleaseSql $Db "SELECT APPLOCK_TEST(N'public',N'toolbelt.deploy.toolbelt.file.content',N'Exclusive',N'Session') Available;" -Rows)
   if($available.Count-ne1-or$available[0].Available-ne0){throw 'FILE_RECOVERY_CONFLICT_NOT_ESTABLISHED'}
   Invoke-ReleaseSql $control $kill @{'@ConnectionId'=$identity[0].ConnectionId;'@OwnerTag'=$token}
   $receipt.idleIdentityVerified=$true;$receipt.killed=$true;Save-ReleaseJournal
   $wait=[Diagnostics.Stopwatch]::StartNew()
   do{
    $gone=@(Invoke-ReleaseSql $control 'SELECT COUNT(*) N FROM sys.dm_exec_connections WHERE connection_id=TRY_CONVERT(uniqueidentifier,@ConnectionId);' @{'@ConnectionId'=$identity[0].ConnectionId} -Rows)
    if($gone.Count-ne1){throw 'FILE_RECOVERY_CONNECTION_OBSERVER_SHAPE'}
    if($gone[0].N-ne0){Start-Sleep -Milliseconds 50}
   }while($gone[0].N-ne0-and$wait.ElapsedMilliseconds-lt5000)
   $available=@(Invoke-ReleaseSql $Db "SELECT APPLOCK_TEST(N'public',N'toolbelt.deploy.toolbelt.file.content',N'Exclusive',N'Session') Available;" -Rows)
   if($gone.Count-ne1-or$gone[0].N-ne0-or$available.Count-ne1-or$available[0].Available-ne1){throw 'FILE_RECOVERY_TERMINATION_OR_RELEASE_UNVERIFIED'}
   $receipt.originalConnectionGone=$true;$receipt.lockAvailable=$true;Save-ReleaseJournal
  }finally{$lease.Dispose()}
  if(-not$receipt.killed-or-not$receipt.lockAvailable){throw 'FILE_RECOVERY_LOSS_REQUIRED'}
  if($operation-ceq'deploy'){
   Invoke-ReleaseBatches $Db (Get-FileRecoveryText $Mode)
   if((Get-FileLifecycleState $Db)-cne$before){throw 'FILE_RECOVERY_DEPLOY_DRIFT'}
  }else{
   Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.file.content/Deployment/Uninstall.sql')))
   Assert-FileLifecycleAbsent $Db $false
  }
  # Das bestehende Orakel prüft die ruhende Sitzung extern und nimmt den
  # lokalen Zustand vor der lesenden SELECT-Transaktion in Variablen auf.
  # APPLOCK_MODE mit Transaction wäre ohne Benutzertransaktion selbst ungültig.
  $samples=Get-ContenderStateSamples $control $Db $worker[0].Spid
  $receipt['endSamples']=$samples;Save-ReleaseJournal
  if(-not(Test-ContenderStateIdle $samples $Db.State $worker[0].Spid)){throw 'FILE_RECOVERY_TRANSACTION_OR_LOCK_LEAK'}
  $receipt.recovered=$true
  $ledger.profileCompletions+=@(@{mode=$Mode;profile=$operation+'-after-idle-session-termination';unchanged=$true});Save-ReleaseJournal
 }
}
