param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$expectedNames=@('RowKind','ErrorOrdinal','Status','Profile','IsValid','DocumentPointer','SchemaPointer','Keyword','ErrorCode','ErrorsTruncated')
$expectedTypes=@('varchar','int','varchar','varchar','bit','nvarchar','nvarchar','nvarchar','varchar','bit')
$command=$Connection.CreateCommand();$command.CommandText='toolbelt_json.USP_ValidateJsonSchema';$command.CommandType=[Data.CommandType]::StoredProcedure;$command.CommandTimeout=30
[void]$command.Parameters.Add('@Json',[Data.SqlDbType]::NVarChar,-1);$command.Parameters['@Json'].Value='{"quantity":0}'
[void]$command.Parameters.Add('@Schema',[Data.SqlDbType]::NVarChar,-1);$command.Parameters['@Schema'].Value='{"properties":{"quantity":{"minimum":1}}}'
$reader=$null
try{
 $reader=$command.ExecuteReader()
 if($reader.FieldCount -ne 10){throw 'SCHEMA_NATIVE_METADATA_COLUMNS'}
 for($ordinal=0;$ordinal-lt10;$ordinal++){
  if($reader.GetName($ordinal)-cne$expectedNames[$ordinal]-or$reader.GetDataTypeName($ordinal)-cne$expectedTypes[$ordinal]){throw 'SCHEMA_NATIVE_METADATA_TYPES'}
 }
 $count=0
 while($reader.Read()){
  if($reader.GetInt32(1)-ne$count-or$reader.GetString(2)-cne'INVALID_INSTANCE'-or$reader.GetBoolean(4)){throw 'SCHEMA_NATIVE_METADATA_ROWS'}
  if($count-eq0-and$reader.GetString(0)-cne'SUMMARY'){throw 'SCHEMA_NATIVE_METADATA_SUMMARY'}
  if($count-eq1-and($reader.GetString(0)-cne'ERROR'-or$reader.GetString(5)-cne'/quantity'-or$reader.GetString(6)-cne'/properties/quantity/minimum')){throw 'SCHEMA_NATIVE_METADATA_POINTER'}
  $count++
 }
 if($count-ne2-or$reader.NextResult()){throw 'SCHEMA_NATIVE_METADATA_RESULTSETS'}
 'PASS JSON_SCHEMA_NATIVE_CLIENT_METADATA'
}finally{if($reader){$reader.Dispose()};$command.Dispose()}
