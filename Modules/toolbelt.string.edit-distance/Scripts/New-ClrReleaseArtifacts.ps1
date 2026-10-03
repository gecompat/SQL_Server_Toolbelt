[CmdletBinding()]
param(
    [ValidateSet('Release')][string]$Configuration = 'Release',
    [string]$OutputDirectory =
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'Artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $moduleRoot 'Clr/Toolbelt.String.EditDistance.csproj'
$assemblyPath = Join-Path $moduleRoot "Clr/bin/$Configuration/Toolbelt.String.EditDistance.dll"
$deployTemplatePath = Join-Path $moduleRoot 'Deployment/Deploy.sql'

# Releaseartefakte benötigen ein leeres Ziel und exakt denselben Quellstand
# vor/nach Build. Pfade im Manifest sind ausschließlich modulrelativ.
if (Test-Path -LiteralPath $OutputDirectory) {
    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container) -or
        @(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -ne 0) {
        throw 'Releaseziel muss neu oder leer sein; vorhandene Artefakte werden nicht wiederverwendet.'
    }
}
$sourcePaths = @('Clr/Toolbelt.String.EditDistance.csproj', 'Clr/Properties/AssemblyInfo.cs',
 'Clr/UnicodeScalar.cs', 'Clr/DistanceKernel.cs', 'Clr/DistanceProvider.cs',
 'Clr/JaroKernel.cs', 'Clr/JaroProvider.cs', 'Source/EditDistance.sql', 'Source/JaroWinkler.sql',
 'Deployment/Deploy.sql', 'Deployment/Uninstall.sql', 'Scripts/New-ClrReleaseArtifacts.ps1')
function Get-ReleaseSourceFingerprints {
    foreach ($relativePath in $sourcePaths) {
        [ordered]@{ path = $relativePath; sha256 =
            (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $moduleRoot $relativePath)).Hash }
    }
}
$sourceFingerprints = @(Get-ReleaseSourceFingerprints)
$sourceSnapshot = ConvertTo-Json -InputObject $sourceFingerprints -Compress

$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if ($null -eq $msbuild) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
        $msbuildPath = & $vswhere `
            -latest -products * -requires Microsoft.Component.MSBuild `
            -find 'MSBuild/**/Bin/MSBuild.exe' | Select-Object -First 1
        if ($msbuildPath) { $msbuild = [pscustomobject]@{ Source = $msbuildPath } }
    }
}
if ($null -eq $msbuild) {
    $ssmsBuild = Join-Path $env:ProgramFiles 'Microsoft SQL Server Management Studio 22/Release/MSBuild/Current/Bin/MSBuild.exe'
    if (Test-Path -LiteralPath $ssmsBuild -PathType Leaf) {
        $msbuild = [pscustomobject]@{ Source = $ssmsBuild }
    }
}
if ($null -eq $msbuild) {
    throw 'MSBuild und das .NET-Framework-4.8-Targeting-Pack werden benötigt.'
}

& $msbuild.Source $projectPath '/t:Rebuild' "/p:Configuration=$Configuration" '/p:Platform=AnyCPU' '/m:1'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $assemblyPath -PathType Leaf)) {
    throw 'Der CLR-EditDistance-Assembly-Build ist fehlgeschlagen.'
}

if ((ConvertTo-Json -InputObject @(Get-ReleaseSourceFingerprints) -Compress) -cne $sourceSnapshot) {
    throw 'Releasequellen wurden während des Builds verändert.'
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$assemblyBytes = [IO.File]::ReadAllBytes($assemblyPath)
$assemblyHex = [BitConverter]::ToString($assemblyBytes).Replace('-', '')
# SQL-Hex, Hash und ausgegebenes Binary stammen aus exakt einem Byte-Snapshot.
$hasher = [Security.Cryptography.SHA512]::Create()
try { $sha512 = [BitConverter]::ToString($hasher.ComputeHash($assemblyBytes)).Replace('-', '') }
finally { $hasher.Dispose() }
$description = 'SQL Server Toolbelt toolbelt.string.edit-distance CLR provider 1.1.0'

$manifest = [ordered]@{
    schemaVersion = '1.0'
    moduleId = 'toolbelt.string.edit-distance'
    moduleVersion = '1.1.0'
    assemblySqlName = 'Toolbelt_String_EditDistance'
    assemblyFileName = [IO.Path]::GetFileName($assemblyPath)
    permissionSet = 'SAFE'
    directFrameworkReferences = @('System', 'System.Data')
    sha512 = $sha512
    sqlServerHexLiteral = '0x' + $sha512
    description = $description
    sourceFingerprints = $sourceFingerprints
}

$manifestPath = Join-Path $OutputDirectory 'Toolbelt.String.EditDistance.trust-manifest.json'
$deployPath = Join-Path $OutputDirectory 'Deploy.WithAssembly.sql'
$assemblyOutputPath = Join-Path $OutputDirectory 'Toolbelt.String.EditDistance.dll'
$deployTemplate = Get-Content -LiteralPath $deployTemplatePath -Raw
if ([regex]::Matches($deployTemplate,[regex]::Escape('$(AssemblyBits)')).Count -ne 1) {
    throw 'Deployment/Deploy.sql muss genau einen AssemblyBits-Platzhalter enthalten.'
}
$deployScript = $deployTemplate.Replace('$(AssemblyBits)', '0x' + $assemblyHex)

# Unmittelbar vor dem Schreiben erneut prüfen; ein anderer Agent darf den
# gekoppelten Source-/Lifecycle-Stand nicht unbemerkt austauschen.
if ((ConvertTo-Json -InputObject @(Get-ReleaseSourceFingerprints) -Compress) -cne $sourceSnapshot) {
    throw 'Releasequellen wurden vor dem Artefaktschreiben verändert.'
}
[IO.File]::WriteAllBytes($assemblyOutputPath, $assemblyBytes)
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8
$deployScript | Set-Content -LiteralPath $deployPath -Encoding utf8

[pscustomobject]@{
    AssemblyPath = $assemblyOutputPath
    TrustManifestPath = $manifestPath
    DeployScriptPath = $deployPath
    AssemblyHash = '0x' + $sha512
    AssemblyDescription = $description
}
