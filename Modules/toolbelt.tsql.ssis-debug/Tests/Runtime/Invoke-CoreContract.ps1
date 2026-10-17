[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[switch]$Full,[string]$CrossDatabase)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Nur in einer vom Labadapter ausdrücklich angelegten, eigenen Testdatenbank
# ausführen. Verbindungs-/Deployment-/Trustentscheidungen gehören zum Adapter.
if($Connection.State -ne 'Open'){throw 'SSIS_NATIVE_CONNECTION_NOT_OPEN'}
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:checks=0
function Sql([string]$Text){
 $cmd=$Connection.CreateCommand();$cmd.CommandText=$Text;$cmd.CommandTimeout=40
 try{$table=[Data.DataTable]::new();$reader=$cmd.ExecuteReader();try{if($reader.FieldCount -gt 0){$table.Load($reader)}}finally{$reader.Dispose()};return ,$table}finally{$cmd.Dispose()}
}
function Check([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_NATIVE_ASSERT_'+$Name)};$script:checks++}
function Explain([byte[]]$Bytes,[string]$Operation='explain',[string]$Bindings,[string]$Catalog,[string]$Target,[string]$Stage,[string]$ResultTable,[bool]$Keep=$false,[bool]$Help=$false,[string]$Policies,[byte]$Debug=0,[string]$Collation,[string]$Procedure='toolbelt_tsql.USP_ExplainSsisDataFlow',[Data.SqlClient.SqlConnection]$Session=$Connection){
 $cmd=$Session.CreateCommand();$cmd.CommandTimeout=40;$cmd.CommandType='StoredProcedure';$cmd.CommandText=$Procedure
 [void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@PackageBytes'].Value=$Bytes
 foreach($p in @(@('Operation',$Operation,32),@('Bindings',$Bindings,-1),@('CatalogBindings',$Catalog,-1),@('TargetFlow',$Target,64),@('InspectStage',$Stage,64),@('ResultTable',$ResultTable,128),@('LookupPolicies',$Policies,-1),@('ComparisonCollation',$Collation,128))){
  $parameter=$cmd.Parameters.Add('@'+$p[0],[Data.SqlDbType]::NVarChar,[int]$p[2]);$parameter.Value=if($null -eq $p[1] -or [string]$p[1] -eq ''){[DBNull]::Value}else{$p[1]}
 }
 foreach($p in @(@('KeepData',$Keep),@('Hilfe',$Help))){[void]$cmd.Parameters.Add('@'+$p[0],[Data.SqlDbType]::Bit);$cmd.Parameters['@'+$p[0]].Value=[bool]$p[1]}
 [void]$cmd.Parameters.Add('@Debug',[Data.SqlDbType]::TinyInt);$cmd.Parameters['@Debug'].Value=$Debug
 try{$reader=$cmd.ExecuteReader();try{$table=[Data.DataTable]::new();if($reader.FieldCount -gt 0){$table.Load($reader);if(-not $reader.IsClosed -and $reader.FieldCount -gt 0){throw 'SSIS_NATIVE_EXTRA_RESULTSET'}}else{while($reader.NextResult()){if($reader.FieldCount -gt 0){throw 'SSIS_NATIVE_EXTRA_RESULTSET'}}};return ,$table}finally{$reader.Dispose()}}finally{$cmd.Dispose()}
}
function Reject([scriptblock]$Action,[string]$Code){
 $failed=$false;try{& $Action|Out-Null}catch{$leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException};if($leaf -isnot [Data.SqlClient.SqlException] -or $leaf.Number -ne 50000 -or $leaf.Message -notmatch ('TBX_SSISDBG_'+$Code)){throw 'SSIS_NATIVE_UNEXPECTED_ERROR'};$failed=$true};Check $failed 'EXPECTED_REJECTION'
}
[void](Sql @'
SET XACT_ABORT OFF;
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES(1,10,7),(1,10,9),(1,20,NULL),(2,10,2);
'@)
$database=[string](Sql 'SELECT DB_NAME() AS Name;').Rows[0].Name
$catalog=@{schemaVersion=1;defaultDatabase=$database;databases=@($database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database}}|ConvertTo-Json -Depth 4 -Compress
foreach($format in @(6,8)){
 $bytes=[IO.File]::ReadAllBytes((Join-Path $moduleRoot "Tests/Fixtures/synthetic-$format.dtsx"))
 $template=Explain -Bytes $bytes -Operation 'bindings-template'
 Check ($template.Rows.Count -eq 1 -and $template.Rows[0].ArtifactKind -eq 'BindingsTemplate') 'TEMPLATE'
 $bindings=[string]$template.Rows[0].Content
 $result=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -Stage 'all'
 Check ($result.Columns.Count -eq 13) 'RESULT_SHAPE'
 foreach($name in @('ArtifactKind','Ordinal','EvidenceClass','IsComplete','SafetyStatus','IsExecutable','Content')){Check (-not $result.Columns[$name].AllowDBNull) ('NON_NULL_'+$name)}
 $targets=@($result.Select("ArtifactKind='TargetSql'",'Ordinal'))
 Check ($targets.Count -eq 2 -and @($targets|Where-Object{-not $_.IsExecutable}).Count -eq 0) 'TARGETS_EXECUTABLE'
 $high=Sql ([string]$targets[0].Content);$low=Sql ([string]$targets[1].Content)
 Check ($high.Rows.Count -eq 2 -and $low.Rows.Count -eq 3) 'FIRST_TRUE_SPLIT'
 $highScore=@($high.Select('KeyA=1 AND KeyB=10'))[0].Score;$lowScore=@($low.Select('KeyA=1 AND KeyB=10'))[0].Score
 Check ($highScore -eq $lowScore -and $highScore -in @(7,9)) 'FROZEN_DUPLICATE_CHOICE'
 Check (@($low.Select('KeyA=1 AND KeyB=20'))[0].IsNull('Score')) 'COMPOSITE_KEY_NULL_PAYLOAD'
 [void](Sql 'BEGIN TRANSACTION;')
 try{[void](Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog);$state=Sql 'SELECT @@TRANCOUNT AS T,XACT_STATE() AS S;';Check ($state.Rows[0].T -eq 1 -and $state.Rows[0].S -eq 1) 'HEALTHY_CALLER_TRANSACTION';[void](Sql ([string]$targets[0].Content))}finally{[void](Sql 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;')}
 [void](Sql 'CREATE TABLE #SsisResult(Dummy bit NULL);')
 [void](Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -ResultTable '#SsisResult')
 $count=[int](Sql 'SELECT COUNT_BIG(*) AS N FROM #SsisResult WITH (NOLOCK);').Rows[0].N
 [void](Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -ResultTable '#SsisResult' -Keep $true)
 Check ([int](Sql 'SELECT COUNT_BIG(*) AS N FROM #SsisResult WITH (NOLOCK);').Rows[0].N -eq 2*$count) 'RESULT_TABLE_APPEND'
 Reject {Explain -Bytes $bytes -Bindings '{invalid' -Catalog $catalog -ResultTable '#SsisResult'} 'invalid_template'
 Check ([int](Sql 'SELECT COUNT_BIG(*) AS N FROM #SsisResult WITH (NOLOCK);').Rows[0].N -eq 2*$count) 'GLOBAL_ERROR_ATOMIC'
 [void](Sql 'DROP TABLE #SsisResult;')
 $help=Explain -Bytes ([byte[]]@(0)) -Bindings '{invalid' -ResultTable '#Missing' -Help $true
 Check ($help.Rows.Count -gt 0 -and $help.Columns.Count -eq 12) 'HELP_FIRST'
 $once=[Collections.Generic.HashSet[string]]::new()
 foreach($row in $result.Select("ArtifactKind='CleanupSql'")){if($once.Add([string]$row.Content)){[void](Sql ([string]$row.Content));[void](Sql ([string]$row.Content))}}
 if($Full){. (Join-Path $PSScriptRoot 'Invoke-V1Cases.ps1');if($format -eq 8){. (Join-Path $PSScriptRoot 'Invoke-ComponentCases.ps1')}}
}
[void](Sql 'DROP TABLE dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup;')
"SSIS_NATIVE_CORE_PASS $script:checks assertions; own synthetic database only"
