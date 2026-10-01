#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Der Supervisor kennt nur Zustandsgrenzen. Der private Adapter erlaubt belastbare
# Fault-Tests ohne SQL-Mutationen; öffentliche Aufrufe verwenden ausschließlich SqlClient.
function Write-WorkerEvent($Slot, [string]$Event, [string]$Code = '') {
    $record = [ordered]@{ Event = $Event; Code = $Code }
    if ($null -ne $Slot) {
        $record.WorkItemId = $Slot.Claim.WorkItemId
        $record.ClaimGeneration = $Slot.Claim.ClaimGeneration
        $record.ExecutionId = $Slot.ExecutionId
    }
    Write-Information ([pscustomobject]$record) -Tags 'ToolbeltQueueWorker'
}

function Update-WorkerDueLeases($Active, [hashtable]$Adapter) {
    $failed=$false
    foreach($peer in @($Active.ToArray())) {
        if($peer.Uncertain -or ((& $Adapter.Now)-$peer.LastRenew) -lt 60){continue}
        try { & $Adapter.Renew $peer; $peer.LastRenew=& $Adapter.Now }
        catch { $peer.Uncertain=$true; $failed=$true; Write-WorkerEvent $peer 'CONTROL_UNCERTAIN' 'WORKER.OUTCOME_UNKNOWN' }
    }
    return $failed
}

