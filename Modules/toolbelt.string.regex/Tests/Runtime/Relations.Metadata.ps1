[CmdletBinding()]
param([Parameter(Mandatory)][string]$Database,[string]$ToolbeltDatabase=$Database)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
foreach($key in @('TBX_SQL_HOST','TBX_SQL_PORT','TBX_SQL_USER','TBX_SQL_PASSWORD')){
 if([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($key,'Process'))){throw 'SQLClient-Prozesskonfiguration fehlt.'}
}
$builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source']="tcp:$($env:TBX_SQL_HOST),$($env:TBX_SQL_PORT)"
$builder['Initial Catalog']=$Database
$builder['User ID']=$env:TBX_SQL_USER
$builder['Password']=$env:TBX_SQL_PASSWORD
$builder['Encrypt']=$true
$builder['TrustServerCertificate']=$true
$builder['Connect Timeout']=15
$connection=New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
$quoted='['+$ToolbeltDatabase.Replace(']',']]')+'].toolbelt_string.'
$messages=New-Object 'System.Collections.Generic.List[string]'
$connection.add_InfoMessage({param($sender,$eventArgs) $messages.Add('message')})
try {
 $connection.Open()
 foreach($case in @(
  @{Call="TVF_RegexMatches(N'a12 b3',N'[0-9]+',DEFAULT,DEFAULT,DEFAULT,DEFAULT)";Rows=2},
  @{Call="TVF_RegexSplit(N'a,,b,',N',',DEFAULT,DEFAULT,DEFAULT)";Rows=4},
  @{Call="TVF_RegexMatches(NULL,N'[',NULL,NULL,NULL,NULL)";Rows=0},
  @{Call="TVF_RegexSplit(N'',N'Z',DEFAULT,DEFAULT,DEFAULT)";Rows=1}
 )) {
  $command=$connection.CreateCommand();$command.CommandTimeout=120
  $command.CommandText='SELECT * FROM '+$quoted+$case.Call+' ORDER BY Ordinal;'
  $reader=$null
  try {
   $reader=$command.ExecuteReader();$schema=$reader.GetSchemaTable()
   if($reader.FieldCount -ne 4 -or $schema.Rows.Count -ne 4){throw 'Column count contract failed.'}
   $names=@('Ordinal','StartPosition','Length','Value');$types=@('bigint','bigint','bigint','nvarchar');$sizes=@(8,8,8,[int]::MaxValue)
   for($i=0;$i -lt 4;$i++) {
    if($reader.GetName($i) -cne $names[$i] -or $reader.GetDataTypeName($i) -cne $types[$i] -or [int]$schema.Rows[$i].ColumnSize -ne $sizes[$i] -or -not [bool]$schema.Rows[$i].AllowDBNull){throw 'Column name/type/size/nullability contract failed.'}
   }
   $count=0;while($reader.Read()){$count++;for($i=0;$i -lt 4;$i++){if($reader.IsDBNull($i)){throw 'Successful row contains NULL.'}}}
   if($count -ne $case.Rows -or $reader.NextResult()){throw 'Row/result count contract failed.'}
  } finally {if($null -ne $reader){$reader.Dispose()};$command.Dispose()}
 }
 # Rowlimit und Runtime-Timeout dürfen auch am SQLClient keine Zeile liefern.
 foreach($failureCase in @(
  @{Call="TVF_RegexSplit(N'abc',N'',N'c',N'standard',4)";Prefix='TBX_REGEX_TOO_MANY_ROWS'},
  @{Call="TVF_RegexMatches(REPLICATE(CONVERT(nvarchar(max),N'a'),100000)+N'!',N'^(a|aa)+$',1,N'c',N'standard',10000)";Prefix='TBX_REGEX_TIMEOUT'}
 )) {
 $command=$connection.CreateCommand();$command.CommandText='SELECT * FROM '+$quoted+$failureCase.Call+';';$command.CommandTimeout=120
 $reader=$null;$seen=0;$errorSeen=$false
 try {
  $reader=$command.ExecuteReader();while($reader.Read()){$seen++};while($reader.NextResult()){while($reader.Read()){$seen++}}
 } catch {
  $failure=$_.Exception;while($null -ne $failure.InnerException){$failure=$failure.InnerException}
  if($failure -isnot [System.Data.SqlClient.SqlException] -or $failure.Number -ne 6522 -or -not $failure.Message.Contains($failureCase.Prefix)){throw 'Unexpected client error signature.'}
  $errorSeen=$true
 } finally {if($null -ne $reader){$reader.Dispose()};$command.Dispose()}
 if(-not $errorSeen -or $seen -ne 0 -or $messages.Count -ne 0){throw 'Atomic/no-message contract failed.'}
 }
 'Regex R2b SQLClient metadata/atomic contract PASS.'
} catch {throw 'Regex R2b SQLClient-Vertrag fehlgeschlagen; private Verbindung/Runtime-Ausgabe unterdrückt.'}
finally {$connection.Dispose();$builder.Clear()}
