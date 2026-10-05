[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[string]$ToolbeltDatabase='',
 [scriptblock]$CommandTimeoutProvider,[scriptblock]$ReadBudgetProvider)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Connection.State-ne[Data.ConnectionState]::Open){throw 'JSON_POINTER_METADATA_OPEN_CONNECTION_REQUIRED'}
$database=if($ToolbeltDatabase){'['+$ToolbeltDatabase.Replace(']',']]')+'].'}else{''}
function Assert-PointerClient([bool]$Condition,[string]$Label){if(-not$Condition){throw ('JSON_POINTER_CLIENT_ORACLE_'+$Label)}}
function New-PointerCommand([string]$Sql){
 $command=$Connection.CreateCommand();$command.CommandText=$Sql;$command.CommandTimeout=30
 if($CommandTimeoutProvider){$command.CommandTimeout=& $CommandTimeoutProvider}
 if($command.CommandTimeout-lt1-or$command.CommandTimeout-gt60){$command.Dispose();throw 'JSON_POINTER_CLIENT_TIMEOUT_INVALID'}
 return $command
}
function Test-PointerBudget($Command){if($ReadBudgetProvider){& $ReadBudgetProvider $Command}}
$sql=@'
SELECT o.type,m.definition,
 (SELECT COUNT(*) FROM DBPREFIXsys.parameters WHERE object_id=o.object_id) ParameterCount,
 (SELECT COUNT(*) FROM DBPREFIXsys.columns WHERE object_id=o.object_id) ColumnCount
FROM DBPREFIXsys.objects o JOIN DBPREFIXsys.schemas s ON s.schema_id=o.schema_id
 JOIN DBPREFIXsys.sql_modules m ON m.object_id=o.object_id