function Invoke-WorkerSupervisor {
    [CmdletBinding()]
    param($Settings, [hashtable]$Adapter)
    $active = [System.Collections.Generic.List[object]]::new()
    $counts = [ordered]@{ Status = 'COMPLETED'; Claims = 0; Completed = 0; Failed = 0; Retried = 0; DeadLetter = 0; Unresolved = 0 }
    $started = & $Adapter.Now
    $draining = $false; $drainStart = 0.0; $graceReported = $false
    & $Adapter.Preflight
    try {
        while ($true) {
            $now = & $Adapter.Now
            if (-not $draining -and (($now - $started) -ge $Settings.MaxRunSeconds -or $counts.Claims -ge $Settings.MaxClaims -or (& $Adapter.ShouldStop))) {
                $draining = $true; $drainStart = $now
                Write-WorkerEvent $null 'DRAIN_STARTED'
            }
            # Steuerfehler sperren jeden späteren Abschluss. Ein verlorenes Acknowledge
            # wird weder erneut ausgeführt noch aus einem lokalen Timer als Erfolg abgeleitet.
            foreach ($slot in @($active.ToArray())) {
                if (-not $slot.Uncertain -and ($now - $slot.LastRenew) -ge 60) {
                    try { & $Adapter.Renew $slot; $slot.LastRenew = & $Adapter.Now }
                    catch { $slot.Uncertain = $true; $draining = $true; $drainStart = $now; Write-WorkerEvent $slot 'CONTROL_UNCERTAIN' 'WORKER.OUTCOME_UNKNOWN' }
                }
                if (-not $slot.Uncertain -and -not $slot.CancelSent -and ($now - $slot.Started) -ge $slot.Budget) {
                    $slot.CancelSent = $true
                    try { & $Adapter.Cancel $slot; Write-WorkerEvent $slot 'CANCELLATION_REQUESTED' }
                    catch { $slot.Uncertain = $true; $draining = $true; $drainStart = $now; Write-WorkerEvent $slot 'CONTROL_UNCERTAIN' 'WORKER.OUTCOME_UNKNOWN' }
                }
                $outcome = & $Adapter.Poll $slot
                if ($outcome.State -eq 'RUNNING') { continue }
                # Vor jeder synchronen Providergrenze erhalten alle noch sicher aktiven
                # Claims eine frische Lease. Commit selbst besitzt keinen Timeoutparameter.
                foreach ($peer in @($active.ToArray())) {
                    if ($peer.Uncertain) { continue }
                    try { & $Adapter.Renew $peer; $peer.LastRenew = & $Adapter.Now }
                    catch { $peer.Uncertain = $true; $draining = $true; $drainStart = $now; Write-WorkerEvent $peer 'CONTROL_UNCERTAIN' 'WORKER.OUTCOME_UNKNOWN' }
                }
                $final = 'Unresolved'; $code = 'WORKER.OUTCOME_UNKNOWN'
                try {
                    if ($slot.Uncertain -or $outcome.State -eq 'UNKNOWN') {
                        # Ein bekannter Rollback ist weiterhin sinnvoll, begründet nach
                        # Ownershipverlust aber keine Fail-/Retry-Berechtigung.
                        try { & $Adapter.Rollback $slot } catch { }
                    }
                    elseif ($outcome.State -eq 'SUCCEEDED') {
                        $checkpoint = & $Adapter.Checkpoint $slot
                        if ($checkpoint -eq 'OWNERSHIP_LOST') {
                            & $Adapter.Rollback $slot
                        }
                        elseif ($checkpoint -eq 'CANCELLED') {
                            & $Adapter.Rollback $slot
                            & $Adapter.Fail $slot 'WORKER.CANCELLED'
                            $final = 'Failed'; $code = 'WORKER.CANCELLED'
                        }
                        else {
                            # Complete und Effect teilen genau dieselbe SqlTransaction.
                            # Ein Commitfehler verlässt diesen Zweig ohne Replay oder Fail.
                            & $Adapter.Complete $slot
                            $final = 'Completed'; $code = ''
                        }
                    }
                    else {
                        & $Adapter.Rollback $slot
                        $code = $outcome.Code
                        if ($outcome.SqlNumber -eq 50001 -and (& $Adapter.IsCancelled $slot)) { $code = 'WORKER.CANCELLED' }
                        if ($code -ne 'WORKER.CANCELLED' -and (& $Adapter.CanRetry $slot $outcome.SqlNumber)) {
                            $retryState = & $Adapter.Retry $slot $code
                            if ($retryState -ceq 'RETRY_WAIT') { $final = 'Retried' }
                            elseif ($retryState -ceq 'DEAD_LETTER') { $final = 'DeadLetter' }
                            else { throw 'WORKER.RETRY_OUTCOME_UNKNOWN' }
                        }
                        else { & $Adapter.Fail $slot $code; $final = 'Failed' }
                    }
                }
                catch { $final = 'Unresolved'; $code = 'WORKER.OUTCOME_UNKNOWN'; $draining = $true; $drainStart = $now }
                $counts[$final]++
                Write-WorkerEvent $slot $final.ToUpperInvariant() $code
                try { & $Adapter.Dispose $slot } catch { Write-WorkerEvent $slot 'CLEANUP_FAILED' 'WORKER.CLEANUP_FAILED' }
                [void]$active.Remove($slot)
            }
            if ($draining -and $active.Count -gt 0 -and -not $graceReported -and ($now - $drainStart) -ge $Settings.GraceSeconds) {
                $graceReported = $true
                foreach ($slot in $active) { Write-WorkerEvent $slot 'DRAIN_ACTIVE' $(if ($slot.Uncertain) { 'WORKER.OUTCOME_UNKNOWN' } else { '' }) }
            }
            if (-not $draining) {
                while ($active.Count -lt $Settings.Slots -and $counts.Claims -lt $Settings.MaxClaims) {
                    # Auch mehrere synchrone Startupcommands dürfen den Heartbeat
                    # bereits gestarteter Peers nicht bis zum Ende der Slotfüllung verschieben.
                    if(Update-WorkerDueLeases $active $Adapter){$draining=$true;$drainStart=& $Adapter.Now;break}
                    # Budgets werden vor jedem Claim erneut geprüft, nicht nur pro Schleife.
                    if ((& $Adapter.Now) - $started -ge $Settings.MaxRunSeconds -or (& $Adapter.ShouldStop)) { $draining = $true; $drainStart = & $Adapter.Now; break }
                    try { $slot = & $Adapter.Claim }
                    catch { $counts.Unresolved++; $draining = $true; $drainStart = & $Adapter.Now; Write-WorkerEvent $null 'CLAIM_UNCERTAIN' 'WORKER.OUTCOME_UNKNOWN'; break }
                    if ($null -eq $slot) { if ($active.Count -eq 0) { $draining = $true }; break }
                    $counts.Claims++
                    $slot.Started = & $Adapter.Now; $slot.LastRenew = $slot.Started
                    $slot.Uncertain = $false; $slot.CancelSent = $false
                    [void]$active.Add($slot)
                    if(Update-WorkerDueLeases $active $Adapter){
                        $draining=$true;$drainStart=& $Adapter.Now;$slot.Uncertain=$true
                        $slot.ImmediateOutcome=[pscustomobject]@{State='UNKNOWN';Code='WORKER.OUTCOME_UNKNOWN';SqlNumber=0}
                        break
                    }
                    try { & $Adapter.Start $slot }
                    catch {
                        $dispatchStarted = $null -ne $slot.PSObject.Properties['DispatchStarted'] -and $slot.DispatchStarted
                        $slot.ImmediateOutcome = [pscustomobject]@{ State = $(if($dispatchStarted){'UNKNOWN'}else{'FAILED'}); Code = 'WORKER.HANDLER_INVALID'; SqlNumber = 0 }
                    }
                    Write-WorkerEvent $slot 'STARTED'
                }
            }
            if ($draining -and $active.Count -eq 0) { break }
            & $Adapter.Sleep $Settings.PollSeconds
        }
    }
    finally {
        # Host-/Prozessabbruch ist kein kooperativer Stop. Keine fiktiven Queueausgänge.
        foreach ($slot in $active) { Write-WorkerEvent $slot 'HOST_INTERRUPTED' 'WORKER.OUTCOME_UNKNOWN' }
    }
    if ($counts.Unresolved -gt 0) { $counts.Status = 'OUTCOME_UNKNOWN' }
    [pscustomobject]$counts
}

