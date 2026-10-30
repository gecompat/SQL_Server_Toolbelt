[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
      [Parameter(Mandatory)][string]$FixtureModuleRoot,
      [Parameter(Mandatory)][System.Collections.IDictionary]$OwnershipJournal)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'CurrentSnapshotHelpers.ps1')
$checks=0
function Assert-Snapshot([bool]$Value,[string]$Code){if(-not $Value){throw ('SSIS_CURRENT_SNAPSHOT_ASSERT_'+$Code)};$script:checks++}
function Invoke-SnapshotSql([string]$Text,[int]$ExpectedResultSets=1){
 $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=Get-SsisNativeTimeout 45;$cmd.CommandText=$Text
 try{$reader=$cmd.ExecuteReader();try{$tables=Read-SnapshotReaderResultSets $reader $ExpectedResultSets}finally{$reader.Dispose()};if($ExpectedResultSets -eq 0){return ,([Data.DataTable]::new())};return ,$tables[0]}finally{$cmd.Dispose()}
}
function Invoke-SnapshotExplain([byte[]]$Bytes,[string]$Operation='explain',[string]$Bindings,[string]$Catalog){
 $cmd=$Connection.CreateCommand();$cmd.CommandType='StoredProcedure';$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow';$cmd.CommandTimeout=Get-SsisNativeTimeout 45
 [void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@PackageBytes'].Value=$Bytes
 [void]$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32);$cmd.Parameters['@Operation'].Value=$Operation
 foreach($p in @(@('Bindings',$Bindings,-1),@('CatalogBindings',$Catalog,-1),@('ProjectContext',$null,-1),@('ResultTable',$null,128))){
  [void]$cmd.Parameters.Add('@'+$p[0],[Data.SqlDbType]::NVarChar,[int]$p[2]);$cmd.Parameters['@'+$p[0]].Value=if([string]::IsNullOrEmpty([string]$p[1])){[DBNull]::Value}else{[string]$p[1]}
 }
 foreach($p in @(@('KeepData',$false),@('Debug',$false),@('Hilfe',$false))){[void]$cmd.Parameters.Add('@'+$p[0],[Data.SqlDbType]::Bit);$cmd.Parameters['@'+$p[0]].Value=[bool]$p[1]}
 try{
  $reader=$cmd.ExecuteReader()
  try{$tables=Read-SnapshotReaderResultSets $reader 1}finally{$reader.Dispose()}
  return ,$tables[0]
 }finally{$cmd.Dispose()}
}
function Get-SnapshotRows([Data.DataTable]$Table){
 $names=@($Table.Columns|ForEach-Object ColumnName)
 foreach($row in $Table.Rows){
  $parts=[Collections.Generic.List[string]]::new()
  foreach($name in $names){$value=$row[$name];if($value -is [DBNull]){$parts.Add('<NULL>')}else{$parts.Add([Convert]::ToString($value,[Globalization.CultureInfo]::InvariantCulture))}}
  ($parts -join [char]31)
 }
}
function Assert-SnapshotDebugScript($Artifacts,$Bundle,[switch]$InsertAfterPlan){
 Assert-Snapshot ($Bundle.IsComplete -and $Bundle.IsExecutable -and $Bundle.SafetyStatus -ceq 'passed') 'DEBUGSCRIPT_VALIDATED'
 $details=([string]$Bundle.DetailsJson)|ConvertFrom-Json -Depth 32;$batches=@($details.batches)
 Assert-Snapshot ($batches.Count -gt 2 -and $details.batchSeparator -ceq 'GO') 'BATCH_DIRECTORY'
 $layout=Get-SnapshotBatchLayout ([string[]]@($batches|ForEach-Object {[string]$_.artifactKind}))
 $selected=@();$pieces=[Collections.Generic.List[string]]::new();$sequence=1;$inserted=$false;$result=@{};$seenOrdinals=[Collections.Generic.HashSet[int]]::new()
 foreach($batch in $batches){
  Assert-Snapshot (Test-SnapshotInteger $batch.resultOrdinal) 'BATCH_ORDINAL_TYPE'
  Assert-Snapshot (Test-SnapshotInteger $batch.sequence) 'BATCH_SEQUENCE_TYPE'
  $ordinal=[int]$batch.resultOrdinal
  if(-not $seenOrdinals.Add($ordinal)){throw 'SSIS_CURRENT_SNAPSHOT_DUPLICATE_ORDINAL'}
  $rows=@($Artifacts.Rows|Where-Object Ordinal -EQ $ordinal)
  Assert-Snapshot ($rows.Count -eq 1 -and [long]$batch.sequence -eq $sequence) 'BATCH_IDENTITY'
  $row=$rows[0];$content=[string]$row.Content
  Assert-Snapshot ([string]$row.TargetFlowId -ceq [string]$Bundle.TargetFlowId) 'BATCH_TARGET_FLOW_IDENTITY'
  $sha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($content)))
  Assert-Snapshot (Test-SnapshotBatchBinding $row.Ordinal $ordinal ([string]$row.ArtifactKind) ([string]$batch.artifactKind) $sha ([string]$batch.contentSha256) ([bool]$row.IsExecutable) ([string]$row.SafetyStatus)) 'BATCH_HASH_SAFETY'
  if($row.ArtifactKind -in @('RowCountSql','TargetSql') -and [string]$row.TargetFlowId -cne [string]$Bundle.TargetFlowId){throw 'SSIS_CURRENT_SNAPSHOT_READ_TARGET_FLOW_MISMATCH'}
  $pieces.Add($content.TrimEnd());$selected+=,$row;$sequence++
 }
 $planCount=[int]$layout.PlanUnitCount
 Assert-Snapshot ($layout.PreparationCount -gt 0 -and $planCount -gt 0 -and $layout.CleanupCount -gt 0) 'COMPLETE_PREPARATION_PLAN_CLEANUP'
 $expected=($pieces -join "`nGO`n")+"`n"
 $prefix="-- Neue SQL-Sitzung verwenden. Bei einem Vorbereitungsfehler keine Ergebnislesebatches verwenden; CleanupSql anschließend in derselben Sitzung ausführen.`n-- Keine SSIS-Tasks werden ausgeführt.`n"
 Assert-Snapshot ([string]$Bundle.Content -ceq ($prefix+$expected)) 'DEBUGSCRIPT_EXACT_ORDERED_CONTENT'
 $executedPlanCount=0
 try{
  foreach($row in $selected){
   if($row.ArtifactKind -ceq 'CleanupSql'){continue}
   if($row.ArtifactKind -in @('PreparationSql','PlanUnitSql')){$table=Invoke-SnapshotSql ([string]$row.Content) 0;if($row.ArtifactKind -ceq 'PlanUnitSql'){$executedPlanCount++};continue}
   if($row.ArtifactKind -in @('RowCountSql','TargetSql')){
    if($InsertAfterPlan -and -not $inserted){
     Assert-Snapshot ($executedPlanCount -eq $planCount -and $planCount -gt 0) 'MATERIALIZATION_BEFORE_READ'
    $insert=Invoke-SnapshotSql 'INSERT dbo.SyntheticSourceA(KeyA,KeyB,Amount) OUTPUT INSERTED.KeyA AS KeyA,INSERTED.KeyB AS KeyB,INSERTED.Amount AS Amount VALUES(2,10,201);' 1
     Assert-Snapshot ($insert.Rows.Count -eq 1 -and [int]$insert.Rows[0].KeyA -eq 2 -and [int]$insert.Rows[0].KeyB -eq 10 -and [int]$insert.Rows[0].Amount -eq 201) 'SINGLE_POST_PLAN_MUTATION'
     $OwnershipJournal['snapshotMutationApplied']=$true
    $live=Invoke-SnapshotSql 'SELECT COUNT_BIG(*) AS CandidateRows FROM dbo.SyntheticSourceA WHERE Amount+1>100;' 1
     Assert-Snapshot ($live.Rows.Count -eq 1 -and [long]$live.Rows[0].CandidateRows -eq 3) 'LIVE_SOURCE_CANDIDATE_CONTROL'
     $inserted=$true
    }
    $expectedSets=if($row.ArtifactKind -in @('TargetSql','RowCountSql')){1}else{0}
    $table=Invoke-SnapshotSql ([string]$row.Content) $expectedSets
    if($result.ContainsKey([string]$row.ArtifactKind)){throw 'SSIS_CURRENT_SNAPSHOT_DUPLICATE_READ'}
    $result[[string]$row.ArtifactKind]=$table;continue
   }
  }
 }finally{
  try{foreach($row in $selected){if($row.ArtifactKind -ceq 'CleanupSql'){[void](Invoke-SnapshotSql ([string]$row.Content) 0)}}}
  catch{$OwnershipJournal['snapshotCleanupBlocked']=$true;throw}
 }
 Assert-Snapshot ($result.ContainsKey('RowCountSql') -and $result.ContainsKey('TargetSql')) 'COMPLETE_PLAN_READS'
 if($InsertAfterPlan){Assert-Snapshot $inserted 'MUTATION_HOOK_REACHED'}
 return $result
}
if($Connection.State -cne 'Open'){throw 'SSIS_CURRENT_SNAPSHOT_CONNECTION_REQUIRED'}
 $compatibility=[int](Invoke-SnapshotSql 'SELECT compatibility_level AS C FROM sys.databases WITH (NOLOCK) WHERE database_id=DB_ID();').Rows[0].C
 Assert-Snapshot ($compatibility -eq 170) 'FIXED_DATABASE_COMPATIBILITY'
