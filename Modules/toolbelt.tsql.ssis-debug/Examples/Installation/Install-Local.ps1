#requires -Version 7.4
<#
.SYNOPSIS
Installiert den aktuellen SSIS-Funktionssatz über den gemeinsamen SQL-Kern.
.DESCRIPTION
Inputs enthält gebundene parser/ssis-Binaryverzeichnisse. Build und ValidateOnly
führen kein SQL aus. Der Client vergibt keine Rechte und aktiviert TRUSTWORTHY nicht.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Server,
    [string]$Database='ContosoSsisDebug',
    [Parameter(Mandatory)][string]$Inputs,
    [string]$RepositoryRoot=([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))),
    [ValidateSet('auto','hash','trustworthy-checked','trustworthy')][string]$TrustMethod='auto',
    [Management.Automation.PSCredential]$Credential,
    [string]$SqlcmdPath='sqlcmd',
    [switch]$TrustServerCertificate,
    [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$output=Join-Path $RepositoryRoot ('.runtime/ssis-install-'+[guid]::NewGuid().ToString('N')+'/Install.sql')
$built=& (Join-Path $RepositoryRoot 'Deployment/Build-Install.ps1') -Inputs $Inputs `
    -OutputSqlFile $output -Platform Windows -DeploymentMode local `
    -ModuleId toolbelt.tsql.ssis-debug -TrustMethod $TrustMethod
$call=@{ServerInstance=$Server;Database=$Database;DeploymentMode='local';Platform='Windows';
    InstallSql=$built.SqlFile;TrustMethod=$TrustMethod;SqlcmdPath=$SqlcmdPath;
    TrustServerCertificate=$TrustServerCertificate;ValidateOnly=$ValidateOnly}
if($Credential){$call.Credential=$Credential}
& (Join-Path $RepositoryRoot 'Deployment/Install-Toolbelt.ps1') @call
