# Führt die bestehenden ZIP-Writer-Verträge gegen die gebundene Paket-DLL aus.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RuntimeRoot,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [Parameter(Mandatory)][string]$CompilerPath,
    [Parameter(Mandatory)][string]$GitPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) { throw 'POWERSHELL_7_REQUIRED' }

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$packageRelative = 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$packageSha256 = '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287'
$sidecarSha256 = '350826f0cbac147d3c78cc457445f562ec0e7f27418ae48d7f365c838c5dd27c'
$archivePrefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
$writerSourceRelative = 'Modules/toolbelt.archive.zip-memory/Tests/Runtime/Writer.Framework.ps1'
$entrySourceRelative = 'Modules/toolbelt.archive.zip-memory/Tests/Runtime/EntrySecurity.Framework.cs'
$mainSourceRelative = 'Tests/Release/ZipWriterPackageHarness.cs'
$ownedHelperRelative = 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'
$references = @(
    'mscorlib.dll', 'System.dll', 'System.Data.dll', 'System.Xml.dll', 'System.Core.dll', 'System.IO.Compression.dll'
)
$expectedAssembly = 'Toolbelt.Archive.ZipMemory.dll'
$expectedAssemblySha256 = 'bae312b3a125ffa157da72a5ae1b5bf29b6abbe604509638df2cc5e7136b575d'
$expectedAssemblySize = 40960
$expectedAssemblyVersion = '1.4.0.0'

