param(
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
 [Parameter(Mandatory)][ValidateSet('local','central')][string]$Mode,
 [Parameter(Mandatory)][string]$PreviousRelease,
 [Parameter(Mandatory)][string]$CurrentRelease,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$ExpectedOldHash,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$ExpectedNewHash,
 [string]$IntermediateRelease,
 [ValidatePattern('^[0-9A-F]{128}$')][string]$ExpectedIntermediateHash
)
# Nur im eigenen Datenbank-/Trustscope des Labadapters; keine Marker als Upgradeersatz.
$checks=0
function AssertUpgrade([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_BUILD_UPGRADE_'+$Name)};$script:checks++}
function BuildState {
 Query $Connection @'
SELECT a.assembly_id,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) AS BinaryHash,
 OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow',N'P') AS PublicId,
 OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal',N'PC') AS InternalId,
 (SELECT CONVERT(nvarchar(64),value) FROM sys.extended_properties WITH(NOLOCK)
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version') AS ModuleVersion
FROM sys.assemblies a WITH(NOLOCK) JOIN sys.assembly_files f WITH(NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1
WHERE a.name=N'Toolbelt_Tsql_SsisDebug';
'@
}
function Capture([string]$Operation,[string]$Bindings){
 $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=Get-SsisNativeTimeout 40;$cmd.CommandType='StoredProcedure';$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'
 [void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@PackageBytes'].Value=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot '../Fixtures/synthetic-8.dtsx'))
 [void]$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32);$cmd.Parameters['@Operation'].Value=$Operation
 if($Bindings){
  [void]$cmd.Parameters.Add('@Bindings',[Data.SqlDbType]::NVarChar,-1);$cmd.Parameters['@Bindings'].Value=$Bindings
  $name=$Connection.Database
  [void]$cmd.Parameters.Add('@CatalogBindings',[Data.SqlDbType]::NVarChar,-1)
  $cmd.Parameters['@CatalogBindings'].Value=(@{schemaVersion=1;defaultDatabase=$name;databases=@($name);connections=@{'Package.ConnectionManagers[Synthetic]'=$name}}|ConvertTo-Json -Depth 4 -Compress)
 }
 try{
  $table=[Data.DataTable]::new();$reader=$cmd.ExecuteReader();try{$table.Load($reader)}finally{$reader.Dispose()};return ,$table
 }finally{$cmd.Dispose()}
}
AssertUpgrade ($ExpectedOldHash -cne $ExpectedNewHash -and (-not $IntermediateRelease -or ($ExpectedIntermediateHash -and $ExpectedIntermediateHash -cne $ExpectedOldHash -and $ExpectedIntermediateHash -cne $ExpectedNewHash))) 'DISTINCT_REAL_BINARIES'
Batches $Connection ([IO.File]::ReadAllText((Join-Path $PreviousRelease 'Deploy.WithAssembly.sql'))) $Mode
$before=BuildState
AssertUpgrade ($before.Rows.Count -eq 1 -and [string]$before.Rows[0].BinaryHash -ceq $ExpectedOldHash) 'GENUINE_OLD_BINARY'
AssertUpgrade ([string]$before.Rows[0].ModuleVersion -ceq '1.0.0' -and $before.Rows[0].PublicId -isnot [DBNull] -and $before.Rows[0].InternalId -isnot [DBNull]) 'OLD_OWNED_API'
$template=Capture 'bindings-template' $null
AssertUpgrade ($template.Rows.Count -eq 1 -and [string]$template.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'OLD_PUBLIC_TEMPLATE'
$bindings=[string]$template.Rows[0].Content
$originalBindings=$bindings
$steps=@()
if($IntermediateRelease){$steps+=@{Release=$IntermediateRelease;Hash=$ExpectedIntermediateHash;Intermediate=$true}}
$steps+=@{Release=$CurrentRelease;Hash=$ExpectedNewHash;Intermediate=$false}
# Beide tatsächlich erzeugten Vorgängervorlagen werden am endgültigen Einstieg geprüft.
NonQuery $Connection 'CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);'
try{
 foreach($step in $steps){
  Batches $Connection ([IO.File]::ReadAllText((Join-Path $step.Release 'Deploy.WithAssembly.sql'))) $Mode
  $after=BuildState
  AssertUpgrade ($after.Rows.Count -eq 1 -and [string]$after.Rows[0].BinaryHash -ceq $step.Hash) 'EXACT_NEW_BINARY'
  AssertUpgrade ($after.Rows[0].assembly_id -eq $before.Rows[0].assembly_id -and $after.Rows[0].PublicId -eq $before.Rows[0].PublicId -and $after.Rows[0].InternalId -eq $before.Rows[0].InternalId) 'IDENTITIES_RETAINED'
  AssertUpgrade ([string]$after.Rows[0].ModuleVersion -ceq '1.0.0') 'UNCHANGED_PUBLIC_VERSION'
  $result=Capture 'explain' $bindings
  AssertUpgrade ($result.Columns.Count -eq 13 -and @($result.Select("ArtifactKind='TargetSql' AND IsExecutable=1")).Count -gt 0) 'OLD_BINDINGS_ACCEPTED_BY_NEW_BUILD'
  if($step.Intermediate){
   $template=Capture 'bindings-template' $null
   AssertUpgrade ($template.Rows.Count -eq 1 -and [string]$template.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'INTERMEDIATE_PUBLIC_TEMPLATE'
   $bindings=[string]$template.Rows[0].Content
  }elseif($IntermediateRelease){
   $result=Capture 'explain' $originalBindings
   AssertUpgrade ($result.Columns.Count -eq 13 -and @($result.Select("ArtifactKind='TargetSql' AND IsExecutable=1")).Count -gt 0) 'ORIGINAL_BINDINGS_STILL_ACCEPTED'
  }
 }
}finally{NonQuery $Connection 'DROP TABLE dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup;'}
"SSIS_NATIVE_BUILD_UPGRADE_PASS $checks assertions; exact previous/new bytes and unchanged public identities"
