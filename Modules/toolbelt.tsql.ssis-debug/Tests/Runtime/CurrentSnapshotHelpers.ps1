Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Assert-SnapshotResultSetCount([int]$Actual,[int]$Expected){
 if($Actual -ne $Expected){throw 'SSIS_CURRENT_SNAPSHOT_RESULTSET_COUNT'}
}

function Read-SnapshotReaderResultSets([System.Data.IDataReader]$Reader,[int]$ExpectedResultSets){
 $tables=[Collections.Generic.List[Data.DataTable]]::new()
 do{
  if($Reader.FieldCount -gt 0){
   $table=[Data.DataTable]::new()
   for($i=0;$i -lt $Reader.FieldCount;$i++){[void]$table.Columns.Add($Reader.GetName($i),$Reader.GetFieldType($i))}
   while($Reader.Read()){$values=[object[]]::new($Reader.FieldCount);[void]$Reader.GetValues($values);[void]$table.Rows.Add($values)}
   $tables.Add($table)
  }else{while($Reader.Read()){$null=$Reader.RecordsAffected}}
 }while($Reader.NextResult())
 Assert-SnapshotResultSetCount $tables.Count $ExpectedResultSets
 return ,$tables.ToArray()
}

function Test-SnapshotRowCountTable($Table,[long]$ExpectedCount){
 if($null -eq $Table -or $Table.Columns.Count -ne 2 -or $Table.Rows.Count -ne 1){return $false}
 if($Table.Columns[0].ColumnName -cne 'CountValue' -or $Table.Columns[0].DataType -ne [long]){return $false}
 if($Table.Columns[1].ColumnName -cne 'FitsTargetVariable' -or $Table.Columns[1].DataType -ne [bool]){return $false}
 $row=$Table.Rows[0]
 return ($row.CountValue -is [long] -and [long]$row.CountValue -eq $ExpectedCount -and $row.FitsTargetVariable -is [bool] -and [bool]$row.FitsTargetVariable)
}

function Get-SnapshotBatchLayout([string[]]$Kinds){
 $rank=-1;$preparations=0;$units=0;$targets=0;$counts=0;$cleanups=0;$readSeen=$false
 foreach($kind in $Kinds){
  switch -CaseSensitive($kind){
   'PreparationSql' {if($readSeen -or $units -gt 0){throw 'SSIS_CURRENT_SNAPSHOT_PREPARATION_AFTER_PLAN_OR_READ'};$current=0;$preparations++}
   'PlanUnitSql' {if($readSeen){throw 'SSIS_CURRENT_SNAPSHOT_PLAN_AFTER_READ'};$current=1;$units++}
   'TargetSql' {$current=2;$readSeen=$true;$targets++}
   'RowCountSql' {$current=2;$readSeen=$true;$counts++}
   'CleanupSql' {if(-not $readSeen){throw 'SSIS_CURRENT_SNAPSHOT_CLEANUP_BEFORE_READ'};$current=3;$cleanups++}
   default {throw 'SSIS_CURRENT_SNAPSHOT_UNKNOWN_BATCH_KIND'}
  }
  if($current -lt $rank){throw 'SSIS_CURRENT_SNAPSHOT_BATCH_PHASE_ORDER'};$rank=$current
 }
 if($preparations -lt 1 -or $units -lt 1 -or $targets -ne 1 -or $counts -ne 1 -or $cleanups -lt 1){throw 'SSIS_CURRENT_SNAPSHOT_BATCH_LAYOUT_INCOMPLETE'}
 return [pscustomobject]@{PreparationCount=$preparations;PlanUnitCount=$units;TargetCount=$targets;RowCountCount=$counts;CleanupCount=$cleanups}
}

function Test-SnapshotBatchBinding($ActualOrdinal,$ExpectedOrdinal,[string]$ActualKind,[string]$ExpectedKind,[string]$ActualHash,[string]$ExpectedHash,[bool]$Executable,[string]$SafetyStatus){
 if(($ActualOrdinal -isnot [int] -and $ActualOrdinal -isnot [long]) -or ($ExpectedOrdinal -isnot [int] -and $ExpectedOrdinal -isnot [long])){return $false}
 if([long]$ActualOrdinal -ne [long]$ExpectedOrdinal -or $ActualKind -cne $ExpectedKind){return $false}
 if($ActualHash -cnotmatch '^[0-9A-F]{64}$' -or $ActualHash -cne $ExpectedHash){return $false}
 return $Executable -and $SafetyStatus -ceq 'passed'
}

