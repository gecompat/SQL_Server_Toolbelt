[CmdletBinding()]
param(
 [ValidateSet('linux','windows')][string]$Platform='linux',
 [ValidateSet('2019','2022','2025')][string]$Version='2019',
 [string]$Patch='latest',
 [Parameter(Mandatory)][string]$ReleaseDirectory,
 [Parameter(Mandatory)][string]$LegacyDirectory,
 [Parameter(Mandatory)][string]$Legacy11Directory,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedLegacy11ProvenanceSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedPromptSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedDriverSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{128}$')][string]$ExpectedAssemblySHA512,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedLegacyProvenanceSHA256,
 [ValidateSet('local','central')][string[]]$DeploymentModes=@('local','central'),
 [ValidateSet('Types.Contract.sql','Types.Safety.sql','Types.Lifecycle.sql','Display.Contract.sql','Display.Safety.sql','Display.Lifecycle.sql')]
 [string[]]$RuntimeTests=@('Types.Contract.sql','Types.Safety.sql','Types.Lifecycle.sql','Display.Contract.sql','Display.Safety.sql','Display.Lifecycle.sql'),
 [switch]$OptInExactTrust
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=$null;$module=$null
$stage='PREPARATION';$batchIndex=0
$script:scopeClock=$null;$script:cleanupPhase=$false
$script:workMilliseconds=960000L;$script:totalMilliseconds=1200000L
function Get-XlsxCommandTimeout {
 param([ValidateRange(1,60)][int]$Maximum=60)
 if($null -eq $script:scopeClock){throw 'XLSX_SCOPE_CLOCK_REQUIRED'}
 $limit=if($script:cleanupPhase){$script:totalMilliseconds}else{$script:workMilliseconds}
 $remaining=$limit-$script:scopeClock.ElapsedMilliseconds
 if($remaining -lt 1000){throw 'XLSX_SCOPE_DEADLINE'}
 return [int][Math]::Min($Maximum,[Math]::Floor($remaining/1000))
}
function Assert-XlsxReadBudget($Command){
 try{[void](Get-XlsxCommandTimeout)}catch{try{$Command.Cancel()}catch{};throw}
}
function Invoke-XlsxOwnSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 # Nur administrative OwnScope-Batches; Original-Produkt-DDL bleibt direkt.
 $prefix="IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;"+[Environment]::NewLine
 Invoke-XlsxSql $Connection ($prefix+$Sql) $Parameters -Rows:$Rows
}

# Keine ungefilterten Fehlerrecords oder SQL-Texte nach außen weiterreichen.
function Get-XlsxFailure($Exception){
 $sql=$null;$cursor=$Exception
 while($null -ne $cursor){if($cursor -is [Data.SqlClient.SqlException]){$sql=$cursor};$cursor=$cursor.InnerException}
 [ordered]@{Stage=$script:stage;Batch=$script:batchIndex;SqlNumber=$(if($sql){$sql.Number}else{0});SqlState=$(if($sql){$sql.State}else{0})}
}
function Invoke-XlsxSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 $timeout=Get-XlsxCommandTimeout
 $command=$Connection.CreateCommand();$command.CommandTimeout=$timeout;$command.CommandText=$Sql
 try{
  foreach($name in $Parameters.Keys){
   $value=$Parameters[$name]
   if($value -is [byte[]]){$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::VarBinary,-1)}
   elseif($value -is [int]){$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::Int)}
   else{$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::NVarChar,-1)}
   $parameter.Value=$value
  }
  $reader=$command.ExecuteReader()
  try{
   $result=[Collections.Generic.List[object]]::new()
   do{Assert-XlsxReadBudget $command;while($reader.Read()){
    Assert-XlsxReadBudget $command
    if($Rows){$record=[ordered]@{};for($index=0;$index -lt $reader.FieldCount;$index++){$record[$reader.GetName($index)]=$reader.GetValue($index)};$result.Add([pscustomobject]$record)}
    else{for($index=0;$index -lt $reader.FieldCount;$index++){[void]$reader.GetValue($index)}}
   };Assert-XlsxReadBudget $command}while($reader.NextResult())
   if($Rows){return $result.ToArray()}
  }finally{$reader.Dispose()}
 }finally{$command.Dispose()}
}
function Read-XlsxSql([string]$Path,[hashtable]$Variables){
 $text=[IO.File]::ReadAllText($Path)
 $text=[regex]::Replace($text,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{param($match)
  Read-XlsxSql (Join-Path (Split-Path -Parent $Path) $match.Groups[1].Value.Trim()) $Variables
 })
 $text=[regex]::Replace($text,'(?im)^\s*:On\s+Error\s+exit\s*$','')
 foreach($key in $Variables.Keys){$text=$text.Replace('$('+ $key +')',[string]$Variables[$key])}
 if($text -match '(?m)^\s*:' -or $text -match '\$\('){throw 'XLSX_SQL_TEMPLATE_UNRESOLVED'}
 return $text
}
function Invoke-XlsxBatches($Connection,[string]$Sql){
 $script:batchIndex=0
 foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
  if(-not [string]::IsNullOrWhiteSpace($batch)){$script:batchIndex++;Invoke-XlsxSql $Connection $batch}
 }
}
function Open-XlsxConnection($Target,[string]$Database){
 $builder=$null;$connection=$null
 try{
  $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString $Target))
  $builder['Initial Catalog']=$Database;$builder['Pooling']=$false;$builder['Enlist']=$false
  $builder['ConnectRetryCount']=0;$builder['Connect Timeout']=Get-XlsxCommandTimeout 15
  $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
  $connection.Open();return $connection
 }catch{if($connection){try{$connection.Dispose()}catch{}};throw}
 finally{if($builder){try{$builder.Clear()}catch{}}}
}
function Save-XlsxJournal{
 try{
  $temporary=$script:journal+'.writing'
  [IO.File]::WriteAllText($temporary,($script:ledger|ConvertTo-Json -Depth 9),[Text.UTF8Encoding]::new($false))
  [IO.File]::Move($temporary,$script:journal,$true)
 }catch{$script:journalHealthy=$false;throw 'XLSX_PRIVATE_JOURNAL_FAILED'}
}
function Get-XlsxTrust($Connection,[byte[]]$Hash){
 # Vollständige datetime2(7)-Bytes: binary(8) wäre eine Trunkierung.
 $rows=@(Invoke-XlsxOwnSql $Connection @'
SELECT description,CONVERT(varchar(64),HASHBYTES('SHA2_256',
 hash+CONVERT(binary(4),ISNULL(DATALENGTH(description),-1))+ISNULL(CONVERT(varbinary(max),description),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(CONVERT(varbinary(max),create_date)),-1))+ISNULL(CONVERT(varbinary(max),create_date),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(created_by),-1))+ISNULL(CONVERT(varbinary(max),created_by),0x)),2) Fingerprint
FROM sys.trusted_assemblies WHERE hash=@Hash;
'@ @{'@Hash'=$Hash} -Rows)
 if($rows.Count -gt 1){throw 'XLSX_TRUST_MULTIPLE'}
 if($rows.Count){if($rows[0].Fingerprint -is [DBNull] -or $rows[0].Fingerprint -notmatch '^[A-F0-9]{64}$'){throw 'XLSX_TRUST_FINGERPRINT_INVALID'};return $rows[0]}
 return $null
}
function Register-XlsxTrust($Control,$Artifact){
 $hash=[Convert]::FromHexString($Artifact.Hash);$existing=Get-XlsxTrust $Control $hash
 $entry=[ordered]@{Hash=$Artifact.Hash;State='PREEXISTING';Preexisting=$true;Description=$null;Fingerprint=$null}
 $script:ledger.Trust+=@($entry);Save-XlsxJournal
 if($existing){
  $entry.Description=if($existing.description -is [DBNull]){$null}else{[string]$existing.description}
  $entry.Fingerprint=[string]$existing.Fingerprint;Save-XlsxJournal;return
 }
 if(-not $OptInExactTrust){throw 'XLSX_EXACT_TRUST_REQUIRED'}
 Assert-XlsxTrustCleanupScope $Control $hash
 $entry.Preexisting=$false;$entry.State='ADDING';$entry.Description='Toolbelt synthetic XLSX types '+$script:ledger.RunId+' '+$Artifact.Label
 Save-XlsxJournal
 Invoke-XlsxOwnSql $Control @'
IF @Hash IS NULL OR DATALENGTH(@Hash)<>64 OR @Description IS NULL OR DATALENGTH(@Description)>8000
 THROW 51591,N'Typed trust arguments invalid.',11;
DECLARE @TrustHash varbinary(64)=@Hash,@TrustDescription nvarchar(4000)=@Description;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash)
 EXEC sys.sp_add_trusted_assembly @hash=@TrustHash,@description=@TrustDescription;
