[CmdletBinding()]
param([Parameter(Mandatory)][string]$ReleaseRoot,
 [ValidateSet('linux','windows')][string]$Platform='linux',
 [ValidateSet('2019','2022','2025')][string]$Version='2019',[string]$Patch='latest',
 [switch]$AllowHashTrustOptIn)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$phase='PREFLIGHT';$journal=$null;$master=$null;$work=$null
# Nur diese kanonischen Definitionen werden importiert; kein Top-Level-Runner.
try{
 $errors=$null;$tokens=$null
 $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'Tests/CI/run-lab-local.ps1'),[ref]$tokens,[ref]$errors)
 if($errors.Count){throw 'DISCOVERY_SYNTAX'}
 foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
  $f=@($ast.FindAll({param($x)$x -is [Management.Automation.Language.FunctionDefinitionAst] -and $x.Name-eq$name},$true))
  if($f.Count-ne1){throw 'DISCOVERY_DEFINITION'};. ([scriptblock]::Create($f[0].Extent.Text))
 }
 $lab=Resolve-LabContract
 $promptPath=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
 if($promptPath){$prompt=[IO.File]::ReadAllText($promptPath);if([string]::IsNullOrWhiteSpace($prompt)){throw 'DISCOVERY_PROMPT'}}
 $targets=@(Get-LabTargetsForSelector $lab.Contract ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
 if(-not $targets.Count){throw 'DISCOVERY_TARGET'}
 $release=(Resolve-Path -LiteralPath $ReleaseRoot).Path
 $manifest=Get-Content -LiteralPath (Join-Path $release 'Toolbelt.String.EditDistance.trust-manifest.json') -Raw|ConvertFrom-Json
 $binary=Join-Path $release 'Toolbelt.String.EditDistance.dll'
 if($manifest.moduleId-cne'toolbelt.string.edit-distance'-or$manifest.moduleVersion-cne'1.1.0'-or$manifest.permissionSet-cne'SAFE'-or$manifest.assemblySqlName-cne'Toolbelt_String_EditDistance'){throw 'RELEASE_IDENTITY'}
 $hash=(Get-FileHash -LiteralPath $binary -Algorithm SHA512).Hash
 if($manifest.sha512-cne$hash-or$manifest.sqlServerHexLiteral-cne('0x'+$hash)){throw 'RELEASE_HASH'}
 $expected=@('Clr/Toolbelt.String.EditDistance.csproj','Clr/Properties/AssemblyInfo.cs','Clr/UnicodeScalar.cs','Clr/DistanceKernel.cs','Clr/DistanceProvider.cs','Clr/JaroKernel.cs','Clr/JaroProvider.cs','Source/EditDistance.sql','Source/JaroWinkler.sql','Deployment/Deploy.sql','Deployment/Uninstall.sql','Scripts/New-ClrReleaseArtifacts.ps1')
 if(@($manifest.sourceFingerprints).Count-ne$expected.Count){throw 'RELEASE_SOURCES'}
 foreach($relative in $expected){$pin=@($manifest.sourceFingerprints|Where-Object path -CEQ $relative);if($pin.Count-ne1-or$pin[0].sha256-cne(Get-FileHash -LiteralPath (Join-Path $moduleRoot $relative) -Algorithm SHA256).Hash){throw 'RELEASE_SOURCE_HASH'}}
 $bits='0x'+[BitConverter]::ToString([IO.File]::ReadAllBytes($binary)).Replace('-','')
}catch{throw 'DISTANCE_PREFLIGHT_FAILED'}