function Test-SnapshotInteger($Value){return ($Value -is [int] -or $Value -is [long])}

function Test-SnapshotOwnedDatabaseState($Expected,$Actual,[string]$ObservedOwner,[bool]$CleanupBlocked){
 if($CleanupBlocked -or $null -eq $Expected -or $null -eq $Actual -or [string]::IsNullOrEmpty($ObservedOwner)){return $false}
 return ([int]$Expected.databaseId -gt 0 -and [int]$Actual.databaseId -eq [int]$Expected.databaseId -and
         [string]$Actual.created -ceq [string]$Expected.created -and [string]$Expected.ownerRunId -ceq $ObservedOwner)
}

function Mark-SnapshotDatabaseDropped([System.Collections.Generic.List[string]]$Owned,[System.Collections.Generic.HashSet[string]]$Dropped,[string]$Name){
 if($null -eq $Owned -or $null -eq $Dropped -or [string]::IsNullOrEmpty($Name) -or -not $Owned.Contains($Name) -or $Dropped.Contains($Name)){return $false}
 return $Dropped.Add($Name)
}

function Test-SnapshotAllDatabasesDropped([System.Collections.Generic.List[string]]$Owned,[System.Collections.Generic.HashSet[string]]$Dropped){
 if($null -eq $Owned -or $null -eq $Dropped){return $false}
 foreach($name in $Owned){if(-not $Dropped.Contains($name)){return $false}}
 return $true
}

function Get-SnapshotFixtureExpectation([bool]$MutationApplied){
 $sourceA=@([pscustomobject]@{KeyA=1;KeyB=10;Amount=100},[pscustomobject]@{KeyA=1;KeyB=20;Amount=20},[pscustomobject]@{KeyA=2;KeyB=10;Amount=200})
 if($MutationApplied){$sourceA+=,[pscustomobject]@{KeyA=2;KeyB=10;Amount=201}}
 return [pscustomobject]@{SourceA=$sourceA;SourceACount=$sourceA.Count;EligibleRows=if($MutationApplied){3}else{2}}
}

