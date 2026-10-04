#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Interne Providerkomponente: SQL-Ownership und Endnachweise liefert erst der
# konkrete Adapter. Scriptblocks sind keine Parameter der öffentlichen Start-API.
function New-WorkerExecutionActor {
    param([Parameter(Mandatory)][guid]$ExecutionId,
          [Parameter(Mandatory)][scriptblock]$Executor,
          [Parameter(Mandatory)][scriptblock]$GuardianControl,
          [Parameter(Mandatory)]$Context,
          [ValidateRange(10,30000)][int]$PollMilliseconds = 1000)
    if ($ExecutionId -eq [guid]::Empty) { throw 'WORKER.ACTOR_ID_INVALID' }
    # Die Operationen verwenden ausschließlich explizite Argumente. Fremde
    # Closures werden nicht als im neuen Runspace gebunden vorausgesetzt.
    $shared = [hashtable]::Synchronized(@{
        ExecutionId=$ExecutionId; Gate=[object]::new(); Context=$Context
        Command=$null; CommandCancellation=$null; Epoch=0L; CancelReaders=0; CancelAttempted=$false
        CancelEpoch=0L; StopRequested=$false; ExecutorFinished=$false
        GuardianFinished=$false; GuardianHealthy=$true; Heartbeats=0L
        Phase='PREPARED'; Outcome='UNKNOWN'; Committed=$false
        RollbackConfirmed=$false; ExecutionEnded=$false; ResourcesDisposed=$false
        PrimaryCode=''; SecondaryCode=''; GuardianOuterDiagnostic=$null
    })
    [pscustomobject]@{ Shared=$shared; ExecutorSource=$Executor.ToString()
        GuardianSource=$GuardianControl.ToString(); PollMilliseconds=$PollMilliseconds
        ModulePath=$PSCommandPath; ExecutorShell=$null; GuardianShell=$null
        ExecutorTask=$null; GuardianTask=$null; ExecutorJoined=$false
        GuardianJoined=$false; ExecutorDisposed=$false; GuardianDisposed=$false
        Disposed=$false }
}

function Publish-WorkerExecutionCommand {
    param([Parameter(Mandatory)][hashtable]$Shared,
          [Parameter(Mandatory)]$Command)
    [System.Threading.Monitor]::Enter($Shared.Gate)
    try {
        if ($Shared.StopRequested -or $null -ne $Shared.Command -or
            $Shared.ExecutorFinished -or $Shared.Epoch -eq [long]::MaxValue) {
            throw 'WORKER.ACTOR_COMMAND_INVALID'
        }
        $Shared.Epoch++; $Shared.Command=$Command
        $Shared.CommandCancellation=[System.Threading.CancellationTokenSource]::new()
        return [long]$Shared.Epoch
    } finally { [System.Threading.Monitor]::Exit($Shared.Gate) }
}

function Get-WorkerExecutionCancellationToken {
    param([Parameter(Mandatory)][hashtable]$Shared,[long]$ExpectedEpoch)
    [System.Threading.Monitor]::Enter($Shared.Gate)
    try {
        if ($Shared.Epoch -ne $ExpectedEpoch -or $null -eq $Shared.Command -or
            $null -eq $Shared.CommandCancellation) { throw 'WORKER.ACTOR_STALE_COMMAND' }
        # Der Executor übergibt genau diesen Token an ExecuteNonQueryAsync.
        # Ein Stop vor dessen Start bleibt damit wirksam, auch wenn Cancel noch
        # keinen laufenden SqlCommand erreichen konnte.
        return $Shared.CommandCancellation.Token
    } finally { [System.Threading.Monitor]::Exit($Shared.Gate) }
}

