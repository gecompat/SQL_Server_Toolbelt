[CmdletBinding()]
param([Parameter(Mandatory)][string]$ConnectionStringEnvironmentVariable,
 [ValidateSet('2019','2022','2025')][string]$ExpectedSqlVersion,
 [switch]$SkipLongHeartbeat,[switch]$IdentityGuardsOnly,[switch]$ManagedOnly,[switch]$ManagedSqlOnly,[switch]$QueueUpgradeOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(@($ManagedOnly,$ManagedSqlOnly,$QueueUpgradeOnly|Where-Object {$_}).Count-gt1){throw 'Runtime scopes are mutually exclusive.'}
$managedScope=$ManagedOnly -or $ManagedSqlOnly -or $QueueUpgradeOnly
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$database='Toolbelt_ExternalQueue_'+[guid]::NewGuid().ToString('N')
$created=$false;$connection=$null;$workerProcesses=[Collections.Generic.List[object]]::new()
$privateEnvironment='TBX_EXTERNAL_QUEUE_FIXTURE_CONNECTION'
$previousEnvironment=[Environment]::GetEnvironmentVariable($privateEnvironment,'Process')
$temporaryRoot=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltQueueFixture_'+[guid]::NewGuid().ToString('N'))
$phase='preflight';$cleanupDeferred=$false
$managedIdentity=$null;$managedRun=[guid]::NewGuid();$managedMarker='Toolbelt.ManagedWorkerFixture.Run'
$originalFailure=$null;$fixtureSqlFailure=$null;$managedFixtureFailure=$null;$cleanupSqlFailure=$null;$managedCleanupPhase='not-started';$historicalFiles=[Collections.Generic.List[object]]::new();$historicalDirectories=[Collections.Generic.List[string]]::new();$secondaryFailures=[Collections.Generic.List[string]]::new()
$managedJournalHash=$null;$managedMarkerConfirmed=$false;$managedDbDropped=$false;$managedControlDeploymentStarted=$false
function Get-ManagedPublicFailureDescriptor($Diagnostic) {
 # Ausschließlich feste Sourcebezeichnungen und numerische SQLcodes veröffentlichen.
 $safe=[ordered]@{Phase='UNSPECIFIED';LastPassedCase='UNSPECIFIED';SqlNumber=0;SqlState=0}
 if($Diagnostic-isnot[Collections.IDictionary]){return [pscustomobject]$safe}
 $phases=@('budget-two','control-timeout','control-timeout-end','control-timeout-fence','control-timeout-lock','control-timeout-reconcile-end','control-timeout-reconcile-hold','control-timeout-release-denied','empty-modes','enable-budget','explicit-release','explicit-release-handler','explicit-release-original-end','explicit-release-publish','late-stop','legacy-bypass','own-database-guard','preflight','race','race-handler','synthetic-handlers','synthetic-held-release','worker-admission')
 $cases=@('NONE','EMPTY_BOUNDED_END','EMPTY_CONTINUOUS_WAIT_TWO_SUPERVISORS','ZERO_BUDGET','LIVE_BUDGET_TWO_REDUCED_WITHOUT_CANCEL','ACTUAL_CANCEL_ROLLBACK_HELD','EXPLICIT_RELEASE_OTHER_REGISTERED_WORKER','LEGACY_CLAIM_REJECTED','KNOWN_COMMIT_WINS_LATE_STOP','ACTUAL_COMPLETION_STOP_RENDEZVOUS','ACTUAL_CONTROL_TIMEOUT_UNKNOWN_OCCUPIED_NO_REPLAY','UNKNOWN_RELEASE_DENIED_EXPLICIT_RECONCILIATION_END')
 if($Diagnostic.Contains('Phase') -and $Diagnostic['Phase']-is[string] -and $Diagnostic['Phase']-cin$phases){$safe.Phase=$Diagnostic['Phase']}
 if($Diagnostic.Contains('LastPassedCase') -and $Diagnostic['LastPassedCase']-is[string] -and $Diagnostic['LastPassedCase']-cin$cases){$safe.LastPassedCase=$Diagnostic['LastPassedCase']}
 if($Diagnostic.Contains('SqlNumber') -and $Diagnostic['SqlNumber']-is[int]){$safe.SqlNumber=$Diagnostic['SqlNumber']}
 if($Diagnostic.Contains('SqlState') -and $Diagnostic['SqlState']-is[int] -and $Diagnostic['SqlState']-ge0 -and $Diagnostic['SqlState']-le255){$safe.SqlState=$Diagnostic['SqlState']}
 return [pscustomobject]$safe
}
function Save-ManagedFixtureJournal {
 if(-not$managedScope -or -not[IO.Directory]::Exists($temporaryRoot)){return}
 $record=[ordered]@{Run=$managedRun;Database=$database;Created=$created;ProcessId=$PID;DatabaseId=$null;CreatedBytes=$null;MarkerName=$managedMarker;MarkerConfirmed=$managedMarkerConfirmed;ControlDeploymentStarted=$managedControlDeploymentStarted;Stage=$phase;DatabaseDropped=$managedDbDropped;PrivateSqlFailure=$fixtureSqlFailure;PrivateManagedFailure=$managedFixtureFailure;PrivateCleanupFailure=$cleanupSqlFailure;PrivateEvidenceRetained=($null-ne$originalFailure);Primary=$null;Secondary=$secondaryFailures.ToArray()}
 if($null-ne$managedIdentity){$record.DatabaseId=$managedIdentity.Id;$record.CreatedBytes=[Convert]::ToHexString($managedIdentity.CreatedBytes)}
 if($null-ne$originalFailure){$record.Primary=$originalFailure}
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $record -Depth 5 -Compress))
 $journal=Join-Path $temporaryRoot 'ManagedOwnership.json'
 $stream=[IO.File]::Open($journal,$(if($null-eq$managedJournalHash){[IO.FileMode]::CreateNew}else{[IO.FileMode]::Open}),[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try{
  if($null-ne$managedJournalHash){
   if($stream.Length-gt65536){throw 'MANAGED.JOURNAL_DRIFT'}
   $previous=[byte[]]::new([int]$stream.Length);$read=0
   while($read-lt$previous.Length){$n=$stream.Read($previous,$read,$previous.Length-$read);if($n-le0){throw 'MANAGED.JOURNAL_READ'};$read+=$n}
   if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($previous))-cne$managedJournalHash){throw 'MANAGED.JOURNAL_DRIFT'}
  }
  $stream.Position=0;$stream.SetLength(0);$stream.Write($bytes,0,$bytes.Length);$stream.Flush()
  $script:managedJournalHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
 }finally{$stream.Dispose()}
}
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
 $batchIndex=0
 foreach($batch in [regex]::Split((Expand-FixtureSql $Path),'(?im)^\s*GO\s*$')){
  if([string]::IsNullOrWhiteSpace($batch)){continue}
  $batchIndex++
  try{Invoke-FixtureSql $batch}
  catch{
   if($null-eq$fixtureSqlFailure){
    $cause=$_.Exception
    while($cause -and $cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
    if($cause){
     $sqlErrors=@($cause.Errors|Select-Object -First 4|ForEach-Object {
      $message=[string]$_.Message
      [pscustomobject]@{Number=$_.Number;State=$_.State;Class=$_.Class;Line=$_.LineNumber;Procedure=$_.Procedure;Message=$message.Substring(0,[Math]::Min(1024,$message.Length));MessageTruncated=($message.Length-gt1024)}
     })
     $script:fixtureSqlFailure=[ordered]@{File=$Path;BatchIndex=$batchIndex;Errors=$sqlErrors;ErrorsTruncated=($cause.Errors.Count-gt4)}
    }
   }
   throw
  }
 }
}
function Invoke-IsolatedLifecycleFailure([string]$Path,[int]$Number,[int]$State){
 # Jede erwartete Abweisung verwendet eine eigene Connection: keine verbliebenen
 # Lifecycle-Temps oder Callertransaktionen zwischen den Negativfällen.
 $isolatedBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new([Environment]::GetEnvironmentVariable($privateEnvironment))
 $isolatedBuilder.Pooling=$false;$isolatedBuilder.Enlist=$false;$isolatedBuilder.ConnectRetryCount=0
 $isolated=[Data.SqlClient.SqlConnection]::new($isolatedBuilder.ConnectionString)
 $matched=$false
 try{
  $isolated.Open();$guard=$isolated.CreateCommand();$guard.CommandTimeout=10
  try{
   $guard.CommandText='IF DB_ID()<>@Id OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Name AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created AND owner_sid=SUSER_SID()) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND SQL_VARIANT_PROPERTY(value,''BaseType'')=''uniqueidentifier'' AND TRY_CONVERT(uniqueidentifier,value)=@Run) THROW 54954,N''Isolierter Lifecycle besitzt nicht die eigene Testdatenbank.'',1;'
   foreach($pair in @{'@Id'=$managedIdentity.Id;'@Name'=$database;'@Created'=$managedIdentity.CreatedBytes;'@Marker'=$managedMarker;'@Run'=$managedRun}.GetEnumerator()){[void]$guard.Parameters.AddWithValue($pair.Key,$pair.Value)}
   [void]$guard.ExecuteNonQuery()
  }finally{$guard.Dispose()}
  $expanded=(Expand-FixtureSql $Path).Replace('$(ConfirmNoExternalConsumers)','1').Replace('$(AllowDataLoss)','1')
  foreach($batch in [regex]::Split($expanded,'(?im)^\s*GO\s*$')){
   if([string]::IsNullOrWhiteSpace($batch)){continue}
   $command=$isolated.CreateCommand();$command.CommandTimeout=10;$command.CommandText=$batch
   try{[void]$command.ExecuteNonQuery()}
   catch{
    $cause=$_.Exception;while($cause -and $cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
    if($null-eq$cause -or $cause.Number-ne$Number -or [int]$cause.State-ne$State){throw}
    $matched=$true;break
   }finally{$command.Dispose()}
  }
  Assert-Fixture $matched 'MANAGED_LIFECYCLE_EXPECTED_DENIAL'
 }finally{$isolated.Dispose();$isolatedBuilder=$null}
}
function New-ControlRepeatConnection {
 # Eigene, nicht enlistete Connection; Identität vor jedem zusätzlichen Actor prüfen.
 $repeatBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new([Environment]::GetEnvironmentVariable($privateEnvironment))
 $repeatBuilder.Pooling=$false;$repeatBuilder.Enlist=$false;$repeatBuilder.ConnectRetryCount=0
 $isolated=[Data.SqlClient.SqlConnection]::new($repeatBuilder.ConnectionString)
 try{
  $isolated.Open();$guard=$isolated.CreateCommand();$guard.CommandTimeout=10
  try{
   $guard.CommandText='IF DB_ID()<>@Id OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Name AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created AND owner_sid=SUSER_SID()) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND SQL_VARIANT_PROPERTY(value,''BaseType'')=''uniqueidentifier'' AND TRY_CONVERT(uniqueidentifier,value)=@Run) OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 OR @@LOCK_TIMEOUT<>-1 THROW 54962,N''Repeatactor besitzt nicht die eigene neutrale Standardsitzung.'',1;'
   foreach($pair in @{'@Id'=$managedIdentity.Id;'@Name'=$database;'@Created'=$managedIdentity.CreatedBytes;'@Marker'=$managedMarker;'@Run'=$managedRun}.GetEnumerator()){[void]$guard.Parameters.AddWithValue($pair.Key,$pair.Value)}
   [void]$guard.ExecuteNonQuery()
  }finally{$guard.Dispose()}
  return $isolated
 }catch{$isolated.Dispose();throw}
}
function Invoke-ControlRepeatExpectedFailure([string]$Path,[int]$Number,[int]$State,[switch]$RollbackOwned){
 $isolated=New-ControlRepeatConnection;$matched=$false
 try{
  foreach($batch in [regex]::Split((Expand-FixtureSql $Path),'(?im)^\s*GO\s*$')){
   if([string]::IsNullOrWhiteSpace($batch)){continue}
   $command=$isolated.CreateCommand();$command.CommandTimeout=10;$command.CommandText=$batch
   try{[void]$command.ExecuteNonQuery()}
   catch{
    $cause=$_.Exception;while($cause -and $cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
    if($null-eq$cause -or $cause.Number-ne$Number -or ($State-ge0 -and [int]$cause.State-ne$State)){throw}
    $matched=$true;break
   }finally{$command.Dispose()}
  }
  Assert-Fixture $matched 'CONTROL_REPEAT_EXPECTED_DENIAL'
  $check=$isolated.CreateCommand();$check.CommandTimeout=10
  try{
   if($RollbackOwned){
    # Sourcefehler über GO können keine äußere TRY/CATCH-Klammer besitzen.
    # Ausschließlich diese frisch eröffnete eigene Actorconnection wiederherstellen.
    $check.CommandText='IF DB_ID()<>@Id OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND TRY_CONVERT(uniqueidentifier,value)=@Run) THROW 54962,N''Eigener Source-Rollback besitzt nicht die Fixture.'',2;IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;SET LOCK_TIMEOUT -1;'
    foreach($pair in @{'@Id'=$managedIdentity.Id;'@Created'=$managedIdentity.CreatedBytes;'@Marker'=$managedMarker;'@Run'=$managedRun}.GetEnumerator()){[void]$check.Parameters.AddWithValue($pair.Key,$pair.Value)}
    [void]$check.ExecuteNonQuery();$check.Parameters.Clear()
   }
   $check.CommandText='SELECT CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 AND @@LOCK_TIMEOUT=-1 THEN 1 ELSE 0 END;';Assert-Fixture ($check.ExecuteScalar()-eq1) 'CONTROL_REPEAT_DENIAL_TRANSACTION_NEUTRAL'
  }finally{$check.Dispose()}
 }finally{$isolated.Dispose()}
}
function Save-ControlRepeatBaseline {
 Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/RepeatInstalled.Snapshot.sql')
 Invoke-FixtureSql 'DROP TABLE IF EXISTS #tbx_ControlRepeatRows;DROP TABLE IF EXISTS #tbx_ControlRepeatCatalog;SELECT * INTO #tbx_ControlRepeatRows FROM #tbx_ControlRepeatActualRows;SELECT * INTO #tbx_ControlRepeatCatalog FROM #tbx_ControlRepeatActualCatalog;'
}
function Compare-ControlRepeatBaseline {
 Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/RepeatInstalled.Snapshot.sql')
 Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/RepeatInstalled.Compare.sql')
}
function Test-ControlRepeatSessionGuard([string]$Path,[switch]$Implicit,[switch]$NondefaultTimeout){
 $isolated=New-ControlRepeatConnection
 try{
  $setup=$isolated.CreateCommand();$setup.CommandTimeout=10
  try{
   $setup.CommandText='CREATE TABLE #RepeatCallerSentinel(Value int NOT NULL);INSERT #RepeatCallerSentinel VALUES(1);'+$(if($NondefaultTimeout){'SET LOCK_TIMEOUT 1234;'}elseif($Implicit){'SET IMPLICIT_TRANSACTIONS ON;'}else{'BEGIN TRANSACTION;UPDATE #RepeatCallerSentinel SET Value=2;'})
   [void]$setup.ExecuteNonQuery()
  }finally{$setup.Dispose()}
  $batch=([regex]::Split((Expand-FixtureSql $Path),'(?im)^\s*GO\s*$')|Where-Object {-not[string]::IsNullOrWhiteSpace($_)}|Select-Object -First 1)
  $command=$isolated.CreateCommand();$command.CommandTimeout=10;$command.CommandText=$batch;$matched=$false
  try{[void]$command.ExecuteNonQuery()}
  catch{
   $cause=$_.Exception;while($cause -and $cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
   if($null-eq$cause -or $cause.Number-ne50000 -or [int]$cause.State-ne1){throw}
   $matched=$true
  }finally{$command.Dispose()}
  Assert-Fixture $matched 'CONTROL_REPEAT_CALLER_DENIAL'
  $check=$isolated.CreateCommand();$check.CommandTimeout=10
  try{
   $check.CommandText=if($NondefaultTimeout){'IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 OR @@LOCK_TIMEOUT<>1234 OR (SELECT Value FROM #RepeatCallerSentinel)<>1 THROW 54963,N''Timeoutguard veränderte Callerzustand.'',5;SET LOCK_TIMEOUT -1;'}elseif($Implicit){'IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 OR (@@OPTIONS&2)<>2 OR @@LOCK_TIMEOUT<>-1 THROW 54963,N''Implicitguard veränderte Callerzustand.'',1;SET IMPLICIT_TRANSACTIONS OFF;IF (SELECT Value FROM #RepeatCallerSentinel)<>1 THROW 54963,N''Implicitguard veränderte Sentinel.'',2;'}else{'IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR @@LOCK_TIMEOUT<>-1 OR (SELECT Value FROM #RepeatCallerSentinel)<>2 THROW 54963,N''Lifecycle rollbackte fremde Callertransaktion.'',3;ROLLBACK TRANSACTION;IF (SELECT Value FROM #RepeatCallerSentinel)<>1 THROW 54963,N''Eigener Sentinelrollback fehlt.'',4;'}
   [void]$check.ExecuteNonQuery()
  }finally{$check.Dispose()}
 }finally{$isolated.Dispose()}
}
function Test-ControlRepeatWriterFence([string]$Path,[ValidateSet('WorkerSlotReservation','WorkQueueManagedGate')][string]$Table){
 Save-ControlRepeatBaseline
 $writer=New-ControlRepeatConnection;$command=$writer.CreateCommand();$command.CommandTimeout=10
 try{
  # Kein UPDATE: dadurch auch keine unbewiesene Rowversionwiederherstellung.
  $command.CommandText="BEGIN TRANSACTION;DECLARE @FenceValue int;SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.[$Table] WITH(TABLOCKX,HOLDLOCK);";[void]$command.ExecuteNonQuery()
  Invoke-ControlRepeatExpectedFailure $Path 1222 -1
  $command.CommandText='IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 54964,N''Writertransaktion wurde verändert.'',1;ROLLBACK TRANSACTION;IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54964,N''Eigene Writertransaktion blieb offen.'',2;';[void]$command.ExecuteNonQuery()
  Compare-ControlRepeatBaseline
 }finally{$command.Dispose();$writer.Dispose()}
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
 Assert-Fixture ((Invoke-FixtureSql 'SELECT CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 THEN 1 ELSE 0 END;' -Scalar)-eq1) 'INITIAL_TRANSACTION_STATE'
 Assert-Fixture ((Invoke-FixtureSql 'SELECT COUNT(*) FROM sys.databases WHERE name=@Database;' @{'@Database'=$database} -Scalar)-eq0) 'DATABASE_UNIQUENESS'
 $phase='create'
 if($managedScope){[void][IO.Directory]::CreateDirectory($temporaryRoot);Save-ManagedFixtureJournal}
 Invoke-FixtureSql "CREATE DATABASE [$database] COLLATE Latin1_General_100_CS_AS;";$created=$true
 if($managedScope){$phase='created';Save-ManagedFixtureJournal}
 $connection.ChangeDatabase($database);$builder['Initial Catalog']=$database
 [Environment]::SetEnvironmentVariable($privateEnvironment,$builder.ConnectionString,'Process')
 [void][IO.Directory]::CreateDirectory($temporaryRoot)
 if($managedScope){
  Save-ManagedFixtureJournal
  $identityCommand=$connection.CreateCommand();$identityCommand.CommandText='SELECT CONVERT(int,DB_ID()),create_date,CONVERT(binary(9),CONVERT(datetime2(7),create_date)) FROM sys.databases WHERE database_id=DB_ID();';$identityCommand.CommandTimeout=10
  try{
   $identityReader=$identityCommand.ExecuteReader()
   try{
    Assert-Fixture ($identityReader.Read()) 'MANAGED_DATABASE_IDENTITY'
    $managedIdentity=[pscustomobject]@{Id=$identityReader.GetInt32(0);Created=$identityReader.GetDateTime(1);CreatedBytes=$identityReader.GetValue(2)}
    Assert-Fixture (-not$identityReader.Read() -and -not$identityReader.NextResult()) 'MANAGED_DATABASE_IDENTITY_SHAPE'
   }finally{$identityReader.Dispose()}
  }finally{$identityCommand.Dispose()}
  $phase='managed-database-identified';Save-ManagedFixtureJournal
  Invoke-FixtureSql 'EXEC sys.sp_addextendedproperty @name=@Marker,@value=@Run;' @{'@Marker'=$managedMarker;'@Run'=$managedRun}
  $managedMarkerConfirmed=$true;$phase='managed-database-marked';Save-ManagedFixtureJournal
 }
 $phase='deploy'
 foreach($module in @('result-table','execution-context','execution-cancel','work-type','work-queue')){
  $phase='deploy-'+$module
  Save-ManagedFixtureJournal
  if($QueueUpgradeOnly -and $module-ceq'work-queue'){
   $phase='queue-upgrade-capture';Save-ManagedFixtureJournal
   . (Join-Path $PSScriptRoot 'New-GenuineQueue20Capture.ps1')
   $historicalDeploy=New-GenuineQueue20Capture -RepositoryRoot $root -OutputRoot (Join-Path $temporaryRoot 'queue20') -OwnedFiles $historicalFiles -OwnedDirectories $historicalDirectories
   $phase='queue-upgrade-original20';Save-ManagedFixtureJournal
   Invoke-FixtureFile $historicalDeploy
   $phase='queue-upgrade-setup';Save-ManagedFixtureJournal
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.work-queue/Tests/Runtime/UpgradeFrom2_0.Setup.sql')
   $phase='queue-upgrade-current21';Save-ManagedFixtureJournal
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.work-queue/Deployment/Deploy.sql')
   $phase='queue-upgrade-verify';Save-ManagedFixtureJournal
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.work-queue/Tests/Runtime/UpgradeFrom2_0.Verify.sql')
  }else{
   Invoke-FixtureFile (Join-Path $root "Modules/toolbelt.core.$module/Deployment/Deploy.sql")
  }
 }
 if($QueueUpgradeOnly){
  $phase='queue-repeat-setup';Save-ManagedFixtureJournal
  Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.work-queue/Tests/Runtime/RepeatCurrent.Setup.sql')
  foreach($repeat in 1..2){
   $phase='queue-repeat-current21';Save-ManagedFixtureJournal
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.work-queue/Deployment/Deploy.sql')
   $phase='queue-repeat-verify';Save-ManagedFixtureJournal
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.work-queue/Tests/Runtime/RepeatCurrent.Verify.sql')
  }
  'PASS: queue2.1 repeat twice; all seven states and five persistent table snapshots preserved.'
  'PASS: genuine queue2.0 to2.1 focused upgrade; preserved rows, original active claim and legacy eight-field admission.'
  $phase='control-repeat-complete-claims';Save-ManagedFixtureJournal
  Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/RepeatInstalled.Setup.sql')
  $phase='control-repeat-install';$managedControlDeploymentStarted=$true;Save-ManagedFixtureJournal
  Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Deployment/Deploy.sql')
  Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/RepeatInstalled.Seed.sql')
  $queueDeploy=Join-Path $root 'Modules/toolbelt.core.work-queue/Deployment/Deploy.sql'
  $controlDeploy=Join-Path $root 'Modules/toolbelt.core.worker-control/Deployment/Deploy.sql'
  $phase='control-repeat-session-guards';Save-ManagedFixtureJournal
  foreach($path in @($queueDeploy,$controlDeploy)){
   Test-ControlRepeatSessionGuard $path
   Test-ControlRepeatSessionGuard $path -Implicit
   Test-ControlRepeatSessionGuard $path -NondefaultTimeout
  }
  $phase='control-repeat-state-guards';Save-ManagedFixtureJournal
  # Jede Abweisung konserviert gerade den absichtlich ungültigen Zustand;
  # erst anschließend wird die eigene synthetische Mutation zurückgenommen.
  Invoke-FixtureSql "SELECT value PropertyValue INTO #tbx_ControlRepeatOriginalMarker FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.WorkerRegistration') AND minor_id=0 AND name=N'Toolbelt.ModuleVersion';"
  $cases=@(
   @{Set="UPDATE toolbelt_core.WorkerSlotReservation SET IsOccupied=1 WHERE State='COMMITTED';";Restore="UPDATE toolbelt_core.WorkerSlotReservation SET IsOccupied=0 WHERE State='COMMITTED';";State=4},
   @{Set="UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1 WHERE StopStatus='ALREADY_COMMITTED';";Restore="UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=0 WHERE StopStatus='ALREADY_COMMITTED';";State=4},
   @{Set='UPDATE toolbelt_core.WorkQueueManagedGate SET ManagedEnabled=1 WHERE GateId=1;';Restore='UPDATE toolbelt_core.WorkQueueManagedGate SET ManagedEnabled=0 WHERE GateId=1;';State=4},
   @{Set="UPDATE toolbelt_core.WorkQueueManagedGate SET PendingReservationId='00000000-0000-0000-0000-000000006099' WHERE GateId=1;";Restore='UPDATE toolbelt_core.WorkQueueManagedGate SET PendingReservationId=NULL WHERE GateId=1;';State=4},
   @{Set="EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.1',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'TABLE',@level1name=N'WorkerRegistration';";Restore="DECLARE @Original sql_variant=(SELECT PropertyValue FROM #tbx_ControlRepeatOriginalMarker);EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Original,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'TABLE',@level1name=N'WorkerRegistration';";State=5},
   @{Set="EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0 ',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'TABLE',@level1name=N'WorkerRegistration';";Restore="DECLARE @Original sql_variant=(SELECT PropertyValue FROM #tbx_ControlRepeatOriginalMarker);EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Original,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'TABLE',@level1name=N'WorkerRegistration';";State=5},
   @{Set="EXEC sys.sp_rename N'toolbelt_core.CK_WorkItem_Status',N'CK_WorkItem_Status_TestRename',N'OBJECT';";Restore="EXEC sys.sp_rename N'toolbelt_core.CK_WorkItem_Status_TestRename',N'CK_WorkItem_Status',N'OBJECT';";State=5},
   @{Set='ALTER INDEX UX_WorkItem_WorkType_IdempotencyKey ON toolbelt_core.WorkItem DISABLE;';Restore='ALTER INDEX UX_WorkItem_WorkType_IdempotencyKey ON toolbelt_core.WorkItem REBUILD;';State=5}
  )
  foreach($case in $cases){
   Invoke-FixtureSql $case.Set;Save-ControlRepeatBaseline
   Invoke-ControlRepeatExpectedFailure $queueDeploy 54202 $case.State
   Compare-ControlRepeatBaseline
   Invoke-FixtureSql $case.Restore
  }
  $phase='control-repeat-writer-fence';Save-ManagedFixtureJournal
  foreach($path in @($queueDeploy,$controlDeploy)){
   foreach($table in @('WorkerSlotReservation','WorkQueueManagedGate')){Test-ControlRepeatWriterFence $path $table}
  }
  $phase='control-repeat-post-source-rollback';Save-ManagedFixtureJournal
  Save-ControlRepeatBaseline
  Invoke-FixtureSql "CREATE TRIGGER Tbx_ControlRepeatRollback ON DATABASE FOR ALTER_PROCEDURE AS BEGIN SET NOCOUNT ON;THROW 54969,N'Synthetischer PostSource-Rollbackfall.',1;END;"
  Invoke-ControlRepeatExpectedFailure $queueDeploy 54969 1 -RollbackOwned
  Compare-ControlRepeatBaseline
  Invoke-FixtureSql 'DROP TRIGGER Tbx_ControlRepeatRollback ON DATABASE;'
  Save-ControlRepeatBaseline
  foreach($repeat in 1..2){
   $phase='control-repeat-current21';Save-ManagedFixtureJournal
   Invoke-FixtureFile $queueDeploy
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/RepeatInstalled.Verify.sql')
   $phase='control-repeat-current10';Save-ManagedFixtureJournal
   Invoke-FixtureFile $controlDeploy
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/RepeatInstalled.Verify.sql')
  }
  'PASS: installed quiescent control1.0 and queue2.1 repeat twice; ten binary table snapshots, identities and catalog preserved.'
  'PASS: caller and implicit transaction guards, state and metadata denials, bounded writer fence and post-source rollback.'
  'NOT_EXECUTED: nonempty synthetic grant witness, active managed refresh and remaining platforms.'
  return
 }
 if($managedScope){
  $phase='deploy-worker-control';$managedControlDeploymentStarted=$true
  Save-ManagedFixtureJournal
  Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Deployment/Deploy.sql')
  if($ManagedSqlOnly){
   $phase='managed-sql-runtime'
   Save-ManagedFixtureJournal
   Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/WorkerControl.Contract.sql')
   foreach($lifecycleCase in @('Occupied','Held','Dependency')){
    $phase='managed-lifecycle-'+$lifecycleCase.ToLowerInvariant();Save-ManagedFixtureJournal
    Invoke-FixtureFile (Join-Path $root ('Modules/toolbelt.core.worker-control/Tests/Runtime/Lifecycle'+$lifecycleCase+'.Setup.sql'))
    foreach($operation in @('Deploy','Uninstall')){
     Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/Lifecycle.Snapshot.sql')
     $expectedNumber=if($lifecycleCase-ceq'Dependency'){54243}elseif($operation-ceq'Deploy'){54242}else{54246}
     $expectedState=if($operation-ceq'Uninstall' -and $lifecycleCase-cne'Dependency'){2}else{1}
     Invoke-IsolatedLifecycleFailure (Join-Path $root ('Modules/toolbelt.core.worker-control/Deployment/'+$operation+'.sql')) $expectedNumber $expectedState
     Invoke-FixtureFile (Join-Path $root 'Modules/toolbelt.core.worker-control/Tests/Runtime/Lifecycle.Verify.sql')
    }
   }
   'PASS: managed SQL admission, generations, holds, private gates and data-preserving lifecycle denials.'
   return
  }
  $phase='managed-runtime'
  Save-ManagedFixtureJournal
  $managedEvidence=Join-Path $temporaryRoot 'managed'
  [void][IO.Directory]::CreateDirectory($managedEvidence)
  try{
   $managedResult=& (Join-Path $PSScriptRoot 'Invoke-ManagedContract.ps1') -ConnectionStringEnvironmentVariable $privateEnvironment -ExpectedDatabaseId $managedIdentity.Id -ExpectedDatabaseCreatedAt $managedIdentity.Created -ExpectedDatabaseRunMarkerName $managedMarker -ExpectedRunId $managedRun -EvidenceDirectory $managedEvidence
   Assert-Fixture ($managedResult.Status -ceq 'PASS' -and $managedResult.Secondary.Count -eq 0) 'MANAGED_RUNTIME_STATUS'
   'PASS: external queue managed focused runtime; budget, cancellation, hold, release and disposition race.'
   'NOT_EXECUTED: commit transport loss, cross-principal rights and full target matrix.'
  }catch{$cleanupDeferred=$true;throw}
  return
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
 while($cause){if($cause-is[Data.SqlClient.SqlException]){$sqlNumber=$cause.Number};if($cause.Data.Contains('Toolbelt.ManagedFixture.Diagnostic')){$managedFixtureFailure=$cause.Data['Toolbelt.ManagedFixture.Diagnostic']};$cause=$cause.InnerException}
 $oracle='UNSPECIFIED'
 if($_.Exception.Message-match '^Synthetic worker oracle failed: ([A-Z0-9_]+)$'){$oracle=$Matches[1]}
 if($null-ne$managedFixtureFailure){$oracle=$managedFixtureFailure.CaseCode}
 $originalFailure=[ordered]@{Phase=$phase;Category=$category;Line=$line;SqlNumber=$sqlNumber;Oracle=$oracle}
 try{Save-ManagedFixtureJournal}catch{$secondaryFailures.Add('MANAGED.JOURNAL_FAILURE_RECORD_FAILED')}
 if($oracle-ne'UNSPECIFIED' -and (Get-Variable result -ErrorAction SilentlyContinue)){
  'SYNTHETIC_ORACLE_DIAGNOSTICS: '+([pscustomobject]@{Summary=$result.Summary;Events=@($result.Events|ForEach-Object {[pscustomobject]@{Event=$_.Event;Code=$_.Code}})}|ConvertTo-Json -Depth 5 -Compress)
 }
 if($null-ne$managedFixtureFailure){
  $publicManagedFailure=Get-ManagedPublicFailureDescriptor $managedFixtureFailure
  Write-Information ('SYNTHETIC_MANAGED_FAILURE_DESCRIPTOR: '+(ConvertTo-Json -InputObject $publicManagedFailure -Compress)) -InformationAction Continue
 }
 if($null-ne$fixtureSqlFailure){
  # Nur numerische Enginepositionen und bekannte Sourcekonstanten: keine
  # beliebigen Messages, Zielwerte, Objekt-/Dateinamen oder Runtimeausgaben.
  $publicSqlErrors=@($fixtureSqlFailure.Errors|ForEach-Object {
   $guard='UNSPECIFIED'
   if($_.Message-ceq'Lifecycle darf keine Callertransaktion oder implizite Transaktion übernehmen.'){$guard='CALLER_OR_IMPLICIT_TRANSACTION'}
   elseif($_.Message-ceq'Lifecycle darf keine aktive Callertransaktion übernehmen.'){$guard='CALLER_TRANSACTION_COUNT'}
   elseif($_.Message-ceq'Lifecycle darf keinen aktiven Transaktionszustand übernehmen.'){$guard='CALLER_TRANSACTION_STATE'}
   elseif($_.Message-ceq'Lifecycle darf keine implizite Transaktion übernehmen.'){$guard='IMPLICIT_TRANSACTION_MODE'}
   elseif($_.Message-ceq'Installierter Queue-/Control-Repeat benötigt initial LOCK_TIMEOUT -1.'){$guard='REPEAT_INITIAL_TIMEOUT'}
   [pscustomobject]@{Number=[int]$_.Number;State=[int]$_.State;Line=[int]$_.Line;Guard=$guard}
  })
  Write-Information ('SYNTHETIC_SQL_FAILURE_DESCRIPTOR: '+(ConvertTo-Json -InputObject ([pscustomobject]@{Batch=[int]$fixtureSqlFailure.BatchIndex;Errors=$publicSqlErrors}) -Depth 4 -Compress)) -InformationAction Continue
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
   try{
    if($managedScope){
     $managedCleanupPhase='own-lifecycle-rollback'
     # Nur die frisch eröffnete, nicht enlistete eigene Fixtureverbindung: erst Identität, dann eigener Lifecycle-Rollback.
     Invoke-FixtureSql 'IF ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 OR DB_ID()<>@Id OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Database AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND TRY_CONVERT(uniqueidentifier,value)=@Run) THROW 50000,N''Synthetic lifecycle rollback identity changed'',1; IF @@TRANCOUNT>0 ROLLBACK TRANSACTION; IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 50000,N''Synthetic lifecycle rollback not ended'',1;' @{'@Id'=$managedIdentity.Id;'@Database'=$database;'@Created'=$managedIdentity.CreatedBytes;'@Marker'=$managedMarker;'@Run'=$managedRun}
     $managedCleanupPhase='catalog-guard'
     Assert-Fixture ((Invoke-FixtureSql 'IF ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 OR DB_ID()<>@Id OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Database AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND TRY_CONVERT(uniqueidentifier,value)=@Run) OR EXISTS(SELECT 1 FROM sys.dm_exec_sessions WHERE database_id=@Id AND session_id<>@@SPID) OR EXISTS(SELECT 1 FROM sys.dm_exec_requests WHERE database_id=@Id AND session_id<>@@SPID) THROW 50000,N''Synthetic database cleanup identity or consumer changed'',1; IF OBJECT_ID(N''toolbelt_core.WorkerSlotReservation'',N''U'') IS NULL BEGIN IF EXISTS(SELECT 1 FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id JOIN (VALUES (N''WorkerControlConfiguration''),(N''WorkerRegistration''),(N''WorkerSlotReservation''),(N''WorkerExecutionDisposition''),(N''WorkerExecutionCommitWitness''),(N''VW_WorkerStatus''),(N''VW_WorkerExecutionStatus''),(N''USP_BeginWorkerCompletion''),(N''USP_BeginWorkerTransactionWitness''),(N''USP_BindWorkerExecution''),(N''USP_ClaimWorkerWork''),(N''USP_CloseWorker''),(N''USP_DisableManagedWorkers''),(N''USP_EnableManagedWorkers''),(N''USP_FinalizeWorkerFailure''),(N''USP_HeartbeatWorker''),(N''USP_ReconcileWorkerExecution''),(N''USP_RecordWorkerCommit''),(N''USP_RecordWorkerRollback''),(N''USP_RecordWorkerUnknown''),(N''USP_RegisterWorker''),(N''USP_ReleaseHeldWork''),(N''USP_ReserveWorkerExecution''),(N''USP_SetWorkerCapacity''),(N''USP_SetWorkerConcurrency''),(N''USP_SetWorkerIntervals''),(N''USP_SetWorkerState''),(N''USP_StopWorkerExecution''),(N''USP_StopWorkers'')) expected(Name) ON o.name COLLATE Latin1_General_100_BIN2=expected.Name COLLATE Latin1_General_100_BIN2 WHERE s.name=N''toolbelt_core'') OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE (class=0 AND name IN(N''Toolbelt.Module.toolbelt.core.worker-control.Version'',N''Toolbelt.Module.toolbelt.core.worker-control.DeploymentMode'')) OR (class=1 AND name=N''Toolbelt.ModuleId'' AND CONVERT(nvarchar(256),value)=N''toolbelt.core.worker-control'')) THROW 50000,N''Synthetic control catalog partially present'',1; END ELSE EXEC sys.sp_executesql N''IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1) THROW 50000,N''''Synthetic occupied reservation remains'''',1;''; SELECT 1;' @{'@Id'=$managedIdentity.Id;'@Database'=$database;'@Created'=$managedIdentity.CreatedBytes;'@Marker'=$managedMarker;'@Run'=$managedRun} -Scalar)-eq1) 'MANAGED_DATABASE_CLEANUP_IDENTITY'
     $managedCleanupPhase='master-drop'
     $connection.ChangeDatabase('master')
     Invoke-FixtureSql "IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Database AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created) OR NOT EXISTS(SELECT 1 FROM [$database].sys.extended_properties WHERE class=0 AND name=@Marker AND TRY_CONVERT(uniqueidentifier,value)=@Run) OR EXISTS(SELECT 1 FROM sys.dm_exec_sessions WHERE database_id=@Id AND session_id<>@@SPID) OR EXISTS(SELECT 1 FROM sys.dm_exec_requests WHERE database_id=@Id AND session_id<>@@SPID) THROW 50000,N'Synthetic database cleanup identity changed',1; DROP DATABASE [$database];" @{'@Id'=$managedIdentity.Id;'@Database'=$database;'@Created'=$managedIdentity.CreatedBytes;'@Marker'=$managedMarker;'@Run'=$managedRun}
     $managedDbDropped=$true;$phase='managed-database-dropped';Save-ManagedFixtureJournal
    }else{$connection.ChangeDatabase('master');Invoke-FixtureSql "DROP DATABASE [$database];"}
   }
   catch{
    $cleanupDeferred=$true;$secondaryFailures.Add('MANAGED.DATABASE_CLEANUP_DEFERRED')
    $cause=$_.Exception;$privateErrors=@()
    while($cause -and $cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
    if($cause){$privateErrors=@($cause.Errors|Select-Object -First 4|ForEach-Object {
     $message=[string]$_.Message
     [pscustomobject]@{Number=$_.Number;State=$_.State;Class=$_.Class;Line=$_.LineNumber;Message=$message.Substring(0,[Math]::Min(1024,$message.Length));MessageTruncated=($message.Length-gt1024)}
    })}
    $cleanupSqlFailure=[ordered]@{Phase=$managedCleanupPhase;Category=$_.Exception.GetType().Name;Line=$_.InvocationInfo.ScriptLineNumber;Errors=$privateErrors}
   }
  }
  try{$connection.Dispose()}catch{$cleanupDeferred=$true;$secondaryFailures.Add('MANAGED.CONTROL_DISPOSE_FAILED')}
 }
 if(-not$cleanupDeferred -and -not($managedScope -and $null-ne$originalFailure) -and (Test-Path -LiteralPath $temporaryRoot)){
  try{
  foreach($capture in $historicalFiles){
   $item=Get-Item -LiteralPath $capture.Path -ErrorAction Stop
   Assert-Fixture ($item.Length-eq$capture.Length -and $item.CreationTimeUtc.Ticks-eq$capture.CreatedTicks -and [int]$item.Attributes-eq$capture.Attributes -and ($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0 -and (Get-FileHash -LiteralPath $capture.Path).Hash-ceq$capture.SHA256) 'HISTORICAL_CLEANUP_IDENTITY'
   Remove-Item -LiteralPath $capture.Path
  }
  foreach($directory in @($historicalDirectories|Sort-Object Length -Descending)){[IO.Directory]::Delete($directory,$false)}
  # Nur exakt eigene Dateien; keine rekursive oder berechnete Fremdlöschung.
  $stopPath=Join-Path $temporaryRoot 'stop'
  if(Test-Path -LiteralPath $stopPath){Remove-Item -LiteralPath $stopPath}
  if($managedScope){
   $managedEvidence=Join-Path $temporaryRoot 'managed'
   if(Test-Path -LiteralPath $managedEvidence){[IO.Directory]::Delete($managedEvidence,$false)}
   $journalPath=Join-Path $temporaryRoot 'ManagedOwnership.json'
   if(Test-Path -LiteralPath $journalPath){Remove-Item -LiteralPath $journalPath}
  }
  Remove-Item -LiteralPath $temporaryRoot
  }catch{$cleanupDeferred=$true;$secondaryFailures.Add('MANAGED.PRIVATE_FILE_CLEANUP_DEFERRED')}
 }
 if($managedScope -and $null-ne$originalFailure -and -not$cleanupDeferred){
  try{Save-ManagedFixtureJournal}catch{$secondaryFailures.Add('MANAGED.JOURNAL_FINAL_RECORD_FAILED')}
 }
 $privateConnection=$null;$builder=$null
 if($cleanupDeferred){
  try{Save-ManagedFixtureJournal}catch{$secondaryFailures.Add('MANAGED.JOURNAL_FINAL_RECORD_FAILED')}
  if($null-eq$originalFailure){throw 'Own synthetic cleanup deferred; no forced disconnect or database removal performed.'}
  Write-Information ([pscustomobject]@{Event='SYNTHETIC_CLEANUP_DEFERRED';Code='MANAGED.CLEANUP_DEFERRED';Secondary=$secondaryFailures.ToArray()}) -Tags 'ToolbeltQueueWorker'
 }
}
