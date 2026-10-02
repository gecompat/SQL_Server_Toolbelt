[CmdletBinding()]
param(
    [string]$Configuration = 'Release',

    [string]$OutputDirectory =
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'Artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $moduleRoot 'Clr/Toolbelt.File.XlsxMemory.csproj'
$assemblyPath = Join-Path $moduleRoot "Clr/bin/$Configuration/Toolbelt.File.XlsxMemory.dll"
$deployTemplatePath = Join-Path $moduleRoot 'Deployment/Deploy.sql'
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $OutputDirectory) {
    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container) -or
        @(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -ne 0) {
        throw 'Das Releaseziel muss neu oder leer sein; kein Überschreiben.'
    }
}
$sourcePaths = @('Clr/Toolbelt.File.XlsxMemory.csproj','Clr/AssemblyInfo.cs','Clr/Workbook.cs',
    'Clr/XlsxEntryPoints.cs','Clr/XlsxCellType.cs','Source/TVF_InternalXlsxSheets.sql',
    'Source/TVF_InternalXlsxCells.sql','Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql',
    'Source/USP_ReadXlsxWorksheetCells.sql','Source/TVF_InternalInterpretXlsxCell.sql','Source/TVF_InterpretXlsxCell.sql',
    'Deployment/Deploy.sql','Deployment/Uninstall.sql','Scripts/New-ClrReleaseArtifacts.ps1')
$sourceFingerprints = @(foreach ($relative in $sourcePaths) {
    [ordered]@{ path = $relative; sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $moduleRoot $relative)).Hash }
})
function Assert-ReleaseSources {
    foreach ($entry in $sourceFingerprints) {
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $moduleRoot $entry.path)).Hash -cne $entry.sha256) {
            throw 'Releasequellen änderten sich während Build oder Artefakterstellung.'
        }
    }
}

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
    throw 'Der CLR-XLSX-Assembly-Build ist fehlgeschlagen oder das erwartete Binary fehlt.'
}
Assert-ReleaseSources

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$assemblyBytes = [IO.File]::ReadAllBytes($assemblyPath)
$assemblyHex = [BitConverter]::ToString($assemblyBytes).Replace('-', '')
# Binary, SQL-Hex und Manifest gehören zu exakt demselben privaten Byte-Snapshot.
$hasher = [Security.Cryptography.SHA512]::Create()
try {
    $sha512 = [BitConverter]::ToString($hasher.ComputeHash($assemblyBytes)).Replace('-', '')
} finally {
    $hasher.Dispose()
}
$description = 'SQL Server Toolbelt toolbelt.file.xlsx-memory CLR provider 1.1.0'

$manifest = [ordered]@{
    schemaVersion = '1.0'
    moduleId = 'toolbelt.file.xlsx-memory'
    moduleVersion = '1.1.0'
    assemblySqlName = 'Toolbelt_File_XlsxMemory'
    assemblyFileName = [IO.Path]::GetFileName($assemblyPath)
    permissionSet = 'SAFE'
    directFrameworkReferences = @('System', 'System.Data', 'System.Xml')
    directModuleReferences = @('Toolbelt.Archive.ZipMemory >= 1.4.0')
    sha512 = $sha512
    sqlServerHexLiteral = '0x' + $sha512
    description = $description
    sourceFingerprints = $sourceFingerprints
}

$manifestPath = Join-Path $OutputDirectory 'Toolbelt.File.XlsxMemory.trust-manifest.json'
$deployPath = Join-Path $OutputDirectory 'Deploy.WithAssembly.sql'
$assemblyOutputPath = Join-Path $OutputDirectory 'Toolbelt.File.XlsxMemory.dll'

$deployTemplate = Get-Content -LiteralPath $deployTemplatePath -Raw
$marker = '$(AssemblyBits)'
if ([regex]::Matches($deployTemplate, [regex]::Escape($marker)).Count -ne 1) {
    throw 'Deployment/Deploy.sql muss genau einen AssemblyBits-Platzhalter enthalten.'
}

$deployScript = $deployTemplate.Replace($marker, '0x' + $assemblyHex)

[IO.File]::WriteAllBytes($assemblyOutputPath, $assemblyBytes)
if ((Get-Item -LiteralPath $assemblyOutputPath).Length -ne $assemblyBytes.LongLength -or
    (Get-FileHash -Algorithm SHA512 -LiteralPath $assemblyOutputPath).Hash -cne $sha512) {
    throw 'Der ausgegebene CLR-Snapshot ist nicht hashkonsistent.'
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8
$deployScript | Set-Content -LiteralPath $deployPath -Encoding utf8
Assert-ReleaseSources

[pscustomobject]@{
    AssemblyPath = $assemblyOutputPath
    TrustManifestPath = $manifestPath
    DeployScriptPath = $deployPath
    AssemblyHash = '0x' + $sha512
    AssemblyDescription = $description
}
