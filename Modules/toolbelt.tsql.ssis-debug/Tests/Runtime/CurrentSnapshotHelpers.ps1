Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Assert-SnapshotResultSetCount([int]$Actual,[int]$Expected){
 if($Actual -ne $Expected){throw 'SSIS_CURRENT_SNAPSHOT_RESULTSET_COUNT'}
}

function Test-SnapshotNoReparsePath([string]$Path,[string]$BoundaryRoot){
 if([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($BoundaryRoot)){return $false}
 try{$full=[IO.Path]::GetFullPath($Path);$boundary=[IO.Path]::GetFullPath($BoundaryRoot)}catch{return $false}
 if(-not $full.StartsWith($boundary.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and $full -cne $boundary){return $false}
 $relative=$full.Substring($boundary.TrimEnd('\','/').Length).TrimStart('\','/')
 $cursor=$boundary.TrimEnd('\','/')
 if($relative.Length -eq 0){$parts=@()}else{$parts=$relative -split '[\\/]'}
 foreach($part in $parts){$cursor=Join-Path $cursor $part;if(-not (Test-Path -LiteralPath $cursor)){return $false};$item=Get-Item -LiteralPath $cursor -Force;if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){return $false}}
 return $true
}

function Test-SnapshotManifestClosure($Entries,$RequiredEntries){
 if($null -eq $Entries -or $null -eq $RequiredEntries -or @($RequiredEntries).Count -eq 0){return $false}
 if(@($Entries).Count -ne @($RequiredEntries).Count){return $false}
 $paths=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($entry in $Entries){
  if($null -eq $entry -or [string]::IsNullOrWhiteSpace([string]$entry.path) -or [string]$entry.sha256 -cnotmatch '^[0-9A-F]{64}$' -or $paths.ContainsKey([string]$entry.path)){return $false}
  $paths[[string]$entry.path]=[string]$entry.sha256
 }
 foreach($required in $RequiredEntries){if($null -eq $required -or -not $paths.ContainsKey([string]$required.path) -or $paths[[string]$required.path] -cne [string]$required.sha256){return $false};[void]$paths.Remove([string]$required.path)}
 if($paths.Count -ne 0){return $false}
 return $true
}

function Assert-SnapshotCurrentInputs($Binding){
 if($null -eq $Binding -or [string]::IsNullOrWhiteSpace([string]$Binding.manifestPath) -or [string]::IsNullOrWhiteSpace([string]$Binding.repositoryRoot) -or [string]$Binding.sha256 -cnotmatch '^[0-9A-F]{64}$'){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_BINDING_INVALID'}
 if(-not (Test-SnapshotNoReparsePath ([string]$Binding.manifestPath) ([string]$Binding.repositoryRoot))){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_CHANGED'}
 $manifestInfo=Get-Item -LiteralPath ([string]$Binding.manifestPath) -Force
 if($manifestInfo.PSIsContainer -or $manifestInfo.Length -lt 1 -or $manifestInfo.Length -gt 1048576 -or (Get-FileHash -LiteralPath ([string]$Binding.manifestPath) -Algorithm SHA256).Hash -cne [string]$Binding.sha256){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_CHANGED'}
 if(@($Binding.files).Count -lt 1 -or @($Binding.files).Count -gt 128 -or @($Binding.externalFiles).Count -lt 2 -or @($Binding.externalFiles).Count -gt 3){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_BINDING_SIZE'}
 foreach($entry in @($Binding.files)){$file=[IO.Path]::GetFullPath((Join-Path ([string]$Binding.repositoryRoot) ([string]$entry.path)));if(-not (Test-SnapshotNoReparsePath $file ([string]$Binding.repositoryRoot))){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_CHANGED'};$info=Get-Item -LiteralPath $file -Force;if($info.PSIsContainer -or $info.Length -lt 0 -or $info.Length -gt 134217728 -or (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne [string]$entry.sha256){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_CHANGED'}}
 foreach($entry in @($Binding.externalFiles)){$file=[IO.Path]::GetFullPath([string]$entry.path);$root=[IO.Path]::GetPathRoot($file);if(-not (Test-SnapshotNoReparsePath $file $root)){throw 'SSIS_CURRENT_SNAPSHOT_EXTERNAL_INPUT_CHANGED'};$info=Get-Item -LiteralPath $file -Force;if($info.PSIsContainer -or $info.Length -lt 0 -or $info.Length -gt 4194304 -or (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne [string]$entry.sha256){throw 'SSIS_CURRENT_SNAPSHOT_EXTERNAL_INPUT_CHANGED'}}
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
 if($units -lt 1 -or $targets -ne 1 -or $counts -ne 1 -or $cleanups -lt 1){throw 'SSIS_CURRENT_SNAPSHOT_BATCH_LAYOUT_INCOMPLETE'}
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

function New-SnapshotFixtureCleanup([bool]$MutationApplied){
 $expected=Get-SnapshotFixtureExpectation $MutationApplied
 $sourceAValues=(@($expected.SourceA|ForEach-Object {'('+[string]$_.KeyA+','+[string]$_.KeyB+','+[string]$_.Amount+')'}) -join ',')
 $template=@'
SELECT
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceA) AS SourceACount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceB) AS SourceBCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticLookup) AS LookupCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceB WHERE (KeyA=1 AND KeyB=10 AND Amount=80) OR (KeyA=3 AND KeyB=30 AND Amount=30)) AS SourceBKnownCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticLookup WHERE (KeyA=1 AND KeyB=10 AND Score=7) OR (KeyA=1 AND KeyB=20 AND Score IS NULL) OR (KeyA=2 AND KeyB=10 AND Score=2)) AS LookupKnownCount,
 (SELECT COUNT_BIG(*) FROM dbo.SyntheticSourceA WHERE Amount+1>100) AS EligibleRows,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA EXCEPT SELECT KeyA,KeyB,Amount FROM (VALUES __SOURCE_A_VALUES__) AS E(KeyA,KeyB,Amount)) AS D) AS SourceAUnexpected,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM (VALUES __SOURCE_A_VALUES__) AS E(KeyA,KeyB,Amount) EXCEPT SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA) AS D) AS SourceAMissing,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceB EXCEPT SELECT KeyA,KeyB,Amount FROM (VALUES(1,10,80),(3,30,30)) AS E(KeyA,KeyB,Amount)) AS D) AS SourceBUnexpected,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Amount FROM (VALUES(1,10,80),(3,30,30)) AS E(KeyA,KeyB,Amount) EXCEPT SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceB) AS D) AS SourceBMissing,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Score FROM dbo.SyntheticLookup EXCEPT SELECT KeyA,KeyB,Score FROM (VALUES(1,10,7),(1,20,CONVERT(int,NULL)),(2,10,2)) AS E(KeyA,KeyB,Score)) AS D) AS LookupUnexpected,
 (SELECT COUNT_BIG(*) FROM (SELECT KeyA,KeyB,Score FROM (VALUES(1,10,7),(1,20,CONVERT(int,NULL)),(2,10,2)) AS E(KeyA,KeyB,Score) EXCEPT SELECT KeyA,KeyB,Score FROM dbo.SyntheticLookup) AS D) AS LookupMissing;
