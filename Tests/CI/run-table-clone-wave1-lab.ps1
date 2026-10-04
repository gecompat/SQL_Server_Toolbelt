[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$LegacyDirectory,
 [ValidateSet('linux','windows')][string]$Platform='linux',
 [ValidateSet('2019','2025')][string]$Version='2019',
 [ValidateSet('latest','CU8')][string]$Patch='latest',
 [string]$ExpectedPromptSHA256,
 [string]$ExpectedRunId,
 [string]$JournalPath,
 [switch]$ExecuteReviewed
)
# Portabler, eng ausgewählter Labtest; Ausführung erst nach Quellen-/Promptreview.
$preparationComplete=$true
if($ExecuteReviewed -and !$preparationComplete){Write-Output 'CLONE_PREPARATION_INCOMPLETE';exit 1}
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$record=$null;$journal=$null;$control=$null
$journalContext=@{Stream=$null;ExpectedBytes=$null;ExpectedHash=$null;ExpectedLength=0;Tuple=$null;Prepared=$false;Failed=$false}
$boundRun=$PSBoundParameters.ContainsKey('ExpectedRunId');$boundPath=$PSBoundParameters.ContainsKey('JournalPath')
$connections=[Collections.Generic.List[Data.SqlClient.SqlConnection]]::new()
$stage='PREPARATION';$batch=0
 $definitionBaseline=[ordered]@{QueryError=$true;Hash=$null}
$faultCaseIndex=0
try {
 if($boundRun -ne $boundPath){throw 'CLONE_RUN_CONTEXT_PAIR_REQUIRED'}
 if($boundRun -and $ExpectedRunId -cnotmatch '^[0-9a-f]{32}$'){throw 'CLONE_RUN_CONTEXT_GUID_INVALID'}
 $repo=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
 $legacy=(Resolve-Path -LiteralPath $LegacyDirectory).Path
 $module=Join-Path $repo 'Modules/toolbelt.metadata.table-clone'
 # Alle konsumierten Projektdateien werden einmal gelesen; keine privaten Reviewhash-Konstanten.
 $snapshots=[Collections.Generic.Dictionary[string,byte[]]]::new([StringComparer]::OrdinalIgnoreCase)
 $inputNames=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
 $pins=@{}
 function Add-InputSnapshot([string]$path,[string]$name){
  $full=[IO.Path]::GetFullPath($path)
  if($snapshots.ContainsKey($full)){if($inputNames[$full] -cne $name){throw 'CLONE_INPUT_ALIAS'};return}
  $bytes=[IO.File]::ReadAllBytes($full)
  $snapshots.Add($full,$bytes);$inputNames.Add($full,$name)
  $pins[$full]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
 }
 function Get-InputText([string]$path){
  $full=[IO.Path]::GetFullPath($path)
  if(!$snapshots.ContainsKey($full)){throw 'CLONE_INPUT_NOT_CLOSED'}
  return [Text.UTF8Encoding]::new($false,$true).GetString($snapshots[$full]).TrimStart([char]0xFEFF)
 }
 function Get-InputLines([string]$path){
  $reader=[IO.StringReader]::new((Get-InputText $path));$lines=[Collections.Generic.List[string]]::new()
  try{while($null -ne ($line=$reader.ReadLine())){$lines.Add($line)}}finally{$reader.Dispose()}
  return ,$lines.ToArray()
 }
 if(@(Get-ChildItem "$module/Source" -Filter '*.sql' -File).Count -ne 2){throw 'CLONE_SOURCE_SET_MISMATCH'}
 if(!(($Platform -ceq 'linux' -and $Version -ceq '2019' -and $Patch -ceq 'latest') -or
      ($Platform -ceq 'windows' -and $Version -ceq '2025' -and $Patch -ceq 'CU8'))){throw 'CLONE_EXACT_SCOPE_REQUIRED'}
 $helperRoot=Join-Path $repo 'Tests/CI'
 foreach($import in @(
  @{File='run-lab-local.ps1';Names=@('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')},
  @{File='run-deterministic-translate-lab.ps1';Names=@('Read-TranslateSql')}
 )){
  $path=Join-Path $helperRoot $import.File
  Add-InputSnapshot $path ('repo/Tests/CI/'+$import.File)
  $helperBytes=$snapshots[[IO.Path]::GetFullPath($path)]
  $helperText=[Text.UTF8Encoding]::new($false,$true).GetString($helperBytes).TrimStart([char]0xFEFF)
  $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($helperText,[ref]$null,[ref]$errors)
  if($errors.Count){throw 'CLONE_HELPER_PARSE_FAILED'}
  foreach($name in $import.Names){
   $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
   if($nodes.Count -ne 1){throw 'CLONE_HELPER_AMBIGUOUS'}
   $functionText=$nodes[0].Extent.Text
   if($name -ceq 'Read-TranslateSql'){
    $needle='[IO.File]::ReadAllLines($resolved)'
    if(([regex]::Matches($functionText,[regex]::Escape($needle))).Count -ne 1){throw 'CLONE_SQL_READER_SEAM'}
    $functionText=$functionText.Replace($needle,'(Get-InputLines $resolved)')
   }
   if($name -ceq 'Resolve-LabContract'){
    $needle='Get-Content -LiteralPath $contractPath -Raw';$schemaNeedle='-SchemaFile $schemaPath'
    if(([regex]::Matches($functionText,[regex]::Escape($needle))).Count -ne 1 -or ([regex]::Matches($functionText,[regex]::Escape($schemaNeedle))).Count -ne 1){throw 'CLONE_DISCOVERY_SNAPSHOT_SEAM'}
    $functionText=$functionText.Replace($needle,'Get-InputText $contractPath').Replace($schemaNeedle,'-Schema (Get-InputText $schemaPath)')
   }
   . ([scriptblock]::Create($functionText))
  }
 }
 $moduleInputs=@('Source/USP_ScriptTableCloneInternal.sql','Source/USP_ScriptTableClone.sql','Source/USP_ExecuteTableClone.sql',
  'Deployment/Deploy.sql','Deployment/Uninstall.sql','Deployment/New-LegacyTestArtifacts.ps1','module.yaml',
  'Tests/Runtime/Central.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql',
  'Tests/Runtime/Lifecycle.CallerTransaction.Deploy.sql','Tests/Runtime/Lifecycle.CallerTransaction.Uninstall.sql',
  'Tests/Runtime/MinimumRights.Contract.sql','Tests/Runtime/SelectMetadata.Contract.ps1',
  'Tests/Runtime/TableClone.Contract.sql','Tests/Runtime/Wave1.Bytes.sql','Tests/Runtime/Wave1.Contract.sql',
  'Tests/Runtime/Wave1.DateTimeOffset.sql','Tests/Runtime/Wave1.PermissionPredicate.sql')
 foreach($relative in $moduleInputs){Add-InputSnapshot (Join-Path $module $relative) ('repo/Modules/toolbelt.metadata.table-clone/'+$relative)}
 Add-InputSnapshot (Join-Path $repo 'Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md') 'repo/Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md'
 $dependency=Join-Path $repo 'Modules/toolbelt.core.result-table'
 foreach($relative in @('Source/USP_PrepareResultTable.sql','Deployment/Deploy.sql','Deployment/Uninstall.sql','module.yaml')){
  Add-InputSnapshot (Join-Path $dependency $relative) ('repo/Modules/toolbelt.core.result-table/'+$relative)
 }
 $legacyFiles=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/USP_ScriptTableCloneInternal.sql','Source/USP_ScriptTableClone.sql','module.yaml')
 foreach($relative in $legacyFiles){
  $expected=(& git -C $repo rev-parse ('fdafa8038e4d5240dd727096f144c8d5fd884117:Modules/toolbelt.metadata.table-clone/'+$relative) 2>$null).Trim()
  if($LASTEXITCODE){throw 'CLONE_LEGACY_PUBLIC_BLOB_UNAVAILABLE'}
  $path=Join-Path $legacy $relative;Add-InputSnapshot $path ('legacy/'+$relative)
  $gitStart=[Diagnostics.ProcessStartInfo]::new('git');$gitStart.WorkingDirectory=$repo;$gitStart.UseShellExecute=$false;$gitStart.CreateNoWindow=$true
  $gitStart.RedirectStandardInput=$true;$gitStart.RedirectStandardOutput=$true;$gitStart.RedirectStandardError=$true
  $gitStart.ArgumentList.Add('hash-object');$gitStart.ArgumentList.Add('--stdin')
  $gitProcess=[Diagnostics.Process]::Start($gitStart)
  try{
   $blobBytes=$snapshots[[IO.Path]::GetFullPath($path)]
   $gitProcess.StandardInput.BaseStream.Write($blobBytes,0,$blobBytes.Length);$gitProcess.StandardInput.Close()
   if(!$gitProcess.WaitForExit(15000)){$gitProcess.Kill();throw 'CLONE_LEGACY_HASH_DEADLINE'}
   $actual=$gitProcess.StandardOutput.ReadToEnd().Trim()
   if($gitProcess.ExitCode -ne 0 -or $actual -cne $expected){throw 'CLONE_LEGACY_BLOB_MISMATCH'}
  }finally{$gitProcess.Dispose()}
 }
 Add-InputSnapshot (Join-Path $legacy 'provenance.json') 'legacy/provenance.json'
 $provenance=(Get-InputText (Join-Path $legacy 'provenance.json'))|ConvertFrom-Json
 if($provenance.moduleId -cne 'toolbelt.metadata.table-clone' -or $provenance.version -cne '1.0.0' -or $provenance.publicCommit -cne 'fdafa8038e4d5240dd727096f144c8d5fd884117' -or @($provenance.files).Count -ne 5){throw 'CLONE_LEGACY_PROVENANCE'}
 foreach($relative in $legacyFiles){$rows=@($provenance.files|Where-Object {$_.path -ceq $relative});if($rows.Count -ne 1 -or $rows[0].sha256 -cne $pins[[IO.Path]::GetFullPath((Join-Path $legacy $relative))]){throw 'CLONE_LEGACY_PROVENANCE'}}
 Add-InputSnapshot $PSCommandPath 'adapter/run-table-clone-wave1-lab.ps1'
 $adapterHash=$pins[[IO.Path]::GetFullPath($PSCommandPath)]
 $clientText=Get-InputText (Join-Path $module 'Tests/Runtime/SelectMetadata.Contract.ps1')
 $clientNeedle='Get-Content (Join-Path $PSScriptRoot "../../Deployment/$lifecycle") -Raw'
 if(([regex]::Matches($clientText,[regex]::Escape($clientNeedle))).Count -ne 1){throw 'CLONE_CLIENT_SNAPSHOT_SEAM'}
 $clientText=$clientText.Replace($clientNeedle,'Get-InputText (Join-Path $module ("Deployment/"+$lifecycle))')
 $clientErrors=$null;[void][Management.Automation.Language.Parser]::ParseInput($clientText,[ref]$null,[ref]$clientErrors)
 if($clientErrors.Count){throw 'CLONE_CLIENT_PARSE'}
 $clientScript=[scriptblock]::Create($clientText)
 function Check-Pins {
  if(@(Get-ChildItem "$module/Source" -Filter '*.sql' -File).Count -ne 2){throw 'CLONE_SOURCE_SET_CHANGED'}
  foreach($p in $pins.Keys){if((Get-FileHash -LiteralPath $p).Hash -cne $pins[$p]){throw 'CLONE_SOURCE_CHANGED'}}
 }
 function Assert-JournalPath {
  $parent=[IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($journal))
  if(!$parent.Exists){throw 'CLONE_JOURNAL_PARENT_REQUIRED'}
  while($parent){if(($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'CLONE_JOURNAL_REPARSE'};$parent=$parent.Parent}
  if([IO.File]::Exists($journal) -and (([IO.File]::GetAttributes($journal) -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'CLONE_JOURNAL_REPARSE'}
 }
 function Read-JournalBytes($stream,[int]$length){
  if($length -le 0 -or $length -gt 4194304 -or $stream.Length -ne $length){throw 'CLONE_JOURNAL_LENGTH'}
  $stream.Position=0;$bytes=[byte[]]::new($length);$offset=0
  while($offset -lt $length){$read=$stream.Read($bytes,$offset,$length-$offset);if($read -le 0){throw 'CLONE_JOURNAL_SHORT_READ'};$offset+=$read}
  if($stream.ReadByte() -ne -1 -or $stream.Length -ne $length){throw 'CLONE_JOURNAL_TRAILING'}
  return ,$bytes
 }
 function Assert-JournalBytes([byte[]]$actual,[byte[]]$expected,$tuple){
  if($actual.Length -ne $expected.Length){throw 'CLONE_JOURNAL_BYTES'}
  for($i=0;$i -lt $actual.Length;$i++){if($actual[$i] -ne $expected[$i]){throw 'CLONE_JOURNAL_BYTES'}}
  $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($actual))
  if($hash -cne [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($expected))){throw 'CLONE_JOURNAL_HASH'}
  $parsed=([Text.UTF8Encoding]::new($false,$true).GetString($actual))|ConvertFrom-Json
  if(!$parsed.PSObject.Properties['JournalTuple'] -or !$parsed.JournalTuple -or !$parsed.PSObject.Properties['RunId'] -or $parsed.RunId -cne $tuple.RunId){throw 'CLONE_JOURNAL_TUPLE'}
  if(@($parsed.JournalTuple.PSObject.Properties).Count -ne $tuple.Count){throw 'CLONE_JOURNAL_TUPLE'}
  foreach($key in $tuple.Keys){if(!$parsed.JournalTuple.PSObject.Properties[$key] -or ![string]::Equals([string]$parsed.JournalTuple.$key,[string]$tuple[$key],[StringComparison]::Ordinal)){throw 'CLONE_JOURNAL_TUPLE'}}
 }
 function Save-Record {
  try{
   Check-Pins;Assert-JournalPath
   if($journalContext.Failed){throw 'CLONE_JOURNAL_PREVIOUS_FAILURE'}
   $next=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 12))
   if($next.Length -eq 0 -or $next.Length -gt 4194304){throw 'CLONE_JOURNAL_CONTROL_LIMIT'}
   # Laufidentität ist auch gegen irrtümliche InMemory-Änderung unveränderlich.
   Assert-JournalBytes $next $next $journalContext.Tuple
   if(!$journalContext.Stream){
    $journalContext.Stream=[IO.FileStream]::new($journal,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
   }else{
    if(!$journalContext.Prepared){throw 'CLONE_JOURNAL_NOT_PREPARED'}
    $before=Read-JournalBytes $journalContext.Stream $journalContext.ExpectedLength
    Assert-JournalBytes $before $journalContext.ExpectedBytes $journalContext.Tuple
    if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($before)) -cne $journalContext.ExpectedHash){throw 'CLONE_JOURNAL_DRIFT'}
   }
   $journalContext.Stream.Position=0
   $journalContext.Stream.Write($next,0,$next.Length)
   $journalContext.Stream.SetLength($next.Length)
   $journalContext.Stream.Flush($true)
   $after=Read-JournalBytes $journalContext.Stream $next.Length
   Assert-JournalBytes $after $next $journalContext.Tuple
   Assert-JournalPath;Check-Pins
   $journalContext.ExpectedBytes=$next
   $journalContext.ExpectedHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($after))
   $journalContext.ExpectedLength=$next.Length
   $journalContext.Prepared=$true
  }catch{$journalContext.Failed=$true;throw}
 }
 function Sql($c,[string]$s,[switch]$Scalar){
  $cmd=$c.CreateCommand();$cmd.CommandTimeout=120;$cmd.CommandText=$s
  try{if($Scalar){return $cmd.ExecuteScalar()};[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
 }
 function Batches($c,[string]$s){$script:batch=0;foreach($b in [regex]::Split($s,'(?im)^[ \t]*GO[ \t]*(?:--[^\r\n]*)?\r?$')){if($b.Trim()){$script:batch++;Sql $c $b}}}
 function Assert-OwnConsumerHealthy($connection){
  $cmd=$connection.CreateCommand()
  try{
   $cmd.CommandTimeout=15
   $cmd.CommandText=@'
DECLARE @ConsumerTransactionCount int,@ConsumerTransactionState int;
SET @ConsumerTransactionCount=@@TRANCOUNT;
SET @ConsumerTransactionState=XACT_STATE();
IF @ConsumerTransactionCount<>0 OR @ConsumerTransactionState<>0
 THROW 54935,N'CLONE_CONSUMER_SESSION_NOT_HEALTHY',1;
'@
   [void]$cmd.ExecuteNonQuery()
  }finally{$cmd.Dispose()}
 }
 function Open-Own($target,[string]$db){
  $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target));$c=$null
  try{$builder['Initial Catalog']=$db;$builder['Pooling']=$false;$builder['Enlist']=$false;$builder['ConnectRetryCount']=0;$builder['Connect Timeout']=15
   $c=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$c.Open();$connections.Add($c);return $c
  }catch{if($c){$c.Dispose()};throw}finally{$builder.Clear()}
 }
 function Preflight($c){
  $cmd=$c.CreateCommand();$cmd.CommandTimeout=60;$cmd.CommandText='SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
  $reader=$null
  try{$reader=$cmd.ExecuteReader();if($reader.FieldCount -ne 1 -or !$reader.Read()){throw 'CLONE_PREFLIGHT_INVALID'};[void]$reader.GetString(0)
   if($reader.Read() -or !$reader.NextResult() -or $reader.FieldCount -ne 2){throw 'CLONE_PREFLIGHT_INVALID'}
   while($reader.Read()){[void]$reader.GetString(0);[void]$reader.GetString(1)}
   if($reader.NextResult()){throw 'CLONE_PREFLIGHT_INVALID'}
  }finally{try{if($reader){$reader.Dispose()}}finally{$cmd.Dispose()}}
  if([int](Sql $c 'SELECT CONVERT(int,SERVERPROPERTY(''ProductMajorVersion''));' -Scalar) -ne $(if($Version -eq '2019'){15}else{17})){throw 'CLONE_MAJOR_MISMATCH'}
 }
 function SnapshotSql {
  return @'
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),COALESCE((
 SELECT o.object_id,o.name,o.type,m.definition,(SELECT e.name,CONVERT(varbinary(max),e.value) AS value FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id ORDER BY e.name,e.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES) AS properties
 FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.schema_id=SCHEMA_ID(N'toolbelt_metadata') ORDER BY o.object_id FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]'))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),COALESCE((
 SELECT e.class,e.name,e.minor_id,CONVERT(varbinary(max),e.value) AS value FROM sys.extended_properties e WHERE (e.class=0 AND e.name LIKE N'Toolbelt.Module.toolbelt.metadata.table-clone.%') OR(e.class=3 AND e.major_id=SCHEMA_ID(N'toolbelt_metadata')) ORDER BY e.class,e.name,e.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]'))),2);