$module=[IO.Path]::GetFullPath($FixtureModuleRoot)
$fixture=[IO.File]::ReadAllBytes((Join-Path $module 'Tests/Fixtures/components-v2-rowcount.dtsx'))
$absence=Invoke-SnapshotSql "SELECT COUNT_BIG(*) AS N FROM sys.tables WITH (NOLOCK) WHERE schema_id=SCHEMA_ID(N'dbo') AND name IN(N'SyntheticSourceA',N'SyntheticSourceB',N'SyntheticLookup');"
Assert-Snapshot ($absence.Rows.Count -eq 1 -and [long]$absence.Rows[0].N -eq 0) 'FIXTURE_COLLISION_BLOCK'
$fixtureIds=@{};$fixturesCreated=$false
$OwnershipJournal['snapshotCleanupBlocked']=$true
[void](Invoke-SnapshotSql @'
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES(1,10,7),(1,20,NULL),(2,10,2);
'@ 0)
$created=Invoke-SnapshotSql "SELECT name,object_id FROM sys.tables WITH (NOLOCK) WHERE schema_id=SCHEMA_ID(N'dbo') AND name IN(N'SyntheticSourceA',N'SyntheticSourceB',N'SyntheticLookup');"
Assert-Snapshot ($created.Rows.Count -eq 3) 'FIXTURE_CREATE_SHAPE'
foreach($row in $created.Rows){if([int]$row.object_id -le 0){throw 'SSIS_CURRENT_SNAPSHOT_FIXTURE_ID_INVALID'};$fixtureIds[[string]$row.name]=[int]$row.object_id}
$fixturesCreated=$true
$OwnershipJournal.Remove('snapshotCleanupBlocked')
$OwnershipJournal['snapshotMutationApplied']=$false
try{
 $database=[string](Invoke-SnapshotSql 'SELECT DB_NAME() AS N;').Rows[0].N
 $catalog=@{schemaVersion=2;defaultDatabase=$database;databases=@($database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database}}
 $catalogJson=$catalog|ConvertTo-Json -Depth 12 -Compress
 $template=Invoke-SnapshotExplain -Bytes $fixture -Operation 'bindings-template'
 Assert-Snapshot ($template.Columns.Count -eq 13 -and $template.Rows.Count -eq 1 -and $template.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'CURRENT_TEMPLATE'
 $bindings=[string]$template.Rows[0].Content
 $first=Invoke-SnapshotExplain -Bytes $fixture -Bindings $bindings -Catalog $catalogJson
 $count=@($first.Rows|Where-Object ArtifactKind -CEQ 'RowCountSql')
 Assert-Snapshot ($count.Count -eq 1) 'ROWCOUNT_ARTIFACT'
 $bundle=@($first.Rows|Where-Object {$_.ArtifactKind -ceq 'DebugScript' -and $_.IsComplete -and $_.TargetFlowId -ceq $count[0].TargetFlowId})
 Assert-Snapshot ($bundle.Count -eq 1) 'BOUND_DEBUGSCRIPT'
 $snapshot=Assert-SnapshotDebugScript $first $bundle[0] -InsertAfterPlan
 $rows=$snapshot.TargetSql.Rows;$countRow=$snapshot.RowCountSql.Rows
 Assert-Snapshot (Test-SnapshotRowCountTable $snapshot.RowCountSql 2) 'SNAPSHOT_ROWCOUNT_BIGINT_FITS_TWO'
 Assert-Snapshot ($rows.Count -eq 2) 'SNAPSHOT_TARGET_TWO_ROWS'
 $columns=@($snapshot.TargetSql.Columns|ForEach-Object ColumnName)
 Assert-Snapshot (($columns -join ',') -ceq 'KeyA,KeyB,Adjusted,Score') 'TARGET_COLUMN_ORDER'
 foreach($column in $snapshot.TargetSql.Columns){Assert-Snapshot ($column.DataType -eq [int]) 'TARGET_INT32_TYPE'}
 Assert-Snapshot (@($rows|Where-Object {$_.KeyA -eq 1 -and $_.KeyB -eq 10 -and $_.Adjusted -eq 101 -and $_.Score -eq 7}).Count -eq 1) 'ORIGINAL_ROW_ONE'
 Assert-Snapshot (@($rows|Where-Object {$_.KeyA -eq 2 -and $_.KeyB -eq 10 -and $_.Adjusted -eq 201 -and $_.Score -eq 2}).Count -eq 1) 'ORIGINAL_ROW_TWO'
 Assert-Snapshot (@($rows|Where-Object {$_.KeyA -eq 2 -and $_.KeyB -eq 10 -and $_.Adjusted -eq 202}).Count -eq 0) 'INSERT_ABSENT_FROM_MATERIALIZED_TARGET'
 $before=Get-SnapshotRows $snapshot.TargetSql
 $cleanup=@($first.Rows|Where-Object ArtifactKind -CEQ 'CleanupSql')
 Assert-Snapshot ($cleanup.Count -ge 1) 'CLEANUP_ARTIFACT'
 $second=Invoke-SnapshotExplain -Bytes $fixture -Bindings $bindings -Catalog $catalogJson
 $secondCount=@($second.Rows|Where-Object ArtifactKind -CEQ 'RowCountSql')
 Assert-Snapshot ($secondCount.Count -eq 1) 'CHANGED_SOURCE_CONTROL_COUNT'
 $secondBundle=@($second.Rows|Where-Object {$_.ArtifactKind -ceq 'DebugScript' -and $_.IsComplete -and $_.TargetFlowId -ceq $secondCount[0].TargetFlowId})
 Assert-Snapshot ($secondBundle.Count -eq 1) 'CHANGED_SOURCE_CONTROL_PLAN'
 $current=Assert-SnapshotDebugScript $second $secondBundle[0]
 Assert-Snapshot (Test-SnapshotRowCountTable $current.RowCountSql 3) 'CHANGED_SOURCE_ROWCOUNT_BIGINT_FITS_THREE'
 Assert-Snapshot ($current.TargetSql.Rows.Count -eq 3) 'CHANGED_SOURCE_TARGET_THREE'
 Assert-Snapshot (@($current.TargetSql.Rows|Where-Object {$_.KeyA -eq 2 -and $_.KeyB -eq 10 -and $_.Adjusted -eq 202 -and $_.Score -eq 2}).Count -eq 1) 'INSERT_PRESENT_IN_FRESH_SNAPSHOT'
 $after=Get-SnapshotRows $current.TargetSql
 foreach($row in $before){Assert-Snapshot (@($after|Where-Object {$_ -ceq $row}).Count -eq 1) 'ORIGINAL_ROWS_PRESERVED_IN_FRESH_SNAPSHOT'}
}finally{
 if($fixturesCreated){
  try{
   $ids=Invoke-SnapshotSql "SELECT name,object_id FROM sys.tables WITH (NOLOCK) WHERE schema_id=SCHEMA_ID(N'dbo') AND name IN(N'SyntheticSourceA',N'SyntheticSourceB',N'SyntheticLookup');"
   if($ids.Rows.Count -ne 3){throw 'SSIS_CURRENT_SNAPSHOT_FIXTURE_CLEANUP_IDENTITY'}
   foreach($expectedName in @('SyntheticSourceA','SyntheticSourceB','SyntheticLookup')){
    $found=@($ids.Rows|Where-Object name -CEQ $expectedName)
    if($found.Count -ne 1 -or [int]$found[0].object_id -ne [int]$fixtureIds[$expectedName]){throw 'SSIS_CURRENT_SNAPSHOT_FIXTURE_CLEANUP_IDENTITY'}
   }
   $shape=Invoke-SnapshotSql @'
SELECT COUNT_BIG(*) AS MatchingColumns, (SELECT COUNT_BIG(*) FROM sys.columns WHERE object_id IN(OBJECT_ID(N'dbo.SyntheticSourceA'),OBJECT_ID(N'dbo.SyntheticSourceB'),OBJECT_ID(N'dbo.SyntheticLookup'))) AS TotalColumns FROM sys.columns c WITH (NOLOCK)
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id=c.user_type_id
WHERE (c.object_id=OBJECT_ID(N'dbo.SyntheticSourceA') AND ((c.column_id=1 AND c.name=N'KeyA' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0) OR (c.column_id=2 AND c.name=N'KeyB' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0) OR (c.column_id=3 AND c.name=N'Amount' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0)))
   OR (c.object_id=OBJECT_ID(N'dbo.SyntheticSourceB') AND ((c.column_id=1 AND c.name=N'KeyA' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0) OR (c.column_id=2 AND c.name=N'KeyB' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0) OR (c.column_id=3 AND c.name=N'Amount' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0)))
   OR (c.object_id=OBJECT_ID(N'dbo.SyntheticLookup') AND ((c.column_id=1 AND c.name=N'KeyA' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0) OR (c.column_id=2 AND c.name=N'KeyB' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=0) OR (c.column_id=3 AND c.name=N'Score' AND t.name=N'int' AND c.max_length=4 AND c.is_nullable=1)));
'@ 1
   if($shape.Rows.Count -ne 1 -or [long]$shape.Rows[0].MatchingColumns -ne 9 -or [long]$shape.Rows[0].TotalColumns -ne 9){throw 'SSIS_CURRENT_SNAPSHOT_FIXTURE_SCHEMA_DRIFT'}
   if(-not $OwnershipJournal.Contains('snapshotMutationApplied') -or $OwnershipJournal['snapshotMutationApplied'] -isnot [bool]){throw 'SSIS_CURRENT_SNAPSHOT_MUTATION_PHASE_UNKNOWN'}
   $expectedFixture=Get-SnapshotFixtureExpectation ([bool]$OwnershipJournal['snapshotMutationApplied'])
   $sourceAValues=(@($expectedFixture.SourceA|ForEach-Object {'('+[string]$_.KeyA+','+[string]$_.KeyB+','+[string]$_.Amount+')'}) -join ',')
   $cleanupSql=@'
SELECT
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceA) AS SourceACount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceB) AS SourceBCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticLookup) AS LookupCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceB WHERE (KeyA=1 AND KeyB=10 AND Amount=80) OR (KeyA=3 AND KeyB=30 AND Amount=30)) AS SourceBKnownCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticLookup WHERE (KeyA=1 AND KeyB=10 AND Score=7) OR (KeyA=1 AND KeyB=20 AND Score IS NULL) OR (KeyA=2 AND KeyB=10 AND Score=2)) AS LookupKnownCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceA WHERE Amount+1>100) AS EligibleRows,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA EXCEPT SELECT KeyA,KeyB,Amount FROM (VALUES__SOURCE_A_VALUES__) AS E(KeyA,KeyB,Amount)) AS D) AS SourceAUnexpected,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM (VALUES__SOURCE_A_VALUES__) AS E(KeyA,KeyB,Amount) EXCEPT SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA) AS D) AS SourceAMissing,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceB EXCEPT SELECT KeyA,KeyB,Amount FROM (VALUES(1,10,80),(3,30,30)) AS E(KeyA,KeyB,Amount)) AS D) AS SourceBUnexpected,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM (VALUES(1,10,80),(3,30,30)) AS E(KeyA,KeyB,Amount) EXCEPT SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceB) AS D) AS SourceBMissing,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Score FROM dbo.SyntheticLookup EXCEPT SELECT KeyA,KeyB,Score FROM (VALUES(1,10,7),(1,20,CONVERT(int,NULL)),(2,10,2)) AS E(KeyA,KeyB,Score)) AS D) AS LookupUnexpected,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Score FROM (VALUES(1,10,7),(1,20,CONVERT(int,NULL)),(2,10,2)) AS E(KeyA,KeyB,Score) EXCEPT SELECT KeyA,KeyB,Score FROM dbo.SyntheticLookup) AS D) AS LookupMissing;
'@
   $cleanupSql=$cleanupSql.Replace('VALUES__SOURCE_A_VALUES__',$sourceAValues)
   $cleanupState=Invoke-SnapshotSql $cleanupSql 1
   if($cleanupState.Rows.Count -ne 1 -or [long]$cleanupState.Rows[0].SourceACount -ne [long]$expectedFixture.SourceACount -or [long]$cleanupState.Rows[0].SourceBCount -ne 2 -or [long]$cleanupState.Rows[0].LookupCount -ne 3 -or [long]$cleanupState.Rows[0].SourceBKnownCount -ne 2 -or [long]$cleanupState.Rows[0].LookupKnownCount -ne 3 -or [long]$cleanupState.Rows[0].EligibleRows -ne [long]$expectedFixture.EligibleRows -or [long]$cleanupState.Rows[0].SourceAUnexpected -ne 0 -or [long]$cleanupState.Rows[0].SourceAMissing -ne 0 -or [long]$cleanupState.Rows[0].SourceBUnexpected -ne 0 -or [long]$cleanupState.Rows[0].SourceBMissing -ne 0 -or [long]$cleanupState.Rows[0].LookupUnexpected -ne 0 -or [long]$cleanupState.Rows[0].LookupMissing -ne 0){throw 'SSIS_CURRENT_SNAPSHOT_FIXTURE_DATA_DRIFT'}
   [void](Invoke-SnapshotSql 'DROP TABLE dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup;' 0)
  }catch{$OwnershipJournal['snapshotCleanupBlocked']=$true;throw}
 }
}
"SSIS_CURRENT_SNAPSHOT_PASS $checks assertions; same materialized RowCount/target snapshot across one source insert; synthetic only"
