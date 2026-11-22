#requires -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'CommitReplyGate.cs')

function Invoke-ProbeSql($Connection, [string]$Text, [hashtable]$Parameters = @{}, [switch]$Scalar) {
    $command = $Connection.CreateCommand()
    try {
        $command.CommandText = $Text
        $command.CommandTimeout = 8
        foreach ($parameter in $Parameters.GetEnumerator()) {
            [void]$command.Parameters.AddWithValue($parameter.Key, $parameter.Value)
        }
        if ($Scalar) { return ,$command.ExecuteScalar() }
        [void]$command.ExecuteNonQuery()
    } finally { $command.Dispose() }
}

$port = [int]$env:TBX_COMMIT_SQL_PORT
$database = $env:TBX_COMMIT_DATABASE
if ($port -notin 1024..65535 -or $database -cnotmatch '^ContosoCommit_[a-f0-9]{16}$' -or
    [string]::IsNullOrEmpty($env:MSSQL_SA_PASSWORD)) { throw 'COMMIT_PROBE_TARGET' }
$builder = [Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder.DataSource = "tcp:127.0.0.1,$port"
$builder.InitialCatalog = $database
$builder.UserID = 'sa'; $builder.Password = $env:MSSQL_SA_PASSWORD
$builder.Encrypt = $true; $builder.TrustServerCertificate = $true
$builder.Pooling = $false; $builder.Enlist = $false; $builder.ConnectRetryCount = 0; $builder.ConnectTimeout = 5
$direct = $builder.ConnectionString
$control = [Data.SqlClient.SqlConnection]::new($direct)
$gate = $null; $subscription = $null; $shell = $null; $task = $null; $observer = $null
$stage = 'TARGET'
try {
    $control.Open()
    Invoke-ProbeSql $control @'
IF DB_ID()<=4 OR DB_NAME()<>@Database OR
   CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion'))<>17 OR
   NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N'Linux') OR
   NOT EXISTS(SELECT 1 FROM dbo.TbxCommitFixtureMarker WHERE DatabaseName=@Database) OR
   EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration)
    THROW 54972,N'COMMIT_PROBE_OWN_TARGET',1;
CREATE TABLE dbo.TbxCommitEffect(WorkItemId bigint NOT NULL);
'@ @{'@Database'=$database}
    # Parameterized commands use RPC scope, so create the temp tables in the outer batch.
    Invoke-ProbeSql $control 'CREATE TABLE #CommitWorker(Dummy int NULL); CREATE TABLE #CommitClaim(Dummy int NULL); CREATE TABLE #FollowClaim(Dummy int NULL); CREATE TABLE #FollowWorker(Dummy int NULL);'
    $stage = 'CLAIM'
    Invoke-ProbeSql $control @'
CREATE PROCEDURE dbo.USP_TbxCommitEffect AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.TbxCommitEffect VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')));
END;
'@
    Invoke-ProbeSql $control @'
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.commit.loss',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxCommitEffect',@ParameterMode='NONE';
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='test.commit.loss',@Principal=N'dbo',@PermissionName='ENQUEUE';
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='test.commit.loss',@Principal=N'dbo',@PermissionName='CLAIM';
DECLARE @Version binary(8)=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_EnableManagedWorkers @ExpectedConfigVersion=@Version;
SELECT @Version=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=1,@ExpectedConfigVersion=@Version;
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.commit.loss';
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@Worker,@Capacity=1,@RunMode='BOUNDED',@ResultTable=N'#CommitWorker';
DECLARE @WorkerGeneration bigint,@WorkerToken uniqueidentifier;
SELECT @WorkerGeneration=WorkerGeneration,@WorkerToken=WorkerToken FROM #CommitWorker;
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@Worker,@WorkerGeneration=@WorkerGeneration,@WorkerToken=@WorkerToken,@ResultTable=N'#CommitClaim';
'@ @{'@Worker'=[guid]::NewGuid()}
    $claim = Invoke-ProbeSql $control @'