'@ @{'@Hash'=$hash;'@Description'=$entry.Description}
 $actual=Get-XlsxTrust $Control $hash
 if($null -eq $actual -or $actual.description -is [DBNull] -or [string]$actual.description -cne $entry.Description){$entry.State='IDENTITY_UNKNOWN';Save-XlsxJournal;throw 'XLSX_TRUST_IDENTITY_UNKNOWN'}
 $entry.Fingerprint=$actual.Fingerprint;$entry.State='OWNED';Save-XlsxJournal
}
function Assert-XlsxTrustCleanupScope($Control,[byte[]]$Hash){
 # Vor eigenem ADD prüfen, ob alle später benötigten Verbraucherprüfungen
 # tatsächlich lesbar sind. Vorbestehende Trustzeilen bleiben unberührt.
 Invoke-XlsxSql $Control @'
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;
IF EXISTS(SELECT 1 FROM sys.databases WHERE state<>0) THROW 51591,N'Consumer inspection uncertain.',6;
DECLARE @Databases TABLE(Id int PRIMARY KEY,Name sysname,Created varbinary(16));
INSERT @Databases SELECT database_id,name,CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases;
DECLARE @Name sysname,@Sql nvarchar(max),@Count int;
DECLARE Consumers CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM @Databases;
OPEN Consumers;FETCH NEXT FROM Consumers INTO @Name;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Count=NULL;
 SET @Sql=N'SELECT @Count=COUNT(*) FROM '+QUOTENAME(@Name)+N'.sys.assembly_files WHERE file_id=1 AND HASHBYTES(''SHA2_512'',content)=@Hash;';
 EXEC sys.sp_executesql @Sql,N'@Hash varbinary(64),@Count int OUTPUT',@Hash,@Count OUTPUT;
 IF @Count IS NULL OR @Count<>0 THROW 51591,N'Hash consumer remains or inspection uncertain.',7;
 FETCH NEXT FROM Consumers INTO @Name;
END;
CLOSE Consumers;DEALLOCATE Consumers;
IF EXISTS(SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases
 EXCEPT SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases)
 OR EXISTS(SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases
 EXCEPT SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases)
 THROW 51591,N'Consumer inspection changed.',8;
'@ @{'@Hash'=$Hash}
}
function New-XlsxDatabase($Control,$Target,[string]$Label,[string]$Collation){
 $name='Toolbelt_XlsxTypes_'+[guid]::NewGuid().ToString('N')
 $entry=[ordered]@{Name=$name;Label=$Label;State='CREATING';Id=$null;Creation=$null;Marker=$false}
 $script:ledger.Databases+=@($entry);Save-XlsxJournal
 Invoke-XlsxOwnSql $Control ("IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Synthetic database collision.',1; CREATE DATABASE [$name] COLLATE $Collation;")
 $connection=Open-XlsxConnection $Target $name
 try{
  Invoke-XlsxOwnSql $connection 'DECLARE @MarkerOwner nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Toolbelt.Test.XlsxTypes.Owner'',@value=@MarkerOwner;' @{'@Owner'=$script:ledger.RunId}
  $identity=@(Invoke-XlsxOwnSql $connection @'
SELECT DB_ID() Id,CONVERT(varchar(32),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)),2) Creation,
 (SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Test.XlsxTypes.Owner'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner)) MarkerCount
FROM sys.databases WHERE database_id=DB_ID();
'@ @{'@Owner'=$script:ledger.RunId} -Rows)
  if($identity.Count -ne 1 -or $identity[0].MarkerCount -ne 1 -or $identity[0].Creation -notmatch '^[A-F0-9]{18}$'){throw 'XLSX_DATABASE_IDENTITY_UNKNOWN'}
  $entry.Id=[int]$identity[0].Id;$entry.Creation=$identity[0].Creation;$entry.Marker=$true;$entry.State='OWNED';Save-XlsxJournal
 }finally{$connection.Dispose()}
 return $name
}
function Remove-XlsxOwnedDatabase($Control,$Entry){
 if($Entry.State -eq 'DROPPED'){return}
 if(-not $Entry.Marker -or $null -eq $Entry.Id -or $null -eq $Entry.Creation){throw 'XLSX_DATABASE_CLEANUP_IDENTITY_UNKNOWN'}
 $name=$Entry.Name
 if($name -notmatch '^Toolbelt_XlsxTypes_[a-f0-9]{32}$'){throw 'XLSX_DATABASE_CLEANUP_NAME_INVALID'}
 Invoke-XlsxOwnSql $Control @"
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Created)
 THROW 51591,N'Owned database identity changed.',2;
DECLARE @MarkerCount int;
EXEC [$name].sys.sp_executesql N'SELECT @Count=COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N''Toolbelt.Test.XlsxTypes.Owner'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner);',
 N'@Owner nvarchar(32),@Count int OUTPUT',@Owner,@MarkerCount OUTPUT;
IF @MarkerCount IS NULL OR @MarkerCount<>1 THROW 51591,N'Owned database marker changed.',3;
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Created)
 THROW 51591,N'Owned database identity changed before removal.',2;
DROP DATABASE [$name];
IF DB_ID(@Name) IS NOT NULL THROW 51591,N'Owned database removal not verified.',4;
"@ @{'@Id'=[int]$Entry.Id;'@Name'=$name;'@Created'=[Convert]::FromHexString($Entry.Creation);'@Owner'=$script:ledger.RunId}
 $Entry.State='DROPPED';Save-XlsxJournal
}
function Remove-XlsxOwnedTrust($Control,$Entry){
 if($Entry.Preexisting){
  $actual=Get-XlsxTrust $Control ([Convert]::FromHexString($Entry.Hash))
  if($Entry.State -cne 'PREEXISTING' -or $null -eq $Entry.Fingerprint -or $null -eq $actual -or [string]$actual.Fingerprint -cne $Entry.Fingerprint){throw 'XLSX_PREEXISTING_TRUST_CHANGED'}
  return
 }
 if($Entry.State -eq 'RESTORED'){return}
 if($Entry.State -cne 'OWNED' -or $null -eq $Entry.Fingerprint){throw 'XLSX_TRUST_CLEANUP_IDENTITY_UNKNOWN'}
 # Kein Verbraucher, keine unbekannte/offline Datenbank; unmittelbar derselbe
 # Batch prüft die eigene vollständige Identität vor der administrativen Entfernung.
 Invoke-XlsxSql $Control @'
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;
IF EXISTS(SELECT 1 FROM sys.databases WHERE state<>0) THROW 51591,N'Consumer inspection uncertain.',6;
DECLARE @Databases TABLE(Id int PRIMARY KEY,Name sysname,Created varbinary(16));
INSERT @Databases SELECT database_id,name,CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases;
DECLARE @Name sysname,@Sql nvarchar(max),@Count int;
DECLARE Consumers CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM @Databases;
OPEN Consumers;FETCH NEXT FROM Consumers INTO @Name;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Count=NULL;
 SET @Sql=N'SELECT @Count=COUNT(*) FROM '+QUOTENAME(@Name)+N'.sys.assembly_files WHERE file_id=1 AND HASHBYTES(''SHA2_512'',content)=@Hash;';
 EXEC sys.sp_executesql @Sql,N'@Hash varbinary(64),@Count int OUTPUT',@Hash,@Count OUTPUT;
 IF @Count IS NULL OR @Count<>0 THROW 51591,N'Hash consumer remains or inspection uncertain.',7;
 FETCH NEXT FROM Consumers INTO @Name;
END;
CLOSE Consumers;DEALLOCATE Consumers;
IF EXISTS(SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases
 EXCEPT SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases)
 OR EXISTS(SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases
 EXCEPT SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases)
 THROW 51591,N'Consumer inspection changed.',8;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash
 AND CONVERT(varbinary(max),description)=CONVERT(varbinary(max),@Description)
 AND CONVERT(varchar(64),HASHBYTES('SHA2_256',hash+CONVERT(binary(4),ISNULL(DATALENGTH(description),-1))+ISNULL(CONVERT(varbinary(max),description),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(CONVERT(varbinary(max),create_date)),-1))+ISNULL(CONVERT(varbinary(max),create_date),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(created_by),-1))+ISNULL(CONVERT(varbinary(max),created_by),0x)),2)=@Fingerprint)
 THROW 51591,N'Owned trust identity changed.',9;
