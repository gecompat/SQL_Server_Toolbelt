[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^tbx_safe_cast_(local|central|consumer)_(150|160|170)$')][string]$Database,
    [Parameter(Mandatory)][ValidatePattern('^tbx_safe_cast_(local|central)_(150|160|170)$')][string]$ToolbeltDatabase
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# Der Host sieht nur den flüchtig veröffentlichten Loopback-Port des eigenen
# CI-Containers. Connection String und Passwort werden niemals ausgegeben.
$port=[Environment]::GetEnvironmentVariable('TBX_CI_SQL_PORT','Process')
$password=[Environment]::GetEnvironmentVariable('TBX_CI_SQL_PASSWORD','Process')
if($port -cnotmatch '^[0-9]{1,5}$' -or [string]::IsNullOrWhiteSpace($password)){
    throw 'SAFE_CAST_CI_CLIENT_ENV_INVALID'
}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source']='tcp:127.0.0.1,'+$port
$builder['Initial Catalog']=$Database
$builder['User ID']='sa'
$builder['Password']=$password
$builder['Encrypt']=$true
$builder['TrustServerCertificate']=$true
$builder['Pooling']=$false
$builder['Connect Timeout']=15
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$builder.Clear()
try{
    $connection.Open()
    & (Join-Path $PSScriptRoot '../../Modules/toolbelt.conversion.safe-cast/Tests/Runtime/Metadata.Tests.ps1') -Connection $connection -ToolbeltDatabase $ToolbeltDatabase | Out-Null
}catch{
    Write-Error 'SAFE_CAST_CI_CLIENT_FAILED' -ErrorAction Continue
    exit 1
}finally{
    $connection.Dispose()
}
