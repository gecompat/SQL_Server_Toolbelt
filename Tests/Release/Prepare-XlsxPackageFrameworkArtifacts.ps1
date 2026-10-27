# Bereitet Sidecars für den vorhandenen XLSX-Frameworkrunner aus Paketbytes vor.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RuntimeRoot,
    [Parameter(Mandatory)][string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw 'POWERSHELL_7_REQUIRED'
}
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$packageRelative = 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$packageSha256 = '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287'
$sidecarSha256 = '350826f0cbac147d3c78cc457445f562ec0e7f27418ae48d7f365c838c5dd27c'
$archivePrefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
$expected = @(
    [pscustomobject]@{
        Key='zip'; Module='toolbelt.archive.zip-memory'; Version='1.4.0'
        Assembly='Toolbelt.Archive.ZipMemory.dll'; SqlName='Toolbelt_Archive_ZipMemory'
        Size=40960; Sha256='bae312b3a125ffa157da72a5ae1b5bf29b6abbe604509638df2cc5e7136b575d'
    },
    [pscustomobject]@{
        Key='xlsx'; Module='toolbelt.file.xlsx-memory'; Version='1.2.0'
        Assembly='Toolbelt.File.XlsxMemory.dll'; SqlName='Toolbelt_File_XlsxMemory'
        Size=37376; Sha256='15bff87fad9695dca6f2127f49a8f509a34825b2d855545dc4b875a1a5af71ec'
    }
)
$xlsxSources = @(
    'Clr/Toolbelt.File.XlsxMemory.csproj','Clr/AssemblyInfo.cs','Clr/Workbook.cs',
    'Clr/XlsxEntryPoints.cs','Clr/XlsxCellType.cs','Clr/XlsxCellDisplay.cs',
    'Clr/XlsxCellDisplayBridge.cs','Source/TVF_InternalXlsxSheets.sql',
    'Source/TVF_InternalXlsxCells.sql','Source/USP_InternalXlsxRead.sql',
    'Source/USP_ListXlsxWorksheets.sql','Source/USP_ReadXlsxWorksheetCells.sql',
    'Source/TVF_InternalInterpretXlsxCell.sql','Source/TVF_InterpretXlsxCell.sql',
    'Source/TVF_InternalFormatXlsxCell.sql','Source/TVF_FormatXlsxCell.sql',
    'Deployment/Deploy.sql','Deployment/Uninstall.sql',
    'Scripts/New-ClrReleaseArtifacts.ps1','Scripts/Invoke-XlsxBuildProcess.ps1'
)
$zipSources = @(
    'Clr/Toolbelt.Archive.ZipMemory.csproj','Clr/Properties/AssemblyInfo.cs',
    'Clr/ZipEntryProvider.cs','Clr/ZipWriter.cs','Clr/ArchiveSession.cs'
)