function Expand-DistanceSql([string]$Path,[hashtable]$Variables){
 $output=[Text.StringBuilder]::new()
 foreach($line in [IO.File]::ReadAllLines($Path)){
  if($line-match'^\s*:r\s+(.+?)\s*$'){[void]$output.AppendLine((Expand-DistanceSql (Join-Path (Split-Path -Parent $Path) $Matches[1].Trim('"')) $Variables));continue}
  if($line-ceq':On Error exit'){continue}
  if($line-match'^\s*:'){throw 'SQLCMD_DIRECTIVE'}
  $value=$line
  foreach($key in $Variables.Keys){$placeholder='$('+$key+')';if($value.Contains($placeholder)){$value=$value.Replace($placeholder,[string]$Variables[$key])}}
  if($value-match'\$\('){throw 'SQLCMD_UNRESOLVED'}
  [void]$output.AppendLine($value)
 }
 return $output.ToString()
}
function Invoke-DistanceSql([Data.SqlClient.SqlConnection]$Connection,[string]$Sql,[switch]$Scalar){
 $cmd=$Connection.CreateCommand();$cmd.CommandText=$Sql;$cmd.CommandTimeout=300
 try{if($Scalar){return $cmd.ExecuteScalar()}else{[void]$cmd.ExecuteNonQuery()}}finally{$cmd.Dispose()}
}
function Invoke-DistanceFile([Data.SqlClient.SqlConnection]$Connection,[string]$Path,[hashtable]$Variables){
 foreach($batch in [regex]::Split((Expand-DistanceSql $Path $Variables),'(?im)^\s*GO\s*$')){if(-not[string]::IsNullOrWhiteSpace($batch)){Invoke-DistanceSql $Connection $batch}}
}
function Get-DistanceSnapshot([Data.SqlClient.SqlConnection]$Connection){
 $cmd=$Connection.CreateCommand();$cmd.CommandText=Expand-DistanceSql (Join-Path $PSScriptRoot 'Lifecycle.Snapshot.sql') @{};$cmd.CommandTimeout=30
 try{$reader=$cmd.ExecuteReader();try{if(-not$reader.Read()){throw 'SNAPSHOT_EMPTY'};$v=@();for($i=0;$i-lt$reader.FieldCount;$i++){$v+=[string]$reader.GetValue($i)};return ($v-join'|')}finally{$reader.Dispose()}}finally{$cmd.Dispose()}
}
function Test-DistanceFailure([Data.SqlClient.SqlConnection]$Connection,[string]$Path,[hashtable]$Variables,[int]$Number){
 $before=Get-DistanceSnapshot $Connection;$caught=$false
 try{Invoke-DistanceFile $Connection $Path $Variables}catch{$cause=$_.Exception;while($cause-and$cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException};if(-not$cause-or$cause.Number-ne$Number){throw 'FAILURE_CATEGORY'};$caught=$true}
 if(-not$caught-or(Get-DistanceSnapshot $Connection)-cne$before){throw 'FAILURE_ATOMICITY'}
}
function Test-DistanceClientSchema([Data.SqlClient.SqlConnection]$Connection,[string]$Prefix){
 foreach($name in @('TVF_LevenshteinDistance','TVF_OsaDistance')){
  $cmd=$Connection.CreateCommand();$cmd.CommandText='SELECT * FROM '+$Prefix+'toolbelt_string.'+$name+"(N'CA',N'AC',DEFAULT,DEFAULT);";$cmd.CommandTimeout=30
  try{$reader=$cmd.ExecuteReader();try{
   if($reader.FieldCount-ne3-or$reader.GetName(0)-cne'Distance'-or$reader.GetName(1)-cne'ExceedsMaxDistance'-or$reader.GetName(2)-cne'ErrorCode'-or$reader.GetFieldType(0)-ne[int]-or$reader.GetFieldType(1)-ne[bool]-or$reader.GetFieldType(2)-ne[int]){throw 'CLIENT_METADATA'}
   $schema=$reader.GetSchemaTable();if($schema.Rows.Count-ne3){throw 'CLIENT_SCHEMA'}
   if(-not$reader.Read()-or$reader.IsDBNull(2)-or$reader.GetInt32(2)-ne0-or$reader.GetBoolean(1)-or$reader.GetInt32(0)-ne$(if($name-eq'TVF_OsaDistance'){1}else{2})-or$reader.Read()){throw 'CLIENT_VALUES'}
  }finally{$reader.Dispose()}}finally{$cmd.Dispose()}
 }
}
function Test-JaroClientSchema([Data.SqlClient.SqlConnection]$Connection,[string]$Prefix){
 $cmd=$Connection.CreateCommand();$cmd.CommandText='SELECT * FROM '+$Prefix+"toolbelt_string.TVF_JaroWinklerSimilarity(N'ABC',N'ACB',DEFAULT);";$cmd.CommandTimeout=30
 try{$reader=$cmd.ExecuteReader();try{
  if($reader.FieldCount-ne2-or$reader.GetName(0)-cne'Similarity'-or$reader.GetName(1)-cne'ErrorCode'-or$reader.GetFieldType(0)-ne[double]-or$reader.GetFieldType(1)-ne[int]){throw 'JARO_CLIENT_METADATA'}
  if(-not$reader.Read()-or$reader.IsDBNull(0)-or$reader.IsDBNull(1)-or$reader.GetInt32(1)-ne0-or[Math]::Abs($reader.GetDouble(0)-5.0/9)-gt1e-12-or$reader.Read()-or$reader.NextResult()){throw 'JARO_CLIENT_VALUES'}
 }finally{$reader.Dispose()}}finally{$cmd.Dispose()}
}
function Invoke-DistanceSource([Data.SqlClient.SqlConnection]$Connection,[string]$Source){
 foreach($batch in [regex]::Split($Source,'(?im)^\s*GO\s*$')){if(-not[string]::IsNullOrWhiteSpace($batch)){Invoke-DistanceSql $Connection $batch}}
}
function Test-DistanceSourceFailure([Data.SqlClient.SqlConnection]$Connection,[string]$Source,[int]$Number,[int]$State){
 $before=Get-DistanceSnapshot $Connection;$caught=$false
 try{Invoke-DistanceSource $Connection $Source}catch{$cause=$_.Exception;while($cause-and$cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException};if(-not$cause-or$cause.Number-ne$Number-or$cause.State-ne$State){throw 'INJECTED_FAILURE_CATEGORY'};$caught=$true}
 if(-not$caught-or(Get-DistanceSnapshot $Connection)-cne$before-or(Invoke-DistanceSql $Connection 'SELECT @@TRANCOUNT;' -Scalar)-ne0){throw 'INJECTED_FAILURE_ATOMICITY'}
}
function Test-DistanceForeignConsumers([Data.SqlClient.SqlConnection]$Connection,[string]$Hash){
 # Ausschließlich read-only; unzugängliche/offline Datenbanken lassen Scope unbestätigt.
 $sql=@"
DECLARE @h varbinary(64)=0xHASH_LITERAL,@found int=0,@name sysname,@query nvarchar(max);
IF EXISTS(SELECT 1 FROM sys.databases WHERE state<>0 OR ISNULL(HAS_DBACCESS(name),0)<>1) BEGIN SELECT -1;RETURN;END;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.databases ORDER BY database_id;
OPEN c;FETCH NEXT FROM c INTO @name;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @query=N'IF ISNULL(HAS_PERMS_BY_NAME(N'''+REPLACE(@name,N'''',N'''''')+N''',N''DATABASE'',N''VIEW DEFINITION''),0)<>1 BEGIN SET @found=-1;RETURN;END;IF EXISTS(SELECT 1 FROM '+QUOTENAME(@name)+N'.sys.assembly_files WHERE file_id=1 AND HASHBYTES(N''SHA2_512'',content)=@h) SET @found=1;';
 EXEC sys.sp_executesql @query,N'@h varbinary(64),@found int OUTPUT',@h=@h,@found=@found OUTPUT;
 IF @found=-1 BREAK;
 FETCH NEXT FROM c INTO @name;
