# Synthetische SELECT-/TDS-Orakel; keine Datei-, Netzwerk- oder Labverwaltung.
function Get-CsvDirectSelectCase {
 param([ValidateRange(0,7)][int]$Phase)
 if($Phase%4 -ge 2){return [pscustomobject]@{ErrorNumber=55303;ErrorState=1;Schema=@();Rows=@()}}
 $quoted=$Phase -ge 4
 $value=if($quoted){','+[string]::new([char]'x',8388603)}else{[string]::new([char]'x',8388606)}
 if($Phase%4 -eq 0){
  $schema=@(
   [pscustomobject]@{Name='RowKind';SqlType='varchar';ClrType='System.String'},
   [pscustomobject]@{Name='RowOrdinal';SqlType='bigint';ClrType='System.Int64'},
   [pscustomobject]@{Name='ColumnOrdinal';SqlType='int';ClrType='System.Int32'},
   [pscustomobject]@{Name='Value';SqlType='nvarchar';ClrType='System.String'})
  $values=@('DATA',[long]1,[int]1,$value)
 }else{
  $schema=@(
   [pscustomobject]@{Name='CsvText';SqlType='nvarchar';ClrType='System.String'},
   [pscustomobject]@{Name='DataRows';SqlType='bigint';ClrType='System.Int64'},
   [pscustomobject]@{Name='ColumnCount';SqlType='int';ClrType='System.Int32'})
  $text=if($quoted){'"'+$value+'"'+[char]13+[char]10}else{$value+[char]13+[char]10}
  $values=@($text,[long]1,[int]1)
 }
 return [pscustomobject]@{ErrorNumber=0;ErrorState=0;Schema=$schema;Rows=@([pscustomobject]@{Values=$values})}
}

function Assert-CsvDirectSelectRows {
 param([object[]]$Schema,[object[]]$Rows,$Expected)
 if($Expected.ErrorNumber -ne 0 -or $Schema.Count -ne $Expected.Schema.Count -or $Rows.Count -ne $Expected.Rows.Count){throw 'CSV_SELECT_RESULT_SHAPE'}
 for($column=0;$column -lt $Schema.Count;$column++){
  foreach($field in 'Name','SqlType','ClrType'){
   if($Schema[$column].$field -isnot [string] -or $Schema[$column].$field -cne $Expected.Schema[$column].$field){throw 'CSV_SELECT_RESULT_METADATA'}
  }
 }
 for($row=0;$row -lt $Rows.Count;$row++){
  if($Rows[$row].Values.Count -ne $Schema.Count -or $Expected.Rows[$row].Values.Count -ne $Schema.Count){throw 'CSV_SELECT_RESULT_WIDTH'}
  for($column=0;$column -lt $Schema.Count;$column++){
   $actual=$Rows[$row].Values[$column];$wanted=$Expected.Rows[$row].Values[$column]
   if($wanted -is [DBNull]){if($actual -isnot [DBNull]){throw 'CSV_SELECT_RESULT_NULL'}}
   elseif($wanted -is [string]){if($actual -isnot [string] -or -not [string]::Equals($actual,$wanted,[StringComparison]::Ordinal)){throw 'CSV_SELECT_RESULT_TEXT'}}
   elseif($wanted -is [long]){if($actual -isnot [long] -or $actual -ne $wanted){throw 'CSV_SELECT_RESULT_BIGINT'}}
   elseif($wanted -is [int]){if($actual -isnot [int] -or $actual -ne $wanted){throw 'CSV_SELECT_RESULT_INT'}}
   else{throw 'CSV_SELECT_EXPECTATION_TYPE'}
  }
 }
}

function Invoke-CsvDirectSelectPhase {
 param($Connection,[string]$Sql,[ValidateRange(0,7)][int]$Phase)
 $expected=Get-CsvDirectSelectCase $Phase
 $command=$Connection.CreateCommand();$command.CommandTimeout=Get-CsvCommandTimeout -Maximum 300;$command.CommandText=$Sql
 $reader=$null;$sets=0;$schema=@();$rows=[Collections.Generic.List[object]]::new();$caughtExpected=$false
 try{
  $reader=$command.ExecuteReader()
  do{
   Assert-CsvReadBudget $command
   if($reader.FieldCount -gt 0){
    $sets++;$schema=@(for($column=0;$column -lt $reader.FieldCount;$column++){
     [pscustomobject]@{Name=$reader.GetName($column);SqlType=$reader.GetDataTypeName($column);ClrType=$reader.GetFieldType($column).FullName}
    })
   }
   while($reader.Read()){
    Assert-CsvReadBudget $command
    if($expected.ErrorNumber -ne 0 -or $rows.Count -ge $expected.Rows.Count){throw 'CSV_SELECT_UNEXPECTED_ROW'}
    $values=@(for($column=0;$column -lt $reader.FieldCount;$column++){$reader.GetValue($column)})
    $rows.Add([pscustomobject]@{Values=$values})
   }
   Assert-CsvReadBudget $command
  }while($reader.NextResult())
 }catch{
  $sqlError=$null;$cursor=$_.Exception
  while($null -ne $cursor){if($cursor -is [Data.SqlClient.SqlException]){$sqlError=$cursor};$cursor=$cursor.InnerException}
  if($expected.ErrorNumber -eq 0 -or $null -eq $sqlError -or $sqlError.Number -ne $expected.ErrorNumber -or $sqlError.State -ne $expected.ErrorState){throw}
  if($sets -ne 0 -or $rows.Count -ne 0){throw 'CSV_SELECT_ERROR_AFTER_RESULT'}
  $caughtExpected=$true
 }finally{
  if($null -ne $reader){$reader.Dispose()}
  $command.Dispose()
 }
 if($expected.ErrorNumber -ne 0){
  if(-not $caughtExpected){throw 'CSV_SELECT_EXPECTED_ERROR_MISSING'}
 }else{
  if($sets -ne 1){throw 'CSV_SELECT_RESULTSET_COUNT'}
  Assert-CsvDirectSelectRows $schema $rows.ToArray() $expected
 }
 return [int]1
}
