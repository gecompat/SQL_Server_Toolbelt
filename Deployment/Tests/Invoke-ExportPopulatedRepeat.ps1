# Fokussierte Qualifikation im bereits autorisierten CI-Ziel; kein Targetstart,
# Provideraufruf, Grant oder Konfigurations-/Trusteingriff. Reale Daten bleiben privat.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')][string]$ConnectionStringEnvironmentVariable,
      [ValidateSet('Repeat','Queue20Upgrade','ParameterMetadata','Queue11Upgrade')][string]$Scenario='Repeat')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repositoryRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtimeRoot=Join-Path $PSScriptRoot 'Runtime'
$temporaryParent=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath([IO.Path]::GetTempPath()))
$ownedRoot=Join-Path $temporaryParent ('toolbelt-export-repeat-'+[guid]::NewGuid().ToString('N'))
$run=[guid]::NewGuid();$marker='Toolbelt.ExportPopulatedFixture.Run'
$phase='preflight';$failure=$null;$cleanupFailed=$false;$cleanupFailure=$null
$identities=[Collections.Generic.List[object]]::new()
$ownedFiles=[Collections.Generic.List[object]]::new()
$historicalFiles=[Collections.Generic.List[object]]::new()
$historicalDirectories=[Collections.Generic.List[string]]::new()
$journalPath=Join-Path $ownedRoot 'Ownership.json';$journalHash=$null
$utf8=[Text.UTF8Encoding]::new($false,$true)
$expectedModules=@('toolbelt.core.execution-context','toolbelt.core.result-table','toolbelt.file.content','toolbelt.core.execution-cancel','toolbelt.core.work-type','toolbelt.core.second-session','toolbelt.core.work-queue','toolbelt.core.event-log','toolbelt.core.worker-control')
$selectedModules=@('toolbelt.core.worker-control','toolbelt.core.event-log','toolbelt.file.content','toolbelt.core.execution-cancel')
if($Scenario-ceq'ParameterMetadata'){
 $expectedModules=@('toolbelt.core.result-table','toolbelt.core.work-type','toolbelt.core.work-queue')
 $selectedModules=@('toolbelt.core.result-table','toolbelt.core.work-queue')
}
$queue11Record=[ordered]@{Acquisition=[ordered]@{};Captures=@();RetainedUnproven=$false}
$queue11ParentIdentity=$null;$queue11RootIdentity=$null;$queue11JournalIdentity=$null;$queue11RootCreationAuthorized=$false
$queue11FileIdentities=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
$sourceConnection=[Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable,'Process')

