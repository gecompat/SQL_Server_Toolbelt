[CmdletBinding()]
param([Parameter(Mandatory)][string]$Database)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Zugangsdaten ausschließlich prozessgebunden; keine Ausgabe von Server/Connectionstring.
$builder=[System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source']="tcp:$($env:TBX_SQL_HOST),$($env:TBX_SQL_PORT)"
$builder['Initial Catalog']=$Database
$builder['User ID']=$env:TBX_SQL_USER
$builder['Password']=$env:TBX_SQL_PASSWORD
$builder['Encrypt']=$true
$builder['TrustServerCertificate']=$true
$builder['Connect Timeout']=15
$builder['Pooling']=$false
$connection=[System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$messages=[System.Collections.Generic.List[string]]::new()
$connection.add_InfoMessage({param($sender,$event) $messages.Add($event.Message)}.GetNewClosure())
try {
 $connection.Open()
 foreach($api in @('USP_JsonArray','USP_JsonObject','USP_JsonArraysByGroup','USP_JsonObjectsByGroup')) {
  $grouped=$api -in @('USP_JsonArraysByGroup','USP_JsonObjectsByGroup')
  $object=$api -in @('USP_JsonObject','USP_JsonObjectsByGroup')
  foreach($empty in @($true,$false)) {
   $command=$connection.CreateCommand();$command.CommandTimeout=180
   $command.CommandText="CREATE TABLE #MetadataInput(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));"
   if(-not $empty){$command.CommandText+="INSERT #MetadataInput VALUES(9,1,N'key',N'null',NULL);"}
   $command.CommandText+="EXEC toolbelt_json.$api @EntriesTable=N'#MetadataInput',@Debug=2; DROP TABLE #MetadataInput;"
   $reader=$command.ExecuteReader()
   try {
    $schema=$reader.GetSchemaTable()
    $jsonOrdinal=if($grouped){1}else{0}
    if($grouped -and ($reader.GetName(0)-cne 'GroupOrdinal' -or $reader.GetDataTypeName(0)-cne 'int' -or $schema.Rows[0].AllowDBNull)){throw 'JSON GroupOrdinal metadata wrong.'}
    if($reader.FieldCount-ne ($jsonOrdinal+1) -or $reader.GetName($jsonOrdinal)-cne 'JsonValue' -or $reader.GetDataTypeName($jsonOrdinal)-cne 'nvarchar' -or $schema.Rows[$jsonOrdinal].AllowDBNull -or $schema.Rows[$jsonOrdinal].ColumnSize-ne [int]::MaxValue){throw 'JSON SELECT metadata contract wrong.'}
    if($grouped -and $empty){if($reader.Read() -or $reader.NextResult()){throw 'Empty grouped SELECT emitted rows/resultsets.'}}
    else {
     if(-not $reader.Read() -or $reader.IsDBNull($jsonOrdinal)){throw 'JSON SELECT row missing/NULL.'}
     $expected=if($object){if($empty){'{}'}else{'{"key":null}'}}else{if($empty){'[]'}else{'[null]'}}
     if($grouped -and $reader.GetInt32(0)-ne 9){throw 'JSON GroupOrdinal value wrong.'}
     if($reader.GetString($jsonOrdinal)-cne $expected -or $reader.Read() -or $reader.NextResult()){throw 'JSON SELECT values/resultsets wrong.'}
    }
   } finally {$reader.Dispose();$command.Dispose()}
  }
  $messages.Clear()
  $command=$connection.CreateCommand();$command.CommandText="CREATE TABLE #tbx_JsonConstructor_GroupResult(SyntheticForeign int); EXEC toolbelt_json.$api @Hilfe=1,@EntriesTable=N'##missing',@MaxEntries=0,@ResultTable=N'invalid',@Debug=255; DROP TABLE #tbx_JsonConstructor_GroupResult;"
  $reader=$command.ExecuteReader()
  try {
   if($reader.FieldCount-ne 12){throw 'JSON Help shape wrong.'}
   $expectedNames=@('HelpContractVersion','SchemaName','ObjectName','Section','Ordinal','ItemName','SqlDataType','IsRequired','IsNullable','DefaultValue','Description','ExampleSql')
   $expectedTypes=@('varchar','nvarchar','nvarchar','varchar','int','nvarchar','varchar','bit','bit','nvarchar','nvarchar','nvarchar')
   for($i=0;$i-lt 12;$i++){if($reader.GetName($i)-cne $expectedNames[$i] -or $reader.GetDataTypeName($i)-cne $expectedTypes[$i]){throw 'JSON Help metadata type/order wrong.'}}
   $defaults=@('NULL','10000','2097152','2097152','NULL','0','0','0')
   $parameterCount=0
   while($reader.Read()){
    if($reader.GetString(3)-ceq 'PARAMETER'){
     $ordinal=$reader.GetInt32(4)
     if($ordinal-lt 1 -or $ordinal-gt 8 -or $reader.IsDBNull(9) -or $reader.GetString(9)-cne $defaults[$ordinal-1]){throw 'JSON Help default contract wrong.'}
     $parameterCount++
    }
   }
   if($parameterCount-ne 8){throw 'JSON Help parameter inventory wrong.'}
   if($reader.NextResult()-or $messages.Count-ne 0){throw 'JSON Help emitted extra output.'}
  } finally {$reader.Dispose();$command.Dispose()}
  $command=$connection.CreateCommand()
  $command.CommandText="CREATE TABLE #MetadataInput(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max)); CREATE TABLE #MetadataOutput(Dummy int); EXEC toolbelt_json.$api @EntriesTable=N'#MetadataInput',@ResultTable=N'#MetadataOutput',@Debug=2; DROP TABLE #MetadataInput; DROP TABLE #MetadataOutput;"
  $reader=$command.ExecuteReader()
  try {if($reader.FieldCount-ne 0 -or $reader.NextResult()){throw 'JSON ResultTable emitted SELECT.'}}
  finally {$reader.Dispose();$command.Dispose()}
 }
 Write-Output 'JSON client metadata/help/resultset contracts: PASS'
} finally {try {$connection.Dispose()} finally {$builder.Clear()}}