function Clear-WorkerExecutionCommand {
    param([Parameter(Mandatory)][hashtable]$Shared,[long]$ExpectedEpoch)
    [System.Threading.Monitor]::Enter($Shared.Gate)
    try {
        if ($Shared.Epoch -ne $ExpectedEpoch -or $null -eq $Shared.Command) {
            throw 'WORKER.ACTOR_STALE_COMMAND'
        }
        # Während eines Cancel-Aufrufs bleibt die Instanz dem Executor gehörig;
        # weder der Guardian noch ein paralleler Cleanup darf sie entsorgen.
        if ($Shared.CancelReaders -ne 0) { return $false }
        $Shared.CommandCancellation.Dispose()
        $Shared.CommandCancellation=$null; $Shared.Command=$null
        return $true
    } finally { [System.Threading.Monitor]::Exit($Shared.Gate) }
}

function Invoke-WorkerExecutionCancellation {
    param([Parameter(Mandatory)][hashtable]$Shared,[long]$ExpectedEpoch)
    $command=$null; $cancellation=$null
    [System.Threading.Monitor]::Enter($Shared.Gate)
    try {
        if (-not $Shared.StopRequested -or $Shared.Epoch -ne $ExpectedEpoch -or
            $null -eq $Shared.Command -or $Shared.ExecutorFinished) { return $false }
        if ($Shared.CancelEpoch -eq $ExpectedEpoch) { return $false }
        $Shared.CancelReaders++; $Shared.CancelEpoch=$ExpectedEpoch
        $Shared.CancelAttempted=$true; $command=$Shared.Command
        $cancellation=$Shared.CommandCancellation
    } finally { [System.Threading.Monitor]::Exit($Shared.Gate) }
    try {
        # Nur diese gebundene Instanz; Cancel ist kein End-/Rollbacknachweis.
        # Beide Aktionen bleiben an denselben Epoch gebunden. Der gelatchte
        # Token schließt die Lücke zwischen Veröffentlichung und Taskstart.
        try { $cancellation.Cancel() } finally { $command.Cancel() }
        return $true
    } finally {
        [System.Threading.Monitor]::Enter($Shared.Gate)
        try { $Shared.CancelReaders-- }
        finally { [System.Threading.Monitor]::Exit($Shared.Gate) }
    }
}

