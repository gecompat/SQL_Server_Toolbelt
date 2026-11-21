[CmdletBinding()]
param(
    [string]$Configuration = 'Release',

    [string]$OutputDirectory =
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'Artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $moduleRoot 'Clr/Toolbelt.Archive.ZipMemory.csproj'
$assemblyPath = Join-Path $moduleRoot "Clr/bin/$Configuration/Toolbelt.Archive.ZipMemory.dll"

$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if ($null -eq $msbuild) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
        $msbuildPath = & $vswhere `
            -latest `
            -products * `
            -requires Microsoft.Component.MSBuild `
            -find 'MSBuild/**/Bin/MSBuild.exe' |
            Select-Object -First 1

        if ($msbuildPath) {
            $msbuild = [pscustomobject]@{ Source = $msbuildPath }
        }
    }
}

if ($null -eq $msbuild) {
    throw 'MSBuild wurde nicht gefunden. Benötigt werden Visual-Studio-Build-Tools und das .NET-Framework-4.8-Targeting-Pack.'
}

& $msbuild.Source $projectPath `
    '/t:Rebuild' `
    "/p:Configuration=$Configuration" `
    '/p:Platform=AnyCPU' `
    '/m:1'

if ($LASTEXITCODE -ne 0 -or
    -not (Test-Path -LiteralPath $assemblyPath -PathType Leaf)) {
    throw 'Der CLR-ZIP-Assembly-Build ist fehlgeschlagen oder das erwartete Binary fehlt.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$assemblyBytes = [IO.File]::ReadAllBytes($assemblyPath)
$assemblyHex = [BitConverter]::ToString($assemblyBytes).Replace('-', '')
$sha512 = (Get-FileHash -Algorithm SHA512 -LiteralPath $assemblyPath).Hash.ToUpperInvariant()
$description = 'SQL Server Toolbelt toolbelt.archive.zip-memory CLR provider 1.4.0'

$manifest = [ordered]@{
    schemaVersion = '1.0'
    moduleId = 'toolbelt.archive.zip-memory'
    moduleVersion = '1.4.0'
    assemblySqlName = 'tlblt_Archive_ZipMemory'
    assemblyFileName = [IO.Path]::GetFileName($assemblyPath)
    permissionSet = 'SAFE'
    directFrameworkReferences = @('System', 'System.Data')
    sha512 = $sha512
    sqlServerHexLiteral = '0x' + $sha512
    description = $description
}

$manifestPath = Join-Path $OutputDirectory 'Toolbelt.Archive.ZipMemory.trust-manifest.json'
$assemblyOutputPath = Join-Path $OutputDirectory 'Toolbelt.Archive.ZipMemory.dll'

[IO.File]::Copy($assemblyPath, $assemblyOutputPath, $true)
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8

[pscustomobject]@{
    AssemblyPath = $assemblyOutputPath
    TrustManifestPath = $manifestPath
    InstallBuilder = "Deployment/Build-Install.ps1"
    AssemblyHash = '0x' + $sha512
    AssemblyDescription = $description
}