IF @Hash IS NULL OR DATALENGTH(@Hash)<>64 THROW 51591,N'Typed trust hash invalid.',12;
DECLARE @TrustHash varbinary(64)=@Hash;
EXEC sys.sp_drop_trusted_assembly @hash=@TrustHash;
IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash) THROW 51591,N'Owned trust removal not verified.',10;
'@ @{'@Hash'=[Convert]::FromHexString($Entry.Hash);'@Description'=$Entry.Description;'@Fingerprint'=$Entry.Fingerprint}
 $Entry.State='RESTORED';Save-XlsxJournal
}
function Assert-XlsxDisposition($Control){
 foreach($entry in $script:ledger.Databases){
  if($entry.State -cne 'DROPPED' -or $entry.Name -notmatch '^Toolbelt_XlsxTypes_[a-f0-9]{32}$'){throw 'XLSX_FINAL_DATABASE_STATE'}
  $rows=@(Invoke-XlsxOwnSql $Control 'SELECT DB_ID(@Name) Id;' @{'@Name'=[string]$entry.Name} -Rows)
  if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'XLSX_FINAL_DATABASE_PRESENT'}
 }
 foreach($entry in $script:ledger.Trust){
  $actual=Get-XlsxTrust $Control ([Convert]::FromHexString($entry.Hash))
  if($entry.Preexisting){
   if($entry.State -cne 'PREEXISTING' -or $null -eq $entry.Fingerprint -or $null -eq $actual -or [string]$actual.Fingerprint -cne $entry.Fingerprint){throw 'XLSX_PREEXISTING_TRUST_CHANGED'}
  }elseif($entry.State -cne 'RESTORED' -or $null -ne $actual){throw 'XLSX_FINAL_OWN_TRUST_PRESENT'}
 }
}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){
 $caught=$false
 try{Invoke-XlsxBatches $Connection $Sql}catch{$failure=Get-XlsxFailure $_.Exception;if($failure.SqlNumber -ne $Number){throw};$caught=$true}
 if(-not $caught){throw 'XLSX_REJECTION_NOT_OBSERVED'}
}
function Get-XlsxSnapshot($Connection){
 $rows=@(Invoke-XlsxSql $Connection @'
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT o.name,o.type,m.definition,CONVERT(varchar(max),a.content,2) AssemblyContent
 FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 LEFT JOIN sys.assembly_modules am ON am.object_id=o.object_id LEFT JOIN sys.assembly_files a ON a.assembly_id=am.assembly_id AND a.file_id=1
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') ORDER BY o.name FOR XML RAW,BINARY BASE64))),2) Objects,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT class,major_id,minor_id,name,CONVERT(nvarchar(max),value) value FROM sys.extended_properties
 WHERE name LIKE N'Toolbelt.Module%' ORDER BY class,major_id,minor_id,name FOR XML RAW,BINARY BASE64))),2) Markers;
'@ -Rows)
 if($rows.Count -ne 1 -or $rows[0].Objects -is [DBNull] -or $rows[0].Markers -is [DBNull]){throw 'XLSX_SNAPSHOT_INVALID'}
 return [string]$rows[0].Objects+':'+[string]$rows[0].Markers
}
# Private Testvorbereitung; Funktionen benötigen den separat geprüften Adapter.
# Kein Top-level-SQL, keine automatische Installation oder Rechteänderung.
function Get-XlsxCompleteSnapshotSql {
 @'
SELECT @Snapshot=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT o.object_id,o.name,o.type,m.definition,
  (SELECT p.name,p.minor_id,CONVERT(nvarchar(max),p.value) value FROM sys.extended_properties p
   WHERE p.class=1 AND p.major_id=o.object_id ORDER BY p.name,p.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES) properties
 FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') ORDER BY o.name FOR JSON PATH,INCLUDE_NULL_VALUES))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT class,major_id,minor_id,name,CONVERT(nvarchar(max),value) value FROM sys.extended_properties
 WHERE (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.file.xlsx-memory.%')
 OR (class=3 AND major_id=SCHEMA_ID(N'toolbelt_file'))
 OR (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory'))
 ORDER BY class,major_id,minor_id,name FOR JSON PATH,INCLUDE_NULL_VALUES))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT a.assembly_id,a.name,a.permission_set,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) BinaryHash
 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_File_XlsxMemory' FOR JSON PATH,INCLUDE_NULL_VALUES))),2)
 +'|'+COALESCE(CONVERT(varchar(12),SCHEMA_ID(N'toolbelt_file')),'ABSENT');
