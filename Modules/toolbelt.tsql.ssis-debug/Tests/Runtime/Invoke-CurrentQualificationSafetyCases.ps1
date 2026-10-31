# Feste End-to-End-, Katalog- und Safetyfälle unter dem aktuellen Default.
# Die Analyse darf eingereichten Quelltext niemals ausführen.
[void](Invoke-V2Sql @'
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES(1,10,7),(1,10,9),(1,20,NULL),(2,10,2);
'@)
$database=$Connection.Database
$catalog=(@{schemaVersion=2;defaultDatabase=$database;databases=@($database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database};flatFileInputs=@{}}|ConvertTo-Json -Depth 4 -Compress)
function Get-CurrentSafetyDocument([int]$Format=8){
 [xml]$doc=[IO.File]::ReadAllText((Join-Path $moduleRoot ('Tests/Fixtures/synthetic-'+$Format+'.dtsx')))
 # Die alten Minimalfixtures enthielten keine synchronen Portreferenzen.
 # Für den vollständigen heutigen Portvertrag werden diese ausdrücklich
 # synthetisch ergänzt; die vorhandene explizite Komponentenversion bleibt.
 foreach($c in $doc.SelectNodes('//component[@name="Derived" or @name="Split"]')){
  $input=$c.SelectSingleNode('inputs/input').GetAttribute('refId')
  foreach($port in $c.SelectNodes('outputs/output')){$port.SetAttribute('synchronousInputId',$input)}
 }
 return ,$doc
}
function New-CurrentSafetyPackage([string]$Query){
 [xml]$doc=Get-CurrentSafetyDocument
 $node=$doc.SelectSingleNode('//component[@name="SourceA"]/properties/property[@name="SqlCommand"]')
 if(-not $node){throw 'SSIS_CURRENT_SAFETY_FIXTURE_STRUCTURE'}
 $node.InnerText=$Query
 return ,[Text.Encoding]::UTF8.GetBytes($doc.OuterXml)
}
function Read-CurrentTarget($Artifacts,$Target){
 $parts=Get-V2PlanParts $Artifacts $Target
 Invoke-V2Units $parts
 try{return ,(Invoke-V2Sql ([string]$Target.Content))}finally{Clear-V2Plan $parts}
}
try{
 foreach($format in @(6,8)){
  Write-Output ('SSIS_CURRENT_SAFETY_FORMAT '+$format)
  $b=[Text.Encoding]::UTF8.GetBytes((Get-CurrentSafetyDocument $format).OuterXml)
  $artifacts=Invoke-V2Explain -Bytes $b -Operation 'explain' -Catalog $catalog
  $targets=@($artifacts.Select("ArtifactKind='TargetSql'",'Ordinal'))
  Assert-V2 ($targets.Count -eq 2 -and @($targets|Where-Object {-not $_.IsExecutable}).Count -eq 0) 'FORMAT6_8_COMPLETE_TARGETS'
  $high=Read-CurrentTarget $artifacts $targets[0];$low=Read-CurrentTarget $artifacts $targets[1]
  Assert-V2 ($high.Rows.Count -eq 2 -and $low.Rows.Count -eq 3) 'UNION_DERIVED_LOOKUP_FIRST_TRUE_SPLIT'
  Assert-V2 (@($low.Select('KeyA=1 AND KeyB=20'))[0].IsNull('Score')) 'COMPOSITE_LOOKUP_NULL_PAYLOAD'
  foreach($row in $high.Rows){Assert-V2 ($row.Score -in @(2,7,9)) 'LOOKUP_EFFECTIVE_KEY_ORACLE'}
 }
 foreach($name in @('@MaxSqlArtifactBytes','@MaxPlanUnits','@MaxCatalogObjects','@MaxCatalogQueries','@MaxParserCalls','@MaxArtifacts','@MaxExpressionBytes','@MaxExpressionTokens','@MaxExpressionNodes')){
  $limits=@{};$limits[$name]=1
  Reject-V2 {Invoke-V2Explain -Bytes $b -Operation 'explain' -Catalog $catalog -Limits $limits} 'resource_limit'
 }
 foreach($query in @('DELETE dbo.SyntheticSourceA;SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA WHERE Amount>=?',
 'SELECT KeyA,KeyB,Amount INTO dbo.SyntheticForbidden FROM dbo.SyntheticSourceA WHERE Amount>=?',
 'EXEC dbo.SyntheticForbidden;',
 'SELECT KeyA,KeyB,Amount FROM [SyntheticRemote].master.dbo.SyntheticSourceA WHERE Amount>=?',
 'SELECT NEXT VALUE FOR dbo.SyntheticSequence AS KeyA,KeyB,Amount FROM dbo.SyntheticSourceA WHERE Amount>=?')){
  $blocked=Invoke-V2Explain -Bytes (New-CurrentSafetyPackage $query) -Operation 'explain' -Catalog $catalog
  Assert-V2 (@($blocked.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0 -and @($blocked.Select("ArtifactKind='Diagnostic'")).Count -gt 0) 'PERSISTENT_EXEC_REMOTE_SEQUENCE_BLOCKED'
 }
 Assert-V2 ((Invoke-V2Sql "SELECT COUNT_BIG(*) AS N FROM sys.objects WHERE name=N'SyntheticForbidden';").Rows[0].N -eq 0 -and (Invoke-V2Sql 'SELECT COUNT_BIG(*) AS N FROM dbo.SyntheticSourceA;').Rows[0].N -eq 3) 'ANALYSIS_NEVER_EXECUTES_SOURCE'
 Write-Output 'SSIS_CURRENT_SAFETY_CATALOG'
 [void](Invoke-V2Sql 'CREATE VIEW dbo.SyntheticView AS SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA;')
 [void](Invoke-V2Sql 'CREATE SYNONYM dbo.SyntheticSynonym FOR dbo.SyntheticView;')
 try{
  $views=Invoke-V2Explain -Bytes (New-CurrentSafetyPackage 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSynonym WHERE Amount>=?') -Operation 'explain' -Catalog $catalog
  $t=@($views.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))
  Assert-V2 ($t.Count -eq 2) 'VIEW_LOCAL_SYNONYM_BOUND'
  Assert-V2 ((Read-CurrentTarget $views $t[0]).Rows.Count -eq 2) 'VIEW_LOCAL_SYNONYM_EXECUTED'
 }finally{[void](Invoke-V2Sql 'DROP SYNONYM dbo.SyntheticSynonym;DROP VIEW dbo.SyntheticView;')}
 [void](Invoke-V2Sql 'CREATE FUNCTION dbo.SyntheticInline() RETURNS TABLE AS RETURN (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA);')
 try{
  $hidden=Invoke-V2Explain -Bytes (New-CurrentSafetyPackage 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticInline() WHERE Amount>=?') -Operation 'explain' -Catalog $catalog
  Assert-V2 (@($hidden.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0 -and @($hidden.Select("ArtifactKind='Diagnostic' AND DiagnosticCode='hint_not_supported'")).Count -gt 0) 'HIDDEN_FUNCTION_READ_BLOCKED'
 }finally{[void](Invoke-V2Sql 'DROP FUNCTION dbo.SyntheticInline;')}
 [void](Invoke-V2Sql 'CREATE SYNONYM dbo.SyntheticRemoteSynonym FOR SyntheticRemote.master.dbo.SyntheticSourceA;')
 try{
  $remote=Invoke-V2Explain -Bytes (New-CurrentSafetyPackage 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticRemoteSynonym WHERE Amount>=?') -Operation 'explain' -Catalog $catalog
  Assert-V2 (@($remote.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0) 'REMOTE_SYNONYM_BLOCKED'
 }finally{[void](Invoke-V2Sql 'DROP SYNONYM dbo.SyntheticRemoteSynonym;')}
 $safeBytes=[Text.Encoding]::UTF8.GetBytes((Get-CurrentSafetyDocument).OuterXml)
 [void](Invoke-V2Sql 'CREATE FUNCTION dbo.SyntheticPure() RETURNS TABLE AS RETURN (SELECT 1 AS KeyA,10 AS KeyB,100 AS Amount);')
 try{
  $pure=Invoke-V2Explain -Bytes (New-CurrentSafetyPackage 'SELECT KeyA,KeyB,Amount FROM dbo.SyntheticPure() WHERE Amount>=?') -Operation 'explain' -Catalog $catalog
  $t=@($pure.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))
  Assert-V2 ($t.Count -eq 2 -and (Read-CurrentTarget $pure $t[0]).Rows.Count -eq 1) 'PURE_FUNCTION_EXECUTED'
 }finally{[void](Invoke-V2Sql 'DROP FUNCTION dbo.SyntheticPure;')}
 [void](Invoke-V2Sql 'CREATE FUNCTION dbo.SyntheticRls(@key int) RETURNS TABLE WITH SCHEMABINDING AS RETURN SELECT 1 AS allowed WHERE @key>=0;')
 [void](Invoke-V2Sql 'CREATE SECURITY POLICY dbo.SyntheticPolicy ADD FILTER PREDICATE dbo.SyntheticRls(KeyA) ON dbo.SyntheticSourceA WITH(STATE=ON);')
 try{
  $rls=Invoke-V2Explain -Bytes $safeBytes -Operation 'explain' -Catalog $catalog
  $t=@($rls.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))
  Assert-V2 ($t.Count -eq 2 -and (Read-CurrentTarget $rls $t[0]).Rows.Count -eq 2) 'PURE_RLS_BOUND_AND_EXECUTED'
 }finally{[void](Invoke-V2Sql 'DROP SECURITY POLICY dbo.SyntheticPolicy;DROP FUNCTION dbo.SyntheticRls;')}
 [void](Invoke-V2Sql 'ALTER TABLE dbo.SyntheticSourceA ADD SyntheticComputed AS (Amount*2);')
 try{
  $computed=Invoke-V2Explain -Bytes (New-CurrentSafetyPackage 'SELECT KeyA,KeyB,SyntheticComputed AS Amount FROM dbo.SyntheticSourceA WHERE Amount>=?') -Operation 'explain' -Catalog $catalog
  $t=@($computed.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))
  Assert-V2 ($t.Count -eq 2 -and (Read-CurrentTarget $computed $t[0]).Rows.Count -eq 2) 'COMPUTED_COLUMN_BOUND_AND_EXECUTED'
 }finally{[void](Invoke-V2Sql 'ALTER TABLE dbo.SyntheticSourceA DROP COLUMN SyntheticComputed;')}
 Write-Output 'SSIS_CURRENT_SAFETY_NOLOCK'
 $dirty=Invoke-V2Explain -Bytes $safeBytes -Operation 'explain' -Catalog $catalog
 $dirtyTarget=@($dirty.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))[0]
 $writer=([ICloneable]$Connection).Clone();$writer.Open()
 try{
  $write=$writer.CreateCommand();$write.CommandTimeout=Get-SsisNativeTimeout 15
  try{$write.CommandText='BEGIN TRANSACTION;UPDATE dbo.SyntheticSourceA SET Amount=Amount+1000;';[void]$write.ExecuteNonQuery()
   $rows=Read-CurrentTarget $dirty $dirtyTarget
   Assert-V2 ($rows.Rows.Count -eq 3 -and @($rows.Rows|Where-Object {$_.Adjusted -ge 1000}).Count -eq 3) 'NOLOCK_DIRTY_SOURCE_READ'
  }finally{$write.CommandText='IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;';[void]$write.ExecuteNonQuery();$write.Dispose()}
 }finally{$writer.Dispose()}
 if($CrossDatabase){
  Write-Output 'SSIS_CURRENT_SAFETY_CROSS_DATABASE'
  $original=$Connection.Database
  $crossBytes=[Text.Encoding]::UTF8.GetBytes((Get-CurrentSafetyDocument).OuterXml)
  $artifacts=Invoke-V2Explain -Bytes $crossBytes -Operation 'explain' -Catalog $catalog
  $target=@($artifacts.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))[0]
  $parts=Get-V2PlanParts $artifacts $target
  $Connection.ChangeDatabase($CrossDatabase)
  try{
   # Ein im Modulkontext gebundener Plan darf im Consumerkontext nicht laufen.
   # Für den positiven dreiteiligen Aufruf ist der Caller ausdrücklich der
   # Defaultkontext; die Connectionzuordnung bleibt die eigene Quelldatenbank.
   Reject-V2 {Invoke-V2Units $parts} 'cache_context_changed'
   $crossCatalog=@{schemaVersion=2;defaultDatabase=$CrossDatabase;databases=@($CrossDatabase,$original);connections=@{'Package.ConnectionManagers[Synthetic]'=$original};flatFileInputs=@{}}|ConvertTo-Json -Depth 4 -Compress
   $cross=Invoke-V2Explain -Bytes $crossBytes -Operation 'explain' -Catalog $crossCatalog -Procedure ('['+$original.Replace(']',']]')+'].toolbelt_tsql.USP_ExplainSsisDataFlow')
   Assert-V2 (@($cross.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'THREE_PART_CALL_FROM_CONSUMER'
   $target=@($cross.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))[0]
   $parts=Get-V2PlanParts $cross $target
   Invoke-V2Units $parts
   Assert-V2 ((Invoke-V2Sql ([string]$target.Content)).Rows.Count -eq 2) 'GENERATED_PLAN_FROM_CONSUMER_DATABASE'
  }finally{try{Clear-V2Plan $parts}finally{$Connection.ChangeDatabase($original)}}
 }
}finally{
 $Connection.ChangeDatabase($database)
 [void](Invoke-V2Sql 'DROP TABLE IF EXISTS dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup;')
}
