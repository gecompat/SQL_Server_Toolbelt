#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot '../ManagedQueueWorker.psm1') -Force
$module=Get-Module ManagedQueueWorker
& $module {
    function Assert-Managed($Condition,[string]$Name){if(-not $Condition){throw "FAIL:$Name"}}
    $summary=[ordered]@{Completed=0L;Unresolved=0L;SlotEndUnconfirmed=0L;CleanupFailed=0L}
    $lane=[hashtable]::Synchronized(@{Healthy=$true})
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $true 0) -ceq 'COMPLETED') 'healthy idle supervisor ends normally'
    $lane.Healthy=$false
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $true 0) -ceq 'OUTCOME_UNKNOWN') 'registration loss without claims never reports completed'
    $summary.Completed=1L
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $true 0) -ceq 'OUTCOME_UNKNOWN' -and $summary.Completed -eq 1L -and $summary.Unresolved -eq 0L) 'late registration loss preserves confirmed commit and execution counts'
    $lane.Healthy=$true
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $false 0) -ceq 'OUTCOME_UNKNOWN') 'unconfirmed registration lane end stays unknown'
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $true 1) -ceq 'OUTCOME_UNKNOWN') 'remaining actor prevents normal supervisor end'
    $summary.CleanupFailed=1L
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $true 0) -ceq 'CLEANUP_FAILED' -and $summary.Completed -eq 1L) 'known commit with cleanup failure remains counted'
    $summary.SlotEndUnconfirmed=1L
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $true 0) -ceq 'END_RECORD_UNKNOWN') 'missing slot end takes precedence over cleanup'
    $summary.Unresolved=1L
    Assert-Managed ((Get-ManagedRunStatus $summary $lane $true 0) -ceq 'OUTCOME_UNKNOWN') 'unknown execution takes precedence over secondary failures'
    $lost=[hashtable]::Synchronized(@{GuardianHealthy=$false;Committed=$false;RollbackConfirmed=$true})
    $terminalCalls=0;$rejected=$false
    try{Assert-ManagedGuardian $lost;$terminalCalls++}catch{$rejected=$true}
    Assert-Managed ($rejected -and $terminalCalls -eq 0 -and $lost.RollbackConfirmed) 'guardian loss preserves rollback fact without terminal retry admission'
    $lost.Committed=$true
    Assert-Managed $lost.Committed 'guardian guard never rewrites actual commit evidence'
    $names=@('WorkItemId','WorkTypeName','PayloadJson','ClaimToken','ClaimedAtUtc','ClaimGeneration','LeaseUntilUtc','LastHeartbeatAtUtc','SlotReservationId','ExecutionId')
    $types=@([long],[string],[string],[guid],[datetime],[long],[datetime],[datetime],[guid],[guid])
    $table=[System.Data.DataTable]::new()
    for($i=0;$i -lt $names.Count;$i++){[void]$table.Columns.Add($names[$i],$types[$i])}
    [void]$table.Rows.Add(@(1L,'demo.noop',[DBNull]::Value,[guid]::NewGuid(),[datetime]::UtcNow,1L,[datetime]::UtcNow.AddSeconds(300),[datetime]::UtcNow,[guid]::NewGuid(),[guid]::NewGuid()))
    $reader=[System.Data.DataTableReader]::new($table)
    try {
        $claim=Read-ManagedRow $reader $names $types @(2)
        Assert-Managed ($claim.PayloadJson -eq $null -and $claim.ExecutionId -is [guid]) 'exact managed reservation shape'
    } finally {$reader.Dispose()}
    $reader=[System.Data.DataTableReader]::new([System.Data.DataTable[]]@($table,$table))
    $rejected=$false
    try{Read-ManagedRow $reader $names $types @(2)}catch{$rejected=$true}finally{$reader.Dispose()}
    Assert-Managed $rejected 'extra resultset rejected rather than mistaken for acknowledgement'
    $table.Rows.Clear()
    $reader=[System.Data.DataTableReader]::new($table)
    try{Assert-Managed ($null -eq (Read-ManagedRow $reader $names $types @(2) -AllowEmpty)) 'empty admitted-work result'}finally{$reader.Dispose()}
    $wrong=$table.Clone();$wrong.Columns.Remove('ExecutionId');[void]$wrong.Columns.Add('ExecutionId',[string])
    $reader=[System.Data.DataTableReader]::new($wrong);$rejected=$false
    try{Read-ManagedRow $reader $names $types @(2) -AllowEmpty}catch{$rejected=$true}finally{$reader.Dispose()}
    Assert-Managed $rejected 'wrong empty-reader metadata rejected'
    $context=[pscustomobject]@{Settings=[pscustomobject]@{ControlTimeoutSeconds=5};Claim=$claim}
    $connection=[System.Data.SqlClient.SqlConnection]::new()
    try {
        $command=New-ManagedCommand $connection 'SELECT 1;' $context
        try {
            Add-ManagedAttempt $command $context
            Assert-Managed ($command.Parameters['@SlotReservationId'].SqlDbType -eq [System.Data.SqlDbType]::UniqueIdentifier -and
                $command.Parameters['@ExecutionId'].Value -eq $claim.ExecutionId -and $command.CommandTimeout -eq 5) 'typed exact attempt parameters on actual SqlCommand without network'
        } finally {$command.Dispose()}
    } finally {$connection.Dispose()}
}
Import-Module (Join-Path $PSScriptRoot '../ExternalQueueWorker.psm1') -Force
$parameters=(Get-Command Start-ExternalQueueWorker).Parameters
$range=@($parameters.Capacity.Attributes | Where-Object {$_ -is [System.Management.Automation.ValidateRangeAttribute]})
if($range.Count -ne 1 -or $range[0].MaxRange -ne [int]::MaxValue){throw 'FAIL:managed capacity retains artificial legacy cap'}
if(-not $parameters.ContainsKey('Managed') -or -not $parameters.ContainsKey('RunMode')){throw 'FAIL:explicit managed entrypoint'}
'PASS:managed summary faults, typed reader and attempt bindings; no SQL execution proof'
