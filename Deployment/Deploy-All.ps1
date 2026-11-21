#requires -Version 7.4
<#
.SYNOPSIS
Gemeinsamer aktueller Einstieg: planen, normale SQL-Datei bauen oder installieren.
.DESCRIPTION
Alle Module und Einzelmodule verwenden den markerfreien Installationskern.
Plan/Build sind offline. Ohne Inputs wird der aktuelle fertige Installationssatz verwendet.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
    [ValidateSet('Windows','Portable')][string]$Platform='Windows',
    [string[]]$ModuleId=@(),
    [string]$Inputs,[string]$OutputSqlFile,[switch]$PlanOnly,
    [ValidateSet('auto','hash','trustworthy-checked','trustworthy')][string]$TrustMethod='auto',
    [string]$ServerInstance,[string]$Database,[Management.Automation.PSCredential]$Credential,
    [ValidateSet('Windows','Sql')][string]$Authentication='Windows',[string]$SqlUsername='sa',
    [string]$PackageZip,[string]$SqlcmdPath='sqlcmd',[switch]$TrustServerCertificate,
    [switch]$CreateDatabase,[switch]$EnableClr
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$build=Join-Path $PSScriptRoot 'Build-Install.ps1'
if($PlanOnly){
    if($OutputSqlFile -or $CreateDatabase -or $EnableClr){throw 'PlanOnly nicht mit Ausgabe oder verändernden Schaltern kombinieren.'}
    & $build -PlanOnly -Platform $Platform -DeploymentMode $DeploymentMode -ModuleId $ModuleId
    return
}
if($OutputSqlFile){
    if(-not $Inputs){throw 'Zum SQL-Build Inputs mit den gebundenen CLR-Buildartefakten angeben.'}
    foreach($key in 'ServerInstance','Database','Credential','Authentication','SqlUsername','PackageZip','CreateDatabase','EnableClr','TrustServerCertificate'){
        if($PSBoundParameters.ContainsKey($key)){throw "OutputSqlFile kann nicht mit $key kombiniert werden."}
    }
    & $build -Inputs $Inputs -OutputSqlFile $OutputSqlFile -Platform $Platform -DeploymentMode $DeploymentMode -ModuleId $ModuleId -TrustMethod $TrustMethod
    return
}
if($Inputs -and $PackageZip){throw 'Inputs und PackageZip sind alternative Quellen.'}
if($ModuleId.Count -gt 0 -and -not $Inputs){throw 'Einzelmodule mit Inputs über denselben Buildkern erstellen; alternativ deren fertige SQL-Datei direkt installieren.'}
if([string]::IsNullOrWhiteSpace($ServerInstance) -or [string]::IsNullOrWhiteSpace($Database)){
    throw 'Zur Installation ServerInstance und Database ausdrücklich angeben.'
}
if($Credential -and $PSBoundParameters.ContainsKey('Authentication') -and $Authentication -eq 'Windows'){
    throw 'Credential nicht mit ausdrücklich gewählter Windows-Authentifizierung kombinieren.'
}
if($Authentication -eq 'Sql' -and -not $Credential){$Credential=Get-Credential -UserName $SqlUsername -Message 'SQL-Anmeldung für die ausdrücklich ausgewählte Zielinstanz'}
$call=@{DeploymentMode=$DeploymentMode;Platform=$Platform;TrustMethod=$TrustMethod;ServerInstance=$ServerInstance;Database=$Database;
    SqlcmdPath=$SqlcmdPath;TrustServerCertificate=$TrustServerCertificate;CreateDatabase=$CreateDatabase;EnableClr=$EnableClr}
if($Credential){$call.Credential=$Credential}
if($Inputs){
    $root=Split-Path -Parent $PSScriptRoot
    $output=Join-Path $root ('.runtime/install-dispatch-'+[guid]::NewGuid().ToString('N')+'/Install.sql')
    $built=& $build -Inputs $Inputs -OutputSqlFile $output -Platform $Platform -DeploymentMode $DeploymentMode -ModuleId $ModuleId -TrustMethod $TrustMethod
    $call.InstallSql=$built.SqlFile
}elseif($PackageZip){$call.PackageZip=$PackageZip}
& (Join-Path $PSScriptRoot 'Install-Toolbelt.ps1') @call
