#requires -Version 7.0
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ConnectionStringEnvironmentVariable,
 [Parameter(Mandatory)][int]$ExpectedDatabaseId,
 [Parameter(Mandatory)][byte[]]$ExpectedDatabaseCreatedBytes,
 [Parameter(Mandatory)][string]$ExpectedDatabaseRunMarkerName,
 [Parameter(Mandatory)][guid]$ExpectedRunId
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Runs only inside the parent fixture's identified disposable database. Two
# nonpooled sessions exercise the real handler binding and rollback protocol.
$clock=[Diagnostics.Stopwatch]::StartNew();$control=$null;$handler=$null;$historyPhase='preflight'
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Json) {
 if($clock.Elapsed.TotalSeconds-ge120){throw 'HISTORY.DEADLINE'}
 $cmd=$Connection.CreateCommand();$cmd.CommandText=$Text;$cmd.CommandTimeout=10
 try {
  foreach($key in $Parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$Parameters[$key])}
  if($Json){
   $reader=$cmd.ExecuteReader()
   try {
    $result=[Text.StringBuilder]::new()
    while($reader.Read()){
     [void]$result.Append($reader.GetString(0))
     if($result.Length-gt4194304){throw 'HISTORY.SNAPSHOT_LIMIT'}
    }
    return $result.ToString()
   }finally{$reader.Dispose()}
  }
  return ,$cmd.ExecuteScalar()
 }finally{$cmd.Dispose()}
}
function Open-OwnedConnection {
 $value=[Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable,'Process')
 if([string]::IsNullOrWhiteSpace($value)){throw 'HISTORY.CONNECTION_MISSING'}
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($value);$value=$null
 $builder['Pooling']=$false;$builder['Enlist']=$false;$builder['Connect Timeout']=10
 $c=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$builder.Clear()
 try {
  $c.Open()
  [void](Sql $c @'
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 OR DB_ID()<>@Id
 OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND TRY_CONVERT(uniqueidentifier,value)=@Run)
 THROW 54970,N'Terminal history fixture identity mismatch.',1;
SELECT 1;
'@ @{'@Id'=$ExpectedDatabaseId;'@Created'=$ExpectedDatabaseCreatedBytes;'@Marker'=$ExpectedDatabaseRunMarkerName;'@Run'=$ExpectedRunId})
  return $c
 }catch{$c.Dispose();throw}
}
function Expect-Stale($Connection,[string]$Text,[hashtable]$Parameters,[int]$Number,[int]$State) {
 try{[void](Sql $Connection $Text $Parameters)}catch{
  $e=$_.Exception
  while($null-ne$e-and$e-isnot[Data.SqlClient.SqlException]){$e=$e.InnerException}
  if($null-ne$e-and$e.Number-eq$Number-and$e.State-eq$State){return}
  throw 'HISTORY.WRONG_REJECTION'
 }
 throw 'HISTORY.STALE_AUTHORITY_ACCEPTED'
}
try {
 $control=Open-OwnedConnection
 [void](Sql $control 'IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1) THROW 54970,N''History fixture requires quiescence.'',2; CREATE TABLE dbo.TbxTerminalHistoryEffect(Value int NOT NULL);')
 [void](Sql $control 'CREATE OR ALTER PROCEDURE dbo.USP_TbxTerminalHistoryNone AS BEGIN SET NOCOUNT ON; END;')
 # Temp tables must be created in a nonparameterized outer batch: SqlClient
 # executes parameterized text in an RPC scope that would discard new tables.
 [void](Sql $control 'CREATE TABLE #HistoryWorker(Dummy int NULL); CREATE TABLE #HistoryClaim(Dummy int NULL); CREATE TABLE #HistoryResult(Dummy int NULL);')
 $historyPhase='registration'
 [void](Sql $control @'
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.history',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxTerminalHistoryNone',@ParameterMode='NONE';
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='test.worker.history',@Principal=N'dbo',@PermissionName='ENQUEUE';
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='test.worker.history',@Principal=N'dbo',@PermissionName='CLAIM';
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@Worker,@Capacity=1,@RunMode='BOUNDED',@ResultTable=N'#HistoryWorker';
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName='test.worker.history',@MaxAttempts=1,@ResultTable=N'#HistoryResult';
'@ @{'@Worker'=[guid]::NewGuid()})
 # Compile observations only after the ResultTable helper has prepared schema.
 $historyPhase='claim'
 [void](Sql $control @'
DECLARE @Worker uniqueidentifier,@Generation bigint,@Token uniqueidentifier;
SELECT @Worker=WorkerId,@Generation=WorkerGeneration,@Token=WorkerToken FROM #HistoryWorker;
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@Worker,@WorkerGeneration=@Generation,@WorkerToken=@Token,@ResultTable=N'#HistoryClaim';
'@)
 # Values stay in memory; neither tokens nor live rows are emitted as evidence.
 $binding=Sql $control @'
IF (SELECT COUNT(*) FROM #HistoryClaim)<>1 OR EXISTS(SELECT 1 FROM #HistoryClaim WHERE WorkTypeName<>'test.worker.history') THROW 54970,N'History claim mismatch.',3;
SELECT c.SlotReservationId,c.ClaimGeneration,c.ClaimToken,c.ExecutionId,w.WorkerId,w.WorkerGeneration,w.WorkerToken
 FROM #HistoryClaim c CROSS JOIN #HistoryWorker w FOR JSON PATH,WITHOUT_ARRAY_WRAPPER;
'@ -Json
 $b=$binding|ConvertFrom-Json
 $parameters=@{'@Slot'=[guid]$b.SlotReservationId;'@Claim'=[guid]$b.ClaimToken;'@Execution'=[guid]$b.ExecutionId}
 $historyPhase='handler-rollback'
 $handler=Open-OwnedConnection
 [void](Sql $handler @'
EXEC toolbelt_core.USP_BindWorkerExecution @SlotReservationId=@Slot,@WorkerId=@Worker,@WorkerGeneration=@Generation,@WorkerToken=@Token,@ClaimGeneration=@ClaimGeneration,@ClaimToken=@Claim,@ExecutionId=@Execution;
BEGIN TRANSACTION;
EXEC toolbelt_core.USP_BeginWorkerTransactionWitness @SlotReservationId=@Slot,@ClaimToken=@Claim,@ExecutionId=@Execution;
INSERT dbo.TbxTerminalHistoryEffect VALUES(1);
ROLLBACK TRANSACTION;
IF EXISTS(SELECT 1 FROM dbo.TbxTerminalHistoryEffect) THROW 54970,N'Actual rollback effect remains.',4;
EXEC toolbelt_core.USP_RecordWorkerRollback @SlotReservationId=@Slot,@ClaimToken=@Claim,@ExecutionId=@Execution;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Slot AND State='ROLLED_BACK' AND IsOccupied=1 AND EndedAtUtc IS NULL) THROW 54970,N'Rollback proof prematurely released slot.',5;
'@ ($parameters+@{'@Worker'=[guid]$b.WorkerId;'@Generation'=[long]$b.WorkerGeneration;'@Token'=[guid]$b.WorkerToken;'@ClaimGeneration'=[long]$b.ClaimGeneration}))
 $finalize="DECLARE @Outcome varchar(24); EXEC toolbelt_core.USP_FinalizeWorkerFailure @SlotReservationId=@Slot,@ClaimToken=@Claim,@ExecutionId=@Execution,@FailureCode='TEST.HISTORY',@Retry=1,@Outcome=@Outcome OUTPUT; IF @Outcome<>'DEAD_LETTER' THROW 54970,N'Expected terminal dead letter.',6;"
 $historyPhase='finalize'
 [void](Sql $handler $finalize $parameters)
 $snapshotSql=@'
SELECT SlotReservationId,WorkerId,WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,ExecutionId,AttemptNonce,BoundPrincipalId,State,IsOccupied,CreatedAtUtc,EndedAtUtc
 FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Slot FOR JSON PATH;
'@
 $terminal=Sql $control $snapshotSql $parameters -Json
 [void](Sql $control "IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Slot AND State='ROLLED_BACK' AND IsOccupied=0 AND EndedAtUtc IS NOT NULL) THROW 54970,N'Terminal slot not released.',7;" $parameters)
 Expect-Stale $handler $finalize $parameters 54220 2
 $handler.Dispose();$handler=$null
 $historyPhase='terminal-reconcile'
 $hold=Sql $control 'SELECT CONVERT(varchar(18),HoldVersion,1) FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@Slot;' $parameters
 $reconcile="DECLARE @Version binary(8)=CONVERT(binary(8),@Hold,1); EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Version,@ResultTable=N'#HistoryResult';"
 foreach($iteration in 1..2){
  [void](Sql $control $reconcile ($parameters+@{'@Hold'=$hold}))
  [void](Sql $control "IF NOT EXISTS(SELECT 1 FROM #HistoryResult WHERE SlotReservationId=@Slot AND Outcome='ROLLED_BACK' AND Occupied=0) THROW 54970,N'Terminal reconcile changed outcome.',8;" $parameters)
  if((Sql $control $snapshotSql $parameters -Json)-cne$terminal){throw 'HISTORY.TERMINAL_RESERVATION_CHANGED'}
 }
 $historyPhase='successor'
 [void](Sql $control @'
DECLARE @Item bigint=(SELECT WorkItemId FROM #HistoryClaim),@Version binary(8),@Worker uniqueidentifier,@Generation bigint,@Token uniqueidentifier;
SELECT @Version=RowVersion FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item;
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@Item,@ExpectedRowVersion=@Version,@RequeueReason=N'synthetic terminal history',@ResultTable=N'#HistoryResult';
SELECT @Worker=WorkerId,@Generation=WorkerGeneration,@Token=WorkerToken FROM #HistoryWorker;
EXEC toolbelt_core.USP_HeartbeatWorker @WorkerId=@Worker,@WorkerGeneration=@Generation,@WorkerToken=@Token;
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@Worker,@WorkerGeneration=@Generation,@WorkerToken=@Token,@ResultTable=N'#HistoryClaim';
IF (SELECT COUNT(*) FROM #HistoryClaim)<>1 OR NOT EXISTS(SELECT 1 FROM #HistoryClaim WHERE WorkItemId=@Item AND SlotReservationId<>@Slot AND ClaimGeneration>@GenerationBefore) THROW 54970,N'Successor claim mismatch.',9;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Slot AND State='ROLLED_BACK' AND IsHeld=0 AND HoldVersion IS NULL AND StopStatus='NONE') THROW 54970,N'Historical view borrowed successor disposition.',10;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.VW_WorkerExecutionStatus v JOIN #HistoryClaim c ON c.SlotReservationId=v.SlotReservationId WHERE v.State='RESERVED' AND v.IsHeld=0 AND v.HoldVersion IS NOT NULL AND v.StopStatus='NONE') THROW 54970,N'Successor view missing current disposition.',11;
'@ ($parameters+@{'@GenerationBefore'=[long]$b.ClaimGeneration}))
 if((Sql $control $snapshotSql $parameters -Json)-cne$terminal){throw 'HISTORY.SUCCESSOR_CHANGED_HISTORY'}
 $allSql=@'
SELECT (SELECT SlotReservationId,WorkerId,WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,ExecutionId,AttemptNonce,BoundPrincipalId,State,IsOccupied,CreatedAtUtc,EndedAtUtc FROM toolbelt_core.WorkerSlotReservation ORDER BY SlotReservationId FOR JSON PATH) Reservations,
 (SELECT WorkItemId,SlotReservationId,IsHeld,HoldVersion,StopStatus FROM toolbelt_core.WorkerExecutionDisposition ORDER BY WorkItemId FOR JSON PATH) Dispositions,
 (SELECT WorkItemId,Status,ClaimGeneration,ClaimToken,ManagedReservationId,ManagedHold,ManagedCompletionNonce,RowVersion,LeaseUntilUtc FROM toolbelt_core.WorkItem ORDER BY WorkItemId FOR JSON PATH) Items FOR JSON PATH;
'@
 $before=Sql $control $allSql -Json
 $historyPhase='stale-reconcile'
 Expect-Stale $control $reconcile ($parameters+@{'@Hold'=$hold}) 54227 2
 if((Sql $control $allSql -Json)-cne$before){throw 'HISTORY.STALE_RECONCILE_CHANGED_CURRENT_ATTEMPT'}
 $historyPhase='successor-cleanup'
 [void](Sql $control @'
DECLARE @NewSlot uniqueidentifier,@Generation bigint,@Version binary(8);
SELECT @NewSlot=SlotReservationId,@Generation=ClaimGeneration FROM #HistoryClaim;
EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@NewSlot,@ExpectedClaimGeneration=@Generation,@ResultTable=N'#HistoryResult';
SELECT @Version=HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@NewSlot;
EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@NewSlot,@ExpectedHoldVersion=@Version,@ResultTable=N'#HistoryResult';
'@)
 [void](Sql $control "IF (SELECT COUNT(*) FROM #HistoryResult)<>1 OR NOT EXISTS(SELECT 1 FROM #HistoryResult r JOIN #HistoryClaim c ON c.SlotReservationId=r.SlotReservationId WHERE r.Outcome='ROLLED_BACK_HELD' AND r.Occupied=0) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1) THROW 54970,N'Successor cleanup not terminal.',12;")
 'PASS: terminal history; real rollback, failure finalization, repeated reconcile, successor isolation and stale rejection.'
}catch{
 $cause=$_.Exception
 while($null-ne$cause-and$cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
 if($null-ne$cause){
  # Fixed phase and numeric fields only; never SQL messages, tokens or endpoints.
  Write-Information "HISTORY_SQL_FAILURE phase=$historyPhase number=$($cause.Number) state=$($cause.State) line=$($cause.LineNumber)" -InformationAction Continue
 }
 throw
}finally{
 if($null-ne$handler){$handler.Dispose()}
 if($null-ne$control){$control.Dispose()}
}
