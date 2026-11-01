<#
Lokales Installationsbeispiel für einen bewusst ausgewählten SQL Server.
Verwendet vorhandene kanonische Deploy-/Trustskripte und einen zusammen-
passenden, vom Betreiber geprüften Artefaktsatz. Kein Build oder Pin-Rewrite.
ValidateOnly liest Dateien und Hashes; es startet weder sqlcmd noch SQL.
Ohne ValidateOnly folgen fünf sqlcmd-Prozesse mit Abbruch beim ersten Fehler.
Voraussetzung: PrepareServer.sql separat geprüft/ausgeführt, vorhandener
sysadmin-Zugang per Windows-Anmeldung und ODBC-sqlcmd. Keine Rechtevergabe.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Server,
    [ValidateNotNullOrEmpty()][string]$Database = 'ContosoSsisDebug',
    [string]$RepositoryRoot = ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))),
    [string]$ParserReleaseDirectory,
    [string]$SsisReleaseDirectory,
    [ValidateNotNullOrEmpty()][string]$SqlcmdPath = 'sqlcmd.exe',
    [bool]$TrustServerCertificate = $true,
    [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resultRoot = Join-Path $RepositoryRoot 'Modules/toolbelt.core.result-table'
$parserRoot = Join-Path $RepositoryRoot 'Modules/toolbelt.tsql.script-parser'
$ssisRoot = Join-Path $RepositoryRoot 'Modules/toolbelt.tsql.ssis-debug'
if (-not $ParserReleaseDirectory) { $ParserReleaseDirectory = Join-Path $parserRoot 'Artifacts' }
if (-not $SsisReleaseDirectory) { $SsisReleaseDirectory = Join-Path $ssisRoot 'Artifacts' }

$required = @(
    (Join-Path $resultRoot 'Deployment/Deploy.sql'),
    (Join-Path $resultRoot 'Source/SchemaTrustPreflight.sql'),
    (Join-Path $resultRoot 'Source/USP_PrepareResultTable.sql'),
    (Join-Path $parserRoot 'Deployment/Add-TrustedAssembly.sql'),
    (Join-Path $ssisRoot 'Deployment/Add-TrustedAssembly.sql'),
    (Join-Path $ssisRoot 'Contracts/DependencyPins.json'),
    (Join-Path $ParserReleaseDirectory 'Toolbelt.Tsql.ScriptParser.trust-manifest.json'),
    (Join-Path $SsisReleaseDirectory 'Toolbelt.Tsql.SsisDebug.trust-manifest.json')
)
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw 'SSIS_INSTALL_INPUT_MISSING: Quellen und passende Releaseartefakte bereitstellen.'
    }
}
$parser = Get-Content -LiteralPath $required[6] -Raw | ConvertFrom-Json
$ssis = Get-Content -LiteralPath $required[7] -Raw | ConvertFrom-Json
$pins = Get-Content -LiteralPath $required[5] -Raw | ConvertFrom-Json
if ($parser.moduleId -cne 'toolbelt.tsql.script-parser' -or $parser.moduleVersion -cne '2.0.1' -or
    $ssis.moduleId -cne 'toolbelt.tsql.ssis-debug' -or $ssis.moduleVersion -cne '1.0.0' -or
    $pins.parserVersion -cne '2.0.1' -or $ssis.parserVersion -cne $pins.parserVersion -or
    $parser.sha512 -cne $pins.parserSha512 -or $ssis.parserSha512 -cne $pins.parserSha512 -or
    $parser.scriptDomSha512 -cne $pins.scriptDomSha512 -or $ssis.scriptDomSha512 -cne $pins.scriptDomSha512) {
    throw 'SSIS_INSTALL_DEPENDENCY_PIN_MISMATCH: Passenden Artefaktsatz verwenden.'
}
function Assert-ReleaseHash([string]$Path, [string]$Expected, [string]$Algorithm = 'SHA512') {
    $pattern = if ($Algorithm -eq 'SHA512') { '\A[0-9A-F]{128}\z' } else { '\A[0-9A-F]{64}\z' }
    if ($Expected -cnotmatch $pattern -or -not (Test-Path -LiteralPath $Path -PathType Leaf) -or
        (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash -cne $Expected) {
        throw 'SSIS_INSTALL_ARTIFACT_HASH_MISMATCH: Binary oder Deploymentartefakt ist abweichend.'
    }
}
Assert-ReleaseHash (Join-Path $ParserReleaseDirectory 'Toolbelt.Tsql.ScriptParser.dll') $parser.sha512
Assert-ReleaseHash (Join-Path $ParserReleaseDirectory 'Microsoft.SqlServer.TransactSql.ScriptDom.dll') $pins.scriptDomSha512
Assert-ReleaseHash (Join-Path $SsisReleaseDirectory 'Toolbelt.Tsql.SsisDebug.dll') $ssis.sha512
Assert-ReleaseHash (Join-Path $ParserReleaseDirectory 'Deploy.WithAssembly.sql') $parser.deploymentArtifactSha256 'SHA256'
Assert-ReleaseHash (Join-Path $SsisReleaseDirectory 'Deploy.WithAssembly.sql') $ssis.deploymentArtifactSha256 'SHA256'
if ($ValidateOnly) {
    'SSIS_INSTALL_ARTIFACTS_VALIDATED files=5; no sqlcmd or SQL executed'
    return
}
$sqlcmd = Get-Command -Name $SqlcmdPath -ErrorAction Stop
function Invoke-InstallSql([string]$File, [string]$TargetDatabase, [string[]]$Variables) {
    # Release-SQL ist UTF-8 ohne BOM; die Eingabecodepage bleibt auch auf
    # Windows-Systemen mit einer anderen Console-/ANSI-Codepage eindeutig.
    $sqlArguments = @('-S', $Server, '-d', $TargetDatabase, '-E', '-N', '-b', '-f', '65001', '-i', $File)
    if ($TrustServerCertificate) { $sqlArguments += '-C' }
    if ($Variables.Count -gt 0) { $sqlArguments += @('-v') + $Variables }
    & $sqlcmd.Source @sqlArguments
    if ($LASTEXITCODE -ne 0) { throw 'SSIS_INSTALL_SQLCMD_FAILED: Installation beim ersten Fehler abgebrochen.' }
}

# ResultTable hat relative :r-Includes. Das Arbeitsverzeichnis danach erhalten.
Push-Location (Join-Path $resultRoot 'Deployment')
try { Invoke-InstallSql './Deploy.sql' $Database @('DeploymentMode=local') }
finally { Pop-Location }
Invoke-InstallSql (Join-Path $parserRoot 'Deployment/Add-TrustedAssembly.sql') 'master' @(
    ('AssemblyHash=0x' + $parser.sha512), ('ScriptDomAssemblyHash=0x' + $pins.scriptDomSha512),
    'AssemblyDescription=Toolbelt_ScriptParser_2.0.1')
Invoke-InstallSql (Join-Path $ParserReleaseDirectory 'Deploy.WithAssembly.sql') $Database @('DeploymentMode=local')
Invoke-InstallSql (Join-Path $ssisRoot 'Deployment/Add-TrustedAssembly.sql') 'master' @('AssemblySha512=0x' + $ssis.sha512)
Invoke-InstallSql (Join-Path $SsisReleaseDirectory 'Deploy.WithAssembly.sql') $Database @('DeploymentMode=local')
'SSIS_INSTALL_COMPLETED modules=3; verify installation and run the SSMS walkthrough'
