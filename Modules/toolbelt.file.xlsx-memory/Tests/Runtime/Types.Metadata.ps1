[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[string]$ToolbeltDatabase)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Connection.State -ne [Data.ConnectionState]::Open){throw 'METADATA_CONNECTION_REQUIRED'}
$prefix='toolbelt_file.'
if($ToolbeltDatabase){$prefix='['+$ToolbeltDatabase.Replace(']',']]')+'].toolbelt_file.'}
function Assert-TypeMetadata([bool]$Value){if(-not $Value){throw 'XLSX_TYPE_METADATA_ORACLE'}}
$command=$Connection.CreateCommand();$command.CommandTimeout=60
$command.CommandText='SELECT * FROM '+$prefix+'TVF_InterpretXlsxCell(DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT);'
try{
 $reader=$command.ExecuteReader()
 try{
  $names=@('StoredType','ValuePresent','RawValue','TextValue','EchoPreserved','ResolvedType','NumberValue','BooleanValue','DateValue','DateTimeValue','TimeValue','DurationTicks','TypedTextValue','StatusCode')
  $types=@('nvarchar','bit','nvarchar','nvarchar','bit','nvarchar','sql_variant','bit','date','datetime2','time','bigint','nvarchar','int')
  Assert-TypeMetadata ($reader.FieldCount -eq 14)
  for($i=0;$i -lt 14;$i++){Assert-TypeMetadata ($reader.GetName($i) -ceq $names[$i]);Assert-TypeMetadata ($reader.GetDataTypeName($i) -ceq $types[$i])}
  Assert-TypeMetadata ($reader.Read());Assert-TypeMetadata ($reader.GetInt32(13) -eq 1 -and $reader.GetBoolean(4))
  Assert-TypeMetadata (-not $reader.Read());Assert-TypeMetadata (-not $reader.NextResult())
 }finally{$reader.Dispose()}
 $command.CommandText='SELECT NumberValue,StatusCode FROM '+$prefix+"TVF_InterpretXlsxCell(N'n',1,N'0.00000000000000000000000000000000000001',NULL,NULL,NULL,NULL);"
 $reader=$command.ExecuteReader()
 try{
  Assert-TypeMetadata ($reader.Read() -and $reader.GetInt32(1) -eq 0)
  $number=$reader.GetSqlDecimal(0)
  Assert-TypeMetadata ($number.Precision -eq 38 -and $number.Scale -eq 38 -and $number.Data[0] -eq 1 -and $number.Data[1] -eq 0 -and $number.Data[2] -eq 0 -and $number.Data[3] -eq 0)
  Assert-TypeMetadata (-not $reader.Read());Assert-TypeMetadata (-not $reader.NextResult())
 }finally{$reader.Dispose()}
}finally{$command.Dispose()}
Write-Output 'PASS: Öffentliche XLSX-Typnamen/-typen, Default-NULL-Zeile und exaktes SqlDecimal1e-38; Nullability separat prüfen.'
