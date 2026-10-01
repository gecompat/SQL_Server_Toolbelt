[CmdletBinding()]
param([Parameter(Mandatory)][string]$ConnectionStringEnvironmentVariable,
 [ValidateSet('2019','2022','2025')][string]$ExpectedSqlVersion,
 [switch]$SkipLongHeartbeat,[switch]$IdentityGuardsOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$database='Toolbelt_ExternalQueue_'+[guid]::NewGuid().ToString('N')
$created=$false;$connection=$null;$workerProcesses=[Collections.Generic.List[object]]::new()
$privateEnvironment='TBX_EXTERNAL_QUEUE_FIXTURE_CONNECTION'
$previousEnvironment=[Environment]::GetEnvironmentVariable($privateEnvironment,'Process')
$temporaryRoot=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltQueueFixture_'+[guid]::NewGuid().ToString('N'))
$phase='preflight';$cleanupDeferred=$false
function Assert-Fixture([bool]$Condition,[string]$Code){if(-not$Condition){throw "Synthetic worker oracle failed: $Code"}}
function Invoke-FixtureSql([string]$Sql,[hashtable]$Parameters=@{},[switch]$Scalar){
 $command=$connection.CreateCommand();$command.CommandTimeout=10;$command.CommandText=$Sql
 try{
  foreach($key in $Parameters.Keys){[void]$command.Parameters.AddWithValue($key,$Parameters[$key])}
  if($Scalar){return $command.ExecuteScalar()}
  [void]$command.ExecuteNonQuery()
 }finally{$command.Dispose()}
}
function Expand-FixtureSql([string]$Path){
 $builder=[Text.StringBuilder]::new()
 foreach($line in Get-Content -LiteralPath $Path){
  if($line -match '^\s*:r\s+(.+?)\s*$'){
   [void]$builder.AppendLine((Expand-FixtureSql (Join-Path (Split-Path $Path -Parent) $Matches[1].Trim('"'))))
  }elseif($line -notmatch '^\s*:(On Error|setvar)'){
   [void]$builder.AppendLine($line.Replace('$(DeploymentMode)','local'))
  }
 }
 return $builder.ToString()
}
function Invoke-FixtureFile([string]$Path){
 foreach($batch in [regex]::Split((Expand-FixtureSql $Path),'(?im)^\s*GO\s*$')){
  if(-not[string]::IsNullOrWhiteSpace($batch)){Invoke-FixtureSql $batch}
 }
}
function Add-FixtureWork([string]$Type,[string]$Payload,[int]$Attempts=2){
 $arguments=@{'@Type'=$Type;'@Attempts'=$Attempts}
 $payloadSql='NULL'
 if($Payload){$arguments['@Payload']=$Payload;$payloadSql='@Payload'}
 Invoke-FixtureSql "EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName=@Type,@PayloadJson=$payloadSql,@MaxAttempts=@Attempts,@RetryBaseDelaySeconds=1,@RetryMaxDelaySeconds=1;" $arguments
}
function Get-FixtureStatus([string]$Type){
 return [string](Invoke-FixtureSql 'SELECT TOP(1) Status FROM toolbelt_core.VW_WorkQueue WHERE WorkTypeName=@Type ORDER BY WorkItemId DESC;' @{'@Type'=$Type} -Scalar)
}
function Start-FixtureWorker([hashtable]$Options=@{}){
 $arguments=@{ConnectionStringEnvironmentVariable=$privateEnvironment;
  WorkerEligibleWorkTypes=@('test.worker.none','test.worker.json','test.worker.terminal','test.worker.retry','test.worker.dead','test.worker.watchdog','test.worker.cancel','test.worker.wait','test.worker.resultset','test.worker.context-drift','test.worker.readonly-mutation');
  MaxRunSeconds=120;MaxClaims=100;PollSeconds=0.1}
 foreach($key in $Options.Keys){$arguments[$key]=$Options[$key]}
 $info=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh -ErrorAction Stop).Source)
 $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
 foreach($argument in @('-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Invoke-WorkerChild.ps1'))){[void]$info.ArgumentList.Add($argument)}
 $info.Environment['TBX_EXTERNAL_QUEUE_TEST_OPTIONS']=ConvertTo-Json $arguments -Compress
 $process=[Diagnostics.Process]::new();$process.StartInfo=$info
 [void]$process.Start()
 $handle=[pscustomobject]@{Process=$process;Output=$process.StandardOutput.ReadToEndAsync();Error=$process.StandardError.ReadToEndAsync()}
 $workerProcesses.Add($handle)
 return $handle
}
function Wait-FixtureWorker($Handle,[scriptblock]$Observer={},[int]$BudgetSeconds=100){
 $timer=[Diagnostics.Stopwatch]::StartNew()
 while(-not$Handle.Process.HasExited){
  & $Observer
  if($timer.Elapsed.TotalSeconds -gt $BudgetSeconds){throw 'Synthetic worker exceeded observation budget; no forced termination.'}
  Start-Sleep -Milliseconds 100
 }
 $text=$Handle.Output.GetAwaiter().GetResult();[void]$Handle.Error.GetAwaiter().GetResult()
 Assert-Fixture ($Handle.Process.ExitCode-eq0) 'CHILD_EXIT'
 $result=$text|ConvertFrom-Json
 Assert-Fixture (@($result.Summary).Count-eq1) 'SUMMARY_SHAPE'
 return $result
}
function Run-FixtureWorker([hashtable]$Options=@{}){return Wait-FixtureWorker (Start-FixtureWorker $Options)}
try{
 $privateConnection=[Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable,'Process')
 if([string]::IsNullOrWhiteSpace($privateConnection)){throw 'Private fixture connection variable absent.'}
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($privateConnection)
 $builder.Pooling=$false;$builder.Enlist=$false;$builder.ConnectRetryCount=0;$builder['Connect Timeout']=5
 $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$connection.Open()
 if($ExpectedSqlVersion){
  $major=[int](Invoke-FixtureSql "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion'));" -Scalar)
  Assert-Fixture ($major-eq @{'2019'=15;'2022'=16;'2025'=17}[$ExpectedSqlVersion]) 'SQL_VERSION'
 }
 Assert-Fixture ((Invoke-FixtureSql 'SELECT COUNT(*) FROM sys.databases WHERE name=@Database;' @{'@Database'=$database} -Scalar)-eq0) 'DATABASE_UNIQUENESS'
 $phase='create';Invoke-FixtureSql "CREATE DATABASE [$database] COLLATE Latin1_General_100_CS_AS;";$created=$true
 $connection.ChangeDatabase($database);$builder['Initial Catalog']=$database
 [Environment]::SetEnvironmentVariable($privateEnvironment,$builder.ConnectionString,'Process')
 [void][IO.Directory]::CreateDirectory($temporaryRoot)
 $phase='deploy'
 foreach($module in @('result-table','execution-context','execution-cancel','work-type','work-queue')){
  $phase='deploy-'+$module
  Invoke-FixtureFile (Join-Path $root "Modules/toolbelt.core.$module/Deployment/Deploy.sql")
 }
 $phase='synthetic-fixtures'
 Invoke-FixtureFile (Join-Path $PSScriptRoot 'Fixtures.sql')
 if(-not$IdentityGuardsOnly){
 $phase='none-json-atomic'
 Add-FixtureWork 'test.worker.none' ''
 Add-FixtureWork 'test.worker.json' '{"marker":"Grüße 😀"}'
 $result=Run-FixtureWorker
 Assert-Fixture ($result.Summary.Completed-eq2 -and $result.Summary.Claims-eq2) 'NONE_JSON_COUNTS'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM dbo.TbxWorkerLedger WHERE Scenario='json' AND Marker=N'Grüße 😀' AND Generation=1;" -Scalar)-eq1) 'JSON_UNICODE'
 Assert-Fixture ((Get-FixtureStatus 'test.worker.none')-eq'COMPLETED') 'NONZERO_RETURN_INFORMATIONAL'
 $phase='terminal-unsupported-resultset'
 Add-FixtureWork 'test.worker.terminal' '';Add-FixtureWork 'test.worker.unsupported' '';Add-FixtureWork 'test.worker.resultset' ''
 $result=Run-FixtureWorker
 Assert-Fixture ($result.Summary.Failed-eq3) 'TERMINAL_COUNTS'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM dbo.TbxWorkerLedger WHERE Scenario='rollback';" -Scalar)-eq0) 'HANDLER_ROLLBACK'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueue WHERE WorkTypeName='test.worker.unsupported' AND Status='FAILED' AND FailureCode='WORKER.UNSUPPORTED_HANDLER';" -Scalar)-eq1) 'UNSUPPORTED_CODE'
 $phase='retry-success-deadletter'
 foreach($type in @('test.worker.retry','test.worker.dead')){
  Add-FixtureWork $type ''
  $retryOptions=@{RetryEligibleWorkTypes=@($type);TransientSqlNumbers=@(50002);MaxClaims=1}
  $first=Run-FixtureWorker $retryOptions
  Assert-Fixture ($first.Summary.Retried-eq1 -and (Get-FixtureStatus $type)-eq'RETRY_WAIT') 'EXPLICIT_RETRY'
  Start-Sleep -Milliseconds 1200
  $second=Run-FixtureWorker $retryOptions
  if($type-eq'test.worker.retry'){
   Assert-Fixture ($second.Summary.Completed-eq1 -and (Get-FixtureStatus $type)-eq'COMPLETED') 'RETRY_SUCCESS'
   Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM dbo.TbxWorkerLedger WHERE Scenario='retry' AND Generation=2;" -Scalar)-eq1) 'RETRY_ROLLBACK_GENERATION'
  }else{Assert-Fixture ((Get-FixtureStatus $type)-eq'DEAD_LETTER' -and $second.Summary.DeadLetter-eq1 -and $second.Summary.Retried-eq0) 'RETRY_DEADLETTER'}
 }
 $phase='retry-optout'
 Add-FixtureWork 'test.worker.dead' ''
 $result=Run-FixtureWorker
 Assert-Fixture ($result.Summary.Failed-eq1 -and (Get-FixtureStatus 'test.worker.dead')-eq'FAILED') 'RETRY_DEFAULT_OFF'
 $phase='watchdog'
 Add-FixtureWork 'test.worker.watchdog' ''
 $result=Run-FixtureWorker
 Assert-Fixture ($result.Summary.Failed-eq1) 'WATCHDOG_FAILED'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueue WHERE WorkTypeName='test.worker.watchdog' AND Status='FAILED' AND FailureCode='WORKER.CANCELLED';" -Scalar)-eq1) 'WATCHDOG_CANCEL_CONFIRMED'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM dbo.TbxWorkerLedger WHERE Scenario='cancel';" -Scalar)-eq0) 'CANCEL_ROLLBACK'
 $phase='manual-cancellation'
 Add-FixtureWork 'test.worker.cancel' ''
 $handle=Start-FixtureWorker
 $observed=@{Requested=$false}
 $result=Wait-FixtureWorker $handle {
  if(-not$observed.Requested){
   $execution=Invoke-FixtureSql "SELECT TOP(1) ExecutionId FROM dbo.TbxWorkerLedger WITH(READUNCOMMITTED) WHERE Scenario='cancel' AND Active=1;" -Scalar
   if($execution-is[guid]){Invoke-FixtureSql 'EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id;' @{'@Id'=$execution};$observed.Requested=$true}
  }
 }
 Assert-Fixture ($observed.Requested -and $result.Summary.Failed-eq1) 'MANUAL_CANCELLATION'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueue WHERE WorkTypeName='test.worker.cancel' AND FailureCode='WORKER.CANCELLED';" -Scalar)-eq1) 'MANUAL_CANCEL_CODE'
 $phase='eight-slots'
 for($index=0;$index-lt8;$index++){Add-FixtureWork 'test.worker.wait' '{"delay":"00:00:04","marker":"slots"}'}
 $peak=@{Value=0};$handle=Start-FixtureWorker @{Slots=8;MaxClaims=8}
 $result=Wait-FixtureWorker $handle {
  $active=[int](Invoke-FixtureSql 'SELECT COUNT(*) FROM dbo.TbxWorkerLedger WITH(READUNCOMMITTED) WHERE Active=1;' -Scalar)
  $peak.Value=[math]::Max($peak.Value,$active)
 }
 Assert-Fixture ($result.Summary.Completed-eq8 -and $result.Summary.Claims-eq8 -and $peak.Value-ge2 -and $peak.Value-le8) 'SUPERVISOR_SLOT_BOUND'
 $phase='stop-drain-grace'
 Add-FixtureWork 'test.worker.wait' '{"delay":"00:00:04","marker":"drain"}'
 Add-FixtureWork 'test.worker.none' ''
 $stop=Join-Path $temporaryRoot 'stop';$stopped=@{Value=$false;ObservedActive=$false}
 $handle=Start-FixtureWorker @{StopFile=$stop;GraceSeconds=1;Slots=1}
 $result=Wait-FixtureWorker $handle {
  if(-not$stopped.Value -and (Get-FixtureStatus 'test.worker.wait')-eq'CLAIMED'){
   [IO.File]::WriteAllText($stop,'synthetic stop');$stopped.Value=$true
  }
  if($stopped.Value -and (Get-FixtureStatus 'test.worker.wait')-eq'CLAIMED'){$stopped.ObservedActive=$true}
 }
 Assert-Fixture ($stopped.Value -and $stopped.ObservedActive -and $result.Summary.Completed-eq1 -and $result.Summary.Claims-eq1) 'STOP_DRAIN'
 Assert-Fixture (@($result.Events | Where-Object {$_.Event-eq'DRAIN_ACTIVE'}).Count-ge1) 'GRACE_ACTIVE_REPORT'
 Assert-Fixture ((Get-FixtureStatus 'test.worker.none')-eq'QUEUED') 'NO_CLAIMS_AFTER_STOP'
 [void](Run-FixtureWorker @{MaxClaims=1})
 if(-not$SkipLongHeartbeat){
  $phase='long-independent-heartbeat'
  Add-FixtureWork 'test.worker.wait' '{"delay":"00:01:10","marker":"heartbeat"}'
  $heartbeat=@{Advanced=$false;Observed=$false}
  $handle=Start-FixtureWorker @{MaxClaims=1;GraceSeconds=1;MaxRunSeconds=10}
  $result=Wait-FixtureWorker $handle {
   $advanced=Invoke-FixtureSql "SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueue WHERE WorkTypeName='test.worker.wait' AND Status='CLAIMED' AND LastHeartbeatAtUtc>ClaimedAtUtc AND IsLeaseExpired=0 AND ClaimGeneration=1;" -Scalar
   if($advanced-gt0){$heartbeat.Advanced=$true}
   $active=Invoke-FixtureSql "SELECT COUNT(*) FROM dbo.TbxWorkerLedger WITH(READUNCOMMITTED) WHERE Marker=N'heartbeat' AND Active=1;" -Scalar
   if($active-gt0){$heartbeat.Observed=$true}
  }
  Assert-Fixture ($heartbeat.Observed -and $heartbeat.Advanced -and $result.Summary.Completed-eq1) 'INDEPENDENT_60S_HEARTBEAT'
 }
 }
 $phase='private-readonly-mutation'
 Add-FixtureWork 'test.worker.readonly-mutation' ''
 $result=Run-FixtureWorker @{MaxClaims=1;RetryEligibleWorkTypes=@('test.worker.readonly-mutation');TransientSqlNumbers=@(15664)}
 Assert-Fixture ($result.Summary.Failed-eq1 -and $result.Summary.Retried-eq0 -and $result.Summary.Unresolved-eq0) 'READONLY_MUTATION_PERMANENT'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueue WHERE WorkTypeName='test.worker.readonly-mutation' AND Status='FAILED' AND FailureCode='WORKER.SQL_15664';" -Scalar)-eq1) 'SQL_READONLY_ENFORCEMENT'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM dbo.TbxWorkerLedger WHERE Scenario='readonly-mutation';" -Scalar)-eq0) 'READONLY_MUTATION_ROLLBACK'
 $phase='protected-context-drift'
 Add-FixtureWork 'test.worker.context-drift' ''
 $result=Run-FixtureWorker @{MaxClaims=1;RetryEligibleWorkTypes=@('test.worker.context-drift');TransientSqlNumbers=@(50002)}
 Assert-Fixture ($result.Summary.Unresolved-eq1 -and $result.Summary.Retried-eq0 -and (Get-FixtureStatus 'test.worker.context-drift')-eq'CLAIMED') 'PROTECTED_EXECUTION_DRIFT'
 Assert-Fixture ((Invoke-FixtureSql "SELECT COUNT(*) FROM dbo.TbxWorkerLedger WHERE Scenario='context-drift';" -Scalar)-eq0) 'CONTEXT_DRIFT_EFFECT_NOT_COMMITTED'
 if($IdentityGuardsOnly){'PASS: external queue focused protected identity; actual readonly SQL15664 permanent denial, rollback and context drift.'}
 else{
  'PASS: external queue synthetic runtime; transaction, Unicode, retry, cancellation, protected identity, slots and drain.'
  if($SkipLongHeartbeat){'NOT_EXECUTED: external queue handler beyond 60-second heartbeat interval.'}
  else{'PASS: external queue independent heartbeat while handler runs beyond 60 seconds.'}
  'NOT_EXECUTED: ambiguous commit transport fault, cross-principal rights, recovery races and central deployment.'
 }
}catch{
 $category=$_.Exception.GetType().Name
 $line=$_.InvocationInfo.ScriptLineNumber
 $sqlNumber=0;$cause=$_.Exception
 while($cause){if($cause-is[Data.SqlClient.SqlException]){$sqlNumber=$cause.Number};$cause=$cause.InnerException}
 $oracle='UNSPECIFIED'
 if($_.Exception.Message-match '^Synthetic worker oracle failed: ([A-Z0-9_]+)$'){$oracle=$Matches[1]}
 if($oracle-ne'UNSPECIFIED' -and (Get-Variable result -ErrorAction SilentlyContinue)){
  'SYNTHETIC_ORACLE_DIAGNOSTICS: '+([pscustomobject]@{Summary=$result.Summary;Events=@($result.Events|ForEach-Object {[pscustomobject]@{Event=$_.Event;Code=$_.Code}})}|ConvertTo-Json -Depth 5 -Compress)
 }
 throw "External queue synthetic qualification failed (phase=$phase,category=$category,line=$line,sql=$sqlNumber,oracle=$oracle); private diagnostics suppressed."
}finally{
 # Weder SQL-KILL noch forcierter Verbindungsabbruch: erst alle eigenen Verbraucher abwarten.
 foreach($handle in $workerProcesses){
  $cleanupDeadline=[DateTimeOffset]::UtcNow.AddSeconds(180)
  while(-not$handle.Process.HasExited -and [DateTimeOffset]::UtcNow-lt$cleanupDeadline){[void]$handle.Process.WaitForExit(1000)}
  if(-not$handle.Process.HasExited){$cleanupDeferred=$true}
  if($handle.Process.HasExited){$handle.Process.Dispose()}
 }
 [Environment]::SetEnvironmentVariable($privateEnvironment,$previousEnvironment,'Process')
 if($connection){
  if($created -and -not$cleanupDeferred){
   try{$connection.ChangeDatabase('master');Invoke-FixtureSql "DROP DATABASE [$database];"}
   catch{$cleanupDeferred=$true}
  }
  $connection.Dispose()
 }
 if(-not$cleanupDeferred -and (Test-Path -LiteralPath $temporaryRoot)){
  # Nur exakt eigene Dateien; keine rekursive oder berechnete Fremdlöschung.
  $stopPath=Join-Path $temporaryRoot 'stop'
  if(Test-Path -LiteralPath $stopPath){Remove-Item -LiteralPath $stopPath}
  Remove-Item -LiteralPath $temporaryRoot
 }
 $privateConnection=$null;$builder=$null
 if($cleanupDeferred){throw 'Own synthetic cleanup deferred; no forced disconnect or database removal performed.'}
}