WHERE s.name=N'toolbelt_json' AND o.name=N'TVF_ResolveJsonPointer';
SELECT parameter_id,name,system_type_id,user_type_id,max_length,is_output FROM DBPREFIXsys.parameters
 WHERE object_id=(SELECT o.object_id FROM DBPREFIXsys.objects o JOIN DBPREFIXsys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_json' AND o.name=N'TVF_ResolveJsonPointer') ORDER BY parameter_id;
SELECT column_id,name,system_type_id,user_type_id,max_length,is_nullable,collation_name FROM DBPREFIXsys.columns
 WHERE object_id=(SELECT o.object_id FROM DBPREFIXsys.objects o JOIN DBPREFIXsys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_json' AND o.name=N'TVF_ResolveJsonPointer') ORDER BY column_id;
'@
$cmd=New-PointerCommand ($sql.Replace('DBPREFIX',$database))
try{
 $reader=$cmd.ExecuteReader()
 try{
  Test-PointerBudget $cmd;Assert-PointerClient ($reader.Read()) 'CATALOG_MISSING'
  Assert-PointerClient ($reader.GetString(0).TrimEnd()-ceq'TF'-and$reader.GetInt32(2)-eq4-and$reader.GetInt32(3)-eq4) 'CATALOG_SHAPE'
  Assert-PointerClient ($reader.GetString(1)-match'@MaxInputBytes\s+bigint\s*=\s*16777216\b'-and$reader.GetString(1)-match'@MaxDepth\s+int\s*=\s*128\b') 'DEFAULTS'
  Test-PointerBudget $cmd;Assert-PointerClient (-not$reader.Read()-and$reader.NextResult()) 'PARAMETERS_BEGIN'
  for($index=0;$index-lt4;$index++){
   Test-PointerBudget $cmd;Assert-PointerClient ($reader.Read()) ('PARAMETER_MISSING_'+$index)
   $type=@(231,231,127,56)[$index];$length=@(-1,-1,8,4)[$index]
   Assert-PointerClient ($reader.GetInt32(0)-eq($index+1)-and$reader.GetString(1)-ceq@('@Json','@Pointer','@MaxInputBytes','@MaxDepth')[$index]-and$reader.GetByte(2)-eq$type-and$reader.GetInt32(3)-eq$type-and$reader.GetInt16(4)-eq$length-and-not$reader.GetBoolean(5)) ('PARAMETER_SHAPE_'+$index)
  }
  Test-PointerBudget $cmd;Assert-PointerClient (-not$reader.Read()-and$reader.NextResult()) 'COLUMNS_BEGIN'
  for($index=0;$index-lt4;$index++){
   Test-PointerBudget $cmd;Assert-PointerClient ($reader.Read()) ('COLUMN_MISSING_'+$index)
   $type=if($index-eq2){231}else{167};$length=@(16,8,-1,32)[$index]
   Assert-PointerClient ($reader.GetInt32(0)-eq($index+1)-and$reader.GetString(1)-ceq@('Status','JsonType','Value','ErrorCode')[$index]-and$reader.GetByte(2)-eq$type-and$reader.GetInt32(3)-eq$type-and$reader.GetInt16(4)-eq$length-and$reader.GetBoolean(5)-eq($index-ne0)-and$reader.GetString(6)-ceq'Latin1_General_100_BIN2') ('COLUMN_SHAPE_'+$index)
  }
  Test-PointerBudget $cmd;Assert-PointerClient (-not$reader.Read()-and-not$reader.NextResult()) 'CATALOG_EXTRA'
 }finally{$reader.Dispose()}
}finally{$cmd.Dispose()}
$scenarios=@(
 @{Json='""';Pointer='';Budget='DEFAULT';Status='FOUND';Type='STRING';Value='';Code=$null},
 @{Json='null';Pointer='';Budget='DEFAULT';Status='JSON_NULL';Type='NULL';Value=$null;Code=$null},
 @{Json='{}';Pointer='/x';Budget='DEFAULT';Status='MISSING';Type=$null;Value=$null;Code=$null},
 @{Json=$null;Pointer='';Budget='0';Status='SQL_NULL';Type=$null;Value=$null;Code=$null},
 @{Json='{}';Pointer='';Budget='0';Status='INVALID';Type=$null;Value=$null;Code='PARAMETER'}
)
foreach($scenario in $scenarios){
 $cmd=New-PointerCommand ('SELECT Status,JsonType,Value,ErrorCode FROM '+$database+'toolbelt_json.TVF_ResolveJsonPointer(@Json,@Pointer,'+$scenario.Budget+',DEFAULT);')
 [void]$cmd.Parameters.Add('@Json',[Data.SqlDbType]::NVarChar,-1);[void]$cmd.Parameters.Add('@Pointer',[Data.SqlDbType]::NVarChar,-1)
 $cmd.Parameters['@Json'].Value=if($null-eq$scenario.Json){[DBNull]::Value}else{$scenario.Json};$cmd.Parameters['@Pointer'].Value=$scenario.Pointer
 try{
  $reader=$cmd.ExecuteReader()
  try{
   Assert-PointerClient ($reader.FieldCount-eq4) 'RESULT_FIELD_COUNT';$schema=$reader.GetSchemaTable()
   for($index=0;$index-lt4;$index++){
    $type=if($index-eq2){'nvarchar'}else{'varchar'};$length=@(16,8,1073741823,32)[$index]
    Assert-PointerClient ($reader.GetName($index)-ceq@('Status','JsonType','Value','ErrorCode')[$index]-and$reader.GetDataTypeName($index)-ceq$type-and$reader.GetFieldType($index)-eq[string]-and[bool]$schema.Rows[$index]['AllowDBNull']-eq($index-ne0)) ('RESULT_METADATA_'+$index)
    if($index-ne2){Assert-PointerClient ([int]$schema.Rows[$index]['ColumnSize']-eq$length) ('RESULT_SIZE_'+$index)}
    else{Assert-PointerClient ([long]$schema.Rows[$index]['ColumnSize']-ge1073741823) 'RESULT_MAX_SIZE'}
   }
   Test-PointerBudget $cmd;Assert-PointerClient ($reader.Read()) 'RESULT_ROW_MISSING'
   $expected=@($scenario.Status,$scenario.Type,$scenario.Value,$scenario.Code)
   for($index=0;$index-lt4;$index++){
    Assert-PointerClient ($reader.IsDBNull($index)-eq($null-eq$expected[$index])) ('RESULT_NULL_'+$index)
    if($null-ne$expected[$index]){Assert-PointerClient ($reader.GetString($index)-ceq$expected[$index]) ('RESULT_VALUE_'+$index)}
   }
   Test-PointerBudget $cmd;Assert-PointerClient (-not$reader.Read()-and-not$reader.NextResult()) 'RESULT_EXTRA'
  }finally{$reader.Dispose()}
 }finally{$cmd.Dispose()}
}
Write-Output 'PASS: JSON Pointer catalog and five genuine client result readers.'