'@
}
function Assert-XlsxCallerPrepared($Connection,[string]$Deploy,[string]$Uninstall,[string]$Abort,[bool]$Doomed){
 $installers=@(([regex]::Split($Deploy,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0],([regex]::Split($Uninstall,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0])
 if($Doomed){
  $index=0
  foreach($installer in $installers){
   $setup=@'
CREATE TABLE #XlsxCaller(Value int NOT NULL CHECK(Value>0));
DECLARE @XlsxOptions int,@XlsxBefore nvarchar(max),@XlsxAfter nvarchar(max),@XlsxRejected bit=0;
BEGIN TRY
 BEGIN TRAN;INSERT #XlsxCaller VALUES(7);
 SET XACT_ABORT ON;
 BEGIN TRY INSERT #XlsxCaller VALUES(-1);END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW;END CATCH;
 IF @XlsxAbort=N'OFF' SET XACT_ABORT OFF;ELSE SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 THROW 51592,N'Caller doom not established.',1;
 SET @XlsxOptions=@@OPTIONS;
 EXEC sys.sp_executesql @XlsxSnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@XlsxBefore OUTPUT;
 BEGIN TRY
'@
   $tail=@'
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()<>50000 OR ERROR_STATE()<>1
   OR LEFT(ERROR_MESSAGE(),LEN(@XlsxPrefix))<>@XlsxPrefix THROW 51592,N'Caller error oracle mismatch.',2;
  SET @XlsxRejected=1;
 END CATCH;
 IF @XlsxRejected<>1 OR @@TRANCOUNT<>1 OR XACT_STATE()<>-1 OR @@OPTIONS<>@XlsxOptions
  OR (SELECT COUNT(*) FROM #XlsxCaller)<>1 OR (SELECT SUM(Value) FROM #XlsxCaller)<>7
  THROW 51592,N'Caller state changed.',3;
 EXEC sys.sp_executesql @XlsxSnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@XlsxAfter OUTPUT;
 IF @XlsxBefore IS NULL OR @XlsxAfter IS NULL OR CONVERT(varbinary(max),@XlsxBefore)<>CONVERT(varbinary(max),@XlsxAfter)
  THROW 51592,N'Caller metadata changed.',4;
 ROLLBACK;DROP TABLE #XlsxCaller;
 SELECT CONVERT(int,1) Witness,@XlsxIndex InstallerIndex;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF OBJECT_ID(N'tempdb..#XlsxCaller') IS NOT NULL DROP TABLE #XlsxCaller;
 THROW;
END CATCH;
'@
   # Die Originalbytes des Erstbatches bleiben unverändert als Teilstring;
   # kein EXEC des Installers. RETURN ohne CATCH würde die Witnesszeile überspringen.
   $sql=$setup+"`n"+$installer+"`n"+$tail
   $rows=@(Invoke-XlsxSql $Connection $sql @{'@XlsxAbort'=$Abort;'@XlsxPrefix'='TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:';'@XlsxSnapshotSql'=(Get-XlsxCompleteSnapshotSql);'@XlsxIndex'=[int]$index} -Rows)
   if($rows.Count -ne 1 -or $rows[0].Witness -ne 1 -or $rows[0].InstallerIndex -ne $index){throw 'XLSX_DOOM_CALLER_WITNESS_MISSING'}
   $index++
  }
  return
 }
 try{
  Invoke-XlsxSql $Connection ("SET XACT_ABORT $Abort;CREATE TABLE #XlsxCaller(Value int NOT NULL CHECK(Value>0));BEGIN TRAN;INSERT #XlsxCaller VALUES(7);")
  $before=Get-XlsxSnapshot $Connection
  $baseline=@(Invoke-XlsxSql $Connection 'SELECT @@OPTIONS Options;' -Rows)
  if($baseline.Count -ne 1){throw 'XLSX_CALLER_OPTIONS_SHAPE'}
  foreach($installer in $installers){
   $caught=$false
   # Direkter Clientbatch ohne SQL-CATCH-/EXEC-Hülle um RAISERROR.
   try{Invoke-XlsxSql $Connection $installer}catch{
    $sqlError=$null;$cursor=$_.Exception
    while($cursor){if($cursor -is [Data.SqlClient.SqlException]){$sqlError=$cursor};$cursor=$cursor.InnerException}
    if($null -eq $sqlError -or $sqlError.Errors.Count -lt 1){throw 'XLSX_CALLER_ERROR_MISSING'}
    foreach($errorEntry in $sqlError.Errors){
     if($errorEntry.Number -ne 50000 -or $errorEntry.State -ne 1 -or -not $errorEntry.Message.StartsWith('TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:',[StringComparison]::Ordinal)){throw 'XLSX_CALLER_ERROR_ORACLE_MISMATCH'}
    }
    $caught=$true
   }
   $state=@(Invoke-XlsxSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState,@@OPTIONS Options,(SELECT COUNT(*) FROM #XlsxCaller) SentinelCount,(SELECT SUM(Value) FROM #XlsxCaller) SentinelSum;' -Rows)
   if(-not $caught -or $state.Count -ne 1 -or $state[0].TranCount -ne 1 -or $state[0].TranState -ne 1 -or $state[0].Options -ne $baseline[0].Options -or $state[0].SentinelCount -ne 1 -or $state[0].SentinelSum -ne 7){throw 'XLSX_INTACT_CALLER_STATE_CHANGED'}
   if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_INTACT_CALLER_METADATA_CHANGED'}
  }
 }finally{Invoke-XlsxSql $Connection 'IF @@TRANCOUNT>0 ROLLBACK;IF OBJECT_ID(N''tempdb..#XlsxCaller'') IS NOT NULL DROP TABLE #XlsxCaller;'}
}
function Assert-XlsxLockPrepared($Target,[string]$Database,$Connection,[string]$Deploy,[string]$Uninstall){
 $holder=Open-XlsxConnection $Target $Database
 try{
  Invoke-XlsxSql $holder @'
BEGIN TRAN;
DECLARE @Result int;
EXEC @Result=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.xlsx-memory',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @Result<0 THROW 51592,N'Synthetic holder lock not acquired.',5;
'@
  foreach($scriptText in @($Deploy,$Uninstall)){
   $before=Get-XlsxSnapshot $Connection
   Assert-XlsxRejected $Connection $scriptText 51533
   if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_LOCK_METADATA_CHANGED'}
   $state=@(Invoke-XlsxSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
   if($state.Count -ne 1 -or $state[0].TranCount -ne 0 -or $state[0].TranState -ne 0){throw 'XLSX_LOCK_TRANSACTION_LEFT'}
  }
 }finally{
  try{if($holder.State -eq [Data.ConnectionState]::Open){Invoke-XlsxSql $holder 'IF @@TRANCOUNT>0 ROLLBACK;'}}finally{$holder.Dispose()}
 }
}
function Assert-XlsxRollbackPrepared($Connection,[string]$Deploy,[string]$Uninstall){
 $deployNeedle=' DROP FUNCTION IF EXISTS toolbelt_file.TVF_InterpretXlsxCell;'
 $uninstallNeedle='  DROP FUNCTION toolbelt_file.TVF_InternalInterpretXlsxCell;'
 $injected=[Collections.Generic.List[string]]::new()
 foreach($item in @(@{Text=$Deploy;Needle=$deployNeedle},@{Text=$Uninstall;Needle=$uninstallNeedle})){
  if(([regex]::Matches($item.Text,[regex]::Escape($item.Needle))).Count -ne 1){throw 'XLSX_POSTDROP_SEAM_AMBIGUOUS'}
  $injected.Add($item.Text.Replace($item.Needle,$item.Needle+"`n THROW 51592,N'Synthetic postDROP fault.',6;"))
 }
 foreach($text in @($Deploy,$Uninstall)){
  # Nur die exakte Installerzeile; Raw-USP-Commits in Includes bleiben unverändert.
  $matches=[regex]::Matches($text,'(?m)^ COMMIT TRANSACTION;\r?$')
  if($matches.Count -ne 1){throw 'XLSX_COMMIT_SEAM_AMBIGUOUS'}
  $injected.Add($text.Insert($matches[0].Index," THROW 51592,N'Synthetic preCOMMIT fault.',6;`n"))
 }
 foreach($text in $injected){
  $before=Get-XlsxSnapshot $Connection;Assert-XlsxRejected $Connection $text 51592
  if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_ROLLBACK_METADATA_CHANGED'}
  $state=@(Invoke-XlsxSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
  if($state.Count -ne 1 -or $state[0].TranCount -ne 0 -or $state[0].TranState -ne 0){throw 'XLSX_ROLLBACK_TRANSACTION_LEFT'}
 }
}
function Get-XlsxForeignSlotPrepared($Connection,[string]$Name){
 $rows=@(Invoke-XlsxSql $Connection @'
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT o.object_id,o.name,o.type,m.definition,
 (SELECT p.name,CONVERT(nvarchar(max),p.value) value FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id
 ORDER BY p.name,p.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES) properties
 FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(@Name)) FOR JSON PATH,INCLUDE_NULL_VALUES))),2) Hash,
 (SELECT COUNT(*) FROM sys.objects WHERE object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(@Name))) Present;
'@ @{'@Name'=$Name} -Rows)
 if($rows.Count -ne 1 -or $rows[0].Present -ne 1 -or $rows[0].Hash -is [DBNull]){throw 'XLSX_FOREIGN_SLOT_SNAPSHOT_INVALID'}
 return [string]$rows[0].Hash
}
function Invoke-XlsxHistoricalFuturePrepared($Target,[string]$Database,$Connection,[hashtable]$Variables,[string]$Deploy,[string]$Uninstall,[string]$LegacyDeploy){
 # Eingang: genuine 1.0 auf frischer Session. Ausgang: wieder genuine 1.0
 # auf neuer Session; der Caller übernimmt und disposed die Rückgabeverbindung.
 try{
  foreach($fault in @('FuturePublic','ImitatedFuturePublic','FutureInternal','ImitatedFutureInternal')){
   $variablesCopy=$Variables.Clone();$variablesCopy.FaultCase=$fault
   $fixture=[regex]::Replace((Read-XlsxSql (Join-Path $module 'Tests/Runtime/Types.CollisionFixture.sql') $variablesCopy),'(?im)^\s*GO\s*$','')
   $oracle=@(Invoke-XlsxSql $Connection $fixture -Rows)
   if($oracle.Count -ne 1 -or $oracle[0].ExpectedError -ne 51534 -or [string]::IsNullOrEmpty($oracle[0].RestoreSql)){throw 'XLSX_FUTURE_ORACLE_SHAPE'}
   $name=if($fault.EndsWith('Public',[StringComparison]::Ordinal)){'TVF_InterpretXlsxCell'}else{'TVF_InternalInterpretXlsxCell'}
   $before=Get-XlsxSnapshot $Connection;Assert-XlsxRejected $Connection $Deploy 51534
   if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_FUTURE_DEPLOY_CHANGED'}
   $foreign=Get-XlsxForeignSlotPrepared $Connection $name
   Invoke-XlsxBatches $Connection $Uninstall
   if((Get-XlsxForeignSlotPrepared $Connection $name) -cne $foreign){throw 'XLSX_HISTORICAL_FUTURE_LOST'}
   $absent=@(Invoke-XlsxSql $Connection "SELECT COUNT(*) Count FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory';" -Rows)
   if($absent.Count -ne 1 -or $absent[0].Count -ne 0){throw 'XLSX_HISTORICAL_UNINSTALL_ASSEMBLY_REMAINS'}
   Invoke-XlsxBatches $Connection $oracle[0].RestoreSql
   Invoke-XlsxBatches $Connection $LegacyDeploy
   $Connection.Dispose();$Connection=Open-XlsxConnection $Target $Database
  }
  return $Connection
 }catch{if($Connection){try{$Connection.Dispose()}catch{}};throw}
}
function Invoke-XlsxDisplayFuturePrepared($Target,[string]$Database,$Connection,[hashtable]$Variables,[string]$Deploy,[string]$Uninstall,[string]$LegacyDeploy){
 # Eingang: genuine predecessor auf frischer Session. Ausgang: wieder genuine predecessor
 # auf neuer Session; der Caller übernimmt und disposed die Rückgabeverbindung.
 try{
  foreach($fault in @('FuturePublic','ImitatedFuturePublic','FutureInternal','ImitatedFutureInternal')){
   $variablesCopy=$Variables.Clone();$variablesCopy.FaultCase=$fault
   $fixture=[regex]::Replace((Read-XlsxSql (Join-Path $module 'Tests/Runtime/Display.CollisionFixture.sql') $variablesCopy),'(?im)^\s*GO\s*$','')
   $oracle=@(Invoke-XlsxSql $Connection $fixture -Rows)
   if($oracle.Count -ne 1 -or $oracle[0].ExpectedError -ne 51534 -or [string]::IsNullOrEmpty($oracle[0].RestoreSql)){throw 'XLSX_FUTURE_ORACLE_SHAPE'}
   $name=if($fault.EndsWith('Public',[StringComparison]::Ordinal)){'TVF_FormatXlsxCell'}else{'TVF_InternalFormatXlsxCell'}
   $before=Get-XlsxSnapshot $Connection;Assert-XlsxRejected $Connection $Deploy 51534
   if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_FUTURE_DEPLOY_CHANGED'}
   $foreign=Get-XlsxForeignSlotPrepared $Connection $name
   Invoke-XlsxBatches $Connection $Uninstall
   if((Get-XlsxForeignSlotPrepared $Connection $name) -cne $foreign){throw 'XLSX_HISTORICAL_FUTURE_LOST'}
   $absent=@(Invoke-XlsxSql $Connection "SELECT COUNT(*) Count FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory';" -Rows)
   if($absent.Count -ne 1 -or $absent[0].Count -ne 0){throw 'XLSX_HISTORICAL_UNINSTALL_ASSEMBLY_REMAINS'}
   Invoke-XlsxBatches $Connection $oracle[0].RestoreSql
   Invoke-XlsxBatches $Connection $LegacyDeploy
   $Connection.Dispose();$Connection=Open-XlsxConnection $Target $Database
  }
  return $Connection
 }catch{if($Connection){try{$Connection.Dispose()}catch{}};throw}
}
function Assert-XlsxNativeNullablePrepared($Connection,[string]$Database,$CatalogConnection=$Connection){
 # Katalog ist das Oracle der tatsächlich deklarierten SQL-Metadaten;
 # der Client muss denselben Zustand wiedergeben, keine erfundene IF-Nullability.
 $catalog=@(Invoke-XlsxSql $CatalogConnection @'
SELECT ROW_NUMBER() OVER(PARTITION BY object_id ORDER BY column_id)-1 Ordinal,name,is_nullable,
 CASE WHEN object_id=OBJECT_ID(N'toolbelt_file.TVF_InternalInterpretXlsxCell') THEN 1 ELSE 0 END Internal
FROM sys.columns WHERE object_id IN(OBJECT_ID(N'toolbelt_file.TVF_InternalInterpretXlsxCell'),OBJECT_ID(N'toolbelt_file.TVF_InterpretXlsxCell'))
ORDER BY Internal,Ordinal;
'@ -Rows)
 $internal=@($catalog|Where-Object Internal -eq 1);$public=@($catalog|Where-Object Internal -eq 0)
 if($internal.Count -ne 14 -or $public.Count -ne 14 -or @($internal|Where-Object {-not $_.is_nullable}).Count){throw 'XLSX_INTERNAL_NULLABILITY_MISMATCH'}
 $prefix='['+$Database.Replace(']',']]')+'].toolbelt_file.'
 $command=$Connection.CreateCommand();$command.CommandTimeout=Get-XlsxCommandTimeout
 $command.CommandText='SELECT * FROM '+$prefix+'TVF_InterpretXlsxCell(DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT);'
 try{
  $reader=$command.ExecuteReader()
  try{
   $schema=$reader.GetSchemaTable()
   if($reader.FieldCount -ne 14 -or $schema.Rows.Count -ne 14){throw 'XLSX_CLIENT_NULLABILITY_SHAPE'}
   for($index=0;$index -lt 14;$index++){
    if($public[$index].Ordinal -ne $index -or $reader.GetName($index) -cne $public[$index].name -or
     [bool]$schema.Rows[$index]['AllowDBNull'] -ne [bool]$public[$index].is_nullable){throw 'XLSX_PUBLIC_NULLABILITY_MISMATCH'}
   }
   Assert-XlsxReadBudget $command
   if(-not $reader.Read() -or $reader.IsDBNull(4) -or $reader.IsDBNull(13) -or $reader.Read() -or $reader.NextResult()){throw 'XLSX_LOGICAL_NULLABILITY_MISMATCH'}
   Assert-XlsxReadBudget $command
  }finally{$reader.Dispose()}
 }finally{$command.Dispose()}
}
function Assert-XlsxVisibilityPrepared($Connection,[string]$Deploy,[string]$Uninstall){
 # Ausschließlich synthetische 0/NULL-Predicate statt Rechteänderungen.
 $predicates=@("HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')","HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT')")
 foreach($original in @($Deploy,$Uninstall)){
  foreach($predicate in $predicates){foreach($invalid in @('0','CONVERT(int,NULL)')){foreach($phase in @(0,1)){
   if(([regex]::Matches($original,[regex]::Escape($predicate))).Count -ne 1){throw 'XLSX_VISIBILITY_SEAM_AMBIGUOUS'}
   $replacement='(CASE WHEN @Phase='+$phase+' THEN '+$invalid+' ELSE '+$predicate+' END)'
   $text=$original.Replace($predicate,$replacement);$before=Get-XlsxSnapshot $Connection;$caught=$false
   try{Invoke-XlsxBatches $Connection $text}catch{
    $failure=Get-XlsxFailure $_.Exception
    if($failure.SqlNumber -ne 51535 -or $failure.SqlState -ne 2){throw 'XLSX_VISIBILITY_ERROR_ORACLE_MISMATCH'}
    $caught=$true
   }
   if(-not $caught -or (Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_VISIBILITY_REJECTION_MUTATED'}
   $state=@(Invoke-XlsxSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
   if($state.Count -ne 1 -or $state[0].TranCount -ne 0 -or $state[0].TranState -ne 0){throw 'XLSX_VISIBILITY_TRANSACTION_LEFT'}
  }}}
 }
}

function Get-XlsxSnapshot($Connection){
 $sql=(Get-XlsxCompleteSnapshotSql).Replace('SELECT @Snapshot=','SELECT ')
 $sql=$sql.Replace("'ABSENT');","'ABSENT') AS Snapshot;")
 $rows=@(Invoke-XlsxSql $Connection $sql -Rows)
 if($rows.Count -ne 1 -or $rows[0].Snapshot -is [DBNull]){throw 'XLSX_COMPLETE_SNAPSHOT_INVALID'}
 return [string]$rows[0].Snapshot
}
try{
 $repo=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
 $module=Join-Path $repo 'Modules/toolbelt.file.xlsx-memory'
 if((Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash -cne $ExpectedDriverSHA256.ToUpperInvariant()){throw 'XLSX_DRIVER_PIN_MISMATCH'}
 $helperPath=Join-Path (Join-Path $repo 'Tests/CI') 'run-lab-local.ps1'
 $helperBytes=[IO.File]::ReadAllBytes($helperPath)
 $helperHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($helperBytes))
 $parseErrors=$null
 $tree=[Management.Automation.Language.Parser]::ParseInput([Text.Encoding]::UTF8.GetString($helperBytes).TrimStart([char]0xFEFF),[ref]$null,[ref]$parseErrors)
 if($parseErrors.Count){throw 'XLSX_LAB_HELPER_PARSE_FAILED'}
 foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
  $definitions=@($tree.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true))
  if($definitions.Count -ne 1){throw 'XLSX_LAB_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($definitions[0].Extent.Text))
 }
 $prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
 if(-not $prompt -or (Get-FileHash -LiteralPath $prompt -Algorithm SHA256).Hash -cne $ExpectedPromptSHA256.ToUpperInvariant() -or [string]::IsNullOrWhiteSpace([IO.File]::ReadAllText($prompt))){throw 'XLSX_REVIEWED_PROMPT_REQUIRED'}
 # Test-Json kann Daten auf Hilfsstreams melden: alle Ausgabe wird privat gehalten.
 $discovery=@(& {Resolve-LabContract} *>&1)
 $contracts=@($discovery|Where-Object {$_ -is [pscustomobject] -and $_.PSObject.Properties.Name -contains 'Contract'})
 if($contracts.Count -ne 1 -or @($discovery|Where-Object {$_ -is [Management.Automation.ErrorRecord]}).Count){throw 'XLSX_LAB_SCHEMA_INVALID'}
 $targets=@(Get-LabTargetsForSelector -Contract $contracts[0].Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
 if(-not $targets.Count){throw 'XLSX_EXACT_TARGET_NOT_READY'}
 $release=(Resolve-Path -LiteralPath $ReleaseDirectory).Path;$legacy=(Resolve-Path -LiteralPath $LegacyDirectory).Path
 $legacyModule=Join-Path $legacy 'original/Modules/toolbelt.file.xlsx-memory'
 $zipModule=Join-Path $legacy 'original/Modules/toolbelt.archive.zip-memory'
 $legacyProvenancePath=Join-Path $legacy 'LegacyProvenance.json'
 if((Get-FileHash -LiteralPath $legacyProvenancePath -Algorithm SHA256).Hash -cne $ExpectedLegacyProvenanceSHA256.ToUpperInvariant()){throw 'XLSX_LEGACY_PROVENANCE_PIN_MISMATCH'}
 $provenance=Get-Content -LiteralPath $legacyProvenancePath -Raw|ConvertFrom-Json
 if($provenance.revision -cne 'fdafa8038e4d5240dd727096f144c8d5fd884117' -or $provenance.moduleVersion -cne '1.0.0'){throw 'XLSX_GENUINE_LEGACY_REQUIRED'}
 $freeze=@{}
 $freeze[$helperPath]=$helperHash
 $resultTableModule=Join-Path $repo 'Modules/toolbelt.core.result-table'
 foreach($file in @(Get-ChildItem (Join-Path $resultTableModule 'Deployment') -Filter '*.sql' -File)+@(Get-ChildItem (Join-Path $resultTableModule 'Source') -Filter '*.sql' -File)){
  $freeze[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
 }
 $freeze[$legacyProvenancePath]=$ExpectedLegacyProvenanceSHA256.ToUpperInvariant()
 $legacyRequired=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/TVF_InternalXlsxSheets.sql','Source/TVF_InternalXlsxCells.sql',
  'Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql','Source/USP_ReadXlsxWorksheetCells.sql',
  'Clr/Workbook.cs','Clr/XlsxEntryPoints.cs','Clr/AssemblyInfo.cs','Clr/Toolbelt.File.XlsxMemory.csproj','Scripts/New-ClrReleaseArtifacts.ps1')
 if((@($provenance.sourcePins.PSObject.Properties.Name|Sort-Object) -join '|') -cne (@($legacyRequired|Sort-Object) -join '|')){throw 'XLSX_LEGACY_SOURCE_MANIFEST_INCOMPLETE'}
 $rawPaths=@('Clr/Workbook.cs','Clr/XlsxEntryPoints.cs','Source/TVF_InternalXlsxSheets.sql','Source/TVF_InternalXlsxCells.sql',
  'Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql','Source/USP_ReadXlsxWorksheetCells.sql')
 foreach($relative in $rawPaths){
  $blob=(& git -C $repo rev-parse ($provenance.revision+':Modules/toolbelt.file.xlsx-memory/'+$relative) 2>$null).Trim()
  if($LASTEXITCODE -or (& git -C $repo hash-object --no-filters (Join-Path $module $relative) 2>$null).Trim() -cne $blob){throw 'XLSX_RAW_SOURCE_CHANGED'}
 }
 foreach($property in $provenance.sourcePins.PSObject.Properties){
  $path=Join-Path $legacyModule $property.Name;$blob=(& git -C $repo rev-parse ($provenance.revision+':Modules/toolbelt.file.xlsx-memory/'+$property.Name) 2>$null).Trim()
  if($LASTEXITCODE -or (& git -C $repo hash-object --no-filters $path 2>$null).Trim() -cne $blob -or $blob -cne $property.Value.gitBlob){throw 'XLSX_LEGACY_BLOB_MISMATCH'}
  $freeze[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
 }
 # Die genuine ZIP-Abhängigkeit stammt ebenso aus dem unveränderten öffentlichen
 # Paket. Alle installierten SQL-Texte und Buildquellen werden bytegenau gebunden.
 $zipPaths=@(& git -C $repo ls-tree -r --name-only $provenance.revision -- Modules/toolbelt.archive.zip-memory 2>$null)
 if($LASTEXITCODE -or -not $zipPaths.Count){throw 'XLSX_ZIP_LEGACY_SOURCE_UNAVAILABLE'}
 foreach($repoPath in $zipPaths){
  if($repoPath -notmatch '/(Source|Deployment|Clr|Scripts)/'){continue}
  $path=Join-Path (Join-Path $legacy 'original') $repoPath
  $blob=(& git -C $repo rev-parse ($provenance.revision+':'+$repoPath) 2>$null).Trim()
  if($LASTEXITCODE -or (& git -C $repo hash-object --no-filters $path 2>$null).Trim() -cne $blob){throw 'XLSX_ZIP_LEGACY_BLOB_MISMATCH'}
  $freeze[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
 }
 $legacy11=(Resolve-Path -LiteralPath $Legacy11Directory).Path
 $legacy11Module=Join-Path $legacy11 'original/Modules/toolbelt.file.xlsx-memory'
 $legacy11ProvenancePath=Join-Path $legacy11 'LegacyProvenance.json'
 if((Get-FileHash -LiteralPath $legacy11ProvenancePath -Algorithm SHA256).Hash -cne $ExpectedLegacy11ProvenanceSHA256.ToUpperInvariant()){throw 'XLSX_LEGACY11_PROVENANCE_PIN_MISMATCH'}
 $provenance11=Get-Content -LiteralPath $legacy11ProvenancePath -Raw|ConvertFrom-Json
 if($provenance11.revision -cne 'f64ee9eb8f6a7f66fd441821c7c40fcf2d92ee1e' -or $provenance11.moduleVersion -cne '1.1.0'){throw 'XLSX_GENUINE_LEGACY11_REQUIRED'}
 $required11=@($legacyRequired)+@('Clr/XlsxCellType.cs','Source/TVF_InternalInterpretXlsxCell.sql','Source/TVF_InterpretXlsxCell.sql')
 if((@($provenance11.sourcePins.PSObject.Properties.Name|Sort-Object) -join '|') -cne (@($required11|Sort-Object) -join '|')){throw 'XLSX_LEGACY11_MANIFEST_INCOMPLETE'}
 foreach($property in $provenance11.sourcePins.PSObject.Properties){
  $path=Join-Path $legacy11Module $property.Name
  $blob=(& git -C $repo rev-parse ($provenance11.revision+':Modules/toolbelt.file.xlsx-memory/'+$property.Name) 2>$null).Trim()
  if($LASTEXITCODE -or (& git -C $repo hash-object --no-filters $path 2>$null).Trim() -cne $blob -or $blob -cne $property.Value.gitBlob -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $property.Value.sha256){throw 'XLSX_LEGACY11_BLOB_MISMATCH'}
  $freeze[$path]=$property.Value.sha256
 }
 $freeze[$legacy11ProvenancePath]=$ExpectedLegacy11ProvenanceSHA256.ToUpperInvariant()
 $artifacts=@()
 foreach($definition in @(@{Root=$release;File='Toolbelt.File.XlsxMemory';Version='1.2.0';Label='current'},@{Root=(Join-Path $legacyModule 'Artifacts');File='Toolbelt.File.XlsxMemory';Version='1.0.0';Label='legacy'},@{Root=(Join-Path $legacy11Module 'Artifacts');File='Toolbelt.File.XlsxMemory';Version='1.1.0';Label='legacy11'},@{Root=(Join-Path $zipModule 'Artifacts');File='Toolbelt.Archive.ZipMemory';Version='1.4.0';Label='zip'})){
  $manifestPath=Join-Path $definition.Root ($definition.File+'.trust-manifest.json');$binaryPath=Join-Path $definition.Root ($definition.File+'.dll')
  $manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json;$binary=[IO.File]::ReadAllBytes($binaryPath)
  $hash=[Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($binary))
  if($manifest.moduleVersion -cne $definition.Version -or $manifest.sha512 -cne $hash -or $manifest.sqlServerHexLiteral -cne ('0x'+$hash)){throw 'XLSX_ARTIFACT_PIN_MISMATCH'}
  if($definition.Label -eq 'legacy' -and $provenance.assemblySHA512 -cne $hash){throw 'XLSX_LEGACY_BINARY_MISMATCH'}
  if($definition.Label -eq 'legacy11' -and $provenance11.assemblySHA512 -cne $hash){throw 'XLSX_LEGACY11_BINARY_MISMATCH'}
  $artifacts+=@([pscustomobject]@{Label=$definition.Label;Hash=$hash;Bits='0x'+[Convert]::ToHexString($binary)})
  $freeze[$manifestPath]=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash;$freeze[$binaryPath]=(Get-FileHash -LiteralPath $binaryPath -Algorithm SHA256).Hash
  if($definition.Label -eq 'current'){
   if($hash -cne $ExpectedAssemblySHA512.ToUpperInvariant()){throw 'XLSX_ROOT_REVIEWED_ASSEMBLY_REQUIRED'}
   $requiredPaths=@('Clr/Toolbelt.File.XlsxMemory.csproj','Clr/AssemblyInfo.cs','Clr/Workbook.cs','Clr/XlsxEntryPoints.cs','Clr/XlsxCellType.cs','Clr/XlsxCellDisplay.cs','Clr/XlsxCellDisplayBridge.cs',
    'Source/TVF_InternalXlsxSheets.sql','Source/TVF_InternalXlsxCells.sql','Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql',
    'Source/USP_ReadXlsxWorksheetCells.sql','Source/TVF_InternalInterpretXlsxCell.sql','Source/TVF_InterpretXlsxCell.sql','Source/TVF_InternalFormatXlsxCell.sql','Source/TVF_FormatXlsxCell.sql',
    'Deployment/Deploy.sql','Deployment/Uninstall.sql','Scripts/New-ClrReleaseArtifacts.ps1','Scripts/Invoke-XlsxBuildProcess.ps1')
   if(@($manifest.sourceFingerprints).Count -ne 20 -or (@($manifest.sourceFingerprints.path|Sort-Object -Unique) -join '|') -cne (@($requiredPaths|Sort-Object) -join '|')){throw 'XLSX_SOURCE_MANIFEST_INCOMPLETE'}
   foreach($entry in $manifest.sourceFingerprints){if($entry.path -match '(^[/\\]|\.\.)'){throw 'XLSX_SOURCE_MANIFEST_PATH_INVALID'};$path=Join-Path $module $entry.path;if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $entry.sha256){throw 'XLSX_SOURCE_PIN_MISMATCH'};$freeze[$path]=$entry.sha256}
   $artifactDeploy=Join-Path $release 'Deploy.WithAssembly.sql'
   $expectedDeploy=[IO.File]::ReadAllText((Join-Path $module 'Deployment/Deploy.sql')).Replace('$(AssemblyBits)','0x'+[Convert]::ToHexString($binary))+[Environment]::NewLine
   if([IO.File]::ReadAllText($artifactDeploy) -cne $expectedDeploy){throw 'XLSX_RELEASE_DEPLOY_MISMATCH'}
   $freeze[$artifactDeploy]=(Get-FileHash -LiteralPath $artifactDeploy -Algorithm SHA256).Hash
  }
 }
 foreach($path in @(Get-ChildItem (Join-Path $module 'Tests/Runtime') -File)){$freeze[$path.FullName]=(Get-FileHash -LiteralPath $path.FullName -Algorithm SHA256).Hash}
 $compositionRoot=Join-Path $module 'Tests/Runtime'
 $compositionHelper=Join-Path $compositionRoot 'Invoke-TypesComposition.ps1'
 $compositionPins=@{'Invoke-TypesComposition.ps1'='956E84C65863D7C9AE0836C4D7F543A7F88F56BDFE21D4226DCB3DCF3277D019';'Types.Composition.sql'='9C63E84B28B066555A20D6354F2154E8C5A830CA3372C52D40F73B02F13B923E';'Types.Composition.xlsx'='7B690C7C0EC6C2EEBBEA180B031C7BDAED1A6D1DC5F2D3CEC360135B8F530BC1'}
 foreach($name in $compositionPins.Keys){$path=Join-Path $compositionRoot $name;if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $compositionPins[$name]){throw 'XLSX_COMPOSITION_INPUT_PIN_MISMATCH'};$freeze[$path]=$compositionPins[$name]}
 $displayCompositionHelper=Join-Path $compositionRoot 'Invoke-DisplayComposition.ps1'
 $displayCompositionPins=@{'Invoke-DisplayComposition.ps1'='DF577A617E2A52D07766DFCD332C57AEEAA4B0F4A44AB6B8D97FDAF4119A23F9';'Display.Composition.sql'='A44F37281DEC7D74E82DE44D62D9A6A929A47AAF9849D4458E68278713901A44'}
 foreach($name in $displayCompositionPins.Keys){$path=Join-Path $compositionRoot $name;if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $displayCompositionPins[$name]){throw 'XLSX_DISPLAY_COMPOSITION_PIN'};$freeze[$path]=$displayCompositionPins[$name]}
 $freeze[$PSCommandPath]=$ExpectedDriverSHA256.ToUpperInvariant()
}catch{$safe=Get-XlsxFailure $_.Exception;Write-Output ('FAILED: XLSX_TYPES_PREPARATION SQL_'+$safe.SqlNumber+'_STATE'+$safe.SqlState);exit 1}

$levels=switch($Version){'2019'{@(150)};'2022'{@(150,160)};'2025'{@(150,160,170)}}
foreach($target in $targets){
 try{
 $runId=[guid]::NewGuid().ToString('N');$journal=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltXlsxTypesRestore-'+$runId+'.json')
 $script:scopeClock=[Diagnostics.Stopwatch]::StartNew();$script:cleanupPhase=$false
 # Externe Reader behalten die Uhr des Zielscopes, nicht ihren eigenen Script-Scope.
 $capturedClock=$script:scopeClock;$capturedWorkMilliseconds=$script:workMilliseconds
 $closedCommandTimeout={
  if($null-eq$capturedClock){throw 'XLSX_SCOPE_CLOCK_REQUIRED'}
  $remaining=$capturedWorkMilliseconds-$capturedClock.ElapsedMilliseconds
  if($remaining-lt1000){throw 'XLSX_SCOPE_DEADLINE'}
  return [int][Math]::Min(60,[Math]::Floor($remaining/1000))
 }.GetNewClosure()
 $capturedTimeout=$closedCommandTimeout
 $closedReadBudget={param($Command)
  try{[void](& $capturedTimeout)}catch{try{$Command.Cancel()}catch{};throw}
 }.GetNewClosure()
 $keyBytes=[Text.Encoding]::UTF8.GetBytes([string]$target.key)
 $ledger=[ordered]@{RunId=$runId;SelectorIdentity=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($keyBytes));Platform=$Platform;Version=$Version;Patch=[string]$target.patch;State='PREPARED';Databases=@();Trust=@();ConfigurationChanges=0;RightsChanges=0;OriginalFailure=$null;CleanupFailure=$null;RuntimeTests=$RuntimeTests;WorkBudgetMilliseconds=$script:workMilliseconds;TotalBudgetMilliseconds=$script:totalMilliseconds;DispositionVerified=$false}
 $journalHealthy=$true;$control=$null;$failed=$false;$cleanupBlocked=$false;$stage='PREFLIGHT'
 }catch{$safe=Get-XlsxFailure $_.Exception;Write-Output ('FAILED: XLSX_TYPES_TARGET_PREPARATION SQL_'+$safe.SqlNumber+'_STATE'+$safe.SqlState);exit 1}
 try{
  Save-XlsxJournal
  foreach($path in $freeze.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $freeze[$path]){throw 'XLSX_PRECONNECT_SOURCE_PIN_CHANGED'}}
  $control=Open-XlsxConnection $target 'master'
  # Pflichtpreflight auf derselben sicheren Verbindung; beide Resultsets konsumieren.
  Invoke-XlsxSql $control 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
  $ready=@(Invoke-XlsxSql $control @'
SELECT TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) Major,
 (SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr enabled') Clr,
 (SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr strict security') StrictSecurity,
 IS_SRVROLEMEMBER(N'sysadmin') Admin,
 DATALENGTH(CONVERT(varbinary(max),CONVERT(datetime2(7),'2026-10-02T00:00:00.0000001'))) DateBytes;
'@ -Rows)
  if($ready.Count -ne 1 -or $ready[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[$Version] -or $ready[0].Clr -ne 1 -or $ready[0].StrictSecurity -ne 1 -or $ready[0].Admin -ne 1 -or $ready[0].DateBytes -ne 9){throw 'XLSX_PREFLIGHT_REQUIRED'}
  $fingerprintProbe=@(Invoke-XlsxSql $control @'
DECLARE @Synthetic TABLE(hash varbinary(64),description nvarchar(4000),create_date datetime2(7),created_by nvarchar(128));
INSERT @Synthetic VALUES(HASHBYTES('SHA2_512',0x01),N'Toolbelt synthetic fingerprint',CONVERT(datetime2(7),'2026-10-02T00:00:00.0000001'),N'SyntheticOwner');
SELECT DATALENGTH(CONVERT(varchar(64),HASHBYTES('SHA2_256',hash+CONVERT(binary(4),ISNULL(DATALENGTH(description),-1))+ISNULL(CONVERT(varbinary(max),description),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(CONVERT(varbinary(max),create_date)),-1))+ISNULL(CONVERT(varbinary(max),create_date),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(created_by),-1))+ISNULL(CONVERT(varbinary(max),created_by),0x)),2)) FingerprintLength FROM @Synthetic;
'@ -Rows)
  if($fingerprintProbe.Count -ne 1 -or $fingerprintProbe[0].FingerprintLength -ne 64){throw 'XLSX_TRUST_FINGERPRINT_PROBE_FAILED'}
  $stage='EXACT_TRUST';foreach($artifact in $artifacts){Register-XlsxTrust $control $artifact}
  foreach($mode in $DeploymentModes){
   $stage='CREATE_'+$mode;$database=New-XlsxDatabase $control $target $mode $(if($mode -eq 'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'})
   $connection=$null
   try{
    $variables=@{DeploymentMode=$mode;ConfirmNoExternalConsumers=1;ToolbeltDatabase=$database;AssemblyBits=($artifacts|Where-Object Label -eq 'zip').Bits}
    foreach($dependency in @((Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql'),(Join-Path $zipModule 'Deployment/Deploy.sql'))){
     $stage='DEPENDENCY_'+$mode;$connection=Open-XlsxConnection $target $database
     try{Invoke-XlsxBatches $connection (Read-XlsxSql $dependency $variables)}finally{$connection.Dispose();$connection=$null}
    }
    $variables.AssemblyBits=($artifacts|Where-Object Label -eq 'current').Bits
    $deploy=Read-XlsxSql (Join-Path $module 'Deployment/Deploy.sql') $variables
    $uninstall=Read-XlsxSql (Join-Path $module 'Deployment/Uninstall.sql') $variables
    foreach($installation in @('clean','genuine1.0','genuine1.1')){
     $connection=Open-XlsxConnection $target $database
     if($installation -eq 'genuine1.0'){
      $stage='GENUINE_1_0_'+$mode;$variables.AssemblyBits=($artifacts|Where-Object Label -eq 'legacy').Bits
      Invoke-XlsxBatches $connection (Read-XlsxSql (Join-Path $legacyModule 'Deployment/Deploy.sql') $variables)
      # Historische Installer-Temps enden mit der SQLCMD-Session, unverändert.
      $connection.Dispose();$connection=Open-XlsxConnection $target $database;$variables.AssemblyBits=($artifacts|Where-Object Label -eq 'current').Bits
      $legacyVariables=$variables.Clone();$legacyVariables.AssemblyBits=($artifacts|Where-Object Label -eq 'legacy').Bits
      $legacySql=Read-XlsxSql (Join-Path $legacyModule 'Deployment/Deploy.sql') $legacyVariables
      $stage='HISTORICAL_FUTURE_'+$mode
      $connection=Invoke-XlsxHistoricalFuturePrepared $target $database $connection $variables $deploy $uninstall $legacySql
      $connection=Invoke-XlsxDisplayFuturePrepared $target $database $connection $variables $deploy $uninstall $legacySql
     }
     if($installation -eq 'genuine1.1'){
      $stage='GENUINE_1_1_'+$mode;$oldVariables=$variables.Clone();$oldVariables.AssemblyBits=($artifacts|Where-Object Label -eq 'legacy11').Bits
      Invoke-XlsxBatches $connection (Read-XlsxSql (Join-Path $legacy11Module 'Deployment/Deploy.sql') $oldVariables)
      & (Join-Path $module 'Tests/Runtime/Types.Metadata.ps1') -Connection $connection -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null
      $connection.Dispose();$connection=Open-XlsxConnection $target $database
      $legacy11Sql=Read-XlsxSql (Join-Path $legacy11Module 'Deployment/Deploy.sql') $oldVariables
      $connection=Invoke-XlsxDisplayFuturePrepared $target $database $connection $variables $deploy $uninstall $legacy11Sql
     }
     $stage='INSTALL_'+$installation+'_'+$mode;Invoke-XlsxBatches $connection $deploy;Invoke-XlsxBatches $connection $deploy
     foreach($abort in @('OFF','ON')){foreach($doomed in @($false,$true)){
      $stage='CALLER_'+$mode+'_'+$abort+'_'+$doomed
      Assert-XlsxCallerPrepared $connection $deploy $uninstall $abort $doomed
     }}
     $stage='LOCK_'+$mode;Assert-XlsxLockPrepared $target $database $connection $deploy $uninstall
     $stage='ROLLBACK_'+$mode;Assert-XlsxRollbackPrepared $connection $deploy $uninstall
     $stage='VISIBILITY_PREDICATE_'+$mode;Assert-XlsxVisibilityPrepared $connection $deploy $uninstall
     foreach($level in $levels){
      Invoke-XlsxSql $control ("ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL=$level;")
      foreach($test in $RuntimeTests){$stage='API_'+$installation+'_'+$mode+'_'+$level+'_'+$test;Write-Output ('RUNNING: '+$stage);Invoke-XlsxBatches $connection (Read-XlsxSql (Join-Path $module ('Tests/Runtime/'+$test)) $variables)}
      $stage='CLIENT_'+$installation+'_'+$mode+'_'+$level
      & (Join-Path $module 'Tests/Runtime/Types.Metadata.ps1') -Connection $connection -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null
      & (Join-Path $module 'Tests/Runtime/Display.Metadata.ps1') -Connection $connection -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null
      Assert-XlsxNativeNullablePrepared $connection $database
     }
     # Komposition einmal je Installation/Modus nach den API-CL-Schleifen (letzte CL).
     $stage='RAW_TYPE_COMPOSITION_'+$installation+'_'+$mode
     Write-Output ('RUNNING: '+$stage)
     & $compositionHelper -Connection $connection -ToolbeltDatabase $database -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null
     $stage='RAW_TYPE_DISPLAY_COMPOSITION_'+$installation+'_'+$mode
     & $displayCompositionHelper -Connection $connection -ToolbeltDatabase $database -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null
     foreach($fault in @('VersionUnknown','VersionPadded','ModePadded','MarkerPadded','MarkerMissing','Dependency')){
      $stage='COLLISION_'+$mode+'_'+$fault;$variables.FaultCase=$fault
      $fixture=[regex]::Replace((Read-XlsxSql (Join-Path $module 'Tests/Runtime/Types.CollisionFixture.sql') $variables),'(?im)^\s*GO\s*$','')
      $oracle=@(Invoke-XlsxSql $connection $fixture -Rows)
      if($oracle.Count -ne 1 -or $oracle[0].ExpectedError -notin @(51534,51535) -or [string]::IsNullOrEmpty($oracle[0].RestoreSql)){throw 'XLSX_COLLISION_FIXTURE_SHAPE'}
      $before=Get-XlsxSnapshot $connection;Assert-XlsxRejected $connection $(if($fault -eq 'Dependency'){$uninstall}else{$deploy}) ([int]$oracle[0].ExpectedError)
      if((Get-XlsxSnapshot $connection) -cne $before){throw 'XLSX_COLLISION_REJECTION_MUTATED'}
      Invoke-XlsxBatches $connection $oracle[0].RestoreSql
     }
     if($mode -eq 'central'){
      $stage='CENTRAL_CLIENT';$caller=New-XlsxDatabase $control $target 'caller' 'Latin1_General_100_CS_AS'
      $consumer=Open-XlsxConnection $target $caller
      try{& (Join-Path $module 'Tests/Runtime/Display.Metadata.ps1') -Connection $consumer -ToolbeltDatabase $database -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null; & $displayCompositionHelper -Connection $consumer -ToolbeltDatabase $database -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null; & (Join-Path $module 'Tests/Runtime/Types.Metadata.ps1') -Connection $consumer -ToolbeltDatabase $database -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null; Assert-XlsxNativeNullablePrepared $consumer $database $connection; $stage='CENTRAL_RAW_TYPE_COMPOSITION_'+$installation; & $compositionHelper -Connection $consumer -ToolbeltDatabase $database -CommandTimeoutProvider $closedCommandTimeout -ReadBudgetProvider $closedReadBudget | Out-Null}finally{$consumer.Dispose()}
      $unconfirmed=$variables.Clone();$unconfirmed.ConfirmNoExternalConsumers=0
      Assert-XlsxRejected $connection (Read-XlsxSql (Join-Path $module 'Deployment/Uninstall.sql') $unconfirmed) 51536
     }
     $stage='UNINSTALL_'+$installation+'_'+$mode;Invoke-XlsxBatches $connection $uninstall
     $absent=@(Invoke-XlsxSql $connection "SELECT COUNT(*) Count FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory';" -Rows)
     if($absent.Count -ne 1 -or $absent[0].Count -ne 0){throw 'XLSX_UNINSTALL_NOT_VERIFIED'}
     $connection.Dispose();$connection=$null
    }
   }finally{if($connection){$connection.Dispose()}}
  }
  foreach($path in $freeze.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $freeze[$path]){throw 'XLSX_FINAL_SOURCE_PIN_CHANGED'}}
 }catch{$failed=$true;$ledger.OriginalFailure=Get-XlsxFailure $_.Exception}
 finally{
  $script:cleanupPhase=$true
  try{
   if($journalHealthy){$ledger.State='CLEANING';Save-XlsxJournal
    if($control -and $control.State -eq [Data.ConnectionState]::Open){
     $stage='DATABASE_CLEANUP';foreach($entry in $ledger.Databases){Remove-XlsxOwnedDatabase $control $entry}
     if(@($ledger.Databases|Where-Object State -ne 'DROPPED').Count){throw 'XLSX_DATABASE_CLEANUP_INCOMPLETE'}
     $stage='TRUST_CLEANUP';foreach($entry in $ledger.Trust){Remove-XlsxOwnedTrust $control $entry}
     $stage='FRESH_DISPOSITION';Assert-XlsxDisposition $control;$ledger.DispositionVerified=$true
    }elseif($ledger.Databases.Count -or @($ledger.Trust|Where-Object {-not $_.Preexisting}).Count){throw 'XLSX_CLEANUP_CONNECTION_UNAVAILABLE'}
    foreach($path in $freeze.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $freeze[$path]){throw 'XLSX_CLEANUP_SOURCE_PIN_CHANGED'}}
    [void](Get-XlsxCommandTimeout)
    if(-not $failed -and -not $ledger.DispositionVerified){throw 'XLSX_FINAL_DISPOSITION_REQUIRED'}
    $ledger.State=$(if($failed){'FAILED_CLEANED'}else{'COMPLETE'});Save-XlsxJournal
   }else{$cleanupBlocked=$true}
  }catch{$cleanupBlocked=$true;$ledger.State='CLEANUP_BLOCKED';$ledger.CleanupFailure=Get-XlsxFailure $_.Exception;try{Save-XlsxJournal}catch{}}
  finally{if($control){try{$control.Dispose()}catch{$cleanupBlocked=$true;$ledger.State='CLEANUP_BLOCKED';$ledger.CleanupFailure=Get-XlsxFailure $_.Exception;try{Save-XlsxJournal}catch{}}}}
 }
 if($cleanupBlocked){Write-Output 'FAILED: XLSX_TYPES_CLEANUP_BLOCKED';exit 1}
 if($failed){Write-Output ('FAILED: XLSX_TYPES_'+$ledger.OriginalFailure.Stage+'_SQL'+$ledger.OriginalFailure.SqlNumber+'_STATE'+$ledger.OriginalFailure.SqlState);exit 1}
 Write-Output ('PASS: XLSX_TYPES '+$Platform+'/'+$Version+'/'+$ledger.Patch+' RuntimeTests='+($RuntimeTests -join ',')+' clean/genuine1.0/genuine1.1/repeat/local-central/client/collisions/uninstall/cleanup; CallerTX/lock/postDROP/preCOMMIT/historicalFutureUninstall/native-nullability/Raw-to-TypeComposition(lastCL, installed+central-caller); MinimalRights NOT_EXECUTED.')
}
