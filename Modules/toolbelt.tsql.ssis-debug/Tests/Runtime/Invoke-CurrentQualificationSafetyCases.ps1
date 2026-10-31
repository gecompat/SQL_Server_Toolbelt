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
  $b=[Text.Encoding]::UTF8.GetBytes((Get-CurrentSafetyDocument $format).OuterXml)
  $artifacts=Invoke-V2Explain -Bytes $b -Operation 'explain' -Catalog $catalog
  $targets=@($artifacts.Select("ArtifactKind='TargetSql'",'Ordinal'))
  Assert-V2 ($targets.Count -eq 2 -and @($targets|Where-Object {-not $_.IsExecutable}).Count -eq 0) 'FORMAT6_8_COMPLETE_TARGETS'
  $high=Read-CurrentTarget $artifacts $targets[0];$low=Read-CurrentTarget $artifacts $targets[1]
  Assert-V2 ($high.Rows.Count -eq 2 -and $low.Rows.Count -eq 3) 'UNION_DERIVED_LOOKUP_FIRST_TRUE_SPLIT'
  Assert-V2 (@($low.Select('KeyA=1 AND KeyB=20'))[0].IsNull('Score')) 'COMPOSITE_LOOKUP_NULL_PAYLOAD'
  foreach($row in $high.Rows){Assert-V2 ($row.Score -in @(2,7,9)) 'LOOKUP_EFFECTIVE_KEY_ORACLE'}
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
 if($CrossDatabase){
  $original=$Connection.Database
  $crossBytes=[Text.Encoding]::UTF8.GetBytes((Get-CurrentSafetyDocument).OuterXml)
  $artifacts=Invoke-V2Explain -Bytes $crossBytes -Operation 'explain' -Catalog $catalog
  $target=@($artifacts.Select("ArtifactKind='TargetSql' AND IsExecutable=true"))[0]
  $parts=Get-V2PlanParts $artifacts $target
  $Connection.ChangeDatabase($CrossDatabase)
  try{
   $cross=Invoke-V2Explain -Bytes $crossBytes -Operation 'explain' -Catalog $catalog -Procedure ('['+$original.Replace(']',']]')+'].toolbelt_tsql.USP_ExplainSsisDataFlow')
   Assert-V2 (@($cross.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'THREE_PART_CALL_FROM_CONSUMER'
   Invoke-V2Units $parts
   Assert-V2 ((Invoke-V2Sql ([string]$target.Content)).Rows.Count -eq 2) 'GENERATED_PLAN_FROM_CONSUMER_DATABASE'
  }finally{Clear-V2Plan $parts;$Connection.ChangeDatabase($original)}
 }
}finally{[void](Invoke-V2Sql 'DROP TABLE dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup;')}
