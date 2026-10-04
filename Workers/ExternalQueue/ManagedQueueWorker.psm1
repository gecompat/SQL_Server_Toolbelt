#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'ExecutionActors.psm1') -Force

# Interner, ausdrücklich gewählter Providerpfad. Die vorhandenen W1-Defaults
# und registrierten Handlerverträge bleiben im Legacy-Modul unverändert.
function New-ManagedConnection($Context) {
    $connection=[System.Data.SqlClient.SqlConnection]::new($Context.ConnectionString)
    try {$connection.Open();return $connection}
    catch {$connection.Dispose();throw}
}
function New-ManagedCommand($Connection,[string]$Text,$Context,$Transaction=$null) {
    $command=$Connection.CreateCommand();$command.CommandText=$Text
    $command.CommandTimeout=$Context.Settings.ControlTimeoutSeconds
    if ($null -ne $Transaction) {$command.Transaction=$Transaction}
    return $command
}
function Add-ManagedParameter($Command,[string]$Name,[System.Data.SqlDbType]$Type,$Value,[int]$Size=0) {
    $parameter=if($Size -eq 0){$Command.Parameters.Add($Name,$Type)}else{$Command.Parameters.Add($Name,$Type,$Size)}
    $parameter.Value=if($null -eq $Value){[DBNull]::Value}else{$Value}
    return $parameter
}
function Add-ManagedRegistration($Command,$Context) {
    [void](Add-ManagedParameter $Command '@WorkerId' UniqueIdentifier $Context.Registration.WorkerId)
    [void](Add-ManagedParameter $Command '@WorkerGeneration' BigInt $Context.Registration.WorkerGeneration)
    [void](Add-ManagedParameter $Command '@WorkerToken' UniqueIdentifier $Context.Registration.WorkerToken)
}
function Add-ManagedAttempt($Command,$Context) {
    [void](Add-ManagedParameter $Command '@SlotReservationId' UniqueIdentifier $Context.Claim.SlotReservationId)
    [void](Add-ManagedParameter $Command '@ClaimToken' UniqueIdentifier $Context.Claim.ClaimToken)
    [void](Add-ManagedParameter $Command '@ExecutionId' UniqueIdentifier $Context.Claim.ExecutionId)
}
function Invoke-ManagedAttempt($Connection,$Context,[string]$Procedure,$Transaction=$null) {
    $command=New-ManagedCommand $Connection ('EXEC toolbelt_core.'+$Procedure+' @SlotReservationId=@SlotReservationId,@ClaimToken=@ClaimToken,@ExecutionId=@ExecutionId;') $Context $Transaction
    try {Add-ManagedAttempt $command $Context;[void]$command.ExecuteNonQuery()}
    finally {$command.Dispose()}
}
function Read-ManagedRow($Reader,[string[]]$Names,[type[]]$Types,[int[]]$Nullable=@(),[switch]$AllowEmpty) {
    if($Reader.FieldCount -ne $Names.Count){throw 'WORKER.MANAGED_SHAPE_INVALID'}
    for($i=0;$i -lt $Names.Count;$i++) {
        if($Reader.GetName($i) -cne $Names[$i] -or $Reader.GetFieldType($i) -ne $Types[$i]){throw 'WORKER.MANAGED_SHAPE_INVALID'}
    }
    $row=$null
    if($Reader.Read()) {
        $values=[ordered]@{}
        for($i=0;$i -lt $Names.Count;$i++) {
            if($Reader.IsDBNull($i)) {
                if($i -notin $Nullable){throw 'WORKER.MANAGED_SHAPE_INVALID'}
                $values[$Names[$i]]=$null
            } else {$values[$Names[$i]]=$Reader.GetValue($i)}
        }
        $row=[pscustomobject]$values
        if($Reader.Read()){throw 'WORKER.MANAGED_SHAPE_INVALID'}
    } elseif(-not $AllowEmpty){throw 'WORKER.MANAGED_SHAPE_INVALID'}
    if($Reader.NextResult()){throw 'WORKER.MANAGED_SHAPE_INVALID'}
    return $row
}
function Read-ManagedStatus($Connection,$Context) {
    $command=New-ManagedCommand $Connection @'
SELECT State,Capacity,HeartbeatSeconds,UnreachableSeconds FROM toolbelt_core.VW_WorkerStatus
WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration;
'@ $Context
    try {
        [void](Add-ManagedParameter $command '@WorkerId' UniqueIdentifier $Context.Registration.WorkerId)
        [void](Add-ManagedParameter $command '@WorkerGeneration' BigInt $Context.Registration.WorkerGeneration)
        $reader=$command.ExecuteReader()
        try {$row=Read-ManagedRow $reader @('State','Capacity','HeartbeatSeconds','UnreachableSeconds') @([string],[int],[int],[int])}
        finally {$reader.Dispose()}
        if($row.State -cnotin @('ACTIVE','PAUSED','DRAINING','UNREACHABLE','CLOSED') -or
            $row.Capacity -lt 1 -or $row.HeartbeatSeconds -lt 1 -or $row.HeartbeatSeconds -gt 3600 -or
            $row.UnreachableSeconds -lt 3*$row.HeartbeatSeconds){throw 'WORKER.MANAGED_STATUS_INVALID'}
        return $row
    } finally {$command.Dispose()}
}
function Read-ManagedExecution($Connection,$Context,$Transaction=$null) {
    $command=New-ManagedCommand $Connection @'
SELECT State,IsHeld,StopStatus FROM toolbelt_core.VW_WorkerExecutionStatus
WHERE SlotReservationId=@SlotReservationId AND ExecutionId=@ExecutionId
AND WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND ClaimGeneration=@ClaimGeneration;
'@ $Context $Transaction
    try {
        [void](Add-ManagedParameter $command '@SlotReservationId' UniqueIdentifier $Context.Claim.SlotReservationId)
        [void](Add-ManagedParameter $command '@ExecutionId' UniqueIdentifier $Context.Claim.ExecutionId)
        [void](Add-ManagedParameter $command '@ClaimGeneration' BigInt $Context.Claim.ClaimGeneration)
        [void](Add-ManagedParameter $command '@WorkerId' UniqueIdentifier $Context.Registration.WorkerId)
        [void](Add-ManagedParameter $command '@WorkerGeneration' BigInt $Context.Registration.WorkerGeneration)
        $reader=$command.ExecuteReader()
        try {return Read-ManagedRow $reader @('State','IsHeld','StopStatus') @([string],[bool],[string])}
        finally {$reader.Dispose()}
    } finally {$command.Dispose()}
}
function Invoke-ManagedGuardian($Shared,$Context) {
    # Die Controllane hat stets eine eigene Connection. Kein SQL läuft parallel
    # auf der Handlerconnection; nur Cancel erhält die gebundene Commandinstanz.
    $connection=$null
    try {
        $connection=New-ManagedConnection $Context
        $status=Read-ManagedExecution $connection $Context
        $stop=$status.IsHeld -or $status.State -cin @('STOP_REQUESTED','STOPPING','UNKNOWN')
        if($Context.Clock.Elapsed.TotalSeconds-$Context.LastRenew -ge 60 -and -not $Shared.Committed) {
            $command=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken;' $Context
            try {
                [void](Add-ManagedParameter $command '@WorkItemId' BigInt $Context.Claim.WorkItemId)
                [void](Add-ManagedParameter $command '@ClaimToken' UniqueIdentifier $Context.Claim.ClaimToken)
                [void]$command.ExecuteNonQuery();$Context.LastRenew=$Context.Clock.Elapsed.TotalSeconds
            } finally {$command.Dispose()}
        }
        if($Context.Clock.Elapsed.TotalSeconds -ge $Context.Budget -and -not $Context.BudgetCancellation -and -not $Shared.Committed) {
            $command=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@ExecutionId,@CancellationReason=N''Worker cooperative budget'';' $Context
            try {
                [void](Add-ManagedParameter $command '@ExecutionId' UniqueIdentifier $Context.Claim.ExecutionId)
                [void]$command.ExecuteNonQuery();$Context.BudgetCancellation=$true
            } finally {$command.Dispose()}
        }
        return [pscustomobject]@{StopRequested=[bool]$stop;HeartbeatConfirmed=$false}
    } catch {$Context.GuardianDiagnostic=Get-ManagedFailureDiagnostic $_ 'GUARDIAN_CONTROL';throw}
    finally {if($null-ne$connection){$connection.Dispose()}}
}
function Get-ManagedSqlNumber($ErrorObject) {
    $exception=$ErrorObject.Exception
    while($null -ne $exception) {
        if($exception -is [System.Data.SqlClient.SqlException]){return [int]$exception.Number}
        $exception=$exception.InnerException
    }
    return 0
}
function Get-ManagedFailureDiagnostic($ErrorObject,[string]$Phase) {
    $number=Get-ManagedSqlNumber $ErrorObject;$state=0;$cause=$ErrorObject.Exception
    while($cause){if($cause-is[System.Data.SqlClient.SqlException]){$state=[int]$cause.State;break};$cause=$cause.InnerException}
    $code='UNSPECIFIED'
    if($ErrorObject.Exception.Message-cin@('WORKER.GUARDIAN_OUTCOME_UNKNOWN','WORKER.ROLLBACK_UNKNOWN','WORKER.HANDLER_INVALID','WORKER.UNSUPPORTED_HANDLER','WORKER.STOP_REQUESTED','WORKER.ACTOR_COMMAND_INVALID','WORKER.ACTOR_STALE_COMMAND','WORKER.CANCEL_DRAIN_UNKNOWN','WORKER.MANAGED_SHAPE_INVALID','WORKER.FAILURE_RECORD_UNKNOWN')){$code=$ErrorObject.Exception.Message}
    return [pscustomobject]@{Phase=$Phase;Code=$code;Category=$ErrorObject.Exception.GetType().Name;SqlNumber=$number;SqlState=$state}
}
function Assert-ManagedGuardian($Shared) {
    if(-not $Shared.GuardianHealthy){throw 'WORKER.GUARDIAN_OUTCOME_UNKNOWN'}
}
function Resolve-ManagedHandler($Connection,$Context,$Transaction) {
    if(-not $Context.Settings.WorkerEligibleWorkTypes.Contains($Context.Claim.WorkTypeName)){throw 'WORKER.UNSUPPORTED_HANDLER'}
    $command=New-ManagedCommand $Connection 'EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName=@Name,@RequireEnabled=1,@RequireExecutableByCaller=1;' $Context $Transaction
    try {
        [void](Add-ManagedParameter $command '@Name' VarChar $Context.Claim.WorkTypeName 128)
        $reader=$command.ExecuteReader()
        try {
            if(-not $reader.Read()){throw 'WORKER.HANDLER_INVALID'}
            $schema=[string]$reader['HandlerSchema'];$procedure=[string]$reader['HandlerProcedure'];$mode=[string]$reader['ParameterMode']
            $Context.Budget=[int]$reader['DefaultTimeoutSeconds']
            if($Context.Budget -lt 1 -or $Context.Budget -gt 86400){throw 'WORKER.HANDLER_INVALID'}
            if($reader.Read()){throw 'WORKER.HANDLER_INVALID'}
            while($reader.NextResult()){while($reader.Read()){}}
        } finally {$reader.Dispose()}
    } finally {$command.Dispose()}
    $qualified='['+$schema.Replace(']',']]')+'].['+$procedure.Replace(']',']]')+']'
    $command=New-ManagedCommand $Connection @'
SELECT CASE WHEN @Mode='NONE' AND NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Qualified) AND parameter_id>0) THEN 1
 WHEN @Mode='JSON_PAYLOAD' AND (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(@Qualified) AND parameter_id>0)=1
 AND EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Qualified) AND parameter_id=1 AND name COLLATE Latin1_General_100_BIN2=N'@PayloadJson'
 AND system_type_id=231 AND user_type_id=231 AND max_length=-1 AND is_output=0) THEN 1 ELSE 0 END;
