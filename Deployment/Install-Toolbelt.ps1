#requires -Version 7.4
<#
.SYNOPSIS
Installiert den aktuellen markerfreien Toolbelt-Satz mit einem Aufruf.
.DESCRIPTION
Normale SQL-Dateien, explizite Trustauswahl, keine Versions-/Ownershipmarker.
CreateDatabase und EnableClr sind ausdrücklich optionale administrative Schritte.
Alte Releasepakete bleiben an ihren mitgelieferten historischen Client gebunden.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
    [string]$ServerInstance,
    [string]$Database,
    [Management.Automation.PSCredential]$Credential,
    [string]$PackageZip,
    [string]$InstallSql,
    [ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSha256,
    [ValidateSet('Auto','Windows','Portable')][string]$Platform='Auto',
    [ValidateSet('auto','hash','trustworthy-checked','trustworthy')][string]$TrustMethod='auto',
    [string]$SqlcmdPath='sqlcmd',
    [switch]$TrustServerCertificate,
    [switch]$ValidateOnly,
    [switch]$PreflightOnly,
    [switch]$CreateDatabase,
    [switch]$EnableClr,
    [ValidateRange(1,120)][int]$LoginTimeoutSeconds=60,
    [ValidateRange(1,1800)][int]$CommandTimeoutSeconds=600
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Toolbelt.CurrentInstall.ps1')
if($MyInvocation.InvocationName -ne '.') { Invoke-ToolbeltInstall @PSBoundParameters }
