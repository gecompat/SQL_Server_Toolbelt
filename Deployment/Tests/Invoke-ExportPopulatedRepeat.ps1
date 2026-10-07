# Fokussierte Qualifikation im bereits autorisierten CI-Ziel; kein Targetstart,
# Provideraufruf, Grant oder Konfigurations-/Trusteingriff. Reale Daten bleiben privat.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')][string]$ConnectionStringEnvironmentVariable)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repositoryRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtimeRoot=Join-Path $PSScriptRoot 'Runtime'
$temporaryParent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$ownedRoot=Join-Path $temporaryParent ('toolbelt-export-repeat-'+[guid]::NewGuid().ToString('N'))
$run=[guid]::NewGuid();$marker='Toolbelt.ExportPopulatedFixture.Run'
$phase='preflight';$failure=$null;$cleanupFailed=$false
$identities=[Collections.Generic.List[object]]::new()
$ownedFiles=[Collections.Generic.List[object]]::new()
$journalPath=Join-Path $ownedRoot 'Ownership.json';$journalHash=$null
$utf8=[Text.UTF8Encoding]::new($false,$true)
$expectedModules=@('toolbelt.core.execution-context','toolbelt.core.result-table','toolbelt.file.content','toolbelt.core.execution-cancel','toolbelt.core.work-type','toolbelt.core.second-session','toolbelt.core.work-queue','toolbelt.core.event-log','toolbelt.core.worker-control')
$selectedModules=@('toolbelt.core.worker-control','toolbelt.core.event-log','toolbelt.file.content','toolbelt.core.execution-cancel')
$sourceConnection=[Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable,'Process')

