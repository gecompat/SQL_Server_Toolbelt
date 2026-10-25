param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection)
# Öffentlicher maschinenlesbarer Vertrag als Soll; native Hostmetadaten als Ist.
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$api=Get-Content (Join-Path $moduleRoot 'Contracts/Api.json') -Raw|ConvertFrom-Json
$checks=0
function Assert([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_API_'+$Name)};$script:checks++}
function ExpectedLength([string]$Type){
 if($Type -eq 'sysname'){return 256};if($Type -match '\((max|\d+)\)') {if($Matches[1] -eq 'max'){return -1};$n=[int]$Matches[1];if($Type.StartsWith('n')){$n*=2};return $n}
 switch($Type){'bit'{1};'tinyint'{1};'smallint'{2};'int'{4};default{throw 'SSIS_API_UNKNOWN_EXPECTED_TYPE'}}
}
$q=$Connection.CreateCommand();$q.CommandText="SELECT p.name,t.name AS TypeName,p.max_length FROM sys.parameters p WITH(NOLOCK) JOIN sys.types t WITH(NOLOCK) ON t.user_type_id=p.user_type_id WHERE p.object_id=OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow') ORDER BY p.parameter_id;"
$table=[Data.DataTable]::new();$reader=$q.ExecuteReader();try{$table.Load($reader)}finally{$reader.Dispose();$q.Dispose()}
Assert ($table.Rows.Count -eq 14) 'PARAMETER_COUNT'
for($i=0;$i -lt $api.parameters.Count;$i++){
 $p=$api.parameters[$i];$row=$table.Rows[$i]
 Assert ([string]$row.name -ceq $p.name -and [string]$row.TypeName -ceq ($p.type.Split('(')[0]) -and $row.max_length -eq (ExpectedLength $p.type)) 'PARAMETER_NAME_TYPE_ORDER_LENGTH'
}
$cmd=$Connection.CreateCommand();$cmd.CommandType='StoredProcedure';$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow';$cmd.CommandTimeout=$(if(Get-Command Get-SsisNativeTimeout -ErrorAction SilentlyContinue){Get-SsisNativeTimeout 40}else{40})
[void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@PackageBytes'].Value=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
[void]$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32);$cmd.Parameters['@Operation'].Value='bindings-template'
$reader=$cmd.ExecuteReader()
try{
 $schema=$reader.GetSchemaTable();Assert ($reader.FieldCount -eq 13) 'RESULT_COUNT'
 for($i=0;$i -lt $api.columns.Count;$i++){
  $c=$api.columns[$i];$family=$c.type.Split('(')[0]
  Assert ($reader.GetName($i) -ceq $c.name -and $reader.GetDataTypeName($i) -ceq $family -and [bool]$schema.Rows[$i].AllowDBNull -eq [bool]$c.nullable) 'RESULT_NAME_TYPE_ORDER_NULLABILITY'
  if($c.type -match '\((\d+)\)'){Assert ([int]$schema.Rows[$i].ColumnSize -eq [int]$Matches[1]) 'RESULT_CHARACTER_WIDTH'}
 }
}finally{$reader.Dispose()}
$q=$Connection.CreateCommand();$q.CommandText='CREATE TABLE #SsisApiShape(Dummy int);';[void]$q.ExecuteNonQuery()
try{
 [void]$cmd.Parameters.Add('@ResultTable',[Data.SqlDbType]::NVarChar,128);$cmd.Parameters['@ResultTable'].Value='#SsisApiShape';[void]$cmd.ExecuteNonQuery()
 $q.CommandText="SELECT c.name,t.name AS TypeName,c.max_length,c.is_nullable,c.collation_name FROM tempdb.sys.columns c WITH(NOLOCK) JOIN tempdb.sys.types t WITH(NOLOCK) ON t.user_type_id=c.user_type_id WHERE c.object_id=OBJECT_ID(N'tempdb..#SsisApiShape') ORDER BY c.column_id;"
 $table=[Data.DataTable]::new();$r=$q.ExecuteReader();try{$table.Load($r)}finally{$r.Dispose()}
 Assert ($table.Rows.Count -eq 13) 'RESULT_TABLE_COUNT'
 for($i=0;$i -lt $api.columns.Count;$i++){
  $c=$api.columns[$i];$row=$table.Rows[$i]
  Assert ([string]$row.name -ceq $c.name -and [string]$row.TypeName -ceq $c.type.Split('(')[0] -and $row.max_length -eq (ExpectedLength $c.type) -and [bool]$row.is_nullable -eq [bool]$c.nullable) 'RESULT_TABLE_EXACT_SHAPE'
  if($c.type -match 'char'){Assert ([string]$row.collation_name -ceq 'Latin1_General_100_BIN2') 'RESULT_TABLE_COLLATION'}
 }
}finally{$q.CommandText='DROP TABLE #SsisApiShape;';[void]$q.ExecuteNonQuery();$q.Dispose();$cmd.Dispose()}
"SSIS_NATIVE_API_PASS $checks assertions"