function New-WorkerCommand($Connection, [string]$Text, [int]$Timeout, $Transaction = $null) {
    $command = $Connection.CreateCommand()
    $command.CommandText = $Text; $command.CommandTimeout = $Timeout
    if ($null -ne $Transaction) { $command.Transaction = $Transaction }
    return $command
}

function Add-WorkerParameter($Command, [string]$Name, [System.Data.SqlDbType]$Type, $Value, [int]$Size = 0) {
    $parameter = if ($Size -eq 0) { $Command.Parameters.Add($Name, $Type) } else { $Command.Parameters.Add($Name, $Type, $Size) }
    $parameter.Value = if ($null -eq $Value) { [DBNull]::Value } else { $Value }
}

# Reader werden vollständig geleert; Claim hat im bestehenden Kern ein Scheduler-
# Resultset. Genau eine Shape ist zulässig, auch bei einem leeren Claimresultset.
function Read-WorkerClaim($Reader) {
    $names = @('WorkItemId','WorkTypeName','PayloadJson','ClaimToken','ClaimedAtUtc','ClaimGeneration','LeaseUntilUtc','LastHeartbeatAtUtc')
    $shapeCount = 0; $claim = $null
    do {
        $matches = $Reader.FieldCount -eq 8
        if ($matches) { for ($i = 0; $i -lt 8; $i++) { if ($Reader.GetName($i) -cne $names[$i]) { $matches = $false; break } } }
        if ($matches) { $shapeCount++ }
        while ($Reader.Read()) {
            if (-not $matches) { continue }
            if ($null -ne $claim) { throw 'WORKER.CLAIM_SHAPE_INVALID' }
            $row = [ordered]@{}
            for ($i = 0; $i -lt 8; $i++) { $row[$names[$i]] = if ($Reader.IsDBNull($i)) { $null } else { $Reader.GetValue($i) } }
            $claim = [pscustomobject]$row
        }
    } while ($Reader.NextResult())
    if ($shapeCount -ne 1) { throw 'WORKER.CLAIM_SHAPE_INVALID' }
    if ($null -ne $claim -and ($claim.WorkItemId -isnot [long] -or $claim.WorkItemId -le 0 -or $claim.ClaimGeneration -isnot [long] -or $claim.ClaimGeneration -le 0 -or $claim.ClaimToken -isnot [guid] -or $claim.ClaimToken -eq [guid]::Empty -or $claim.WorkTypeName -isnot [string] -or $claim.LeaseUntilUtc -isnot [datetime] -or $claim.ClaimedAtUtc -isnot [datetime] -or $claim.LastHeartbeatAtUtc -isnot [datetime])) { throw 'WORKER.CLAIM_SHAPE_INVALID' }
    return $claim
}