'@
 }
 function Snapshot($c){$s=Sql $c (SnapshotSql) -Scalar;if($s -is [DBNull] -or !$s){throw 'CLONE_SNAPSHOT_NULL'};return [string]$s}
 function Read-PlanLineCandidate($connection,[int]$line){
  $result=[ordered]@{PlanExists=$false;ShapeCanonical=$false;QueryError=$false;LineNumber=$line;Ordinal=$null;ObjectKindCode='OTHER';PropertyCode='OTHER';SourceBaseTypeCode='OTHER'}
  $cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
DECLARE @PlanId int=OBJECT_ID(N'tempdb..#Wave1Plan',N'U');
SELECT CONVERT(bit,CASE WHEN @PlanId IS NOT NULL THEN 1 ELSE 0 END) AS PlanExists,
 CONVERT(bit,CASE WHEN @PlanId IS NOT NULL AND(SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@PlanId)=4
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@PlanId AND name=N'Ordinal' AND system_type_id=56 AND max_length=4 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@PlanId AND name=N'ObjectKind' AND system_type_id=167 AND max_length=32 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@PlanId AND name=N'TargetName' AND system_type_id=231 AND max_length=1552 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@PlanId AND name=N'ScriptText' AND system_type_id=231 AND max_length=-1 AND is_nullable=0)
 THEN 1 ELSE 0 END) AS ShapeCanonical;
