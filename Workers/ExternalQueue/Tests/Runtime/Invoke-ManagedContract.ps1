#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConnectionStringEnvironmentVariable,
    [Parameter(Mandatory)][int]$ExpectedDatabaseId,
    [Parameter(Mandatory)][datetime]$ExpectedDatabaseCreatedAt,
    [Parameter(Mandatory)][string]$ExpectedDatabaseRunMarkerName,
    [Parameter(Mandatory)][guid]$ExpectedRunId,
    [Parameter(Mandatory)][string]$EvidenceDirectory,
    [ValidateRange(30,600)][int]$MaxSeconds=180
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Der übergeordnete Labadapter installiert und besitzt eine frische Test-DB.
# Dieser fokussierte Verbraucher verwaltet keine DB, Trusts oder Labressourcen.
$clock=[Diagnostics.Stopwatch]::StartNew();$connection=$null
$workers=[Collections.Generic.List[object]]::new();$ownedConfig=$null
$primary=$null;$fixturePhase='preflight';$secondary=[Collections.Generic.List[string]]::new();$records=[Collections.Generic.List[object]]::new()
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
function Need([bool]$Condition,[string]$Code){if(-not $Condition){throw $Code}}
function Sql([string]$Text,[hashtable]$Parameters=@{},[switch]$Scalar,[switch]$Cleanup,[Diagnostics.Stopwatch]$ProbeClock=$null,[int]$ProbeSeconds=0) {
    if(-not $Cleanup){Need ($clock.Elapsed.TotalSeconds -lt $MaxSeconds) 'MANAGED.FIXTURE_DEADLINE'}
    $command=$connection.CreateCommand();$command.CommandText=$Text
    $command.CommandTimeout=if($Cleanup){5}else{[Math]::Max(1,[Math]::Min(10,[int][Math]::Ceiling($MaxSeconds-$clock.Elapsed.TotalSeconds)))}
    if($null-ne$ProbeClock){
        $probeTimeout=[int][Math]::Floor($ProbeSeconds-$ProbeClock.Elapsed.TotalSeconds)
        if($probeTimeout-lt1){$command.Dispose();throw 'MANAGED.RACE_PROBE_DEADLINE'}
        $command.CommandTimeout=$probeTimeout
    }
    try {
        foreach($key in $Parameters.Keys){[void]$command.Parameters.AddWithValue($key,$Parameters[$key])}
        if($Scalar){return ,$command.ExecuteScalar()}
        [void]$command.ExecuteNonQuery()
    }finally{$command.Dispose()}
}
function Wait([scriptblock]$Predicate,[string]$Code,[switch]$AllowUnknown,[Diagnostics.Stopwatch]$LocalClock=$null,[int]$LocalSeconds=0,$RendezvousWorker=$null) {
    while($true) {
        if($null-ne$LocalClock){Need ($LocalClock.Elapsed.TotalSeconds-lt$LocalSeconds) $Code}else{Need ($clock.Elapsed.TotalSeconds -lt $MaxSeconds) $Code}
        if(& $Predicate){break}
        if($null-ne$RendezvousWorker){
            foreach($entry in $RendezvousWorker.Shell.Streams.Information){
                if($entry.Tags-contains'ToolbeltQueueWorker' -and $entry.MessageData.Event-ceq'MANAGED_EXECUTION_ENDED'){throw 'MANAGED.RACE_ACTOR_ENDED_BEFORE_RENDEZVOUS'}
            }
        }
        if(-not $AllowUnknown){
            foreach($ownedWorker in $workers){
                foreach($entry in $ownedWorker.Shell.Streams.Information){
                    if($entry.Tags-contains'ToolbeltQueueWorker' -and $entry.MessageData.Event-ceq'MANAGED_EXECUTION_ENDED' -and $entry.MessageData.Outcome-ceq'UNKNOWN'){
                        throw 'MANAGED.UNEXPECTED_UNKNOWN'
                    }
                }
            }
        }
        if($null-ne$LocalClock){Need ($LocalClock.Elapsed.TotalSeconds-lt$LocalSeconds) $Code}else{Need ($clock.Elapsed.TotalSeconds -lt $MaxSeconds) $Code}
        [Threading.Thread]::Sleep(100)
    }
}
function Start-ManagedFixture([int]$Capacity=2,[string]$Mode='CONTINUOUS',[int]$Claims=10,[int]$RunSeconds=60) {
    $stop=Join-Path $EvidenceDirectory ([guid]::NewGuid().ToString('N')+'.stop')
    $arguments=@{ConnectionStringEnvironmentVariable=$ConnectionStringEnvironmentVariable
        WorkerEligibleWorkTypes=@('test.managed.long','test.managed.short');Managed=$true
        WorkerId=[guid]::NewGuid();Capacity=$Capacity;RunMode=$Mode;MaxRunSeconds=$RunSeconds
        MaxClaims=$Claims;PollSeconds=0.1;StopFile=$stop;ControlTimeoutSeconds=5;ConnectTimeoutSeconds=5}
    $shell=[powershell]::Create()
    [void]$shell.AddScript('param($path,$arguments) Import-Module $path -Force; Start-ExternalQueueWorker @arguments').AddArgument((Join-Path $root 'ExternalQueueWorker.psm1')).AddArgument($arguments)
    $handle=[pscustomobject]@{Shell=$shell;Task=$null;Stop=$stop;StopCreated=$false;StopCreatedAt=$null;Result=$null;WorkerId=$arguments.WorkerId;Ended=$false;Disposed=$false}
    $workers.Add($handle);$handle.Task=$shell.BeginInvoke();return $handle
}
function End-ManagedFixture($Handle) {
    if(-not $Handle.StopCreated) {
        $stream=[IO.File]::Open($Handle.Stop,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$stream.Dispose()
        $Handle.StopCreated=$true;$Handle.StopCreatedAt=[IO.File]::GetCreationTimeUtc($Handle.Stop)
    }
    $joinClock=[Diagnostics.Stopwatch]::StartNew()
    Wait {$Handle.Task.IsCompleted} 'MANAGED.WORKER_END_UNKNOWN' -AllowUnknown -LocalClock $joinClock -LocalSeconds 90
    $result=$Handle.Shell.EndInvoke($Handle.Task);$Handle.Result=$result;$Handle.Ended=$true
    Need (-not $Handle.Shell.HadErrors -and $result.Count -eq 1) 'MANAGED.WORKER_RESULT'
    $Handle.Shell.Dispose();$Handle.Disposed=$true
    return $result[0]
}
function Budget([int]$Value) {
    $version=Sql 'SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;' -Scalar
    if($null -ne $ownedConfig){Need ([Convert]::ToHexString($version) -ceq [Convert]::ToHexString($ownedConfig)) 'MANAGED.CONFIG_DRIFT'}
    Sql 'EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=@Value,@ExpectedConfigVersion=@Version;' @{'@Value'=$Value;'@Version'=$version}
    $script:ownedConfig=Sql 'SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;' -Scalar
}
function Record([string]$Case){$records.Add([pscustomobject]@{Case=$Case;Outcome='PASS'})}
try {
    Need ([IO.Directory]::Exists($EvidenceDirectory) -and @(Get-ChildItem -LiteralPath $EvidenceDirectory -Force).Count -eq 0) 'MANAGED.EVIDENCE_NOT_FRESH'
    $text=[Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable)
    Need (-not [string]::IsNullOrWhiteSpace($text)) 'MANAGED.CONNECTION_UNAVAILABLE'
    $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($text)
    Need $builder.Encrypt 'MANAGED.ENCRYPTION_REQUIRED'
    $builder.Pooling=$false;$builder.Enlist=$false;$builder.ConnectRetryCount=0;$builder['Connect Timeout']=5
    $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$connection.Open();$text=$null
    $fixturePhase='own-database-guard'
    $guard=Sql @'
SELECT CASE WHEN DB_ID()=@Id AND DB_ID()>4
 AND EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND create_date=@Created)
 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker
 AND TRY_CONVERT(uniqueidentifier,value)=@Run) THEN 1 ELSE 0 END;