function Assert-ExportRepeat([bool]$Condition,[string]$Code){if(-not$Condition){throw ('EXPORT_REPEAT.'+$Code)}}
function Save-PrivateOwnership {
 $record=[ordered]@{Run=$run;Marker=$marker;Phase=$phase;Databases=$identities.ToArray();Failure=$failure;CleanupFailed=$cleanupFailed}
 $bytes=$utf8.GetBytes((ConvertTo-Json -InputObject $record -Depth 5 -Compress))
 $stream=[IO.File]::Open($journalPath,$(if($null-eq$journalHash){[IO.FileMode]::CreateNew}else{[IO.FileMode]::Open}),[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try{
  if($null-ne$journalHash){
   Assert-ExportRepeat ($stream.Length-le65536) 'JOURNAL_SIZE'
   $old=[byte[]]::new([int]$stream.Length);$read=0
   while($read-lt$old.Length){$n=$stream.Read($old,$read,$old.Length-$read);Assert-ExportRepeat ($n-gt0) 'JOURNAL_READ';$read+=$n}
   Assert-ExportRepeat ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($old))-ceq$journalHash) 'JOURNAL_DRIFT'
  }
  $stream.Position=0;$stream.SetLength(0);$stream.Write($bytes,0,$bytes.Length);$stream.Flush()
  $script:journalHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
 }finally{$stream.Dispose()}
}
function New-ExportConnection([string]$Database){
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($sourceConnection)
 $builder.InitialCatalog=$Database;$builder.Pooling=$false;$builder.Enlist=$false;$builder.ConnectRetryCount=0;$builder.ConnectTimeout=5
 $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
 try{$connection.Open();return $connection}catch{$connection.Dispose();throw}finally{$builder=$null}
}
function Invoke-ExportSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Scalar){
 $command=$Connection.CreateCommand();$command.CommandTimeout=15;$command.CommandText=$Sql
 try{
  foreach($key in $Parameters.Keys){
   if($Parameters[$key]-is[DateTime]){
    $parameter=$command.Parameters.Add($key,[Data.SqlDbType]::DateTime2);$parameter.Scale=7;$parameter.Value=$Parameters[$key]
   }else{[void]$command.Parameters.AddWithValue($key,$Parameters[$key])}
  }
  if($Scalar){return ,$command.ExecuteScalar()}
  [void]$command.ExecuteNonQuery()
 }finally{$command.Dispose()}
}
function Get-IdentityParameters($Identity){
 return @{'@Id'=$Identity.Id;'@Name'=$Identity.Name;'@Created'=[Convert]::FromHexString($Identity.CreatedBytes);'@Owner'=[Convert]::FromHexString($Identity.OwnerBytes);'@Marker'=$marker;'@Run'=$run}
}
function Assert-OwnedConnection($Connection,$Identity){
 Assert-ExportRepeat ($Identity.MarkerConfirmed-and-not$Identity.Dropped) 'OWNERSHIP_UNCONFIRMED'
 Invoke-ExportSql $Connection 'IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 OR (@@OPTIONS&2)<>0 OR @@LOCK_TIMEOUT<>-1 OR DB_ID()<>@Id OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Name AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created AND owner_sid=@Owner AND owner_sid=SUSER_SID()) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND SQL_VARIANT_PROPERTY(value,''BaseType'')=''uniqueidentifier'' AND TRY_CONVERT(uniqueidentifier,value)=@Run) THROW 54984,N''Eigene Exportfixtureidentität oder neutrale Session fehlt.'',1;' (Get-IdentityParameters $Identity)
}
function Get-ExportBatches([string]$Text){
 Assert-ExportRepeat (-not$Text.Contains('$(')) 'UNRESOLVED_VARIABLE'
 $lines=[Collections.Generic.List[string]]::new();$abortCount=0
 foreach($line in [regex]::Split($Text,'\r?\n')){
  if($line-match'^\s*[:!]'){
   Assert-ExportRepeat ($line-match'^\s*:ON\s+ERROR\s+EXIT\s*$') 'UNSUPPORTED_DIRECTIVE'
   $abortCount++;continue
  }
  $lines.Add($line)
 }
 Assert-ExportRepeat ($abortCount-ge1) 'ERROR_ABORT_MISSING'
 # Nur unveränderte GO-Grenzen konsumieren, keine Includeauflösung/Variablenersetzung hier.
 return @([regex]::Split(($lines-join "`n"),'(?im)^\s*GO\s*$')|Where-Object {-not[string]::IsNullOrWhiteSpace($_)})
}
function Invoke-ExportFile($Identity,$Export){
 $actual=[IO.File]::ReadAllBytes($Export.Path)
 Assert-ExportRepeat ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($actual))-ceq$Export.Hash) 'EXPORT_BYTES_CHANGED'
 $batches=@(Get-ExportBatches ($utf8.GetString($actual)))
 Assert-ExportRepeat ($batches.Count-eq$Export.BatchCount) 'EXPORT_BATCH_COUNT_CHANGED'
 $connection=New-ExportConnection $Identity.Name
 try{
  Assert-OwnedConnection $connection $Identity
  $started=Invoke-ExportSql $connection 'SELECT SYSUTCDATETIME();' -Scalar
  $consumed=0
  foreach($batch in $batches){Invoke-ExportSql $connection $batch;$consumed++}
  Assert-ExportRepeat ($consumed-eq$Export.BatchCount) 'EXPORT_NOT_FULLY_CONSUMED'
  Assert-OwnedConnection $connection $Identity
  return $started
 }finally{$connection.Dispose()}
}
function Invoke-OwnedFixture($Identity,[string]$Name,[hashtable]$Parameters=@{}){
 $connection=New-ExportConnection $Identity.Name
 try{Assert-OwnedConnection $connection $Identity;Invoke-ExportSql $connection ([IO.File]::ReadAllText((Join-Path $runtimeRoot $Name),$utf8)) $Parameters;Assert-OwnedConnection $connection $Identity}
 finally{$connection.Dispose()}
}
function Read-PrivateSnapshot($Identity){
 $connection=New-ExportConnection $Identity.Name
 try{
  Assert-OwnedConnection $connection $Identity
  $command=$connection.CreateCommand();$command.CommandTimeout=15;$command.CommandText=[IO.File]::ReadAllText((Join-Path $runtimeRoot 'ExportPopulated.Capture.sql'),$utf8)
  try{
   $reader=$command.ExecuteReader();$snapshot=[Collections.Generic.Dictionary[string,Collections.Generic.List[string]]]::new([StringComparer]::Ordinal)
   try{
    Assert-ExportRepeat ($reader.FieldCount-eq2-and$reader.GetName(0)-ceq'Category'-and$reader.GetName(1)-ceq'Payload') 'SNAPSHOT_SHAPE'
    while($reader.Read()){
     $category=$reader.GetString(0);$payload=[Convert]::ToHexString([byte[]]$reader.GetValue(1))
     if(-not$snapshot.ContainsKey($category)){$snapshot.Add($category,[Collections.Generic.List[string]]::new())}
     $snapshot[$category].Add($payload)
    }
    Assert-ExportRepeat (-not$reader.NextResult()) 'SNAPSHOT_EXTRA_RESULT'
   }finally{$reader.Dispose()}
   foreach($category in $snapshot.Keys){$snapshot[$category].Sort([StringComparer]::Ordinal)}
   Assert-ExportRepeat (@($snapshot.Keys|Where-Object {$_.StartsWith('row:',[StringComparison]::Ordinal)}).Count-eq14) 'SNAPSHOT_TABLES14'
   return ,$snapshot
  }finally{$command.Dispose()}
 }finally{$connection.Dispose()}
}
function Compare-PrivateSnapshots($Previous,$Current,[switch]$First){
 $skip=if($First){@('event-work-type','file-description')}else{@()}
 $previousKeys=@($Previous.Keys|Where-Object {$_-cnotin$skip}|Sort-Object)
 $currentKeys=@($Current.Keys|Where-Object {$_-cnotin$skip}|Sort-Object)
 Assert-ExportRepeat (($previousKeys-join "`n")-ceq($currentKeys-join "`n")) 'SNAPSHOT_CATEGORIES_CHANGED'
 foreach($key in $previousKeys){
  Assert-ExportRepeat ($Previous[$key].Count-eq$Current[$key].Count) 'SNAPSHOT_ROWCOUNT_CHANGED'
  for($i=0;$i-lt$Previous[$key].Count;$i++){Assert-ExportRepeat ($Previous[$key][$i]-ceq$Current[$key][$i]) 'SNAPSHOT_BYTES_CHANGED'}
 }
}
function Remove-OwnedDatabase($Identity){
 if($Identity.Dropped){return}
 Assert-ExportRepeat ($Identity.MarkerConfirmed-and$null-ne$Identity.Id) 'CLEANUP_UNCONFIRMED'
 Assert-ExportRepeat ($Identity.Name-match'^Toolbelt_ExportRepeat_(local|central)_[0-9a-f]{32}$') 'CLEANUP_NAME'
 $connection=New-ExportConnection 'master'
 try{
  # Eine frische Sicht bindet ID, Erzeugungszeit, Owner und Marker; keine fremden Sessions beenden.
  $sql='IF ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Name AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created AND owner_sid=@Owner AND owner_sid=SUSER_SID()) OR NOT EXISTS(SELECT 1 FROM ['+$Identity.Name+'].sys.extended_properties WHERE class=0 AND name=@Marker AND SQL_VARIANT_PROPERTY(value,''BaseType'')=''uniqueidentifier'' AND TRY_CONVERT(uniqueidentifier,value)=@Run) OR EXISTS(SELECT 1 FROM sys.dm_exec_sessions WHERE database_id=@Id AND session_id<>@@SPID) OR EXISTS(SELECT 1 FROM sys.dm_exec_requests WHERE database_id=@Id AND session_id<>@@SPID) THROW 54985,N''Own-Cleanup-Identität oder Verbrauchergrenze fehlt.'',1; DROP DATABASE ['+$Identity.Name+']; IF DB_ID(@Name) IS NOT NULL THROW 54985,N''Eigene Datenbank bleibt vorhanden.'',2;'
  Invoke-ExportSql $connection $sql (Get-IdentityParameters $Identity)
  $Identity.Dropped=$true;Save-PrivateOwnership
 }finally{$connection.Dispose()}
}