'@
   try{
    $reader=$cmd.ExecuteReader()
    if($reader.FieldCount -ne 2 -or !$reader.Read()){throw 'CLONE_PLAN_DIAGNOSTIC_SHAPE'}
    $result.PlanExists=$reader.GetBoolean(0);$result.ShapeCanonical=$reader.GetBoolean(1)
    if($reader.Read() -or $reader.NextResult()){throw 'CLONE_PLAN_DIAGNOSTIC_SHAPE'}
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
   # Eine separate Command wird erst nach kanonischer Shapeprüfung kompiliert.
   if(!$result.ShapeCanonical -or $line -le 0){return $result}
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
;WITH Lines AS(
 SELECT Ordinal,ObjectKind,ScriptText,CONVERT(bigint,1)+(DATALENGTH(ScriptText)-DATALENGTH(REPLACE(ScriptText,NCHAR(10),N'')))/2 AS LineCount FROM #Wave1Plan
), Positioned AS(
 SELECT *,CONVERT(bigint,1)+COALESCE(SUM(LineCount) OVER(ORDER BY Ordinal ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) AS StartLine FROM Lines
), Matching AS(
 SELECT names.Code,CONVERT(nvarchar(32),SQL_VARIANT_PROPERTY(e.value,'BaseType')) AS BaseType,p.Ordinal
 FROM Positioned p CROSS JOIN(VALUES
 (N'bit'),(N'tinyint'),(N'smallint'),(N'int'),(N'bigint'),(N'decimal38'),(N'scale38'),(N'money'),(N'smallmoney'),
 (N'float'),(N'floatzero'),(N'real'),(N'date'),(N'time'),(N'datetime'),(N'smalldatetime'),(N'datetime2'),(N'datetimeoffset'),
 (N'char'),(N'varchar'),(N'nchar'),(N'nvarchar'),(N'binary'),(N'varbinary'),(N'utf8'),(N'guid'),(N'NULL')) names(Code)
 JOIN sys.extended_properties e ON e.class=1 AND e.major_id=OBJECT_ID(N'dbo.SyntheticWave1Source',N'U') AND e.minor_id=0
 AND CONVERT(varbinary(max),e.name)=CONVERT(varbinary(max),names.Code)
 WHERE @Line>=p.StartLine AND @Line<p.StartLine+p.LineCount AND p.ObjectKind='EXTENDED_PROPERTY'
 AND CHARINDEX(N'@name=N'''+REPLACE(names.Code,N'''',N'''''')+N'''',p.ScriptText COLLATE Latin1_General_100_BIN2)>0
)
SELECT p.Ordinal,
 CASE p.ObjectKind WHEN 'SESSION_OPTION' THEN 'SESSION_OPTION' WHEN 'TABLE' THEN 'TABLE' WHEN 'DEFAULT' THEN 'DEFAULT' WHEN 'CHECK' THEN 'CHECK'
 WHEN 'PRIMARY_KEY' THEN 'PRIMARY_KEY' WHEN 'UNIQUE_CONSTRAINT' THEN 'UNIQUE_CONSTRAINT' WHEN 'INDEX' THEN 'INDEX' WHEN 'EXTENDED_PROPERTY' THEN 'EXTENDED_PROPERTY' ELSE 'OTHER' END AS ObjectKindCode,
 CASE WHEN m.CountMatches=1 THEN m.Code ELSE N'OTHER' END AS PropertyCode,
 CASE WHEN m.CountMatches=1 AND m.Code=N'NULL' AND m.BaseType IS NULL THEN N'SQLNULL'
 WHEN m.CountMatches=1 THEN CASE m.BaseType WHEN N'bit' THEN N'bit' WHEN N'tinyint' THEN N'tinyint' WHEN N'smallint' THEN N'smallint' WHEN N'int' THEN N'int'
 WHEN N'bigint' THEN N'bigint' WHEN N'decimal' THEN N'decimal' WHEN N'numeric' THEN N'numeric' WHEN N'money' THEN N'money' WHEN N'smallmoney' THEN N'smallmoney'
 WHEN N'float' THEN N'float' WHEN N'real' THEN N'real' WHEN N'date' THEN N'date' WHEN N'time' THEN N'time' WHEN N'datetime' THEN N'datetime'
 WHEN N'smalldatetime' THEN N'smalldatetime' WHEN N'datetime2' THEN N'datetime2' WHEN N'datetimeoffset' THEN N'datetimeoffset' WHEN N'char' THEN N'char'
 WHEN N'varchar' THEN N'varchar' WHEN N'nchar' THEN N'nchar' WHEN N'nvarchar' THEN N'nvarchar' WHEN N'binary' THEN N'binary' WHEN N'varbinary' THEN N'varbinary'
 WHEN N'uniqueidentifier' THEN N'uniqueidentifier' ELSE N'OTHER' END ELSE N'OTHER' END AS SourceBaseTypeCode
FROM Positioned p OUTER APPLY(SELECT COUNT(*) AS CountMatches,MAX(Code) AS Code,MAX(BaseType) AS BaseType FROM Matching WHERE Ordinal=p.Ordinal) m
WHERE @Line>=p.StartLine AND @Line<p.StartLine+p.LineCount;
'@
   [void]$cmd.Parameters.Add('@Line',[Data.SqlDbType]::Int);$cmd.Parameters['@Line'].Value=$line
   try{
    $reader=$cmd.ExecuteReader()
    if($reader.FieldCount -ne 4){throw 'CLONE_PLAN_DIAGNOSTIC_SHAPE'}
    if($reader.Read()){
     $result.Ordinal=$reader.GetInt32(0);$result.ObjectKindCode=$reader.GetString(1);$result.PropertyCode=$reader.GetString(2);$result.SourceBaseTypeCode=$reader.GetString(3)
     if($reader.Read()){throw 'CLONE_PLAN_DIAGNOSTIC_SHAPE'}
    }
    if($reader.NextResult()){throw 'CLONE_PLAN_DIAGNOSTIC_SHAPE'}
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{
   $result.QueryError=$true;$result.Ordinal=$null;$result.ObjectKindCode='OTHER';$result.PropertyCode='OTHER';$result.SourceBaseTypeCode='OTHER'
  }finally{
   try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true}}
  }
  return $result
 }
 function Read-TemporalReference($connection){
  $result=[ordered]@{QueryError=$false;Cases=@()};$cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
SELECT TypeCode,CurrentParseBool,CurrentRawBytesEqualBool,CurrentBaseTypeEqualBool,CurrentPrecisionEqualBool,CurrentScaleEqualBool,CurrentMaxLengthEqualBool,CurrentCollationEqualBool,CurrentFullRoundtripBool,AlternativeParseBool,AlternativeRawBytesEqualBool,AlternativeBaseTypeEqualBool,AlternativePrecisionEqualBool,AlternativeScaleEqualBool,AlternativeMaxLengthEqualBool,AlternativeCollationEqualBool,AlternativeFullRoundtripBool FROM (
SELECT N'date' AS TypeCode,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL THEN 1 ELSE 0 END) AS CurrentParseBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS CurrentRawBytesEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS CurrentBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS CurrentPrecisionEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS CurrentScaleEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS CurrentMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentCollationEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentFullRoundtripBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS AlternativeParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS AlternativeRawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS AlternativePrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeCollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeFullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(date,N'2001-02-03')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(date,CONVERT(nvarchar(128),CONVERT(datetime2(7),O.Value),126))) AS Value) C
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(date,CONVERT(nvarchar(128),CONVERT(date,O.Value),126),126)) AS Value) A
UNION ALL
SELECT N'time' AS TypeCode,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL THEN 1 ELSE 0 END) AS CurrentParseBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS CurrentRawBytesEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS CurrentBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS CurrentPrecisionEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS CurrentScaleEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS CurrentMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentCollationEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentFullRoundtripBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS AlternativeParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS AlternativeRawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS AlternativePrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeCollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeFullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(time(7),N'12:34:56.1234567')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(time(7),CONVERT(nvarchar(128),CONVERT(time(7),O.Value),126))) AS Value) C
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(time(7),CONVERT(nvarchar(128),CONVERT(time(7),O.Value),126),126)) AS Value) A
UNION ALL
SELECT N'datetime' AS TypeCode,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL THEN 1 ELSE 0 END) AS CurrentParseBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS CurrentRawBytesEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS CurrentBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS CurrentPrecisionEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS CurrentScaleEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS CurrentMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentCollationEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentFullRoundtripBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS AlternativeParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS AlternativeRawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS AlternativePrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeCollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeFullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetime,N'2001-02-03T12:34:56.997')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetime,CONVERT(nvarchar(128),CONVERT(datetime,O.Value),126))) AS Value) C
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetime,CONVERT(nvarchar(128),CONVERT(datetime,O.Value),126),126)) AS Value) A
UNION ALL
SELECT N'smalldatetime' AS TypeCode,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL THEN 1 ELSE 0 END) AS CurrentParseBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS CurrentRawBytesEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS CurrentBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS CurrentPrecisionEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS CurrentScaleEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS CurrentMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentCollationEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentFullRoundtripBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS AlternativeParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS AlternativeRawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS AlternativePrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeCollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeFullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(smalldatetime,N'2001-02-03T12:34:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(smalldatetime,CONVERT(nvarchar(128),CONVERT(datetime2(7),O.Value),126))) AS Value) C
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(smalldatetime,CONVERT(nvarchar(128),CONVERT(smalldatetime,O.Value),126),126)) AS Value) A
UNION ALL
SELECT N'datetime2' AS TypeCode,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL THEN 1 ELSE 0 END) AS CurrentParseBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS CurrentRawBytesEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS CurrentBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS CurrentPrecisionEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS CurrentScaleEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS CurrentMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentCollationEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentFullRoundtripBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS AlternativeParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS AlternativeRawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS AlternativePrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeCollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeFullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetime2(7),N'2001-02-03T12:34:56.1234567')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetime2(7),CONVERT(nvarchar(128),CONVERT(datetime2(7),O.Value),126))) AS Value) C
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetime2(7),CONVERT(nvarchar(128),CONVERT(datetime2(7),O.Value),126),126)) AS Value) A
UNION ALL
SELECT N'datetimeoffset' AS TypeCode,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL THEN 1 ELSE 0 END) AS CurrentParseBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS CurrentRawBytesEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS CurrentBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS CurrentPrecisionEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS CurrentScaleEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS CurrentMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentCollationEqualBool,
 CONVERT(bit,CASE WHEN C.Value IS NOT NULL AND CONVERT(varbinary(max),C.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(C.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(C.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(C.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(C.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(C.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(C.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CurrentFullRoundtripBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS AlternativeParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS AlternativeRawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeBaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS AlternativePrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeMaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeCollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS AlternativeFullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) C
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),127),127)) AS Value) A
) Q ORDER BY CASE TypeCode WHEN N'date' THEN 1 WHEN N'time' THEN 2 WHEN N'datetime' THEN 3 WHEN N'smalldatetime' THEN 4 WHEN N'datetime2' THEN 5 WHEN N'datetimeoffset' THEN 6 END;
'@
   try{
    $reader=$cmd.ExecuteReader()
    $columns=@('TypeCode','CurrentParseBool','CurrentRawBytesEqualBool','CurrentBaseTypeEqualBool','CurrentPrecisionEqualBool','CurrentScaleEqualBool','CurrentMaxLengthEqualBool','CurrentCollationEqualBool','CurrentFullRoundtripBool','AlternativeParseBool','AlternativeRawBytesEqualBool','AlternativeBaseTypeEqualBool','AlternativePrecisionEqualBool','AlternativeScaleEqualBool','AlternativeMaxLengthEqualBool','AlternativeCollationEqualBool','AlternativeFullRoundtripBool')
    if($reader.FieldCount -ne $columns.Count){throw 'CLONE_TEMPORAL_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt $columns.Count;$field++){
     $type=if($field -eq 0){'nvarchar'}else{'bit'}
     if($reader.GetName($field) -cne $columns[$field] -or $reader.GetDataTypeName($field) -cne $type){throw 'CLONE_TEMPORAL_DIAGNOSTIC_SHAPE'}
    }
    $expected=@('date','time','datetime','smalldatetime','datetime2','datetimeoffset');$cases=@();$index=0
    while($reader.Read()){
     if($index -ge 6 -or $reader.IsDBNull(0) -or $reader.GetString(0) -cne $expected[$index]){throw 'CLONE_TEMPORAL_DIAGNOSTIC_SHAPE'}
     $case=[ordered]@{TypeCode=$reader.GetString(0)}
     for($field=1;$field -lt $columns.Count;$field++){
      if($reader.IsDBNull($field)){throw 'CLONE_TEMPORAL_DIAGNOSTIC_SHAPE'}
      $case[$columns[$field]]=$reader.GetBoolean($field)
     }
     $cases+=,$case;$index++
    }
    if($index -ne 6 -or $reader.NextResult()){throw 'CLONE_TEMPORAL_DIAGNOSTIC_SHAPE'}
    $result.Cases=$cases
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Cases=@()}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Cases=@()}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Cases=@()}}}
  return $result
 }
 function Read-PropertyReference($connection){
  $result=[ordered]@{QueryError=$false;ShapeCanonical=$false;SourceExists=$false;TargetExists=$false;SourceCount=$null;TargetCount=$null;UnknownSourceCount=$null;UnknownTargetCount=$null;Cases=@()};$cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
DECLARE @Source int=OBJECT_ID(N'dbo.SyntheticWave1Source',N'U'),@Target int=OBJECT_ID(N'dbo.SyntheticWave1Target',N'U');
WITH Expected(Ordinal,Code) AS(SELECT Ordinal,Code FROM (VALUES(1,N'bit'),(2,N'tinyint'),(3,N'smallint'),(4,N'int'),(5,N'bigint'),(6,N'decimal38'),(7,N'scale38'),(8,N'money'),(9,N'smallmoney'),(10,N'float'),(11,N'floatzero'),(12,N'real'),(13,N'date'),(14,N'time'),(15,N'datetime'),(16,N'smalldatetime'),(17,N'datetime2'),(18,N'datetimeoffset'),(19,N'char'),(20,N'varchar'),(21,N'nchar'),(22,N'nvarchar'),(23,N'binary'),(24,N'varbinary'),(25,N'utf8'),(26,N'guid'),(27,N'NULL')) E(Ordinal,Code))
SELECT CONVERT(bit,CASE WHEN @Source IS NOT NULL THEN 1 ELSE 0 END) AS SourceExists,
 CONVERT(bit,CASE WHEN @Target IS NOT NULL THEN 1 ELSE 0 END) AS TargetExists,
 (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@Source AND minor_id=0) AS SourceCount,
 (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@Target AND minor_id=0) AS TargetCount,
 (SELECT COUNT(*) FROM sys.extended_properties S WHERE S.class=1 AND S.major_id=@Source AND S.minor_id=0 AND NOT EXISTS(SELECT 1 FROM Expected E WHERE CONVERT(varbinary(max),E.Code)=CONVERT(varbinary(max),S.name))) AS UnknownSourceCount,
 (SELECT COUNT(*) FROM sys.extended_properties T WHERE T.class=1 AND T.major_id=@Target AND T.minor_id=0 AND NOT EXISTS(SELECT 1 FROM Expected E WHERE CONVERT(varbinary(max),E.Code)=CONVERT(varbinary(max),T.name))) AS UnknownTargetCount;
WITH Expected(Ordinal,Code) AS(SELECT Ordinal,Code FROM (VALUES(1,N'bit'),(2,N'tinyint'),(3,N'smallint'),(4,N'int'),(5,N'bigint'),(6,N'decimal38'),(7,N'scale38'),(8,N'money'),(9,N'smallmoney'),(10,N'float'),(11,N'floatzero'),(12,N'real'),(13,N'date'),(14,N'time'),(15,N'datetime'),(16,N'smalldatetime'),(17,N'datetime2'),(18,N'datetimeoffset'),(19,N'char'),(20,N'varchar'),(21,N'nchar'),(22,N'nvarchar'),(23,N'binary'),(24,N'varbinary'),(25,N'utf8'),(26,N'guid'),(27,N'NULL')) E(Ordinal,Code))
SELECT E.Code AS PropertyCode,CONVERT(bit,CASE WHEN S.name IS NOT NULL THEN 1 ELSE 0 END) AS SourcePresent,
 CONVERT(bit,CASE WHEN T.name IS NOT NULL THEN 1 ELSE 0 END) AS TargetPresent,
 CONVERT(bit,CASE WHEN S.name IS NOT NULL AND T.name IS NOT NULL AND (CONVERT(varbinary(max),S.value)=CONVERT(varbinary(max),T.value) OR (S.value IS NULL AND T.value IS NULL)) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
CONVERT(bit,CASE WHEN S.name IS NOT NULL AND T.name IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(S.value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(T.value,'BaseType')) OR (SQL_VARIANT_PROPERTY(S.value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(T.value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN S.name IS NOT NULL AND T.name IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(S.value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(T.value,'Precision')) OR (SQL_VARIANT_PROPERTY(S.value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(T.value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN S.name IS NOT NULL AND T.name IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(S.value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(T.value,'Scale')) OR (SQL_VARIANT_PROPERTY(S.value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(T.value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN S.name IS NOT NULL AND T.name IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(S.value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(T.value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(S.value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(T.value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN S.name IS NOT NULL AND T.name IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(S.value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(T.value,'Collation')) OR (SQL_VARIANT_PROPERTY(S.value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(T.value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool
FROM Expected E
LEFT JOIN sys.extended_properties S ON S.class=1 AND S.major_id=@Source AND S.minor_id=0 AND CONVERT(varbinary(max),S.name)=CONVERT(varbinary(max),E.Code)
LEFT JOIN sys.extended_properties T ON T.class=1 AND T.major_id=@Target AND T.minor_id=0 AND CONVERT(varbinary(max),T.name)=CONVERT(varbinary(max),E.Code)
ORDER BY E.Ordinal;
'@
   try{
    $reader=$cmd.ExecuteReader();$summaryColumns=@('SourceExists','TargetExists','SourceCount','TargetCount','UnknownSourceCount','UnknownTargetCount')
    if($reader.FieldCount -ne 6){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 6;$field++){
     $type=if($field -lt 2){'bit'}else{'int'}
     if($reader.GetName($field) -cne $summaryColumns[$field] -or $reader.GetDataTypeName($field) -cne $type){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
    }
    if(!$reader.Read()){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 6;$field++){
     if($reader.IsDBNull($field)){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
     $result[$summaryColumns[$field]]=if($field -lt 2){$reader.GetBoolean($field)}else{$reader.GetInt32($field)}
    }
    if($reader.Read() -or !$reader.NextResult()){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
    $columns=@('PropertyCode','SourcePresent','TargetPresent','RawBytesEqualBool','BaseTypeEqualBool','PrecisionEqualBool','ScaleEqualBool','MaxLengthEqualBool','CollationEqualBool');$expected=@('bit','tinyint','smallint','int','bigint','decimal38','scale38','money','smallmoney','float','floatzero','real','date','time','datetime','smalldatetime','datetime2','datetimeoffset','char','varchar','nchar','nvarchar','binary','varbinary','utf8','guid','NULL');$cases=@();$index=0
    if($reader.FieldCount -ne 9){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 9;$field++){
     $type=if($field -eq 0){'nvarchar'}else{'bit'}
     if($reader.GetName($field) -cne $columns[$field] -or $reader.GetDataTypeName($field) -cne $type){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
    }
    while($reader.Read()){
     if($index -ge 27 -or $reader.IsDBNull(0) -or $reader.GetString(0) -cne $expected[$index]){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
     $case=[ordered]@{PropertyCode=$reader.GetString(0)}
     for($field=1;$field -lt 9;$field++){
      if($reader.IsDBNull($field)){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
      $case[$columns[$field]]=$reader.GetBoolean($field)
     }
     $cases+=,$case;$index++
    }
    if($index -ne 27 -or $reader.NextResult()){throw 'CLONE_PROPERTY_DIAGNOSTIC_SHAPE'}
    $result.Cases=$cases
    $result.ShapeCanonical=($result.SourceExists -and $result.TargetExists -and $result.SourceCount -eq 27 -and $result.TargetCount -eq 27 -and $result.UnknownSourceCount -eq 0 -and $result.UnknownTargetCount -eq 0)
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Cases=@();$result.ShapeCanonical=$false}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Cases=@();$result.ShapeCanonical=$false}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Cases=@();$result.ShapeCanonical=$false}}}
  return $result
 }
 function Read-DtoCandidateReference($connection){
  $result=[ordered]@{QueryError=$false;Cases=@()};$cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
SELECT CaseCode,CandidateCode,ParseBool,RawBytesEqualBool,BaseTypeEqualBool,PrecisionEqualBool,ScaleEqualBool,MaxLengthEqualBool,CollationEqualBool,FullRoundtripBool FROM (
SELECT 1 AS Ordinal,N'S0_ZERO_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 2 AS Ordinal,N'S0_ZERO_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 3 AS Ordinal,N'S0_ZERO_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T23:59:59.9999999+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 4 AS Ordinal,N'S0_ZERO_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T23:59:59.9999999+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 5 AS Ordinal,N'S0_POS_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 6 AS Ordinal,N'S0_POS_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 7 AS Ordinal,N'S0_POS_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T23:59:59.9999999+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 8 AS Ordinal,N'S0_POS_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T23:59:59.9999999+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 9 AS Ordinal,N'S0_NEG_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 10 AS Ordinal,N'S0_NEG_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T12:34:56.1234567-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 11 AS Ordinal,N'S0_NEG_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T23:59:59.9999999-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 12 AS Ordinal,N'S0_NEG_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(0),N'2001-02-03T23:59:59.9999999-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(0),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 13 AS Ordinal,N'S3_ZERO_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 14 AS Ordinal,N'S3_ZERO_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 15 AS Ordinal,N'S3_ZERO_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T23:59:59.9999999+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 16 AS Ordinal,N'S3_ZERO_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T23:59:59.9999999+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 17 AS Ordinal,N'S3_POS_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 18 AS Ordinal,N'S3_POS_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 19 AS Ordinal,N'S3_POS_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T23:59:59.9999999+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 20 AS Ordinal,N'S3_POS_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T23:59:59.9999999+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 21 AS Ordinal,N'S3_NEG_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 22 AS Ordinal,N'S3_NEG_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T12:34:56.1234567-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 23 AS Ordinal,N'S3_NEG_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T23:59:59.9999999-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 24 AS Ordinal,N'S3_NEG_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(3),N'2001-02-03T23:59:59.9999999-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(3),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 25 AS Ordinal,N'S7_ZERO_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 26 AS Ordinal,N'S7_ZERO_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 27 AS Ordinal,N'S7_ZERO_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T23:59:59.9999999+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 28 AS Ordinal,N'S7_ZERO_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T23:59:59.9999999+00:00')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 29 AS Ordinal,N'S7_POS_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 30 AS Ordinal,N'S7_POS_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 31 AS Ordinal,N'S7_POS_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T23:59:59.9999999+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 32 AS Ordinal,N'S7_POS_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T23:59:59.9999999+05:30')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 33 AS Ordinal,N'S7_NEG_FRACTION' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 34 AS Ordinal,N'S7_NEG_FRACTION' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
UNION ALL
SELECT 35 AS Ordinal,N'S7_NEG_ENDSECOND' AS CaseCode,
 N'DEFAULT' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T23:59:59.9999999-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value)))) AS Value) A
UNION ALL
SELECT 36 AS Ordinal,N'S7_NEG_ENDSECOND' AS CaseCode,
 N'STYLE121' AS CandidateCode,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL THEN 1 ELSE 0 END) AS ParseBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) THEN 1 ELSE 0 END) AS RawBytesEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) THEN 1 ELSE 0 END) AS BaseTypeEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) THEN 1 ELSE 0 END) AS PrecisionEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) THEN 1 ELSE 0 END) AS ScaleEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) THEN 1 ELSE 0 END) AS MaxLengthEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS CollationEqualBool,
 CONVERT(bit,CASE WHEN A.Value IS NOT NULL AND CONVERT(varbinary(max),A.Value)=CONVERT(varbinary(max),O.Value) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'BaseType'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'BaseType')) OR (SQL_VARIANT_PROPERTY(A.Value,'BaseType') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'BaseType') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Precision'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Precision')) OR (SQL_VARIANT_PROPERTY(A.Value,'Precision') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Precision') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Scale'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Scale')) OR (SQL_VARIANT_PROPERTY(A.Value,'Scale') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Scale') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'MaxLength'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'MaxLength')) OR (SQL_VARIANT_PROPERTY(A.Value,'MaxLength') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'MaxLength') IS NULL)) AND (CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(A.Value,'Collation'))=CONVERT(varbinary(max),SQL_VARIANT_PROPERTY(O.Value,'Collation')) OR (SQL_VARIANT_PROPERTY(A.Value,'Collation') IS NULL AND SQL_VARIANT_PROPERTY(O.Value,'Collation') IS NULL)) THEN 1 ELSE 0 END) AS FullRoundtripBool
