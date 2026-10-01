#requires -Version 7.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../ExternalQueueWorker.psm1') -Force
$module = Get-Module ExternalQueueWorker
& $module {
    function Assert-Worker($Condition, [string]$Name) { if (-not $Condition) { throw "FAIL:$Name" } }
    function New-FakeWorker([string]$Scenario, [int]$Items = 1, [int]$Slots = 1) {
        $state = @{ Now=0.0; Items=$Items; Claims=0; Peak=0; Active=0; Renew=0; Cancel=0; Complete=0; Rollback=0; Fail=0; Retry=0; Dispose=0; Scenario=$Scenario;Log=[System.Collections.Generic.List[string]]::new() }
        $settings = [pscustomobject]@{Slots=$Slots;MaxRunSeconds=300;MaxClaims=10;PollSeconds=1;GraceSeconds=2}
        $adapter = @{
            Now={return $state.Now}.GetNewClosure()
            Sleep={param($seconds) $state.Now += $seconds; if($state.Now -gt 200){throw 'Test finite bound'}}.GetNewClosure()
            ShouldStop={return $state.Scenario -eq 'Drain' -and $state.Now -ge 1}.GetNewClosure()
            Preflight={}
            Claim={
                if($state.Claims -ge $state.Items){return $null}
                $state.Claims++;$state.Active++;$state.Peak=[Math]::Max($state.Peak,$state.Active)
                $state.Log.Add('Claim'+$state.Claims)
                return [pscustomobject]@{Claim=[pscustomobject]@{WorkItemId=$state.Claims;ClaimGeneration=1};ExecutionId=[guid]::NewGuid();Budget=$(if($state.Scenario -eq 'Watchdog'){2}else{1000});Started=0.0;LastRenew=0.0;Uncertain=$false;CancelSent=$false;ImmediateOutcome=$null}
            }.GetNewClosure()
            Start={param($slot) $state.Log.Add('Start'+$slot.Claim.WorkItemId);if($state.Scenario -eq 'DelayedStart'){$state.Now+=61}}.GetNewClosure()
            Poll={
                param($slot)
                if($state.Scenario -in @('Drain','Watchdog') -and $state.Now -lt 125){return [pscustomobject]@{State='RUNNING'}}
                if($state.Scenario -in @('Retry','DeadLetter','RollbackUnknown','Cancelled','NoAck')){return [pscustomobject]@{State='FAILED';Code='WORKER.SQL_50002';SqlNumber=$(if($state.Scenario -in @('Cancelled','NoAck')){50001}else{50002})}}
                return [pscustomobject]@{State='SUCCEEDED'}
            }.GetNewClosure()
            Renew={param($slot) $state.Renew++;$state.Log.Add('Renew'+$slot.Claim.WorkItemId);if($state.Scenario -eq 'Ownership'){throw 'ownership'}}.GetNewClosure()
            Cancel={param($slot) $state.Cancel++}.GetNewClosure()
            Checkpoint={param($slot) return 'ACTIVE'}
            Rollback={param($slot) $state.Rollback++;if($state.Scenario -eq 'RollbackUnknown'){throw 'rollback unknown'}}.GetNewClosure()
            Complete={param($slot) $state.Complete++;if($state.Scenario -eq 'CommitUnknown'){throw 'commit acknowledge lost'}}.GetNewClosure()
            Fail={param($slot,$code) $state.Fail++;$state.LastCode=$code}.GetNewClosure()
            Retry={param($slot,$code) $state.Retry++;return $(if($state.Scenario -eq 'DeadLetter'){'DEAD_LETTER'}else{'RETRY_WAIT'})}.GetNewClosure()
            IsCancelled={param($slot) return $state.Scenario -eq 'Cancelled'}.GetNewClosure()
            CanRetry={param($slot,$number) return $number -eq 50002}
            Dispose={param($slot) $state.Dispose++;$state.Active--;if($state.Scenario -eq 'Cleanup'){throw 'cleanup failed'}}.GetNewClosure()
        }
        return @{State=$state;Settings=$settings;Adapter=$adapter}
    }
    foreach($scenario in @('Success','CommitUnknown','RollbackUnknown','Retry','DeadLetter','Cancelled','NoAck','Ownership','Drain','Watchdog','Cleanup')) {
        $fake=New-FakeWorker $scenario
        $events=@()
        $result=Invoke-WorkerSupervisor $fake.Settings $fake.Adapter -InformationVariable events
        switch($scenario) {
            Success { Assert-Worker ($result.Completed -eq 1 -and $fake.State.Complete -eq 1) 'atomic boundary' }
            CommitUnknown { Assert-Worker ($result.Unresolved -eq 1 -and $fake.State.Complete -eq 1 -and $fake.State.Retry -eq 0 -and $fake.State.Fail -eq 0) 'no commit replay' }
            RollbackUnknown { Assert-Worker ($result.Unresolved -eq 1 -and $fake.State.Retry -eq 0 -and $fake.State.Fail -eq 0) 'unknown rollback' }
            Retry { Assert-Worker ($result.Retried -eq 1 -and $fake.State.Rollback -eq 1) 'known rollback retry' }
            DeadLetter { Assert-Worker ($result.DeadLetter -eq 1 -and $result.Retried -eq 0) 'dead letter summary' }
            Cancelled { Assert-Worker ($result.Failed -eq 1 -and $fake.State.LastCode -ceq 'WORKER.CANCELLED' -and $fake.State.Rollback -eq 1) 'cancellation ack' }
            NoAck { Assert-Worker ($result.Failed -eq 1 -and $fake.State.LastCode -cne 'WORKER.CANCELLED') 'request not acknowledgement' }
            Ownership { Assert-Worker ($result.Unresolved -eq 1 -and $fake.State.Complete -eq 0 -and $fake.State.Fail -eq 0) 'ownership lost' }
            Drain { Assert-Worker ($fake.State.Now -ge 125 -and $fake.State.Renew -ge 3 -and $fake.State.Cancel -eq 0 -and @($events | Where-Object {$_.MessageData.Event -eq 'DRAIN_ACTIVE'}).Count -eq 1) 'drain beyond grace keeps heartbeat' }
            Watchdog { Assert-Worker ($fake.State.Cancel -eq 1 -and $fake.State.Now -ge 125 -and $result.Completed -eq 1) 'watchdog once no fabricated cancel' }
            Cleanup { Assert-Worker ($result.Completed -eq 1 -and $fake.State.Retry -eq 0) 'cleanup after commit' }
        }
    }
    $fake=New-FakeWorker 'Success' 20 8
    $fake.Settings.MaxClaims=5
    $result=Invoke-WorkerSupervisor $fake.Settings $fake.Adapter
    Assert-Worker ($result.Claims -eq 5 -and $fake.State.Peak -eq 5) 'global claim budget'
    $fake=New-FakeWorker 'Success' 20 8
    $result=Invoke-WorkerSupervisor $fake.Settings $fake.Adapter
    Assert-Worker ($fake.State.Peak -eq 8 -and $result.Claims -eq 10) 'maximum concurrency'
    $fake=New-FakeWorker 'DelayedStart' 3 3
    $fake.Settings.MaxClaims=3
    $result=Invoke-WorkerSupervisor $fake.Settings $fake.Adapter
    Assert-Worker ($fake.State.Log.IndexOf('Renew1') -gt $fake.State.Log.IndexOf('Start1') -and $fake.State.Log.IndexOf('Renew1') -lt $fake.State.Log.IndexOf('Claim2') -and $fake.State.Log.IndexOf('Renew2') -lt $fake.State.Log.IndexOf('Claim3')) 'startup refresh before further claims'

    # DataTableReader bietet echte mehrfache Reader-Resultsets, keine nachgebildete
    # Parserlogik. Die Fixtures bleiben synthetisch und benötigen keine SQL-Verbindung.
    function New-ClaimTable([bool]$WithRow=$true) {
        $table=[System.Data.DataTable]::new()
        foreach($name in @('WorkItemId','WorkTypeName','PayloadJson','ClaimToken','ClaimedAtUtc','ClaimGeneration','LeaseUntilUtc','LastHeartbeatAtUtc')){[void]$table.Columns.Add($name,[object])}
        if($WithRow){[void]$table.Rows.Add(@(1L,'demo.noop',[DBNull]::Value,[guid]::NewGuid(),[datetime]::UtcNow,1L,[datetime]::UtcNow.AddSeconds(300),[datetime]::UtcNow))}
        return ,$table
    }
    $scheduler=[System.Data.DataTable]::new();[void]$scheduler.Columns.Add('SchedulerId',[int]);[void]$scheduler.Rows.Add(1)
    $table=New-ClaimTable
    $reader=[System.Data.DataTableReader]::new([System.Data.DataTable[]]@($scheduler,$table))
    try{$claim=Read-WorkerClaim $reader;Assert-Worker ($claim.WorkTypeName -ceq 'demo.noop') 'scheduler resultset'}finally{$reader.Dispose()}
    $reader=[System.Data.DataTableReader]::new((New-ClaimTable $false))
    try{Assert-Worker ($null -eq (Read-WorkerClaim $reader)) 'empty claim'}finally{$reader.Dispose()}
    $reader=[System.Data.DataTableReader]::new([System.Data.DataTable[]]@($table,$table))
    $rejected=$false
    try{Read-WorkerClaim $reader}catch{$rejected=$true}finally{$reader.Dispose()}
    Assert-Worker $rejected 'duplicate claim resultset'
    $reader=[System.Data.DataTableReader]::new($scheduler);$rejected=$false
    try{Read-WorkerClaim $reader}catch{$rejected=$true}finally{$reader.Dispose()}
    Assert-Worker $rejected 'missing claim shape'

    $settings=[pscustomobject]@{ConnectTimeoutSeconds=5;ControlTimeoutSeconds=5;StopFile='';WorkerEligibleWorkTypes=[System.Collections.Generic.HashSet[string]]::new([string[]]@('demo.retry'),[System.StringComparer]::Ordinal);RetryEligibleWorkTypes=[System.Collections.Generic.HashSet[string]]::new([string[]]@('demo.retry'),[System.StringComparer]::Ordinal);TransientSqlNumbers=[System.Collections.Generic.HashSet[int]]::new([int[]]@(50002,229,50001,51923,1205,15664))}
    $adapter=New-WorkerSqlAdapter $settings 'Server=localhost;Database=Contoso;Integrated Security=true;Encrypt=true'
    $slot=[pscustomobject]@{Claim=[pscustomobject]@{WorkTypeName='demo.retry'}}
    Assert-Worker (& $adapter.CanRetry $slot 50002) 'explicit custom transient'
    Assert-Worker (& $adapter.CanRetry $slot 1205) 'explicit deadlock'
    foreach($number in @(229,50001,51923,15664,0,-2)){Assert-Worker (-not (& $adapter.CanRetry $slot $number)) "terminal number $number"}
    $slot.Claim.WorkTypeName='Demo.Retry';Assert-Worker (-not (& $adapter.CanRetry $slot 50002)) 'ordinal eligibility'
    # Die tatsächlichen Adapterclosures müssen die privaten Helpers finden.
    # Eine geschlossene synthetische Verbindung erreicht die Providergrenze ohne Netzwerk.
    $slot=[pscustomobject]@{Control=[System.Data.SqlClient.SqlConnection]::new();Claim=[pscustomobject]@{WorkItemId=1L;ClaimToken=[guid]::NewGuid()}}
    $slot | Add-Member -NotePropertyName ExecutionId -NotePropertyValue ([guid]::NewGuid())
    foreach($operation in @('Renew','Fail','Retry','Cancel','IsCancelled')) {
        $reachedProvider=$false
        try{& $adapter[$operation] $slot 'WORKER.TEST'}catch{$reachedProvider=$_.Exception.Message -match 'Execute(NonQuery|Reader|Scalar)'}
        Assert-Worker $reachedProvider "private callback binding $operation"
    }
    $rejected=$false
    try{New-WorkerSqlAdapter $settings 'Server=localhost;Database=Contoso;Integrated Security=true;Encrypt=false'}catch{$rejected=$true}
    Assert-Worker $rejected 'encryption before network'
}
foreach($arguments in @(@{Slots=0},@{Slots=9},@{MaxClaims=0},@{PollSeconds=0},@{TransientSqlNumbers=@(50002,50002)},@{RetryEligibleWorkTypes=@('other')})){
    $rejected=$false
    try{Start-ExternalQueueWorker -ConnectionStringEnvironmentVariable TOOLBELT_SYNTHETIC_MISSING -WorkerEligibleWorkTypes demo.noop @arguments}catch{$rejected=$true}
    if(-not $rejected){throw 'FAIL:parameter boundary'}
}
'PASS:external-worker deterministic contract and fault oracles'