function Invoke-SnapshotOfflineChecks{
 Assert-SnapshotResultSetCount 0 0;Assert-SnapshotResultSetCount 1 1
 foreach($pair in @([pscustomobject]@{actual=1;expected=0},[pscustomobject]@{actual=2;expected=1})){
  $rejected=$false;try{Assert-SnapshotResultSetCount $pair.actual $pair.expected}catch{$rejected=$_.Exception.Message -ceq 'SSIS_CURRENT_SNAPSHOT_RESULTSET_COUNT'}
  if(-not $rejected){throw 'SSIS_CURRENT_SNAPSHOT_RESULTSET_NEGATIVE_FAILED'}
 }
 $emptySet=[Data.DataTable]::new();$emptyTables=[Data.DataTable[]]::new(1);$emptyTables[0]=$emptySet;$emptyReader=[Data.DataTableReader]::new($emptyTables)
 try{$emptyResults=Read-SnapshotReaderResultSets $emptyReader 0;if($emptyResults.Count -ne 0){throw 'SSIS_CURRENT_SNAPSHOT_READER_EMPTY_CONTROL_FAILED'}}finally{$emptyReader.Dispose()}
 $oneSet=[Data.DataTable]::new();[void]$oneSet.Columns.Add('OnlyValue',[int]);[void]$oneSet.Rows.Add([int]23)
 $oneTables=[Data.DataTable[]]::new(1);$oneTables[0]=$oneSet;$oneReader=[Data.DataTableReader]::new($oneTables)
 try{$oneResults=Read-SnapshotReaderResultSets $oneReader 1;if($oneResults.Count -ne 1 -or $oneResults[0].Rows.Count -ne 1 -or [int]$oneResults[0].Rows[0].OnlyValue -ne 23){throw 'SSIS_CURRENT_SNAPSHOT_READER_SINGLE_CONTROL_FAILED'}}finally{$oneReader.Dispose()}
 $twoA=[Data.DataTable]::new();[void]$twoA.Columns.Add('First',[int]);[void]$twoA.Rows.Add([int]1)
 $twoB=[Data.DataTable]::new();[void]$twoB.Columns.Add('Second',[int]);[void]$twoB.Rows.Add([int]2)
 $twoTables=[Data.DataTable[]]::new(2);$twoTables[0]=$twoA;$twoTables[1]=$twoB;$twoReader=[Data.DataTableReader]::new($twoTables);$extraRejected=$false
 try{[void](Read-SnapshotReaderResultSets $twoReader 1)}catch{$extraRejected=$_.Exception.Message -ceq 'SSIS_CURRENT_SNAPSHOT_RESULTSET_COUNT'}finally{$twoReader.Dispose()}
 if(-not $extraRejected){throw 'SSIS_CURRENT_SNAPSHOT_READER_EXTRA_RESULT_NEGATIVE_FAILED'}
 $rowCountTable=[Data.DataTable]::new();[void]$rowCountTable.Columns.Add('CountValue',[long]);[void]$rowCountTable.Columns.Add('FitsTargetVariable',[bool]);[void]$rowCountTable.Rows.Add([long]2,$true)
 if(-not (Test-SnapshotRowCountTable $rowCountTable 2)){throw 'SSIS_CURRENT_SNAPSHOT_ROWCOUNT_CONTROL_FAILED'}
 $badRowCount=[Data.DataTable]::new();[void]$badRowCount.Columns.Add('CountValue',[long]);[void]$badRowCount.Columns.Add('FitsTargetVariable',[bool]);[void]$badRowCount.Rows.Add([long]2,$false)
 if(Test-SnapshotRowCountTable $badRowCount 2){throw 'SSIS_CURRENT_SNAPSHOT_ROWCOUNT_FIT_NEGATIVE_FAILED'}
 $wrongRowCount=[Data.DataTable]::new();[void]$wrongRowCount.Columns.Add('CountValue',[int]);[void]$wrongRowCount.Columns.Add('FitsTargetVariable',[bool]);[void]$wrongRowCount.Rows.Add([int]2,$true)
 if(Test-SnapshotRowCountTable $wrongRowCount 2){throw 'SSIS_CURRENT_SNAPSHOT_ROWCOUNT_TYPE_NEGATIVE_FAILED'}
 $extraRowCount=[Data.DataTable]::new();[void]$extraRowCount.Columns.Add('CountValue',[long]);[void]$extraRowCount.Columns.Add('FitsTargetVariable',[bool]);[void]$extraRowCount.Columns.Add('Unexpected',[int]);[void]$extraRowCount.Rows.Add([long]2,$true,0)
 if(Test-SnapshotRowCountTable $extraRowCount 2){throw 'SSIS_CURRENT_SNAPSHOT_ROWCOUNT_SHAPE_NEGATIVE_FAILED'}
 $layout=Get-SnapshotBatchLayout ([string[]]@('PreparationSql','PlanUnitSql','PlanUnitSql','TargetSql','RowCountSql','CleanupSql'))
 if($layout.PlanUnitCount -ne 2){throw 'SSIS_CURRENT_SNAPSHOT_BATCH_LAYOUT_CONTROL_FAILED'}
 $invalidLayouts=@(
  [pscustomobject]@{values=[string[]]@('PlanUnitSql','TargetSql','PlanUnitSql','RowCountSql','CleanupSql')},
  [pscustomobject]@{values=[string[]]@('PreparationSql','PlanUnitSql','TargetSql','MysterySql','CleanupSql')})
 foreach($candidate in $invalidLayouts){$rejected=$false;try{[void](Get-SnapshotBatchLayout $candidate.values)}catch{$rejected=$true};if(-not $rejected){throw 'SSIS_CURRENT_SNAPSHOT_BATCH_ORDER_NEGATIVE_FAILED'}}
 if(-not (Test-SnapshotBatchBinding 4 4 'PlanUnitSql' 'PlanUnitSql' ('A'*64) ('A'*64) $true 'passed')){throw 'SSIS_CURRENT_SNAPSHOT_BATCH_BINDING_CONTROL_FAILED'}
 if(-not (Test-SnapshotInteger ([long]4)) -or (Test-SnapshotInteger $false) -or (Test-SnapshotInteger ([double]4.0))){throw 'SSIS_CURRENT_SNAPSHOT_INTEGER_TYPE_CONTROL_FAILED'}
 $badBindings=@(
  [pscustomobject]@{actual=4;expected=5;actualKind='PlanUnitSql';expectedKind='PlanUnitSql';actualHash=('A'*64);expectedHash=('A'*64);executable=$true;safety='passed'},
  [pscustomobject]@{actual=4;expected=4;actualKind='PlanUnitSql';expectedKind='RowCountSql';actualHash=('A'*64);expectedHash=('A'*64);executable=$true;safety='passed'},
  [pscustomobject]@{actual=4;expected=4;actualKind='PlanUnitSql';expectedKind='PlanUnitSql';actualHash=('A'*64);expectedHash=('B'*64);executable=$true;safety='passed'},
  [pscustomobject]@{actual=4;expected=4;actualKind='PlanUnitSql';expectedKind='PlanUnitSql';actualHash=('A'*64);expectedHash=('A'*64);executable=$false;safety='passed'},
  [pscustomobject]@{actual=$false;expected=4;actualKind='PlanUnitSql';expectedKind='PlanUnitSql';actualHash=('A'*64);expectedHash=('A'*64);executable=$true;safety='passed'})
 foreach($candidate in $badBindings){if(Test-SnapshotBatchBinding $candidate.actual $candidate.expected $candidate.actualKind $candidate.expectedKind $candidate.actualHash $candidate.expectedHash $candidate.executable $candidate.safety){throw 'SSIS_CURRENT_SNAPSHOT_BATCH_BINDING_NEGATIVE_FAILED'}}
 $expected=[pscustomobject]@{databaseId=17;created='2026-10-30T00:00:00.000';ownerRunId='synthetic-owner'};$actual=[pscustomobject]@{databaseId=17;created='2026-10-30T00:00:00.000'}
 if(-not (Test-SnapshotOwnedDatabaseState $expected $actual 'synthetic-owner' $false)){throw 'SSIS_CURRENT_SNAPSHOT_OWNERSHIP_CONTROL_FAILED'}
 $badOwnership=@(
  [pscustomobject]@{actual=[pscustomobject]@{databaseId=18;created=$actual.created};owner='synthetic-owner';blocked=$false},
  [pscustomobject]@{actual=[pscustomobject]@{databaseId=17;created='2026-10-30T00:00:01.000'};owner='synthetic-owner';blocked=$false},
  [pscustomobject]@{actual=$actual;owner='different-owner';blocked=$false},
  [pscustomobject]@{actual=$actual;owner='synthetic-owner';blocked=$true})
 foreach($candidate in $badOwnership){if(Test-SnapshotOwnedDatabaseState $expected $candidate.actual $candidate.owner $candidate.blocked){throw 'SSIS_CURRENT_SNAPSHOT_OWNERSHIP_NEGATIVE_FAILED'}}
 $ownedNames=[Collections.Generic.List[string]]::new();$ownedNames.Add('synthetic-a');$ownedNames.Add('synthetic-b');$droppedNames=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 if(-not (Mark-SnapshotDatabaseDropped $ownedNames $droppedNames 'synthetic-a') -or $ownedNames.Count -ne 2 -or (Test-SnapshotAllDatabasesDropped $ownedNames $droppedNames)){throw 'SSIS_CURRENT_SNAPSHOT_DROP_TRACKER_PREFIX_FAILED'}
 if(-not (Mark-SnapshotDatabaseDropped $ownedNames $droppedNames 'synthetic-b') -or -not (Test-SnapshotAllDatabasesDropped $ownedNames $droppedNames) -or (Mark-SnapshotDatabaseDropped $ownedNames $droppedNames 'foreign') -or (Mark-SnapshotDatabaseDropped $ownedNames $droppedNames 'synthetic-a')){throw 'SSIS_CURRENT_SNAPSHOT_DROP_TRACKER_COMPLETE_FAILED'}
 if($ownedNames.Count -ne 2 -or $ownedNames[0] -cne 'synthetic-a' -or $ownedNames[1] -cne 'synthetic-b'){throw 'SSIS_CURRENT_SNAPSHOT_DROP_JOURNAL_RETENTION_FAILED'}
 $initialFixture=Get-SnapshotFixtureExpectation $false;$mutatedFixture=Get-SnapshotFixtureExpectation $true
 if($initialFixture.SourceACount -ne 3 -or $initialFixture.EligibleRows -ne 2 -or $mutatedFixture.SourceACount -ne 4 -or $mutatedFixture.EligibleRows -ne 3){throw 'SSIS_CURRENT_SNAPSHOT_FIXTURE_PHASE_CONTROL_FAILED'}
}