'@ $Context $Transaction
    try {
        [void](Add-ManagedParameter $command '@Mode' VarChar $mode 16)
        [void](Add-ManagedParameter $command '@Qualified' NVarChar $qualified 517)
        if([int]$command.ExecuteScalar() -ne 1){throw 'WORKER.HANDLER_INVALID'}
    } finally {$command.Dispose()}
    if($mode -ceq 'NONE' -and $null -ne $Context.Claim.PayloadJson){throw 'WORKER.HANDLER_INVALID'}
    if($mode -ceq 'JSON_PAYLOAD') {
        $payload=$Context.Claim.PayloadJson
        if($null -eq $payload -or [System.Text.Encoding]::Unicode.GetByteCount($payload) -gt 65536 -or -not $payload.TrimStart().StartsWith('{')){throw 'WORKER.HANDLER_INVALID'}
        try {$json=[System.Text.Json.JsonDocument]::Parse($payload);$json.Dispose()}catch{throw 'WORKER.HANDLER_INVALID'}
    }
    return [pscustomobject]@{Qualified=$qualified;Mode=$mode}
}
function Invoke-ManagedExecutor($Shared,$Context) {
    $connection=$null;$transaction=$null;$command=$null;$epoch=0L
    $bound=$false;$contextStarted=$false;$taskEnded=$true;$rollback=$false;$disposed=$true
    $original=$null;$sqlNumber=0;$commitAttempted=$false;$diagnosticPhase='BIND'
    try {
        $connection=New-ManagedConnection $Context
        $bind=New-ManagedCommand $connection @'
EXEC toolbelt_core.USP_BindWorkerExecution @SlotReservationId=@SlotReservationId,@WorkerId=@WorkerId,
 @WorkerGeneration=@WorkerGeneration,@WorkerToken=@WorkerToken,@ClaimGeneration=@ClaimGeneration,@ClaimToken=@ClaimToken,@ExecutionId=@ExecutionId;
'@ $Context
        try {
            Add-ManagedRegistration $bind $Context;Add-ManagedAttempt $bind $Context
            [void](Add-ManagedParameter $bind '@ClaimGeneration' BigInt $Context.Claim.ClaimGeneration)
            [void]$bind.ExecuteNonQuery();$bound=$true
        } finally {$bind.Dispose()}
        $diagnosticPhase='BEGIN_CONTEXT'
        $begin=New-ManagedCommand $connection @'
DECLARE @Id uniqueidentifier=@ExecutionId;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@AllowNested=0;
EXEC sys.sp_set_session_context @key=N'toolbelt.worker.work_item_id',@value=@WorkItemId,@read_only=1;
EXEC sys.sp_set_session_context @key=N'toolbelt.worker.claim_generation',@value=@Generation,@read_only=1;
EXEC sys.sp_set_session_context @key=N'toolbelt.worker.execution_id',@value=@ExecutionId,@read_only=1;
'@ $Context
        try {
            [void](Add-ManagedParameter $begin '@ExecutionId' UniqueIdentifier $Context.Claim.ExecutionId)
            [void](Add-ManagedParameter $begin '@WorkItemId' BigInt $Context.Claim.WorkItemId)
            [void](Add-ManagedParameter $begin '@Generation' BigInt $Context.Claim.ClaimGeneration)
            [void]$begin.ExecuteNonQuery();$contextStarted=$true
        } finally {$begin.Dispose()}
        $diagnosticPhase='BEGIN_TRANSACTION'
        $transaction=$connection.BeginTransaction([System.Data.IsolationLevel]::ReadCommitted)
        $diagnosticPhase='TRANSACTION_WITNESS'
        Invoke-ManagedAttempt $connection $Context 'USP_BeginWorkerTransactionWitness' $transaction
        $diagnosticPhase='RESOLVE_HANDLER'
        $handler=Resolve-ManagedHandler $connection $Context $transaction
        if($Shared.StopRequested -or (Read-ManagedExecution $connection $Context $transaction).IsHeld){throw 'WORKER.STOP_REQUESTED'}
        $text='EXEC @HandlerReturnCode = '+$handler.Qualified+$(if($handler.Mode -ceq 'JSON_PAYLOAD'){' @PayloadJson=@PayloadJson'}else{''})+' WITH RESULT SETS NONE; IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR ISNULL(toolbelt_core.SVF_CurrentExecutionId(),''00000000-0000-0000-0000-000000000000'')<>CONVERT(uniqueidentifier,SESSION_CONTEXT(N''toolbelt.worker.execution_id'')) THROW 50003,N''Worker transaction discipline violated'',1;'
        $command=New-ManagedCommand $connection $text $Context $transaction;$command.CommandTimeout=0
        if($handler.Mode -ceq 'JSON_PAYLOAD'){[void](Add-ManagedParameter $command '@PayloadJson' NVarChar $Context.Claim.PayloadJson -1)}
        $returnCode=$command.Parameters.Add('@HandlerReturnCode',[System.Data.SqlDbType]::Int);$returnCode.Direction=[System.Data.ParameterDirection]::Output
        $diagnosticPhase='HANDLER'
        $epoch=Publish-WorkerExecutionCommand $Shared $command
        $token=Get-WorkerExecutionCancellationToken $Shared $epoch
        $taskEnded=$false
        try {$task=$command.ExecuteNonQueryAsync($token);[void]$task.GetAwaiter().GetResult()}
        finally {$taskEnded=$true;Clear-ManagedCommand $Shared $epoch;$epoch=0L}
        Assert-ManagedGuardian $Shared
        $diagnosticPhase='COMPLETING';$Shared.Phase='COMPLETING'
        Invoke-ManagedAttempt $connection $Context 'USP_BeginWorkerCompletion' $transaction
        $complete=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken;' $Context $transaction
        try {
            [void](Add-ManagedParameter $complete '@WorkItemId' BigInt $Context.Claim.WorkItemId)
            [void](Add-ManagedParameter $complete '@ClaimToken' UniqueIdentifier $Context.Claim.ClaimToken)
            [void]$complete.ExecuteNonQuery()
        } finally {$complete.Dispose()}
        Assert-ManagedGuardian $Shared
        $diagnosticPhase='COMMITTING';$Shared.Phase='COMMITTING';$commitAttempted=$true
        $transaction.Commit();$Shared.Committed=$true
        # Der tatsächliche Commit ist bereits primär bekannt. Ein verlorenes
        # End-Acknowledge verändert weder diesen Fakt noch die Retryentscheidung.
        Invoke-ManagedAttempt $connection $Context 'USP_RecordWorkerCommit'
        $Context.Terminal='COMMITTED';$Context.SlotEndConfirmed=$true
    } catch {
        $original=$_;$sqlNumber=Get-ManagedSqlNumber $_;$Context.PrimaryDiagnostic=Get-ManagedFailureDiagnostic $_ $diagnosticPhase
        if($Shared.Committed){$Shared.SecondaryCode='WORKER.COMMIT_RECORD_UNKNOWN'}
        elseif($bound -and -not $commitAttempted -and $null -eq $Shared.Command -and $Shared.CancelReaders -eq 0) {
            try {
                $diagnosticPhase='ROLLBACK'
                if($null -ne $transaction) {
                    if($null -ne $transaction.Connection){$transaction.Rollback()}
                    elseif($sqlNumber -ne 1205){throw 'WORKER.ROLLBACK_UNKNOWN'}
                }
                $rollback=$true
                # Tatsächlicher Rollback bleibt als Fakt erhalten. Verlorene
                # Guardianautorität erlaubt jedoch weder Freigabe noch Retry.
                Assert-ManagedGuardian $Shared
                $diagnosticPhase='RECORD_ROLLBACK'
                Invoke-ManagedAttempt $connection $Context 'USP_RecordWorkerRollback'
                $status=Read-ManagedExecution $connection $Context
                if($status.IsHeld -and $status.StopStatus -ceq 'ROLLED_BACK_HELD') {
                    $Context.Terminal='ROLLED_BACK_HELD';$Context.SlotEndConfirmed=$true
                } else {
                    Assert-ManagedGuardian $Shared
                    $denied=$sqlNumber -le 0 -or $sqlNumber -in @(20,64,102,156,207,208,229,230,233,262,297,515,547,245,2601,2627,2812,8114,8115,8152,11535,11536,15151,15247,15664,10053,10054,10060,50001,50003) -or ($sqlNumber -ge 51000 -and $sqlNumber -le 54999)
                    $retry=-not $denied -and $Context.Settings.RetryEligibleWorkTypes.Contains($Context.Claim.WorkTypeName) -and $Context.Settings.TransientSqlNumbers.Contains($sqlNumber)
                    $failure=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_FinalizeWorkerFailure @SlotReservationId=@SlotReservationId,@ClaimToken=@ClaimToken,@ExecutionId=@ExecutionId,@FailureCode=@FailureCode,@Retry=@Retry,@Outcome=@Outcome OUTPUT;' $Context
                    try {
                        Assert-ManagedGuardian $Shared
                        Add-ManagedAttempt $failure $Context
                        [void](Add-ManagedParameter $failure '@FailureCode' VarChar ('WORKER.SQL_'+$sqlNumber) 64)
                        [void](Add-ManagedParameter $failure '@Retry' Bit $retry)
                        $out=Add-ManagedParameter $failure '@Outcome' VarChar $null 24;$out.Direction=[System.Data.ParameterDirection]::Output
                        [void]$failure.ExecuteNonQuery()
                        if($out.Value -isnot [string] -or $out.Value -cnotin @('FAILED','RETRY_WAIT','DEAD_LETTER','ROLLED_BACK_HELD')){throw 'WORKER.FAILURE_RECORD_UNKNOWN'}
                        $Context.Terminal=[string]$out.Value;$Context.SlotEndConfirmed=$true
                    } finally {$failure.Dispose()}
                }
            } catch {$Context.FailureDiagnostic=Get-ManagedFailureDiagnostic $_ $diagnosticPhase;$Shared.SecondaryCode='WORKER.FAILURE_RECORD_UNKNOWN'}
        }
        if(-not $Shared.Committed -and -not $Context.SlotEndConfirmed) {
            try {
                $control=New-ManagedConnection $Context
                try {
                    $unknown=New-ManagedCommand $control 'EXEC toolbelt_core.USP_RecordWorkerUnknown @SlotReservationId=@SlotReservationId,@WorkerToken=@WorkerToken,@ExecutionId=@ExecutionId;' $Context
                    try {
                        [void](Add-ManagedParameter $unknown '@SlotReservationId' UniqueIdentifier $Context.Claim.SlotReservationId)
                        [void](Add-ManagedParameter $unknown '@WorkerToken' UniqueIdentifier $Context.Registration.WorkerToken)
                        [void](Add-ManagedParameter $unknown '@ExecutionId' UniqueIdentifier $Context.Claim.ExecutionId)
                        [void]$unknown.ExecuteNonQuery()
                    } finally {$unknown.Dispose()}
                } finally {$control.Dispose()}
            } catch {$Shared.SecondaryCode='WORKER.UNKNOWN_RECORD_FAILED'}
        }
    } finally {
        if($epoch -ne 0) {
            try {Clear-ManagedCommand $Shared $epoch}
            catch {$disposed=$false;$Shared.SecondaryCode='WORKER.CANCEL_DRAIN_UNKNOWN'}
        }
        # Bei unbekanntem Cancel-Ende gehört die Commandinstanz weiterhin dem
        # Executor. Kein Dispose des Commands oder seiner Connection unter Cancel.
        if($null -eq $Shared.Command -and $Shared.CancelReaders -eq 0) {
            if($contextStarted -and $null -ne $connection -and $connection.State -eq [System.Data.ConnectionState]::Open -and ($Shared.Committed -or $rollback)) {
                try {
                    $end=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@ExecutionId;' $Context
                    try {[void](Add-ManagedParameter $end '@ExecutionId' UniqueIdentifier $Context.Claim.ExecutionId);[void]$end.ExecuteNonQuery()}finally{$end.Dispose()}
                } catch {$disposed=$false;$Shared.SecondaryCode='WORKER.CONTEXT_END_FAILED'}
            }
            foreach($resource in @($command,$transaction,$connection)) {
                if($null -ne $resource){try{$resource.Dispose()}catch{$disposed=$false;$Shared.SecondaryCode='WORKER.RESOURCE_DISPOSE_FAILED'}}
            }
        } else {$disposed=$false}
        $Shared.ExecutionEnded=$taskEnded;$Shared.ResourcesDisposed=$disposed
        $Context.PrimaryError=$original
    }
    return [pscustomobject]@{Committed=[bool]$Shared.Committed;RollbackConfirmed=$rollback;ExecutionEnded=$taskEnded;ResourcesDisposed=$disposed}
}
function Clear-ManagedCommand($Shared,[long]$Epoch) {
    $clock=[System.Diagnostics.Stopwatch]::StartNew()
    while(-not (Clear-WorkerExecutionCommand $Shared $Epoch)) {
        if($clock.ElapsedMilliseconds -ge 30000){throw 'WORKER.CANCEL_DRAIN_UNKNOWN'}
        [System.Threading.Thread]::Sleep(10)
    }
}