function Get-Sha256([byte[]]$Bytes) {
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}
function Get-Sha512([byte[]]$Bytes) {
    [Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($Bytes)).ToLowerInvariant()
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
    if ($matches[0].FullName.EndsWith('/') -or ((($matches[0].ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000)) { throw 'PACKAGE_ENTRY_NOT_REGULAR' }
    return $matches[0]
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
function Write-NewText([string]$Path, [string]$Text) {
    Write-NewFile $Path ([Text.UTF8Encoding]::new($false).GetBytes($Text))
}
function Save-Json([string]$Path, $Value) {
    Write-NewText $Path (($Value | ConvertTo-Json -Depth 14) + [char]10)
}

$runtime = [IO.Path]::GetFullPath($RuntimeRoot)
$output = [IO.Path]::GetFullPath($OutputDirectory)
Assert-NoReparseAncestors $runtime
if ([IO.Path]::GetFileName($runtime) -cne '.runtime' -or
    -not [string]::Equals($runtime, (Resolve-Path -LiteralPath $runtime).Path, [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($output)) -cne $runtime -or
    $runtime.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    $repoRoot.StartsWith($runtime + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'PRIVATE_FRESH_OUTPUT_REQUIRED'
}
$existingOutput = Get-Item -LiteralPath $output -Force -ErrorAction SilentlyContinue
if ([IO.Directory]::Exists($output) -or [IO.File]::Exists($output) -or $null -ne $existingOutput) { throw 'PRIVATE_FRESH_OUTPUT_REQUIRED' }

$packagePath = Join-Path $repoRoot $packageRelative
$sidecarPath = $packagePath + '.sha256'
$writerSourcePath = Join-Path $repoRoot $writerSourceRelative
$entrySourcePath = Join-Path $repoRoot $entrySourceRelative
$mainSourcePath = Join-Path $repoRoot $mainSourceRelative
$ownedHelperPath = Join-Path $repoRoot $ownedHelperRelative
$wrapperPath = $PSCommandPath
$allPins = [Collections.Generic.List[object]]::new()
$initialPins = @{}
$phaseRecords = [Collections.Generic.List[object]]::new()
$gitChecks = [Collections.Generic.List[object]]::new()
$artifacts = [Collections.Generic.List[object]]::new()
$inputPinsAfter = @()
$compiledPinsBefore = @()
$compiledPinsAfterCompile = @()
$compiledPinsAfter = @()
$copyLease = $null
$failure = $null
$stage = 'PREFLIGHT'
$status = 'FAILED'
$markers = @()
$packageBuffer = $null
$dllBytes = $null
$writerCSharp = $null
try {
    $stage = 'PIN_INPUTS'
    foreach ($path in @($packagePath, $sidecarPath, $writerSourcePath, $entrySourcePath, $ownedHelperPath, $wrapperPath, $CompilerPath, $GitPath, $mainSourcePath)) {
        Assert-NoReparseAncestors $path
        $bytes = [IO.File]::ReadAllBytes($path)
        $digest = Get-Sha256 $bytes
        $allPins.Add([pscustomobject]@{ path = $path; sha256 = $digest })
        $initialPins[$path] = $digest
    }
    $refRoot = Join-Path ${env:ProgramFiles(x86)} 'Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8'
    foreach ($reference in $references) {
        $path = Join-Path $refRoot $reference
        Assert-NoReparseAncestors $path
        $allPins.Add([pscustomobject]@{ path = $path; sha256 = (Get-Sha256 ([IO.File]::ReadAllBytes($path))) })
    }
    $helperBytes = [IO.File]::ReadAllBytes($ownedHelperPath)
    if ((Get-Sha256 $helperBytes) -cne $allPins[4].sha256) { throw 'OWNED_HELPER_DRIFT' }
    . ([scriptblock]::Create([Text.Encoding]::UTF8.GetString($helperBytes).TrimStart([char]0xFEFF)))
    foreach ($source in @(
        @{ relative=$writerSourceRelative; path=$writerSourcePath },
        @{ relative=$entrySourceRelative; path=$entrySourcePath },
        @{ relative=$ownedHelperRelative; path=$ownedHelperPath }
    )) {
        $blob = Invoke-OwnedProcess -FileName $GitPath -Arguments @('-C', $repoRoot, 'rev-parse', ('HEAD:' + $source.relative)) -TimeoutMilliseconds 20000
        $filtered = Invoke-OwnedProcess -FileName $GitPath -Arguments @('-C', $repoRoot, 'hash-object', ('--path=' + $source.relative), $source.path) -TimeoutMilliseconds 20000
        $raw = Invoke-OwnedProcess -FileName $GitPath -Arguments @('-C', $repoRoot, 'hash-object', '--no-filters', $source.path) -TimeoutMilliseconds 20000
        if ($blob.ExitCode -ne 0 -or -not $blob.CaptureComplete -or $blob.Stderr.Length -ne 0 -or
            $filtered.ExitCode -ne 0 -or -not $filtered.CaptureComplete -or $filtered.Stderr.Length -ne 0 -or
            $raw.ExitCode -ne 0 -or -not $raw.CaptureComplete -or $raw.Stderr.Length -ne 0 -or
            $blob.Stdout.Trim() -cne $filtered.Stdout.Trim() -or $blob.Stdout.Trim() -cne $raw.Stdout.Trim()) { throw 'CANONICAL_SOURCE_BYTES_MISMATCH' }
        $gitChecks.Add([pscustomobject]@{ path=$source.relative; canonical_git_blob=$blob.Stdout.Trim(); filtered_worktree_blob=$filtered.Stdout.Trim(); raw_worktree_blob=$raw.Stdout.Trim() })
    }
    foreach ($source in @(
        @{ relative='Tests/Release/Invoke-ZipWriterPackageFramework.ps1'; path=$wrapperPath },
        @{ relative=$mainSourceRelative; path=$mainSourcePath }
    )) {
        $filtered = Invoke-OwnedProcess -FileName $GitPath -Arguments @('-C', $repoRoot, 'hash-object', ('--path=' + $source.relative), $source.path) -TimeoutMilliseconds 20000
        $raw = Invoke-OwnedProcess -FileName $GitPath -Arguments @('-C', $repoRoot, 'hash-object', '--no-filters', $source.path) -TimeoutMilliseconds 20000
        if ($filtered.ExitCode -ne 0 -or -not $filtered.CaptureComplete -or $filtered.Stderr.Length -ne 0 -or
            $raw.ExitCode -ne 0 -or -not $raw.CaptureComplete -or $raw.Stderr.Length -ne 0 -or
            $filtered.Stdout.Trim() -cne $raw.Stdout.Trim()) { throw 'NEW_SOURCE_BYTES_NOT_CANONICAL' }
        $gitChecks.Add([pscustomobject]@{ path=$source.relative; filtered_worktree_blob=$filtered.Stdout.Trim(); raw_worktree_blob=$raw.Stdout.Trim(); no_commit_source=$true })
    }

    $stage = 'PACKAGE_BINDING'
    $packageBuffer = [IO.File]::ReadAllBytes($packagePath)
    $sidecarBytes = [IO.File]::ReadAllBytes($sidecarPath)
    if ((Get-Sha256 $packageBuffer) -cne $packageSha256 -or (Get-Sha256 $sidecarBytes) -cne $sidecarSha256) { throw 'PACKAGE_SHA256_MISMATCH' }
    $sidecarText = [Text.Encoding]::ASCII.GetString($sidecarBytes)
    if ($sidecarText -cne ($packageSha256 + '  ' + [IO.Path]::GetFileName($packagePath) + [char]10)) { throw 'PACKAGE_SIDECAR_MISMATCH' }
    $zipStream = [IO.MemoryStream]::new($packageBuffer, $false)
    try {
        $archive = [IO.Compression.ZipArchive]::new($zipStream, [IO.Compression.ZipArchiveMode]::Read, $true)
        try {
            $prefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
            $manifestBytes = Read-EntryBytes (Get-UniqueEntry $archive ($prefix + 'CLR-PACKAGE.json'))
            $manifest = [Text.Encoding]::UTF8.GetString($manifestBytes) | ConvertFrom-Json -AsHashtable -Depth 30
            if ($manifest.schema_version -cne '1.0' -or $manifest.state -cne 'prepared_not_published' -or
                $manifest.qualification_state -cne 'qualified' -or $manifest.publication_authorized -isnot [bool] -or
                $manifest.publication_authorized -cne $false) { throw 'PACKAGE_MANIFEST_STATE' }
            $artifact = @($manifest.artifacts | Where-Object { $_.module_id -ceq 'toolbelt.archive.zip-memory' })
            $binaryName = 'Binaries/' + $expectedAssembly
            $record = $manifest.files[$binaryName]
            $dllEntry = Get-UniqueEntry $archive ($prefix + $binaryName)
            $dllBytes = Read-EntryBytes $dllEntry
            $dllSha512 = Get-Sha512 $dllBytes
            if ($artifact.Count -ne 1 -or $artifact[0].file -cne $expectedAssembly -or
                $artifact[0].origin -cne 'reproducible_double_build' -or $artifact[0].sha256 -cne $expectedAssemblySha256 -or
                $artifact[0].sha512 -cne $dllSha512 -or $null -eq $record -or
                $record.sha256 -cne $expectedAssemblySha256 -or $record.size -ne $expectedAssemblySize -or
                $dllBytes.Length -ne $expectedAssemblySize -or (Get-Sha256 $dllBytes) -cne $expectedAssemblySha256) {
                throw 'PACKAGE_DLL_BINDING'
            }
        } finally { $archive.Dispose() }
    } finally { $zipStream.Dispose() }

    $stage = 'SOURCE_AST'
    $writerBytes = [IO.File]::ReadAllBytes($writerSourcePath)
    $entryBytes = [IO.File]::ReadAllBytes($entrySourcePath)
    $mainBytes = [IO.File]::ReadAllBytes($mainSourcePath)
    if ((Get-Sha256 $writerBytes) -cne $initialPins[$writerSourcePath] -or
        (Get-Sha256 $entryBytes) -cne $initialPins[$entrySourcePath] -or
        (Get-Sha256 $mainBytes) -cne $initialPins[$mainSourcePath]) { throw 'SOURCE_SNAPSHOT_DRIFT' }
    $writerText = [Text.UTF8Encoding]::new($false, $true).GetString($writerBytes)
    $tokens = $null; $parseErrors = $null
    $writerAst = [Management.Automation.Language.Parser]::ParseInput($writerText, [ref]$tokens, [ref]$parseErrors)
    if (@($parseErrors).Count -ne 0) { throw 'WRITER_SOURCE_PARSE' }
    $hereStrings = @($writerAst.FindAll({ param($node)
        $node -is [Management.Automation.Language.StringConstantExpressionAst] -and
        $node.StringConstantType -eq [Management.Automation.Language.StringConstantType]::SingleQuotedHereString
    }, $true))
    if ($hereStrings.Count -ne 1) { throw 'WRITER_HERESTRING_COUNT' }
    $writerCSharp = [string]$hereStrings[0].Value
    if ([regex]::Matches($writerCSharp, 'public\s+static\s+class\s+WriterFramework').Count -ne 1) { throw 'WRITER_CLASS_BINDING' }
    $copyPath = Join-Path $output $expectedAssembly
    $exePath = Join-Path $output 'ZipWriterPackageFramework.exe'
    $entryCsPath = Join-Path $output 'EntrySecurity.Framework.Snapshot.cs'
    $writerCsPath = Join-Path $output 'WriterFramework.Extracted.cs'
    $mainCsPath = Join-Path $output 'WriterPackageHarness.cs'

    $stage = 'OUTPUT_CREATE'
    [void][IO.Directory]::CreateDirectory($output)
    if (([IO.File]::GetAttributes($output) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'OUTPUT_REPARSE_POINT' }
    Write-NewFile $copyPath $dllBytes
    Write-NewFile $entryCsPath $entryBytes
    Write-NewFile $writerCsPath ([Text.UTF8Encoding]::new($false).GetBytes($writerCSharp))
    Write-NewFile $mainCsPath $mainBytes
    $copyLease = [IO.File]::Open($copyPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    if ($copyLease.Length -ne $expectedAssemblySize -or (Get-Sha256 ([IO.File]::ReadAllBytes($copyPath))) -cne $expectedAssemblySha256) { throw 'PACKAGE_COPY_BINDING' }

    $compiledPinsBefore = @(
        [pscustomobject]@{ name='PackageDllCopy'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($copyPath))) },
        [pscustomobject]@{ name='EntrySecuritySnapshot'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($entryCsPath))) },
        [pscustomobject]@{ name='WriterFrameworkExtract'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($writerCsPath))) },
        [pscustomobject]@{ name='PackageHarnessSource'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($mainCsPath))) }
    )
    if ($compiledPinsBefore[0].sha256 -cne $expectedAssemblySha256 -or
        $compiledPinsBefore[1].sha256 -cne (Get-Sha256 $entryBytes) -or
        $compiledPinsBefore[2].sha256 -cne (Get-Sha256 ([Text.UTF8Encoding]::new($false).GetBytes($writerCSharp))) -or
        $compiledPinsBefore[3].sha256 -cne $initialPins[$mainSourcePath]) { throw 'PRECOMPILE_SNAPSHOT_BINDING' }

    $stage = 'COMPILER'
    $argv = @('/nologo','/noconfig','/nostdlib+','/optimize+','/deterministic+','/langversion:7.3','/target:exe','/platform:x64','/checked-',('/main:WriterPackageHarness'),('/out:'+$exePath))
    foreach ($reference in $references) { $argv += ,('/reference:'+(Join-Path $refRoot $reference)) }
    $argv += ,('/reference:'+$copyPath)
    $argv += @($entryCsPath, $writerCsPath, $mainCsPath)
    $stdoutPath = Join-Path $output 'Compiler.stdout.bin'
    $compile = Invoke-OwnedProcess -FileName $CompilerPath -Arguments $argv -TimeoutMilliseconds 30000 -BinaryOutputPath $stdoutPath
    $compilerStdout = [IO.File]::ReadAllBytes($stdoutPath)
    Write-NewText (Join-Path $output 'Compiler.stderr.private.txt') $compile.Stderr
    $phaseRecords.Add([pscustomobject]@{ phase='Compile'; exit_code=$compile.ExitCode; capture_complete=$compile.CaptureComplete; stdout_sha256=(Get-Sha256 $compilerStdout); stderr_sha256=(Get-Sha256 ([Text.UTF8Encoding]::new($false).GetBytes($compile.Stderr))) })
    if ($compile.ExitCode -ne 0 -or -not $compile.CaptureComplete -or $compilerStdout.Length -ne 0 -or $compile.Stderr.Length -ne 0) { throw 'COMPILER_RESULT_REJECTED' }

    $exeSha256 = Get-Sha256 ([IO.File]::ReadAllBytes($exePath))
    $compiledPinsAfterCompile = @($compiledPinsBefore) + @([pscustomobject]@{ name='CompiledHarnessExe'; sha256=$exeSha256 })
    $stage = 'RUNTIME'
    $stdoutPath = Join-Path $output 'Writer.stdout.bin'
    $runtimeArgs = @($copyPath, $expectedAssemblySha256, $expectedAssemblyVersion)
    $execution = Invoke-OwnedProcess -FileName $exePath -Arguments $runtimeArgs -TimeoutMilliseconds 120000 -BinaryOutputPath $stdoutPath
    $runtimeStdoutBytes = [IO.File]::ReadAllBytes($stdoutPath)
    $runtimeStdout = [Text.Encoding]::UTF8.GetString($runtimeStdoutBytes)
    Write-NewText (Join-Path $output 'Writer.stderr.private.txt') $execution.Stderr
    $expectedStdout = "ZIP_ENTRY_SECURITY_PASS cases=7`r`nZIP Writer Framework: independent ZipArchive roundtrips, empty Deflate, deterministic Stored, boundaries, names, malformed transport and parallel calls PASS.`r`nZIP_WRITER_PACKAGE_FRAMEWORK_PASS`r`n"
    $phaseRecords.Add([pscustomobject]@{ phase='WriterRuntime'; exit_code=$execution.ExitCode; capture_complete=$execution.CaptureComplete; stdout_sha256=(Get-Sha256 $runtimeStdoutBytes); stderr_sha256=(Get-Sha256 ([Text.UTF8Encoding]::new($false).GetBytes($execution.Stderr))) })
    if ($execution.ExitCode -ne 0 -or -not $execution.CaptureComplete -or $execution.Stderr.Length -ne 0 -or $runtimeStdout -cne $expectedStdout) { throw 'WRITER_RUNTIME_RESULT_REJECTED' }
    $markers = @($runtimeStdout -split "`r`n" | Where-Object { $_.Length -gt 0 })

    $stage = 'POSTPINS'
    foreach ($pin in $allPins) {
        if ((Get-Sha256 ([IO.File]::ReadAllBytes($pin.path))) -cne $pin.sha256) { throw 'INPUT_PIN_DRIFT' }
    }
    $inputPinsAfter = @($allPins | ForEach-Object {
        [pscustomobject]@{ path=$_.path; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($_.path))) }
    })
    $compiledPinsAfter = @(
        [pscustomobject]@{ name='PackageDllCopy'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($copyPath))) },
        [pscustomobject]@{ name='EntrySecuritySnapshot'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($entryCsPath))) },
        [pscustomobject]@{ name='WriterFrameworkExtract'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($writerCsPath))) },
        [pscustomobject]@{ name='PackageHarnessSource'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($mainCsPath))) },
        [pscustomobject]@{ name='CompiledHarnessExe'; sha256=(Get-Sha256 ([IO.File]::ReadAllBytes($exePath))) }
    )
    for ($i=0; $i -lt $compiledPinsBefore.Count; $i++) {
        if ($compiledPinsBefore[$i].sha256 -cne $compiledPinsAfter[$i].sha256) { throw 'OUTPUT_PIN_DRIFT' }
    }
    if ($compiledPinsAfter[4].sha256 -cne $compiledPinsAfterCompile[4].sha256) { throw 'OUTPUT_PIN_DRIFT' }
    if ($compiledPinsAfter[0].sha256 -cne $expectedAssemblySha256) { throw 'OUTPUT_PIN_DRIFT' }
    $status = 'PASS'
} catch {
    $failure = [string]$_.Exception.Message
    if (-not [IO.Directory]::Exists($output)) {
        # No output is created for rejected paths or failed preflight.
        throw
    }
} finally {
    if ($null -ne $copyLease) { $copyLease.Dispose(); $copyLease = $null }
    if ([IO.Directory]::Exists($output) -and -not [IO.File]::Exists((Join-Path $output 'WriterEvidence.private.json'))) {
        $outputPins = @(Get-ChildItem -LiteralPath $output -File -Force | ForEach-Object {
            $bytes = [IO.File]::ReadAllBytes($_.FullName)
            [pscustomobject]@{ name=$_.Name; size=$bytes.Length; sha256=(Get-Sha256 $bytes) }
        } | Sort-Object name)
        $receipt = [ordered]@{
            schema='zip-writer-package-framework/v1'; result=$status; stage=$stage; failure=$failure
            package_sha256=$packageSha256; package_sidecar_sha256=$sidecarSha256
            assembly_sha256=$expectedAssemblySha256; assembly_version=$expectedAssemblyVersion
            writer_source_sha256=if($allPins.Count -gt 2){$allPins[2].sha256}else{$null}
            entry_security_source_sha256=if($allPins.Count -gt 3){$allPins[3].sha256}else{$null}
            extracted_writer_sha256=if($null -ne $writerCSharp){Get-Sha256 ([Text.UTF8Encoding]::new($false).GetBytes($writerCSharp))}else{$null}
            loaded_assembly_assertion=($status -eq 'PASS')
            loaded_assembly_before=[ordered]@{ location=$copyPath; version=$expectedAssemblyVersion; sha256=$expectedAssemblySha256 }
            loaded_assembly_after=[ordered]@{ location=$copyPath; version=$expectedAssemblyVersion; sha256=$expectedAssemblySha256 }
            markers=$markers; phases=@($phaseRecords); canonical_source_checks=@($gitChecks)
            input_pins_before=@($allPins); input_pins_after=$inputPinsAfter
            compiled_outputs_before=$compiledPinsBefore; compiled_outputs_after_compile=$compiledPinsAfterCompile
            compiled_outputs_after_runtime=$compiledPinsAfter; output_pins=$outputPins
        }
        Save-Json (Join-Path $output 'WriterEvidence.private.json') $receipt
    }
}
if ($status -ne 'PASS') { throw ('ZIP_WRITER_FRAMEWORK_FAILED:' + $failure) }
'PASS ZIP_WRITER_PACKAGE_FRAMEWORK'
