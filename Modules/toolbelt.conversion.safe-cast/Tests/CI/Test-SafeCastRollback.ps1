[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidatePattern('^tbx_safe_cast_central_(150|160|170)$')][string]$Database
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# Nur die eigene flüchtige CI-Datenbank über ihren Loopback-Port verwenden.
# Produktdateien bleiben unverändert; die vier Faultseams entstehen im Speicher.
$port=[Environment]::GetEnvironmentVariable('TBX_CI_SQL_PORT','Process')
$password=[Environment]::GetEnvironmentVariable('TBX_CI_SQL_PASSWORD','Process')
if($port -cnotmatch '^[0-9]{1,5}$' -or [string]::IsNullOrWhiteSpace($password)){
 throw 'SAFE_CAST_CI_ROLLBACK_ENV_INVALID'
}
$deployment=Join-Path $PSScriptRoot '../../Deployment'
. (Join-Path $PSScriptRoot '../../../../Tests/CI/SafeCastLifecycle.Helpers.ps1')
$script:files=@('Deploy.sql','Uninstall.sql','Preflight.sql','CreateObjects.sql','MarkRelease.sql') |
 ForEach-Object { Join-Path $deployment $_ }
$script:pins=@{}
foreach($path in $script:files){$script:pins[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}

function Assert-SafeCastPins {
 foreach($path in $script:files){
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $script:pins[$path]){
   throw 'SAFE_CAST_CI_ROLLBACK_SOURCE_CHANGED'
  }
 }
}

function Read-SafeCastCiSql([string]$Path,[hashtable]$Variables){
 $text=[IO.File]::ReadAllText($Path)
 $text=[regex]::Replace($text,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{param($match)
  Read-SafeCastCiSql (Join-Path (Split-Path -Parent $Path) $match.Groups[1].Value.Trim()) $Variables
 })
 $text=[regex]::Replace($text,'(?im)^\s*:On\s+Error\s+exit\s*$','')
 foreach($key in $Variables.Keys){$text=$text.Replace('$('+$key+')',[string]$Variables[$key])}
 if($text -match '(?m)^\s*:' -or $text -match '\$\('){throw 'SAFE_CAST_CI_ROLLBACK_TEMPLATE_UNRESOLVED'}
 return $text
}

function Invoke-SafeCastSql($Connection,[string]$Sql,[switch]$Rows){
 $command=$Connection.CreateCommand()
 $command.CommandText=$Sql;$command.CommandTimeout=60
 try{
  if($Rows){
   $reader=$command.ExecuteReader()
   try{
    while($reader.Read()){
     $record=[ordered]@{}
     for($index=0;$index -lt $reader.FieldCount;$index++){
      $record[$reader.GetName($index)]=$reader.GetValue($index)
     }
     [pscustomobject]$record
    }
   }finally{$reader.Dispose()}
  }else{[void]$command.ExecuteNonQuery()}
 }finally{$command.Dispose()}
}

function Invoke-SafeCastBatches($Connection,[string]$Sql){
 foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
  if(-not [string]::IsNullOrWhiteSpace($batch)){Invoke-SafeCastSql $Connection $batch}
 }
}

function Get-SafeCastFailure($Exception){
 $sql=$null;$cursor=$Exception
 while($null -ne $cursor){
  if($cursor -is [Data.SqlClient.SqlException]){$sql=$cursor}
  $cursor=$cursor.InnerException
 }
 return [pscustomobject]@{
  SqlNumber=$(if($null-ne$sql){$sql.Number}else{0})
  SqlState=$(if($null-ne$sql){$sql.State}else{0})
 }
}

$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source']='tcp:127.0.0.1,'+$port
$builder['Initial Catalog']=$Database
$builder['User ID']='sa';$builder['Password']=$password
$builder['Encrypt']=$true;$builder['TrustServerCertificate']=$true
$builder['Pooling']=$false;$builder['Connect Timeout']=15
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$builder.Clear()
try{
 $connection.Open()
 $deploy=Read-SafeCastCiSql (Join-Path $deployment 'Deploy.sql') @{'DeploymentMode'='central'}
 $uninstall=Read-SafeCastCiSql (Join-Path $deployment 'Uninstall.sql') @{'ConfirmNoExternalConsumers'='1'}
 Assert-SafeCastRollbackPrepared $connection $deploy $uninstall
 Write-Output 'PASS: Safe Cast central postDROP/preCOMMIT Deploy/Uninstall rollback'
}catch{
 # Keine SQL-Ausnahme, Connection String oder Runtimewerte in CI ausgeben.
 [Console]::Error.WriteLine('SAFE_CAST_CI_ROLLBACK_FAILED')
 exit 1
}finally{
 $connection.Dispose()
}