'@ @{'@Id'=$ExpectedDatabaseId;'@Created'=$ExpectedDatabaseCreatedAt;'@Marker'=$ExpectedDatabaseRunMarkerName;'@Run'=$ExpectedRunId} -Scalar
    Need ($guard -eq 1) 'MANAGED.OWN_DATABASE_GUARD'
    Need ((Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkItem;' -Scalar) -eq 0 -and
        (Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerRegistration;' -Scalar) -eq 0) 'MANAGED.FRESH_DATABASE_REQUIRED'
    $fixturePhase='synthetic-handlers'
    Sql 'IF OBJECT_ID(N''dbo.TbxManagedEffects'') IS NOT NULL OR OBJECT_ID(N''dbo.USP_TbxManagedLong'') IS NOT NULL OR OBJECT_ID(N''dbo.USP_TbxManagedShort'') IS NOT NULL THROW 50000,N''Synthetic fixture collision'',1; CREATE TABLE dbo.TbxManagedEffects(WorkItemId bigint NOT NULL PRIMARY KEY);'
    Sql @'
CREATE PROCEDURE dbo.USP_TbxManagedLong AS
BEGIN SET NOCOUNT ON;
 INSERT dbo.TbxManagedEffects VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')));
 WAITFOR DELAY '00:00:30';
END;
'@
    Sql @'
CREATE PROCEDURE dbo.USP_TbxManagedShort AS
BEGIN SET NOCOUNT ON;
 INSERT dbo.TbxManagedEffects VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')));
 RETURN 7;
END;
'@
    Sql "EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.managed.long',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxManagedLong',@ParameterMode='NONE'; EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.managed.short',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxManagedShort',@ParameterMode='NONE';"
    $fixturePhase='enable-budget'
    $beforeBudget=[int](Sql 'SELECT MaxConcurrentExecutions FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;' -Scalar)
    $beforeEnabled=[bool](Sql 'SELECT ManagedEnabled FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1;' -Scalar)
    Need (-not $beforeEnabled) 'MANAGED.FRESH_DISABLED_GATE_REQUIRED'
    $version=Sql 'SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;' -Scalar
    Sql 'EXEC toolbelt_core.USP_EnableManagedWorkers @ExpectedConfigVersion=@Version;' @{'@Version'=$version}
    $ownedConfig=Sql 'SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;' -Scalar
    Budget 0
    $fixturePhase='empty-modes'
    $emptyWorker=Start-ManagedFixture -Capacity 1 -Mode BOUNDED -RunSeconds 1
    Wait {$emptyWorker.Task.IsCompleted} 'MANAGED.EMPTY_BOUNDED_END'
    $emptySummary=End-ManagedFixture $emptyWorker
    Need ($emptySummary.Status-ceq'COMPLETED' -and $emptySummary.Claims-eq0 -and $emptySummary.Completed-eq0 -and $emptySummary.Unresolved-eq0) 'MANAGED.EMPTY_BOUNDED_ORACLE'
    Record 'EMPTY_BOUNDED_END'
    $worker=Start-ManagedFixture -Capacity 1 -RunSeconds 1
    $otherWorker=Start-ManagedFixture -Capacity 1 -RunSeconds 1
    Wait {(Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerRegistration WHERE WorkerId IN(@First,@Second);' @{'@First'=$worker.WorkerId;'@Second'=$otherWorker.WorkerId} -Scalar) -eq 2} 'MANAGED.REGISTRATION_WAIT'
    [Threading.Thread]::Sleep(1300)
    Need (-not $worker.Task.IsCompleted -and -not $otherWorker.Task.IsCompleted -and (Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkItem;' -Scalar)-eq0) 'MANAGED.EMPTY_CONTINUOUS_ORACLE'
    Record 'EMPTY_CONTINUOUS_WAIT_TWO_SUPERVISORS'
    $fixturePhase='worker-admission'
    Sql "EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.managed.long';EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.managed.long';"
    Need ((Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation;' -Scalar) -eq 0) 'MANAGED.ZERO_BUDGET_ADMITTED'
    Record 'ZERO_BUDGET'
    $fixturePhase='budget-two'
    Budget 2
    Wait {(Sql "SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE State='RUNNING' AND IsOccupied=1;" -Scalar) -eq 2} 'MANAGED.BUDGET_TWO_WAIT'
    Need ((Sql 'SELECT COUNT(DISTINCT WorkerId) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1 AND WorkerId IN(@First,@Second);' @{'@First'=$worker.WorkerId;'@Second'=$otherWorker.WorkerId} -Scalar)-eq2) 'MANAGED.TWO_SUPERVISORS_ADMITTED'
    Need ((Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1;' -Scalar) -eq 2) 'MANAGED.GLOBAL_BUDGET'
    # Dirty Read belegt nur den Start eigener uncommitted Handlerwirkungen.
    # Rollback-/Commit-/Endnachweise verwenden weiterhin sperrende Abfragen.
    Wait {(Sql 'SELECT COUNT_BIG(*) FROM dbo.TbxManagedEffects WITH(READUNCOMMITTED);' -Scalar)-eq2} 'MANAGED.HANDLERS_ACTUALLY_STARTED'
    Budget 1
    Need ((Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1;' -Scalar) -eq 2) 'MANAGED.REDUCTION_CANCELLED_WORK'
    Record 'LIVE_BUDGET_TWO_REDUCED_WITHOUT_CANCEL'
    $stop=Sql "SELECT TOP(1) CONVERT(varchar(36),SlotReservationId)+'|'+CONVERT(varchar(20),ClaimGeneration) FROM toolbelt_core.WorkerSlotReservation WHERE State='RUNNING' ORDER BY WorkItemId;" -Scalar
    $parts=$stop.Split('|');$reservation=[guid]$parts[0];$generation=[long]$parts[1]
    Sql 'EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@Id,@ExpectedClaimGeneration=@Generation;' @{'@Id'=$reservation;'@Generation'=$generation}
    Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id AND StopStatus=''ROLLED_BACK_HELD'' AND IsHeld=1;' @{'@Id'=$reservation} -Scalar) -eq 1} 'MANAGED.STOP_ROLLBACK_HOLD_WAIT'
    Need ((Sql 'SELECT COUNT(*) FROM dbo.TbxManagedEffects WHERE WorkItemId=(SELECT WorkItemId FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id);' @{'@Id'=$reservation} -Scalar) -eq 0) 'MANAGED.CANCEL_EFFECT_NOT_ROLLED_BACK'
    Record 'ACTUAL_CANCEL_ROLLBACK_HELD'
    $stoppedWorkerId=Sql 'SELECT WorkerId FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id;' @{'@Id'=$reservation} -Scalar
    $stoppedWorker=if($stoppedWorkerId-eq$worker.WorkerId){$worker}else{$otherWorker}
    $releaseWorker=if($stoppedWorkerId-eq$worker.WorkerId){$otherWorker}else{$worker}
    $otherOriginalReservation=Sql 'SELECT SlotReservationId FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@Worker;' @{'@Worker'=$releaseWorker.WorkerId} -Scalar
    $otherOriginalItem=[long](Sql 'SELECT WorkItemId FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id AND WorkerId=@Worker;' @{'@Id'=$otherOriginalReservation;'@Worker'=$releaseWorker.WorkerId} -Scalar)
    [void](End-ManagedFixture $stoppedWorker)
    $fixturePhase='explicit-release'
    $heldItem=[long](Sql 'SELECT WorkItemId FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id;' @{'@Id'=$reservation} -Scalar)
    $holdVersion=Sql 'SELECT HoldVersion FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id;' @{'@Id'=$reservation} -Scalar
    # Korrektur erfolgt im registrierten Handler; kein Payload enthält SQL.
    # Den registrierten Handler erst ändern, wenn der andere ursprüngliche
    # Attempt belegt committed und beendet ist; keine Definition im Lauf ändern.
    $fixturePhase='explicit-release-original-end'
    Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation r JOIN toolbelt_core.WorkItem w ON w.WorkItemId=r.WorkItemId WHERE r.SlotReservationId=@Id AND r.WorkerId=@Worker AND r.WorkItemId=@Item AND r.State=''COMMITTED'' AND r.IsOccupied=0 AND w.Status=''COMPLETED'' AND w.ManagedReservationId=r.SlotReservationId AND w.ClaimGeneration=r.ClaimGeneration;' @{'@Id'=$otherOriginalReservation;'@Worker'=$releaseWorker.WorkerId;'@Item'=$otherOriginalItem} -Scalar)-eq1} 'MANAGED.ORIGINAL_OTHER_COMMIT_WAIT'
    $fixturePhase='explicit-release-handler'
    Sql "ALTER PROCEDURE dbo.USP_TbxManagedLong AS BEGIN SET NOCOUNT ON; INSERT dbo.TbxManagedEffects VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id'))); RETURN 7; END;"
    $fixturePhase='explicit-release-publish'
    Sql 'EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Version;' @{'@Item'=$heldItem;'@Version'=$holdVersion}
    Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status=''COMPLETED'';' @{'@Item'=$heldItem} -Scalar) -eq 1} 'MANAGED.EXPLICIT_RELEASE_WAIT'
    Need ((Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkItemId=@Item AND WorkerId=@Worker AND State=''COMMITTED'' AND IsOccupied=0;' @{'@Item'=$heldItem;'@Worker'=$releaseWorker.WorkerId} -Scalar)-eq1) 'MANAGED.RELEASE_OTHER_WORKER'
    Record 'EXPLICIT_RELEASE_OTHER_REGISTERED_WORKER'
    $fixturePhase='legacy-bypass'
    $bypass=Sql @'
BEGIN TRY EXEC toolbelt_core.USP_ClaimWork;SELECT CONVERT(int,0);END TRY
 BEGIN CATCH SELECT CONVERT(int,CASE WHEN ERROR_NUMBER()=54200 THEN 1 ELSE 0 END);END CATCH;
'@ -Scalar
    Need ($bypass -eq 1) 'MANAGED.LEGACY_BYPASS_NOT_REJECTED'
    Record 'LEGACY_CLAIM_REJECTED'
    Wait {(Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1;' -Scalar) -eq 0} 'MANAGED.ALL_EXECUTIONS_END_WAIT'
    # Der bereits committed Attempt darf ein späteres Stop nicht in Hold drehen.
    $fixturePhase='late-stop'
    $completed=Sql 'SELECT TOP(1) CONVERT(varchar(36),SlotReservationId)+''|''+CONVERT(varchar(20),ClaimGeneration) FROM toolbelt_core.WorkerSlotReservation WHERE WorkItemId=@Item ORDER BY ClaimGeneration DESC;' @{'@Item'=$heldItem} -Scalar
    $parts=$completed.Split('|')
    Sql 'EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@Id,@ExpectedClaimGeneration=@Generation;' @{'@Id'=[guid]$parts[0];'@Generation'=[long]$parts[1]}
    Need ((Sql 'SELECT COUNT(*) FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id AND StopStatus=''ALREADY_COMMITTED'' AND IsHeld=0;' @{'@Id'=[guid]$parts[0]} -Scalar) -eq 1) 'MANAGED.COMMIT_WINNER_LOST'
    Record 'KNOWN_COMMIT_WINS_LATE_STOP'
    $releaseSummary=End-ManagedFixture $releaseWorker
    $stoppedSummary=$stoppedWorker.Result[0]
    Need ($releaseSummary.Unresolved-eq0 -and $stoppedSummary.Unresolved-eq0 -and ($releaseSummary.Completed+$stoppedSummary.Completed)-eq2 -and ($releaseSummary.Held+$stoppedSummary.Held)-eq1) 'MANAGED.SUMMARY_ORACLE'
    # Tatsächlicher Wettlauf: eigener Session-Gate hält Completion und Stop auf
    # demselben Ressourcenlock. Erst zwei beobachtete wartende Requests zählen.
    Need ((Sql 'SELECT ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0);' -Scalar) -eq 1) 'MANAGED.RACE_EXISTING_VISIBILITY_REQUIRED'
    $fixturePhase='race'
    $raceId=[guid]::NewGuid();$gate=$null;$stopConnection=$null;$stopCommand=$null;$stopTask=$null;$rendezvousDiagnostic=$null;$raceSucceeded=$false
    try {
        $stopConnection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$stopConnection.Open()
        $sessionCommand=$stopConnection.CreateCommand();$sessionCommand.CommandTimeout=1
        try{$sessionCommand.CommandText='SELECT CONVERT(int,@@SPID);';$stopSpid=[int]$sessionCommand.ExecuteScalar()}finally{$sessionCommand.Dispose()}
        Sql "EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.managed.short';"
        # Admission bleibt bei 0, bis die Reservation den genau eigenen Gate hat.
        Budget 0
        $raceWorker=Start-ManagedFixture -Capacity 1
        Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@Id;' @{'@Id'=$raceWorker.WorkerId} -Scalar) -eq 1} 'MANAGED.RACE_REGISTER_WAIT'
        # Eine feste Synthetic-Handlerwartezeit erlaubt den Gate vor Completion
        # zu halten; keine Produkt hooks oder fremden Sessionaktionen.
        $fixturePhase='race-handler'
        Sql "ALTER PROCEDURE dbo.USP_TbxManagedShort AS BEGIN SET NOCOUNT ON; INSERT dbo.TbxManagedEffects VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id'))); WAITFOR DELAY '00:00:02'; RETURN 7; END;"
        Budget 1
        Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@Id;' @{'@Id'=$raceWorker.WorkerId} -Scalar) -eq 1} 'MANAGED.RACE_RESERVATION_WAIT'
        $race=Sql 'SELECT CONVERT(varchar(36),SlotReservationId)+''|''+CONVERT(varchar(20),ClaimGeneration) FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@Id;' @{'@Id'=$raceWorker.WorkerId} -Scalar
        $parts=$race.Split('|');$raceId=[guid]$parts[0];$raceGeneration=[long]$parts[1]
        $gate=Sql 'SELECT N''Toolbelt.Worker.Disposition.''+CONVERT(nvarchar(36),@Id);' @{'@Id'=$raceId} -Scalar
        Need ((Sql 'DECLARE @rc int; EXEC @rc=sys.sp_getapplock @Resource=@Gate,@LockMode=N''Exclusive'',@LockOwner=N''Session'',@LockTimeout=0,@DbPrincipal=N''public'';SELECT @rc;' @{'@Gate'=$gate} -Scalar) -ge 0) 'MANAGED.RACE_OWN_GATE'
        $holderSpid=[int](Sql 'SELECT @@SPID;' -Scalar)
        $rendezvousClock=[Diagnostics.Stopwatch]::StartNew();$script:completionSpid=0
        $waiterSql=@'
SELECT CASE WHEN COUNT(DISTINCT r.session_id)=1 THEN MIN(r.session_id) ELSE 0 END
FROM sys.dm_tran_locks h JOIN sys.dm_tran_locks w
 ON w.resource_type=h.resource_type AND w.resource_database_id=h.resource_database_id
 AND w.resource_associated_entity_id=h.resource_associated_entity_id
 AND w.resource_description COLLATE Latin1_General_100_BIN2=h.resource_description COLLATE Latin1_General_100_BIN2
 JOIN sys.dm_exec_requests r ON r.session_id=w.request_session_id
WHERE h.resource_type='APPLICATION' AND h.resource_database_id=DB_ID()
 AND h.resource_associated_entity_id=DATABASE_PRINCIPAL_ID(N'public')
 AND h.request_session_id=@Holder AND h.request_status='GRANT' AND h.request_mode='X' AND h.request_owner_type='SESSION'
 AND w.request_status='WAIT' AND w.request_mode='X' AND w.request_owner_type='TRANSACTION'
 AND r.blocking_session_id=@Holder AND r.database_id=DB_ID()
 AND APPLOCK_MODE(N'public',@Gate,N'Session')=N'Exclusive';
'@
        Wait {$script:completionSpid=[int](Sql $waiterSql @{'@Holder'=$holderSpid;'@Gate'=$gate} -Scalar -ProbeClock $rendezvousClock -ProbeSeconds 4);$script:completionSpid-gt0} 'MANAGED.COMPLETION_WAITING' -LocalClock $rendezvousClock -LocalSeconds 4 -RendezvousWorker $raceWorker
        Need ($stopSpid-ne$script:completionSpid -and $stopSpid-ne$holderSpid) 'MANAGED.RACE_SESSION_DISTINCT'
        $stopCommand=$stopConnection.CreateCommand();$stopCommand.CommandTimeout=10
        $stopCommand.CommandText='EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@Id,@ExpectedClaimGeneration=@Generation;'
        [void]$stopCommand.Parameters.AddWithValue('@Id',$raceId);[void]$stopCommand.Parameters.AddWithValue('@Generation',$raceGeneration)
        $stopTask=$stopCommand.ExecuteNonQueryAsync()
        $bothWaiterSql=$waiterSql.Replace('SELECT CASE WHEN COUNT(DISTINCT r.session_id)=1 THEN MIN(r.session_id) ELSE 0 END','SELECT COUNT(DISTINCT r.session_id)').Replace(" AND APPLOCK_MODE"," AND r.session_id IN(@Completion,@Stop) AND APPLOCK_MODE")
        $captureWaitersSql=$bothWaiterSql.Replace('SELECT COUNT(DISTINCT r.session_id)','SELECT DISTINCT TOP(3) r.session_id,r.blocking_session_id').Replace(' AND r.blocking_session_id=@Holder','')
        $probeSelect="SELECT CONVERT(varchar(12),COUNT(*))+'|'+CONVERT(varchar(12),COUNT(CASE WHEN SessionId=@Completion THEN 1 END))+'|'+CONVERT(varchar(12),COUNT(CASE WHEN SessionId=@Stop THEN 1 END))+'|'+CONVERT(varchar(12),COUNT(CASE WHEN SessionId=@Completion AND Blocker=@Holder THEN 1 END))+'|'+CONVERT(varchar(12),COUNT(CASE WHEN SessionId=@Stop AND Blocker=@Holder THEN 1 END))+'|'+CONVERT(varchar(12),COUNT(CASE WHEN SessionId=@Stop AND Blocker=@Completion THEN 1 END)) FROM @Waiters;"
        $bothProbeSql='DECLARE @Waiters table(SessionId int NOT NULL,Blocker int NOT NULL); INSERT @Waiters(SessionId,Blocker) '+$captureWaitersSql+$probeSelect
        Wait {
            $values=(Sql $bothProbeSql @{'@Holder'=$holderSpid;'@Gate'=$gate;'@Completion'=$script:completionSpid;'@Stop'=$stopSpid} -Scalar -ProbeClock $rendezvousClock -ProbeSeconds 4).Split('|')
            Need ($values.Count-eq6) 'MANAGED.RACE_PROBE_SHAPE'
            $script:rendezvousDiagnostic=[ordered]@{MaterializedRows=[int]$values[0];CompletionSameResourceWait=[int]$values[1];StopSameResourceWait=[int]$values[2];CompletionBlockedByHolder=[int]$values[3];StopBlockedByHolder=[int]$values[4];StopBlockedByCompletion=[int]$values[5]}
            [int]$values[0]-eq2 -and [int]$values[1]-eq1 -and [int]$values[2]-eq1 -and [int]$values[3]-eq1 -and ([int]$values[4]-eq1 -or [int]$values[5]-eq1)
        } 'MANAGED.BOTH_DISPOSITION_CONTENDERS_WAITING' -LocalClock $rendezvousClock -LocalSeconds 4 -RendezvousWorker $raceWorker
        Need ((Sql 'DECLARE @rc int;EXEC @rc=sys.sp_releaseapplock @Resource=@Gate,@LockOwner=N''Session'',@DbPrincipal=N''public'';SELECT @rc;' @{'@Gate'=$gate} -Scalar) -eq 0) 'MANAGED.RACE_GATE_RELEASE_FAILED';$gate=$null
        Wait {$stopTask.IsCompleted} 'MANAGED.RACE_STOP_END'
        [void]$stopTask.GetAwaiter().GetResult()
        Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id AND IsOccupied=0;' @{'@Id'=$raceId} -Scalar) -eq 1} 'MANAGED.RACE_TERMINAL_END'
        Need ((Sql @'
SELECT CASE WHEN r.State='COMMITTED' AND w.Status='COMPLETED' AND d.IsHeld=0
 AND EXISTS(SELECT 1 FROM dbo.TbxManagedEffects e WHERE e.WorkItemId=w.WorkItemId) THEN 1
 WHEN r.State='ROLLED_BACK' AND w.Status='FAILED' AND d.IsHeld=1 AND d.StopStatus='ROLLED_BACK_HELD'
 AND NOT EXISTS(SELECT 1 FROM dbo.TbxManagedEffects e WHERE e.WorkItemId=w.WorkItemId) THEN 1 ELSE 0 END
FROM toolbelt_core.WorkerSlotReservation r JOIN toolbelt_core.WorkItem w ON w.WorkItemId=r.WorkItemId
JOIN toolbelt_core.WorkerExecutionDisposition d ON d.SlotReservationId=r.SlotReservationId WHERE r.SlotReservationId=@Id;
'@ @{'@Id'=$raceId} -Scalar) -eq 1) 'MANAGED.RACE_EFFECT_END_CONJUNCTION'
        [void](End-ManagedFixture $raceWorker)
        # Ein möglicher belegter Race-Hold bleibt beendet und gesperrt; keine
        # neue Queuearbeit verfälscht den anschließenden Controltimeoutfall.
        Record 'ACTUAL_COMPLETION_STOP_RENDEZVOUS';$raceSucceeded=$true
    } finally {
        if($null -ne $gate){try{Need ((Sql 'DECLARE @rc int;EXEC @rc=sys.sp_releaseapplock @Resource=@Gate,@LockOwner=N''Session'',@DbPrincipal=N''public'';SELECT @rc;' @{'@Gate'=$gate} -Scalar -Cleanup) -eq 0) 'MANAGED.RACE_GATE_RELEASE_FAILED'}catch{$secondary.Add('MANAGED.RACE_GATE_RELEASE_FAILED')}}
        if($null-ne$stopTask){try{$drainClock=[Diagnostics.Stopwatch]::StartNew();Wait {$stopTask.IsCompleted} 'MANAGED.RACE_STOP_END_UNKNOWN' -AllowUnknown -LocalClock $drainClock -LocalSeconds 15;[void]$stopTask.GetAwaiter().GetResult()}catch{$secondary.Add('MANAGED.RACE_STOP_END_UNKNOWN')}}
        if($null-eq$stopTask -or $stopTask.IsCompleted){if($null-ne$stopCommand){try{$stopCommand.Dispose()}catch{$secondary.Add('MANAGED.RACE_STOP_DISPOSE_FAILED')}};if($null-ne$stopConnection){try{$stopConnection.Dispose()}catch{$secondary.Add('MANAGED.RACE_STOP_DISPOSE_FAILED')}}}
        if(-not $raceSucceeded){try{
            $path=Join-Path $EvidenceDirectory 'RendezvousDiagnostic.json'
            $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $rendezvousDiagnostic -Depth 3))
            $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
        }catch{$secondary.Add('MANAGED.RACE_DIAGNOSTIC_WRITE_FAILED')}}
    }

    # Ein eigener kurzer Zeilenlock erzeugt einen realen Controltimeout. Das ist
    # kein Nachweis für Hostverlust, KILL oder einen simulierten Commitausgang.
    $fixturePhase='control-timeout'
    Budget 0
    Sql "ALTER PROCEDURE dbo.USP_TbxManagedShort AS BEGIN SET NOCOUNT ON; INSERT dbo.TbxManagedEffects VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id'))); WAITFOR DELAY '00:00:15'; RETURN 7; END;"
    Sql "EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.managed.short';"
    $faultWorker=Start-ManagedFixture -Capacity 1
    Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@Id;' @{'@Id'=$faultWorker.WorkerId} -Scalar)-eq1} 'MANAGED.FAULT_REGISTER'
    Budget 1
    Wait {(Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@Id AND State=''RUNNING'';' @{'@Id'=$faultWorker.WorkerId} -Scalar)-eq1} 'MANAGED.FAULT_RESERVATION'
    $faultReservation=Sql 'SELECT SlotReservationId FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@Id;' @{'@Id'=$faultWorker.WorkerId} -Scalar
    $faultItem=[long](Sql 'SELECT WorkItemId FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id;' @{'@Id'=$faultReservation} -Scalar)
    Wait {(Sql 'SELECT COUNT(*) FROM dbo.TbxManagedEffects WITH(READUNCOMMITTED) WHERE WorkItemId=@Item;' @{'@Item'=$faultItem} -Scalar)-eq1} 'MANAGED.FAULT_HANDLER_STARTED'
    $fixturePhase='control-timeout-lock'
    $faultConnection=$null;$faultTransaction=$null;$faultCommand=$null;$faultLockError=$null
    try {
        $faultConnection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$faultConnection.Open()
        $faultTransaction=$faultConnection.BeginTransaction()
        $faultCommand=$faultConnection.CreateCommand();$faultCommand.Transaction=$faultTransaction;$faultCommand.CommandTimeout=5
        $faultCommand.CommandText='SELECT SlotReservationId FROM toolbelt_core.WorkerSlotReservation WITH(XLOCK,ROWLOCK,HOLDLOCK) WHERE SlotReservationId=@Id;'
        [void]$faultCommand.Parameters.AddWithValue('@Id',$faultReservation)
        Need ($faultCommand.ExecuteScalar()-eq$faultReservation) 'MANAGED.FAULT_OWN_LOCK'
        [Threading.Thread]::Sleep(6500)
    }catch{$faultLockError=$_}
    finally {
        if($null-ne$faultTransaction){try{$faultTransaction.Rollback()}catch{if($null-eq$faultLockError){$faultLockError=$_}else{$secondary.Add('MANAGED.FAULT_LOCK_ROLLBACK_FAILED')}}}
        foreach($resource in @($faultCommand,$faultTransaction,$faultConnection)){if($null-ne$resource){try{$resource.Dispose()}catch{if($null-eq$faultLockError){$faultLockError=$_}else{$secondary.Add('MANAGED.FAULT_LOCK_DISPOSE_FAILED')}}}}
    }
    if($null-ne$faultLockError){throw $faultLockError}
    $fixturePhase='control-timeout-end'
    $faultSummary=End-ManagedFixture $faultWorker
    $faultEvents=@($faultWorker.Shell.Streams.Information | Where-Object {$_.Tags-contains'ToolbeltQueueWorker' -and $_.MessageData.Event-ceq'MANAGED_EXECUTION_ENDED'} | ForEach-Object {$_.MessageData})
    Need ($faultSummary.Status-ceq'OUTCOME_UNKNOWN' -and $faultSummary.Unresolved-eq1 -and $faultEvents.Count-eq1 -and $faultEvents[0].Outcome-ceq'UNKNOWN' -and -not $faultEvents[0].GuardianHealthy -and $faultEvents[0].RollbackConfirmed -and $faultEvents[0].ResourcesDisposed -and $null-ne$faultEvents[0].GuardianDiagnostic -and $faultEvents[0].GuardianDiagnostic.SqlNumber-eq-2) 'MANAGED.FAULT_ACTUAL_UNKNOWN'
    Need ((Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation r JOIN toolbelt_core.WorkItem w ON w.WorkItemId=r.WorkItemId WHERE r.SlotReservationId=@Id AND r.State=''UNKNOWN'' AND r.IsOccupied=1 AND r.EndedAtUtc IS NULL AND w.Status=''CLAIMED'' AND w.ManagedReservationId=r.SlotReservationId;' @{'@Id'=$faultReservation} -Scalar)-eq1) 'MANAGED.FAULT_UNKNOWN_OCCUPIED'
    Need ((Sql 'SELECT COUNT(*) FROM dbo.TbxManagedEffects WHERE WorkItemId=@Item;' @{'@Item'=$faultItem} -Scalar)-eq0) 'MANAGED.FAULT_ROLLBACK_EFFECT'
    # Ein weiterer geeigneter Worker darf den belegten unbekannten Slot nicht
    # über Lease-Recovery, Retry oder erneuten Claim übernehmen.
    Sql "EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.managed.short';"
    $fencedItem=[long](Sql 'SELECT MAX(WorkItemId) FROM toolbelt_core.WorkItem;' -Scalar)
    $fixturePhase='control-timeout-fence'
    $fencedWorker=Start-ManagedFixture -Capacity 1 -Mode BOUNDED -RunSeconds 1
    Wait {$fencedWorker.Task.IsCompleted} 'MANAGED.FAULT_FENCED_WORKER_END' -AllowUnknown
    $fencedSummary=End-ManagedFixture $fencedWorker
    Need ($fencedSummary.Status-ceq'COMPLETED' -and $fencedSummary.Claims-eq0 -and (Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status=''QUEUED'';' @{'@Item'=$fencedItem} -Scalar)-eq1 -and (Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkItemId=@Item;' @{'@Item'=$faultItem} -Scalar)-eq1 -and (Sql 'SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id AND State=''UNKNOWN'' AND IsOccupied=1;' @{'@Id'=$faultReservation} -Scalar)-eq1) 'MANAGED.FAULT_NO_REPLAY'
    $controlTimeoutFacts=[ordered]@{OriginalOutcome=$faultEvents[0].Outcome;GuardianHealthy=[bool]$faultEvents[0].GuardianHealthy;RollbackConfirmed=[bool]$faultEvents[0].RollbackConfirmed;ResourcesDisposed=[bool]$faultEvents[0].ResourcesDisposed;ControlSqlNumber=[int]$faultEvents[0].GuardianDiagnostic.SqlNumber;OriginalOccupied=$true;SubsequentClaims=[long]$fencedSummary.Claims;HoldBeforeReconciliation=[bool](Sql 'SELECT IsHeld FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id;' @{'@Id'=$faultReservation} -Scalar)}
    Record 'ACTUAL_CONTROL_TIMEOUT_UNKNOWN_OCCUPIED_NO_REPLAY'
    # Erst die explizite Admin-Reconciliation klassifiziert Hold. Ein zuvor
    # nicht gesetzter Hold wird dem UNKNOWN-Ausgang nicht rückwirkend zugeschrieben.
    $faultVersion=Sql 'SELECT HoldVersion FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id;' @{'@Id'=$faultReservation} -Scalar
    $fixturePhase='control-timeout-reconcile-hold'
    Sql 'EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Id,@ExpectedHoldVersion=@Version;' @{'@Id'=$faultReservation;'@Version'=$faultVersion}
    Need ((Sql 'SELECT COUNT(*) FROM toolbelt_core.VW_WorkerExecutionStatus v JOIN toolbelt_core.WorkerSlotReservation r ON r.SlotReservationId=v.SlotReservationId WHERE v.SlotReservationId=@Id AND v.State=''UNKNOWN'' AND r.IsOccupied=1 AND v.IsHeld=1 AND v.StopStatus=''UNKNOWN'';' @{'@Id'=$faultReservation} -Scalar)-eq1) 'MANAGED.FAULT_RECONCILE_UNKNOWN_HOLD'
    $faultVersion=Sql 'SELECT HoldVersion FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id;' @{'@Id'=$faultReservation} -Scalar
    $fixturePhase='control-timeout-release-denied'
    $releaseDenied=Sql @'
BEGIN TRY EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Version;SELECT CONVERT(int,0);END TRY
BEGIN CATCH IF ERROR_NUMBER()<>54225 OR ERROR_STATE()<>2 THROW;SELECT CONVERT(int,1);END CATCH;
'@ @{'@Item'=$faultItem;'@Version'=$faultVersion} -Scalar
    Need ($releaseDenied-eq1) 'MANAGED.FAULT_UNKNOWN_RELEASE_DENIED'
    $fixturePhase='control-timeout-reconcile-end'
    Sql 'EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Id,@ExpectedHoldVersion=@Version;' @{'@Id'=$faultReservation;'@Version'=$faultVersion}
    Need ((Sql 'SELECT COUNT(*) FROM toolbelt_core.VW_WorkerExecutionStatus v JOIN toolbelt_core.WorkerSlotReservation r ON r.SlotReservationId=v.SlotReservationId WHERE v.SlotReservationId=@Id AND v.State=''ROLLED_BACK'' AND r.IsOccupied=0 AND v.IsHeld=1 AND v.StopStatus=''ROLLED_BACK_HELD'';' @{'@Id'=$faultReservation} -Scalar)-eq1 -and (Sql 'SELECT COUNT(*) FROM dbo.TbxManagedEffects WHERE WorkItemId=@Item;' @{'@Item'=$faultItem} -Scalar)-eq0) 'MANAGED.FAULT_RECONCILE_END'
    Record 'UNKNOWN_RELEASE_DENIED_EXPLICIT_RECONCILIATION_END'
    Write-Information ('SYNTHETIC_CONTROL_TIMEOUT_FACTS: '+(ConvertTo-Json -InputObject $controlTimeoutFacts -Compress)) -InformationAction Continue
    # Erst nach sämtlichen physischen Endnachweisen eigene belegte Holds explizit
    # lösen. Es startet kein Verbraucher mehr; QUEUED-Synthetik endet mit OwnDB.
    Need (@($workers | Where-Object {-not $_.Ended -or -not $_.Disposed}).Count-eq0) 'MANAGED.SYNTHETIC_RELEASE_ACTORS_ENDED'
    $fixturePhase='synthetic-held-release'
    foreach($endedReservation in @($raceId,$faultReservation)) {
        $endedHeld=[bool](Sql 'SELECT IsHeld FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id;' @{'@Id'=$endedReservation} -Scalar)
        if($endedHeld) {
            Need ((Sql 'SELECT COUNT(*) FROM toolbelt_core.VW_WorkerExecutionStatus v JOIN toolbelt_core.WorkerSlotReservation r ON r.SlotReservationId=v.SlotReservationId WHERE v.SlotReservationId=@Id AND v.State=''ROLLED_BACK'' AND r.IsOccupied=0 AND v.IsHeld=1 AND v.StopStatus=''ROLLED_BACK_HELD'';' @{'@Id'=$endedReservation} -Scalar)-eq1) 'MANAGED.SYNTHETIC_RELEASE_END_PROOF'
            $endedItem=[long](Sql 'SELECT WorkItemId FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Id;' @{'@Id'=$endedReservation} -Scalar)
            $endedVersion=Sql 'SELECT HoldVersion FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Id;' @{'@Id'=$endedReservation} -Scalar
            Sql 'EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Version;' @{'@Item'=$endedItem;'@Version'=$endedVersion}
        }
    }

} catch {$primary=$_}
finally {
    foreach($worker in $workers) {
        if(-not $worker.Disposed){try{[void](End-ManagedFixture $worker)}catch{$secondary.Add('MANAGED.WORKER_DISPOSITION_UNKNOWN')}}
        if($worker.Disposed -and [IO.File]::Exists($worker.Stop)) {
            try {
                $info=[IO.FileInfo]::new($worker.Stop)
                Need ($worker.StopCreated -and $info.CreationTimeUtc -eq $worker.StopCreatedAt -and $info.Length -eq 0 -and $info.Name -match '^[a-f0-9]{32}\.stop$') 'MANAGED.OWN_STOP_FILE_DRIFT'
                [IO.File]::Delete($worker.Stop)
            } catch {$secondary.Add('MANAGED.STOP_FILE_CLEANUP_FAILED')}
        }
    }
    if($null-ne$primary -or $secondary.Count-gt0){try {
        $diagnostics=@();$workerEnds=@();$ordinal=0
        foreach($handle in $workers){
            $ordinal++
            $summary=$null
            if($null-ne$handle.Result -and $handle.Result.Count-eq1){
                $actual=$handle.Result[0]
                $summary=[ordered]@{Status=$actual.Status;Completed=$actual.Completed;Failed=$actual.Failed;Held=$actual.Held;Unresolved=$actual.Unresolved;SlotEndUnconfirmed=$actual.SlotEndUnconfirmed;CleanupFailed=$actual.CleanupFailed}
            }
            $workerEnds+=,[ordered]@{WorkerOrdinal=$ordinal;Ended=$handle.Ended;Disposed=$handle.Disposed;Summary=$summary}
            foreach($entry in $handle.Shell.Streams.Information){
                if($entry.Tags-contains'ToolbeltQueueWorker' -and $entry.MessageData.Event-ceq'MANAGED_EXECUTION_ENDED'){
                    $diagnostics+=,[ordered]@{WorkerOrdinal=$ordinal;Outcome=$entry.MessageData.Outcome;SlotEndConfirmed=$entry.MessageData.SlotEndConfirmed;ResourcesDisposed=$entry.MessageData.ResourcesDisposed;Code=$entry.MessageData.Code;ActorPhase=$entry.MessageData.ActorPhase;GuardianHealthy=$entry.MessageData.GuardianHealthy;RollbackConfirmed=$entry.MessageData.RollbackConfirmed;PrimaryCode=$entry.MessageData.PrimaryCode;PrimaryDiagnostic=$entry.MessageData.PrimaryDiagnostic;FailureDiagnostic=$entry.MessageData.FailureDiagnostic;GuardianDiagnostic=$entry.MessageData.GuardianDiagnostic;GuardianOuterDiagnostic=$entry.MessageData.GuardianOuterDiagnostic}
                }
            }
        }
        $path=Join-Path $EvidenceDirectory 'ActorDiagnostics.json'
        $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject ([ordered]@{Executions=$diagnostics;Workers=$workerEnds}) -Depth 8))
        $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
    }catch{$secondary.Add('MANAGED.ACTOR_DIAGNOSTIC_WRITE_FAILED')}}
    if($null -ne $connection) {
        try {
            if($null -ne $ownedConfig -and $null -eq $primary -and $secondary.Count -eq 0) {
                Need ((Sql 'SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1;' -Scalar) -eq 0) 'MANAGED.CLEANUP_OCCUPIED'
                Budget $beforeBudget
                Sql 'EXEC toolbelt_core.USP_DisableManagedWorkers @ExpectedConfigVersion=@Version;' @{'@Version'=$ownedConfig}
            }
        } catch {$secondary.Add('MANAGED.CONFIG_RESTORE_REQUIRED')}
        try{$connection.Dispose()}catch{$secondary.Add('MANAGED.CONTROL_DISPOSE_FAILED')}
    }
}
$result=[pscustomobject]@{Status=$(if($null -ne $primary -or $secondary.Count){'FAILED'}else{'PASS'})
    Cases=$records.ToArray();Secondary=$secondary.ToArray();FullProduct=$false}
$result
if($null -ne $primary){
 $caseCode='UNSPECIFIED'
 $allowedCodes=@(
'MANAGED.FIXTURE_DEADLINE','MANAGED.WORKER_END_UNKNOWN','MANAGED.WORKER_RESULT','MANAGED.CONFIG_DRIFT','MANAGED.EVIDENCE_NOT_FRESH','MANAGED.CONNECTION_UNAVAILABLE','MANAGED.ENCRYPTION_REQUIRED','MANAGED.OWN_DATABASE_GUARD','MANAGED.FRESH_DATABASE_REQUIRED','MANAGED.FRESH_DISABLED_GATE_REQUIRED','MANAGED.REGISTRATION_WAIT','MANAGED.ZERO_BUDGET_ADMITTED','MANAGED.BUDGET_TWO_WAIT','MANAGED.REDUCTION_CANCELLED_WORK','MANAGED.STOP_ROLLBACK_HOLD_WAIT','MANAGED.CANCEL_EFFECT_NOT_ROLLED_BACK','MANAGED.EXPLICIT_RELEASE_WAIT','MANAGED.LEGACY_BYPASS_NOT_REJECTED','MANAGED.ALL_EXECUTIONS_END_WAIT','MANAGED.COMMIT_WINNER_LOST','MANAGED.SUMMARY_ORACLE','MANAGED.RACE_EFFECT_END_CONJUNCTION','MANAGED.OWN_STOP_FILE_DRIFT','MANAGED.CLEANUP_OCCUPIED','MANAGED.GLOBAL_BUDGET','MANAGED.BOTH_DISPOSITION_CONTENDERS_WAITING','MANAGED.COMPLETION_WAITING','MANAGED.RACE_EXISTING_VISIBILITY_REQUIRED','MANAGED.RACE_OWN_GATE','MANAGED.RACE_REGISTER_WAIT','MANAGED.RACE_RESERVATION_WAIT','MANAGED.RACE_STOP_END','MANAGED.RACE_TERMINAL_END','MANAGED.UNEXPECTED_UNKNOWN','MANAGED.RACE_ACTOR_ENDED_BEFORE_RENDEZVOUS','MANAGED.RACE_SESSION_DISTINCT','MANAGED.RACE_PROBE_DEADLINE','MANAGED.RACE_PROBE_SHAPE','MANAGED.EMPTY_BOUNDED_END','MANAGED.EMPTY_BOUNDED_ORACLE','MANAGED.EMPTY_CONTINUOUS_ORACLE','MANAGED.FAULT_ACTUAL_UNKNOWN','MANAGED.FAULT_FENCED_WORKER_END','MANAGED.FAULT_HANDLER_STARTED','MANAGED.FAULT_LOCK_DISPOSE_FAILED','MANAGED.FAULT_LOCK_ROLLBACK_FAILED','MANAGED.FAULT_NO_REPLAY','MANAGED.FAULT_OWN_LOCK','MANAGED.FAULT_RECONCILE_END','MANAGED.FAULT_RECONCILE_UNKNOWN_HOLD','MANAGED.FAULT_REGISTER','MANAGED.FAULT_RESERVATION','MANAGED.FAULT_ROLLBACK_EFFECT','MANAGED.FAULT_UNKNOWN_OCCUPIED','MANAGED.FAULT_UNKNOWN_RELEASE_DENIED','MANAGED.HANDLERS_ACTUALLY_STARTED','MANAGED.RELEASE_OTHER_WORKER','MANAGED.TWO_SUPERVISORS_ADMITTED','MANAGED.SYNTHETIC_RELEASE_ACTORS_ENDED','MANAGED.SYNTHETIC_RELEASE_END_PROOF','MANAGED.ORIGINAL_OTHER_COMMIT_WAIT')
 if($primary.Exception.Message-cin$allowedCodes){$caseCode=$primary.Exception.Message}
 $cause=$primary.Exception;$sqlNumber=0;$sqlState=0
 while($cause){if($cause-is[Data.SqlClient.SqlException]){$sqlNumber=$cause.Number;$sqlState=[int]$cause.State;break};$cause=$cause.InnerException}
 $lastPassedCase=if($records.Count-gt0){[string]$records[$records.Count-1].Case}else{'NONE'}
 $diagnostic=[ordered]@{Phase=$fixturePhase;LastPassedCase=$lastPassedCase;CaseCode=$caseCode;Category=$primary.Exception.GetType().Name;Line=$primary.InvocationInfo.ScriptLineNumber;SqlNumber=$sqlNumber;SqlState=$sqlState}
 $primary.Exception.Data['Toolbelt.ManagedFixture.Diagnostic']=$diagnostic
 try{
  $privatePath=Join-Path $EvidenceDirectory 'FailureDiagnostic.json'
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $diagnostic -Depth 4))
  $stream=[IO.File]::Open($privatePath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
 }catch{$secondary.Add('MANAGED.PRIVATE_DIAGNOSTIC_WRITE_FAILED')}
 throw $primary
}
if($secondary.Count){throw 'MANAGED.FIXTURE_RESTORE_REQUIRED'}