function Start-WorkerExecutionActor {
    param([Parameter(Mandatory)]$Actor)
    if ($Actor.Disposed -or $null -ne $Actor.ExecutorShell) { throw 'WORKER.ACTOR_START_INVALID' }
    $executorBody = {
        param($shared,$source,$modulePath)
        $ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
        try {
            Import-Module $modulePath -Force
            $shared.Phase='EXECUTING'
            $evidence=& ([scriptblock]::Create($source)) $shared $shared.Context
            $valid=$null -ne $evidence
            foreach ($name in @('Committed','RollbackConfirmed','ExecutionEnded','ResourcesDisposed')) {
                if ($null -eq $evidence -or $null -eq $evidence.PSObject.Properties[$name] -or
                    $evidence.$name -isnot [bool]) { $valid=$false }
            }
            if ($valid -and $evidence.Committed -and $evidence.RollbackConfirmed) { $valid=$false }
            if ($valid) {
                $shared.Committed=$shared.Committed -or $evidence.Committed
                $shared.RollbackConfirmed=$evidence.RollbackConfirmed
                $shared.ExecutionEnded=$evidence.ExecutionEnded
                $shared.ResourcesDisposed=$evidence.ResourcesDisposed
                if ($evidence.ExecutionEnded -and $evidence.ResourcesDisposed -and
                    $null -eq $shared.Command -and $shared.CancelReaders -eq 0) {
                    if ($evidence.Committed) { $shared.Outcome='COMMITTED' }
                    elseif ($evidence.RollbackConfirmed) { $shared.Outcome='ROLLED_BACK' }
                }
            }
            if ($shared.Committed) { $shared.Outcome='COMMITTED' }
            elseif ($shared.Outcome -eq 'UNKNOWN') { $shared.PrimaryCode='WORKER.ACTOR_END_UNKNOWN' }
        } catch {
            if ($shared.Committed) {
                $shared.Outcome='COMMITTED'; $shared.SecondaryCode='WORKER.ACTOR_POSTCOMMIT_FAILED'
            } else { $shared.Outcome='UNKNOWN'; $shared.PrimaryCode='WORKER.ACTOR_EXECUTOR_FAILED' }
        } finally { $shared.Phase='ENDED'; $shared.ExecutorFinished=$true }
    }
    $guardianBody = {
        param($shared,$source,$modulePath,$pollMilliseconds)
        $ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
        $diagnosticPhase='GUARDIAN_IMPORT'
        try {
            Import-Module $modulePath -Force
            $cancelCandidates=@(Get-Command Invoke-WorkerExecutionCancellation -Module ExecutionActors -CommandType Function -ErrorAction Stop)
            if($cancelCandidates.Count-ne1 -or $cancelCandidates[0].ModuleName-cne'ExecutionActors' -or
                -not[string]::Equals([IO.Path]::GetFullPath($cancelCandidates[0].Module.Path),[IO.Path]::GetFullPath($modulePath),[StringComparison]::OrdinalIgnoreCase)){
                throw 'WORKER.ACTOR_CANCEL_BINDING_INVALID'
            }
            $cancelCommand=$cancelCandidates[0]
            while (-not $shared.ExecutorFinished) {
                $diagnosticPhase='GUARDIAN_SOURCE'
                $control=& ([scriptblock]::Create($source)) $shared $shared.Context
                $diagnosticPhase='GUARDIAN_RESULT'
                if ($null -eq $control -or $control.StopRequested -isnot [bool] -or
                    $control.HeartbeatConfirmed -isnot [bool]) { throw 'WORKER.ACTOR_CONTROL_INVALID' }
                [System.Threading.Monitor]::Enter($shared.Gate)
                try {
                    if ($control.StopRequested) { $shared.StopRequested=$true }
                    if ($control.HeartbeatConfirmed) { $shared.Heartbeats++ }
                    $epoch=[long]$shared.Epoch
                } finally { [System.Threading.Monitor]::Exit($shared.Gate) }
                if ($shared.StopRequested) {
                    $diagnosticPhase='GUARDIAN_CANCEL'
                    [void](& $cancelCommand $shared $epoch)
                }
                [System.Threading.Thread]::Sleep($pollMilliseconds)
            }
        } catch {
            $number=0;$state=0;$cause=$_.Exception
            while($cause){if($cause-is[System.Data.SqlClient.SqlException]){$number=[int]$cause.Number;$state=[int]$cause.State;break};$cause=$cause.InnerException}
            $code='UNSPECIFIED';$errorId='UNSPECIFIED'
            if($_.Exception.Message-cin@('WORKER.ACTOR_CONTROL_INVALID','WORKER.ACTOR_STALE_COMMAND','WORKER.ACTOR_COMMAND_INVALID','WORKER.ACTOR_CANCEL_BINDING_INVALID')){$code=$_.Exception.Message}
            if($_.FullyQualifiedErrorId-cin@('CommandNotFoundException','StrictModeInvalidOperation','PropertyNotFoundStrict','ParameterBindingArgumentTransformationException','ArgumentException','InvalidOperationException')){$errorId=$_.FullyQualifiedErrorId}
            $shared.GuardianOuterDiagnostic=[pscustomobject]@{Phase=$diagnosticPhase;Code=$code;Category=$_.Exception.GetType().Name;SqlNumber=$number;SqlState=$state;ErrorId=$errorId}
            $shared.GuardianHealthy=$false
            $shared.SecondaryCode='WORKER.ACTOR_GUARDIAN_FAILED'
        } finally { $shared.GuardianFinished=$true }
    }
    try {
        $Actor.ExecutorShell=[powershell]::Create()
        [void]$Actor.ExecutorShell.AddScript($executorBody.ToString()).AddArgument($Actor.Shared).AddArgument($Actor.ExecutorSource).AddArgument($Actor.ModulePath)
        $Actor.GuardianShell=[powershell]::Create()
        [void]$Actor.GuardianShell.AddScript($guardianBody.ToString()).AddArgument($Actor.Shared).AddArgument($Actor.GuardianSource).AddArgument($Actor.ModulePath).AddArgument($Actor.PollMilliseconds)
        $Actor.GuardianTask=$Actor.GuardianShell.BeginInvoke()
        $Actor.ExecutorTask=$Actor.ExecutorShell.BeginInvoke()
    } catch {
        $Actor.Shared.PrimaryCode='WORKER.ACTOR_START_FAILED'
        if($null -eq $Actor.ExecutorTask){$Actor.Shared.ExecutorFinished=$true}
        if($null -eq $Actor.GuardianTask){$Actor.Shared.GuardianFinished=$true}
        # Bereits gestartete Guardianen enden über ihr eigenes Finished-Signal.
        throw 'WORKER.ACTOR_START_FAILED'
    }
}

