#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot '../ExecutionActors.psm1') -Force

# Tatsächliche Runspaces und Ereignisse, kein SQL und kein nachgebildeter Scheduler.
function Assert-Actor($Condition,[string]$Name) {
    if (-not $Condition) { throw "FAIL:$Name" }
}
function Wait-Actor($Actor,[scriptblock]$Predicate) {
    $clock=[System.Diagnostics.Stopwatch]::StartNew()
    while (-not (& $Predicate (Get-WorkerExecutionActorState $Actor))) {
        if ($clock.ElapsedMilliseconds -ge 5000) { throw 'FAIL:actor bounded rendezvous' }
        [System.Threading.Thread]::Sleep(10)
    }
}
$control={ param($shared,$context)
    [pscustomobject]@{StopRequested=[bool]$context.Stop;HeartbeatConfirmed=$true}
}
$actors=[System.Collections.Generic.List[object]]::new()
$contexts=[System.Collections.Generic.List[object]]::new()
try {
    $context=[hashtable]::Synchronized(@{Stop=$false;Release=[System.Threading.ManualResetEventSlim]::new($false)})
    $contexts.Add($context)
    $executor={ param($shared,$context)
        $shared.Phase='COMMITTING'
        if (-not $context.Release.Wait(5000)) { throw 'Synthetic commit deadline' }
        [pscustomobject]@{Committed=$true;RollbackConfirmed=$false;ExecutionEnded=$true;ResourcesDisposed=$true}
    }
    $actor=New-WorkerExecutionActor ([guid]::NewGuid()) $executor $control $context -PollMilliseconds 20
    $actors.Add($actor); Start-WorkerExecutionActor $actor
    Wait-Actor $actor {param($s) $s.Phase -eq 'COMMITTING' -and $s.Heartbeats -ge 3}
    $before=Get-WorkerExecutionActorState $actor
    Assert-Actor (-not $before.ExecutorFinished -and $before.Outcome -eq 'UNKNOWN') 'blocked commit has no terminal proof'
    $context.Release.Set()
    Wait-Actor $actor {param($s) $s.ExecutorFinished -and $s.GuardianFinished}
    Assert-Actor ((Get-WorkerExecutionActorState $actor).Outcome -eq 'COMMITTED') 'separate guardian progresses while executor blocks'
    Assert-Actor (Close-WorkerExecutionActor $actor) 'ended actor disposed'

    # CancellationTokenSource hat eine reale Cancel-Methode und bleibt ein
    # synthetischer Instanzzeuge; sie belegt keinen SqlClient-/SQL-Abbruch.
    $context=[hashtable]::Synchronized(@{Stop=$false;Published=[System.Threading.ManualResetEventSlim]::new($false)
        Release=[System.Threading.ManualResetEventSlim]::new($false);Command=[System.Threading.CancellationTokenSource]::new()})
    $contexts.Add($context)
    $executor={ param($shared,$context)
        $epoch=Publish-WorkerExecutionCommand $shared $context.Command
        $context.Published.Set()
        try {
            if (-not $context.Release.Wait(5000)) { throw 'Synthetic end deadline' }
        } finally {
            $clock=[System.Diagnostics.Stopwatch]::StartNew()
            while (-not (Clear-WorkerExecutionCommand $shared $epoch)) {
                if ($clock.ElapsedMilliseconds -ge 1000) { throw 'Synthetic cancel drain deadline' }
                [System.Threading.Thread]::Sleep(10)
            }
        }
        [pscustomobject]@{Committed=$false;RollbackConfirmed=$false;ExecutionEnded=$true;ResourcesDisposed=$true}
    }
    $actor=New-WorkerExecutionActor ([guid]::NewGuid()) $executor $control $context -PollMilliseconds 20
    $actors.Add($actor); Start-WorkerExecutionActor $actor
    Assert-Actor ($context.Published.Wait(5000)) 'actual command publication'
    $context.Stop=$true
    Wait-Actor $actor {param($s) $s.CancelAttempted}
    $clock=[System.Diagnostics.Stopwatch]::StartNew()
    while (-not $context.Command.IsCancellationRequested) {
        if ($clock.ElapsedMilliseconds -ge 1000) { throw 'FAIL:cancel instance rendezvous' }
        [System.Threading.Thread]::Sleep(5)
    }
    Assert-Actor (-not (Get-WorkerExecutionActorState $actor).ExecutorFinished -and -not (Close-WorkerExecutionActor $actor)) 'cancel request never disposes live actor'
    $context.Release.Set()
    Wait-Actor $actor {param($s) $s.ExecutorFinished -and $s.GuardianFinished}
    $state=Get-WorkerExecutionActorState $actor
    Assert-Actor ($state.Outcome -eq 'UNKNOWN' -and -not $state.RollbackConfirmed) 'cancel without rollback evidence stays unknown'
    Assert-Actor (Close-WorkerExecutionActor $actor) 'cancel actor runspaces disposed'

    $unused=New-WorkerExecutionActor ([guid]::NewGuid()) {} $control @{}
    $actors.Add($unused)
    $first=[System.Threading.CancellationTokenSource]::new()
    $second=[System.Threading.CancellationTokenSource]::new()
    try {
        $epoch1=Publish-WorkerExecutionCommand $unused.Shared $first
        Assert-Actor (Clear-WorkerExecutionCommand $unused.Shared $epoch1) 'first command detached before replacement'
        $epoch2=Publish-WorkerExecutionCommand $unused.Shared $second
        $armedToken=Get-WorkerExecutionCancellationToken $unused.Shared $epoch2
        $unused.Shared.StopRequested=$true
        Assert-Actor (-not (Invoke-WorkerExecutionCancellation $unused.Shared $epoch1)) 'stale epoch rejected'
        Assert-Actor (-not $first.IsCancellationRequested -and -not $second.IsCancellationRequested) 'stale epoch affects neither instance'
        Assert-Actor (Invoke-WorkerExecutionCancellation $unused.Shared $epoch2) 'current epoch admitted'
        Assert-Actor (-not $first.IsCancellationRequested -and $second.IsCancellationRequested) 'exact current instance only'
        Assert-Actor ($armedToken.IsCancellationRequested) 'stop between arm and task start remains latched'
        $effects=0
        try { $armedToken.ThrowIfCancellationRequested(); $effects++ } catch [System.OperationCanceledException] {}
        Assert-Actor ($effects -eq 0) 'cancelled prestart token admits no synthetic work'
        Assert-Actor (-not (Invoke-WorkerExecutionCancellation $unused.Shared $epoch2)) 'same epoch cancel once'
        Assert-Actor (Clear-WorkerExecutionCommand $unused.Shared $epoch2) 'current command detached after cancel'
    } finally {$first.Dispose();$second.Dispose()}

    $context=[hashtable]::Synchronized(@{Stop=$false;Release=[System.Threading.ManualResetEventSlim]::new($false)})
    $contexts.Add($context)
    $lostControl={param($shared,$context) throw 'Synthetic private error must not escape'}
    $actor=New-WorkerExecutionActor ([guid]::NewGuid()) $executor $lostControl $context -PollMilliseconds 20
    # Hier wird ein eigener Executor ohne Command-/Releaseannahmen verwendet.
    $actor.ExecutorSource={param($shared,$context)
        if (-not $context.Release.Wait(5000)) {throw 'Synthetic deadline'}
        [pscustomobject]@{Committed=$false;RollbackConfirmed=$true;ExecutionEnded=$true;ResourcesDisposed=$true}
    }.ToString()
    $actors.Add($actor); Start-WorkerExecutionActor $actor
    Wait-Actor $actor {param($s) -not $s.GuardianHealthy}
    Assert-Actor ((Get-WorkerExecutionActorState $actor).Outcome -eq 'UNKNOWN') 'guardian loss blocks terminal admission'
    $context.Release.Set()
    Wait-Actor $actor {param($s) $s.ExecutorFinished -and $s.GuardianFinished}
    $state=Get-WorkerExecutionActorState $actor
    Assert-Actor ($state.Outcome -eq 'UNKNOWN' -and $state.RollbackConfirmed -and $state.SecondaryCode -eq 'WORKER.ACTOR_GUARDIAN_FAILED') 'evidence retained without forged free slot'
    Assert-Actor (Close-WorkerExecutionActor $actor) 'lost guardian resources ended and disposed'

    $context=[hashtable]::Synchronized(@{Stop=$false;Release=[System.Threading.ManualResetEventSlim]::new($false)})
    $contexts.Add($context)
    $actor=New-WorkerExecutionActor ([guid]::NewGuid()) {
        param($shared,$context)
        if (-not $context.Release.Wait(5000)) {throw 'Synthetic deadline'}
        [pscustomobject]@{Committed=$true;RollbackConfirmed=$false;ExecutionEnded=$true;ResourcesDisposed=$true}
    } $lostControl $context -PollMilliseconds 20
    $actors.Add($actor); Start-WorkerExecutionActor $actor
    Wait-Actor $actor {param($s) -not $s.GuardianHealthy}
    $context.Release.Set()
    Wait-Actor $actor {param($s) $s.ExecutorFinished -and $s.GuardianFinished}
    Assert-Actor (Close-WorkerExecutionActor $actor) 'committed actor cleanup completed'
    $state=Get-WorkerExecutionActorState $actor
    Assert-Actor ($state.Outcome -eq 'COMMITTED' -and -not $state.GuardianHealthy -and
        $state.SecondaryCode -eq 'WORKER.ACTOR_GUARDIAN_FAILED') 'late control fault never reinterprets known commit'

    $actor=New-WorkerExecutionActor ([guid]::NewGuid()) {
        param($shared,$context)
        $shared.Committed=$true
        throw 'Synthetic postcommit cleanup failure'
    } $control ([hashtable]::Synchronized(@{Stop=$false})) -PollMilliseconds 20
    $actors.Add($actor); Start-WorkerExecutionActor $actor
    Wait-Actor $actor {param($s) $s.ExecutorFinished -and $s.GuardianFinished}
    $state=Get-WorkerExecutionActorState $actor
    Assert-Actor ($state.Outcome -eq 'COMMITTED' -and -not $state.ResourcesDisposed -and
        $state.PrimaryCode -eq '' -and $state.SecondaryCode -eq 'WORKER.ACTOR_POSTCOMMIT_FAILED') 'known commit survives unconfirmed resource cleanup without retry'
    Assert-Actor (Close-WorkerExecutionActor $actor) 'postcommit failed executor runspace disposed separately'

    $command=[pscustomobject]@{Entered=[System.Threading.ManualResetEventSlim]::new($false)
        Release=[System.Threading.ManualResetEventSlim]::new($false);Disposed=$false}
    $command | Add-Member -MemberType ScriptMethod -Name Cancel -Value {
        $this.Entered.Set()
        if (-not $this.Release.Wait(5000)) {throw 'Synthetic reader deadline'}
    }
    $context=[hashtable]::Synchronized(@{Stop=$false;Command=$command
        Published=[System.Threading.ManualResetEventSlim]::new($false)
        Release=[System.Threading.ManualResetEventSlim]::new($false)})
    $contexts.Add($context)
    $actor=New-WorkerExecutionActor ([guid]::NewGuid()) {
        param($shared,$context)
        $epoch=Publish-WorkerExecutionCommand $shared $context.Command
        $context.Published.Set()
        if (-not $context.Release.Wait(5000)) {throw 'Synthetic executor deadline'}
        if (-not (Clear-WorkerExecutionCommand $shared $epoch)) {throw 'Synthetic premature detach'}
        $context.Command.Disposed=$true
        [pscustomobject]@{Committed=$false;RollbackConfirmed=$true;ExecutionEnded=$true;ResourcesDisposed=$true}
    } $control $context -PollMilliseconds 20
    $actors.Add($actor); Start-WorkerExecutionActor $actor
    Assert-Actor ($context.Published.Wait(5000)) 'reader lease command published'
    $context.Stop=$true
    try {
        Assert-Actor ($command.Entered.Wait(5000)) 'actual Cancel call holds reader lease'
        Assert-Actor (-not (Clear-WorkerExecutionCommand $actor.Shared $actor.Shared.Epoch)) 'reader lease blocks detach'
        Assert-Actor (-not $command.Disposed -and -not (Close-WorkerExecutionActor $actor)) 'reader lease blocks physical actor cleanup'
    } finally {$command.Release.Set()}
    $clock=[System.Diagnostics.Stopwatch]::StartNew()
    while ($actor.Shared.CancelReaders -ne 0) {
        if ($clock.ElapsedMilliseconds -ge 1000) {throw 'FAIL:reader release deadline'}
        [System.Threading.Thread]::Sleep(5)
    }
    $context.Release.Set()
    Wait-Actor $actor {param($s) $s.ExecutorFinished -and $s.GuardianFinished}
    Assert-Actor ($command.Disposed -and (Close-WorkerExecutionActor $actor)) 'cleanup follows actual Cancel return'
    $command.Entered.Dispose();$command.Release.Dispose()

    $context=[hashtable]::Synchronized(@{Stop=$false})
    $contexts.Add($context)
    $actor=New-WorkerExecutionActor ([guid]::NewGuid()) {param($shared,$context) throw 'Synthetic executor loss'} $control $context -PollMilliseconds 20
    $actors.Add($actor); Start-WorkerExecutionActor $actor
    Wait-Actor $actor {param($s) $s.ExecutorFinished -and $s.GuardianFinished}
    $state=Get-WorkerExecutionActorState $actor
    Assert-Actor ($state.Outcome -eq 'UNKNOWN' -and -not $state.RollbackConfirmed -and
        -not $state.ResourcesDisposed -and $state.PrimaryCode -eq 'WORKER.ACTOR_EXECUTOR_FAILED') 'executor loss has no invented rollback or SQL resource disposal'
    Assert-Actor (Close-WorkerExecutionActor $actor) 'failed executor runspaces physically disposed'
    'PASS:execution actor isolation, exact cancellation epoch and unknown outcomes'
} finally {
    foreach ($context in $contexts) {if ($context.ContainsKey('Release')) {$context.Release.Set()}}
    foreach ($actor in $actors) {
        $clock=[System.Diagnostics.Stopwatch]::StartNew()
        while (-not (Close-WorkerExecutionActor $actor) -and $clock.ElapsedMilliseconds -lt 6000) {
            [System.Threading.Thread]::Sleep(10)
        }
        if (-not $actor.Disposed) {throw 'FAIL:actor cleanup remains unknown'}
    }
    foreach ($context in $contexts) {
        foreach($name in @('Release','Published','Command')) {
            if($context.ContainsKey($name) -and $context[$name] -is [System.IDisposable]) {$context[$name].Dispose()}
        }
    }
}