try{
 Assert-ExportRepeat (-not[string]::IsNullOrWhiteSpace($sourceConnection)) 'CONNECTION_INPUT_MISSING'
 [void][IO.Directory]::CreateDirectory($ownedRoot);Save-PrivateOwnership
 $connection=New-ExportConnection 'master'
 try{
  Invoke-ExportSql $connection 'IF CONVERT(int,SERVERPROPERTY(N''ProductMajorVersion''))<>15 OR ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 OR NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N''Linux'') THROW 54986,N''Der bestehende begrenzte CI-Zielvertrag fehlt.'',1;'
 }finally{$connection.Dispose()}
 foreach($mode in @('local','central')){
  $phase=$mode+'-export';Save-PrivateOwnership
  $exportPath=Join-Path $ownedRoot ($mode+'.sql')
  & (Join-Path $repositoryRoot 'Deployment/Deploy-All.ps1') -DeploymentMode $mode -ModuleId $selectedModules -OutputSqlFile $exportPath *> $null
  $bytes=[IO.File]::ReadAllBytes($exportPath);$text=$utf8.GetString($bytes)
  Assert-ExportRepeat (-not($bytes[0]-eq239-and$bytes[1]-eq187-and$bytes[2]-eq191)) 'EXPORT_BOM'
  $moduleIds=@([regex]::Matches($text,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)$')|ForEach-Object {$_.Groups[1].Value})
  Assert-ExportRepeat (($moduleIds-join ',')-ceq($expectedModules-join ',')) 'EXPORT_CLOSURE'
  Assert-ExportRepeat ([regex]::Matches($text,'(?m)^-- END MODULE ').Count-eq9) 'EXPORT_ENDS9'
  Assert-ExportRepeat ([regex]::Matches($text,'IF @@TRANCOUNT <> 0 OR \(2 & @@OPTIONS\) <> 0').Count-eq10) 'EXPORT_GUARDS10'
  $export=[pscustomobject]@{Path=$exportPath;Hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes));BatchCount=@(Get-ExportBatches $text).Count}
  $ownedFiles.Add($export)
  $identity=[pscustomobject]@{Name=('Toolbelt_ExportRepeat_'+$mode+'_'+[guid]::NewGuid().ToString('N'));Id=$null;CreatedBytes=$null;OwnerBytes=$null;MarkerConfirmed=$false;Dropped=$false}
  $identities.Add($identity);$phase=$mode+'-create';Save-PrivateOwnership
  $connection=New-ExportConnection 'master'
  try{
   $collation=if($mode-ceq'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'}
   Invoke-ExportSql $connection ('IF DB_ID(@Name) IS NOT NULL THROW 54987,N''Synthetischer DB-Name ist belegt.'',1; CREATE DATABASE ['+$identity.Name+'] COLLATE '+$collation+';') @{'@Name'=$identity.Name}
   $command=$connection.CreateCommand();$command.CommandTimeout=15;$command.CommandText='SELECT database_id,CONVERT(binary(9),CONVERT(datetime2(7),create_date)),owner_sid FROM sys.databases WHERE name=@Name AND owner_sid=SUSER_SID();';[void]$command.Parameters.AddWithValue('@Name',$identity.Name)
   try{
    $reader=$command.ExecuteReader()
    try{Assert-ExportRepeat ($reader.Read()) 'DATABASE_IDENTITY';$identity.Id=$reader.GetInt32(0);$identity.CreatedBytes=[Convert]::ToHexString([byte[]]$reader.GetValue(1));$identity.OwnerBytes=[Convert]::ToHexString([byte[]]$reader.GetValue(2));Assert-ExportRepeat (-not$reader.Read()-and-not$reader.NextResult()) 'DATABASE_IDENTITY_SHAPE'}finally{$reader.Dispose()}
   }finally{$command.Dispose()}
   Save-PrivateOwnership
  }finally{$connection.Dispose()}
  $connection=New-ExportConnection $identity.Name
  try{
   Invoke-ExportSql $connection 'EXEC sys.sp_addextendedproperty @name=@Marker,@value=@Run;' @{'@Marker'=$marker;'@Run'=$run}
   $identity.MarkerConfirmed=$true;Assert-OwnedConnection $connection $identity
   Invoke-ExportSql $connection ('ALTER DATABASE ['+$identity.Name+'] SET COMPATIBILITY_LEVEL=150;')
  }finally{$connection.Dispose()}
  $phase=$mode+'-install';Save-PrivateOwnership
  [void](Invoke-ExportFile $identity $export)
  $phase=$mode+'-seed';Save-PrivateOwnership
  Invoke-OwnedFixture $identity 'ExportPopulated.Setup.sql'
  $connection=New-ExportConnection $identity.Name
  try{Assert-OwnedConnection $connection $identity;$originalEventRv=Invoke-ExportSql $connection 'SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName=''toolbelt.event-log.write'';' -Scalar}finally{$connection.Dispose()}
  $previous=Read-PrivateSnapshot $identity
  foreach($repeat in 1..2){
   $phase=$mode+'-repeat'+$repeat;Save-PrivateOwnership
   $started=Invoke-ExportFile $identity $export
   Invoke-OwnedFixture $identity 'ExportPopulated.Assert.sql' @{'@Phase'=$repeat;'@OriginalEventRowVersion'=$originalEventRv;'@DeployStartedAtUtc'=$started}
   $current=Read-PrivateSnapshot $identity
   Compare-PrivateSnapshots $previous $current -First:($repeat-eq1)
   $previous=$current
  }
  Invoke-OwnedFixture $identity 'ExportPopulated.IdentityWitness.sql'
  $phase=$mode+'-cleanup';Save-PrivateOwnership;Remove-OwnedDatabase $identity
 }
}catch{
 $cause=$_.Exception;while($cause-and$cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
 $code='UNCLASSIFIED'
 if($_.Exception.Message-match'^EXPORT_REPEAT\.([A-Z0-9_]+)$'){$code=$Matches[1]}
 $failure=[ordered]@{Phase=$phase;Code=$code;SqlNumber=$(if($cause){$cause.Number}else{0});SqlState=$(if($cause){[int]$cause.State}else{0})}
 if([IO.Directory]::Exists($ownedRoot)){try{Save-PrivateOwnership}catch{}}
}finally{
 foreach($identity in $identities){if(-not$identity.Dropped){try{Remove-OwnedDatabase $identity}catch{$cleanupFailed=$true}}}
 if([IO.Directory]::Exists($ownedRoot)){
  if($null-ne$failure-or$cleanupFailed){try{Save-PrivateOwnership}catch{$cleanupFailed=$true}}
  else{
   try{
    foreach($file in $ownedFiles){Assert-ExportRepeat ((Get-FileHash -LiteralPath $file.Path -Algorithm SHA256).Hash-ceq$file.Hash) 'FILE_CLEANUP_DRIFT';[IO.File]::Delete($file.Path)}
    Assert-ExportRepeat ((Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash-ceq$journalHash) 'JOURNAL_CLEANUP_DRIFT';[IO.File]::Delete($journalPath)
    $resolved=[IO.Path]::GetFullPath($ownedRoot)
    Assert-ExportRepeat ([IO.Path]::GetDirectoryName($resolved)-ceq$temporaryParent-and[IO.Path]::GetFileName($resolved)-match'^toolbelt-export-repeat-[0-9a-f]{32}$') 'DIRECTORY_CLEANUP_BOUNDARY'
    [IO.Directory]::Delete($resolved,$false)
   }catch{$cleanupFailed=$true}
  }
 }
 $sourceConnection=$null
}
# Nur feste öffentliche Marker; SQLtexte, Resultsets, Ziel-/DBnamen und Exceptions bleiben privat.
if($null-ne$failure){[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_FAILED');exit 1}
if($cleanupFailed){[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_CLEANUP_DEFERRED');exit 1}
[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_PASS local central SQL2019 CL150 fourteen-tables two-cycles')
[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_CLEANUP_VERIFIED')
