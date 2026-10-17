# Wird im Scope des Kernrunners je DTSX-Profil ausgeführt. Alle Änderungen
# betreffen ausschließlich seine synthetischen Tabellen und lokale Tempdaten.
function ChangedPackage([string]$SourceSql,[string]$LookupSql,[string]$LookupMapping){
 [xml]$doc=[Text.Encoding]::UTF8.GetString($bytes)
 foreach($c in $doc.SelectNodes('//*[local-name()="component"]')){
  if($c.name -eq 'SourceA' -and $SourceSql){$c.SelectSingleNode('properties/property[@name="SqlCommand"]').InnerText=$SourceSql}
  if($c.name -eq 'Lookup' -and $LookupSql){
   $c.SelectSingleNode('properties/property[@name="SqlCommand"]').InnerText=$LookupSql
   if($LookupMapping){$p=$doc.CreateElement('property');$p.SetAttribute('name','ParameterMapping');$p.InnerText=$LookupMapping;[void]$c.SelectSingleNode('properties').AppendChild($p)}
  }
 }
 return ,[Text.Encoding]::UTF8.GetBytes($doc.OuterXml)
}
function EditDeclare([string]$Text,[string]$Key,[int]$Value){
 $pattern='(?m)^DECLARE @'+[regex]::Escape($Key)+' int = [^;]+;'
 Check ([regex]::Matches($Text,$pattern).Count -eq 1) 'EDITABLE_DECLARE'
 [regex]::Replace($Text,$pattern,('DECLARE @'+$Key+' int = '+$Value+';'))
}
function CleanupArtifacts($Artifacts){$seen=[Collections.Generic.HashSet[string]]::new();foreach($a in $Artifacts.Select("ArtifactKind='CleanupSql'")){if($seen.Add([string]$a.Content)){[void](Sql ([string]$a.Content))}}}
function CacheState([string]$Text){
 $name=[regex]::Match($Text,'#tbx_SsisDebug_S_[A-Za-z0-9_]+').Value
 Check ([bool]$name) 'CACHE_STATE_FOUND'
 $row=(Sql ('SELECT OBJECT_ID(N''tempdb..'+$name+''') AS O,CONVERT(varchar(64),[Owner],2) AS W,CONVERT(varchar(64),[Fingerprint],2) AS F FROM ['+$name+'] WITH (NOLOCK);')).Rows[0]
 [pscustomobject]@{Name=$name;Id=$row.O;Owner=$row.W;Fingerprint=$row.F}
}
# Jede Stage muss ohne vorherige Vorbereitung in einer neuen Sitzung laufen.
foreach($a in $result.Select("ArtifactKind='StageSql' AND IsExecutable=true")){
 $fresh=([ICloneable]$Connection).Clone();$fresh.Open()
 try{$cmd=$fresh.CreateCommand();$cmd.CommandTimeout=40;$cmd.CommandText=[string]$a.Content;$reader=$cmd.ExecuteReader();$data=[Data.DataTable]::new();try{$data.Load($reader)}finally{$reader.Dispose()};Check ($data.Columns.Count -gt 0) 'STANDALONE_STAGE'}finally{$fresh.Dispose()}
}
# Der unveränderte Block verwendet dieselbe Auswahl auch bei geänderter
# Quelle. Eine irrelevante Split-Schwelle darf den Lookupcache nicht ersetzen.
[void](Sql ([string]$targets[0].Content));$before=CacheState ([string]$targets[0].Content)
$threshold=($bindings|ConvertFrom-Json).availableInputs|Where-Object name -eq 'User::Threshold'
$edited=EditDeclare ([string]$targets[0].Content) $threshold.key 1000
[void](Sql 'UPDATE dbo.SyntheticLookup SET Score=Score+100 WHERE Score IS NOT NULL;')
try{
 $empty=Sql $edited;Check ($empty.Rows.Count -eq 0) 'DIRECT_DECLARE_CHANGED_SPLIT'
 $after=CacheState $edited;Check ($before.Id -eq $after.Id -and $before.Fingerprint -ceq $after.Fingerprint) 'IRRELEVANT_DECLARE_REUSES_CACHE'
 $again=Sql ([string]$targets[0].Content);Check (@($again.Select('KeyA=1 AND KeyB=10'))[0].Score -in @(7,9)) 'REFERENCE_CHANGE_DOES_NOT_RESELECT'
}finally{[void](Sql 'UPDATE dbo.SyntheticLookup SET Score=Score-100 WHERE Score IS NOT NULL;');CleanupArtifacts $result}
# Relevante Referenzparameter werden dagegen in den Fingerprint aufgenommen.
$lookupId='{11111111-1111-1111-1111-000000000002}'
$parameterized=ChangedPackage -LookupSql 'SELECT KeyA,KeyB,Score FROM dbo.SyntheticLookup WHERE KeyA >= ?' -LookupMapping ('"@Floor:Input",'+$lookupId+';')
$pTemplate=Explain -Bytes $parameterized -Operation 'bindings-template';$pBindings=[string]$pTemplate.Rows[0].Content
$pResult=Explain -Bytes $parameterized -Bindings $pBindings -Catalog $catalog -Stage 'all'
$pTarget=[string]$pResult.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content
$floor=($pBindings|ConvertFrom-Json).availableInputs|Where-Object name -eq 'User::LookupFloor'
$changed=EditDeclare $pTarget $floor.key 2
[void](Sql $pTarget);$before=CacheState $pTarget
[void](Sql 'BEGIN TRANSACTION;')
try{Reject {Sql $changed} 'cache_context_changed';Check ((Sql 'SELECT XACT_STATE() AS S;').Rows[0].S -eq 1) 'CACHE_REJECT_PRESERVES_TRANSACTION'}finally{[void](Sql 'ROLLBACK TRANSACTION;')}
$changedRows=Sql $changed;$after=CacheState $changed
Check ($before.Fingerprint -cne $after.Fingerprint) 'RELEVANT_DECLARE_CHANGES_FINGERPRINT'
Check (@($changedRows.Select('KeyA=1'))[0].IsNull('Score')) 'RELEVANT_DECLARE_REBUILDS_CACHE'
[void](Sql ('UPDATE ['+$after.Name+'] SET [Owner]=0x'+('00'*32)+';'))
try{Reject {Sql $changed} 'cache_ownership'}finally{[void](Sql ('UPDATE ['+$after.Name+'] SET [Owner]=0x'+$after.Owner+';'))}
CleanupArtifacts $pResult
# Explizite fachliche Ordnung hat ein überprüfbares Ergebnis, auch bei Ties.
$policy=@{schemaVersion=1;lookups=@{'Package\Flow\Lookup'=@{orderBy=@(@{column='Score';direction='desc'})}}}|ConvertTo-Json -Depth 7 -Compress
$ordered=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -Policies $policy
$orderedRows=Sql ([string]$ordered.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content)
Check (@($orderedRows.Select('KeyA=1 AND KeyB=10'))[0].Score -eq 9) 'ORDERED_LOOKUP'
CleanupArtifacts $ordered
# Alle KeepData-Fälle, kompatibles Schema mit Index und blockierende
# ResultTable-Dependency vor Schema-/Datenmutation.
[void](Sql 'CREATE TABLE #V1Result(AnyDummy uniqueidentifier NULL);')
try{
 $none=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -ResultTable '#V1Result' -Keep $true
 Check ($none.Columns.Count -eq 0) 'RESULT_TABLE_HAS_NO_RESULTSET'
 $n=[int](Sql 'SELECT COUNT_BIG(*) AS N FROM #V1Result WITH(NOLOCK);').Rows[0].N
 [void](Sql 'CREATE INDEX IX_V1Ordinal ON #V1Result(Ordinal);')
 [void](Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -ResultTable '#V1Result' -Keep $false)
 Check ([int](Sql 'SELECT COUNT_BIG(*) AS N FROM #V1Result WITH(NOLOCK);').Rows[0].N -eq $n) 'KEEP_FALSE_REPLACES_COMPATIBLE'
 Check ([int](Sql "SELECT COUNT_BIG(*) AS N FROM tempdb.sys.indexes WITH(NOLOCK) WHERE object_id=OBJECT_ID(N'tempdb..#V1Result') AND name=N'IX_V1Ordinal';").Rows[0].N -eq 1) 'COMPATIBLE_INDEX_PRESERVED'
 [void](Sql 'BEGIN TRANSACTION;')
 try{[void](Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -ResultTable '#V1Result' -Keep $true);Check ([int](Sql 'SELECT @@TRANCOUNT AS T;').Rows[0].T -eq 1) 'RESULT_TABLE_CALLER_TRANSACTION'}finally{[void](Sql 'ROLLBACK TRANSACTION;')}
 Check ([int](Sql 'SELECT COUNT_BIG(*) AS N FROM #V1Result WITH(NOLOCK);').Rows[0].N -eq $n) 'CALLER_ROLLBACK_RESTORES_RESULT'
}finally{[void](Sql 'DROP TABLE #V1Result;')}
[void](Sql 'CREATE TABLE #V1Blocked(Dummy int CHECK(Dummy>0));INSERT #V1Blocked VALUES(1);')
try{
 $rejected=$false;try{[void](Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -ResultTable '#V1Blocked')}catch{$rejected=$true}
 Check ($rejected -and [int](Sql 'SELECT Dummy FROM #V1Blocked WITH(NOLOCK);').Rows[0].Dummy -eq 1) 'RESULT_DEPENDENCY_ATOMIC'
}finally{[void](Sql 'DROP TABLE #V1Blocked;')}
# Analyse bewahrt SET- und TX-Zustand; Debug darf keine Zusatzresultsets erzeugen.
$settings=[int](Sql 'SELECT @@OPTIONS AS O;').Rows[0].O
$debugRows=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -Debug 1
Check ($debugRows.Columns.Count -eq 13 -and [int](Sql 'SELECT @@OPTIONS AS O;').Rows[0].O -eq $settings) 'SET_PRESERVED_DEBUG'
# Quell-DML/DDL/EXEC/Remote/Synonym-/Funktionsgrenzen werden als lokale
# Diagnosen ausgewiesen; die Analyse führt keinen eingereichten SQL-Text aus.
foreach($bad in @('DELETE dbo.SyntheticSourceA;SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA WHERE Amount>=?',
 'SELECT KeyA,KeyB,Amount INTO dbo.SyntheticForbidden FROM dbo.SyntheticSourceA WHERE Amount>=?',
 'EXEC dbo.SyntheticForbidden;', 'SELECT KeyA,KeyB,Amount FROM [SyntheticRemote].master.dbo.SyntheticSourceA WHERE Amount>=?',
 'SELECT NEXT VALUE FOR dbo.SyntheticSequence AS KeyA,KeyB,Amount FROM dbo.SyntheticSourceA WHERE Amount>=?')){
 $badBytes=ChangedPackage -SourceSql $bad;$blocked=Explain -Bytes $badBytes -Catalog $catalog
 Check (@($blocked.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0 -and @($blocked.Select("ArtifactKind='Diagnostic'")).Count -gt 0) 'UNSAFE_SOURCE_BLOCKED'
}
Check ([int](Sql "SELECT COUNT_BIG(*) AS N FROM sys.objects WITH(NOLOCK) WHERE name=N'SyntheticForbidden';").Rows[0].N -eq 0 -and [int](Sql 'SELECT COUNT_BIG(*) AS N FROM dbo.SyntheticSourceA WITH(NOLOCK);').Rows[0].N -eq 3) 'ANALYSIS_DID_NOT_EXECUTE_SOURCE'
[void](Sql 'CREATE VIEW dbo.SyntheticView AS SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA;')
[void](Sql 'CREATE SYNONYM dbo.SyntheticSynonym FOR dbo.SyntheticView;')
try{
 $viewBytes=ChangedPackage -SourceSql 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSynonym WHERE Amount>=?'
 $viewResult=Explain -Bytes $viewBytes -Catalog $catalog
 Check (@($viewResult.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'VIEW_SYNONYM_BOUND'
 [void](Sql ([string]$viewResult.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content));CleanupArtifacts $viewResult
}finally{[void](Sql 'DROP SYNONYM dbo.SyntheticSynonym;DROP VIEW dbo.SyntheticView;')}
[void](Sql 'CREATE FUNCTION dbo.SyntheticInline() RETURNS TABLE AS RETURN (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA);')
try{
 $fnBytes=ChangedPackage -SourceSql 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticInline() WHERE Amount>=?'
 $fnResult=Explain -Bytes $fnBytes -Catalog $catalog
 Check (@($fnResult.Select("ArtifactKind='Diagnostic' AND DiagnosticCode='hint_not_supported'")).Count -gt 0 -and @($fnResult.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0) 'HIDDEN_FUNCTION_TABLE_READ_BLOCKED'
}finally{[void](Sql 'DROP FUNCTION dbo.SyntheticInline;')}
[void](Sql 'CREATE FUNCTION dbo.SyntheticPure() RETURNS TABLE AS RETURN (SELECT 1 AS KeyA,10 AS KeyB,100 AS Amount);')
try{
 $fnBytes=ChangedPackage -SourceSql 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticPure() WHERE Amount>=?'
 $fnResult=Explain -Bytes $fnBytes -Catalog $catalog
 Check (@($fnResult.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'PURE_INLINE_FUNCTION_BOUND'
 [void](Sql ([string]$fnResult.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content));CleanupArtifacts $fnResult
}finally{[void](Sql 'DROP FUNCTION dbo.SyntheticPure;')}
[void](Sql 'CREATE FUNCTION dbo.SyntheticRls(@key int) RETURNS TABLE WITH SCHEMABINDING AS RETURN SELECT 1 AS allowed WHERE @key>=0;')
[void](Sql 'CREATE SECURITY POLICY dbo.SyntheticPolicy ADD FILTER PREDICATE dbo.SyntheticRls(KeyA) ON dbo.SyntheticSourceA WITH(STATE=ON);')
try{
 $rls=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog
 Check (@($rls.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'PURE_RLS_DEPENDENCY_BOUND'
 [void](Sql ([string]$rls.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content));CleanupArtifacts $rls
}finally{[void](Sql 'DROP SECURITY POLICY dbo.SyntheticPolicy;DROP FUNCTION dbo.SyntheticRls;')}
[void](Sql 'CREATE SYNONYM dbo.SyntheticRemoteSynonym FOR SyntheticRemote.master.dbo.SyntheticSourceA;')
try{
 $remote=Explain -Bytes (ChangedPackage -SourceSql 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticRemoteSynonym WHERE Amount>=?') -Catalog $catalog
 Check (@($remote.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0) 'REMOTE_SYNONYM_BLOCKED'
}finally{[void](Sql 'DROP SYNONYM dbo.SyntheticRemoteSynonym;')}
# NOLOCK liest parallele unbestätigte DML, verhindert aber keine Sch-M-Sperre.
$sourceStage=[string]@($result.Select("ArtifactKind='StageSql'")|Where-Object ComponentId -eq 'Package\Flow\SourceA')[0].Content
$writer=([ICloneable]$Connection).Clone();$writer.Open()
try{
 $w=$writer.CreateCommand();$w.CommandText='BEGIN TRANSACTION;UPDATE dbo.SyntheticSourceA SET Amount=Amount+1000;';[void]$w.ExecuteNonQuery()
 $dirty=Sql $sourceStage;Check (@($dirty.Rows|Where-Object{$_.Amount -ge 1000}).Count -eq 3) 'NOLOCK_DIRTY_READ'
 $w.CommandText='ROLLBACK TRANSACTION;BEGIN TRANSACTION;ALTER TABLE dbo.SyntheticSourceA ADD SyntheticHeld int NULL;';[void]$w.ExecuteNonQuery()
 $waiting=$Connection.CreateCommand();$waiting.CommandTimeout=10;$waiting.CommandText=$sourceStage;$task=$waiting.ExecuteReaderAsync()
 Start-Sleep -Milliseconds 200;Check (-not $task.IsCompleted) 'NOLOCK_STILL_WAITING_FOR_SCHEMA'
 $w.CommandText='ROLLBACK TRANSACTION;';[void]$w.ExecuteNonQuery();$r=$task.GetAwaiter().GetResult();$r.Dispose();$waiting.Dispose()
}finally{try{$w.CommandText='IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;';[void]$w.ExecuteNonQuery()}finally{$writer.Dispose()}}
# Rechte ausschließlich für einen loginlosen synthetischen Principal in
# dieser eigenen Testdatenbank; keine Login-/Serverrechte oder Agentrechte.
[void](Sql 'CREATE USER SyntheticSsisReader WITHOUT LOGIN;GRANT EXECUTE ON OBJECT::toolbelt_tsql.USP_ExplainSsisDataFlow TO SyntheticSsisReader;GRANT VIEW DEFINITION TO SyntheticSsisReader;GRANT SELECT ON OBJECT::sys.sql_expression_dependencies TO SyntheticSsisReader;GRANT SELECT ON OBJECT::sys.security_predicates TO SyntheticSsisReader;')
try{
 [void](Sql "EXECUTE AS USER=N'SyntheticSsisReader';")
 try{
  Check ([int](Sql "SELECT HAS_PERMS_BY_NAME(N'dbo.SyntheticSourceA',N'OBJECT',N'SELECT') AS P;").Rows[0].P -eq 0) 'CALLER_HAS_NO_SOURCE_SELECT'
  Check ([int](Sql "SELECT HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT') AS P;").Rows[0].P -eq 1) 'CALLER_HAS_REQUIRED_CATALOG_SELECT'
  $limited=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog
  Check (@($limited.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'ANALYSIS_WITHOUT_SOURCE_SELECT'
 }finally{[void](Sql 'REVERT;')}
 [void](Sql 'REVOKE VIEW DEFINITION FROM SyntheticSsisReader;')
 [void](Sql "EXECUTE AS USER=N'SyntheticSsisReader';")
 try{
  $visibilityDenied=$false
  try{$hidden=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog;$visibilityDenied=@($hidden.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0}catch{$leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException};$visibilityDenied=$leaf -is [Data.SqlClient.SqlException] -and $leaf.Message -match 'TBX_SSISDBG_(catalog_visibility|unresolved_dependency)'}
  Check $visibilityDenied 'MISSING_METADATA_RIGHTS_BLOCKED'
 }finally{[void](Sql 'REVERT;')}
}finally{[void](Sql 'DROP USER SyntheticSsisReader;')}
if($CrossDatabase){
 $client=([ICloneable]$Connection).Clone();$client.Open();$client.ChangeDatabase($CrossDatabase)
 try{
  $crossCatalog=@{schemaVersion=1;defaultDatabase=$CrossDatabase;databases=@($CrossDatabase,$database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database}}|ConvertTo-Json -Depth 4 -Compress
  $cross=Explain -Bytes $bytes -Bindings $bindings -Catalog $crossCatalog -Session $client -Procedure ('['+$database+'].toolbelt_tsql.USP_ExplainSsisDataFlow')
  Check (@($cross.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'CROSS_DATABASE_CALLER_AND_COLLATION'
  $command=$client.CreateCommand();$command.CommandText=[string]$cross.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content;$reader=$command.ExecuteReader();$crossRows=[Data.DataTable]::new();try{$crossRows.Load($reader)}finally{$reader.Dispose()}
  Check ($crossRows.Rows.Count -eq 2) 'CROSS_DATABASE_GENERATED_SQL'
 }finally{$client.Dispose()}
}
# Bindungsmetadaten sind paketgebunden; optionale Informationsfelder werden
# dagegen neu bestimmt. Nur die im Vertrag benannten Identitätsfelder sperren.
$badTemplate=$bindings|ConvertFrom-Json;$badTemplate.availableInputs[0].sqlType='bigint'
Reject {Explain -Bytes $bytes -Bindings ($badTemplate|ConvertTo-Json -Depth 12 -Compress) -Catalog $catalog} 'invalid_template'
$badTemplate=$bindings|ConvertFrom-Json;$badTemplate.packageSha256='0'*64
Reject {Explain -Bytes $bytes -Bindings ($badTemplate|ConvertTo-Json -Depth 12 -Compress) -Catalog $catalog} 'invalid_template'
Reject {Explain -Bytes $bytes -Bindings '{"schemaVersion":1,"schemaVersion":1}' -Catalog $catalog} 'invalid_template'
Reject {Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -Stage 's9999'} 'unresolved_binding'
# Eine bereits doomed Callertransaktion bleibt Eigentum des Callers. Help
# bleibt vorher erreichbar, Fachanalyse lehnt vor jeder Ausgabe/Mutation ab.
$doom=$Connection.CreateCommand();$doom.CommandTimeout=40
$doom.CommandText=@'
SET NOCOUNT ON;
CREATE TABLE #V1Doomed(Id int CHECK(Id>0));
DECLARE @before int,@after int,@denied bit=0;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT #V1Doomed VALUES(-1);
END TRY
BEGIN CATCH
 SET @before=XACT_STATE();
 EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;
 BEGIN TRY
  EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@p,@Bindings=@b,@CatalogBindings=@c;
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()=50000 AND ERROR_MESSAGE() LIKE N'%TBX_SSISDBG_unresolved_binding:%' SET @denied=1;
  ELSE THROW;
 END CATCH;
 SET @after=XACT_STATE();
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;
DROP TABLE #V1Doomed;
SELECT @before AS BeforeState,@after AS AfterState,@denied AS Denied;
'@
[void]$doom.Parameters.Add('@p',[Data.SqlDbType]::VarBinary,-1);$doom.Parameters['@p'].Value=$bytes
[void]$doom.Parameters.Add('@b',[Data.SqlDbType]::NVarChar,-1);$doom.Parameters['@b'].Value=$bindings
[void]$doom.Parameters.Add('@c',[Data.SqlDbType]::NVarChar,-1);$doom.Parameters['@c'].Value=$catalog
try{
 $reader=$doom.ExecuteReader();try{$h=[Data.DataTable]::new();$h.Load($reader);Check ($h.Columns.Count -eq 12) 'HELP_IN_DOOMED_TRANSACTION';$flags=[Data.DataTable]::new();$flags.Load($reader);Check ($flags.Rows.Count -eq 1 -and $flags.Rows[0].BeforeState -eq -1 -and $flags.Rows[0].AfterState -eq -1 -and $flags.Rows[0].Denied) 'DOOMED_TRANSACTION_PRESERVED'}finally{$reader.Dispose()}
}finally{$doom.Dispose();[void](Sql "IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;SET XACT_ABORT OFF;IF OBJECT_ID(N'tempdb..#V1Doomed') IS NOT NULL DROP TABLE #V1Doomed;")}
