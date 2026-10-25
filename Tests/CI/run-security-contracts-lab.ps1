[CmdletBinding()]
param([ValidateSet('linux','windows')][string]$Platform='linux',
      [ValidateSet('2019','2022','2025')][string]$Version='2019',[string]$Patch='latest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Auch isoliert extrahierte Labfunktionen benötigen den gemeinsamen Reader.
. (Join-Path $PSScriptRoot 'LabQualifiedContract.ps1')

$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'run-lab-local.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'SECURITY_QUEUE_DISCOVERY_PARSE'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $definitions=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
 if($definitions.Count-ne1){throw 'SECURITY_QUEUE_DISCOVERY'}
 . ([scriptblock]::Create($definitions[0].Extent.Text))
}
function Read-Source([string]$Path,[string]$AssemblyBits=''){
 $full=[IO.Path]::GetFullPath($Path)
 if(-not$full.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SECURITY_QUEUE_SOURCE_SCOPE'}
 $text=Get-Content -LiteralPath $full -Raw
 $text=[regex]::Replace($text,'(?im)^:r\s+([^\r\n]+)\r?$',{param($m)Read-Source (Join-Path (Split-Path -Parent $full) $m.Groups[1].Value.Trim()) $AssemblyBits})
 $text=[regex]::Replace($text,'(?im)^:on error exit\s*$','')
 $text=$text.Replace('$(DeploymentMode)','local')
 if($AssemblyBits){$text=$text.Replace('$(AssemblyBits)',$AssemblyBits)}
 if($text-match '(?m)^:'-or$text-match '\$\('){throw 'SECURITY_QUEUE_SQLCMD_UNRESOLVED'}
 return $text
}
function Execute([Data.SqlClient.SqlConnection]$Connection,[string]$Sql,[switch]$Scalar){
 $command=$Connection.CreateCommand();$command.CommandText=$Sql;$command.CommandTimeout=30
 try{if($Scalar){return $command.ExecuteScalar()};[void]$command.ExecuteNonQuery()}finally{$command.Dispose()}
}
function Batches([string]$Sql){return @([regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?\r?$')|Where-Object{-not[string]::IsNullOrWhiteSpace($_)})}
function Run-Source([Data.SqlClient.SqlConnection]$Connection,[string]$Path){foreach($batch in (Batches (Read-Source $Path))){Execute $Connection $batch}}
$lab=Resolve-LabContract
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if($targets.Count-ne1){throw 'SECURITY_QUEUE_EXACT_SINGLE_TARGET'}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $targets[0]))
$builder['Initial Catalog']='master';$builder['Pooling']=$false
$master=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$worker=$null;$migration=$null;$created=$false;$pending=$null;$command=$null
$database='TBX_SecurityQueue_'+[guid]::NewGuid().ToString('N')
try{
 $master.Open();Execute $master ('CREATE DATABASE ['+$database+'] COLLATE Latin1_General_100_CS_AS;');$created=$true
 $builder['Initial Catalog']=$database
 $worker=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$worker.Open()
 $migration=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$migration.Open()
 Run-Source $worker (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')
 Run-Source $worker (Join-Path $repo 'Modules/toolbelt.core.work-type/Deployment/Deploy.sql')
 Run-Source $worker (Join-Path $repo 'Modules/toolbelt.core.work-queue/Tests/Runtime/UpgradeFrom1_0.Setup.sql')
 $deploy=Read-Source (Join-Path $repo 'Modules/toolbelt.core.work-queue/Deployment/Deploy.sql')
 $gate="DECLARE @SecurityGate int; EXEC @SecurityGate=sys.sp_getapplock @Resource=N'toolbelt.security.queue.test',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=20000; IF @SecurityGate<0 THROW 52998,N'Testgate nicht erreicht.',1;"
 $anchors=@('-- Legacyclaims unter einer bis COMMIT gehaltenen Tabellensperre prüfen.','IF @RepeatControl=0 AND (EXISTS')
 foreach($case in 0,1){
  Execute $worker "EXEC sys.sp_getapplock @Resource=N'toolbelt.security.queue.test',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0;"
  $anchor=$anchors[$case]
  if(([regex]::Matches($deploy,[regex]::Escape($anchor))).Count-ne1){throw 'SECURITY_QUEUE_HOOK_NOT_UNIQUE'}
  # Only test copies receive synchronization hooks. Product deployment is unchanged.
  $batches=Batches ($deploy.Replace($anchor,$gate+[Environment]::NewLine+$anchor))
  $index=-1
  for($i=0;$i-lt$batches.Count;$i++){if($batches[$i].Contains('DECLARE @SecurityGate')){$index=$i;break};Execute $migration $batches[$i]}
  if($index-lt0){throw 'SECURITY_QUEUE_HOOK_MISSING'}
  $spid=[int](Execute $migration 'SELECT @@SPID;' -Scalar)
  $command=$migration.CreateCommand();$command.CommandText=$batches[$index];$command.CommandTimeout=30
  $pending=$command.ExecuteNonQueryAsync()
  $blocked=$false
  for($attempt=0;$attempt-lt100;$attempt++){
   if([int](Execute $worker ("SELECT COUNT(*) FROM sys.dm_exec_requests WHERE session_id=$spid AND blocking_session_id=@@SPID;") -Scalar)-eq1){$blocked=$true;break}
   if($pending.IsCompleted){break};Start-Sleep -Milliseconds 50
  }
  if(-not$blocked){throw 'SECURITY_QUEUE_SYNC_NOT_OBSERVED'}
  if($case-eq0){
   Execute $worker "UPDATE toolbelt_core.WorkItem SET Status='CLAIMED',ClaimedAtUtc=SYSUTCDATETIME(),ClaimedBy=N'synthetic-worker',ClaimToken='00000000-0000-0000-0000-000000000222' WHERE Status='QUEUED';"
  }else{
   $rejected=$false
   try{Execute $worker "SET LOCK_TIMEOUT 500; UPDATE toolbelt_core.WorkItem SET Status='CLAIMED',ClaimedAtUtc=SYSUTCDATETIME(),ClaimedBy=N'synthetic-worker',ClaimToken='00000000-0000-0000-0000-000000000222' WHERE Status='QUEUED';"}
   catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($failure -isnot [Data.SqlClient.SqlException]-or$failure.Number-ne1222){throw};$rejected=$true}
   finally{Execute $worker 'SET LOCK_TIMEOUT -1;'}
   if(-not$rejected){throw 'SECURITY_QUEUE_LOCK_NOT_HELD'}
  }
  Execute $worker "EXEC sys.sp_releaseapplock @Resource=N'toolbelt.security.queue.test',@LockOwner=N'Session';"
  $rejected=$false
  try{$null=$pending.GetAwaiter().GetResult()}
  catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($case-ne0-or$failure -isnot [Data.SqlClient.SqlException]-or$failure.Number-ne51948-or$failure.State-ne4){throw};$rejected=$true}
  finally{$pending=$null;$command.Dispose();$command=$null}
  if($case-eq0){
   if(-not$rejected-or[int](Execute $worker "SELECT CASE WHEN COL_LENGTH(N'toolbelt_core.WorkItem',N'ClaimGeneration') IS NULL AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0') AND EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED') THEN 1 ELSE 0 END;" -Scalar)-ne1){throw 'SECURITY_QUEUE_REJECTION_MUTATED_SCOPE'}
   Execute $worker "UPDATE toolbelt_core.WorkItem SET Status='QUEUED',ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL WHERE Status='CLAIMED';"
  }else{
   for($i=$index+1;$i-lt$batches.Count;$i++){Execute $migration $batches[$i]}
   Run-Source $worker (Join-Path $repo 'Modules/toolbelt.core.work-queue/Tests/Runtime/UpgradeFrom1_0.Verify.sql')
  }
 }
 # Prove the strengthened barrier assertion catches each premature-claim shape.
 $contract=Get-Content -LiteralPath (Join-Path $repo 'Modules/toolbelt.core.work-queue/Tests/Runtime/WorkQueue.Contract.sql') -Raw
 $match=[regex]::Match($contract,"(?s)IF NOT EXISTS\(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@BarrierId AND Status='BARRIER_WAIT'\).*?THROW 52958,.*?2;")
 if(-not$match.Success){throw 'SECURITY_QUEUE_BARRIER_ASSERTION_MISSING'}
 $assertion=$match.Value.Replace('toolbelt_core.WorkItem','#SyntheticBarrier')
 foreach($case in 0,1){
  $status=if($case-eq0){'CLAIMED'}else{'BARRIER_WAIT'}
  $claim=if($case-eq1){'INSERT #Claim VALUES(1);'}else{''}
  $rejected=$false
  try{Execute $worker ("CREATE TABLE #SyntheticBarrier(WorkItemId bigint,Status varchar(16));CREATE TABLE #Claim(WorkItemId bigint);INSERT #SyntheticBarrier VALUES(1,'$status');$claim DECLARE @BarrierId bigint=1;"+$assertion)}
  catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($failure -isnot [Data.SqlClient.SqlException]-or$failure.Number-ne52958-or$failure.State-ne2){throw};$rejected=$true}
  finally{Execute $worker 'DROP TABLE IF EXISTS #Claim;DROP TABLE IF EXISTS #SyntheticBarrier;'}
  if(-not$rejected){throw 'SECURITY_QUEUE_BARRIER_INJECTION_ACCEPTED'}
 }
 Run-Source $worker (Join-Path $repo 'Modules/toolbelt.core.error-envelope/Source/USP_CaptureErrorEnvelope.sql')
 & (Join-Path $repo 'Modules/toolbelt.core.error-envelope/Tests/Runtime/Envelope.Metadata.ps1') -Connection $worker
 if(-not$?){throw 'SECURITY_ENVELOPE_METADATA'}
 'SECURITY_QUEUE_RACE_AND_BARRIER_PASS'
}catch{
 $failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException}
 if($failure -is [Data.SqlClient.SqlException]){throw ('SECURITY_QUEUE_SQL_FAILED_'+$failure.Number+'_LINE_'+$failure.LineNumber)}
 if($failure.Message-cmatch'^[A-Z0-9_]+$'){throw $failure.Message}
 throw 'SECURITY_QUEUE_FAILED_PRIVATE_DETAILS_SUPPRESSED'
}finally{
 if($worker-and$worker.State-eq'Open'){try{Execute $worker "EXEC sys.sp_releaseapplock @Resource=N'toolbelt.security.queue.test',@LockOwner=N'Session';"}catch{}}
 if($pending-and-not$pending.IsCompleted-and$command){$command.Cancel();try{$null=$pending.GetAwaiter().GetResult()}catch{}}
 if($command){$command.Dispose()}
 if($migration){$migration.Dispose()};if($worker){$worker.Dispose()}
 if($created){Execute $master ('ALTER DATABASE ['+$database+'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE ['+$database+'];');if([int](Execute $master ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)-ne0){throw 'SECURITY_QUEUE_CLEANUP_UNVERIFIED'}}
 $master.Dispose()
}