function Assert-ExportRepeat([bool]$Condition,[string]$Code){if(-not$Condition){throw ('EXPORT_REPEAT.'+$Code)}}
function Get-SafeFailureDiagnostic([Exception]$Exception,[string]$Phase) {
 # Ausschließlich feste Quellcode-Tokens und Phasen publizieren, keine freien Exceptiontexte.
 $allowedPhases=@('preflight','cleanup','local-export','local-create','local-install','local-seed','local-repeat1','local-repeat2','local-cleanup','central-export','central-create','central-install','central-seed','central-repeat1','central-repeat2','central-cleanup','local-bootstrap','local-historical','local-upgrade','central-bootstrap','central-historical','central-upgrade','local-parameter-seed','local-parameter-repeat','local-parameter-verify','central-parameter-seed','central-parameter-repeat','central-parameter-verify','queue11-acquire')
 $allowedCodes=@(
  'JOURNAL_SIZE','JOURNAL_READ','JOURNAL_DRIFT','OWNERSHIP_UNCONFIRMED',
  'UNRESOLVED_VARIABLE','UNSUPPORTED_DIRECTIVE','ERROR_ABORT_MISSING',
  'EXPORT_BYTES_CHANGED','EXPORT_BATCH_COUNT_CHANGED','EXPORT_NOT_FULLY_CONSUMED',
  'SNAPSHOT_SHAPE','SNAPSHOT_EXTRA_RESULT','SNAPSHOT_TABLES14',
  'SNAPSHOT_CATEGORIES_CHANGED','SNAPSHOT_ROWCOUNT_CHANGED','SNAPSHOT_BYTES_CHANGED',
  'CLEANUP_UNCONFIRMED','CLEANUP_NAME','CONNECTION_INPUT_MISSING',
  'EXPORT_BOM','EXPORT_CLOSURE','EXPORT_ENDS9','EXPORT_GUARDS10',
  'DATABASE_IDENTITY','DATABASE_IDENTITY_SHAPE','FILE_CLEANUP_DRIFT',
  'JOURNAL_CLEANUP_DRIFT','DIRECTORY_CLEANUP_BOUNDARY',
  'BOOTSTRAP_CLOSURE','BOOTSTRAP_MARKERS','SNAPSHOT_TABLES8',
  'HISTORICAL_CAPTURE_HELPER','HISTORICAL_PROCESS_HELPER','HISTORICAL_CAPTURE_UNIQUE',
  'HISTORICAL_CAPTURE_DEADLINE','HISTORICAL_BLOB_ID','HISTORICAL_BLOB_CAPTURE',
  'HISTORICAL_BLOB_BYTES','HISTORICAL_TOOL_DRIFT','HISTORICAL_INCLUDE_COUNT',
  'HISTORICAL_INCLUDE_SHAPE','HISTORICAL_INCLUDE_BINDING','HISTORICAL_FILE_IDENTITY',
  'HISTORICAL_DEPLOY_BINDING','HISTORICAL_MODE_BINDING','HISTORICAL_DIRECTORY_BOUNDARY',
  'SNAPSHOT_TABLE_COUNT','PARAMETER_CAPTURE_BINDING','PARAMETER_SNAPSHOT_CATEGORIES',
  'PARAMETER_SNAPSHOT_CARDINALITY','PARAMETER_COUNTS_XML','PARAMETER_COUNT_ENCODING',
  'PARAMETER_COUNT_BINDING','EXPORT_ENDS3','EXPORT_GUARDS4',
  'QUEUE11_ROOT_PARENT_PATH','QUEUE11_ROOT_NAME','QUEUE11_ROOT_PARENT_ATTRIBUTES',
  'QUEUE11_ROOT_PARENT_CREATED_TICKS','QUEUE11_ROOT_PARENT_REPARSE','QUEUE11_ROOT_DIRECTORY',
  'QUEUE11_ROOT_REPARSE','QUEUE11_ROOT_CREATION_AUTHORITY','QUEUE11_ROOT_CREATED_TICKS',
  'QUEUE11_ROOT_ATTRIBUTES','QUEUE11_ROOT_INITIAL_ABSENT','QUEUE11_ROOT_INITIAL_PARENT_DIRECTORY',
  'QUEUE11_ROOT_INITIAL_PARENT_REPARSE',
  'QUEUE11_DIRECTORY_CI_SCOPE','QUEUE11_DIRECTORY_PROCESS_HELPER','QUEUE11_DIRECTORY_TOOL',
  'QUEUE11_DIRECTORY_TOOL_DRIFT','QUEUE11_DIRECTORY_PATHS','QUEUE11_DIRECTORY_BUDGET',
  'QUEUE11_DIRECTORY_PROCESS','QUEUE11_DIRECTORY_CAPTURE','QUEUE11_DIRECTORY_RECORDS',
  'QUEUE11_DIRECTORY_TYPE','QUEUE11_ROOT_PARENT_IDENTITY','QUEUE11_ROOT_IDENTITY',
  'QUEUE11_ROOT_BOUNDARY','QUEUE11_FILE_BOUNDARY','QUEUE11_FILE_REGISTRATION','QUEUE11_FILE_IDENTITY',
  'QUEUE11_JOURNAL_IDENTITY','QUEUE11_ACQUIRE_HELPER','QUEUE11_CAPTURE_HELPER','QUEUE11_ACQUIRE_RETURN',
  'QUEUE11_CAPTURE_RETURN','QUEUE11_MANIFEST_BINDING','QUEUE11_SQL_FIXTURE_PIN',
  'QUEUE11_ROWVERSION_KEYS','QUEUE11_ROWVERSION_BYTES','QUEUE11_ROWVERSION_CHANGE',
  'QUEUE11_SNAPSHOT_CATEGORIES','QUEUE11_SNAPSHOT_CARDINALITY','QUEUE11_RETAINED_UNPROVEN'
 )
 $safePhase=if($Phase-cin$allowedPhases){$Phase}else{'UNSPECIFIED'}
 $safeCode='UNCLASSIFIED';$sqlNumber=0;$sqlState=0;$cause=$Exception
 while($null-ne$cause){
  foreach($candidate in $allowedCodes){
   if($cause.Message-ceq('EXPORT_REPEAT.'+$candidate)){$safeCode=$candidate;break}
  }
  if($cause-is[Data.SqlClient.SqlException]){
   $sqlNumber=[int]$cause.Number
   $candidateState=[int]$cause.State
   if($candidateState-ge0-and$candidateState-le255){$sqlState=$candidateState}
   break
  }
  $cause=$cause.InnerException
 }
 return [ordered]@{Phase=$safePhase;Code=$safeCode;SqlNumber=$sqlNumber;SqlState=$sqlState}
}
function Write-SafeFailureDiagnostic($Diagnostic) {
 # Auch private Journalwerte vor Ausgabe erneut durch die geschlossene Abbildung führen.
 $safe=Get-SafeFailureDiagnostic ([Exception]::new('EXPORT_REPEAT.'+$Diagnostic.Code)) $Diagnostic.Phase
 $number=0;$state=0
 if($Diagnostic.SqlNumber-is[int]){$number=$Diagnostic.SqlNumber}
 if($Diagnostic.SqlState-is[int]-and$Diagnostic.SqlState-ge0-and$Diagnostic.SqlState-le255){$state=$Diagnostic.SqlState}
 [Console]::Out.WriteLine(('EXPORT_POPULATED_REPEAT_DIAGNOSTIC phase={0} code={1} sql-number={2} sql-state={3}'-f$safe.Phase,$safe.Code,$number,$state))
}
function Save-PrivateOwnership {
 $record=[ordered]@{Run=$run;Marker=$marker;Phase=$phase;Databases=$identities.ToArray();Failure=$failure;CleanupFailed=$cleanupFailed}
 if($Scenario-ceq'Queue11Upgrade'){$record['Queue11']=$queue11Record}
 $bytes=$utf8.GetBytes((ConvertTo-Json -InputObject $record -Depth $(if($Scenario-ceq'Queue11Upgrade'){8}else{5}) -Compress))
 if($Scenario-ceq'Queue11Upgrade'){
  Assert-ExportRepeat ($bytes.Length-le65536) 'JOURNAL_SIZE'
  Assert-Queue11Journal
 }
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
 if($Scenario-ceq'Queue11Upgrade'){Bind-Queue11Journal}
}
function New-ExportConnection([string]$Database){
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($sourceConnection)
 $builder['Initial Catalog']=$Database;$builder.Pooling=$false;$builder.Enlist=$false;$builder.ConnectRetryCount=0;$builder['Connect Timeout']=5
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
 # Feste States unterscheiden ausschließlich die bestehenden booleschen Gates.
 # Keine Metadatenwerte oder freien Diagnosen verlassen die private Sitzung.
 Invoke-ExportSql $Connection '
 IF @@TRANCOUNT<>0 THROW 54984,N''Neutrale Exportfixture fehlt.'',1;
 IF XACT_STATE()<>0 THROW 54984,N''Neutrale Exportfixture fehlt.'',2;
 IF (@@OPTIONS&2)<>0 THROW 54984,N''Neutrale Exportfixture fehlt.'',3;
 IF @@LOCK_TIMEOUT<>-1 THROW 54984,N''Neutrale Exportfixture fehlt.'',4;
 IF DB_ID()<>@Id THROW 54984,N''Eigene Exportfixture fehlt.'',5;
 IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Name) THROW 54984,N''Eigene Exportfixture fehlt.'',6;
 IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created) THROW 54984,N''Eigene Exportfixture fehlt.'',7;
 IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND owner_sid=@Owner) THROW 54984,N''Eigene Exportfixture fehlt.'',8;
 IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND owner_sid=SUSER_SID()) THROW 54984,N''Eigene Exportfixture fehlt.'',9;
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker) THROW 54984,N''Eigene Exportfixture fehlt.'',10;
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND SQL_VARIANT_PROPERTY(value,''BaseType'')=''uniqueidentifier'') THROW 54984,N''Eigene Exportfixture fehlt.'',11;
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND TRY_CONVERT(uniqueidentifier,value)=@Run) THROW 54984,N''Eigene Exportfixture fehlt.'',12;
 -- Relationale Identität vollständig binden; den Live-Sessionzustand separat erneut prüfen.
 IF DB_ID()<>@Id OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND name=@Name AND CONVERT(binary(9),CONVERT(datetime2(7),create_date))=@Created AND owner_sid=@Owner AND owner_sid=SUSER_SID()) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Marker AND SQL_VARIANT_PROPERTY(value,''BaseType'')=''uniqueidentifier'' AND TRY_CONVERT(uniqueidentifier,value)=@Run) THROW 54984,N''Eigene Exportfixtureidentität oder neutrale Session fehlt.'',13;
 IF @@TRANCOUNT<>0 THROW 54984,N''Neutrale Exportfixture fehlt.'',14;
 IF XACT_STATE()<>0 THROW 54984,N''Neutrale Exportfixture fehlt.'',15;
 IF (@@OPTIONS&2)<>0 THROW 54984,N''Neutrale Exportfixture fehlt.'',16;
 IF @@LOCK_TIMEOUT<>-1 THROW 54984,N''Neutrale Exportfixture fehlt.'',17;
 ' (Get-IdentityParameters $Identity)
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
function Read-PrivateSnapshot($Identity,[string]$Name='ExportPopulated.Capture.sql',[hashtable]$Parameters=@{},[int]$TableCount=14){
 Assert-ExportRepeat ($TableCount-in@(0,8,14)) 'SNAPSHOT_TABLE_COUNT'
 if($TableCount-eq0){Assert-ExportRepeat ($Name-ceq'ExportParameter.Capture.sql'-and$Parameters.Count-eq0) 'PARAMETER_CAPTURE_BINDING'}
 $connection=New-ExportConnection $Identity.Name
 try{
  Assert-OwnedConnection $connection $Identity
  $command=$connection.CreateCommand();$command.CommandTimeout=15;$command.CommandText=[IO.File]::ReadAllText((Join-Path $runtimeRoot $Name),$utf8)
  foreach($key in $Parameters.Keys){[void]$command.Parameters.AddWithValue($key,$Parameters[$key])}
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
   $actualTables=@($snapshot.Keys|Where-Object {$_.StartsWith('row:',[StringComparison]::Ordinal)}).Count
   if($TableCount-eq0){Assert-ParameterSnapshotShape $snapshot}
   else{if($TableCount-eq8){Assert-ExportRepeat ($actualTables-eq8) 'SNAPSHOT_TABLES8'}else{Assert-ExportRepeat ($actualTables-eq14) 'SNAPSHOT_TABLES14'}}
   return ,$snapshot
  }finally{$command.Dispose()}
 }finally{$connection.Dispose()}
}
function Assert-ParameterSnapshotShape($Snapshot){
 # Die Parameterfixture ist der einzige erlaubte tabellenfreie Snapshotpfad.
 $required=@('counts','parameters','objects','modules','properties')
 $allowed=$required+@('permissions')
 Assert-ExportRepeat (@($Snapshot.Keys|Where-Object {$_-cnotin$allowed}).Count-eq0-and@($required|Where-Object {-not$Snapshot.ContainsKey($_)}).Count-eq0) 'PARAMETER_SNAPSHOT_CATEGORIES'
 Assert-ExportRepeat ($Snapshot['counts'].Count-eq1-and$Snapshot['parameters'].Count-eq11-and$Snapshot['objects'].Count-eq2-and$Snapshot['modules'].Count-eq2-and$Snapshot['properties'].Count-ge4) 'PARAMETER_SNAPSHOT_CARDINALITY'
 if($Snapshot.ContainsKey('permissions')){Assert-ExportRepeat ($Snapshot['permissions'].Count-gt0) 'PARAMETER_SNAPSHOT_CARDINALITY'}
 $countHex=$Snapshot['counts'][0]
 Assert-ExportRepeat ($countHex.Length-gt0-and$countHex.Length-le16384-and($countHex.Length%4)-eq0) 'PARAMETER_COUNTS_XML'
 $xml=$null;$reader=$null
 try{
  # SQL-NVARCHAR->varbinary ist UTF16LE. Nur der kleine eigene Countzeuge wird als XML gelesen.
  $xml=[Text.UnicodeEncoding]::new($false,$false,$true).GetString([Convert]::FromHexString($countHex))
  $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null;$settings.MaxCharactersInDocument=4096
  $reader=[Xml.XmlReader]::Create([IO.StringReader]::new($xml),$settings)
  $document=[Xml.XmlDocument]::new();$document.XmlResolver=$null;$document.Load($reader)
  Assert-ExportRepeat ($document.DocumentElement.Name-ceq'row'-and$document.DocumentElement.SelectNodes('*').Count-eq5) 'PARAMETER_COUNTS_XML'
  foreach($field in @('Parameters','Objects','Modules','Properties','Permissions')){
   $nodes=$document.DocumentElement.SelectNodes($field)
   Assert-ExportRepeat ($nodes.Count-eq1-and$nodes[0].SelectNodes('*').Count-eq0) 'PARAMETER_COUNT_ENCODING'
   $bytes=[Convert]::FromBase64String($nodes[0].InnerText)
   Assert-ExportRepeat ($bytes.Length-eq4-and$bytes[0]-lt128) 'PARAMETER_COUNT_ENCODING'
   # SQL-int->binary verwendet Netzwerkbytefolge; keine hostabhängige BitConverter-Auswertung.
   $count=([int]$bytes[0]-shl24)-bor([int]$bytes[1]-shl16)-bor([int]$bytes[2]-shl8)-bor[int]$bytes[3]
   $category=$field.ToLowerInvariant()
   $observed=if($Snapshot.ContainsKey($category)){$Snapshot[$category].Count}else{0}
   Assert-ExportRepeat ($count-eq$observed) 'PARAMETER_COUNT_BINDING'
  }
 }catch{
  # Decoder-/XMLtexte können fremde Inhalte enthalten und verlassen das private Memory nicht.
  if($_.Exception.Message-cin@('EXPORT_REPEAT.PARAMETER_COUNTS_XML','EXPORT_REPEAT.PARAMETER_COUNT_ENCODING','EXPORT_REPEAT.PARAMETER_COUNT_BINDING')){throw}
  Assert-ExportRepeat $false 'PARAMETER_COUNTS_XML'
 }finally{if($null-ne$reader){$reader.Dispose()};$xml=$null}
}
function Assert-Fixture([bool]$Condition,[string]$Code){Assert-ExportRepeat $Condition $Code}
function Assert-HistoricalFile($File){
 $item=Get-Item -LiteralPath $File.Path -ErrorAction Stop
 Assert-ExportRepeat ($item.Length-eq$File.Length-and$item.CreationTimeUtc.Ticks-eq$File.CreatedTicks-and[int]$item.Attributes-eq$File.Attributes-and($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0-and(Get-FileHash -LiteralPath $File.Path -Algorithm SHA256).Hash-ceq$File.SHA256) 'HISTORICAL_FILE_IDENTITY'
}
function New-UpgradeBootstrap([string]$Mode){
 $path=Join-Path $ownedRoot ($Mode+'-bootstrap.sql')
 & (Join-Path $repositoryRoot 'Deployment/Deploy-All.ps1') -DeploymentMode $Mode -ModuleId @('toolbelt.core.event-log','toolbelt.file.content','toolbelt.core.execution-cancel') -OutputSqlFile $path *> $null
 $bytes=[IO.File]::ReadAllBytes($path);$text=$utf8.GetString($bytes)
 Assert-ExportRepeat (-not($bytes[0]-eq239-and$bytes[1]-eq187-and$bytes[2]-eq191)) 'EXPORT_BOM'
 $expected=@('toolbelt.core.execution-context','toolbelt.core.result-table','toolbelt.file.content','toolbelt.core.execution-cancel','toolbelt.core.work-type','toolbelt.core.second-session','toolbelt.core.event-log')
 $actual=@([regex]::Matches($text,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)$')|ForEach-Object {$_.Groups[1].Value})
 Assert-ExportRepeat (($actual-join ',')-ceq($expected-join ',')) 'BOOTSTRAP_CLOSURE'
 Assert-ExportRepeat ([regex]::Matches($text,'(?m)^-- END MODULE ').Count-eq7-and[regex]::Matches($text,'IF @@TRANCOUNT <> 0 OR \(2 & @@OPTIONS\) <> 0').Count-eq8) 'BOOTSTRAP_MARKERS'
 $export=[pscustomobject]@{Path=$path;Hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes));BatchCount=@(Get-ExportBatches $text).Count}
 $ownedFiles.Add($export);return $export
}
function New-UpgradeHistoricalExport([string]$Mode){
 $helper=Join-Path $repositoryRoot 'Workers/ExternalQueue/Tests/Runtime/New-GenuineQueue20Capture.ps1'
 Assert-ExportRepeat ((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash-ceq'04A92F46ADECCDF33A7CB6D7882F30AC427449C1CD8F9EBBDD978EB193F7B377') 'HISTORICAL_CAPTURE_HELPER'
 . $helper
 $captureRoot=Join-Path $ownedRoot ('queue20-'+$Mode)
 $deploy=New-GenuineQueue20Capture -RepositoryRoot $repositoryRoot -OutputRoot $captureRoot -OwnedFiles $historicalFiles -OwnedDirectories $historicalDirectories
 $deployFile=@($historicalFiles|Where-Object {$_.Path-ceq$deploy})
 Assert-ExportRepeat ($deployFile.Count-eq1) 'HISTORICAL_DEPLOY_BINDING'
 Assert-HistoricalFile $deployFile[0]
 $text=[IO.File]::ReadAllText($deploy,$utf8);$includeCount=0
 $expanded=[Text.StringBuilder]::new()
 foreach($line in [regex]::Split($text,'\r?\n')){
  if($line.StartsWith(':r ',[StringComparison]::Ordinal)){
   Assert-ExportRepeat ($line-cmatch'^:r ../Source/([A-Za-z0-9_]+\.sql)$') 'HISTORICAL_INCLUDE_SHAPE'
   $relative='Source/'+$Matches[1]
   $file=@($historicalFiles|Where-Object {$_.Path.StartsWith($captureRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)-and$_.PSObject.Properties.Name-ccontains'Relative'-and$_.Relative-ceq$relative})
   Assert-ExportRepeat ($file.Count-eq1) 'HISTORICAL_INCLUDE_BINDING'
   Assert-HistoricalFile $file[0]
   [void]$expanded.AppendLine([IO.File]::ReadAllText($file[0].Path,$utf8));$includeCount++
  }else{[void]$expanded.AppendLine($line)}
 }
 Assert-ExportRepeat ($includeCount-eq14) 'HISTORICAL_INCLUDE_COUNT'
 Assert-ExportRepeat ([regex]::Matches($expanded.ToString(),'\$\(DeploymentMode\)').Count-eq1) 'HISTORICAL_MODE_BINDING'
 $bytes=$utf8.GetBytes($expanded.ToString().Replace('$(DeploymentMode)',$Mode))
 $path=Join-Path $ownedRoot ($Mode+'-queue20.sql');[IO.File]::WriteAllBytes($path,$bytes)
 $export=[pscustomobject]@{Path=$path;Hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes));BatchCount=@(Get-ExportBatches ($utf8.GetString($bytes))).Count}
 $ownedFiles.Add($export);return $export
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
# Zusätzliche Grenzen ausschließlich für Queue11Upgrade; alte Consumer bleiben unverändert.
function Assert-Queue11DirectoryTools {
 # Kein Neuauflösen oder Rebind bei Drift; keine Toolpfade/Hashes öffentlich ausgeben.
 foreach($binding in @($queue11DirectoryProcessHelper,$queue11DirectoryTool)){
  $item=Get-Item -LiteralPath $binding.Path -ErrorAction Stop
  $code=if($binding.Path-ceq$queue11DirectoryProcessHelper.Path){'QUEUE11_DIRECTORY_PROCESS_HELPER'}else{'QUEUE11_DIRECTORY_TOOL_DRIFT'}
  Assert-ExportRepeat ([IO.File]::Exists($binding.Path)-and-not$item.PSIsContainer-and($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0-and(Get-FileHash -LiteralPath $binding.Path -Algorithm SHA256).Hash-ceq$binding.Hash) $code
 }
}
function Get-Queue11DirectoryIdentities([string[]]$Paths){
 # Nur Parent oder geordnet Parent/Root: kein allgemeiner Dateireader und kein Shellaufruf.
 Assert-ExportRepeat ($Paths.Count-eq1-or$Paths.Count-eq2) 'QUEUE11_DIRECTORY_PATHS'
 Assert-ExportRepeat ($Paths[0]-ceq$temporaryParent-and[IO.Path]::GetFullPath($Paths[0])-ceq$Paths[0]) 'QUEUE11_DIRECTORY_PATHS'
 if($Paths.Count-eq2){Assert-ExportRepeat ($Paths[1]-ceq$ownedRoot-and[IO.Path]::GetFullPath($Paths[1])-ceq$Paths[1]) 'QUEUE11_DIRECTORY_PATHS'}
 Assert-Queue11DirectoryTools
 $remaining=60000L-$queue11DirectoryBudget.ElapsedMilliseconds
 Assert-ExportRepeat ($remaining-ge1-and$queue11DirectoryBudget.ProcessCount-lt1024) 'QUEUE11_DIRECTORY_BUDGET'
 $timeout=[int][Math]::Min(5000L,$remaining)
 $arguments=@('--printf=%d:%i:%f\n','--')+$Paths
 $script:queue11DirectoryBudget.ProcessCount++
 $watch=[Diagnostics.Stopwatch]::StartNew();$result=$null
 try{
  try{$result=Invoke-OwnedProcess -FileName $queue11DirectoryTool.Path -Arguments $arguments -TimeoutMilliseconds $timeout}
  catch{throw 'EXPORT_REPEAT.QUEUE11_DIRECTORY_PROCESS'}
 }finally{
  $watch.Stop();$script:queue11DirectoryBudget.ElapsedMilliseconds+=$watch.ElapsedMilliseconds
  Assert-Queue11DirectoryTools
 }
 Assert-ExportRepeat ($queue11DirectoryBudget.ElapsedMilliseconds-le60000) 'QUEUE11_DIRECTORY_BUDGET'
 Assert-ExportRepeat ($null-ne$result-and$result.ExitCode-is[int]-and$result.ExitCode-eq0-and$result.CaptureComplete-is[bool]-and$result.CaptureComplete-and$result.Stdout-is[string]-and$result.Stderr-is[string]-and$result.Stderr.Length-eq0) 'QUEUE11_DIRECTORY_CAPTURE'
 # Getrennte 4-MiB-Transportcaps des unveränderten Helpers; hier enger 128-Byte-Akzeptanzvertrag.
 Assert-ExportRepeat ($result.Stdout.Length-le128-and[Text.Encoding]::UTF8.GetByteCount($result.Stdout)-le128) 'QUEUE11_DIRECTORY_RECORDS'
 $pattern='\A(?:[0-9]{1,20}:[0-9]{1,20}:[0-9a-f]{1,8}\n){'+$Paths.Count+'}\z'
 Assert-ExportRepeat ([regex]::IsMatch($result.Stdout,$pattern,[Text.RegularExpressions.RegexOptions]::CultureInvariant)) 'QUEUE11_DIRECTORY_RECORDS'
 $records=[Collections.Generic.List[object]]::new()
 foreach($line in $result.Stdout.Substring(0,$result.Stdout.Length-1).Split("`n")){
  $fields=$line.Split(':');[uint64]$device=0;[uint64]$inode=0;[uint32]$mode=0
  Assert-ExportRepeat ([uint64]::TryParse($fields[0],[Globalization.NumberStyles]::None,[Globalization.CultureInfo]::InvariantCulture,[ref]$device)) 'QUEUE11_DIRECTORY_RECORDS'
  Assert-ExportRepeat ([uint64]::TryParse($fields[1],[Globalization.NumberStyles]::None,[Globalization.CultureInfo]::InvariantCulture,[ref]$inode)-and$inode-gt0) 'QUEUE11_DIRECTORY_RECORDS'
  Assert-ExportRepeat ([uint32]::TryParse($fields[2],[Globalization.NumberStyles]::AllowHexSpecifier,[Globalization.CultureInfo]::InvariantCulture,[ref]$mode)) 'QUEUE11_DIRECTORY_RECORDS'
  Assert-ExportRepeat (($mode-band0xF000)-eq0x4000) 'QUEUE11_DIRECTORY_TYPE'
  $records.Add([pscustomobject]@{Device=$device;Inode=$inode;Mode=$mode})
 }
 Assert-ExportRepeat ($records.Count-eq$Paths.Count) 'QUEUE11_DIRECTORY_RECORDS'
 return ,$records.ToArray()
}
function Assert-Queue11Root {
 $resolved=[IO.Path]::GetFullPath($ownedRoot)
 # Nur feste Operandtokens unterscheiden; keine Pfade oder Runtimewerte publizieren.
 Assert-ExportRepeat ([IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetDirectoryName($resolved))-ceq$temporaryParent) 'QUEUE11_ROOT_PARENT_PATH'
 Assert-ExportRepeat ([IO.Path]::GetFileName($resolved)-cmatch'^toolbelt-export-repeat-[0-9a-f]{32}$') 'QUEUE11_ROOT_NAME'
 $parent=Get-Item -LiteralPath $temporaryParent -ErrorAction Stop
 Assert-ExportRepeat ([int]$parent.Attributes-eq$queue11ParentIdentity.Attributes) 'QUEUE11_ROOT_PARENT_ATTRIBUTES'
 # Ein Prozess liefert beide Identitäten; keine mutable Verzeichniszeit als Objekt-ID verwenden.
 $directoryIdentities=Get-Queue11DirectoryIdentities @($temporaryParent,$ownedRoot)
 Assert-ExportRepeat ($directoryIdentities[0].Device-eq$queue11ParentIdentity.Device-and$directoryIdentities[0].Inode-eq$queue11ParentIdentity.Inode-and$directoryIdentities[0].Mode-eq$queue11ParentIdentity.Mode) 'QUEUE11_ROOT_PARENT_IDENTITY'
 Assert-ExportRepeat (($parent.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0) 'QUEUE11_ROOT_PARENT_REPARSE'
 $item=Get-Item -LiteralPath $resolved -ErrorAction Stop
 Assert-ExportRepeat ([IO.Directory]::Exists($resolved)) 'QUEUE11_ROOT_DIRECTORY'
 Assert-ExportRepeat (($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0) 'QUEUE11_ROOT_REPARSE'
 if($null-eq$queue11RootIdentity){
  Assert-ExportRepeat $queue11RootCreationAuthorized 'QUEUE11_ROOT_CREATION_AUTHORITY'
  $script:queue11RootIdentity=[pscustomobject]@{Device=$directoryIdentities[1].Device;Inode=$directoryIdentities[1].Inode;Mode=$directoryIdentities[1].Mode;Attributes=[int]$item.Attributes}
 }
 Assert-ExportRepeat ($directoryIdentities[1].Device-eq$queue11RootIdentity.Device-and$directoryIdentities[1].Inode-eq$queue11RootIdentity.Inode-and$directoryIdentities[1].Mode-eq$queue11RootIdentity.Mode) 'QUEUE11_ROOT_IDENTITY'
 Assert-ExportRepeat ([int]$item.Attributes-eq$queue11RootIdentity.Attributes) 'QUEUE11_ROOT_ATTRIBUTES'
}
function Assert-Queue11Path([string]$Path){
 Assert-Queue11Root
 $resolved=[IO.Path]::GetFullPath($Path)
 Assert-ExportRepeat ($resolved-ceq$Path-and$resolved.StartsWith($ownedRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)) 'QUEUE11_FILE_BOUNDARY'
 $parent=[IO.Path]::GetDirectoryName($resolved);$depth=0
 while($parent-cne$ownedRoot){
  $depth++;Assert-ExportRepeat ($depth-le16-and$parent.StartsWith($ownedRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)) 'QUEUE11_FILE_BOUNDARY'
  $item=Get-Item -LiteralPath $parent -ErrorAction Stop
  Assert-ExportRepeat ([IO.Directory]::Exists($parent)-and($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0) 'QUEUE11_FILE_BOUNDARY'
  $parent=[IO.Path]::GetDirectoryName($parent)
 }
}
function Register-Queue11File($File){
 Assert-Queue11Path $File.Path
 Assert-ExportRepeat (-not$queue11FileIdentities.ContainsKey($File.Path)) 'QUEUE11_FILE_REGISTRATION'
 $item=Get-Item -LiteralPath $File.Path -ErrorAction Stop
 $hash=(Get-FileHash -LiteralPath $File.Path -Algorithm SHA256).Hash
 $expected=if($File.PSObject.Properties.Name-ccontains'Hash'){$File.Hash}else{$File.SHA256}
 Assert-ExportRepeat ([IO.File]::Exists($File.Path)-and($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0-and$hash-ceq$expected) 'QUEUE11_FILE_IDENTITY'
 $queue11FileIdentities.Add($File.Path,[pscustomobject]@{Path=$File.Path;Length=$item.Length;CreatedTicks=$item.CreationTimeUtc.Ticks;Attributes=[int]$item.Attributes;Hash=$hash})
}
function Assert-Queue11File([string]$Path){
 Assert-Queue11Path $Path
 Assert-ExportRepeat ($queue11FileIdentities.ContainsKey($Path)) 'QUEUE11_FILE_REGISTRATION'
 $expected=$queue11FileIdentities[$Path];$item=Get-Item -LiteralPath $Path -ErrorAction Stop
 Assert-ExportRepeat ([IO.File]::Exists($Path)-and$item.Length-eq$expected.Length-and$item.CreationTimeUtc.Ticks-eq$expected.CreatedTicks-and[int]$item.Attributes-eq$expected.Attributes-and($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0-and(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash-ceq$expected.Hash) 'QUEUE11_FILE_IDENTITY'
}
function Assert-Queue11Journal {
 Assert-Queue11Path $journalPath
 if($null-eq$journalHash){Assert-ExportRepeat (-not(Test-Path -LiteralPath $journalPath)) 'QUEUE11_JOURNAL_IDENTITY';return}
 Assert-ExportRepeat ($null-ne$queue11JournalIdentity) 'QUEUE11_JOURNAL_IDENTITY'
 $item=Get-Item -LiteralPath $journalPath -ErrorAction Stop
 Assert-ExportRepeat ([IO.File]::Exists($journalPath)-and$item.Length-eq$queue11JournalIdentity.Length-and$item.Length-le65536-and$item.CreationTimeUtc.Ticks-eq$queue11JournalIdentity.CreatedTicks-and[int]$item.Attributes-eq$queue11JournalIdentity.Attributes-and($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0-and(Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash-ceq$journalHash) 'QUEUE11_JOURNAL_IDENTITY'
}
function Bind-Queue11Journal {
 $item=Get-Item -LiteralPath $journalPath -ErrorAction Stop
 Assert-ExportRepeat ([IO.File]::Exists($journalPath)-and$item.Length-le65536-and($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0-and(Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash-ceq$journalHash) 'QUEUE11_JOURNAL_IDENTITY'
 $script:queue11JournalIdentity=[pscustomobject]@{Length=$item.Length;CreatedTicks=$item.CreationTimeUtc.Ticks;Attributes=[int]$item.Attributes}
}
function New-Queue11HistoricalExport([string]$Mode){
 $helper=Join-Path $repositoryRoot 'Workers/ExternalQueue/Tests/Runtime/New-GenuineQueue11Capture.ps1'
 Assert-ExportRepeat ((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash-ceq'0DDE104052907548E6CDD29FEF0CAEC64DCC425E7DFCC418D5B5FA2ED1F52DFF') 'QUEUE11_CAPTURE_HELPER'
 . $helper
 $captureRoot=Join-Path $ownedRoot ('queue11-'+$Mode)
 Assert-Queue11Root
 Assert-ExportRepeat (-not(Test-Path -LiteralPath $captureRoot)) 'QUEUE11_CAPTURE_RETURN'
 $deploy=New-GenuineQueue11Capture -RepositoryRoot $repositoryRoot -OutputRoot $captureRoot -DeploymentMode $Mode -OwnedFiles $historicalFiles -OwnedDirectories $historicalDirectories
 Assert-ExportRepeat ($deploy-is[string]-and$deploy-ceq(Join-Path $captureRoot ('Queue11-'+$Mode+'.sql'))) 'QUEUE11_CAPTURE_RETURN'
 $files=@($historicalFiles|Where-Object {$_.Path.StartsWith($captureRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)})
 Assert-ExportRepeat ($files.Count-eq13-and@($files.Path|Sort-Object -Unique).Count-eq13) 'QUEUE11_CAPTURE_RETURN'
 foreach($file in $files){Assert-HistoricalFile $file;Register-Queue11File $file;Assert-Queue11File $file.Path}
 $manifestPath=Join-Path $captureRoot 'SourcePins.json';Assert-Queue11File $manifestPath
 $manifestBytes=[IO.File]::ReadAllBytes($manifestPath)
 Assert-ExportRepeat ($manifestBytes.Length-le65536) 'QUEUE11_MANIFEST_BINDING'
 $manifest=$utf8.GetString($manifestBytes)|ConvertFrom-Json -ErrorAction Stop
 Assert-ExportRepeat ($manifest.Commit-ceq'7c6cb157db39a948e14f3db1f4973f80579a5832'-and$manifest.Tree-ceq'86e3b854bbf66b442cd2b19c26802628acfd0cd0'-and$manifest.ModuleTree-ceq'8b0c04a64a91f7022865cc695659dd8f6e06bd39'-and$manifest.DeploymentMode-ceq$Mode-and$manifest.HelperSHA256-ceq'7B3E838EE5D294B3DECF3153D2D02276BE401E6F76EE8D810F20C5DCC51D1BD4'-and$manifest.GitSHA256-ceq$queue11Record.Acquisition.GitSHA256) 'QUEUE11_MANIFEST_BINDING'
 $relative=@('Deployment/Deploy.sql','Source/WorkItem.sql','Source/VW_WorkQueue.sql','Source/USP_EnqueueWork.sql','Source/USP_ClaimWork.sql','Source/USP_RenewWorkLease.sql','Source/USP_RecoverExpiredWork.sql','Source/USP_CompleteWork.sql','Source/USP_FailWork.sql','Source/USP_GetWorkStatus.sql','module.yaml')
 Assert-ExportRepeat (@($manifest.Files).Count-eq11-and@($manifest.Includes).Count-eq9-and($manifest.Includes-join"`n")-ceq(($relative|Where-Object {$_.StartsWith('Source/',[StringComparison]::Ordinal)})-join"`n")) 'QUEUE11_MANIFEST_BINDING'
 $sourceBytes=0
 for($i=0;$i-lt11;$i++){
  $source=$manifest.Files[$i];$path=Join-Path $captureRoot $relative[$i]
  $registered=@($files|Where-Object {$_.Path-ceq$path-and$_.Relative-ceq$relative[$i]})
  Assert-ExportRepeat ($registered.Count-eq1-and$source.Path-ceq$path-and$source.Relative-ceq$relative[$i]-and$source.Blob-ceq$registered[0].Blob-and$source.SHA256-ceq$registered[0].SHA256-and$source.Length-eq$registered[0].Length-and$source.CreatedTicks-eq$registered[0].CreatedTicks-and$source.Attributes-eq$registered[0].Attributes) 'QUEUE11_MANIFEST_BINDING'
  Assert-Queue11File $path;$sourceBytes+=$source.Length
 }
 Assert-ExportRepeat ($sourceBytes-eq88821) 'QUEUE11_MANIFEST_BINDING'
 Assert-Queue11File $deploy
 $bytes=[IO.File]::ReadAllBytes($deploy);$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
 Assert-ExportRepeat ($hash-ceq$manifest.ExpandedSHA256) 'QUEUE11_MANIFEST_BINDING'
 $batches=@(Get-ExportBatches ($utf8.GetString($bytes)))
 Assert-ExportRepeat ($batches.Count-gt0-and$batches.Count-le512) 'QUEUE11_CAPTURE_RETURN'
 Assert-ExportRepeat ((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash-ceq'0DDE104052907548E6CDD29FEF0CAEC64DCC425E7DFCC418D5B5FA2ED1F52DFF') 'QUEUE11_CAPTURE_HELPER'
 $queue11Record.Captures+=@([ordered]@{Mode=$Mode;ManifestSHA256=$queue11FileIdentities[$manifestPath].Hash;ExpandedSHA256=$hash;BatchCount=$batches.Count;Files=@($files|ForEach-Object {$queue11FileIdentities[$_.Path]})})
 Save-PrivateOwnership
 return [pscustomobject]@{Path=$deploy;Hash=$hash;BatchCount=$batches.Count}
}
function Invoke-Queue11ExportFile($Identity,$Export){
 Assert-Queue11File $Export.Path
 $started=Invoke-ExportFile $Identity $Export
 Assert-Queue11File $Export.Path
 return $started
}
function Assert-Queue11Fixtures {
 foreach($binding in @(@{Name='ExportQueue11.Setup.sql';Hash='04EB235CCEEC0036EDDD2C8B9D342EB800F76432656731BC6339B96E32E0ECEC'},@{Name='ExportQueue11.Capture.sql';Hash='58DB015EF05262E62670A0055BAECB2CD57AFFE23FDF33576382350347E7CE99'},@{Name='ExportQueue11.Assert.sql';Hash='204FDCEE62260238EFA0AC31A140ED6FD4F7ED00F4A8102A799D8351BB62F55D'})){
  Assert-ExportRepeat ((Get-FileHash -LiteralPath (Join-Path $runtimeRoot $binding.Name) -Algorithm SHA256).Hash-ceq$binding.Hash) 'QUEUE11_SQL_FIXTURE_PIN'
 }
}
function Read-Queue11Snapshot($Identity,[bool]$After,[string]$Mode){
 Assert-Queue11Fixtures
 $connection=New-ExportConnection $Identity.Name
 try{
  Assert-OwnedConnection $connection $Identity
  $command=$connection.CreateCommand();$command.CommandTimeout=15;$command.CommandText=[IO.File]::ReadAllText((Join-Path $runtimeRoot 'ExportQueue11.Capture.sql'),$utf8)
  [void]$command.Parameters.AddWithValue('@After',$After);[void]$command.Parameters.AddWithValue('@InstallMode',$Mode)
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
   Assert-Queue11SnapshotShape $snapshot $After
   Assert-OwnedConnection $connection $Identity
   return ,$snapshot
  }finally{$command.Dispose()}
 }finally{$connection.Dispose()}
}
function Assert-Queue11SnapshotShape($Snapshot,[bool]$After){
 $rows=[ordered]@{'toolbelt_core.WorkType'=2;'toolbelt_core.WorkItem'=3;'toolbelt_core.ExecutionCancellation'=3;'toolbelt_core.SecondSessionProvider'=1;'toolbelt_core.EventLog'=3;'toolbelt_file.FileContentRootAllowlist'=4}
 if($After){foreach($item in @(@{Name='WorkQueueBarrierBlocker';Rows=0},@{Name='WorkQueueManagedGate';Rows=1},@{Name='WorkQueueScheduler';Rows=1},@{Name='WorkerControlConfiguration';Rows=1},@{Name='WorkerExecutionCommitWitness';Rows=0},@{Name='WorkerExecutionDisposition';Rows=0},@{Name='WorkerRegistration';Rows=0},@{Name='WorkerSlotReservation';Rows=0})){$rows['toolbelt_core.'+$item.Name]=$item.Rows}}
 $catalog=@('schemas','tables','objects','columns','view-columns','identity','indexes','index-columns','defaults','checks','keys','foreign-keys','foreign-key-columns','modules','parameters','properties','permissions','rowversion-count')
 $expected=@($rows.Keys|ForEach-Object {'row:'+$_})+@($catalog|ForEach-Object {'catalog:'+$_})
 $rv=@($Snapshot.Keys|Where-Object {$_-cmatch'^rv:toolbelt_core\.WorkItem:[1-9][0-9]*$'}|Sort-Object)
 Assert-ExportRepeat ($rv.Count-eq3) 'QUEUE11_ROWVERSION_KEYS'
 foreach($key in $rv){Assert-ExportRepeat ($Snapshot[$key].Count-eq1-and$Snapshot[$key][0]-cmatch'^[0-9A-F]{16}$') 'QUEUE11_ROWVERSION_BYTES'}
 $expected+=$rv
 if($After){$expected+=@('target:toolbelt_core.WorkItem');Assert-ExportRepeat ($Snapshot.ContainsKey('target:toolbelt_core.WorkItem')-and$Snapshot['target:toolbelt_core.WorkItem'].Count-eq4) 'QUEUE11_SNAPSHOT_CATEGORIES'}
 Assert-ExportRepeat ((@($Snapshot.Keys|Sort-Object)-join"`n")-ceq(@($expected|Sort-Object)-join"`n")) 'QUEUE11_SNAPSHOT_CATEGORIES'
 foreach($name in $rows.Keys){Assert-ExportRepeat ($Snapshot['row:'+$name].Count-eq(1+$rows[$name])) 'QUEUE11_SNAPSHOT_CARDINALITY'}
 foreach($name in $catalog){Assert-ExportRepeat ($Snapshot['catalog:'+$name].Count-ge1) 'QUEUE11_SNAPSHOT_CARDINALITY'}
 Assert-ExportRepeat ($Snapshot['catalog:rowversion-count'].Count-eq1) 'QUEUE11_SNAPSHOT_CARDINALITY'
}
function Compare-Queue11Snapshots($Previous,$Current){
 $legacy=@('row:toolbelt_core.WorkType','row:toolbelt_core.WorkItem','row:toolbelt_core.ExecutionCancellation','row:toolbelt_core.SecondSessionProvider','row:toolbelt_core.EventLog','row:toolbelt_file.FileContentRootAllowlist')
 $before=[Collections.Generic.Dictionary[string,Collections.Generic.List[string]]]::new([StringComparer]::Ordinal)
 $after=[Collections.Generic.Dictionary[string,Collections.Generic.List[string]]]::new([StringComparer]::Ordinal)
 foreach($key in $Previous.Keys){if($key-cin$legacy-or$key.StartsWith('catalog:',[StringComparison]::Ordinal)){$before.Add($key,$Previous[$key]);Assert-ExportRepeat ($Current.ContainsKey($key)) 'QUEUE11_SNAPSHOT_CATEGORIES';$after.Add($key,$Current[$key])}}
 Compare-PrivateSnapshots $before $after
 $oldRv=@($Previous.Keys|Where-Object {$_.StartsWith('rv:',[StringComparison]::Ordinal)}|Sort-Object)
 $newRv=@($Current.Keys|Where-Object {$_.StartsWith('rv:',[StringComparison]::Ordinal)}|Sort-Object)
 Assert-ExportRepeat (($oldRv-join"`n")-ceq($newRv-join"`n")-and$oldRv.Count-eq3) 'QUEUE11_ROWVERSION_KEYS'
 foreach($key in $oldRv){Assert-ExportRepeat ($Previous[$key][0]-cne$Current[$key][0]) 'QUEUE11_ROWVERSION_CHANGE'}
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
 if($Scenario-ceq'Queue11Upgrade'){
  Assert-ExportRepeat (-not(Test-Path -LiteralPath $ownedRoot)) 'QUEUE11_ROOT_INITIAL_ABSENT'
  $parent=Get-Item -LiteralPath $temporaryParent -ErrorAction Stop
  Assert-ExportRepeat ([IO.Directory]::Exists($temporaryParent)) 'QUEUE11_ROOT_INITIAL_PARENT_DIRECTORY'
  Assert-ExportRepeat (($parent.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0) 'QUEUE11_ROOT_INITIAL_PARENT_REPARSE'
  # Ausschließlich der bestehende Linux-GitHub-CI-Fall; kein Installations-/Fallbackpfad.
  Assert-ExportRepeat ($env:CI-ceq'true'-and$env:GITHUB_ACTIONS-ceq'true'-and$env:RUNNER_OS-ceq'Linux'-and$env:GITHUB_REPOSITORY-ceq'gecompat/SQL_Server_Toolbelt') 'QUEUE11_DIRECTORY_CI_SCOPE'
  $processPath=[IO.Path]::GetFullPath((Join-Path $repositoryRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'))
  $processItem=Get-Item -LiteralPath $processPath -ErrorAction Stop
  Assert-ExportRepeat ([IO.File]::Exists($processPath)-and-not$processItem.PSIsContainer-and($processItem.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0-and(Get-FileHash -LiteralPath $processPath -Algorithm SHA256).Hash-ceq'7B3E838EE5D294B3DECF3153D2D02276BE401E6F76EE8D810F20C5DCC51D1BD4') 'QUEUE11_DIRECTORY_PROCESS_HELPER'
  $queue11DirectoryProcessHelper=[pscustomobject]@{Path=$processPath;Hash='7B3E838EE5D294B3DECF3153D2D02276BE401E6F76EE8D810F20C5DCC51D1BD4'}
  . $processPath
  # Genau die tatsächlich ausgewählte Application binden, ohne PATH-Inventar oder Neuauflösung.
  $commands=@(Get-Command -Name stat -CommandType Application -ErrorAction Stop)
  Assert-ExportRepeat ($commands.Count-eq1-and$commands[0].CommandType-eq[Management.Automation.CommandTypes]::Application-and-not[string]::IsNullOrWhiteSpace($commands[0].Path)) 'QUEUE11_DIRECTORY_TOOL'
  $statPath=[IO.Path]::GetFullPath($commands[0].Path)
  Assert-ExportRepeat ($statPath-ceq$commands[0].Path) 'QUEUE11_DIRECTORY_TOOL'
  $statItem=Get-Item -LiteralPath $statPath -ErrorAction Stop
  Assert-ExportRepeat ([IO.File]::Exists($statPath)-and-not$statItem.PSIsContainer-and($statItem.Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0) 'QUEUE11_DIRECTORY_TOOL'
  $queue11DirectoryTool=[pscustomobject]@{Path=$statPath;Hash=(Get-FileHash -LiteralPath $statPath -Algorithm SHA256).Hash}
  $queue11DirectoryBudget=[pscustomobject]@{ElapsedMilliseconds=0L;ProcessCount=0}
  $parentDirectoryIdentity=Get-Queue11DirectoryIdentities @($temporaryParent)
  $queue11ParentIdentity=[pscustomobject]@{Device=$parentDirectoryIdentity[0].Device;Inode=$parentDirectoryIdentity[0].Inode;Mode=$parentDirectoryIdentity[0].Mode;Attributes=[int]$parent.Attributes}
  $queue11RootCreationAuthorized=$true
 }
 [void][IO.Directory]::CreateDirectory($ownedRoot);Save-PrivateOwnership
 $connection=New-ExportConnection 'master'
 try{
  Invoke-ExportSql $connection 'IF CONVERT(int,SERVERPROPERTY(N''ProductMajorVersion''))<>15 OR ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 OR NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N''Linux'') THROW 54986,N''Der bestehende begrenzte CI-Zielvertrag fehlt.'',1;'
 }finally{$connection.Dispose()}
 if($Scenario-ceq'Queue11Upgrade'){
  $phase='queue11-acquire';Save-PrivateOwnership
  $acquireHelper=Join-Path $runtimeRoot 'Acquire-GenuineQueue11Source.ps1'
  $captureHelper=Join-Path $repositoryRoot 'Workers/ExternalQueue/Tests/Runtime/New-GenuineQueue11Capture.ps1'
  Assert-ExportRepeat ((Get-FileHash -LiteralPath $acquireHelper -Algorithm SHA256).Hash-ceq'A048C2FF03646FC18C95D65222CFE542205ADBB49EF59844D0C4FBE967DDB09B') 'QUEUE11_ACQUIRE_HELPER'
  Assert-ExportRepeat ((Get-FileHash -LiteralPath $captureHelper -Algorithm SHA256).Hash-ceq'0DDE104052907548E6CDD29FEF0CAEC64DCC425E7DFCC418D5B5FA2ED1F52DFF') 'QUEUE11_CAPTURE_HELPER'
  . $acquireHelper
  $acquired=Acquire-GenuineQueue11Source -RepositoryRoot $repositoryRoot -CaptureHelperPath $captureHelper -AcquisitionState $queue11Record.Acquisition -CallerOwnsExclusiveCheckoutBeforeDatabase
  Assert-ExportRepeat ($acquired.Status-ceq'COMMIT_AND_TREES_AVAILABLE_CAPTURE_PENDING'-and$acquired.FetchInvocations-eq1-and$acquired.DatabaseMutationAllowed-eq$false) 'QUEUE11_ACQUIRE_RETURN'
  Assert-ExportRepeat ((Get-FileHash -LiteralPath $acquireHelper -Algorithm SHA256).Hash-ceq'A048C2FF03646FC18C95D65222CFE542205ADBB49EF59844D0C4FBE967DDB09B') 'QUEUE11_ACQUIRE_HELPER'
  Assert-ExportRepeat ((Get-FileHash -LiteralPath $captureHelper -Algorithm SHA256).Hash-ceq'0DDE104052907548E6CDD29FEF0CAEC64DCC425E7DFCC418D5B5FA2ED1F52DFF') 'QUEUE11_CAPTURE_HELPER'
  Save-PrivateOwnership
 }
 foreach($mode in @('local','central')){
  $phase=$mode+'-export';Save-PrivateOwnership
  $exportPath=Join-Path $ownedRoot ($mode+'.sql')
  if($Scenario-ceq'Queue11Upgrade'){Assert-Queue11Path $exportPath;Assert-ExportRepeat (-not(Test-Path -LiteralPath $exportPath)) 'QUEUE11_FILE_BOUNDARY'}
  & (Join-Path $repositoryRoot 'Deployment/Deploy-All.ps1') -DeploymentMode $mode -ModuleId $selectedModules -OutputSqlFile $exportPath *> $null
  $bytes=[IO.File]::ReadAllBytes($exportPath);$text=$utf8.GetString($bytes)
  Assert-ExportRepeat (-not($bytes[0]-eq239-and$bytes[1]-eq187-and$bytes[2]-eq191)) 'EXPORT_BOM'
  $moduleIds=@([regex]::Matches($text,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)$')|ForEach-Object {$_.Groups[1].Value})
  Assert-ExportRepeat (($moduleIds-join ',')-ceq($expectedModules-join ',')) 'EXPORT_CLOSURE'
  if($Scenario-ceq'ParameterMetadata'){
   $endIds=@([regex]::Matches($text,'(?m)^-- END MODULE ([a-z0-9.-]+)$')|ForEach-Object {$_.Groups[1].Value})
   Assert-ExportRepeat (($endIds-join ',')-ceq($expectedModules-join ',')) 'EXPORT_ENDS3'
   Assert-ExportRepeat ([regex]::Matches($text,'IF @@TRANCOUNT <> 0 OR \(2 & @@OPTIONS\) <> 0').Count-eq4) 'EXPORT_GUARDS4'
  }else{
  Assert-ExportRepeat ([regex]::Matches($text,'(?m)^-- END MODULE ').Count-eq9) 'EXPORT_ENDS9'
  Assert-ExportRepeat ([regex]::Matches($text,'IF @@TRANCOUNT <> 0 OR \(2 & @@OPTIONS\) <> 0').Count-eq10) 'EXPORT_GUARDS10'
  }
  $export=[pscustomobject]@{Path=$exportPath;Hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes));BatchCount=@(Get-ExportBatches $text).Count}
  $ownedFiles.Add($export)
  if($Scenario-ceq'Queue11Upgrade'){
   Register-Queue11File $export
   $phase=$mode+'-historical';Save-PrivateOwnership
   $queue11BootstrapPath=Join-Path $ownedRoot ($mode+'-bootstrap.sql')
   Assert-Queue11Path $queue11BootstrapPath
   Assert-ExportRepeat (-not(Test-Path -LiteralPath $queue11BootstrapPath)) 'QUEUE11_FILE_BOUNDARY'
   $queue11Bootstrap=New-UpgradeBootstrap $mode;Register-Queue11File $queue11Bootstrap
   $queue11Historical=New-Queue11HistoricalExport $mode
   Assert-Queue11File $export.Path;Assert-Queue11File $queue11Bootstrap.Path;Assert-Queue11File $queue11Historical.Path
   Assert-Queue11Fixtures
   Save-PrivateOwnership
  }
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
  if($Scenario-ceq'Queue11Upgrade'){
   $phase=$mode+'-bootstrap';Save-PrivateOwnership
   [void](Invoke-Queue11ExportFile $identity $queue11Bootstrap)
   $phase=$mode+'-historical';Save-PrivateOwnership
   [void](Invoke-Queue11ExportFile $identity $queue11Historical)
   $phase=$mode+'-seed';Save-PrivateOwnership;Assert-Queue11Fixtures
   Invoke-OwnedFixture $identity 'ExportQueue11.Setup.sql' @{'@InstallMode'=$mode}
   Invoke-OwnedFixture $identity 'ExportQueue11.Assert.sql' @{'@After'=$false;'@InstallMode'=$mode}
   $previous=Read-Queue11Snapshot $identity $false $mode
   $phase=$mode+'-upgrade';Save-PrivateOwnership
   [void](Invoke-Queue11ExportFile $identity $export)
   Assert-Queue11Fixtures
   Invoke-OwnedFixture $identity 'ExportQueue11.Assert.sql' @{'@After'=$true;'@InstallMode'=$mode}
   $current=Read-Queue11Snapshot $identity $true $mode
   # Sofortiger Legacyvergleich vor jeder weiteren persistenten DML; keine Repeat-/Claimfolge.
   Compare-Queue11Snapshots $previous $current
   Assert-Queue11Fixtures
   $phase=$mode+'-cleanup';Save-PrivateOwnership;Remove-OwnedDatabase $identity
   continue
  }
  if($Scenario-ceq'ParameterMetadata'){
   $phase=$mode+'-install';Save-PrivateOwnership
   [void](Invoke-ExportFile $identity $export)
   $phase=$mode+'-parameter-seed';Save-PrivateOwnership
   Invoke-OwnedFixture $identity 'ExportParameter.Setup.sql'
   Invoke-OwnedFixture $identity 'ExportParameter.Assert.sql'
   $previous=Read-PrivateSnapshot $identity 'ExportParameter.Capture.sql' @{} 0
   $phase=$mode+'-parameter-repeat';Save-PrivateOwnership
   [void](Invoke-ExportFile $identity $export)
   $phase=$mode+'-parameter-verify';Save-PrivateOwnership
   Invoke-OwnedFixture $identity 'ExportParameter.Assert.sql'
   $current=Read-PrivateSnapshot $identity 'ExportParameter.Capture.sql' @{} 0
   Compare-PrivateSnapshots $previous $current
   $phase=$mode+'-cleanup';Save-PrivateOwnership;Remove-OwnedDatabase $identity
   continue
  }
  if($Scenario-ceq'Queue20Upgrade'){
   $phase=$mode+'-bootstrap';Save-PrivateOwnership
   $bootstrap=New-UpgradeBootstrap $mode
   [void](Invoke-ExportFile $identity $bootstrap)
   $phase=$mode+'-historical';Save-PrivateOwnership
   $historical=New-UpgradeHistoricalExport $mode
   [void](Invoke-ExportFile $identity $historical)
   $phase=$mode+'-seed';Save-PrivateOwnership
   Invoke-OwnedFixture $identity 'ExportUpgrade.Setup.sql'
   $previous=Read-PrivateSnapshot $identity 'ExportUpgrade.Capture.sql' @{'@After'=$false} 8
   $phase=$mode+'-upgrade';Save-PrivateOwnership
   [void](Invoke-ExportFile $identity $export)
   Invoke-OwnedFixture $identity 'ExportUpgrade.Assert.sql'
   $current=Read-PrivateSnapshot $identity 'ExportUpgrade.Capture.sql' @{'@After'=$true} 8
   Compare-PrivateSnapshots $previous $current
   # Zusätzliche Wartungswelle NACH dem unveränderten Immediate-109-Feldervergleich.
   # Bestehende Claim-/Lease-/Consumer-Guards bleiben unverändert; nur eigener unmanaged Abschluss.
   Invoke-OwnedFixture $identity 'ExportUpgradeRepeat.Assert.sql' @{'@Completed'=$false}
   $beforeCompletion=Read-PrivateSnapshot $identity 'ExportUpgradeRepeat.Capture.sql' @{'@Completed'=$false} 14
   Invoke-OwnedFixture $identity 'ExportUpgradeRepeat.Complete.sql'
   Invoke-OwnedFixture $identity 'ExportUpgradeRepeat.Assert.sql' @{'@Completed'=$true}
   $afterCompletion=Read-PrivateSnapshot $identity 'ExportUpgradeRepeat.Capture.sql' @{'@Completed'=$true} 14
   # Nur vollständige WorkItem-Zeilen sind im Completionfenster veränderlich.
   # 42 stabile Felder aller drei sowie 46 Felder der beiden anderen WorkItems werden separat verglichen.
   $stableBefore=[Collections.Generic.Dictionary[string,Collections.Generic.List[string]]]::new([StringComparer]::Ordinal)
   $stableAfter=[Collections.Generic.Dictionary[string,Collections.Generic.List[string]]]::new([StringComparer]::Ordinal)
   foreach($key in $beforeCompletion.Keys){if($key-cne'row:toolbelt_core.WorkItem'){$stableBefore.Add($key,$beforeCompletion[$key])}}
   foreach($key in $afterCompletion.Keys){if($key-cne'row:toolbelt_core.WorkItem'){$stableAfter.Add($key,$afterCompletion[$key])}}
   Compare-PrivateSnapshots $stableBefore $stableAfter
   # Genau ein vollständiger Repeat DERSELBEN bereits hashgebundenen Neun-Modul-Exportdatei.
   # Neue private Baseline, keine First-Ausnahme und keine Versionsnormalisierung.
   [void](Invoke-ExportFile $identity $export)
   Invoke-OwnedFixture $identity 'ExportUpgradeRepeat.Assert.sql' @{'@Completed'=$true}
   $afterRepeat=Read-PrivateSnapshot $identity 'ExportUpgradeRepeat.Capture.sql' @{'@Completed'=$true} 14
   Compare-PrivateSnapshots $afterCompletion $afterRepeat
   # Keine weitere DML/Claimadmission nach diesem Repeatorakel; eigene DB vollständig bereinigen.
   $phase=$mode+'-cleanup';Save-PrivateOwnership;Remove-OwnedDatabase $identity
   continue
  }
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
 $failure=Get-SafeFailureDiagnostic $_.Exception $phase
 if($Scenario-ceq'Queue11Upgrade'-and[IO.Directory]::Exists($ownedRoot)){
  $queue11Record.RetainedUnproven=$true;$cleanupFailed=$true
  if($null-eq$cleanupFailure){$cleanupFailure=Get-SafeFailureDiagnostic ([Exception]::new('EXPORT_REPEAT.QUEUE11_RETAINED_UNPROVEN')) 'cleanup'}
 }
 if([IO.Directory]::Exists($ownedRoot)){try{Save-PrivateOwnership}catch{}}
}finally{
 foreach($identity in $identities){if(-not$identity.Dropped){try{Remove-OwnedDatabase $identity}catch{
  $cleanupFailed=$true
  if($null-eq$cleanupFailure){
   $cleanupPhase=if($identity.Name.StartsWith('Toolbelt_ExportRepeat_local_',[StringComparison]::Ordinal)){'local-cleanup'}elseif($identity.Name.StartsWith('Toolbelt_ExportRepeat_central_',[StringComparison]::Ordinal)){'central-cleanup'}else{'cleanup'}
   $cleanupFailure=Get-SafeFailureDiagnostic $_.Exception $cleanupPhase
  }
 }}}
 if([IO.Directory]::Exists($ownedRoot)){
  if($null-ne$failure-or$cleanupFailed){try{Save-PrivateOwnership}catch{$cleanupFailed=$true;if($null-eq$cleanupFailure){$cleanupFailure=Get-SafeFailureDiagnostic $_.Exception 'cleanup'}}}
  else{
   try{
    if($Scenario-ceq'Queue11Upgrade'){
     Assert-Queue11Root;Assert-Queue11Journal
     foreach($path in $queue11FileIdentities.Keys){Assert-Queue11File $path}
    }
    # Alle eigenen Parentverzeichnisse vor der ersten Dateilöschung gegen Umleitung prüfen.
    foreach($directory in $historicalDirectories){
     $resolvedDirectory=[IO.Path]::GetFullPath($directory)
     Assert-ExportRepeat ($resolvedDirectory.StartsWith($ownedRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)-and((Get-Item -LiteralPath $directory).Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0) 'HISTORICAL_DIRECTORY_BOUNDARY'
    }
    foreach($file in $historicalFiles){
     Assert-ExportRepeat ([IO.Path]::GetFullPath($file.Path).StartsWith($ownedRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)) 'HISTORICAL_DIRECTORY_BOUNDARY'
     Assert-HistoricalFile $file;[IO.File]::Delete($file.Path)
    }
    foreach($directory in @($historicalDirectories|Sort-Object Length -Descending)){
     $resolvedDirectory=[IO.Path]::GetFullPath($directory)
     Assert-ExportRepeat ($resolvedDirectory.StartsWith($ownedRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)-and((Get-Item -LiteralPath $directory).Attributes-band[IO.FileAttributes]::ReparsePoint)-eq0) 'HISTORICAL_DIRECTORY_BOUNDARY'
     [IO.Directory]::Delete($resolvedDirectory,$false)
    }
    foreach($file in $ownedFiles){if($Scenario-ceq'Queue11Upgrade'){Assert-Queue11File $file.Path};Assert-ExportRepeat ((Get-FileHash -LiteralPath $file.Path -Algorithm SHA256).Hash-ceq$file.Hash) 'FILE_CLEANUP_DRIFT';[IO.File]::Delete($file.Path)}
    if($Scenario-ceq'Queue11Upgrade'){Assert-Queue11Journal}
    Assert-ExportRepeat ((Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash-ceq$journalHash) 'JOURNAL_CLEANUP_DRIFT';[IO.File]::Delete($journalPath)
    $resolved=[IO.Path]::GetFullPath($ownedRoot)
    Assert-ExportRepeat ([IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetDirectoryName($resolved))-ceq$temporaryParent-and[IO.Path]::GetFileName($resolved)-match'^toolbelt-export-repeat-[0-9a-f]{32}$') 'DIRECTORY_CLEANUP_BOUNDARY'
    if($Scenario-ceq'Queue11Upgrade'){Assert-Queue11Root}
    [IO.Directory]::Delete($resolved,$false)
   }catch{$cleanupFailed=$true;if($null-eq$cleanupFailure){$cleanupFailure=Get-SafeFailureDiagnostic $_.Exception 'cleanup'}}
  }
 }
 $sourceConnection=$null
}
# Nur feste öffentliche Marker; SQLtexte, Resultsets, Ziel-/DBnamen und Exceptions bleiben privat.
if($null-ne$failure){
 [Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_FAILED');Write-SafeFailureDiagnostic $failure
 if($cleanupFailed){[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_CLEANUP_DEFERRED');Write-SafeFailureDiagnostic $cleanupFailure}
 exit 1
}
if($cleanupFailed){[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_CLEANUP_DEFERRED');Write-SafeFailureDiagnostic $cleanupFailure;exit 1}
if($Scenario-ceq'Queue11Upgrade'){[Console]::Out.WriteLine('EXPORT_QUEUE11_UPGRADE_PASS local central SQL2019 CL150 six-legacy-tables genuine1.1-to2.1 original-clean')}
elseif($Scenario-ceq'Queue20Upgrade'){[Console]::Out.WriteLine('EXPORT_QUEUE20_UPGRADE_PASS local central SQL2019 CL150 eight-legacy-tables genuine2.0-to2.1 first-control')}
elseif($Scenario-ceq'ParameterMetadata'){[Console]::Out.WriteLine('EXPORT_PARAMETER_METADATA_PASS local central SQL2019 CL150 three-modules two-procedures eleven-parameters one-cycle')}
else{[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_PASS local central SQL2019 CL150 fourteen-tables two-cycles')}
[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_CLEANUP_VERIFIED')
