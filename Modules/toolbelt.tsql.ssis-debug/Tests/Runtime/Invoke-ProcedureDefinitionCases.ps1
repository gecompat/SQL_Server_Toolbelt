[CmdletBinding()]
param(
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Master,
 [Parameter(Mandatory)][string]$AdminConnectionString,
 [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{32}$')][string]$RunId,
 [Parameter(Mandatory)][string]$IdentityJournal
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:checks=0
function Assert-Current([bool]$Condition,[string]$Check){
 if(-not $Condition){throw "SSIS_PROCEDURE_ASSERT_$Check"}
 $script:checks++
}
function Invoke-CurrentSql([string]$Sql){return ,(Query $Connection $Sql)}
function Get-InstalledProcedure {
 $snapshot=Query $Connection @'
SELECT p.object_id AS Id,p.schema_id AS SchemaId,p.create_date AS Created,p.modify_date AS Modified,
       COALESCE(p.principal_id,s.principal_id) AS OwnerId,m.definition AS Definition
FROM sys.procedures AS p
JOIN sys.schemas AS s ON s.schema_id=p.schema_id
JOIN sys.sql_modules AS m ON m.object_id=p.object_id
WHERE p.object_id=OBJECT_ID(N'ContosoDebug.USP_Synthetic',N'P');
'@
 if($snapshot.Rows.Count -ne 1 -or $snapshot.Rows[0].Definition -isnot [string]){throw 'SSIS_PROCEDURE_INSTALLED_SNAPSHOT_MISSING'}
 return ,$snapshot.Rows[0]
}
function Get-InstalledProcedureBody([string]$Definition){
 $header=[regex]::Match($Definition,'\A(?:CREATE|ALTER)[ \t]+PROCEDURE[ \t]+',[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::CultureInvariant)
 if(-not $header.Success){throw 'SSIS_PROCEDURE_INSTALLED_HEADER'}
 return $Definition.Substring($header.Length).TrimEnd()
}
function Test-OwnedProcedure($Expected,$Actual){
 return $Actual.Id -eq $Expected.Id -and $Actual.SchemaId -eq $Expected.SchemaId -and
     $Actual.Created -eq $Expected.Created -and $Actual.OwnerId -eq $Expected.OwnerId
}
function Test-ExactProcedureVersion($Expected,$Actual){
 return (Test-OwnedProcedure $Expected $Actual) -and $Actual.Modified -eq $Expected.Modified -and
     $Actual.Definition -ceq $Expected.Definition
}
function Reject-Procedure([scriptblock]$Operation,[int]$Number){
 try{& $Operation|Out-Null}catch{
  $leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException}
  if($leaf -isnot [Data.SqlClient.SqlException] -or $leaf.Number -ne $Number){throw}
  $script:checks++
  return
 }
 throw "SSIS_PROCEDURE_EXPECTED_ERROR_$Number"
}
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-CurrentCases.ps1'),[ref]$null,[ref]$errors)
$method=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Invoke-CurrentDebugScript'},$true))
if($errors.Count -or $method.Count -ne 1){throw 'SSIS_PROCEDURE_DEBUG_ORACLE_BINDING'}
. ([scriptblock]::Create($method[0].Extent.Text))
$bytes=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot '../Fixtures/procedure-8.dtsx'))
$db=$Connection.Database
$catalog=@{schemaVersion=1;defaultDatabase=$db;databases=@($db);connections=@{'Package.ConnectionManagers[Synthetic]'=$db}}|ConvertTo-Json -Depth 4 -Compress
function Generate-ProcedureArtifact([string]$Operation,[string]$Bindings){
 $cmd=$Connection.CreateCommand()
 $cmd.CommandTimeout=Get-SsisNativeTimeout
 $cmd.CommandType='StoredProcedure'
 $cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'
 try{
  $cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1).Value=$bytes
  $cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32).Value=$Operation
  if($Operation -ne 'bindings-template'){
   $cmd.Parameters.Add('@CatalogBindings',[Data.SqlDbType]::NVarChar,-1).Value=$catalog
   $cmd.Parameters.Add('@Bindings',[Data.SqlDbType]::NVarChar,-1).Value=$Bindings
   $cmd.Parameters.Add('@TargetFlow',[Data.SqlDbType]::VarChar,64).Value='f0001'
  }
  if($Operation -eq 'procedure-definition'){
   $cmd.Parameters.Add('@ProcedureSchema',[Data.SqlDbType]::NVarChar,-1).Value='ContosoDebug'
   $cmd.Parameters.Add('@ProcedureName',[Data.SqlDbType]::NVarChar,-1).Value='USP_Synthetic'
  }
  $table=[Data.DataTable]::new()
  $reader=$cmd.ExecuteReader()
  try{$table.Load($reader)}finally{$reader.Dispose()}
  return ,$table
 }finally{$cmd.Dispose()}
}
function Read-Projection([Data.SqlClient.SqlDataReader]$Reader){
 try{
  $schema=$Reader.GetSchemaTable()
  Assert-Current ($schema.Rows.Count -eq 2 -and $Reader.GetName(0) -ceq 'KeyA' -and $Reader.GetName(1) -ceq 'Adjusted' -and
      @($schema.Rows|Where-Object {$_.DataType -ne [int] -or $_.AllowDBNull}).Count -eq 0) 'NATIVE_PROJECTION_SHAPE'
  $rows=@(while($Reader.Read()){"$($Reader.GetInt32(0))=$($Reader.GetInt32(1))"})
  Assert-Current (-not $Reader.NextResult()) 'SINGLE_RESULTSET'
  return ($rows | Sort-Object) -join ','
 }finally{$Reader.Dispose()}
}
NonQuery $Connection @'
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(2,10,200);
EXEC(N'CREATE SCHEMA ContosoDebug AUTHORIZATION dbo;');
EXEC(N'CREATE PROCEDURE ContosoDebug.USP_Unrelated AS SELECT 7 AS Witness;');
'@
$template=[string](Generate-ProcedureArtifact 'bindings-template' '').Rows[0].Content
$artifacts=Generate-ProcedureArtifact 'procedure-definition' $template
$definitions=@($artifacts.Select("ArtifactKind='ProcedureDefinition'"))
$manifests=@($artifacts.Select("ArtifactKind='ProcedureManifest'"))
Assert-Current ($definitions.Count -eq 1 -and $manifests.Count -eq 1 -and $definitions[0].IsComplete -and -not $definitions[0].IsExecutable) 'DEFINITION_AND_MANIFEST'
$definition=[string]$definitions[0].Content
$manifest=$manifests[0].Content|ConvertFrom-Json -AsHashtable
Assert-Current ($manifest.definitionSha256 -ceq [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($definition)))) 'DEFINITION_HASH'
$floor=[string](@($manifest.parameters|Where-Object inputName -like '*SourceFloor')[0].name)
$offset=[string](@($manifest.parameters|Where-Object inputName -like '*Offset')[0].name)
Assert-Current ($floor -cmatch '^@v[0-9]+$' -and $offset -cmatch '^@v[0-9]+$' -and $floor -cne $offset) 'TYPED_KEYS'
NonQuery $Connection $definition
$installed=Get-InstalledProcedure
Assert-Current ($installed.Definition.TrimEnd() -ceq $definition.TrimEnd()) 'CREATE_PERSISTS_DEFINITION'
Reject-Procedure {NonQuery $Connection $definition} 2714
Assert-Current (Test-ExactProcedureVersion $installed (Get-InstalledProcedure)) 'CREATE_COLLISION_PRESERVES_DEFINITION'
$login='ToolbeltSsisProc_'+$RunId.Substring(0,16)
$sid=[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
$password='aA1!'+[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
$identity=[ordered]@{login=$login;sid=$sid;state='INTENT'}
if(Test-Path -LiteralPath $IdentityJournal){throw 'SSIS_PROCEDURE_IDENTITY_JOURNAL_COLLISION'}
function Save-Identity{$identity|ConvertTo-Json -Compress|Set-Content -LiteralPath $IdentityJournal -Encoding utf8NoBOM}
Save-Identity
$callerBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new($AdminConnectionString)
$callerBuilder['Integrated Security']=$false
$callerBuilder['User ID']=$login
$callerBuilder['Password']=$password
$callerBuilder['Initial Catalog']=$db
$callerBuilder['Pooling']=$false
$callerBuilder['Connect Timeout']=10
$caller=[Data.SqlClient.SqlConnection]::new($callerBuilder.ConnectionString)
$other=[Data.SqlClient.SqlConnection]::new($callerBuilder.ConnectionString)
function New-ProjectionCommand($Channel,[int]$Minimum,[int]$Delta){
 $cmd=$Channel.CreateCommand()
 $cmd.CommandTimeout=Get-SsisNativeTimeout
 $cmd.CommandType='StoredProcedure'
 $cmd.CommandText='ContosoDebug.USP_Synthetic'
 $cmd.Parameters.Add($floor,[Data.SqlDbType]::Int).Value=$Minimum
 $cmd.Parameters.Add($offset,[Data.SqlDbType]::Int).Value=$Delta
 return $cmd
}
try{
 Assert-Current ((Query $Master "SELECT COUNT(*) AS N FROM sys.server_principals WHERE name=N'$login' OR sid=0x$sid;").Rows[0].N -eq 0) 'LOGIN_ABSENT'
 $identity.state='CREATE_DISPATCHED';Save-Identity
 NonQuery $Master "CREATE LOGIN [$login] WITH PASSWORD=N'$password',SID=0x$sid,CHECK_POLICY=ON,CHECK_EXPIRATION=OFF;"
 $identity.state='ACTIVE';Save-Identity
 NonQuery $Connection "CREATE USER [$login] FOR LOGIN [$login]; GRANT CONNECT TO [$login]; GRANT VIEW DEFINITION TO [$login]; GRANT EXECUTE ON OBJECT::ContosoDebug.USP_Synthetic TO [$login]; GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO [$login];"
 $caller.Open()
 $rights=Query $caller "SELECT ORIGINAL_LOGIN() AS L,IS_SRVROLEMEMBER(N'sysadmin') AS A,HAS_PERMS_BY_NAME(N'dbo.SyntheticSourceA',N'OBJECT',N'SELECT') AS S;"
 Assert-Current ($rights.Rows[0].L -ceq $login -and $rights.Rows[0].A -eq 0 -and $rights.Rows[0].S -eq 0) 'REAL_LOWPRIV_WITHOUT_SELECT'
 $owners=Query $Connection "SELECT COUNT(DISTINCT COALESCE(o.principal_id,s.principal_id)) AS N FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.object_id IN(OBJECT_ID(N'dbo.SyntheticSourceA'),OBJECT_ID(N'ContosoDebug.USP_Synthetic'));"
 Assert-Current ($owners.Rows[0].N -eq 1) 'SAME_SOURCE_AND_PROCEDURE_OWNER'
 Assert-Current ((Query $caller 'EXEC ContosoDebug.USP_Synthetic @Hilfe=1;').Select("Section='PARAMETER'").Count -eq 6) 'HELP_WITHOUT_SOURCE_ACCESS'
 Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1;"} 229
 Reject-Procedure {Query $caller 'EXEC ContosoDebug.USP_Synthetic;'} 50000
 NonQuery $Connection "GRANT SELECT ON OBJECT::dbo.SyntheticSourceA TO [$login];"
 foreach($scenario in @(@{Floor=0;Offset=1;Expected='1=101,2=201'},@{Floor=150;Offset=7;Expected='2=207'},@{Floor=999;Offset=2;Expected=''})){
  $binding=$template|ConvertFrom-Json -AsHashtable -Depth 20
  $binding.values[$floor.Substring(1)]=$scenario.Floor
  $binding.values[$offset.Substring(1)]=$scenario.Offset
  $debug=Generate-ProcedureArtifact 'explain' ($binding|ConvertTo-Json -Depth 20 -Compress)
  $bundle=@($debug.Select("ArtifactKind='DebugScript'"))[0]
  $old=(Invoke-CurrentDebugScript $debug $bundle).TargetSql
  $oldRows=(@($old.Rows|ForEach-Object {"$($_.KeyA)=$($_.Adjusted)"})|Sort-Object) -join ','
  $cmd=New-ProjectionCommand $caller $scenario.Floor $scenario.Offset
  try{$actual=Read-Projection ($cmd.ExecuteReader())}finally{$cmd.Dispose()}
  Assert-Current ($actual -ceq $scenario.Expected -and $actual -ceq $oldRows) 'DEBUGSCRIPT_PROJECTION_PARITY'
 }
 NonQuery $caller 'CREATE TABLE #Projection(Dummy bit NULL);'
 NonQuery $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1,@ResultTable=N'#Projection';"
 NonQuery $caller "EXEC ContosoDebug.USP_Synthetic $floor=150,$offset=7,@ResultTable=N'#Projection',@KeepData=1;"
 Assert-Current ((Query $caller 'SELECT COUNT(*) AS N FROM #Projection;').Rows[0].N -eq 3) 'RESULTTABLE_APPEND'
 NonQuery $caller "EXEC ContosoDebug.USP_Synthetic $floor=150,$offset=7,@ResultTable=N'#Projection',@KeepData=0;"
 Assert-Current ((Query $caller 'SELECT Adjusted FROM #Projection;').Rows[0].Adjusted -eq 207) 'RESULTTABLE_REPLACE'
 $temp=[regex]::Match($definition,'CREATE TABLE \[(#tbx_SsisDebug_P_[A-F0-9_]+s[0-9]+)\]').Groups[1].Value
 Assert-Current ([bool]$temp) 'TEMP_WITNESS'
 NonQuery $caller "CREATE TABLE [$temp](Witness int); INSERT [$temp] VALUES(7);"
 Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1;"} 50000
 Assert-Current ((Query $caller "SELECT Witness FROM [$temp];").Rows[0].Witness -eq 7) 'CALLER_TEMP_PRESERVED'
 NonQuery $caller "DROP TABLE [$temp];"
 $other.Open()
 $first=New-ProjectionCommand $caller 0 1
 $second=New-ProjectionCommand $other 150 7
 try{
  $firstReader=$first.ExecuteReaderAsync();$secondReader=$second.ExecuteReaderAsync()
  Assert-Current ((Read-Projection ($firstReader.GetAwaiter().GetResult())) -ceq '1=101,2=201' -and
      (Read-Projection ($secondReader.GetAwaiter().GetResult())) -ceq '2=207') 'CONCURRENT_CALLER_SESSIONS'
 }finally{$first.Dispose();$second.Dispose()}
 Assert-Current (Test-ExactProcedureVersion $installed (Get-InstalledProcedure)) 'OWNED_UPDATE_PRECONDITION'
 $body=Get-InstalledProcedureBody $definition
 $update='ALTER PROCEDURE '+$body.Replace("SET NOCOUNT ON;`n","SET NOCOUNT ON;`n-- Contoso lifecycle revision 2`n")
 Assert-Current ($update.Contains('-- Contoso lifecycle revision 2')) 'UPDATE_VERSION_WITNESS'
 NonQuery $Connection $update
 $updated=Get-InstalledProcedure
 Assert-Current ((Test-OwnedProcedure $installed $updated) -and
     (Get-InstalledProcedureBody $updated.Definition) -ceq (Get-InstalledProcedureBody $update)) 'ALTER_PERSISTS_OWNED_VERSION'
 Assert-Current ((Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=150,$offset=7;").Rows[0].Adjusted -eq 207) 'UPDATE_PRESERVES_EXECUTE'
 NonQuery $Connection 'ALTER TABLE dbo.SyntheticSourceA ADD Drift int NULL;'
 Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1;"} 50000
 Assert-Current (Test-ExactProcedureVersion $updated (Get-InstalledProcedure)) 'OWNED_REMOVE_PRECONDITION'
 NonQuery $Connection 'DROP PROCEDURE ContosoDebug.USP_Synthetic;'
 Assert-Current ((Query $Connection "SELECT OBJECT_ID(N'ContosoDebug.USP_Synthetic',N'P') AS Id;").Rows[0].IsNull('Id')) 'OWN_PROCEDURE_REMOVED'
 Assert-Current ((Query $Connection 'EXEC ContosoDebug.USP_Unrelated;').Rows[0].Witness -eq 7) 'FOREIGN_DDL_OBJECT_PRESERVED'
}finally{
 $caller.Dispose();$other.Dispose()
 if($identity.state -in @('CREATE_DISPATCHED','ACTIVE')){
  NonQuery $Connection "IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'$login' AND sid=0x$sid) DROP USER [$login];"
  NonQuery $Master "IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name=N'$login' AND sid=0x$sid) DROP LOGIN [$login];"
  Assert-Current ((Query $Master "SELECT COUNT(*) AS N FROM sys.server_principals WHERE name=N'$login' OR sid=0x$sid;").Rows[0].N -eq 0) 'OWN_LOGIN_REMOVED'
  $identity.state='CLEANED';Save-Identity
 }
}
"SSIS_PROCEDURE_NATIVE_PASS $script:checks checks"
