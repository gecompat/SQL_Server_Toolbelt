[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[string]$ToolbeltDatabase='',
 [scriptblock]$CommandTimeoutProvider,[scriptblock]$ReadBudgetProvider)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Connection.State -ne [Data.ConnectionState]::Open){throw 'CSV_METADATA_OPEN_CONNECTION_REQUIRED'}
$prefix='toolbelt_file.'
if($ToolbeltDatabase){$prefix='['+$ToolbeltDatabase.Replace(']',']]')+'].toolbelt_file.'}
$script:CsvClientPhase='SETUP'
function Assert-CsvClient([bool]$Condition,[string]$Label=''){
 if(-not $Condition){
  # Nur feste Prüflabels und lokale Aufrufzeilen; keine tatsächlichen Metadaten oder Payloads.
  if(-not $Label){$Label=$script:CsvClientPhase+'_ASSERT_LINE_'+$MyInvocation.ScriptLineNumber}
  throw ('CSV_CLIENT_CONTRACT_ORACLE_'+$Label.ToUpperInvariant())
 }
}
function New-CsvCommand([string]$Sql){
 $cmd=$Connection.CreateCommand();$cmd.CommandText=$Sql;$cmd.CommandTimeout=30
 if($CommandTimeoutProvider){$cmd.CommandTimeout=& $CommandTimeoutProvider}
 return $cmd
}
function Test-CsvReadBudget($Command){if($ReadBudgetProvider){& $ReadBudgetProvider $Command}}
function Assert-CsvFields($Reader,[string[]]$Names,[string[]]$Types,[bool[]]$Nullable,[string]$Context){
 Assert-CsvClient ($Reader.FieldCount -eq $Names.Count) ($Context+'_FIELD_COUNT')
 $schema=$Reader.GetSchemaTable();Assert-CsvClient ($schema.Rows.Count -eq $Names.Count) ($Context+'_SCHEMA_COUNT')
 for($index=0;$index-lt$Names.Count;$index++){
  Assert-CsvClient ($Reader.GetName($index) -ceq $Names[$index] -and $Reader.GetDataTypeName($index) -ceq $Types[$index]) ($Context+'_NAME_TYPE_FIELD_'+$index)
  Assert-CsvClient ([bool]$schema.Rows[$index]['AllowDBNull'] -eq $Nullable[$index]) ($Context+'_NULLABILITY_FIELD_'+$index)
 }
}
$numbers=[Collections.Generic.List[int]]::new()
$handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$eventArgs) foreach($info in $eventArgs.Errors){if($numbers.Count -ge 64){throw 'CSV_CLIENT_MESSAGE_LIMIT'};[void]$numbers.Add([int]$info.Number)}}
$Connection.add_InfoMessage($handler)
try{
 # Beide Help-Pfade mit ausdrücklich ungültigen Fachparametern, fehlendem Ziel und Debug255.
 foreach($name in @('USP_ParseCsv','USP_WriteCsv')){
  $script:CsvClientPhase='HELP_'+$name
  $numbers.Clear()
  $sql='EXEC '+$prefix+$name+' @Separator=NULL,@HasHeader=NULL,@MaxRows=NULL,@ResultTable=N''#MissingCsvHelpTarget'',@KeepData=1,@Debug=255,@Hilfe=1;'
  $cmd=New-CsvCommand $sql
  try{
   $reader=$cmd.ExecuteReader()
   try{
    $names=@('HelpContractVersion','SchemaName','ObjectName','Section','Ordinal','ItemName','SqlDataType','IsRequired','IsNullable','DefaultValue','Description','ExampleSql')
    $types=@('varchar','nvarchar','nvarchar','varchar','int','nvarchar','varchar','bit','bit','nvarchar','nvarchar','nvarchar')
    $nullable=@($false,$false,$false,$false,$false,$true,$true,$true,$true,$true,$false,$true)
    Assert-CsvFields $reader $names $types $nullable ('HELP_'+$name)
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $parameters=[Collections.Generic.List[string]]::new()
    $rows=0
    while($true){
     Test-CsvReadBudget $cmd
     if(-not $reader.Read()){break}
     $rows++;Assert-CsvClient ($rows -le 64)
     Assert-CsvClient ($reader.GetString(0) -ceq '1.0' -and $reader.GetString(1) -ceq 'toolbelt_file' -and $reader.GetString(2) -ceq $name)
     $section=$reader.GetString(3);[void]$seen.Add($section)
     if($section -ceq 'PARAMETER'){[void]$parameters.Add($reader.GetString(5))}
    }
    foreach($section in @('DESCRIPTION','PARAMETER','RESULT_COLUMN','EXAMPLE')){Assert-CsvClient ($seen.Contains($section))}
    $expected=if($name -ceq 'USP_ParseCsv'){@('@Text','@Separator','@HasHeader','@NullToken','@MaxRows','@MaxColumns','@MaxCells','@MaxInputBytes','@ResultTable','@KeepData','@Debug','@Hilfe')}else{@('@CellsTable','@Separator','@HasHeader','@NullToken','@LineEnding','@MaxRows','@MaxColumns','@MaxCells','@MaxValueBytes','@MaxOutputBytes','@ResultTable','@KeepData','@Debug','@Hilfe')}
    Assert-CsvClient (($parameters -join '|') -ceq ($expected -join '|'))
    Test-CsvReadBudget $cmd;Assert-CsvClient (-not $reader.NextResult())
    Assert-CsvClient ($numbers.Count -eq 0)
   }finally{$reader.Dispose()}
  }finally{$cmd.Dispose()}
 }
 $numbers.Clear()
 $script:CsvClientPhase='PARSE'
 $cmd=New-CsvCommand ('EXEC '+$prefix+'USP_ParseCsv @Text=N''a,b'',@Debug=1;')
 try{
  $reader=$cmd.ExecuteReader()
  try{
   Assert-CsvFields $reader @('RowKind','RowOrdinal','ColumnOrdinal','Value') @('varchar','bigint','int','nvarchar') @($false,$false,$false,$true) 'PARSE'
   for($column=1;$column-le2;$column++){
    Test-CsvReadBudget $cmd;Assert-CsvClient ($reader.Read())
    Assert-CsvClient ($reader.GetString(0) -ceq 'DATA' -and $reader.GetInt64(1) -eq 1 -and $reader.GetInt32(2) -eq $column)
    Assert-CsvClient ($reader.GetString(3) -ceq $(if($column-eq1){'a'}else{'b'}))
   }
   Test-CsvReadBudget $cmd;Assert-CsvClient (-not $reader.Read());Assert-CsvClient (-not $reader.NextResult())
   Assert-CsvClient ($numbers.Count -gt 0)
  }finally{$reader.Dispose()}
 }finally{$cmd.Dispose()}
 # Eigene Source/Resulttemps in derselben Caller-Session; keine fremden Datenbanken lesen.
 $cmd=New-CsvCommand @'
CREATE TABLE #CsvClientCells(RowKind varchar(6) NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) NULL);
INSERT #CsvClientCells VALUES('DATA',1,1,N'x');
CREATE TABLE #CsvClientResult(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
'@
 try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
 try{
  $script:CsvClientPhase='WRITE'
  $cmd=New-CsvCommand ('EXEC '+$prefix+'USP_WriteCsv @CellsTable=N''#CsvClientCells'';')
  try{
   $reader=$cmd.ExecuteReader()
   try{
    Assert-CsvFields $reader @('CsvText','DataRows','ColumnCount') @('nvarchar','bigint','int') @($false,$false,$false) 'WRITE'
    Test-CsvReadBudget $cmd;Assert-CsvClient ($reader.Read())
    Assert-CsvClient ($reader.GetSqlChars(0).Length -eq 3 -and $reader.GetString(0) -ceq ('x'+[char]13+[char]10) -and $reader.GetInt64(1) -eq 1 -and $reader.GetInt32(2) -eq 1)
    Test-CsvReadBudget $cmd;Assert-CsvClient (-not $reader.Read());Assert-CsvClient (-not $reader.NextResult())
   }finally{$reader.Dispose()}
  }finally{$cmd.Dispose()}
  $script:CsvClientPhase='WRITE_RESULT_TABLE'
  $cmd=New-CsvCommand ('EXEC '+$prefix+'USP_WriteCsv @CellsTable=N''#CsvClientCells'',@ResultTable=N''#CsvClientResult'';')
  try{
   $reader=$cmd.ExecuteReader()
   try{
    Test-CsvReadBudget $cmd
    Assert-CsvClient ($reader.FieldCount -eq 0 -and -not $reader.Read() -and -not $reader.NextResult())
   }finally{$reader.Dispose()}
  }finally{$cmd.Dispose()}
 }finally{
  $cmd=New-CsvCommand 'DROP TABLE #CsvClientResult;DROP TABLE #CsvClientCells;'
  try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
 }
}finally{$Connection.remove_InfoMessage($handler)}
Write-Output 'PASS: CSV SQLClient names/types/nullability, Help bypass, Debug messages and ResultTable-only routing.'