FROM (SELECT CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T23:59:59.9999999-12:34')) AS Value) O
CROSS APPLY(SELECT CONVERT(sql_variant,TRY_CONVERT(datetimeoffset(7),CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),O.Value),121))) AS Value) A
) Q ORDER BY Ordinal;
'@
   try{
    $reader=$cmd.ExecuteReader();$columns=@('CaseCode','CandidateCode','ParseBool','RawBytesEqualBool','BaseTypeEqualBool','PrecisionEqualBool','ScaleEqualBool','MaxLengthEqualBool','CollationEqualBool','FullRoundtripBool');$expected=@('S0_ZERO_FRACTION|DEFAULT','S0_ZERO_FRACTION|STYLE121','S0_ZERO_ENDSECOND|DEFAULT','S0_ZERO_ENDSECOND|STYLE121','S0_POS_FRACTION|DEFAULT','S0_POS_FRACTION|STYLE121','S0_POS_ENDSECOND|DEFAULT','S0_POS_ENDSECOND|STYLE121','S0_NEG_FRACTION|DEFAULT','S0_NEG_FRACTION|STYLE121','S0_NEG_ENDSECOND|DEFAULT','S0_NEG_ENDSECOND|STYLE121','S3_ZERO_FRACTION|DEFAULT','S3_ZERO_FRACTION|STYLE121','S3_ZERO_ENDSECOND|DEFAULT','S3_ZERO_ENDSECOND|STYLE121','S3_POS_FRACTION|DEFAULT','S3_POS_FRACTION|STYLE121','S3_POS_ENDSECOND|DEFAULT','S3_POS_ENDSECOND|STYLE121','S3_NEG_FRACTION|DEFAULT','S3_NEG_FRACTION|STYLE121','S3_NEG_ENDSECOND|DEFAULT','S3_NEG_ENDSECOND|STYLE121','S7_ZERO_FRACTION|DEFAULT','S7_ZERO_FRACTION|STYLE121','S7_ZERO_ENDSECOND|DEFAULT','S7_ZERO_ENDSECOND|STYLE121','S7_POS_FRACTION|DEFAULT','S7_POS_FRACTION|STYLE121','S7_POS_ENDSECOND|DEFAULT','S7_POS_ENDSECOND|STYLE121','S7_NEG_FRACTION|DEFAULT','S7_NEG_FRACTION|STYLE121','S7_NEG_ENDSECOND|DEFAULT','S7_NEG_ENDSECOND|STYLE121');$cases=@();$index=0
    if($reader.FieldCount -ne 10){throw 'CLONE_DTO_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 10;$field++){
     $type=if($field -lt 2){'nvarchar'}else{'bit'}
     if($reader.GetName($field) -cne $columns[$field] -or $reader.GetDataTypeName($field) -cne $type){throw 'CLONE_DTO_DIAGNOSTIC_SHAPE'}
    }
    while($reader.Read()){
     if($index -ge 36 -or $reader.IsDBNull(0) -or $reader.IsDBNull(1) -or ($reader.GetString(0)+'|'+$reader.GetString(1)) -cne $expected[$index]){throw 'CLONE_DTO_DIAGNOSTIC_SHAPE'}
     $case=[ordered]@{CaseCode=$reader.GetString(0);CandidateCode=$reader.GetString(1)}
     for($field=2;$field -lt 10;$field++){
      if($reader.IsDBNull($field)){throw 'CLONE_DTO_DIAGNOSTIC_SHAPE'}
      $case[$columns[$field]]=$reader.GetBoolean($field)
     }
     $cases+=,$case;$index++
    }
    if($index -ne 36 -or $reader.NextResult()){throw 'CLONE_DTO_DIAGNOSTIC_SHAPE'}
    $result.Cases=$cases
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Cases=@()}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Cases=@()}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Cases=@()}}}
  return $result
 }
 function Capture-CoreDefinitionBaseline($connection){
  $result=[ordered]@{QueryError=$false;Hash=$null};$cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
SELECT HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P')))) AS DefinitionHash;
'@
   try{
    $reader=$cmd.ExecuteReader()
    if($reader.FieldCount -ne 1 -or $reader.GetName(0) -cne 'DefinitionHash' -or $reader.GetDataTypeName(0) -cne 'varbinary' -or !$reader.Read() -or $reader.IsDBNull(0)){throw 'CLONE_BASELINE_DIAGNOSTIC_SHAPE'}
    $hash=[byte[]]$reader.GetValue(0)
    if($hash.Length -ne 32 -or $reader.Read() -or $reader.NextResult()){throw 'CLONE_BASELINE_DIAGNOSTIC_SHAPE'}
    $result.Hash=$hash
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Hash=$null}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Hash=$null}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Hash=$null}}}
  return $result
 }
 function Read-TempCollisionReference($connection,$baseline){
  $result=[ordered]@{QueryError=$true;Checks=@{}};$cmd=$null;$reader=$null
  if($null -eq $baseline -or $baseline.QueryError -or $null -eq $baseline.Hash -or $baseline.Hash.Length -ne 32){return $result}
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
DECLARE @Id int=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P');
DECLARE @LiveHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@Id)));
SELECT CONVERT(bit,CASE WHEN OBJECT_ID(N'tempdb..#tbx_TableClone_Plan',N'U') IS NOT NULL THEN 1 ELSE 0 END) AS InternalPlanExists,
 CONVERT(bit,CASE WHEN OBJECT_ID(N'tempdb..#BytePlan',N'U') IS NOT NULL THEN 1 ELSE 0 END) AS BytePlanExists,
 CONVERT(bit,CASE WHEN OBJECT_ID(N'tempdb..#ByteSnapshot',N'U') IS NOT NULL THEN 1 ELSE 0 END) AS ByteSnapshotExists,
 CONVERT(bit,CASE WHEN @LiveHash IS NOT NULL AND DATALENGTH(@LiveHash)=32 THEN 1 ELSE 0 END) AS DefinitionPresent,
 CONVERT(bit,CASE WHEN @LiveHash=@Baseline THEN 1 ELSE 0 END) AS InstalledDefinitionBaselineMatch,
 CONVERT(bit,CASE WHEN (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@Id AND minor_id=0 AND name=N'Toolbelt.SourceHash')=1 THEN 1 ELSE 0 END) AS SourceHashPropertyUnique,
 CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@Id AND minor_id=0 AND name=N'Toolbelt.SourceHash'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),CONVERT(nvarchar(64),CONVERT(varchar(64),@LiveHash,2)))) THEN 1 ELSE 0 END) AS SourceHashMatchesLiveDefinition,
 CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@Id AND minor_id=0 AND name=N'Toolbelt.SourceHash'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),CONVERT(nvarchar(64),CONVERT(varchar(64),@Baseline,2)))) THEN 1 ELSE 0 END) AS SourceHashMatchesBaseline;
