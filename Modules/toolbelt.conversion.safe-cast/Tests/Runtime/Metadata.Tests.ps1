[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[string]$ToolbeltDatabase='',
 [scriptblock]$CommandTimeoutProvider,[scriptblock]$ReadBudgetProvider)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Connection.State -ne [Data.ConnectionState]::Open){throw 'SAFE_CAST_METADATA_OPEN_CONNECTION_REQUIRED'}
$database=if($ToolbeltDatabase){'['+$ToolbeltDatabase.Replace(']',']]')+'].'}else{''}
$prefix=$database+'toolbelt_conversion.'
function Assert-SafeCastClient([bool]$Condition,[string]$Label){
 if(-not $Condition){throw ('SAFE_CAST_CLIENT_ORACLE_'+$Label)}
}
function New-SafeCastCommand([string]$Sql){
 $command=$Connection.CreateCommand();$command.CommandText=$Sql;$command.CommandTimeout=30
 if($CommandTimeoutProvider){$command.CommandTimeout=& $CommandTimeoutProvider}
 return $command
}
function Test-SafeCastBudget($Command){if($ReadBudgetProvider){& $ReadBudgetProvider $Command}}
$specs=@(
 @{Name='BigInt';SqlType='bigint';Managed=[long];Text='1';TypeId=127;Length=8;Precision=19;Scale=0},
 @{Name='Decimal';SqlType='decimal';Managed=[decimal];Text='1.25';TypeId=106;Length=17;Precision=38;Scale=18},
 @{Name='Date';SqlType='date';Managed=[datetime];Text='2024-02-29';TypeId=40;Length=3;Precision=10;Scale=0},
 @{Name='DateTime2';SqlType='datetime2';Managed=[datetime];Text='2024-02-29T01:02:03.1234567';TypeId=42;Length=8;Precision=27;Scale=7},
 @{Name='Bit';SqlType='bit';Managed=[bool];Text='1';TypeId=104;Length=1;Precision=1;Scale=0},
 @{Name='UniqueIdentifier';SqlType='uniqueidentifier';Managed=[guid];Text='abcdef01-2345-6789-abcd-ef0123456789';TypeId=36;Length=16;Precision=0;Scale=0}
)
foreach($spec in $specs){
 $name='TVF_TryCast'+$spec.Name
 # Catalog- und Clientmetadaten sind getrennte Oracles; T-SQL-Defaults stehen in definition.
 $sql=@'
SELECT o.type,m.is_schema_bound,m.definition,
 (SELECT COUNT(*) FROM DBPREFIXsys.parameters p WHERE p.object_id=o.object_id) AS ParameterCount,
 (SELECT COUNT(*) FROM DBPREFIXsys.columns c WHERE c.object_id=o.object_id) AS ColumnCount
FROM DBPREFIXsys.objects o JOIN DBPREFIXsys.schemas s ON s.schema_id=o.schema_id
JOIN DBPREFIXsys.sql_modules m ON m.object_id=o.object_id
WHERE s.name=N'toolbelt_conversion' AND o.name=@Name;
SELECT parameter_id,name,system_type_id,user_type_id,max_length,is_output
FROM DBPREFIXsys.parameters WHERE object_id=(
 SELECT o.object_id FROM DBPREFIXsys.objects o JOIN DBPREFIXsys.schemas s ON s.schema_id=o.schema_id
 WHERE s.name=N'toolbelt_conversion' AND o.name=@Name) ORDER BY parameter_id;
SELECT column_id,name,system_type_id,user_type_id,max_length,precision,scale,is_nullable,collation_name
FROM DBPREFIXsys.columns WHERE object_id=(
 SELECT o.object_id FROM DBPREFIXsys.objects o JOIN DBPREFIXsys.schemas s ON s.schema_id=o.schema_id
 WHERE s.name=N'toolbelt_conversion' AND o.name=@Name) ORDER BY column_id;
'@
 $cmd=New-SafeCastCommand ($sql.Replace('DBPREFIX',$database))
 [void]$cmd.Parameters.Add('@Name',[Data.SqlDbType]::NVarChar,128);$cmd.Parameters['@Name'].Value=$name
 try{
  $reader=$cmd.ExecuteReader()
  try{
   Test-SafeCastBudget $cmd
   Assert-SafeCastClient ($reader.Read()) 'CATALOG_MISSING'
   Assert-SafeCastClient ($reader.GetString(0).TrimEnd() -ceq 'IF' -and $reader.GetBoolean(1) -and $reader.GetInt32(3)-eq2 -and $reader.GetInt32(4)-eq3) 'CATALOG_SHAPE'
   Assert-SafeCastClient ($reader.GetString(2) -match '@MaxInputBytes\s+int\s*=\s*8192\b') 'DEFAULT'
   Assert-SafeCastClient (-not $reader.Read()) 'CATALOG_DUPLICATE'
   Assert-SafeCastClient ($reader.NextResult()) 'PARAMETERS_MISSING'
   foreach($index in 1,2){
    Assert-SafeCastClient ($reader.Read()) 'PARAMETER_MISSING'
    $expectedName=if($index-eq1){'@Text'}else{'@MaxInputBytes'}
    $expectedType=if($index-eq1){231}else{56};$expectedLength=if($index-eq1){-1}else{4}
    Assert-SafeCastClient ($reader.GetInt32(0)-eq$index -and $reader.GetString(1)-ceq$expectedName -and $reader.GetByte(2)-eq$expectedType -and $reader.GetInt32(3)-eq$expectedType -and $reader.GetInt16(4)-eq$expectedLength -and -not $reader.GetBoolean(5)) 'PARAMETER_TYPE_ORDER'
   }
   Assert-SafeCastClient (-not $reader.Read()) 'PARAMETER_EXTRA'
   Assert-SafeCastClient ($reader.NextResult()) 'COLUMNS_MISSING'
   for($index=0;$index-lt3;$index++){
    Assert-SafeCastClient ($reader.Read()) 'COLUMN_MISSING'
    $columnName=@('Value','Status','ErrorCode')[$index]
    $type=if($index-eq0){$spec.TypeId}else{167};$length=if($index-eq0){$spec.Length}elseif($index-eq1){16}else{32}
    Assert-SafeCastClient ($reader.GetInt32(0)-eq($index+1) -and $reader.GetString(1)-ceq$columnName -and $reader.GetByte(2)-eq$type -and $reader.GetInt32(3)-eq$type -and $reader.GetInt16(4)-eq$length -and $reader.GetBoolean(7)-eq($index-ne1)) 'COLUMN_TYPE_NULLABILITY'
    if($index-eq0){Assert-SafeCastClient ($reader.GetByte(5)-eq$spec.Precision -and $reader.GetByte(6)-eq$spec.Scale) 'VALUE_PRECISION_SCALE'}
    else{Assert-SafeCastClient ($reader.GetString(8)-ceq'Latin1_General_100_BIN2') 'TEXT_COLLATION'}
   }
   Assert-SafeCastClient (-not $reader.Read() -and -not $reader.NextResult()) 'CATALOG_EXTRA'
  }finally{$reader.Dispose()}
 }finally{$cmd.Dispose()}
 foreach($scenario in @('OK','SQL_NULL','INVALID_ARGUMENT')){
  $cmd=New-SafeCastCommand ('SELECT Value,Status,ErrorCode FROM '+$prefix+$name+'(@Text,'+$(if($scenario-ceq'INVALID_ARGUMENT'){'0'}else{'DEFAULT'})+');')
  [void]$cmd.Parameters.Add('@Text',[Data.SqlDbType]::NVarChar,-1)
  $cmd.Parameters['@Text'].Value=if($scenario-ceq'SQL_NULL'){[DBNull]::Value}else{$spec.Text}
  try{
   $reader=$cmd.ExecuteReader()
   try{
    Assert-SafeCastClient ($reader.FieldCount-eq3) 'CLIENT_FIELD_COUNT'
    $schema=$reader.GetSchemaTable()
    for($index=0;$index-lt3;$index++){
     Assert-SafeCastClient ($reader.GetName($index)-ceq@('Value','Status','ErrorCode')[$index]) 'CLIENT_NAMES'
     $sqlType=if($index-eq0){$spec.SqlType}else{'varchar'}
     Assert-SafeCastClient ($reader.GetDataTypeName($index)-ceq$sqlType -and [bool]$schema.Rows[$index]['AllowDBNull']-eq($index-ne1)) 'CLIENT_TYPE_NULLABILITY'
     if($index-gt0){Assert-SafeCastClient ([int]$schema.Rows[$index]['ColumnSize']-eq$(if($index-eq1){16}else{32})) 'CLIENT_TEXT_LENGTH'}
    }
    Assert-SafeCastClient ($reader.GetFieldType(0)-eq$spec.Managed) 'CLIENT_MANAGED_TYPE'
    Test-SafeCastBudget $cmd;Assert-SafeCastClient ($reader.Read()) 'CLIENT_ROW_MISSING'
    Assert-SafeCastClient ($reader.GetString(1)-ceq$scenario -and $reader.IsDBNull(0)-eq($scenario-cne'OK') -and $reader.IsDBNull(2)-eq($scenario-cne'INVALID_ARGUMENT')) 'CLIENT_VALUE_STATUS'
    if($scenario-ceq'INVALID_ARGUMENT'){Assert-SafeCastClient ($reader.GetString(2)-ceq'PARAMETER') 'CLIENT_CODE'}
    Test-SafeCastBudget $cmd;Assert-SafeCastClient (-not $reader.Read() -and -not $reader.NextResult()) 'CLIENT_EXTRA'
   }finally{$reader.Dispose()}
  }finally{$cmd.Dispose()}
 }
}
Write-Output 'PASS: Safe Cast client metadata; six functions, catalog and 18 direct result readers.'