'@
 $token='__SOURCE_A_VALUES__'
 if([regex]::Matches($template,[regex]::Escape($token)).Count -ne 2){throw 'SSIS_CURRENT_SNAPSHOT_CLEANUP_VALUES_TOKEN_COUNT'}
 $sql=$template.Replace($token,$sourceAValues)
  if($sql.Contains($token) -or [regex]::Matches($sql,'(?i)FROM\s*\(\s*VALUES\s*\(').Count -ne 6){throw 'SSIS_CURRENT_SNAPSHOT_CLEANUP_VALUES_RENDERING'}
 return [pscustomobject]@{Sql=$sql;Expected=$expected}
}

function Get-SnapshotErrorSummary($ErrorValue){
 $exception=if($ErrorValue -is [System.Management.Automation.ErrorRecord]){$ErrorValue.Exception}else{$ErrorValue}
 while($null -ne $exception -and $null -ne $exception.InnerException){$exception=$exception.InnerException}
 if($null -eq $exception){return [pscustomobject]@{kind='unknown'}}
 if($exception -is [System.Data.SqlClient.SqlException]){
  $details=@(foreach($sqlError in $exception.Errors){[pscustomobject]@{number=[int]$sqlError.Number;state=[int]$sqlError.State;class=[int]$sqlError.Class;line=[int]$sqlError.LineNumber}})
  return [pscustomobject]@{kind='sql';errors=$details}
 }
 return [pscustomobject]@{kind=$exception.GetType().FullName}
}