function Get-WorkerSqlNumber($ErrorObject) {
    $exception = $ErrorObject.Exception
    while ($null -ne $exception) {
        if ($exception -is [System.Data.SqlClient.SqlException]) { return [int]$exception.Number }
        $exception = $exception.InnerException
    }
    return 0
}

function New-WorkerSqlAdapter($Settings, [string]$ConnectionString) {
    # GetNewClosure isoliert Variablen in einem dynamischen Modul; private Helpers
    # werden deshalb als Scriptblocks gebunden statt per Namenslookup aufgelöst.
    $newCommand = ${function:New-WorkerCommand}
    $addParameter = ${function:Add-WorkerParameter}
    $readClaim = ${function:Read-WorkerClaim}
    $sqlNumber = ${function:Get-WorkerSqlNumber}
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new($ConnectionString)
    if (-not $builder.Encrypt) { throw 'WORKER.ENCRYPTION_REQUIRED' }
    $builder['Connect Timeout'] = $Settings.ConnectTimeoutSeconds
    $builder.ConnectRetryCount = 0; $builder.Pooling = $false; $builder.Enlist = $false
    $builder.MultipleActiveResultSets = $false
    $privateConnectionString = $builder.ConnectionString
    $connect = { $connection = [System.Data.SqlClient.SqlConnection]::new($privateConnectionString); $connection.Open(); return $connection }.GetNewClosure()
    $execute = {
        param($connection, $text, $parameters, $transaction = $null)
        $command = & $newCommand $connection $text $Settings.ControlTimeoutSeconds $transaction
        try {
            foreach ($parameter in $parameters) { & $addParameter $command @parameter }
            [void]$command.ExecuteNonQuery()
        } finally { $command.Dispose() }
    }.GetNewClosure()
    $bound = { param($slot) return @(@('@WorkItemId',[System.Data.SqlDbType]::BigInt,$slot.Claim.WorkItemId),@('@ClaimToken',[System.Data.SqlDbType]::UniqueIdentifier,$slot.Claim.ClaimToken)) }.GetNewClosure()
    $checkpoint = {
        param($slot)
        $command = & $newCommand $slot.Handler @'
SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM toolbelt_core.VW_WorkQueue
 WHERE WorkItemId=@WorkItemId AND Status='CLAIMED' AND ClaimGeneration=@Generation AND IsLeaseExpired=0)
 THEN 'OWNERSHIP_LOST' WHEN ISNULL(TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.execution_id')),'00000000-0000-0000-0000-000000000000')<>@ExecutionId
 OR ISNULL(toolbelt_core.SVF_CurrentExecutionId(),'00000000-0000-0000-0000-000000000000')<>@ExecutionId THEN 'OWNERSHIP_LOST'
 WHEN toolbelt_core.SVF_IsCancellationRequested(@ExecutionId)=1
 THEN 'CANCELLED' ELSE 'ACTIVE' END;
'@ $Settings.ControlTimeoutSeconds $slot.Transaction
        try {
            & $addParameter $command '@WorkItemId' BigInt $slot.Claim.WorkItemId
            & $addParameter $command '@Generation' BigInt $slot.Claim.ClaimGeneration
            & $addParameter $command '@ExecutionId' UniqueIdentifier $slot.ExecutionId
            return [string]$command.ExecuteScalar()
        } finally { $command.Dispose() }
    }.GetNewClosure()
    $adapter = @{
        Now = { return $timer.Elapsed.TotalSeconds }.GetNewClosure()
        Sleep = { param($seconds) Start-Sleep -Milliseconds ([int]($seconds * 1000)) }
        ShouldStop = { return $Settings.StopFile -and (Test-Path -LiteralPath $Settings.StopFile -PathType Leaf) }.GetNewClosure()
        Preflight = {
            $connection = & $connect
            try {
                $command = & $newCommand $connection @'
SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND
 ((name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.0.0')
 OR(name=N'Toolbelt.Module.toolbelt.core.work-type.Version' AND CONVERT(nvarchar(64),value)=N'1.1.0')
 OR(name=N'Toolbelt.Module.toolbelt.core.execution-context.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR(name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0'));
'@ $Settings.ControlTimeoutSeconds
                try { if ([int]$command.ExecuteScalar() -ne 4) { throw 'WORKER.DEPENDENCY_UNAVAILABLE' } } finally { $command.Dispose() }
            } finally { $connection.Dispose() }
        }.GetNewClosure()
        Claim = {
            $control = & $connect
            try {
                $command = & $newCommand $control 'EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;' $Settings.ControlTimeoutSeconds
                try { $reader = $command.ExecuteReader(); try { $claim = & $readClaim $reader } finally { $reader.Dispose() } } finally { $command.Dispose() }
                if ($null -eq $claim) { $control.Dispose(); return $null }
                return [pscustomobject]@{ Claim = $claim; ExecutionId = [guid]::NewGuid(); Control = $control; Handler = $null; Transaction = $null; Command = $null; Task = $null; ImmediateOutcome = $null; Budget = 86400; Started = 0.0; LastRenew = 0.0; Uncertain = $false; CancelSent = $false; ContextStarted = $false; Committed = $false; LastSqlNumber = 0; DispatchStarted = $false }
            } catch { $control.Dispose(); throw 'WORKER.OUTCOME_UNKNOWN' }
        }.GetNewClosure()
        Renew = {
            param($slot)
            & $execute $slot.Control 'EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken;' (& $bound $slot)
        }.GetNewClosure()
        Cancel = {
            param($slot)
            & $execute $slot.Control 'EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@ExecutionId,@CancellationReason=N''Worker cooperative budget'';' (,@('@ExecutionId',[System.Data.SqlDbType]::UniqueIdentifier,$slot.ExecutionId))
        }.GetNewClosure()
        Checkpoint = $checkpoint
        Start = {
            param($slot)
            if (-not $Settings.WorkerEligibleWorkTypes.Contains($slot.Claim.WorkTypeName)) {
                $slot.ImmediateOutcome = [pscustomobject]@{ State='FAILED'; Code='WORKER.UNSUPPORTED_HANDLER'; SqlNumber=0 }; return
            }
            $slot.Handler = & $connect
            $command = & $newCommand $slot.Handler 'EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName=@Name,@RequireEnabled=1,@RequireExecutableByCaller=1;' $Settings.ControlTimeoutSeconds
            try {
                & $addParameter $command '@Name' VarChar $slot.Claim.WorkTypeName 128
                $reader = $command.ExecuteReader()
                try {
                    if (-not $reader.Read()) { throw 'WORKER.HANDLER_INVALID' }
                    $schema = [string]$reader['HandlerSchema']; $procedure = [string]$reader['HandlerProcedure']; $mode = [string]$reader['ParameterMode']
                    $slot.Budget = [int]$reader['DefaultTimeoutSeconds']
                    while ($reader.Read()) { throw 'WORKER.HANDLER_INVALID' }
                    while ($reader.NextResult()) { while ($reader.Read()) { } }
                } finally { $reader.Dispose() }
            } finally { $command.Dispose() }
            $qualified = '[' + $schema.Replace(']',']]') + '].[' + $procedure.Replace(']',']]') + ']'
            $command = & $newCommand $slot.Handler @'
SELECT CASE WHEN @Mode='NONE' AND NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Qualified) AND parameter_id>0) THEN 1
 WHEN @Mode='JSON_PAYLOAD' AND (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(@Qualified) AND parameter_id>0)=1
 AND EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Qualified) AND parameter_id=1 AND name COLLATE Latin1_General_100_BIN2=N'@PayloadJson'
 AND system_type_id=231 AND user_type_id=231 AND max_length=-1 AND is_output=0) THEN 1 ELSE 0 END;
