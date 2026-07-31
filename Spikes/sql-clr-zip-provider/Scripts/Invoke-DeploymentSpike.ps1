[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SqlInstance,

    [ValidatePattern('^[A-Za-z0-9_]{1,96}$')]
    [string]$TestDatabase = 'Toolbelt_ClrZipSpike',

    [string]$Configuration = 'Release',

    [switch]$KeepTestObjects
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$spikeRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $spikeRoot 'Source/Toolbelt.ZipClr.Spike.csproj'
$artifactDirectory = Join-Path $spikeRoot 'Artifacts'
$assemblyPath = Join-Path $spikeRoot "Source/bin/$Configuration/Toolbelt.ZipClr.Spike.dll"
$manifestPath = Join-Path $artifactDirectory 'Toolbelt.ZipClr.Spike.trust-manifest.json'

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if ($null -eq $sqlcmd) {
    throw 'sqlcmd wurde nicht gefunden. Der Spike veraendert keine Serveroptionen und wird nicht ohne explizites SQLCMD-Tool ausgefuehrt.'
}

$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if ($null -eq $msbuild) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
        $msbuildPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild/**/Bin/MSBuild.exe' | Select-Object -First 1
        if ($msbuildPath) {
            $msbuild = [pscustomobject]@{ Source = $msbuildPath }
        }
    }
}
if ($null -eq $msbuild) {
    throw 'MSBuild wurde nicht gefunden. Installiere Visual-Studio-Build-Tools mit .NET-Framework-4.8-Targeting-Pack; es wird nichts automatisch installiert.'
}

& $msbuild.Source $projectPath '/t:Rebuild' "/p:Configuration=$Configuration" '/p:Platform=AnyCPU' '/m:1'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $assemblyPath -PathType Leaf)) {
    throw 'Der SQL-CLR-Assembly-Build ist fehlgeschlagen oder das erwartete Binary fehlt.'
}

& (Join-Path $PSScriptRoot 'New-TrustManifest.ps1') -AssemblyPath $assemblyPath -OutputPath $manifestPath
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

function Invoke-SqlCmdFile {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Variables,
        [string]$Database = 'master'
    )

    & $sqlcmd.Source -S $SqlInstance -d $Database -b -i $FilePath -v $Variables
    if ($LASTEXITCODE -ne 0) {
        throw "SQLCMD-Schritt fehlgeschlagen: $FilePath"
    }
}

# Das Trust-Opt-in ist absichtlich ein sichtbarer, getrennt aufgerufener Schritt.
Invoke-SqlCmdFile -FilePath (Join-Path $spikeRoot 'Deployment/Add-TrustedAssembly.sql') `
    -Variables @("AssemblyHash=$($manifest.sqlServerHexLiteral)", "AssemblyDescription=$($manifest.description)")

$assemblyBytes = [IO.File]::ReadAllBytes($assemblyPath)
$assemblyHex = '0x' + ([BitConverter]::ToString($assemblyBytes).Replace('-', ''))
$deployTemplatePath = Join-Path $spikeRoot 'Deployment/Deploy-TestDatabase.sql'
$deployTemplate = [IO.File]::ReadAllText($deployTemplatePath)
if (-not $deployTemplate.Contains('$(AssemblyBits)')) {
    throw 'Deploy-TestDatabase.sql enthaelt den erwarteten AssemblyBits-Platzhalter nicht.'
}

$temporaryDeployScript = Join-Path ([IO.Path]::GetTempPath()) ("toolbelt-sql-clr-zip-{0}.sql" -f [Guid]::NewGuid().ToString('N'))
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText(
    $temporaryDeployScript,
    $deployTemplate.Replace('$(AssemblyBits)', $assemblyHex),
    $utf8NoBom
)

try {
    Invoke-SqlCmdFile -FilePath $temporaryDeployScript `
        -Variables @("TestDatabase=$TestDatabase") `
        -Database $TestDatabase

    Invoke-SqlCmdFile -FilePath (Join-Path $spikeRoot 'Deployment/Verify-TestDatabase.sql') `
        -Variables @("TestDatabase=$TestDatabase") `
        -Database $TestDatabase

    if (-not $KeepTestObjects) {
        Invoke-SqlCmdFile -FilePath (Join-Path $spikeRoot 'Deployment/Uninstall-TestDatabase.sql') `
            -Variables @("TestDatabase=$TestDatabase") `
            -Database $TestDatabase
    }
}
finally {
    Remove-Item -LiteralPath $temporaryDeployScript -Force -ErrorAction SilentlyContinue
}

Write-Output 'SQL CLR ZIP deployment spike abgeschlossen. Ein vorhandener Trust-Eintrag wurde absichtlich nicht entfernt.'