function Invoke-ManagedRegistrationLane($Context,$Lane) {
    $clock=[System.Diagnostics.Stopwatch]::StartNew();$last=-1.0
    try {
        while(-not $Lane.Stop) {
            if($last -lt 0 -or $clock.Elapsed.TotalSeconds-$last -ge $Lane.HeartbeatSeconds) {
                $connection=New-ManagedConnection $Context
                try {
                    $command=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_HeartbeatWorker @WorkerId=@WorkerId,@WorkerGeneration=@WorkerGeneration,@WorkerToken=@WorkerToken;' $Context
                    try {Add-ManagedRegistration $command $Context;[void]$command.ExecuteNonQuery()}finally{$command.Dispose()}
                    $status=Read-ManagedStatus $connection $Context
                    # Intervalle sind an die registrierte Generation gebunden;
                    # spätere Konfiguration wird hier nicht still übernommen.
                    if($status.HeartbeatSeconds -ne $Lane.HeartbeatSeconds -or $status.UnreachableSeconds -ne $Lane.UnreachableSeconds){throw 'WORKER.GENERATION_INTERVAL_DRIFT'}
                    $Lane.State=$status.State;$Lane.Capacity=$status.Capacity;$Lane.Heartbeats++
                    $last=$clock.Elapsed.TotalSeconds
                } finally {$connection.Dispose()}
            }
            [System.Threading.Thread]::Sleep(100)
        }
    } catch {$Lane.Healthy=$false;$Lane.Code='WORKER.REGISTRATION_CONTROL_FAILED'}
    finally {$Lane.Ended=$true}
}
function Read-ManagedClaim($Connection,$Context) {
    $command=New-ManagedCommand $Connection 'EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@WorkerId,@WorkerGeneration=@WorkerGeneration,@WorkerToken=@WorkerToken;' $Context
    try {
        Add-ManagedRegistration $command $Context
        $reader=$command.ExecuteReader()
        try {
            $row=Read-ManagedRow $reader @('WorkItemId','WorkTypeName','PayloadJson','ClaimToken','ClaimedAtUtc','ClaimGeneration','LeaseUntilUtc','LastHeartbeatAtUtc','SlotReservationId','ExecutionId') @([long],[string],[string],[guid],[datetime],[long],[datetime],[datetime],[guid],[guid]) @(2) -AllowEmpty
        } finally {$reader.Dispose()}
        if($null -ne $row -and ($row.WorkItemId -le 0 -or $row.ClaimGeneration -le 0 -or
            $row.ClaimToken -eq [guid]::Empty -or $row.SlotReservationId -eq [guid]::Empty -or $row.ExecutionId -eq [guid]::Empty)){throw 'WORKER.MANAGED_CLAIM_INVALID'}
        return $row
    } finally {$command.Dispose()}
}
function Invoke-ManagedQueueWorker($Settings,[string]$ConnectionString,[guid]$WorkerId,[int]$Capacity,[string]$RunMode) {
    $builder=[System.Data.SqlClient.SqlConnectionStringBuilder]::new($ConnectionString)
    if(-not $builder.Encrypt){throw 'WORKER.ENCRYPTION_REQUIRED'}
    $builder['Connect Timeout']=$Settings.ConnectTimeoutSeconds
    $builder.ConnectRetryCount=0;$builder.Pooling=$false;$builder.Enlist=$false;$builder.MultipleActiveResultSets=$false
    $context=[pscustomobject]@{ConnectionString=$builder.ConnectionString;Settings=$Settings;Registration=$null}
    $modulePath=$PSCommandPath;$connection=$null;$laneShell=$null;$laneTask=$null;$lane=$null
    $active=[System.Collections.Generic.List[object]]::new()
    $counts=[ordered]@{Status='COMPLETED';Managed=$true;Claims=0L;Completed=0L;Failed=0L;Retried=0L;DeadLetter=0L;Held=0L;Unresolved=0L;SlotEndUnconfirmed=0L;CleanupFailed=0L}
    $draining=$false;$clock=[System.Diagnostics.Stopwatch]::StartNew()
    try {
        $connection=New-ManagedConnection $context
        $preflight=New-ManagedCommand $connection @'
SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND
 ((name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.1.0')
 OR(name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR(name=N'Toolbelt.Module.toolbelt.core.work-type.Version' AND CONVERT(nvarchar(64),value)=N'1.1.0')
 OR(name=N'Toolbelt.Module.toolbelt.core.execution-context.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR(name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0'));
'@ $context
        try {if([int]$preflight.ExecuteScalar() -ne 5){throw 'WORKER.DEPENDENCY_UNAVAILABLE'}}finally{$preflight.Dispose()}
        $register=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@WorkerId,@Capacity=@Capacity,@RunMode=@RunMode;' $context
        try {
            [void](Add-ManagedParameter $register '@WorkerId' UniqueIdentifier $(if($WorkerId -eq [guid]::Empty){[guid]::NewGuid()}else{$WorkerId}))
            [void](Add-ManagedParameter $register '@Capacity' Int $Capacity)
            [void](Add-ManagedParameter $register '@RunMode' VarChar $RunMode 16)
            $reader=$register.ExecuteReader()
            try {$context.Registration=Read-ManagedRow $reader @('WorkerId','WorkerGeneration','WorkerToken','ConfigVersion') @([guid],[long],[guid],[byte[]])}
            finally {$reader.Dispose()}
        } finally {$register.Dispose()}
        if($context.Registration.WorkerId -eq [guid]::Empty -or $context.Registration.WorkerToken -eq [guid]::Empty -or $context.Registration.WorkerGeneration -le 0 -or $context.Registration.ConfigVersion.Length -ne 8){throw 'WORKER.REGISTRATION_INVALID'}
        $status=Read-ManagedStatus $connection $context
        $lane=[hashtable]::Synchronized(@{Stop=$false;Ended=$false;Healthy=$true;Code='';Heartbeats=0L
            State=$status.State;Capacity=$status.Capacity;HeartbeatSeconds=$status.HeartbeatSeconds;UnreachableSeconds=$status.UnreachableSeconds})
        $laneShell=[powershell]::Create()
        [void]$laneShell.AddScript('param($path,$context,$lane) Import-Module $path -Force; Invoke-ManagedRegistrationLane $context $lane').AddArgument($modulePath).AddArgument($context).AddArgument($lane)
        $laneTask=$laneShell.BeginInvoke()
        while($true) {
            $shouldDrain=(-not $lane.Healthy -or $lane.State -cin @('UNREACHABLE','CLOSED','DRAINING') -or
                ($Settings.StopFile -and (Test-Path -LiteralPath $Settings.StopFile -PathType Leaf)) -or
                ($RunMode -ceq 'BOUNDED' -and ($clock.Elapsed.TotalSeconds -ge $Settings.MaxRunSeconds -or $counts.Claims -ge $Settings.MaxClaims)))
            if($shouldDrain){$draining=$true}
            foreach($actor in @($active.ToArray())) {
                $state=Get-WorkerExecutionActorState $actor
                if(-not $state.ExecutorFinished -or -not $state.GuardianFinished){continue}
                $physical=Close-WorkerExecutionActor $actor
                $result=$actor.Shared.Context
                # Commit, belegte SQL-Slotfreigabe und physischer Cleanup sind
                # getrennt. Ein bekannter Commit wird unter keinem Fehler retried.
                if($state.Committed){$counts.Completed++}
                elseif($result.SlotEndConfirmed) {
                    switch -CaseSensitive ($result.Terminal) {
                        'RETRY_WAIT' {$counts.Retried++}
                        'DEAD_LETTER' {$counts.DeadLetter++}
                        'ROLLED_BACK_HELD' {$counts.Held++}
                        'FAILED' {$counts.Failed++}
                        default {$counts.Unresolved++}
                    }
                } else {$counts.Unresolved++}
                if(-not $physical -or -not $state.ResourcesDisposed -or $state.SecondaryCode -ne ''){$counts.CleanupFailed++}
                if(-not $result.SlotEndConfirmed){$counts.SlotEndUnconfirmed++;$draining=$true}
                Write-Information ([pscustomobject]@{Event='MANAGED_EXECUTION_ENDED';Outcome=$state.Outcome;SlotEndConfirmed=$result.SlotEndConfirmed;ResourcesDisposed=$state.ResourcesDisposed;Code=$state.SecondaryCode;ActorPhase=$state.Phase;GuardianHealthy=$state.GuardianHealthy;RollbackConfirmed=$state.RollbackConfirmed;PrimaryCode=$state.PrimaryCode;PrimaryDiagnostic=$result.PrimaryDiagnostic;FailureDiagnostic=$result.FailureDiagnostic;GuardianDiagnostic=$result.GuardianDiagnostic;GuardianOuterDiagnostic=$actor.Shared.GuardianOuterDiagnostic}) -Tags 'ToolbeltQueueWorker'
                # Ein nicht entsorgter Actor bleibt referenziert; keine vorgespielte
                # Ressourcenfreigabe durch bloßes Entfernen aus einer Liste.
                if($physical){[void]$active.Remove($actor)}else{$draining=$true}
            }
            if(-not $draining -and $lane.State -ceq 'ACTIVE' -and $active.Count -lt $lane.Capacity) {
                try {$claim=Read-ManagedClaim $connection $context}
                catch {$counts.Unresolved++;$draining=$true;continue}
                if($null -ne $claim) {
                    $counts.Claims++
                    $execution=[hashtable]::Synchronized(@{ConnectionString=$context.ConnectionString;Settings=$Settings
                        Registration=$context.Registration;Claim=$claim;ModulePath=$modulePath
                        Clock=[System.Diagnostics.Stopwatch]::StartNew();LastRenew=0.0;Budget=86400
                        BudgetCancellation=$false;Terminal='UNKNOWN';SlotEndConfirmed=$false;PrimaryError=$null;PrimaryDiagnostic=$null;FailureDiagnostic=$null;GuardianDiagnostic=$null})
                    $executor={param($shared,$context) Import-Module $context.ModulePath -Force;Invoke-ManagedExecutor $shared $context}
                    $guardian={param($shared,$context) if(-not (Get-Module ManagedQueueWorker)){Import-Module $context.ModulePath -Force};Invoke-ManagedGuardian $shared $context}
                    $actor=New-WorkerExecutionActor $claim.ExecutionId $executor $guardian $execution -PollMilliseconds ([int]($Settings.PollSeconds*1000))
                    $active.Add($actor)
                    try {Start-WorkerExecutionActor $actor}
                    catch {$draining=$true}
                } elseif($RunMode -ceq 'BOUNDED' -and $active.Count -eq 0){$draining=$true}
            }
            if($draining -and $active.Count -eq 0){break}
            [System.Threading.Thread]::Sleep([int]($Settings.PollSeconds*1000))
        }
        if($counts.Unresolved -gt 0){$counts.Status='OUTCOME_UNKNOWN'}
        elseif($counts.SlotEndUnconfirmed -gt 0){$counts.Status='END_RECORD_UNKNOWN'}
        elseif($counts.CleanupFailed -gt 0){$counts.Status='CLEANUP_FAILED'}
    } finally {
        if($null -ne $lane){$lane.Stop=$true}
        $laneClosed=$true
        if($null -ne $laneTask) {
            $wait=[System.Diagnostics.Stopwatch]::StartNew()
            while(-not $laneTask.IsCompleted -and $wait.Elapsed.TotalSeconds -lt 2*($Settings.ControlTimeoutSeconds+$Settings.ConnectTimeoutSeconds)+2){[System.Threading.Thread]::Sleep(20)}
            if($laneTask.IsCompleted){try{[void]$laneShell.EndInvoke($laneTask)}catch{$laneClosed=$false}}
            else{$laneClosed=$false}
        }
        if($null -ne $laneShell -and ($null -eq $laneTask -or $laneTask.IsCompleted)){try{$laneShell.Dispose()}catch{$laneClosed=$false}}
        if($active.Count -gt 0){$counts.Status='OUTCOME_UNKNOWN'}
        if($null -ne $connection) {
            if($null -ne $context.Registration -and $active.Count -eq 0 -and $laneClosed) {
                try {
                    $close=New-ManagedCommand $connection 'EXEC toolbelt_core.USP_CloseWorker @WorkerId=@WorkerId,@WorkerGeneration=@WorkerGeneration,@WorkerToken=@WorkerToken;' $context
                    try{Add-ManagedRegistration $close $context;[void]$close.ExecuteNonQuery()}finally{$close.Dispose()}
                } catch {$counts.CleanupFailed++;if($counts.Status -ceq 'COMPLETED'){$counts.Status='CLEANUP_FAILED'}}
            }
            $connection.Dispose()
        }
        if(-not $laneClosed){$counts.Status='OUTCOME_UNKNOWN'}
        $context.ConnectionString=$null
    }
    return [pscustomobject]$counts
}

Export-ModuleMember -Function Invoke-ManagedQueueWorker,Invoke-ManagedExecutor,Invoke-ManagedGuardian,Invoke-ManagedRegistrationLane
