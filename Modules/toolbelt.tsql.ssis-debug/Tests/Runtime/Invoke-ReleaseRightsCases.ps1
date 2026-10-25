[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Nur im bereits journalisierten eigenen Lab-DB-Scope: keine Logins,
# CrossDB-Identitätsmappings oder Serverrechte. Feste Fachorakel, keine Retryschleife.
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:checks=0
function Check([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_RELEASE_RIGHTS_ASSERT_'+$Name)};$script:checks++}
function Sql([string]$Text){
 $c=$Connection.CreateCommand();$c.CommandText=$Text;$c.CommandTimeout=Get-SsisNativeTimeout 40
 try{$r=$c.ExecuteReader();try{$t=[Data.DataTable]::new();if($r.FieldCount -gt 0){$t.Load($r)};return ,$t}finally{$r.Dispose()}}finally{$c.Dispose()}
}
function New-ReleaseRightsCommand([string]$Operation,[byte[]]$Bytes=$package,[string]$Bindings,[string]$ResultTable,[bool]$Help=$false,[bool]$Keep=$true){
 $c=$Connection.CreateCommand();$c.CommandTimeout=Get-SsisNativeTimeout 40;$c.CommandType='StoredProcedure';$c.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'
 $selectedCatalog=$null;$selectedStage=$null;if($Operation -eq 'explain'){$selectedCatalog=$catalog;$selectedStage='all'}
 foreach($p in @(@('@Operation',[Data.SqlDbType]::NVarChar,32,$Operation),@('@PackageBytes',[Data.SqlDbType]::VarBinary,-1,$Bytes),@('@Bindings',[Data.SqlDbType]::NVarChar,-1,$Bindings),@('@CatalogBindings',[Data.SqlDbType]::NVarChar,-1,$selectedCatalog),@('@InspectStage',[Data.SqlDbType]::NVarChar,64,$selectedStage),@('@ResultTable',[Data.SqlDbType]::NVarChar,128,$ResultTable))){
  $v=$c.Parameters.Add($p[0],$p[1],$p[2]);$v.Value=$p[3]
  if($null -eq $p[3] -or ($p[3] -is [string] -and $p[3] -eq '')){$v.Value=[DBNull]::Value}
 }
 [void]$c.Parameters.Add('@Hilfe',[Data.SqlDbType]::Bit);$c.Parameters['@Hilfe'].Value=$Help
 [void]$c.Parameters.Add('@KeepData',[Data.SqlDbType]::Bit);$c.Parameters['@KeepData'].Value=$Keep
 return $c
}
function Call([string]$Operation,[byte[]]$Bytes=$package,[string]$Bindings,[string]$ResultTable,[bool]$Help=$false,[bool]$Keep=$true){
 $c=New-ReleaseRightsCommand @PSBoundParameters
 try{$r=$c.ExecuteReader();try{$t=[Data.DataTable]::new();if($r.FieldCount -gt 0){$t.Load($r)};return ,$t}finally{$r.Dispose()}}finally{$c.Dispose()}
}
function Denied([scriptblock]$Action,[int]$Number,[string]$Prefix){
 $rejected=$false
 try{& $Action | Out-Null}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -isnot [Data.SqlClient.SqlException] -or $e.Number -ne $Number -or ($Prefix -and $e.Message -notmatch ([regex]::Escape($Prefix)))){throw};$rejected=$true}
 Check $rejected 'STRICT_DENIAL'
}
$package=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
$catalog=@{schemaVersion=1;defaultDatabase=$Connection.Database;databases=@($Connection.Database);connections=@{'Package.ConnectionManagers[Synthetic]'=$Connection.Database}}|ConvertTo-Json -Compress -Depth 4
$principal=$false;$impersonated=$false
try{
 [void](Sql 'CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);INSERT dbo.SyntheticSourceA VALUES(1,10,100);')
 [void](Sql 'CREATE USER SyntheticSsisReleaseCaller WITHOUT LOGIN;');$principal=$true
 [void](Sql 'GRANT EXECUTE ON OBJECT::toolbelt_tsql.USP_ExplainSsisDataFlow TO SyntheticSsisReleaseCaller;')
 [void](Sql "EXECUTE AS USER=N'SyntheticSsisReleaseCaller';");$impersonated=$true
 Check ([int](Sql "SELECT IS_MEMBER(N'db_owner') AS N;").Rows[0].N -eq 0) 'NOT_DB_OWNER'
 Check ((Call -Operation 'explain' -Help $true).Rows.Count -gt 0) 'HELP_EXECUTE_ONLY'
 # Auch der Vorlagenpfad prüft die exakten Assembly-/ResultTable-Dependencies.
 # Ohne Metadatensicht darf er deren Unsichtbarkeit nicht als PASS behandeln.
 Denied {Call -Operation 'bindings-template'} 50000 'TBX_SSISDBG_unresolved_dependency'
 [void](Sql 'REVERT;');$impersonated=$false
 [void](Sql 'GRANT VIEW DEFINITION TO SyntheticSsisReleaseCaller;GRANT SELECT ON OBJECT::sys.sql_expression_dependencies TO SyntheticSsisReleaseCaller;GRANT SELECT ON OBJECT::sys.security_predicates TO SyntheticSsisReleaseCaller;')
 [void](Sql "EXECUTE AS USER=N'SyntheticSsisReleaseCaller';");$impersonated=$true
 try{
  $template=Call -Operation 'bindings-template'
  Check (@($template.Select("ArtifactKind='BindingsTemplate'")).Count -eq 1) 'TEMPLATE_WITH_METADATA'
  $bindings=[string]$template.Select("ArtifactKind='BindingsTemplate'")[0].Content
 }finally{[void](Sql 'REVERT;');$impersonated=$false}
 foreach($missing in @('none','execute','view','dependencies','predicates')){
  $deny=switch($missing){'execute' {'DENY EXECUTE ON OBJECT::toolbelt_tsql.USP_ExplainSsisDataFlow TO SyntheticSsisReleaseCaller;'} 'view' {'DENY VIEW DEFINITION TO SyntheticSsisReleaseCaller;'} 'dependencies' {'DENY SELECT ON OBJECT::sys.sql_expression_dependencies TO SyntheticSsisReleaseCaller;'} 'predicates' {'DENY SELECT ON OBJECT::sys.security_predicates TO SyntheticSsisReleaseCaller;'} default {''}}
  if($deny){[void](Sql $deny)}
  [void](Sql "EXECUTE AS USER=N'SyntheticSsisReleaseCaller';");$impersonated=$true
  try{
   Check ([int](Sql "SELECT HAS_PERMS_BY_NAME(N'dbo.SyntheticSourceA',N'OBJECT',N'SELECT') AS N;").Rows[0].N -eq 0) 'NO_SOURCE_SELECT'
   $witness=switch($missing){'execute' {"SELECT HAS_PERMS_BY_NAME(N'toolbelt_tsql.USP_ExplainSsisDataFlow',N'OBJECT',N'EXECUTE') AS N;"} 'view' {"SELECT HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION') AS N;"} 'dependencies' {"SELECT HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT') AS N;"} 'predicates' {"SELECT HAS_PERMS_BY_NAME(N'sys.security_predicates',N'OBJECT',N'SELECT') AS N;"} default {''}}
   if($witness){Check ([int](Sql $witness).Rows[0].N -eq 0) 'DENIED_RIGHT_WITNESS'}
   if($missing -eq 'none'){
    $result=Call -Operation 'explain' -Bindings $bindings
    Check (@($result.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'METADATA_ONLY_ANALYSIS'
    $stage=@($result.Select("ArtifactKind='StageSql' AND IsExecutable=true")|Where-Object ComponentId -eq 'Package\Flow\SourceA')
    # Die gemeinsame Quelle erscheint einmal je tatsächlichem Zielfluss.
    Check ($stage.Count -eq 2) 'SOURCE_STAGE_PER_TARGET_WITNESS'
    foreach($sourceStage in $stage){Denied {Sql ([string]$sourceStage.Content)} 229 ''}
   }elseif($missing -eq 'execute'){Denied {Call -Operation 'explain' -Help $true} 229 ''}
   elseif($missing -eq 'view'){Denied {Call -Operation 'explain' -Bindings $bindings} 50000 'TBX_SSISDBG_unresolved_dependency'}
   else{Denied {Call -Operation 'explain' -Bindings $bindings} 50000 'TBX_SSISDBG_catalog_visibility'}
  }finally{[void](Sql 'REVERT;');$impersonated=$false}
  $restore=switch($missing){'execute' {'GRANT EXECUTE ON OBJECT::toolbelt_tsql.USP_ExplainSsisDataFlow TO SyntheticSsisReleaseCaller;'} 'view' {'GRANT VIEW DEFINITION TO SyntheticSsisReleaseCaller;'} 'dependencies' {'GRANT SELECT ON OBJECT::sys.sql_expression_dependencies TO SyntheticSsisReleaseCaller;'} 'predicates' {'GRANT SELECT ON OBJECT::sys.security_predicates TO SyntheticSsisReleaseCaller;'} default {''}}
  if($restore){[void](Sql $restore)}
 }
 # Öffentlicher Größenfehler muss eine bereits befüllte ResultTable erhalten.
 [void](Sql 'CREATE TABLE #SsisReleaseRows(Dummy bit NULL);')
 [void](Call -Operation 'bindings-template' -ResultTable '#SsisReleaseRows' -Keep $false)
 $before=[long](Sql 'SELECT COUNT_BIG(*) AS N FROM #SsisReleaseRows WITH(NOLOCK);').Rows[0].N
 Check ($before -gt 0) 'RESULT_TABLE_SEEDED'
 Denied {Call -Operation 'bindings-template' -Bytes ([byte[]]::new(16777217)) -ResultTable '#SsisReleaseRows'} 50000 'TBX_SSISDBG_resource_limit'
 Check ([long](Sql 'SELECT COUNT_BIG(*) AS N FROM #SsisReleaseRows WITH(NOLOCK);').Rows[0].N -eq $before) 'RESOURCE_OUTPUT_ATOMIC'
 [void](Sql 'DROP TABLE #SsisReleaseRows;')
}finally{
 if($impersonated){[void](Sql 'REVERT;')}
 if($principal){[void](Sql 'DROP USER SyntheticSsisReleaseCaller;')}
 [void](Sql 'DROP TABLE IF EXISTS dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup;')
}
"SSIS_RELEASE_RIGHTS_PASS $script:checks assertions"
