# Fokussierte Qualifikation im bereits autorisierten CI-Ziel; kein Targetstart,
# Provideraufruf, Grant oder Konfigurations-/Trusteingriff. Reale Daten bleiben privat.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')][string]$ConnectionStringEnvironmentVariable,
      [ValidateSet('Repeat','Queue20Upgrade','ParameterMetadata')][string]$Scenario='Repeat')
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
$sourceConnection=[Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable,'Process')

function Assert-ExportRepeat([bool]$Condition,[string]$Code){if(-not$Condition){throw ('EXPORT_REPEAT.'+$Code)}}
function Get-SafeFailureDiagnostic([Exception]$Exception,[string]$Phase) {
 # Ausschließlich feste Quellcode-Tokens und Phasen publizieren, keine freien Exceptiontexte.
 $allowedPhases=@('preflight','cleanup','local-export','local-create','local-install','local-seed','local-repeat1','local-repeat2','local-cleanup','central-export','central-create','central-install','central-seed','central-repeat1','central-repeat2','central-cleanup','local-bootstrap','local-historical','local-upgrade','central-bootstrap','central-historical','central-upgrade','local-parameter-seed','local-parameter-repeat','local-parameter-verify','central-parameter-seed','central-parameter-repeat','central-parameter-verify')
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
  'PARAMETER_COUNT_BINDING','EXPORT_ENDS3','EXPORT_GUARDS4'
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
    foreach($file in $ownedFiles){Assert-ExportRepeat ((Get-FileHash -LiteralPath $file.Path -Algorithm SHA256).Hash-ceq$file.Hash) 'FILE_CLEANUP_DRIFT';[IO.File]::Delete($file.Path)}
    Assert-ExportRepeat ((Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash-ceq$journalHash) 'JOURNAL_CLEANUP_DRIFT';[IO.File]::Delete($journalPath)
    $resolved=[IO.Path]::GetFullPath($ownedRoot)
    Assert-ExportRepeat ([IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetDirectoryName($resolved))-ceq$temporaryParent-and[IO.Path]::GetFileName($resolved)-match'^toolbelt-export-repeat-[0-9a-f]{32}$') 'DIRECTORY_CLEANUP_BOUNDARY'
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
if($Scenario-ceq'Queue20Upgrade'){[Console]::Out.WriteLine('EXPORT_QUEUE20_UPGRADE_PASS local central SQL2019 CL150 eight-legacy-tables genuine2.0-to2.1 first-control')}
elseif($Scenario-ceq'ParameterMetadata'){[Console]::Out.WriteLine('EXPORT_PARAMETER_METADATA_PASS local central SQL2019 CL150 three-modules two-procedures eleven-parameters one-cycle')}
else{[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_PASS local central SQL2019 CL150 fourteen-tables two-cycles')}
[Console]::Out.WriteLine('EXPORT_POPULATED_REPEAT_CLEANUP_VERIFIED')