'@
   [void]$cmd.Parameters.Add('@Baseline',[Data.SqlDbType]::VarBinary,32);$cmd.Parameters['@Baseline'].Value=[byte[]]$baseline.Hash
   try{
    $reader=$cmd.ExecuteReader();$fields=@('InternalPlanExists','BytePlanExists','ByteSnapshotExists','DefinitionPresent','InstalledDefinitionBaselineMatch','SourceHashPropertyUnique','SourceHashMatchesLiveDefinition','SourceHashMatchesBaseline');$checks=[ordered]@{}
    if($reader.FieldCount -ne 8){throw 'CLONE_TEMP_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 8;$field++){if($reader.GetName($field) -cne $fields[$field] -or $reader.GetDataTypeName($field) -cne 'bit'){throw 'CLONE_TEMP_DIAGNOSTIC_SHAPE'}}
    if(!$reader.Read()){throw 'CLONE_TEMP_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 8;$field++){if($reader.IsDBNull($field)){throw 'CLONE_TEMP_DIAGNOSTIC_SHAPE'};$checks[$fields[$field]]=$reader.GetBoolean($field)}
    if($reader.Read() -or $reader.NextResult()){throw 'CLONE_TEMP_DIAGNOSTIC_SHAPE'}
    $result.Checks=$checks;$result.QueryError=$false
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Checks=@{}}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Checks=@{}}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Checks=@{}}}}
  return $result
 }
 function Read-ByteBoundaryReference($connection){
  $result=[ordered]@{QueryError=$false;BytePlanShapeCanonical=$false;ByteSnapshotShapeCanonical=$false;Checks=@{}};$cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
SELECT CONVERT(bit,CASE WHEN OBJECT_ID(N'tempdb..#BytePlan',N'U') IS NOT NULL
 AND(SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#BytePlan'))=4
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#BytePlan') AND name=N'Ordinal' AND system_type_id=56 AND max_length=4 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#BytePlan') AND name=N'ObjectKind' AND system_type_id=167 AND max_length=32 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#BytePlan') AND name=N'TargetName' AND system_type_id=231 AND max_length=1552 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#BytePlan') AND name=N'ScriptText' AND system_type_id=231 AND max_length=-1 AND is_nullable=0)
 THEN 1 ELSE 0 END) AS BytePlanShapeCanonical,CONVERT(bit,CASE WHEN OBJECT_ID(N'tempdb..#ByteSnapshot',N'U') IS NOT NULL
 AND(SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#ByteSnapshot'))=4
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#ByteSnapshot') AND name=N'Ordinal' AND system_type_id=56 AND max_length=4 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#ByteSnapshot') AND name=N'ObjectKind' AND system_type_id=167 AND max_length=32 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#ByteSnapshot') AND name=N'TargetName' AND system_type_id=231 AND max_length=1552 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#ByteSnapshot') AND name=N'ScriptText' AND system_type_id=231 AND max_length=-1 AND is_nullable=0)
 THEN 1 ELSE 0 END) AS ByteSnapshotShapeCanonical;
'@
   try{
    $reader=$cmd.ExecuteReader()
    if($reader.FieldCount -ne 2 -or $reader.GetName(0) -cne 'BytePlanShapeCanonical' -or $reader.GetName(1) -cne 'ByteSnapshotShapeCanonical' -or $reader.GetDataTypeName(0) -cne 'bit' -or $reader.GetDataTypeName(1) -cne 'bit' -or !$reader.Read() -or $reader.IsDBNull(0) -or $reader.IsDBNull(1)){throw 'CLONE_BYTE_DIAGNOSTIC_SHAPE'}
    $result.BytePlanShapeCanonical=$reader.GetBoolean(0);$result.ByteSnapshotShapeCanonical=$reader.GetBoolean(1)
    if($reader.Read() -or $reader.NextResult()){throw 'CLONE_BYTE_DIAGNOSTIC_SHAPE'}
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
   if(!$result.BytePlanShapeCanonical -or !$result.ByteSnapshotShapeCanonical){return $result}
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
DECLARE @Source int=OBJECT_ID(N'dbo.SyntheticByteSource',N'U');
WITH ExpectedNames AS(SELECT N'Byte'+RIGHT(N'000'+CONVERT(nvarchar(3),1+100*H.N+10*T.N+U.N),3) AS Code
 FROM(VALUES(0),(1))H(N) CROSS JOIN(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))T(N)
 CROSS JOIN(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))U(N))
SELECT CONVERT(bit,CASE WHEN (SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #BytePlan)=2097152 THEN 1 ELSE 0 END) AS BytePlanSumAtLimit,
 CONVERT(bit,CASE WHEN (SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #ByteSnapshot)=2097152 THEN 1 ELSE 0 END) AS ByteSnapshotSumAtLimit,
 CONVERT(bit,CASE WHEN (SELECT COUNT(*) FROM #BytePlan)=(SELECT COUNT(*) FROM #ByteSnapshot) THEN 1 ELSE 0 END) AS PlanSnapshotRowCountEqual,
 CONVERT(bit,CASE WHEN NOT EXISTS(SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #BytePlan EXCEPT SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #ByteSnapshot)
 AND NOT EXISTS(SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #ByteSnapshot EXCEPT SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #BytePlan) THEN 1 ELSE 0 END) AS PlanSnapshotRowsByteEqual,
 CONVERT(bit,CASE WHEN @Source IS NOT NULL AND(SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@Source AND minor_id=0)=200 THEN 1 ELSE 0 END) AS SourcePropertyCount200,
 CONVERT(bit,CASE WHEN @Source IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sys.extended_properties S WHERE class=1 AND major_id=@Source AND minor_id=0 AND NOT EXISTS(SELECT 1 FROM ExpectedNames E WHERE CONVERT(varbinary(max),E.Code)=CONVERT(varbinary(max),S.name))) THEN 1 ELSE 0 END) AS SourceAllPropertyNamesKnown;
'@
   try{
    $reader=$cmd.ExecuteReader();$fields=@('BytePlanSumAtLimit','ByteSnapshotSumAtLimit','PlanSnapshotRowCountEqual','PlanSnapshotRowsByteEqual','SourcePropertyCount200','SourceAllPropertyNamesKnown');$checks=[ordered]@{}
    if($reader.FieldCount -ne 6){throw 'CLONE_BYTE_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 6;$field++){if($reader.GetName($field) -cne $fields[$field] -or $reader.GetDataTypeName($field) -cne 'bit'){throw 'CLONE_BYTE_DIAGNOSTIC_SHAPE'}}
    if(!$reader.Read()){throw 'CLONE_BYTE_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 6;$field++){if($reader.IsDBNull($field)){throw 'CLONE_BYTE_DIAGNOSTIC_SHAPE'};$checks[$fields[$field]]=$reader.GetBoolean($field)}
    if($reader.Read() -or $reader.NextResult()){throw 'CLONE_BYTE_DIAGNOSTIC_SHAPE'}
    $result.Checks=$checks
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Checks=@{}}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Checks=@{}}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Checks=@{}}}}
  return $result
 }
 function Read-DefinitionWholePrefix($connection){
  $result=[ordered]@{QueryError=$true;Observation=$null};$cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15
   $cmd.CommandText=@'
DECLARE @Definition varbinary(max)=CONVERT(varbinary(max),OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P')));
DECLARE @Source3 nvarchar(max)=N'-- Kanonischer Catalog-/Scriptkern; keine Ausführung des erzeugten Scripttexts.'+NCHAR(10)+
 N'-- Interner Aufruf ausschließlich über öffentliche Namespace-/Helpgrenze.'+NCHAR(10)+
 N'-- Definitionen werden wörtlich erhalten, kein Parser oder neue Scalar-Funktion.'+NCHAR(10);
DECLARE @Source2 nvarchar(max)=N'-- Interner Aufruf ausschließlich über öffentliche Namespace-/Helpgrenze.'+NCHAR(10)+
 N'-- Definitionen werden wörtlich erhalten, kein Parser oder neue Scalar-Funktion.'+NCHAR(10);
DECLARE @Header nvarchar(max)=N'CREATE   PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'+NCHAR(10);
DECLARE @Candidates TABLE(Id int NOT NULL PRIMARY KEY,Signature varbinary(max) NOT NULL);
INSERT @Candidates(Id,Signature)VALUES
 (1,CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),NCHAR(10)),0)+@Source3+@Header)),
 (2,CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),NCHAR(10)),1)+@Source3+@Header)),
 (3,CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),NCHAR(10)),2)+@Source3+@Header)),
 (4,CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),NCHAR(10)),3)+@Source3+@Header)),
 (5,CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),NCHAR(10)),4)+@Source3+@Header)),
 (6,CONVERT(varbinary(max),NCHAR(10)+@Source2+@Header));
SELECT CONVERT(bit,CASE WHEN @Definition IS NULL THEN 0 ELSE 1 END) AS DefinitionPresent,
 CONVERT(bit,MAX(CASE WHEN Id=1 AND DATALENGTH(@Definition)>=DATALENGTH(Signature) AND SUBSTRING(@Definition,1,DATALENGTH(Signature))=Signature THEN 1 ELSE 0 END)) AS Source3LeadingLf0Match,
 CONVERT(bit,MAX(CASE WHEN Id=2 AND DATALENGTH(@Definition)>=DATALENGTH(Signature) AND SUBSTRING(@Definition,1,DATALENGTH(Signature))=Signature THEN 1 ELSE 0 END)) AS Source3LeadingLf1Match,
 CONVERT(bit,MAX(CASE WHEN Id=3 AND DATALENGTH(@Definition)>=DATALENGTH(Signature) AND SUBSTRING(@Definition,1,DATALENGTH(Signature))=Signature THEN 1 ELSE 0 END)) AS Source3LeadingLf2Match,
 CONVERT(bit,MAX(CASE WHEN Id=4 AND DATALENGTH(@Definition)>=DATALENGTH(Signature) AND SUBSTRING(@Definition,1,DATALENGTH(Signature))=Signature THEN 1 ELSE 0 END)) AS Source3LeadingLf3Match,
 CONVERT(bit,MAX(CASE WHEN Id=5 AND DATALENGTH(@Definition)>=DATALENGTH(Signature) AND SUBSTRING(@Definition,1,DATALENGTH(Signature))=Signature THEN 1 ELSE 0 END)) AS Source3LeadingLf4Match,
 CONVERT(bit,MAX(CASE WHEN Id=6 AND DATALENGTH(@Definition)>=DATALENGTH(Signature) AND SUBSTRING(@Definition,1,DATALENGTH(Signature))=Signature THEN 1 ELSE 0 END)) AS HistoricalSource2LeadingLf1Match
