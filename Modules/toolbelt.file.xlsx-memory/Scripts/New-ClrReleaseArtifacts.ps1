[CmdletBinding()]
param(
    [string]$Configuration = 'Release',

    [string]$OutputDirectory =
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'Artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Bereits qualifizierter gemeinsamer Paketierungshelfer; keine ungegrenzten
# direkten Toolstarts. Seine Kanäle bleiben privat und auf je 4 MiB begrenzt.
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$ownedHelper = Join-Path $repoRoot 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'
$toolPins = @{}
$helperBytes = [IO.File]::ReadAllBytes($ownedHelper)
$helperHasher = [Security.Cryptography.SHA256]::Create()
try { $toolPins[$ownedHelper] = [BitConverter]::ToString($helperHasher.ComputeHash($helperBytes)).Replace('-','') } finally { $helperHasher.Dispose() }
. ([scriptblock]::Create([Text.UTF8Encoding]::new($false,$true).GetString($helperBytes).TrimStart([char]0xFEFF)))
$buildHelper = Join-Path $PSScriptRoot 'Invoke-XlsxBuildProcess.ps1'
$buildHelperBytes = [IO.File]::ReadAllBytes($buildHelper)
$buildHelperHasher = [Security.Cryptography.SHA256]::Create()
try { $toolPins[$buildHelper] = [BitConverter]::ToString($buildHelperHasher.ComputeHash($buildHelperBytes)).Replace('-','') } finally { $buildHelperHasher.Dispose() }
. ([scriptblock]::Create([Text.UTF8Encoding]::new($false,$true).GetString($buildHelperBytes)))
function Assert-ReleaseTools {
    foreach ($path in $toolPins.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $toolPins[$path]) {
            throw 'RELEASE_TOOL_DRIFT'
        }
    }
}

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
    'Clr/XlsxEntryPoints.cs','Clr/XlsxCellType.cs','Clr/XlsxCellDisplay.cs','Clr/XlsxCellDisplayBridge.cs','Source/TVF_InternalXlsxSheets.sql',
    'Source/TVF_InternalXlsxCells.sql','Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql',
    'Source/USP_ReadXlsxWorksheetCells.sql','Source/TVF_InternalInterpretXlsxCell.sql','Source/TVF_InterpretXlsxCell.sql',
    'Source/TVF_InternalFormatXlsxCell.sql','Source/TVF_FormatXlsxCell.sql',
    'Deployment/Deploy.sql','Deployment/Uninstall.sql','Scripts/New-ClrReleaseArtifacts.ps1','Scripts/Invoke-XlsxBuildProcess.ps1')
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
function Invoke-ReleaseTool([string]$Path,[string[]]$Arguments,[int]$Milliseconds) {
    $result=$null;$firstFailure=$null;$secondary=@()
    Assert-ReleaseSources;Assert-ReleaseTools
    try {
        if($null -ne $script:xlsxBuildControl -and $Path -ceq $script:xlsxBuildControl.Tool){
            Assert-XlsxBuildImports $script:xlsxBuildControl
            $result=Invoke-XlsxBuildProcess -FileName $Path -Arguments ($Arguments+$script:xlsxBuildControl.Arguments) -TimeoutMilliseconds $Milliseconds -WorkingDirectory $script:xlsxBuildControl.WorkingDirectory -ChildEnvironment $script:xlsxBuildControl.Environment
            Assert-XlsxBuildImports $script:xlsxBuildControl
        }else{$result=Invoke-OwnedProcess -FileName $Path -Arguments $Arguments -TimeoutMilliseconds $Milliseconds}
    }
    catch { $firstFailure=$_ }
    finally {
        try { Assert-ReleaseSources;Assert-ReleaseTools }
        catch { if($null -eq $firstFailure){$firstFailure=$_}else{$secondary+=@('RELEASE_POSTPIN_FAILED')} }
    }
    if($null -ne $firstFailure){
        if($secondary.Count){$firstFailure.Exception.Data['ReleaseSecondaryFailures']=$secondary -join ','}
        throw $firstFailure
    }
    return $result
}

$script:xlsxBuildControl=$null
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if ($null -eq $msbuild) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
        $toolPins[$vswhere] = (Get-FileHash -LiteralPath $vswhere -Algorithm SHA256).Hash
        Assert-ReleaseTools
        $discovery = Invoke-ReleaseTool $vswhere @('-latest','-products','*','-requires','Microsoft.Component.MSBuild','-find','MSBuild/**/Bin/MSBuild.exe') 20000
        Assert-ReleaseTools
        if ($discovery.ExitCode -ne 0 -or -not $discovery.CaptureComplete -or $discovery.Stderr.Length -ne 0) { throw 'RELEASE_DISCOVERY_FAILED' }
        $paths = @($discovery.Stdout -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $msbuildPath = if ($paths.Count) { $paths[0] } else { $null }

        if ($msbuildPath) {
            $msbuild = [pscustomobject]@{ Source = $msbuildPath }
        }
    }
}

if ($null -eq $msbuild) {
    throw 'MSBuild wurde nicht gefunden. Benötigt werden Visual-Studio-Build-Tools und das .NET-Framework-4.8-Targeting-Pack.'
}

$script:xlsxBuildControl=New-XlsxBuildControl $projectPath $msbuild.Source
Assert-XlsxBuildImports $script:xlsxBuildControl
$toolPins[$msbuild.Source] = (Get-FileHash -LiteralPath $msbuild.Source -Algorithm SHA256).Hash
Assert-ReleaseSources
Assert-ReleaseTools
$build = Invoke-ReleaseTool $msbuild.Source @($projectPath,'/t:Rebuild',"/p:Configuration=$Configuration",'/p:Platform=AnyCPU','/m:1') 120000
Assert-ReleaseTools

if ($build.ExitCode -ne 0 -or -not $build.CaptureComplete -or
    -not (Test-Path -LiteralPath $assemblyPath -PathType Leaf)) {
    throw 'Der CLR-XLSX-Assembly-Build ist fehlgeschlagen oder das erwartete Binary fehlt.'
}
Assert-ReleaseSources
Assert-ReleaseTools

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
$description = 'SQL Server Toolbelt toolbelt.file.xlsx-memory CLR provider 1.2.0'

$manifest = [ordered]@{
    schemaVersion = '1.0'
    moduleId = 'toolbelt.file.xlsx-memory'
    moduleVersion = '1.2.0'
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
Assert-ReleaseTools

[pscustomobject]@{
    AssemblyPath = $assemblyOutputPath
    TrustManifestPath = $manifestPath
    DeployScriptPath = $deployPath
    AssemblyHash = '0x' + $sha512
    AssemblyDescription = $description
}