function Get-Sha256([byte[]]$Bytes) {
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}
function Get-Sha512([byte[]]$Bytes) {
    return [Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($Bytes)).ToLowerInvariant()
}
function Assert-NoReparseAncestors([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($true) {
        if (-not [IO.File]::Exists($current) -and -not [IO.Directory]::Exists($current)) { throw 'PATH_COMPONENT_MISSING' }
        if (([IO.File]::GetAttributes($current) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'REPARSE_POINT_REJECTED' }
        $parent = [IO.Directory]::GetParent($current)
        if ($null -eq $parent -or $parent.FullName -eq $current) { break }
        $current = $parent.FullName
    }
}
function Get-UniqueEntry([IO.Compression.ZipArchive]$Archive, [string]$Name) {
    $matches = @($Archive.Entries | Where-Object { $_.FullName -ceq $Name })
    if ($matches.Count -ne 1) { throw 'PACKAGE_ENTRY_COUNT' }
    $entry = $matches[0]
    if ($entry.FullName.EndsWith('/') -or (($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) { throw 'PACKAGE_ENTRY_NOT_REGULAR' }
    return $entry
}
function Read-EntryBytes([IO.Compression.ZipArchiveEntry]$Entry) {
    $stream = $Entry.Open()
    try {
        $memory = [IO.MemoryStream]::new()
        try { $stream.CopyTo($memory); return ,$memory.ToArray() }
        finally { $memory.Dispose() }
    } finally { $stream.Dispose() }
}
function Write-NewFile([string]$Path, [byte[]]$Bytes) {
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    try { $stream.Write($Bytes, 0, $Bytes.Length); $stream.Flush($true) }
    finally { $stream.Dispose() }
    if ((Get-Sha256 ([IO.File]::ReadAllBytes($Path))) -cne (Get-Sha256 $Bytes)) { throw 'OUTPUT_WRITE_MISMATCH' }
}

$runtime = [IO.Path]::GetFullPath($RuntimeRoot)
$output = [IO.Path]::GetFullPath($OutputDirectory)
Assert-NoReparseAncestors $runtime
if ([IO.Path]::GetFileName($runtime) -cne '.runtime' -or
    -not [string]::Equals([IO.Path]::GetFullPath($runtime), (Resolve-Path -LiteralPath $runtime).Path, [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($output)) -cne $runtime -or
    $runtime.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    $repoRoot.StartsWith($runtime + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'PRIVATE_FRESH_OUTPUT_REQUIRED'
}
$existingOutput = Get-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
if ([IO.Directory]::Exists($output) -or [IO.File]::Exists($output) -or $null -ne $existingOutput) {
    throw 'PRIVATE_FRESH_OUTPUT_REQUIRED'
}

$packagePath = Join-Path $repoRoot $packageRelative
$sidecarPath = $packagePath + '.sha256'
Assert-NoReparseAncestors $packagePath
Assert-NoReparseAncestors $sidecarPath
$packageBytes = [IO.File]::ReadAllBytes($packagePath)
$sidecarBytes = [IO.File]::ReadAllBytes($sidecarPath)
$packageHash = Get-Sha256 $packageBytes
if ($packageHash -cne $packageSha256) { throw 'PACKAGE_SHA256_MISMATCH' }
$sidecarText = [Text.Encoding]::ASCII.GetString($sidecarBytes)
if ((Get-Sha256 $sidecarBytes) -cne $sidecarSha256 -or
    $sidecarText -cne ($packageSha256 + '  ' + [IO.Path]::GetFileName($packagePath) + [char]10)) { throw 'PACKAGE_SIDECAR_MISMATCH' }

$sourcePins = [Collections.Generic.List[object]]::new()
$payloads = @{}
$zipStream = [IO.MemoryStream]::new($packageBytes, $false)
try {
    $archive = [IO.Compression.ZipArchive]::new($zipStream, [IO.Compression.ZipArchiveMode]::Read, $true)
    try {
        $manifestEntry = Get-UniqueEntry $archive ($archivePrefix + 'CLR-PACKAGE.json')
        $manifestBytes = Read-EntryBytes $manifestEntry
        $packageManifest = [Text.Encoding]::UTF8.GetString($manifestBytes) | ConvertFrom-Json -AsHashtable -Depth 30
        if ($packageManifest['schema_version'] -cne '1.0' -or $packageManifest['state'] -cne 'prepared_not_published' -or
            $packageManifest['qualification_state'] -cne 'qualified' -or
            $packageManifest['publication_authorized'] -isnot [bool] -or
            $packageManifest['publication_authorized'] -cne $false) {
            throw 'PACKAGE_MANIFEST_STATE'
        }
        foreach ($item in $expected) {
            $artifact = @($packageManifest['artifacts'] | Where-Object { $_['module_id'] -ceq $item.Module })
            $binaryRecordName = 'Binaries/' + $item.Assembly
            $fileRecord = $packageManifest['files'][$binaryRecordName]
            $entry = Get-UniqueEntry $archive ($archivePrefix + 'Binaries/' + $item.Assembly)
            $bytes = Read-EntryBytes $entry
            $sha512 = Get-Sha512 $bytes
            if ($artifact.Count -ne 1 -or $artifact[0]['file'] -cne $item.Assembly -or
                $artifact[0]['origin'] -cne 'reproducible_double_build' -or
                $artifact[0]['sha256'] -cne $item.Sha256 -or $artifact[0]['sha512'] -cne $sha512 -or
                $null -eq $fileRecord -or $fileRecord['sha256'] -cne $item.Sha256 -or $fileRecord['size'] -ne $item.Size) {
                throw 'PACKAGE_ARTIFACT_BINDING'
            }
            if ($bytes.Length -ne $item.Size -or (Get-Sha256 $bytes) -cne $item.Sha256 -or
                $sha512 -cne $artifact[0]['sha512']) { throw 'PACKAGE_DLL_BINDING' }
            $payloads[$item.Key] = $bytes
            $payloads['sha512:' + $item.Key] = $sha512
        }
        $relativeSources = [Collections.Generic.List[string]]::new()
        foreach ($item in $expected) {
            $sourceNames = if ($item.Key -ceq 'xlsx') { $xlsxSources + @('module.yaml') } else { $zipSources + @('Deployment/Deploy.sql', 'module.yaml') }
            foreach ($relative in $sourceNames) { $relativeSources.Add($item.Module + '/' + $relative) }
        }
        foreach ($relative in $relativeSources) {
            $entryName = $archivePrefix + 'Sources/Modules/' + $relative
            $entry = Get-UniqueEntry $archive $entryName
            $bytes = Read-EntryBytes $entry
            $sourceRecordName = 'Sources/Modules/' + $relative
            $record = $packageManifest['files'][$sourceRecordName]
            $currentPath = Join-Path $repoRoot ('Modules/' + $relative)
            Assert-NoReparseAncestors $currentPath
            $currentBytes = [IO.File]::ReadAllBytes($currentPath)
            if ($null -eq $record -or $record.size -ne $bytes.Length -or
                $record['sha256'] -cne (Get-Sha256 $bytes) -or
                (Get-Sha256 $currentBytes) -cne (Get-Sha256 $bytes)) { throw 'PACKAGE_SOURCE_BINDING' }
            $sourcePins.Add([pscustomobject]@{ path = 'Modules/' + $relative; sha256 = (Get-Sha256 $currentBytes) })
            $payloads['source:' + $relative] = $bytes
        }
    } finally { $archive.Dispose() }
} finally { $zipStream.Dispose() }

foreach ($item in $expected) {
    $yaml = [Text.Encoding]::UTF8.GetString($payloads['source:' + $item.Module + '/module.yaml'])
    if ($yaml -notmatch ('(?m)^module_id: "?' + [regex]::Escape($item.Module) + '"?\s*$') -or
        $yaml -notmatch ('(?m)^version: "?' + [regex]::Escape($item.Version) + '"?\s*$')) { throw 'PACKAGE_MODULE_VERSION_BINDING' }
}

[void][IO.Directory]::CreateDirectory($output)
foreach ($item in $expected) {
    $directory = Join-Path $output $item.Key
    [void][IO.Directory]::CreateDirectory($directory)
    $dllBytes = [byte[]]$payloads[$item.Key]
    Write-NewFile (Join-Path $directory $item.Assembly) $dllBytes
    $manifest = [ordered]@{
        moduleId = $item.Module; moduleVersion = $item.Version
        assemblySqlName = $item.SqlName; assemblyFileName = $item.Assembly; permissionSet = 'SAFE'
        sha512 = $payloads['sha512:' + $item.Key].ToUpperInvariant()
        sqlServerHexLiteral = '0x' + $payloads['sha512:' + $item.Key].ToUpperInvariant()
    }
    if ($item.Key -ceq 'xlsx') {
        $manifest.sourceFingerprints = @($xlsxSources | ForEach-Object {
            $relative = $item.Module + '/' + $_
            [ordered]@{ path = $_; sha256 = ($sourcePins | Where-Object { $_.path -ceq ('Modules/' + $relative) } | Select-Object -ExpandProperty sha256).ToUpperInvariant() }
        })
        if ($manifest.sourceFingerprints.Count -ne 20) { throw 'XLSX_SOURCE_FINGERPRINT_COUNT' }
    }
    $manifestBytes = [Text.UTF8Encoding]::new($false).GetBytes(($manifest | ConvertTo-Json -Depth 8) + [char]10)
    Write-NewFile (Join-Path $directory ($item.Assembly.Replace('.dll', '.trust-manifest.json'))) $manifestBytes

    $templateBytes = [byte[]]$payloads['source:' + $item.Module + '/Deployment/Deploy.sql']
    $template = [Text.UTF8Encoding]::new($false, $true).GetString($templateBytes)
    $marker = '$(AssemblyBits)'
    if ([regex]::Matches($template, [regex]::Escape($marker)).Count -ne 1) { throw 'DEPLOY_MARKER_COUNT' }
    $deployBytes = [Text.UTF8Encoding]::new($false).GetBytes($template.Replace($marker, '0x' + [Convert]::ToHexString($dllBytes)))
    Write-NewFile (Join-Path $directory 'Deploy.WithAssembly.sql') $deployBytes
}

if ((Get-Sha256 ([IO.File]::ReadAllBytes($packagePath))) -cne $packageHash -or
    (Get-Sha256 ([IO.File]::ReadAllBytes($sidecarPath))) -cne $sidecarSha256) { throw 'PACKAGE_INPUT_DRIFT' }
foreach ($pin in $sourcePins) {
    if ((Get-Sha256 ([IO.File]::ReadAllBytes((Join-Path $repoRoot $pin.path)))) -cne $pin.sha256) {
        throw 'PACKAGE_SOURCE_DRIFT'
    }
}
$receipt = [ordered]@{
    schema = 'xlsx-package-framework-preparation/v1'; result = 'PREPARED'
    package = [ordered]@{ path = $packageRelative; sha256 = $packageHash; sidecar_sha256 = $sidecarSha256 }
    outputs = @($expected | ForEach-Object {
        $directory = Join-Path $output $_.Key
        [ordered]@{ module_id = $_.Module; version = $_.Version; assembly = $_.Assembly
            sha256 = $_.Sha256; sha512 = $payloads['sha512:' + $_.Key]; size = $_.Size
            manifest_sha256 = Get-Sha256 ([IO.File]::ReadAllBytes((Join-Path $directory ($_.Assembly.Replace('.dll', '.trust-manifest.json')))))
            deploy_sha256 = Get-Sha256 ([IO.File]::ReadAllBytes((Join-Path $directory 'Deploy.WithAssembly.sql'))) }
    })
    source_pins = @($sourcePins | Sort-Object path)
}
$receiptBytes = [Text.UTF8Encoding]::new($false).GetBytes(($receipt | ConvertTo-Json -Depth 10) + [char]10)
Write-NewFile (Join-Path $output 'Preparation.private.json') $receiptBytes
'PASS XLSX_PACKAGE_FRAMEWORK_ARTIFACTS'
