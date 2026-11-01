#Requires -Version 7.5
<#
Zwei echte SQL-Clientabbrüche, keine Simulation durch einen SQL-Fehler:
DebugScript unter beobachteter Blockierung und aktuelle API in Callertransaktion.
Der Koordinator überlebt und reconciliert Ausgang, Daten und eigenen Scope.
Nur eigene sqlcmd-Prozesshandles werden beendet; kein SQL-KILL/VM-/Serverstop.
#>
[CmdletBinding()]
param(
 [ValidateSet('Prepare','Run','Audit')][string]$Mode='Prepare',
 [Parameter(Mandatory)][string]$PlanPath,
 [string]$ExpectedPlanSha256,
 [string]$JournalPath,
 [string]$ExpectedJournalSha256,
 [string]$SsisReleaseDirectory,
 [string]$ParserReleaseDirectory,
 [string]$SqlcmdPath,
 [string]$BudgetPath,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'LabClientCommon.ps1')
. (Join-Path $PSScriptRoot 'RecoveryFixture.ps1')
$PlanPath=[IO.Path]::GetFullPath($PlanPath)
$prefix='Modules/toolbelt.tsql.ssis-debug/'
$files=@('Tests/WindowsClientRecovery/Invoke-TransportRecovery.ps1','Tests/WindowsClientRecovery/LabClientCommon.ps1','Tests/WindowsClientRecovery/RecoveryFixture.ps1',
 'Examples/Installation/PrepareServer.sql','Tests/Runtime/Invoke-LabContract.ps1','Tests/Fixtures/synthetic-8.dtsx','Contracts/DependencyPins.json','Tests/Qualification/Current.Functional.20261031.json')|ForEach-Object {$prefix+$_}