'@ $Settings.ControlTimeoutSeconds
            try {
                & $addParameter $command '@Mode' VarChar $mode 16
                & $addParameter $command '@Qualified' NVarChar $qualified 517
                if ([int]$command.ExecuteScalar() -ne 1) { throw 'WORKER.HANDLER_INVALID' }
            } finally { $command.Dispose() }
            if ($mode -ceq 'NONE' -and $null -ne $slot.Claim.PayloadJson) { throw 'WORKER.HANDLER_INVALID' }
            if ($mode -ceq 'JSON_PAYLOAD') {
                $payload = $slot.Claim.PayloadJson
                if ($null -eq $payload -or [System.Text.Encoding]::Unicode.GetByteCount($payload) -gt 65536 -or -not $payload.TrimStart().StartsWith('{')) { throw 'WORKER.HANDLER_INVALID' }
                try { $json = [System.Text.Json.JsonDocument]::Parse($payload); $json.Dispose() } catch { throw 'WORKER.HANDLER_INVALID' }
            }
            & $execute $slot.Handler @'
DECLARE @Id uniqueidentifier=@ExecutionId;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@AllowNested=0;
EXEC sys.sp_set_session_context @key=N'toolbelt.worker.work_item_id',@value=@WorkItemId,@read_only=1;
EXEC sys.sp_set_session_context @key=N'toolbelt.worker.claim_generation',@value=@Generation,@read_only=1;
EXEC sys.sp_set_session_context @key=N'toolbelt.worker.execution_id',@value=@ExecutionId,@read_only=1;
'@ @(@('@ExecutionId',[System.Data.SqlDbType]::UniqueIdentifier,$slot.ExecutionId),@('@WorkItemId',[System.Data.SqlDbType]::BigInt,$slot.Claim.WorkItemId),@('@Generation',[System.Data.SqlDbType]::BigInt,$slot.Claim.ClaimGeneration))
            $slot.ContextStarted = $true
            $slot.Transaction = $slot.Handler.BeginTransaction([System.Data.IsolationLevel]::ReadCommitted)
            $before = & $checkpoint $slot
            if ($before -ne 'ACTIVE') {
                $slot.ImmediateOutcome = [pscustomobject]@{State=$(if($before -eq 'CANCELLED'){'FAILED'}else{'UNKNOWN'});Code='WORKER.CANCELLED';SqlNumber=50001}; return
            }
            $text = 'EXEC @HandlerReturnCode = ' + $qualified + $(if ($mode -ceq 'JSON_PAYLOAD') { ' @PayloadJson=@PayloadJson' } else { '' }) + ' WITH RESULT SETS NONE; IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR ISNULL(toolbelt_core.SVF_CurrentExecutionId(),''00000000-0000-0000-0000-000000000000'')<>CONVERT(uniqueidentifier,SESSION_CONTEXT(N''toolbelt.worker.execution_id'')) THROW 50003,N''Worker transaction discipline violated'',1;'
            $slot.Command = & $newCommand $slot.Handler $text 0 $slot.Transaction
            if ($mode -ceq 'JSON_PAYLOAD') { & $addParameter $slot.Command '@PayloadJson' NVarChar $slot.Claim.PayloadJson -1 }
            $returnCode = $slot.Command.Parameters.Add('@HandlerReturnCode',[System.Data.SqlDbType]::Int); $returnCode.Direction = [System.Data.ParameterDirection]::Output
            $slot.DispatchStarted = $true
            $slot.Task = $slot.Command.ExecuteNonQueryAsync()
        }.GetNewClosure()
        Poll = {
            param($slot)
            if ($null -ne $slot.ImmediateOutcome) { return $slot.ImmediateOutcome }
            if (-not $slot.Task.IsCompleted) { return [pscustomobject]@{ State='RUNNING' } }
            try { [void]$slot.Task.GetAwaiter().GetResult(); return [pscustomobject]@{ State='SUCCEEDED' } }
            catch {
                $number = & $sqlNumber $_
                $slot.LastSqlNumber = $number
                $unknown = $number -in @(0,-2,20,64,233,10053,10054,10060,50003)
                return [pscustomobject]@{ State=$(if($unknown){'UNKNOWN'}else{'FAILED'}); Code=('WORKER.SQL_' + $number); SqlNumber=$number }
            }
        }.GetNewClosure()
        Rollback = {
            param($slot)
            if ($null -eq $slot.Transaction) { return }
            if ($null -eq $slot.Transaction.Connection) {
                # SQL1205 garantiert Engine-Rollback. Jede andere bereits beendete
                # Transaktion kann ein unerlaubter Handlercommit gewesen sein.
                if ($slot.LastSqlNumber -ne 1205) { throw 'WORKER.TRANSACTION_DRIFT' }
                $command = & $newCommand $slot.Handler 'SELECT CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 THEN 1 ELSE 0 END;' $Settings.ControlTimeoutSeconds
                try { if ([int]$command.ExecuteScalar() -ne 1) { throw 'WORKER.ROLLBACK_UNKNOWN' } } finally { $command.Dispose() }
            }
            else { $slot.Transaction.Rollback() }
            $finishedTransaction=$slot.Transaction; $slot.Transaction=$null
            try { $finishedTransaction.Dispose() }
            catch { Write-Information ([pscustomobject]@{Event='CLEANUP_FAILED';Code='WORKER.CLEANUP_FAILED'}) -Tags 'ToolbeltQueueWorker' }
        }.GetNewClosure()
        Complete = {
            param($slot)
            & $execute $slot.Handler 'EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken;' (& $bound $slot) $slot.Transaction
            $slot.Transaction.Commit(); $slot.Committed=$true
            $completedTransaction=$slot.Transaction; $slot.Transaction=$null
            try { $completedTransaction.Dispose() }
            catch { Write-Information ([pscustomobject]@{Event='CLEANUP_FAILED';Code='WORKER.CLEANUP_FAILED'}) -Tags 'ToolbeltQueueWorker' }
        }.GetNewClosure()
        Fail = {
            param($slot,$code)
            $parameters = @(& $bound $slot); $parameters += ,@('@Code',[System.Data.SqlDbType]::VarChar,$code,64)
            & $execute $slot.Control 'EXEC toolbelt_core.USP_FailWork @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken,@FailureCode=@Code;' $parameters
        }.GetNewClosure()
        Retry = {
            param($slot,$code)
            $parameters = @(& $bound $slot); $parameters += ,@('@Code',[System.Data.SqlDbType]::VarChar,$code,64)
            $command=& $newCommand $slot.Control 'EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken,@FailureCode=@Code;' $Settings.ControlTimeoutSeconds
            try {
                foreach($parameter in $parameters){& $addParameter $command @parameter}
                $reader=$command.ExecuteReader();$status=$null
                try {
                    do {
                        $statusOrdinal=-1
                        for($i=0;$i -lt $reader.FieldCount;$i++){if($reader.GetName($i) -ceq 'Status'){$statusOrdinal=$i}}
                        while($reader.Read()){if($statusOrdinal -ge 0){if($null -ne $status){throw 'WORKER.RETRY_OUTCOME_UNKNOWN'};$status=[string]$reader.GetValue($statusOrdinal)}}
                    }while($reader.NextResult())
                } finally {$reader.Dispose()}
                return $status
            } finally {$command.Dispose()}
        }.GetNewClosure()
        IsCancelled = {
            param($slot)
            $command = & $newCommand $slot.Control 'SELECT toolbelt_core.SVF_IsCancellationRequested(@ExecutionId);' $Settings.ControlTimeoutSeconds
            try { & $addParameter $command '@ExecutionId' UniqueIdentifier $slot.ExecutionId; return [bool]$command.ExecuteScalar() } finally { $command.Dispose() }
        }.GetNewClosure()
        CanRetry = {
            param($slot,$number)
            # Fachliche Validierung/Ownership/Rechte bleiben terminal, auch wenn der
            # Aufrufer solche Nummern irrtümlich in die lokale Liste einträgt.
            $denied = $number -le 0 -or $number -in @(20,64,102,156,207,208,229,230,233,262,297,515,547,245,2601,2627,2812,8114,8115,8152,11535,11536,15151,15247,15664,10053,10054,10060,50001,50003) -or ($number -ge 51000 -and $number -le 52999)
            return -not $denied -and $Settings.RetryEligibleWorkTypes.Contains($slot.Claim.WorkTypeName) -and $Settings.TransientSqlNumbers.Contains([int]$number)
        }.GetNewClosure()
        Dispose = {
            param($slot)
            try {
                if ($slot.ContextStarted -and $null -ne $slot.Handler -and $slot.Handler.State -eq [System.Data.ConnectionState]::Open) {
                    & $execute $slot.Handler 'EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@ExecutionId;' (,@('@ExecutionId',[System.Data.SqlDbType]::UniqueIdentifier,$slot.ExecutionId)) $slot.Transaction
                }
            } finally {
                if ($null -ne $slot.Command) { $slot.Command.Dispose() }
                if ($null -ne $slot.Transaction) { $slot.Transaction.Dispose() }
                if ($null -ne $slot.Handler) { $slot.Handler.Dispose() }
                $slot.Control.Dispose()
            }
        }.GetNewClosure()
    }
    return $adapter
}