IF (SELECT COUNT(*) FROM #CommitClaim)<>1 THROW 54972,N'COMMIT_PROBE_CLAIM',2;
SELECT CONVERT(nvarchar(max),(SELECT c.WorkItemId,c.ClaimGeneration,c.ClaimToken,c.ExecutionId,c.SlotReservationId,
       w.WorkerId,w.WorkerGeneration,w.WorkerToken FROM #CommitClaim c CROSS JOIN #CommitWorker w
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER));
'@ -Scalar | ConvertFrom-Json

    $stage = 'EXECUTOR'
    $gate = [CommitReplyGate]::new($port)
    $builder.DataSource = "tcp:127.0.0.1,$($gate.Port)"
    $proxy = $builder.ConnectionString
    $builder.Clear()
    $subscription = [CommitReplyDiagnostic]::new($gate)
    $shell = [powershell]::Create()
    [void]$shell.AddScript({
        param($Root,$Claim,$Direct,$Proxy)
        $ErrorActionPreference='Stop'
        Import-Module (Join-Path $Root 'ExecutionActors.psm1') -Force
        Import-Module (Join-Path $Root 'ManagedQueueWorker.psm1') -Force
        $eligible = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        [void]$eligible.Add('test.commit.loss')
        $context = [pscustomobject]@{
            Direct=$Direct; Proxy=$Proxy; ExecutorConnected=$false
            Settings=@{ControlTimeoutSeconds=5;WorkerEligibleWorkTypes=$eligible}
            Registration=@{WorkerId=[guid]$Claim.WorkerId;WorkerGeneration=[long]$Claim.WorkerGeneration;WorkerToken=[guid]$Claim.WorkerToken}
            Claim=@{WorkItemId=[long]$Claim.WorkItemId;ClaimGeneration=[long]$Claim.ClaimGeneration
                ClaimToken=[guid]$Claim.ClaimToken;ExecutionId=[guid]$Claim.ExecutionId
                SlotReservationId=[guid]$Claim.SlotReservationId;WorkTypeName='test.commit.loss'}
            Budget=86400;Terminal='UNKNOWN';SlotEndConfirmed=$false;PrimaryDiagnostic=$null;PrimaryError=$null
        }
        $context | Add-Member ScriptProperty ConnectionString {
            if ($this.ExecutorConnected) { return $this.Direct }
            $this.ExecutorConnected=$true
            return $this.Proxy
        }
        $actor = New-WorkerExecutionActor -ExecutionId $context.Claim.ExecutionId -Executor {} -GuardianControl {} -Context $context
        $result = Invoke-ManagedExecutor $actor.Shared $context
        [pscustomobject]@{Commit=$result.Committed;Rollback=$result.RollbackConfirmed;Disposed=$result.ResourcesDisposed
            Terminal=$context.Terminal;SlotEndConfirmed=$context.SlotEndConfirmed
            Phase=$context.PrimaryDiagnostic.Phase;Secondary=$actor.Shared.SecondaryCode}
    }).AddArgument((Resolve-Path (Join-Path $PSScriptRoot '../..')).Path).AddArgument($claim).AddArgument($direct).AddArgument($proxy)
    $task = $shell.BeginInvoke()
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while (-not $gate.ReplyWithheld.IsCompleted -and -not $task.IsCompleted -and $timer.Elapsed.TotalSeconds -lt 25) {
        Start-Sleep -Milliseconds 50
    }
    if (-not $gate.ReplyWithheld.IsCompletedSuccessfully -or $task.IsCompleted) { throw 'COMMIT_PROBE_NO_WITHHELD_REPLY' }
    $stage = 'PERSISTED'
    $slot = @{'@Slot'=[guid]$claim.SlotReservationId;'@Item'=[long]$claim.WorkItemId}
    $observer = [Data.SqlClient.SqlConnection]::new($direct)
    $observer.Open()
    Invoke-ProbeSql $observer @'
IF (SELECT COUNT(*) FROM dbo.TbxCommitEffect WHERE WorkItemId=@Item)<>1 OR NOT EXISTS(
    SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness x
    JOIN toolbelt_core.WorkerSlotReservation r ON r.SlotReservationId=x.SlotReservationId
    JOIN toolbelt_core.WorkItem w ON w.WorkItemId=r.WorkItemId
    WHERE r.SlotReservationId=@Slot AND x.ExecutionId=r.ExecutionId AND x.ClaimGeneration=r.ClaimGeneration
    AND x.AttemptNonce=r.AttemptNonce AND w.Status='COMPLETED' AND r.IsOccupied=1)
    THROW 54972,N'COMMIT_PROBE_WITNESS',3;
'@ $slot
    if ($task.IsCompleted) { throw 'COMMIT_PROBE_RETURNED_BEFORE_CUT' }
    $gate.Abort()
    $stage='WORKER_UNKNOWN'
    if (-not $task.AsyncWaitHandle.WaitOne([timespan]::FromSeconds(20))) { throw 'COMMIT_PROBE_ACTOR_TIMEOUT' }
    $results = @($shell.EndInvoke($task))
    if ($shell.HadErrors -or $results.Count -ne 1) { throw 'COMMIT_PROBE_ACTOR_RESULT' }
    $result = $results[0]
    if ($result.Phase -cne 'COMMITTING' -or $result.Terminal -cne 'UNKNOWN' -or $result.Commit -or
        $result.Rollback -or -not $result.Disposed -or $result.SlotEndConfirmed -or $result.Secondary) {
        throw 'COMMIT_PROBE_ACTOR_DISPOSITION'
    }
    Invoke-ProbeSql $control @'
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Slot AND State='UNKNOWN' AND IsOccupied=1)
    THROW 54972,N'COMMIT_PROBE_UNKNOWN_OCCUPIED',4;
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.commit.loss';
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@Worker,@Capacity=1,@RunMode='BOUNDED',@ResultTable=N'#FollowWorker';
DECLARE @WorkerGeneration bigint,@WorkerToken uniqueidentifier;
SELECT @WorkerGeneration=WorkerGeneration,@WorkerToken=WorkerToken FROM #FollowWorker;
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@Worker,@WorkerGeneration=@WorkerGeneration,@WorkerToken=@WorkerToken,@ResultTable=N'#FollowClaim';
IF EXISTS(SELECT 1 FROM #FollowClaim) THROW 54972,N'COMMIT_PROBE_UNSAFE_ADMISSION',5;
'@ ($slot + @{'@Worker'=[guid]::NewGuid()})
    $stage='RECONCILE'
    Invoke-ProbeSql $observer @'
DECLARE @Version binary(8)=(SELECT HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@Slot);
EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Version;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@Slot AND State='COMMITTED' AND IsOccupied=0 AND EndedAtUtc IS NOT NULL)
   OR (SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkItemId=@Item)<>1
   OR (SELECT COUNT(*) FROM dbo.TbxCommitEffect WHERE WorkItemId=@Item)<>1
    THROW 54972,N'COMMIT_PROBE_RECONCILIATION',6;
'@ $slot
    'WORKER_REAL_COMMIT_REPLY_LOSS_PASS'
} catch {
    # The fixture only reports its own phase and exception category.
    $number = $_.Exception
    while ($number -and $number -isnot [Data.SqlClient.SqlException]) { $number=$number.InnerException }
    $code = if ($number) { "$($number.Number)/$($number.State)" } else { $_.Exception.GetType().Name }
    throw "WORKER_COMMIT_LOSS_FAILED $stage $code"
} finally {
    if ($null -ne $gate) { $gate.Dispose() }
    if ($null -ne $shell) {
        if ($null -ne $task -and -not $task.IsCompleted) { $shell.Stop() }
        $shell.Dispose()
    }
    if ($null -ne $subscription) { $subscription.Dispose() }
    if ($null -ne $observer) { $observer.Dispose() }
    $control.Dispose()
}