$files+=@('Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1','Modules/toolbelt.core.result-table/Deployment/Deploy.sql','Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql','Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql')
function Private([string]$Path){
 if(-not $Path -or -not [IO.Path]::GetFullPath($Path).StartsWith((Join-Path $repoRoot '.runtime')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_TRANSPORT_PRIVATE_PATH_REQUIRED'}
}
Private $PlanPath
if($Mode-ceq 'Prepare'){
 if(Test-Path $PlanPath){throw 'SSIS_TRANSPORT_PLAN_COLLISION'}
 $lab=Read-ClientLab;$target=Select-ClientTarget $lab '2025' 'CU8'
 $sources=[ordered]@{};foreach($f in $files){$sources[$f]=Get-ClientHash (Join-Path $repoRoot $f)}
 $plan=@{contract='ssis-sql-hard-transport/1';key=[string]$target.key;contractSha256=(Get-ClientHash $lab.Path);files=$sources;
  ssis=[IO.Path]::GetFullPath($SsisReleaseDirectory);parser=[IO.Path]::GetFullPath($ParserReleaseDirectory);sqlcmd=[IO.Path]::GetFullPath($SqlcmdPath);sqlcmdSha256=(Get-ClientHash $SqlcmdPath)}
 Assert-RecoveryArtifacts $plan;Save-ClientPrivate $PlanPath $plan
 'SSIS_TRANSPORT_PLAN_PREPARED; no SQL';return
}
if(-not $ExpectedPlanSha256 -or (Get-ClientHash $PlanPath)-cne $ExpectedPlanSha256){throw 'SSIS_TRANSPORT_PLAN_CHANGED'}
$plan=Get-Content $PlanPath -Raw|ConvertFrom-Json -DateKind String
if($plan.contract-cne 'ssis-sql-hard-transport/1' -or @($plan.files.psobject.Properties).Count-ne $files.Count){throw 'SSIS_TRANSPORT_PLAN_SCHEMA'}
foreach($f in $files){if((Get-ClientHash (Join-Path $repoRoot $f))-cne $plan.files.$f){throw 'SSIS_TRANSPORT_SOURCE_CHANGED'}}
Assert-RecoveryArtifacts $plan
if((Get-ClientHash $plan.sqlcmd)-cne $plan.sqlcmdSha256){throw 'SSIS_TRANSPORT_SQLCMD_CHANGED'}
if($ValidateOnly){'SSIS_TRANSPORT_INPUTS_VALIDATED; no SQL';return}
Private $JournalPath;Private $BudgetPath
$JournalPath=[IO.Path]::GetFullPath($JournalPath);$BudgetPath=[IO.Path]::GetFullPath($BudgetPath)
$lab=Read-ClientLab
if((Get-ClientHash $lab.Path)-cne $plan.contractSha256){throw 'SSIS_TRANSPORT_CONTRACT_CHANGED'}
$target=Select-ClientTarget $lab '2025' 'CU8'
if($target.key-cne $plan.key){throw 'SSIS_TRANSPORT_TARGET_CHANGED'}
Reserve-ClientCase $BudgetPath
$master=Open-ClientSql $target;$connection=$null;$blocker=$null;$child=$null;$journal=$null;$failure=$null;$lease=$false
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target -TestPurpose Functional))
function Save {Save-ClientPrivate $JournalPath $script:journal}
function Check([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_TRANSPORT_'+$Name)};$script:journal.checks.Add($Name)}
function Database-State([string]$Name){
 $r=Query-Client $master ("SELECT database_id,CONVERT(varchar(33),create_date,126) AS C FROM sys.databases WHERE name=N'"+$Name+"';")
 if(-not $r.Rows.Count){return $null};return [ordered]@{id=[int]$r.Rows[0].database_id;created=[string]$r.Rows[0].C}
}
function Reserve-Interruption {
 $b=Get-Content $BudgetPath -Raw|ConvertFrom-Json -DateKind String
 if($b.hardInterruptionUsed-ge $b.maximumHardInterruptionCases -or [datetimeoffset]::UtcNow-ge [datetimeoffset]::Parse($b.ceilingUtc)){throw 'SSIS_TRANSPORT_INTERRUPTION_BUDGET'}
 $b.hardInterruptionUsed++;Save-ClientPrivate $BudgetPath $b
}
function Start-OwnClient([string]$Path,[string]$Marker){
 Reserve-Interruption
 $info=[Diagnostics.ProcessStartInfo]::new($plan.sqlcmd);$info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
 foreach($a in @('-S',$builder.DataSource,'-d',$journal.database,'-N','-b','-l','15','-t','90','-f','65001','-H',$Marker,'-i',$Path)){$info.ArgumentList.Add([string]$a)}
 if($builder.TrustServerCertificate){$info.ArgumentList.Add('-C')}
 $info.ArgumentList.Add('-U');$info.ArgumentList.Add($builder.UserID);$info.Environment['SQLCMDPASSWORD']=$builder.Password
 $p=[Diagnostics.Process]::new();$p.StartInfo=$info
 try{if(-not $p.Start()){throw 'SSIS_TRANSPORT_CLIENT_START'};return @{process=$p;pid=$p.Id;started=$p.StartTime.ToUniversalTime().ToString('o');output=$p.StandardOutput.ReadToEndAsync();error=$p.StandardError.ReadToEndAsync();marker=$Marker}}
 finally{$info.Environment.Remove('SQLCMDPASSWORD')|Out-Null}
}
function Own-Sessions($Client){
 Query-Client $master ("SELECT s.session_id,s.open_transaction_count,r.blocking_session_id,r.wait_type FROM sys.dm_exec_sessions s LEFT JOIN sys.dm_exec_requests r ON r.session_id=s.session_id WHERE s.host_process_id="+$Client.pid+" AND s.host_name=N'"+$Client.marker+"' AND s.database_id="+$journal.databaseState.id+" AND s.program_name=N'SQLCMD';")
}
function End-OwnClient($Client){
 $p=$Client.process
 if($p.HasExited -or $p.Id-ne $Client.pid -or $p.StartTime.ToUniversalTime().ToString('o')-cne $Client.started){throw 'SSIS_TRANSPORT_CLIENT_NOT_OWNED_OR_ALREADY_EXITED'}
 $p.Kill();if(-not $p.WaitForExit(10000)){throw 'SSIS_TRANSPORT_CLIENT_NOT_TERMINATED'}
 Check ($p.ExitCode-ne 0) 'ACTUAL_HARD_CLIENT_TERMINATION'
 foreach($name in @('output','error')){if(-not $Client[$name].Wait(5000)){throw 'SSIS_TRANSPORT_PIPE_NOT_CLOSED'};[IO.File]::WriteAllText($JournalPath+'.'+$Client.marker+'.'+$name+'.txt',$Client[$name].Result,[Text.UTF8Encoding]::new($false))}
}
function Wait-NoClient($Client){
 $clock=[Diagnostics.Stopwatch]::StartNew()
 while($clock.Elapsed.TotalSeconds-lt 35){if((Own-Sessions $Client).Rows.Count-eq 0){return};Start-Sleep -Milliseconds 200}
 throw 'SSIS_TRANSPORT_SERVER_SESSION_NOT_RECONCILED'
}
try{
 [void](Query-Client $master 'SELECT @@VERSION;');[void](Query-Client $master 'SELECT name,state_desc FROM sys.databases ORDER BY database_id;')
 $id=Query-Client $master "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) AS V,CONVERT(nvarchar(32),SERVERPROPERTY('ProductUpdateLevel')) AS P,IS_SRVROLEMEMBER('sysadmin') AS A,(SELECT host_platform FROM sys.dm_os_host_info) AS O;"
 if($id.Rows[0].V-ne 17 -or $id.Rows[0].P-ine 'CU8' -or $id.Rows[0].A-ne 1 -or $id.Rows[0].O-cne 'Windows'){throw 'SSIS_TRANSPORT_ACTUAL_TARGET_IDENTITY'}
 if($Mode-ceq 'Audit'){
  if(-not $ExpectedJournalSha256 -or (Get-ClientHash $JournalPath)-cne $ExpectedJournalSha256){throw 'SSIS_TRANSPORT_AUDIT_JOURNAL_CHANGED'}
  $j=Get-Content $JournalPath -Raw|ConvertFrom-Json -DateKind String
  if($j.planSha256-cne $ExpectedPlanSha256 -or $j.state-cnotin @('PASS_CLEANED','FAILED_CLEANED')){throw 'SSIS_TRANSPORT_AUDIT_BINDING'}
  if((Database-State $j.database) -or -not (Same-Client (Get-ClientConfiguration $master) $j.beforeConfig) -or -not (Same-Client (Get-RecoveryTrust $master) $j.beforeTrust) -or -not (Same-Client (Get-RecoveryConsumers $master) $j.beforeConsumers)){throw 'SSIS_TRANSPORT_AUDIT_DRIFT'}
  Save-ClientPrivate ($JournalPath+'.audit.json') @{result='PASS';journalSha256=$ExpectedJournalSha256;databaseAbsent=$true;configurationRestored=$true;trustRestored=$true;consumersUnchanged=$true}
  'SSIS_TRANSPORT_INDEPENDENT_AUDIT_PASS';return
 }
 if(Test-Path $JournalPath){throw 'SSIS_TRANSPORT_JOURNAL_COLLISION'}
 $lock=Query-Client $master "DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.lab.clr.configuration',@LockOwner=N'Session',@LockMode=N'Exclusive',@LockTimeout=0;SELECT @r AS R;"
 if($lock.Rows[0].R-lt 0){throw 'SSIS_TRANSPORT_LEASE_BUSY'};$lease=$true
 $before=Get-ClientConfiguration $master
 if(@($before|Where-Object {$_.C-ne $_.R -and -not (Test-ClientImplicit $_)}).Count){throw 'SSIS_TRANSPORT_FOREIGN_PENDING_CONFIGURATION'}
 $db='ContosoSsisRecovery_'+[guid]::NewGuid().ToString('N');$token=[guid]::NewGuid().ToString('N')
 $journal=[ordered]@{contract='ssis-sql-hard-transport-run/1';planSha256=$ExpectedPlanSha256;state='BEFORE_EFFECTS';database=$db;token=$token;databaseState=$null;beforeConfig=$before;beforeTrust=(Get-RecoveryTrust $master);beforeConsumers=(Get-RecoveryConsumers $master);ownedTrust=@();checks=[Collections.Generic.List[string]]::new();cases=@()}
 Save;Check (-not (Database-State $db)) 'OWN_DATABASE_ABSENT'
 $prepare=[IO.File]::ReadAllText((Join-Path $repoRoot ($prefix+'Examples/Installation/PrepareServer.sql')))
 if(($prepare.Split("N'ContosoSsisDebug'").Count-1)-ne 1){throw 'SSIS_TRANSPORT_PREPARATION_ANCHOR'}
 $databaseBudget=Get-Content $BudgetPath -Raw|ConvertFrom-Json -DateKind String
 if($databaseBudget.ownedDatabasesReserved-ge $databaseBudget.maximumOwnedDatabases){throw 'SSIS_TRANSPORT_DATABASE_BUDGET'}
 $databaseBudget.ownedDatabasesReserved++;Save-ClientPrivate $BudgetPath $databaseBudget
 Exec-Client $master ($prepare.Replace("N'ContosoSsisDebug'","N'"+$db+"'"))
 $journal.databaseState=Database-State $db;Save
 $databaseBudget=Get-Content $BudgetPath -Raw|ConvertFrom-Json -DateKind String
 $databaseBudget.ownedDatabasesCreated++;Save-ClientPrivate $BudgetPath $databaseBudget
 Exec-Client $master ('EXEC ['+$db+"].sys.sp_addextendedproperty @name=N'ToolbeltSsisRecoveryOwner',@value=N'"+$token+"';")
 $hashes=@((Get-FileHash (Join-Path $plan.ssis 'Toolbelt.Tsql.SsisDebug.dll') -Algorithm SHA512).Hash,
  (Get-FileHash (Join-Path $plan.parser 'Toolbelt.Tsql.ScriptParser.dll') -Algorithm SHA512).Hash,
  (Get-FileHash (Join-Path $plan.parser 'Microsoft.SqlServer.TransactSql.ScriptDom.dll') -Algorithm SHA512).Hash)
 $description='Toolbelt SSIS recovery '+$token
 foreach($hash in $hashes){
  $exists=Query-Client $master ('SELECT COUNT_BIG(*) AS N FROM sys.trusted_assemblies WHERE hash=0x'+$hash+';')
  if($exists.Rows[0].N-eq 0){
   $consumers=Get-RecoveryConsumers $master $hash
   if($consumers.Count){throw 'SSIS_TRANSPORT_UNTRUSTED_EXISTING_CONSUMER'}
   $journal.ownedTrust+=@{hash=$hash;description=$description};Save
   Exec-Client $master ("EXEC sys.sp_add_trusted_assembly @hash=0x"+$hash+",@description=N'"+$description+"';")
  }
 }
 $connection=Open-ClientSql $target $db
 Set-Alias -Name Query -Value Query-Client;Set-Alias -Name NonQuery -Value Exec-Client
 $PackageSqlcmdPath=$null;Import-RecoveryDefinitions
 Batches $connection (Expand (Join-Path $repoRoot 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')) 'local'
 Batches $connection ([IO.File]::ReadAllText((Join-Path $plan.parser 'Deploy.WithAssembly.sql'))) 'local'
 Batches $connection ([IO.File]::ReadAllText((Join-Path $plan.ssis 'Deploy.WithAssembly.sql'))) 'local'
 Check ((Query-Client $connection "SELECT COUNT(*) AS N FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow');").Rows[0].N-eq 38) 'CURRENT_INSTALLED_API'
 Exec-Client $connection @'
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);
CREATE TABLE dbo.SyntheticRecoveryMarker(Marker int NOT NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES(1,10,7),(1,10,9),(1,20,NULL),(2,10,2);
INSERT dbo.SyntheticRecoveryMarker VALUES(0);
'@
 $bytes=Get-RecoveryPackage
 $catalog=@{schemaVersion=2;defaultDatabase=$db;databases=@($db);connections=@{'Package.ConnectionManagers[Synthetic]'=$db};flatFileInputs=@{}}|ConvertTo-Json -Depth 8 -Compress
 $template=Invoke-RecoveryExplain $connection $bytes 'bindings-template' $null $null
 $bindings=[string]$template.Rows[0].Content
 $artifacts=Invoke-RecoveryExplain $connection $bytes 'explain' $bindings $catalog
 $scripts=@($artifacts.Rows|Where-Object {$_.ArtifactKind-ceq 'DebugScript' -and $_.ComponentId-ceq 'Package\Flow\DestinationHigh' -and $_.IsComplete -and $_.IsExecutable -and $_.SafetyStatus-ceq 'passed'})
 Check ($scripts.Count-eq 1) 'ACTUAL_COMPLETE_DEBUGSCRIPT'
 $sql=[string]$scripts[0].Content;$scriptPath=$JournalPath+'.debug.sql'
 [IO.File]::WriteAllText($scriptPath,$sql,[Text.UTF8Encoding]::new($false));$journal.debugSha256=Get-ClientHash $scriptPath;Save
 $baseline=Invoke-RecoveryDebug $connection $sql
 Check ($baseline.Count-eq 1 -and $baseline[0].count-eq 2) 'FIXED_SYNTHETIC_TARGET_ORACLE'
 $blocker=Open-ClientSql $target $db
 # Der öffentliche Debugpfad liest Quellen bewusst mit NOLOCK. Eine reine
 # Datensperre wäre deshalb kein beobachteter Unterbrechungspunkt. Die eigene
 # uncommittete, wertgleiche Tabellenoption hält stattdessen Sch-M; nachher
 # wird ausschließlich diese eigene Transaktion zurückgerollt.
 Exec-Client $blocker 'BEGIN TRAN;ALTER TABLE dbo.SyntheticSourceA SET(LOCK_ESCALATION=TABLE);'
 $blockerId=(Query-Client $blocker 'SELECT @@SPID AS S;').Rows[0].S
 $schemaLock=Query-Client $blocker "SELECT COUNT_BIG(*) AS N FROM sys.dm_tran_locks WHERE request_session_id=@@SPID AND request_mode=N'Sch-M' AND request_status=N'GRANT';"
 Check ($schemaLock.Rows[0].N-gt 0) 'ACTUAL_OWN_SCHEMA_MODIFICATION_LOCK'
 $child=Start-OwnClient $scriptPath ('ContosoSsisBlocked'+$token)
 $clock=[Diagnostics.Stopwatch]::StartNew();$observed=$false
 while($clock.Elapsed.TotalSeconds-lt 25){
  if($child.process.HasExited){throw 'SSIS_TRANSPORT_DEBUG_CLIENT_EXITED_BEFORE_BLOCK'}
  $sessions=Own-Sessions $child
  if($sessions.Rows.Count-eq 1 -and $sessions.Rows[0].blocking_session_id-eq $blockerId){$observed=$true;break}
  Start-Sleep -Milliseconds 200
 }
 Check $observed 'ACTUAL_DEBUGSCRIPT_BLOCKED_ON_OWN_SOURCE'
 End-OwnClient $child;Exec-Client $blocker 'ROLLBACK;';$blocker.Dispose();$blocker=$null
 Wait-NoClient $child;$child.process.Dispose();$child=$null
 $fresh=Open-ClientSql $target $db
 try{$recovered=Invoke-RecoveryDebug $fresh $sql;Check (Same-Client $recovered $baseline) 'FRESH_DEBUGSCRIPT_RESULTS_IDENTICAL'}finally{$fresh.Dispose()}
 Check ((Get-ClientHash $scriptPath)-ceq $journal.debugSha256) 'DEBUGSCRIPT_BYTES_UNCHANGED'
 $journal.cases+=@{name='blocked-current-debugscript';result='PASS';processKilled=$true;serverSessionGone=$true;freshResultsIdentical=$true};Save
 $transactionSql="SET NOCOUNT ON;BEGIN TRAN;UPDATE dbo.SyntheticSourceA SET Amount=Amount+1000 WHERE KeyA=1;CREATE TABLE #RecoveryArtifacts(Dummy bit NULL);EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=0x"+[Convert]::ToHexString($bytes)+",@Operation=N'bindings-template',@ResultTable=N'#RecoveryArtifacts';IF NOT EXISTS(SELECT 1 FROM #RecoveryArtifacts WHERE ArtifactKind=N'BindingsTemplate') THROW 51000,N'SYNTHETIC_API_NOT_COMPLETED',1;UPDATE dbo.SyntheticRecoveryMarker SET Marker=1;WAITFOR DELAY '00:00:25';COMMIT;"
 $path=$JournalPath+'.transaction.sql';[IO.File]::WriteAllText($path,$transactionSql,[Text.UTF8Encoding]::new($false))
 $child=Start-OwnClient $path ('ContosoSsisTransaction'+$token)
 $clock.Restart();$observed=$false
 while($clock.Elapsed.TotalSeconds-lt 20){
  if($child.process.HasExited){throw 'SSIS_TRANSPORT_TRANSACTION_CLIENT_EXITED_EARLY'}
  $sessions=Own-Sessions $child
  $marker=Query-Client $connection 'SELECT Marker FROM dbo.SyntheticRecoveryMarker WITH(NOLOCK);'
  if($sessions.Rows.Count-eq 1 -and $sessions.Rows[0].open_transaction_count-gt 0 -and $marker.Rows[0].Marker-eq 1){$observed=$true;break}
  Start-Sleep -Milliseconds 200
 }
 Check $observed 'ACTUAL_API_COMPLETED_WITH_OPEN_CALLER_TRANSACTION'
 End-OwnClient $child;Wait-NoClient $child;$child.process.Dispose();$child=$null
 $fresh=Open-ClientSql $target $db
 try{
  Check ((Query-Client $fresh 'SELECT Marker FROM dbo.SyntheticRecoveryMarker;').Rows[0].Marker-eq 0) 'CALLER_MARKER_ROLLED_BACK'
  Check ((Query-Client $fresh 'SELECT SUM(Amount) AS A FROM dbo.SyntheticSourceA;').Rows[0].A-eq 320) 'CALLER_SOURCE_UPDATE_ROLLED_BACK'
  Check (Same-Client (Invoke-RecoveryDebug $fresh $sql) $baseline) 'POST_TRANSACTION_FRESH_DEBUGSCRIPT_IDENTICAL'
 }finally{$fresh.Dispose()}
 $journal.cases+=@{name='current-api-open-caller-transaction';result='PASS';processKilled=$true;serverSessionGone=$true;callerChangesRolledBack=$true;freshResultsIdentical=$true};$journal.state='QUALIFICATION_COMPLETE';Save
}catch{
 $failure=$_.Exception
 if($journal){
  $journal.failure=$failure.GetType().Name
  $journal.failureCode=if($failure.Message-match '((?:SSIS|LAB)_[A-Z0-9_]+)'){$Matches[1]}else{'UNCLASSIFIED'}
  $detail=$failure.Message
  foreach($secret in @($builder.ConnectionString,[string]$target.password,[string]$target.username,[string]$target.host)){if($secret){$detail=$detail.Replace($secret,'<redacted>')}}
  $journal.failureMessage=$detail.Substring(0,[Math]::Min(2000,$detail.Length));$journal.failureStack=$_.ScriptStackTrace
  $journal.state='FAILED_REQUIRES_CLEANUP';Save
 }
}finally{
 if($child){
  try{
   if(-not $child.process.HasExited){$child.process.Kill();$child.process.WaitForExit(10000)|Out-Null}
   foreach($name in @('output','error')){
    $path=$JournalPath+'.'+$child.marker+'.'+$name+'.txt'
    if(-not (Test-Path $path) -and $child[$name].Wait(5000)){[IO.File]::WriteAllText($path,$child[$name].Result,[Text.UTF8Encoding]::new($false))}
   }
   $child.process.Dispose()
  }catch{}
 }
 if($blocker){try{Exec-Client $blocker 'IF @@TRANCOUNT>0 ROLLBACK;'}finally{$blocker.Dispose()}}
 if($connection){$connection.Dispose()}
 if($journal){
  try{
   $current=Database-State $journal.database
   if($current){
    if(-not (Same-Client $current $journal.databaseState)){throw 'SSIS_TRANSPORT_DATABASE_IDENTITY_DRIFT'}
    $marker=Query-Client $master ('SELECT CONVERT(nvarchar(128),value) AS V FROM ['+$journal.database+"].sys.extended_properties WHERE class=0 AND name=N'ToolbeltSsisRecoveryOwner';")
    if($marker.Rows.Count-ne 1 -or $marker.Rows[0].V-cne $journal.token){throw 'SSIS_TRANSPORT_DATABASE_OWNER_DRIFT'}
    Exec-Client $master ('DROP DATABASE ['+$journal.database+'];')
   }
   foreach($entry in $journal.ownedTrust){
    $users=Get-RecoveryConsumers $master $entry.hash
    if($users.Count){throw 'SSIS_TRANSPORT_TRUST_CONSUMER_REMAINS'}
    $r=Query-Client $master ('SELECT description FROM sys.trusted_assemblies WHERE hash=0x'+$entry.hash+';')
    if($r.Rows.Count-eq 0){continue}
    if($r.Rows.Count-ne 1 -or $r.Rows[0].description-cne $entry.description){throw 'SSIS_TRANSPORT_TRUST_OWNER_DRIFT'}
    Exec-Client $master ('EXEC sys.sp_drop_trusted_assembly @hash=0x'+$entry.hash+';')
   }
   Check (Same-Client (Get-RecoveryConsumers $master) $journal.beforeConsumers) 'OTHER_ASSEMBLY_CONSUMERS_UNCHANGED'
   $currentConfig=Get-ClientConfiguration $master
   foreach($row in $currentConfig){$old=@($journal.beforeConfig|Where-Object name -CEQ $row.name)[0];if($row.name-cne 'clr enabled' -and -not (Same-Client $row $old)){throw 'SSIS_TRANSPORT_FOREIGN_CONFIGURATION_DRIFT'}}
   $old=@($journal.beforeConfig|Where-Object name -CEQ 'clr enabled')[0]
   $actual=@($currentConfig|Where-Object name -CEQ 'clr enabled')[0]
   if($actual.C-ne $actual.R){throw 'SSIS_TRANSPORT_PENDING_CLR_DRIFT'}
   if($actual.C-ne $old.C -or $actual.R-ne $old.R){Exec-Client $master ("EXEC sys.sp_configure N'clr enabled',"+$old.C+';RECONFIGURE;')}
   Check (-not (Database-State $journal.database)) 'OWN_DATABASE_REMOVED'
   Check (Same-Client (Get-ClientConfiguration $master) $journal.beforeConfig) 'EXACT_CONFIGURATION_RESTORED'
   Check (Same-Client (Get-RecoveryTrust $master) $journal.beforeTrust) 'EXACT_TRUST_RESTORED'
   $journal.state=if($failure){'FAILED_CLEANED'}else{'PASS_CLEANED'}
  }catch{$journal.state='RECOVERY_REQUIRED';$journal.cleanupFailure=$_.Exception.GetType().Name;if(-not $failure){$failure=$_.Exception}}
  Save
 }
 if($lease){try{Exec-Client $master "EXEC sys.sp_releaseapplock @Resource=N'toolbelt.lab.clr.configuration',@LockOwner=N'Session';"}catch{}}
 $builder.Clear();$master.Dispose()
}
if($failure){throw 'SSIS_TRANSPORT_FAILED_PRIVATE_JOURNAL'}
if(-not $journal -or $journal.state-cne 'PASS_CLEANED' -or $journal.cases.Count-ne 2){throw 'SSIS_TRANSPORT_INCOMPLETE'}
'SSIS_SQL_HARD_TRANSPORT_PASS cases=2 assertions='+$journal.checks.Count+'; own clients terminated and all state restored'