function Start-ExternalQueueWorker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')][string]$ConnectionStringEnvironmentVariable,
        [Parameter(Mandatory)][ValidateCount(1,1000)][string[]]$WorkerEligibleWorkTypes,
        [string[]]$RetryEligibleWorkTypes = @(),
        [int[]]$TransientSqlNumbers = @(),
        [ValidateRange(1,8)][int]$Slots = 1,
        [ValidateRange(1,86400)][int]$MaxRunSeconds = 300,
        [ValidateRange(1,100000)][int]$MaxClaims = 1000,
        [ValidateRange(1,30)][int]$ControlTimeoutSeconds = 5,
        [ValidateRange(1,30)][int]$ConnectTimeoutSeconds = 5,
        [ValidateRange(0.1,10)][double]$PollSeconds = 1,
        [ValidateRange(1,3600)][int]$GraceSeconds = 30,
        [string]$StopFile = ''
    )
    $eligible = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $retry = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($name in $WorkerEligibleWorkTypes) { if ([string]::IsNullOrWhiteSpace($name) -or $name.Length -gt 128 -or -not $eligible.Add($name)) { throw 'WORKER.ELIGIBILITY_INVALID' } }
    foreach ($name in $RetryEligibleWorkTypes) { if (-not $eligible.Contains($name) -or -not $retry.Add($name)) { throw 'WORKER.RETRY_ELIGIBILITY_INVALID' } }
    $numbers = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($number in $TransientSqlNumbers) { if ($number -le 0 -or -not $numbers.Add($number)) { throw 'WORKER.RETRY_NUMBERS_INVALID' } }
    if ($numbers.Count -gt 32) { throw 'WORKER.RETRY_NUMBERS_INVALID' }
    $settings = [pscustomobject]@{ Slots=$Slots; MaxRunSeconds=$MaxRunSeconds; MaxClaims=$MaxClaims; ControlTimeoutSeconds=$ControlTimeoutSeconds; ConnectTimeoutSeconds=$ConnectTimeoutSeconds; PollSeconds=$PollSeconds; GraceSeconds=$GraceSeconds; StopFile=$StopFile; WorkerEligibleWorkTypes=$eligible; RetryEligibleWorkTypes=$retry; TransientSqlNumbers=$numbers }
    $connectionString = [Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable)
    if ([string]::IsNullOrWhiteSpace($connectionString)) { throw 'WORKER.CONNECTION_UNAVAILABLE' }
    try { $adapter = New-WorkerSqlAdapter $settings $connectionString; Invoke-WorkerSupervisor $settings $adapter }
    catch { throw 'WORKER.RUN_FAILED' }
    finally { $connectionString = $null }
}

Export-ModuleMember -Function Start-ExternalQueueWorker