FROM @Candidates;
'@
   try{
    $reader=$cmd.ExecuteReader();$fields=@('DefinitionPresent','Source3LeadingLf0Match','Source3LeadingLf1Match','Source3LeadingLf2Match','Source3LeadingLf3Match','Source3LeadingLf4Match','HistoricalSource2LeadingLf1Match' )
    if($reader.FieldCount -ne 7){throw 'CLONE_PREFIX_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt 7;$field++){if($reader.GetName($field) -cne $fields[$field] -or $reader.GetDataTypeName($field) -cne 'bit'){throw 'CLONE_PREFIX_DIAGNOSTIC_SHAPE'}}
    if(!$reader.Read()){throw 'CLONE_PREFIX_DIAGNOSTIC_SHAPE'}
    $observation=[ordered]@{};$matchCount=0
    for($field=0;$field -lt 7;$field++){
     if($reader.IsDBNull($field)){throw 'CLONE_PREFIX_DIAGNOSTIC_SHAPE'}
     $value=$reader.GetBoolean($field);$observation[$fields[$field]]=$value
     if($field -gt 0 -and $value){$matchCount++}
    }
    if($reader.Read() -or $reader.NextResult() -or $matchCount -gt 1 -or (!$observation.DefinitionPresent -and $matchCount -ne 0)){throw 'CLONE_PREFIX_DIAGNOSTIC_SHAPE'}
    $result.Observation=$observation;$result.QueryError=$false
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Observation=$null}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Observation=$null}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Observation=$null}}}
  return $result
 }
 function Read-PredicateDiagnosticBits($connection,[string]$sql,[string[]]$fields){
  $result=[ordered]@{QueryError=$true;Observation=$null};$cmd=$null;$reader=$null
  try{
   $cmd=$connection.CreateCommand();$cmd.CommandTimeout=15;$cmd.CommandText=$sql
   try{
    $reader=$cmd.ExecuteReader()
    if($reader.FieldCount -ne $fields.Count){throw 'CLONE_ROLLBACK_DIAGNOSTIC_SHAPE'}
    for($field=0;$field -lt $fields.Count;$field++){if($reader.GetName($field) -cne $fields[$field] -or $reader.GetDataTypeName($field) -cne 'bit'){throw 'CLONE_ROLLBACK_DIAGNOSTIC_SHAPE'}}
    if(!$reader.Read()){throw 'CLONE_ROLLBACK_DIAGNOSTIC_SHAPE'}
    $observation=[ordered]@{}
    for($field=0;$field -lt $fields.Count;$field++){if($reader.IsDBNull($field)){throw 'CLONE_ROLLBACK_DIAGNOSTIC_SHAPE'};$observation[$fields[$field]]=$reader.GetBoolean($field)}
    if($reader.Read() -or $reader.NextResult()){throw 'CLONE_ROLLBACK_DIAGNOSTIC_SHAPE'}
    $result.Observation=$observation;$result.QueryError=$false
   }finally{try{if($reader){$reader.Dispose();$reader=$null}}finally{$cmd.Dispose();$cmd=$null}}
  }catch{$result.QueryError=$true;$result.Observation=$null}
  finally{try{if($reader){$reader.Dispose()}}catch{$result.QueryError=$true;$result.Observation=$null}
   finally{try{if($cmd){$cmd.Dispose()}}catch{$result.QueryError=$true;$result.Observation=$null}}}
  return $result
 }
 function Read-PredicateRollbackProbe($connection,[switch]$Eligibility){
  $result=[ordered]@{QueryError=$true;Observation=$null}
  try{
   $sql=@'
DECLARE @Id int=OBJECT_ID(N'tempdb..#tbx_ClonePredicateRollbackDiagnostic',N'U');
SELECT CONVERT(bit,CASE WHEN @Id IS NOT NULL THEN 1 ELSE 0 END) AS TempExists,
 CONVERT(bit,CASE WHEN @Id IS NOT NULL AND (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@Id)=11
 AND (SELECT COUNT(*) FROM tempdb.sys.columns C JOIN(VALUES
 (1,N'TransactionCountZero'),
 (2,N'TransactionStateZero'),
 (3,N'ObjectIdPresent'),
 (4,N'ObjectIdEqual'),
 (5,N'DefinitionBytesEqual'),
 (6,N'AnsiNullsEqual'),
 (7,N'QuotedIdentifierEqual'),
 (8,N'PropertyCountEqual'),
 (9,N'OriginalMinusLiveEmpty'),
 (10,N'LiveMinusOriginalEmpty'),
 (11,N'ImplicitTransactionsEnabled')
 )E(Id,Name) ON C.column_id=E.Id AND CONVERT(varbinary(max),C.name)=CONVERT(varbinary(max),E.Name)
 WHERE C.object_id=@Id AND C.system_type_id=104 AND C.max_length=1 AND C.is_nullable=0)=11 THEN 1 ELSE 0 END) AS ShapeCanonical;
'@
   $shape=Read-PredicateDiagnosticBits $connection $sql @('TempExists','ShapeCanonical')
   if($shape.QueryError -or (!$shape.Observation.TempExists -and $shape.Observation.ShapeCanonical)){return $result}
   if($Eligibility){return $shape}
   if(!$shape.Observation.TempExists -or !$shape.Observation.ShapeCanonical){return $result}
   $sql=@'
SELECT TransactionCountZero,TransactionStateZero,ObjectIdPresent,ObjectIdEqual,DefinitionBytesEqual,AnsiNullsEqual,QuotedIdentifierEqual,PropertyCountEqual,OriginalMinusLiveEmpty,LiveMinusOriginalEmpty,ImplicitTransactionsEnabled FROM #tbx_ClonePredicateRollbackDiagnostic;
'@
   return (Read-PredicateDiagnosticBits $connection $sql @('TransactionCountZero','TransactionStateZero','ObjectIdPresent','ObjectIdEqual','DefinitionBytesEqual','AnsiNullsEqual','QuotedIdentifierEqual','PropertyCountEqual','OriginalMinusLiveEmpty','LiveMinusOriginalEmpty','ImplicitTransactionsEnabled'))
  }catch{return $result}
 }
 function Add-PredicateRollbackDiagnostic([string]$original){
  $anchor="  THROW 54930,N'Predicate fixture rollback changed original metadata.',23;`n IF OBJECT_ID"
  if(([regex]::Matches($original,[regex]::Escape($anchor))).Count -ne 1){return $null}
  $insert=@'
  DECLARE @CapturedTransactionCount int,@CapturedTransactionState int,@CapturedImplicitTransactions bit;
  SET @CapturedTransactionCount=@@TRANCOUNT;
  SET @CapturedTransactionState=XACT_STATE();
  SET @CapturedImplicitTransactions=CONVERT(bit,CASE WHEN(@@OPTIONS&2)=0 THEN 0 ELSE 1 END);
  BEGIN TRY
   CREATE TABLE #tbx_ClonePredicateRollbackDiagnostic(
    TransactionCountZero bit NOT NULL,
    TransactionStateZero bit NOT NULL,
    ObjectIdPresent bit NOT NULL,
    ObjectIdEqual bit NOT NULL,
    DefinitionBytesEqual bit NOT NULL,
    AnsiNullsEqual bit NOT NULL,
    QuotedIdentifierEqual bit NOT NULL,
    PropertyCountEqual bit NOT NULL,
    OriginalMinusLiveEmpty bit NOT NULL,
    LiveMinusOriginalEmpty bit NOT NULL,
    ImplicitTransactionsEnabled bit NOT NULL);
   INSERT #tbx_ClonePredicateRollbackDiagnostic(TransactionCountZero,TransactionStateZero,ObjectIdPresent,ObjectIdEqual,DefinitionBytesEqual,AnsiNullsEqual,QuotedIdentifierEqual,PropertyCountEqual,OriginalMinusLiveEmpty,LiveMinusOriginalEmpty,ImplicitTransactionsEnabled)
   SELECT CONVERT(bit,CASE WHEN @CapturedTransactionCount=0 THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN @CapturedTransactionState=0 THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P') IS NOT NULL THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P')=@OriginalId THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id=@OriginalId AND CONVERT(varbinary(max),definition)=CONVERT(varbinary(max),@Original)) THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id=@OriginalId AND uses_ansi_nulls=@Ansi) THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id=@OriginalId AND uses_quoted_identifier=@Quoted) THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN (SELECT COUNT(*) FROM sys.extended_properties WHERE major_id=@OriginalId AND class IN(1,2))=(SELECT COUNT(*) FROM @OriginalProperties) THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN NOT EXISTS(SELECT Class,MinorId,NameBytes,ValueBytes,BaseType,PrecisionValue,ScaleValue,MaxLengthValue,CollationValue FROM @OriginalProperties EXCEPT SELECT class,minor_id,CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE major_id=@OriginalId AND class IN(1,2)) THEN 1 ELSE 0 END),
    CONVERT(bit,CASE WHEN NOT EXISTS(SELECT class,minor_id,CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation') FROM sys.extended_properties WHERE major_id=@OriginalId AND class IN(1,2) EXCEPT SELECT Class,MinorId,NameBytes,ValueBytes,BaseType,PrecisionValue,ScaleValue,MaxLengthValue,CollationValue FROM @OriginalProperties) THEN 1 ELSE 0 END),
    @CapturedImplicitTransactions;
  END TRY BEGIN CATCH
   -- Ausschließlich Diagnosefehler unterdrücken; originales Restore-IF entscheidet unverändert.
  END CATCH;
'@
  return $original.Replace($anchor,"  THROW 54930,N'Predicate fixture rollback changed original metadata.',23;`n"+$insert+"`n IF OBJECT_ID")
 }
 function Reject($c,[string]$sql,[int]$number,[int]$state=1){
  $script:faultCaseIndex++
  $diagnostic=[ordered]@{FaultCaseIndex=$script:faultCaseIndex;CategoryCaught=$false;SnapshotEqual=$null;TxZero=$null;SqlNumber=$null;SqlState=$null}
  $record.Rejection=$diagnostic
  $before=Snapshot $c;$caught=$false;$probe=$null
  # SQLCMD endet mit seiner Session. Die Installer-Temps werden nicht in einer
  # anderen negativen Testsession übernommen; keine fremden Temps löschen.
  try{
   $probe=Open-Own $target $script:currentDatabase
   try{Batches $probe $sql}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException}
    if($e -is [Data.SqlClient.SqlException]){$diagnostic.SqlNumber=$e.Number;$diagnostic.SqlState=$e.State}
    if($e -isnot [Data.SqlClient.SqlException] -or $e.Number -ne $number -or $e.State -ne $state){throw 'CLONE_REJECTION_CATEGORY_MISMATCH'};$caught=$true}
   $diagnostic.CategoryCaught=$caught
   $diagnostic.SnapshotEqual=((Snapshot $c) -ceq $before)
   $diagnostic.TxZero=([int](Sql $probe 'SELECT @@TRANCOUNT;' -Scalar) -eq 0)
   if(!$caught -or !$diagnostic.SnapshotEqual -or !$diagnostic.TxZero){throw 'CLONE_REJECTION_PRESERVATION_FAILED'}
  }finally{if($probe){$probe.Dispose()}}
 }
 function Inject([string]$text,[string]$needle,[int]$index,[string]$replacement){
  $hits=@([regex]::Matches($text,[regex]::Escape($needle)));if($index -ge $hits.Count){throw 'CLONE_INJECTION_SEAM_MISSING'}
  $p=$hits[$index].Index;return $text.Substring(0,$p)+$replacement+$text.Substring($p+$needle.Length)
 }
 function Client($target,[string]$db){
  $names=@('TBX_SQL_HOST','TBX_SQL_PORT','TBX_SQL_USER','TBX_SQL_PASSWORD');$old=@{};$builder=$null
  foreach($name in $names){$old[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
  try{
   $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target))
   if($builder.IntegratedSecurity){throw 'CLONE_CLIENT_AUTH_CONTRACT_UNSUPPORTED'}
   # Die bestehende Clientfixture nimmt ausschließlich diese bereits vorhandenen Prozesswerte.
   $source=$builder.DataSource
   if($source -cnotmatch '^tcp:(.+),([0-9]+)$'){throw 'CLONE_CLIENT_ENDPOINT_FORM_UNSUPPORTED'}
   [Environment]::SetEnvironmentVariable('TBX_SQL_HOST',$Matches[1],'Process')
   [Environment]::SetEnvironmentVariable('TBX_SQL_PORT',$Matches[2],'Process')
   [Environment]::SetEnvironmentVariable('TBX_SQL_USER',$builder.UserID,'Process')
   [Environment]::SetEnvironmentVariable('TBX_SQL_PASSWORD',$builder.Password,'Process')
   [void](& $clientScript -Database $db)
  }finally{if($builder){$builder.Clear()};foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$old[$name],'Process')}}
 }
 function Caller($c,[string]$installer,[string]$abort,[bool]$doomed){
  $first=([regex]::Split($installer,'(?im)^[ \t]*GO[ \t]*(?:--[^\r\n]*)?\r?$'))[0]
  $originalAbort=[int](Sql $c 'SELECT CASE WHEN (@@OPTIONS&16384)=16384 THEN 1 ELSE 0 END;' -Scalar)
  $cmd=$null
  try{
   if(!$doomed){
    Sql $c ("CREATE TABLE #CloneCaller(Value int CHECK(Value>0));BEGIN TRAN;INSERT #CloneCaller VALUES(7);SET XACT_ABORT $abort;")
    $before=Snapshot $c;$options=[int](Sql $c 'SELECT @@OPTIONS;' -Scalar);$caught=$false
    # Originaler erster Installerbatch als direkter Clientbatch ohne TRY/EXEC-Huelle.
    try{Sql $c $first}catch{
     $e=$_.Exception;while($e.InnerException){$e=$e.InnerException}
     if($e -isnot [Data.SqlClient.SqlException] -or $e.Number -ne 50000 -or $e.State -ne 1 -or !$e.Message.StartsWith('TBX_TABLE_CLONE_CALLER_TRANSACTION:',[StringComparison]::Ordinal)){throw 'CLONE_CALLER_CATEGORY'}
     if($e.Errors.Count -eq 0){throw 'CLONE_CALLER_CATEGORY'}
     foreach($sqlItem in $e.Errors){if($sqlItem.Number -ne 50000 -or $sqlItem.State -ne 1 -or !$sqlItem.Message.StartsWith('TBX_TABLE_CLONE_CALLER_TRANSACTION:',[StringComparison]::Ordinal)){throw 'CLONE_CALLER_CATEGORY'}}
     $caught=$true
    }
    if(!$caught -or (Snapshot $c) -cne $before -or [int](Sql $c ("SELECT CASE WHEN @@TRANCOUNT=1 AND XACT_STATE()=1 AND @@OPTIONS=$options AND(SELECT COUNT(*) FROM #CloneCaller)=1 AND(SELECT SUM(Value) FROM #CloneCaller)=7 THEN 1 ELSE 0 END;") -Scalar) -ne 1){throw 'CLONE_CALLER_CHANGED'}
   }else{
    $cmd=$c.CreateCommand();$cmd.CommandTimeout=120
    $cmd.CommandText=@'
CREATE TABLE #CloneCaller(Value int CHECK(Value>0));
DECLARE @Before nvarchar(max),@After nvarchar(max),@Options int,@Caught bit=0;
BEGIN TRY
 BEGIN TRAN;INSERT #CloneCaller VALUES(7);SET XACT_ABORT ON;
 BEGIN TRY INSERT #CloneCaller VALUES(-1);END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW;END CATCH;
 IF XACT_STATE()<>-1 THROW 54931,N'CLONE_DOOM_WITNESS',3;
 IF @Abort=N'ON' SET XACT_ABORT ON;ELSE SET XACT_ABORT OFF;
 SET @Options=@@OPTIONS;
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Before OUTPUT;
 BEGIN TRY
__ORIGINAL_FIRST_BATCH__
 END TRY BEGIN CATCH
  IF ERROR_NUMBER()<>50000 OR ERROR_STATE()<>1 OR LEFT(ERROR_MESSAGE(),35)<>N'TBX_TABLE_CLONE_CALLER_TRANSACTION:' THROW 54931,N'CLONE_CALLER_CATEGORY',1;
  SET @Caught=1;
 END CATCH;
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@After OUTPUT;
 IF @Caught<>1 OR @@TRANCOUNT<>1 OR XACT_STATE()<>-1 OR @@OPTIONS<>@Options
  OR(SELECT COUNT(*) FROM #CloneCaller)<>1 OR(SELECT SUM(Value) FROM #CloneCaller)<>7 OR @Before IS NULL OR @After IS NULL
  OR CONVERT(varbinary(max),@Before)<>CONVERT(varbinary(max),@After) THROW 54931,N'CLONE_CALLER_CHANGED',2;
 ROLLBACK;DROP TABLE #CloneCaller;
 SELECT CONVERT(int,1) AS MandatoryCallerWitness;
END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
'@
    $cmd.CommandText=$cmd.CommandText.Replace('__ORIGINAL_FIRST_BATCH__',$first)
    foreach($item in @(@{Name='@SnapshotSql';Value=[regex]::Replace((SnapshotSql),'\ASELECT ','SELECT @Snapshot=')},@{Name='@Abort';Value=$abort})){
     [void]$cmd.Parameters.Add($item.Name,[Data.SqlDbType]::NVarChar,-1);$cmd.Parameters[$item.Name].Value=$item.Value}
    $witnessReader=$null
    try{
     $witnessReader=$cmd.ExecuteReader()
     if($witnessReader.FieldCount -ne 1 -or $witnessReader.GetName(0) -cne 'MandatoryCallerWitness' -or $witnessReader.GetFieldType(0) -ne [int] -or !$witnessReader.Read() -or $witnessReader.IsDBNull(0) -or $witnessReader.GetInt32(0) -ne 1){throw 'CLONE_CALLER_WITNESS_MISSING'}
     if($witnessReader.Read() -or $witnessReader.NextResult()){throw 'CLONE_CALLER_WITNESS_EXTRA_RESULTS'}
    }finally{if($witnessReader){$witnessReader.Dispose()}}
   }
  }finally{
   try{if($cmd){$cmd.Dispose()}}finally{
    Sql $c ('IF @@TRANCOUNT>0 ROLLBACK;IF OBJECT_ID(N''tempdb..#CloneCaller'',N''U'') IS NOT NULL DROP TABLE #CloneCaller;SET XACT_ABORT '+$(if($originalAbort -eq 1){'ON'}else{'OFF'})+';')
   }
  }
 }
 # Keine Discovery-/Hostaktion ohne ausdrücklichen Aufruf nach Rootreview.
 Check-Pins
 if(!$ExecuteReviewed){Write-Output 'CLONE_PREPARED_NOT_EXECUTED';return}
 $promptPath=Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
 if([string]::IsNullOrWhiteSpace($promptPath)){throw 'CLONE_REVIEWED_PROMPT_REQUIRED'}
 Add-InputSnapshot $promptPath 'lab/prompt'
 $promptBytes=$snapshots[[IO.Path]::GetFullPath($promptPath)]
 $promptHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($promptBytes))
 if($ExpectedPromptSHA256 -cnotmatch '^[0-9A-Fa-f]{64}$' -or $promptHash -cne $ExpectedPromptSHA256.ToUpperInvariant()){throw 'CLONE_PROMPT_PIN_MISMATCH'}
 Add-InputSnapshot $promptPath 'lab/prompt'
 $contractPath=Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_FILE'
 if([string]::IsNullOrWhiteSpace($contractPath)){$dataRoot=Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_DATA_ROOT';if([string]::IsNullOrWhiteSpace($dataRoot)){throw 'CLONE_LAB_CONTRACT_REQUIRED'};$contractPath=Join-Path $dataRoot 'Exports/TestUmgebung.json'}
 $schemaPath=Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE'
 if([string]::IsNullOrWhiteSpace($schemaPath)){$schemaPath=Join-Path (Split-Path -Parent $contractPath) 'TestUmgebung.schema.json'}
 Add-InputSnapshot $contractPath 'lab/contract';Add-InputSnapshot $schemaPath 'lab/schema'
 # Längenframing: BinaryWriter UTF8-Namenlänge/Namebytes, danach 32 SHA256-Bytes; Ordinalname-sortiert.
 $framed=[IO.MemoryStream]::new();$writer=[IO.BinaryWriter]::new($framed,[Text.Encoding]::UTF8,$true)
 try{
  $names=[string[]]@($inputNames.Values);[Array]::Sort($names,[StringComparer]::Ordinal)
  foreach($name in $names){$paths=@($inputNames.Keys|Where-Object {$inputNames[$_] -ceq $name});if($paths.Count -ne 1){throw 'CLONE_INPUT_NAME_DUPLICATE'};$nameBytes=[Text.Encoding]::UTF8.GetBytes($name);$writer.Write([int]$nameBytes.Length);$writer.Write($nameBytes);$writer.Write([Convert]::FromHexString($pins[$paths[0]]))}
  $writer.Flush();$inputSetHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($framed.ToArray()))
 }finally{try{$writer.Dispose()}finally{$framed.Dispose()}}
 Check-Pins
 # Alle Streams intern konsumieren; genau ein schema-validiertes Ergebnis zulassen.
 $labResults=@(Resolve-LabContract *>&1)
 if($labResults.Count -ne 1 -or $labResults[0] -isnot [pscustomobject] -or !$labResults[0].PSObject.Properties['Contract'] -or !$labResults[0].Contract){throw 'CLONE_DISCOVERY_RESULT_INVALID'}
 $lab=$labResults[0]
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
 if(!$targets.Count){throw 'CLONE_EXACT_TARGET_NOT_READY'}
 if($boundRun -and $targets.Count -ne 1){throw 'CLONE_RUN_CONTEXT_ONE_TARGET_REQUIRED'}
 foreach($target in $targets){
  if(!$target.PSObject.Properties['key'] -or [string]::IsNullOrWhiteSpace([string]$target.key)){throw 'CLONE_TARGET_KEY_REQUIRED'}
  $targetDigest=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$target.key)))
  $id=if($boundRun){$ExpectedRunId}else{[guid]::NewGuid().ToString('N')}
  $journal=if($boundRun){$JournalPath}else{Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltCloneW1Restore-'+$id+'.json')}
  $journal=[IO.Path]::GetFullPath($journal)
  if($boundRun -and (![IO.Path]::IsPathFullyQualified($JournalPath) -or ![string]::Equals($journal,$JournalPath,[StringComparison]::OrdinalIgnoreCase))){throw 'CLONE_JOURNAL_PATH_INVALID'}
  if([IO.Path]::GetFileName($journal) -cne ('ToolbeltCloneW1Restore-'+$id+'.json')){throw 'CLONE_JOURNAL_NAME_INVALID'}
  $journalContext=@{Stream=$null;ExpectedBytes=$null;ExpectedHash=$null;ExpectedLength=0;Tuple=$null;Prepared=$false;Failed=$false}
  $journalTuple=[ordered]@{RunId=$id;JournalPath=$journal;Platform=$Platform;Version=$Version;Patch=$Patch;TargetKeySha256=$targetDigest;AdapterSHA256=$adapterHash;InputSetSHA256=$inputSetHash}
  $journalContext.Tuple=[ordered]@{}
  foreach($tupleKey in $journalTuple.Keys){$journalContext.Tuple[$tupleKey]=$journalTuple[$tupleKey]}
  $record=[ordered]@{SchemaVersion=1;JournalTuple=$journalTuple;RunId=$id;State='PREPARED';TargetKeySha256=$targetDigest;PromptSha256=$promptHash;Platform=$Platform;Version=$Version;Patch=$Patch;SourcePins=$pins;Databases=@();ConfigurationChanges=0;RightsChanges=0;TrustChanges=0;InfrastructureChanges=0;CasesPassed=0}
  $failed=$false;$blocked=$false
  try {
   Save-Record
   $control=Open-Own $target 'master';Preflight $control;Check-Pins
   foreach($mode in @('local','central')){
    $db='tbx_clone_'+$mode+'_'+$id
    $script:currentDatabase=$db
    $entry=[ordered]@{Name=$db;State='CREATING';Id=$null;CreateDateBytes=$null;Marker=$id};$record.Databases+=,$entry;Save-Record
    $stage='CREATE_'+$mode
    Sql $control ("IF EXISTS(SELECT 1 FROM sys.databases WHERE name=N'$db') THROW 54931,N'CLONE_DB_COLLISION',3;CREATE DATABASE [$db] COLLATE Latin1_General_100_CS_AS;")
    $c=Open-Own $target $db
    Sql $c ("EXEC sys.sp_addextendedproperty @name=N'Toolbelt.PrivateCloneRun',@value=N'$id';")
    $entry.Id=[int](Sql $control ("SELECT database_id FROM sys.databases WHERE name=N'$db';") -Scalar)
    $entry.CreateDateBytes=[string](Sql $control ("SELECT CONVERT(varchar(max),CONVERT(varbinary(max),create_date),2) FROM sys.databases WHERE name=N'$db';") -Scalar)
    $entry.State='CREATED';Save-Record
    $vars=@{DeploymentMode=$mode;ConfirmNoExternalConsumers='1';ToolbeltDatabase=$db}
    $deploy=Read-TranslateSql (Join-Path $module 'Deployment/Deploy.sql') $vars
    $uninstall=Read-TranslateSql (Join-Path $module 'Deployment/Uninstall.sql') $vars
    Batches $c (Read-TranslateSql (Join-Path $dependency 'Deployment/Deploy.sql') @{DeploymentMode='local'})
    $deployFault=Inject $deploy '    DROP TABLE #tbx_TableCloneReleaseObjects;' 0 "    THROW 54932,N'CLONE_SYNTHETIC_FINALINSTALL',1;`n    DROP TABLE #tbx_TableCloneReleaseObjects;"
    $stage='CLEAN_ROLLBACK_'+$mode;Reject $c $deployFault 54932
    $stage='CLEAN_'+$mode;Batches $c $deploy;Batches $c $deploy
    Reject $c $deployFault 54932
    Batches $c (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.Contract.sql') $vars)
    Batches $c $uninstall
    $stage='GENUINE_'+$mode
    Batches $c (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
    if([int](Sql $c "SELECT CASE WHEN(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone'))=9 AND(SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_metadata') AND type='P' AND name IN(N'USP_ScriptTableClone',N'USP_ScriptTableCloneInternal'))=2 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0')) THEN 1 ELSE 0 END;" -Scalar) -ne 1){throw 'CLONE_LEGACY_INVENTORY_FAILED'}
    $c.Dispose();$c=Open-Own $target $db
    $stage='GENUINE_UNINSTALL_'+$mode;Batches $c $uninstall
    Batches $c (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
    $c.Dispose();$c=Open-Own $target $db
    $stage='GENUINE_UPGRADE_ROLLBACK_'+$mode;Reject $c $deployFault 54932
    Batches $c $deploy;Batches $c $deploy
    $definitionBaseline=Capture-CoreDefinitionBaseline $c
    $record.DefinitionBaselineQueryError=$definitionBaseline.QueryError
    $record.DefinitionWholePrefix=Read-DefinitionWholePrefix $c
    $levels=if($Version -ceq '2019'){@(150)}else{@(150,160,170)}
    foreach($level in $levels){
     $stage='CONSUMER_SESSION_'+$mode+'_'+$level;$script:batch=0
     Assert-OwnConsumerHealthy $c
     $c.Dispose();$c=$null
     $c=Open-Own $target $db
     $stage='API_'+$mode+'_'+$level;Sql $control ("ALTER DATABASE [$db] SET COMPATIBILITY_LEVEL=$level;")
     foreach($file in @('TableClone.Contract.sql','Wave1.Contract.sql','Wave1.DateTimeOffset.sql','Lifecycle.Contract.sql')){
      $runtimeLabel=switch -CaseSensitive ($file){'TableClone.Contract.sql'{'TABLECLONE'}'Wave1.Contract.sql'{'WAVE1'}'Wave1.DateTimeOffset.sql'{'DTO18'}'Lifecycle.Contract.sql'{'LIFECYCLE'}default{throw 'CLONE_RUNTIME_LABEL_UNKNOWN'}}
      $stage='API_'+$mode+'_'+$level+'_'+$runtimeLabel
      Batches $c (Read-TranslateSql (Join-Path $module ('Tests/Runtime/'+$file)) $vars)
     }
     $stage='CLIENT_'+$mode+'_'+$level;Client $target $db
    }
    if($mode -ceq 'local'){$stage='BYTES';Batches $c (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Wave1.Bytes.sql') $vars)}
    $stage='COMPUTED_PERMISSION_PREDICATE'
    $predicateRollbackEligible=$false
    $predicateInput=Read-TranslateSql (Join-Path $module 'Tests/Runtime/Wave1.PermissionPredicate.sql') $vars
    $predicateEligibility=Read-PredicateRollbackProbe $c -Eligibility
    if(!$predicateEligibility.QueryError -and !$predicateEligibility.Observation.TempExists){
     $instrumentedPredicate=Add-PredicateRollbackDiagnostic $predicateInput
     if($null -ne $instrumentedPredicate){$predicateRollbackEligible=$true;$predicateInput=$instrumentedPredicate}
    }
    Batches $c $predicateInput
    $stage='HELPER_ID'
    foreach($badId in @('toolbelt.core.result-table ','TOOLBELT.CORE.RESULT-TABLE',('toolbelt.core.result-table'+(' '*200)+'x'))){
     # Originale Typ-/Wertinstanz bleibt in dieser Session; keine angenommene
     # neue Property-Typisierung bei Wiederherstellung.
     Sql $c "DECLARE @Saved sql_variant=(SELECT value FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') AND name=N'Toolbelt.ModuleId');CREATE TABLE #HelperOriginal(Value sql_variant);INSERT #HelperOriginal VALUES(@Saved);EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'$badId',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'PROCEDURE',@level1name=N'USP_PrepareResultTable';"
     try{
      Reject $c $deploy 53922
      Sql $c @'
CREATE TABLE dbo.SyntheticHelperIdSource(Id int);CREATE TABLE #HelperIdPlan(Dummy int);INSERT #HelperIdPlan VALUES(73);
BEGIN TRY
 EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticHelperIdSource',N'dbo',N'SyntheticHelperIdTarget',@ResultTable=N'#HelperIdPlan';
 THROW 54931,N'CLONE_BAD_HELPER_ACCEPTED',8;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53907 OR ERROR_STATE()<>1 THROW;END CATCH;
IF(SELECT COUNT(*) FROM #HelperIdPlan)<>1 OR(SELECT Dummy FROM #HelperIdPlan)<>73 THROW 54931,N'CLONE_HELPER_OUTPUT_CHANGED',9;
DROP TABLE #HelperIdPlan;DROP TABLE dbo.SyntheticHelperIdSource;
'@
     }finally{Sql $c "DECLARE @Saved sql_variant=(SELECT Value FROM #HelperOriginal);EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=@Saved,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'PROCEDURE',@level1name=N'USP_PrepareResultTable';IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),value)=CONVERT(varbinary(max),@Saved) AND SQL_VARIANT_PROPERTY(value,'BaseType')=SQL_VARIANT_PROPERTY(@Saved,'BaseType') AND SQL_VARIANT_PROPERTY(value,'MaxLength')=SQL_VARIANT_PROPERTY(@Saved,'MaxLength')) THROW 54931,N'CLONE_HELPER_RESTORE_CHANGED',10;DROP TABLE #HelperOriginal;"}
    }
    foreach($abort in @('OFF','ON')){foreach($doomed in @($false,$true)){foreach($installer in @($deploy,$uninstall)){$stage='CALLER_'+$abort+'_'+$doomed;Caller $c $installer $abort $doomed}}}
    $stage='PERMISSION_PREDICATES'
    foreach($installer in @($deploy,$uninstall)){foreach($needle in @("COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1","COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1")){foreach($pass in @(0,1)){foreach($value in @('0','NULL')){Reject $c (Inject $installer $needle $pass ('COALESCE('+$value+',0)<>1')) 53926 2;$record.CasesPassed++;Save-Record}}}}
    $stage='POSTLOCK_PADDING'
    foreach($installer in @($deploy,$uninstall)){
     $seam='DECLARE @CurrentInstalledVersion nvarchar(max);'
     $mutation="EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version',@value=N'4.0.0 ';`n"+$seam
     Reject $c (Inject $installer $seam 0 $mutation) 53927
    }
    $stage='APPLOCK'
    $holder=Open-Own $target $db
    try{Sql $holder "BEGIN TRAN;DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.metadata.table-clone',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0;IF @r<0 THROW 54931,N'CLONE_HOLDER_FAILED',4;"
     foreach($installer in @($deploy,$uninstall)){Reject $c $installer 53927}
    }finally{try{Sql $holder 'IF @@TRANCOUNT>0 ROLLBACK;'}finally{$holder.Dispose()}}
    $stage='POSTDROP_ROLLBACK';Reject $c (Inject $uninstall '    COMMIT TRANSACTION;' 0 "    THROW 54932,N'CLONE_SYNTHETIC_POSTDROP',1;`n    COMMIT TRANSACTION;") 54932
    $stage='MARKER_NEGATIVES'
    foreach($marker in @('Version','DeploymentMode')){
     Sql $c ("EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.metadata.table-clone.$marker',@value=NULL;")
     try{foreach($installer in @($deploy,$uninstall)){Reject $c $installer 53923}}
     finally{$value=if($marker -ceq 'Version'){'4.0.0'}else{$mode};Sql $c ("EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.metadata.table-clone.$marker',@value=N'$value';")}
    }
    if($mode -ceq 'central'){
     $stage='CENTRAL_CONSUMER'
     # Jeder Name trägt denselben Eigentums-RunToken; ein zentraler Consumer ist eindeutig.
     $consumer='tbx_clone_consumer_'+$id
     $consumerEntry=[ordered]@{Name=$consumer;State='CREATING';Id=$null;CreateDateBytes=$null;Marker=$id};$record.Databases+=,$consumerEntry;Save-Record
     Sql $control ("IF EXISTS(SELECT 1 FROM sys.databases WHERE name=N'$consumer') THROW 54931,N'CLONE_DB_COLLISION',3;CREATE DATABASE [$consumer] COLLATE Latin1_General_100_CI_AS;")
     $consumerConnection=Open-Own $target $consumer
     Sql $consumerConnection ("EXEC sys.sp_addextendedproperty @name=N'Toolbelt.PrivateCloneRun',@value=N'$id';")
     $consumerEntry.Id=[int](Sql $control ("SELECT database_id FROM sys.databases WHERE name=N'$consumer';") -Scalar)
     $consumerEntry.CreateDateBytes=[string](Sql $control ("SELECT CONVERT(varchar(max),CONVERT(varbinary(max),create_date),2) FROM sys.databases WHERE name=N'$consumer';") -Scalar)
     $consumerEntry.State='CREATED';Save-Record
     Batches $consumerConnection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Central.Contract.sql') $vars)
    }
    $stage='UNINSTALL';Batches $c $uninstall
    $stage='FOREIGN_SCHEMA_ENVELOPE'
    if([int](Sql $c "SELECT CASE WHEN SCHEMA_ID(N'toolbelt_metadata') IS NULL THEN 0 ELSE 1 END;" -Scalar) -eq 0){Sql $c 'CREATE SCHEMA toolbelt_metadata;'}
    # Leere unmarkierte/fremde Schemas dürfen ebenfalls benutzt, aber nicht
    # still übernommen oder bei fehlender eindeutiger Markierung entfernt werden.
    foreach($managed in @('ABSENT','0','NULL','PAD_CATEGORY')){
     if($managed -ceq '0'){Sql $c "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=0,@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata';EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'metadata',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata';"}
     elseif($managed -ceq 'NULL'){Sql $c "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Managed',@value=NULL,@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata';"}
     elseif($managed -ceq 'PAD_CATEGORY'){Sql $c "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata';EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'metadata ',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata';"}
     Batches $c $deploy;Batches $c $deploy;Batches $c $uninstall
     if([int](Sql $c "SELECT CASE WHEN SCHEMA_ID(N'toolbelt_metadata') IS NULL THEN 0 ELSE 1 END;" -Scalar) -ne 1){throw 'CLONE_FOREIGN_EMPTY_SCHEMA_REMOVED'}
    }
    Sql $c "EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Managed',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata';EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.SchemaCategory',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata';"
    Sql $c 'CREATE TABLE toolbelt_metadata.SyntheticForeignSibling(Value int);INSERT toolbelt_metadata.SyntheticForeignSibling VALUES(73);'
    Batches $c $deploy;Batches $c $deploy;Batches $c $uninstall
    if([int](Sql $c "SELECT CASE WHEN SCHEMA_ID(N'toolbelt_metadata') IS NOT NULL AND OBJECT_ID(N'toolbelt_metadata.SyntheticForeignSibling',N'U') IS NOT NULL AND (SELECT COUNT(*) FROM toolbelt_metadata.SyntheticForeignSibling)=1 AND (SELECT Value FROM toolbelt_metadata.SyntheticForeignSibling)=73 AND NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=SCHEMA_ID(N'toolbelt_metadata') AND name=N'Toolbelt.Managed') THEN 1 ELSE 0 END;" -Scalar) -ne 1){throw 'CLONE_FOREIGN_SCHEMA_CHANGED'}
    $stage='WRONG_KIND'
    Batches $c $deploy
    # Eigene synthetische Test-DB; kein beschädigtes Objekt wird adoptiert oder repariert.
    Sql $c 'DROP PROCEDURE toolbelt_metadata.USP_ScriptTableClone;'
    Sql $c 'CREATE FUNCTION toolbelt_metadata.USP_ScriptTableClone() RETURNS @r TABLE(Value int) AS BEGIN RETURN;END;'
    Sql $c ("EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.metadata.table-clone',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'FUNCTION',@level1name=N'USP_ScriptTableClone';EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'4.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'FUNCTION',@level1name=N'USP_ScriptTableClone';EXEC sys.sp_addextendedproperty @name=N'Toolbelt.DeploymentMode',@value=N'$mode',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'FUNCTION',@level1name=N'USP_ScriptTableClone';")
    foreach($installer in @($deploy,$uninstall)){Reject $c $installer 53923}
   }
   Check-Pins;$record.State='TESTS_PASSED'
  }catch{
   $failed=$true;$record.State='TESTS_FAILED';$e=$_.Exception;$sqlError=$null
   $scriptCode='UNCLASSIFIED_SCRIPT'
   $allowedScriptCodes=@('CLONE_REJECTION_CATEGORY_MISMATCH','CLONE_REJECTION_PRESERVATION_FAILED','CLONE_SNAPSHOT_NULL','CLONE_INJECTION_SEAM_MISSING','CLONE_SOURCE_CHANGED','CLONE_SOURCE_SET_CHANGED','CLONE_CALLER_CATEGORY','CLONE_CALLER_CHANGED','CLONE_CALLER_WITNESS_MISSING','CLONE_CALLER_WITNESS_EXTRA_RESULTS')
   $codeException=$e
   while($codeException){if($codeException.Message -cin $allowedScriptCodes){$scriptCode=$codeException.Message};$codeException=$codeException.InnerException}
   while($e){if($e -is [Data.SqlClient.SqlException] -and !$sqlError){$sqlError=$e};$e=$e.InnerException}
   $record.Failure=[ordered]@{Stage=$stage;Batch=$batch;Class=$(if($sqlError){'SQL'}else{'SCRIPT'});ScriptCode=$scriptCode;FaultCaseIndex=$script:faultCaseIndex;Number=$(if($sqlError){$sqlError.Number}else{$null});SqlState=$(if($sqlError){$sqlError.State}else{$null})}
   if($sqlError){
    # Nur strukturelle Fehlerfelder und geschlossene Prozedurklassen.
    # Keine SQL-Message, kein roher Prozedurname, keine SQL-/Objekt-/Payloadausgabe.
    $diagnosticErrors=@()
    for($errorIndex=0;$errorIndex -lt $sqlError.Errors.Count;$errorIndex++){
     $sqlItem=$sqlError.Errors[$errorIndex]
     $procedureClass=if([string]::IsNullOrEmpty($sqlItem.Procedure)){'EMPTY'}
      elseif($sqlItem.Procedure -cin @('USP_ScriptTableCloneInternal','toolbelt_metadata.USP_ScriptTableCloneInternal')){'CORE'}
      elseif($sqlItem.Procedure -cin @('USP_ScriptTableClone','toolbelt_metadata.USP_ScriptTableClone')){'PUBLIC'}
      elseif($sqlItem.Procedure -cin @('sp_addextendedproperty','sys.sp_addextendedproperty')){'ADDEXTENDEDPROPERTY'}
      elseif($sqlItem.Procedure -cin @('sp_executesql','sys.sp_executesql')){'EXECUTESQL'}else{'OTHER'}
     $diagnosticErrors+=,[ordered]@{Index=$errorIndex;Number=$sqlItem.Number;SqlState=$sqlItem.State;LineNumber=$sqlItem.LineNumber;ProcedureClass=$procedureClass}
    }
    $record.Failure.SqlDiagnostics=$diagnosticErrors
    $record.Failure.SqlErrorCount=$sqlError.Errors.Count
    if($sqlError.Number -eq 54930 -and $sqlError.State -eq 23 -and $stage -ceq 'COMPUTED_PERMISSION_PREDICATE'){
     $record.Failure.PredicateRollbackProbe=[ordered]@{QueryError=$true;Observation=$null}
     try{if($predicateRollbackEligible){$record.Failure.PredicateRollbackProbe=Read-PredicateRollbackProbe $c}}catch{}
    }
    if($sqlError.Number -eq 2714 -and $stage -ceq 'BYTES'){
     $knownMessages=@()
     foreach($nativeError in $sqlError.Errors){
      $codes=@()
      if($nativeError.Number -eq 2714){
       if($nativeError.Message.Contains('#tbx_TableClone_Plan')){$codes+='INTERNAL_PLAN_TEMP'}
       if($nativeError.Message.Contains('#BytePlan')){$codes+='BYTE_PLAN_TEMP'}
       if($nativeError.Message.Contains('#ByteSnapshot')){$codes+='BYTE_SNAPSHOT_TEMP'}
      }
      $knownMessages+=,[ordered]@{MessageContainsKnownObjectCodes=$codes}
     }
     $record.Failure.ClosedTempMessageObservations=$knownMessages
     $record.Failure.TempCollisionReference=Read-TempCollisionReference $c $definitionBaseline
     $quotedObservations=@()
     foreach($nativeError in $sqlError.Errors){
      $code='NO_KNOWN_MATCH';$quoteShape=$false
      if($nativeError.Number -eq 2714){
       $quoted=[regex]::Matches($nativeError.Message,"'([^']{1,128})'",[Text.RegularExpressions.RegexOptions]::CultureInvariant)
       if($quoted.Count -eq 1){
        $quoteShape=$true;$identifier=$quoted[0].Groups[1].Value
        $known=@{'#tbx_TableClone_Plan'='INTERNAL_PLAN_TEMP';'#BytePlan'='BYTE_PLAN_TEMP';'#ByteSnapshot'='BYTE_SNAPSHOT_TEMP';'SyntheticByteSource'='BYTE_SOURCE';'SyntheticByteTarget'='BYTE_TARGET';'USP_ScriptTableCloneInternal'='CLONE_CORE';'USP_ScriptTableClone'='CLONE_PUBLIC';'USP_PrepareResultTable'='RESULT_HELPER';'PropertyCursor'='PROPERTY_CURSOR';'IndexCursor'='INDEX_CURSOR';'Ordinal'='PLAN_ORDINAL_COLUMN';'ObjectKind'='PLAN_KIND_COLUMN';'TargetName'='PLAN_TARGET_COLUMN';'ScriptText'='PLAN_SCRIPT_COLUMN';'Dummy'='RESULT_DUMMY_COLUMN';'Id'='BYTE_ID_COLUMN'}
        foreach($knownName in $known.Keys){if([string]::Equals($identifier,$knownName,[StringComparison]::Ordinal)){$code=$known[$knownName];break}}
       }
      }
      $quotedObservations+=,[ordered]@{QuotedShapeRecognized=$quoteShape;KnownRepositoryIdentifierCode=$code}
     }
     $record.Failure.QuotedObjectObservations=$quotedObservations
     $record.Failure.ByteBoundaryReference=Read-ByteBoundaryReference $c
    }
    if($sqlError.Number -eq 241 -and [string]::IsNullOrEmpty($sqlError.Procedure) -and $stage -cmatch '^API_(local|central)_(150|160|170)_WAVE1$'){
     $record.Failure.PlanLineCandidate=Read-PlanLineCandidate $c $sqlError.Errors[0].LineNumber
     $record.Failure.TemporalReference=Read-TemporalReference $c
    }
    if($sqlError.Number -eq 54930 -and $sqlError.State -eq 6 -and $stage -cmatch '^API_(local|central)_(150|160|170)_WAVE1$'){
     $record.Failure.PropertyReference=Read-PropertyReference $c
     $record.Failure.TemporalReference=Read-TemporalReference $c
     $record.Failure.DtoCandidateReference=Read-DtoCandidateReference $c
    }
   }
  }finally{
   $disposeFailed=$false
   foreach($conn in $connections){try{$conn.Dispose()}catch{$disposeFailed=$true}}
   $connections.Clear()
   if($disposeFailed){$failed=$true;$record.DisposeFailure=$true}
   # Nach Dispose neue Kontrollverbindung; niemals KILL/SINGLE_USER/ROLLBACK IMMEDIATE.
   $control=$null
   try{$control=Open-Own $target 'master'
    foreach($entry in $record.Databases){
     try{
      if($entry.State -cne 'CREATED' -or !$entry.Id -or !$entry.CreateDateBytes){throw 'CLONE_UNCERTAIN_CREATE'}
      $db=$entry.Name;$date=$entry.CreateDateBytes;$dbid=$entry.Id
      if($db -cnotmatch '^tbx_clone_(local|central|consumer)_[0-9a-f]{32}$' -or $db.Substring($db.Length-32) -cne $id){throw 'CLONE_OWN_NAME_MISMATCH'}
      Sql $control ("IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name=N'$db' AND database_id=$dbid AND CONVERT(varbinary(max),create_date)=0x$date) THROW 54931,N'CLONE_DB_IDENTITY_CHANGED',5;IF NOT EXISTS(SELECT 1 FROM [$db].sys.extended_properties WHERE class=0 AND name=N'Toolbelt.PrivateCloneRun' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'$id')) THROW 54931,N'CLONE_DB_MARKER_CHANGED',6;DROP DATABASE [$db];IF EXISTS(SELECT 1 FROM sys.databases WHERE name=N'$db') THROW 54931,N'CLONE_DROP_UNCONFIRMED',7;")
      $entry.State='DROPPED'
     }catch{$blocked=$true;$entry.State='CLEANUP_BLOCKED'}
    }
   }catch{$blocked=$true}finally{try{if($control){$control.Dispose()}}catch{$blocked=$true}finally{$connections.Clear()}}
   try{Check-Pins}catch{$failed=$true;$record.SourceVerificationFailure=$true}
   if($journalContext.Failed){$failed=$true;$record.JournalFailure=$true}
   $record.State=if($blocked){'CLEANUP_BLOCKED'}elseif($failed){'FAILED_CLEANED'}else{'COMPLETE'}
   try{Save-Record}catch{$failed=$true;$record.JournalFailure=$true}
   try{if($journalContext.Stream){$journalContext.Stream.Dispose()}}catch{$failed=$true}finally{$journalContext.Stream=$null}
  }
  if($blocked -or $failed){throw 'CLONE_NATIVE_FAILED'}
  Write-Output 'CLONE_NATIVE_SCOPE_COMPLETE'
 }
} catch {Write-Output 'CLONE_PREPARATION_OR_NATIVE_FAILED';exit 1}