END;
CLOSE c;DEALLOCATE c;SELECT @found;
"@
 return (Invoke-DistanceSql $Connection $sql.Replace('HASH_LITERAL',$Hash) -Scalar)
}
function Save-DistanceJournal{[IO.File]::WriteAllText($journalPath,($journal|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))}
foreach($target in $targets){
 $phase='PREPARE';$journal=$null;$master=$null;$work=$null;$masterBuilder=$null;$builder=$null;$trustOwned=$false
 try{
 $run=[guid]::NewGuid().ToString('N');$journalPath=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltDistanceRestore-'+$run+'.json')
 $journal=[ordered]@{SchemaVersion=1;RunToken=$run;Status='RUNNING';ConfigurationChanges=0;RightsChanges=0;Databases=@();Trust=@{Hash=$hash;Preexisting=$false;Owned=$false;Description=('ToolbeltDistanceQualification-'+$run);CreationDate=$null;Status='UNCHANGED'}}
 Save-DistanceJournal
 $masterBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString $target));$masterBuilder['Initial Catalog']='master';$masterBuilder['Pooling']=$false
 $master=[Data.SqlClient.SqlConnection]::new($masterBuilder.ConnectionString)
  $phase='CONNECT';$master.Open()
  # Pflichtpreflight wird vollständig gelesen, ohne Inventar zu persistieren.
  $null=Invoke-DistanceSql $master 'SELECT @@VERSION;' -Scalar
  $preflight=$master.CreateCommand();$preflight.CommandText='SELECT name,state_desc FROM sys.databases ORDER BY database_id;';$preflight.CommandTimeout=30
  try{$reader=$preflight.ExecuteReader();try{while($reader.Read()){$null=$reader.GetString(0);$null=$reader.GetString(1)}}finally{$reader.Dispose()}}finally{$preflight.Dispose()}
  $expectedMajor=switch($Version){'2019'{15}'2022'{16}'2025'{17}}
  if((Invoke-DistanceSql $master "SELECT TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion'));" -Scalar)-ne$expectedMajor){throw 'SELECTED_VERSION_MISMATCH'}
  if((Invoke-DistanceSql $master "SELECT COUNT(*) FROM sys.configurations WHERE (name=N'clr enabled' OR name=N'clr strict security') AND value_in_use=1;" -Scalar)-ne2){throw 'CLR_PRECONDITION'}
  $phase='TRUST';$exists=Invoke-DistanceSql $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=0x'+$hash+';') -Scalar
  $journal.Trust.Preexisting=($exists-eq1)
  if(-not$exists){
   if(-not$AllowHashTrustOptIn){throw 'EXPLICIT_TRUST_OPTIN_REQUIRED'}
   if((Test-DistanceForeignConsumers $master $hash)-ne0){throw 'TRUST_CLEANUP_SCOPE_UNCONFIRMED'}
   $journal.Trust.Status='ADD_PENDING';Save-DistanceJournal
   $added=Invoke-DistanceSql $master ("IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x"+$hash+") BEGIN EXEC sys.sp_add_trusted_assembly @hash=0x"+$hash+",@description=N'"+$journal.Trust.Description+"';SELECT 1;END ELSE SELECT 0;") -Scalar
   if($added-eq0){$journal.Trust.Preexisting=$true;$journal.Trust.Status='PREEXISTING'}
   if($added-eq1){$trustOwned=$true;$journal.Trust.Owned=$true;$journal.Trust.Status='OWN_ADDED';$journal.Trust.CreationDate=Invoke-DistanceSql $master ("SELECT CONVERT(nvarchar(30),create_date,126) FROM sys.trusted_assemblies WHERE hash=0x"+$hash+" AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),description))=CONVERT(varbinary(max),N'"+$journal.Trust.Description+"');") -Scalar;if(-not$journal.Trust.CreationDate){throw 'TRUST_OWNERSHIP'}}
  }
  Save-DistanceJournal
  foreach($mode in @('local','central')){
   $phase='DATABASE';$name='ToolbeltDistance_'+$mode+'_'+$run
   $entry=[ordered]@{Name=$name;Id=$null;MarkerWritten=$false;Status='CREATE_PENDING'};$journal.Databases+=,$entry;Save-DistanceJournal
   $databaseCollation=if($mode-eq'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_CI_AS'}
   Invoke-DistanceSql $master ('CREATE DATABASE ['+$name+'] COLLATE '+$databaseCollation+';')
   $entry.Id=Invoke-DistanceSql $master ("SELECT DB_ID(N'"+$name+"');") -Scalar
   $entry.Status='CREATED';Save-DistanceJournal
   $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($masterBuilder.ConnectionString);$builder['Initial Catalog']=$name
   $work=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$work.Open()
   Invoke-DistanceSql $work ("EXEC sys.sp_addextendedproperty @name=N'Toolbelt.DistanceQualification.RunToken',@value=N'"+$run+"';")
   $entry.MarkerWritten=$true;Save-DistanceJournal
   $variables=@{AssemblyBits=$bits;DeploymentMode=$mode;ExpectedInstalledAssemblyHash='0x';ConfirmNoExternalConsumers='1'}
   # Ein vorhandener NULL-Modemarker ist keine frische Modulabwesenheit.
   $phase='NULL_MODE_MARKER'
   Invoke-DistanceSql $work "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.string.edit-distance.DeploymentMode',@value=NULL;"
   foreach($file in @('Deploy.sql','Uninstall.sql')){Test-DistanceFailure $work (Join-Path $moduleRoot ('Deployment/'+$file)) $variables 55033}
   if((Invoke-DistanceSql $work "SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.edit-distance.DeploymentMode' AND value IS NULL;" -Scalar)-ne1){throw 'NULL_MODE_MARKER_CHANGED'}
   Invoke-DistanceSql $work "EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.string.edit-distance.DeploymentMode';"
   $phase='DEPLOY';Invoke-DistanceFile $work (Join-Path $moduleRoot 'Deployment/Deploy.sql') $variables
   $variables.ExpectedInstalledAssemblyHash='0x'+$hash
   $levels=switch($Version){'2019'{@(150)}'2022'{@(150,160)}'2025'{@(150,160,170)}}
   foreach($level in $levels){
    Invoke-DistanceSql $work ('ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL='+$level+';')
    foreach($fixture in @('Distance.Contract.sql','Distance.Boundaries.sql','Jaro.Contract.sql','Jaro.Boundaries.sql','InstalledMetadata.Contract.sql','Lifecycle.Contract.sql')){$phase='API_'+$mode+'_'+$level+'_'+$fixture;Invoke-DistanceFile $work (Join-Path $PSScriptRoot $fixture) $variables}
   }
   $phase='CLIENT_METADATA';Test-DistanceClientSchema $work '';Test-JaroClientSchema $work ''
   $phase='REINSTALL';Invoke-DistanceFile $work (Join-Path $moduleRoot 'Deployment/Deploy.sql') $variables
   $phase='CALLER_TRANSACTION'
   foreach($abort in @('OFF','ON')){foreach($count in @('OFF','ON')){
    Invoke-DistanceSql $work ("SET XACT_ABORT "+$abort+";SET NOCOUNT "+$count+";CREATE TABLE #DistanceCaller(Value int);BEGIN TRANSACTION;INSERT #DistanceCaller VALUES(37);")
    $options=Invoke-DistanceSql $work 'SELECT @@OPTIONS;' -Scalar
    foreach($file in @('Deploy.sql','Uninstall.sql')){
     Test-DistanceFailure $work (Join-Path $moduleRoot ('Deployment/'+$file)) $variables 50000
     if((Invoke-DistanceSql $work 'SELECT @@OPTIONS;' -Scalar)-ne$options-or(Invoke-DistanceSql $work 'SELECT @@TRANCOUNT;' -Scalar)-ne1-or(Invoke-DistanceSql $work 'SELECT XACT_STATE();' -Scalar)-ne1-or(Invoke-DistanceSql $work 'SELECT COUNT(*) FROM #DistanceCaller WHERE Value=37;' -Scalar)-ne1){throw 'CALLER_TRANSACTION_OR_OPTIONS'}
    }
    Invoke-DistanceSql $work 'ROLLBACK;DROP TABLE #DistanceCaller;'
   }}
   $phase='LOCK_CONTENTION'
   $holder=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
   try{
    $holder.Open()
    $held=Invoke-DistanceSql $holder "BEGIN TRANSACTION;DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.string.edit-distance',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';SELECT @r;" -Scalar
    if($held-lt0){throw 'LOCK_HOLDER'}
    foreach($file in @('Deploy.sql','Uninstall.sql')){Test-DistanceFailure $work (Join-Path $moduleRoot ('Deployment/'+$file)) $variables 55035}
   }finally{if($holder.State-eq'Open'){Invoke-DistanceSql $holder 'IF @@TRANCOUNT>0 ROLLBACK;'};$holder.Dispose()}
   $phase='POST_DROP_ROLLBACK'
   foreach($file in @('Deploy.sql','Uninstall.sql')){
    $original=Expand-DistanceSql (Join-Path $moduleRoot ('Deployment/'+$file)) $variables
    $drop='DROP FUNCTION [toolbelt_string].[TVF_LevenshteinDistance];'
    if([regex]::Matches($original,[regex]::Escape($drop)).Count-ne1){throw 'FAULT_INJECTION_ANCHOR'}
    $injected=$original.Replace($drop,$drop+" THROW 55099,N'Synthetic post-DROP fault',1;")
    Test-DistanceSourceFailure $work $injected 55099 1
    foreach($predicate in @('0','NULL')){
     $gate="ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION'), 0)"
     if([regex]::Matches($original,[regex]::Escape($gate)).Count-ne1){throw 'RIGHTS_INJECTION_ANCHOR'}
     # NULL wird wie ein nicht bestätigtes Recht behandelt; nur synthetische Negativprobe.
     $replacement="ISNULL(CASE WHEN @Pass=2 THEN "+$predicate+" ELSE HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION') END,0)"
     Test-DistanceSourceFailure $work $original.Replace($gate,$replacement) 55034 6
    }
   }
   $phase='COLLISIONS'
   foreach($case in @('unknown-version','padded-version','missing-marker','external-dependency','wrong-kind','alias-parameter')){
    $collision=$variables.Clone();$collision.CollisionCase=$case
    Invoke-DistanceFile $work (Join-Path $PSScriptRoot 'Lifecycle.CollisionFixture.sql') $collision
    $expectedFailure=switch($case){'unknown-version'{55032}'padded-version'{55032}'external-dependency'{55038}default{55033}}
    foreach($file in @('Deploy.sql','Uninstall.sql')){Test-DistanceFailure $work (Join-Path $moduleRoot ('Deployment/'+$file)) $variables $expectedFailure}
    $restoreCase=if($case-eq'alias-parameter'){'wrong-kind'}else{$case}
    switch($restoreCase){
     'unknown-version'{Invoke-DistanceSql $work "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.edit-distance.Version',@value=N'1.1.0';"}
     'padded-version'{Invoke-DistanceSql $work "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.edit-distance.Version',@value=N'1.1.0';"}
     'missing-marker'{Invoke-DistanceSql $work "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_OsaDistance';"}
     'external-dependency'{Invoke-DistanceSql $work 'DROP VIEW dbo.ToolbeltDistanceFixtureConsumer;'}
     'wrong-kind'{
      Invoke-DistanceSql $work 'DROP FUNCTION toolbelt_string.TVF_OsaDistance;'
      if($case-eq'alias-parameter'){Invoke-DistanceSql $work 'DROP TYPE dbo.ToolbeltDistanceFixtureAlias;'}
      $facade=@([regex]::Split((Expand-DistanceSql (Join-Path $moduleRoot 'Source/EditDistance.sql') @{}),'(?im)^\s*GO\s*$')|Where-Object{$_-match'CREATE FUNCTION toolbelt_string\.TVF_OsaDistance\s*\('})
      if($facade.Count-ne1){throw 'RESTORE_FACADE_ANCHOR'}
      Invoke-DistanceSql $work $facade[0]
      foreach($property in @(@('Toolbelt.Managed',1),@('Toolbelt.ModuleId','toolbelt.string.edit-distance'),@('Toolbelt.ModuleVersion','1.1.0'),@('Toolbelt.Visibility','public'))){
       Invoke-DistanceSql $work ("EXEC sys.sp_addextendedproperty @name=N'"+$property[0]+"',@value="+$(if($property[0]-eq'Toolbelt.Managed'){'1'}else{"N'"+$property[1]+"'"})+",@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_OsaDistance';")
      }
     }
    }
    Invoke-DistanceFile $work (Join-Path $PSScriptRoot 'Lifecycle.Contract.sql') $variables
   }
   $phase='NEGATIVE_HASH';$negative=$variables.Clone();$negative.ExpectedInstalledAssemblyHash='0x'+('00'*64)
   Test-DistanceFailure $work (Join-Path $moduleRoot 'Deployment/Deploy.sql') $negative 55047
   Test-DistanceFailure $work (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $negative 55047
   $negative.ExpectedInstalledAssemblyHash='0x00'
   Test-DistanceFailure $work (Join-Path $moduleRoot 'Deployment/Deploy.sql') $negative 55046
   Test-DistanceFailure $work (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $negative 55046
   if($mode-eq'central'){
    $phase='CENTRAL_CONSUMER';$consumerName='ToolbeltDistance_consumer_'+$run
    $consumerEntry=[ordered]@{Name=$consumerName;Id=$null;MarkerWritten=$false;Status='CREATE_PENDING'};$journal.Databases+=,$consumerEntry;Save-DistanceJournal
    Invoke-DistanceSql $master ('CREATE DATABASE ['+$consumerName+'] COLLATE Latin1_General_100_CI_AS_SC_UTF8;')
    $consumerEntry.Id=Invoke-DistanceSql $master ("SELECT DB_ID(N'"+$consumerName+"');") -Scalar
    $consumerEntry.Status='CREATED';Save-DistanceJournal
    $consumerBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new($masterBuilder.ConnectionString);$consumerBuilder['Initial Catalog']=$consumerName
    $consumer=[Data.SqlClient.SqlConnection]::new($consumerBuilder.ConnectionString)
    try{
     $consumer.Open();Invoke-DistanceSql $consumer ("EXEC sys.sp_addextendedproperty @name=N'Toolbelt.DistanceQualification.RunToken',@value=N'"+$run+"';")
     $consumerEntry.MarkerWritten=$true;Save-DistanceJournal
     Invoke-DistanceSql $consumer ('ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL='+$levels[-1]+';')
     Test-DistanceClientSchema $consumer ('['+$name+'].');Test-JaroClientSchema $consumer ('['+$name+'].')
    }finally{$consumer.Dispose();$consumerBuilder.Clear()}
   }
   $phase='SHARED_SCHEMA_PRESERVATION'
   Invoke-DistanceSql $work 'CREATE FUNCTION toolbelt_string.TVF_DistanceForeignFixture() RETURNS TABLE AS RETURN SELECT CONVERT(int,37) AS Value;'
   $phase='UNINSTALL';Invoke-DistanceFile $work (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $variables
   if((Invoke-DistanceSql $work "SELECT COUNT(*) FROM sys.assemblies WHERE name=N'Toolbelt_String_EditDistance';" -Scalar)-ne0){throw 'UNINSTALL_ASSEMBLY'}
   if((Invoke-DistanceSql $work 'SELECT Value FROM toolbelt_string.TVF_DistanceForeignFixture();' -Scalar)-ne37){throw 'FOREIGN_SCHEMA_OBJECT_PRESERVATION'}
   $work.Dispose();$work=$null;$builder.Clear()
  }
  $journal.Status='PASSED'
 }catch{
  if($journal){$journal.Status='FAILED'};$cause=$_.Exception;while($cause-and$cause-isnot[Data.SqlClient.SqlException]){$cause=$cause.InnerException}
  if($journal){$journal.Failure=@{Phase=$phase;SqlNumber=if($cause){$cause.Number}else{0};SqlState=if($cause){$cause.State}else{0}}}
 }finally{
  try{
  if($work){try{$work.Dispose()}catch{$phase='DISPOSE'};$work=$null}
  if($journal){
  $cleanup=($journal.Trust.Status-ne'ADD_PENDING')
  try{
   foreach($entry in $journal.Databases){
    if(-not$entry.MarkerWritten){$cleanup=$false;$entry.Status='OWNERSHIP_UNCONFIRMED';continue}
    $dropped=Invoke-DistanceSql $master ("IF DB_ID(N'"+$entry.Name+"')="+$entry.Id+" AND EXISTS(SELECT 1 FROM ["+$entry.Name+"].sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.DistanceQualification.RunToken' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'"+$run+"')) BEGIN DROP DATABASE ["+$entry.Name+"];SELECT 1;END ELSE SELECT 0;") -Scalar
    if($dropped-ne1){$cleanup=$false;$entry.Status='OWNERSHIP_CHANGED';continue}
    if((Invoke-DistanceSql $master ("SELECT DB_ID(N'"+$entry.Name+"');") -Scalar)-isnot[DBNull]){$cleanup=$false;$entry.Status='DROP_UNVERIFIED'}else{$entry.Status='DROPPED'}
   }
   if($trustOwned){
    $foreign=Test-DistanceForeignConsumers $master $hash
    if($cleanup-and$foreign-eq0){
     $removed=Invoke-DistanceSql $master ("IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x"+$hash+" AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),description))=CONVERT(varbinary(max),N'"+$journal.Trust.Description+"') AND CONVERT(varbinary(max),CONVERT(nvarchar(30),create_date,126))=CONVERT(varbinary(max),N'"+$journal.Trust.CreationDate+"')) BEGIN EXEC sys.sp_drop_trusted_assembly @hash=0x"+$hash+";SELECT 1;END ELSE SELECT 0;") -Scalar
     if($removed-ne1){$cleanup=$false;$journal.Trust.Status='OWNERSHIP_CHANGED'}
     elseif((Invoke-DistanceSql $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=0x'+$hash+';') -Scalar)-eq0){$journal.Trust.Status='RESTORED'}
     else{$cleanup=$false;$journal.Trust.Status='RESTORE_UNVERIFIED'}
    }else{$cleanup=$false;$journal.Trust.Status='OWNERSHIP_OR_CONSUMERS_CHANGED'}
   }
  }catch{$cleanup=$false}
  if($cleanup){$journal.Status=if($journal.Status-eq'PASSED'){'COMPLETE'}else{'FAILED_CLEANED'}}else{$journal.Status='RESTORE_REQUIRED'}
  try{Save-DistanceJournal}catch{$journal.Status='RESTORE_REQUIRED';$phase='JOURNAL'}
  }
  }finally{
   # Auch fehlgeschlagene Journalwrites dürfen Disposal niemals überspringen.
   try{if($work){try{$work.Dispose()}catch{$phase='DISPOSE'}}}finally{
    try{if($master){try{$master.Dispose()}catch{$phase='DISPOSE'};$master=$null}}finally{
     try{if($builder){try{$builder.Clear()}catch{$phase='DISPOSE'}}}finally{if($masterBuilder){try{$masterBuilder.Clear()}catch{$phase='DISPOSE'}}}
    }
   }
  }
 }
 if(-not$journal-or$journal.Status-ne'COMPLETE'-or$phase-eq'DISPOSE'){throw ('DISTANCE_LAB_FAILED_PHASE_'+$phase)}
}
Write-Output 'PASS Distance Lab'