function Get-WorkerExecutionActorState {
    param([Parameter(Mandatory)]$Actor)
    $s=$Actor.Shared
    [System.Threading.Monitor]::Enter($s.Gate)
    try {
        $knownCommit=$s.Committed
        $outcome=if ($knownCommit) { 'COMMITTED' }
            elseif ($s.GuardianHealthy) { $s.Outcome } else { 'UNKNOWN' }
        [pscustomobject]@{ ExecutionId=$s.ExecutionId; Phase=$s.Phase
            Outcome=$outcome; ExecutorFinished=$s.ExecutorFinished
            GuardianFinished=$s.GuardianFinished; GuardianHealthy=$s.GuardianHealthy
            Heartbeats=$s.Heartbeats; StopRequested=$s.StopRequested
            CancelAttempted=$s.CancelAttempted; Committed=$s.Committed
            RollbackConfirmed=$s.RollbackConfirmed; ExecutionEnded=$s.ExecutionEnded
            ResourcesDisposed=$s.ResourcesDisposed; PrimaryCode=$s.PrimaryCode
            SecondaryCode=$s.SecondaryCode }
    } finally { [System.Threading.Monitor]::Exit($s.Gate) }
}

function Close-WorkerExecutionActor {
    param([Parameter(Mandatory)]$Actor)
    if ($Actor.Disposed) { return $true }
    foreach ($pair in @(@($Actor.ExecutorShell,$Actor.ExecutorTask),@($Actor.GuardianShell,$Actor.GuardianTask))) {
        if ($null -ne $pair[1] -and -not $pair[1].IsCompleted) { return $false }
        if($null -ne $pair[0] -and $null -eq $pair[1] -and
            $pair[0].InvocationStateInfo.State -in @([System.Management.Automation.PSInvocationState]::Running,[System.Management.Automation.PSInvocationState]::Stopping)){return $false}
    }
    $healthy=$true
    foreach ($kind in @('Executor','Guardian')) {
        $shell=$Actor.($kind+'Shell'); $task=$Actor.($kind+'Task')
        if ($null -eq $shell) { $Actor.($kind+'Disposed')=$true; continue }
        if ($Actor.($kind+'Disposed')) { continue }
        try {
            if ($null -ne $task -and -not $Actor.($kind+'Joined')) {
                # Auch fehlgeschlagenes EndInvoke wird nicht blind wiederholt.
                $Actor.($kind+'Joined')=$true
                [void]$shell.EndInvoke($task)
            }
            if ($shell.HadErrors) { $healthy=$false }
        } catch { $healthy=$false }
        finally {
            try { $shell.Dispose(); $Actor.($kind+'Disposed')=$true }
            catch { $healthy=$false }
        }
    }
    if (-not $healthy) {
        $Actor.Shared.GuardianHealthy=$false
        if ($Actor.Shared.SecondaryCode -eq '') {
            $Actor.Shared.SecondaryCode='WORKER.ACTOR_DISPOSITION_FAILED'
        }
    }
    # Physischer Dispose und fachlicher Ausgang bleiben getrennte Aussagen.
    $Actor.Disposed=$Actor.ExecutorDisposed -and $Actor.GuardianDisposed
    return $Actor.Disposed
}

Export-ModuleMember -Function New-WorkerExecutionActor,Start-WorkerExecutionActor,Get-WorkerExecutionActorState,Close-WorkerExecutionActor,Publish-WorkerExecutionCommand,Get-WorkerExecutionCancellationToken,Clear-WorkerExecutionCommand,Invoke-WorkerExecutionCancellation
