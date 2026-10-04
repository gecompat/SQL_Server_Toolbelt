[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[string]$ToolbeltDatabase,
 [scriptblock]$CommandTimeoutProvider,[scriptblock]$ReadBudgetProvider)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Connection.State -ne [Data.ConnectionState]::Open){throw 'DISPLAY_METADATA_CONNECTION_REQUIRED'}
$prefix='toolbelt_file.'
if($ToolbeltDatabase){$prefix='['+$ToolbeltDatabase.Replace(']',']]')+'].toolbelt_file.'}
function Assert-DisplayMetadata([bool]$Value){if(-not $Value){throw 'XLSX_DISPLAY_METADATA_ORACLE'}}
$command=$Connection.CreateCommand();$command.CommandTimeout=60
try{
 foreach($case in @(@{Sql='DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT,DEFAULT';Status=1;Length=-1},
  @{Sql="N'n',1,N'0.00000000000000000000000000000000000001',NULL,NULL,N'0.00E+00',NULL,N'en-US'";Status=0;Length=8},
  @{Sql="N's',1,N'0',REPLICATE(CONVERT(nvarchar(max),N'x'),32733),NULL,N'@',NULL,N'en-US'";Status=0;Length=32733})){
  $command.CommandText='SELECT * FROM '+$prefix+'TVF_FormatXlsxCell('+$case.Sql+');'
  if($CommandTimeoutProvider){$command.CommandTimeout=& $CommandTimeoutProvider}
  $reader=$command.ExecuteReader()
  try{
   Assert-DisplayMetadata ($reader.FieldCount -eq 2)
   Assert-DisplayMetadata ($reader.GetName(0) -ceq 'DisplayText' -and $reader.GetDataTypeName(0) -ceq 'nvarchar')
   Assert-DisplayMetadata ($reader.GetName(1) -ceq 'StatusCode' -and $reader.GetDataTypeName(1) -ceq 'int')
   if($ReadBudgetProvider){& $ReadBudgetProvider $command}
   Assert-DisplayMetadata ($reader.Read() -and -not $reader.IsDBNull(1) -and $reader.GetInt32(1) -eq $case.Status)
   if($case.Length -eq -1){Assert-DisplayMetadata ($reader.IsDBNull(0))}
   else{Assert-DisplayMetadata (-not $reader.IsDBNull(0) -and $reader.GetSqlChars(0).Length -eq $case.Length)}
   Assert-DisplayMetadata (-not $reader.Read());Assert-DisplayMetadata (-not $reader.NextResult())
   if($ReadBudgetProvider){& $ReadBudgetProvider $command}
  }finally{$reader.Dispose()}
 }
}finally{$command.Dispose()}
Write-Output 'PASS: Display names/types/default NULL and nontruncated SqlChars; catalog nullability separately.'