function Resolve-SnapshotFailure([System.Collections.IDictionary]$Journal,[string]$Scope,$PrimaryError,$CleanupError){
 if($null -ne $PrimaryError){$Journal[$Scope+'Failure']=Get-SnapshotErrorSummary $PrimaryError}
 if($null -ne $CleanupError){$Journal[$Scope+'CleanupFailure']=Get-SnapshotErrorSummary $CleanupError;$Journal['snapshotCleanupBlocked']=$true}
 if($null -ne $PrimaryError){return $PrimaryError}
 return $CleanupError
}

function Invoke-SnapshotOfflineChecks([string]$ScriptDomPath){
 if([string]::IsNullOrWhiteSpace($ScriptDomPath) -or -not (Test-Path -LiteralPath $ScriptDomPath -PathType Leaf)){throw 'SSIS_CURRENT_SNAPSHOT_SCRIPTDOM_REQUIRED'}
 [void][Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($ScriptDomPath))
 $parserType=[Type]::GetType('Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser, Microsoft.SqlServer.TransactSql.ScriptDom',$true)
 $parser=[Activator]::CreateInstance($parserType,[object[]]@($true))
 foreach($mutationApplied in @($false,$true)){
  $rendered=New-SnapshotFixtureCleanup ([bool]$mutationApplied)
  $parseErrors=$null;$reader=[IO.StringReader]::new([string]$rendered.Sql)
  try{$null=$parser.Parse($reader,[ref]$parseErrors)}finally{$reader.Dispose()}
  if(@($parseErrors).Count -ne 0){throw 'SSIS_CURRENT_SNAPSHOT_CLEANUP_SCRIPTDOM_PARSE_FAILED'}
  if($rendered.Expected.SourceACount -ne $(if($mutationApplied){4}else{3})){throw 'SSIS_CURRENT_SNAPSHOT_CLEANUP_EXPECTED_SHAPE_FAILED'}
 }
 $cwd=[IO.Path]::GetFullPath((Get-Location).Path)
 if(-not (Test-SnapshotNoReparsePath (Join-Path $cwd 'AGENTS.md') $cwd) -or (Test-SnapshotNoReparsePath (Join-Path $env:SystemRoot 'System32') $cwd)){throw 'SSIS_CURRENT_SNAPSHOT_PATH_BOUNDARY_CHECK_FAILED'}
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
 $noPreparation=Get-SnapshotBatchLayout ([string[]]@('PlanUnitSql','TargetSql','RowCountSql','CleanupSql'))
 if($noPreparation.PreparationCount -ne 0 -or $noPreparation.PlanUnitCount -ne 1 -or $noPreparation.TargetCount -ne 1 -or $noPreparation.RowCountCount -ne 1 -or $noPreparation.CleanupCount -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_ZERO_PREPARATION_CONTROL_FAILED'}
 $invalidLayouts=@(
  [pscustomobject]@{values=[string[]]@('PlanUnitSql','TargetSql','PlanUnitSql','RowCountSql','CleanupSql')},
  [pscustomobject]@{values=[string[]]@('PreparationSql','PlanUnitSql','TargetSql','MysterySql','CleanupSql')},
  [pscustomobject]@{values=[string[]]@('TargetSql','RowCountSql','CleanupSql')},
  [pscustomobject]@{values=[string[]]@('PlanUnitSql','RowCountSql','CleanupSql')},
  [pscustomobject]@{values=[string[]]@('PlanUnitSql','TargetSql','CleanupSql')},
  [pscustomobject]@{values=[string[]]@('PlanUnitSql','TargetSql','RowCountSql')})
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
 $closedPaths=@('adapter.ps1','helpers.ps1','fixture.dtsx','provider.dll')
 $closedEntries=@(foreach($path in $closedPaths){[pscustomobject]@{path=$path;sha256=('A'*64)}})
 if(-not (Test-SnapshotManifestClosure $closedEntries $closedEntries)){throw 'SSIS_CURRENT_SNAPSHOT_MANIFEST_CONTROL_FAILED'}
 if(Test-SnapshotManifestClosure @($closedEntries|Where-Object path -ne 'helpers.ps1') $closedEntries){throw 'SSIS_CURRENT_SNAPSHOT_MANIFEST_MISSING_HELPER_NEGATIVE_FAILED'}
 $changedEntries=@($closedEntries|ForEach-Object {if($_.path -ceq 'provider.dll'){[pscustomobject]@{path=$_.path;sha256=('B'*64)}}else{$_}})
 if(Test-SnapshotManifestClosure $changedEntries $closedEntries){throw 'SSIS_CURRENT_SNAPSHOT_MANIFEST_CHANGED_ENTRY_NEGATIVE_FAILED'}
 $extraEntries=@($closedEntries)+@([pscustomobject]@{path='unbound.extra';sha256=('A'*64)})
 if(Test-SnapshotManifestClosure $extraEntries $closedEntries){throw 'SSIS_CURRENT_SNAPSHOT_MANIFEST_EXTRA_ENTRY_NEGATIVE_FAILED'}
 $boundFile=Join-Path $cwd 'AGENTS.md';$boundHash=(Get-FileHash -LiteralPath $boundFile -Algorithm SHA256).Hash
 $secondBoundFile=Join-Path $cwd '.ai/PROJECT_RULES.md';$secondBoundHash=(Get-FileHash -LiteralPath $secondBoundFile -Algorithm SHA256).Hash
 $testBinding=[pscustomobject]@{manifestPath=$boundFile;sha256=$boundHash;repositoryRoot=$cwd;files=@([pscustomobject]@{path='AGENTS.md';sha256=$boundHash});externalFiles=@([pscustomobject]@{path=$boundFile;sha256=$boundHash},[pscustomobject]@{path=$secondBoundFile;sha256=$secondBoundHash})}
 Assert-SnapshotCurrentInputs $testBinding
 $changedBinding=[pscustomobject]@{manifestPath=$boundFile;sha256=('B'*64);repositoryRoot=$cwd;files=$testBinding.files;externalFiles=$testBinding.externalFiles};$changedBindingRejected=$false
 try{Assert-SnapshotCurrentInputs $changedBinding}catch{$changedBindingRejected=$_.Exception.Message -ceq 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_CHANGED'}
 if(-not $changedBindingRejected){throw 'SSIS_CURRENT_SNAPSHOT_MANIFEST_HASH_NEGATIVE_FAILED'}
 $expected=[pscustomobject]@{databaseId=17;created='2026-10-30T00:00:00.000';ownerRunId='synthetic-owner'};$actual=[pscustomobject]@{databaseId=17;created='2026-10-30T00:00:00.000'}
 $failureJournal=[ordered]@{};$primaryFailure=[InvalidOperationException]::new('synthetic-primary');$cleanupFailure=[ApplicationException]::new('synthetic-cleanup')
 $selectedFailure=Resolve-SnapshotFailure $failureJournal 'snapshotProbe' $primaryFailure $cleanupFailure
 if(-not [object]::ReferenceEquals($selectedFailure,$primaryFailure) -or -not $failureJournal.Contains('snapshotProbeFailure') -or -not $failureJournal.Contains('snapshotProbeCleanupFailure') -or -not [bool]$failureJournal['snapshotCleanupBlocked']){throw 'SSIS_CURRENT_SNAPSHOT_PRIMARY_CLEANUP_DIAGNOSTICS_FAILED'}
 $cleanupOnlyJournal=[ordered]@{};$cleanupOnly=Resolve-SnapshotFailure $cleanupOnlyJournal 'snapshotProbe' $null $cleanupFailure
 if(-not [object]::ReferenceEquals($cleanupOnly,$cleanupFailure) -or $cleanupOnlyJournal.Contains('snapshotProbeFailure')){throw 'SSIS_CURRENT_SNAPSHOT_CLEANUP_ONLY_DIAGNOSTIC_FAILED'}
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
