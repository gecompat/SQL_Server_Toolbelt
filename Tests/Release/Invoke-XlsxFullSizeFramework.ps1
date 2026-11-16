# Vier feste XLSX-Grenzpaare gegen die unveränderten, bereits gebundenen DLLs.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory,
      [string]$PythonPath = 'python')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$out = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $out) { throw 'OUTPUT_NOT_FRESH' }
$watch = [Diagnostics.Stopwatch]::StartNew()
$pins = @{}
function Pin([string]$Path) {
    $resolved = [IO.Path]::GetFullPath($Path)
    $script:pins[$resolved] = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash.ToLowerInvariant()
    return $resolved
}
function Check-Pins {
    foreach ($path in $pins.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $pins[$path]) { throw 'INPUT_DRIFT' }
    }
    if ($watch.Elapsed.TotalMinutes -ge 10) { throw 'FRAMEWORK_DEADLINE' }
}
$helper = Pin (Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
. $helper
$python = Pin (Get-Command $PythonPath -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$composer = Pin (Join-Path $PSScriptRoot 'compose_xlsx_full_size.py')
$source = Pin (Join-Path $PSScriptRoot 'Runtime/XlsxFullSize.Framework.cs')
[void](Pin $PSCommandPath)
$priorPath = Pin (Join-Path $repo 'Releases/1.0.0/xlsx-sst-budget-correction.json')
$prior = Get-Content -LiteralPath $priorPath -Raw | ConvertFrom-Json
$bundle = Pin (Join-Path $repo $prior.candidate_bundle.path)
if ($pins[$bundle] -cne $prior.candidate_bundle.sha256) { throw 'CANDIDATE_BUNDLE_HASH' }
$vswhere = Pin (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe')
$discovery = Invoke-OwnedProcess -FileName $vswhere -Arguments @('-latest','-products','*','-requires','Microsoft.Component.MSBuild','-find','MSBuild/**/Bin/Roslyn/csc.exe') -TimeoutMilliseconds 20000
if ($discovery.ExitCode -ne 0 -or -not $discovery.CaptureComplete -or $discovery.Stderr.Length) { throw 'COMPILER_DISCOVERY' }
$found = @($discovery.Stdout -split '\r?\n' | Where-Object { $_.Trim() })
if ($found.Count -ne 1) { throw 'COMPILER_COUNT' }
$compiler = Pin $found[0]
$refRoot = Join-Path ${env:ProgramFiles(x86)} 'Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8'
$refs = @(foreach ($name in @('mscorlib','System','System.Data','System.Xml','System.Core')) { Pin (Join-Path $refRoot ($name+'.dll')) })
[void][IO.Directory]::CreateDirectory($out)
$record = [ordered]@{status='RUNNING'; sql_executed=$false; product_build=$false; phases=@()}
function Run([string]$Name,[string]$File,[string[]]$Argv,[int]$Milliseconds) {
    Check-Pins
    $result = Invoke-OwnedProcess -FileName $File -Arguments $Argv -TimeoutMilliseconds $Milliseconds
    [IO.File]::WriteAllText((Join-Path $out ($Name+'.stdout.txt')), $result.Stdout)
    [IO.File]::WriteAllText((Join-Path $out ($Name+'.stderr.txt')), $result.Stderr)
    $record.phases += @{name=$Name; exit_code=$result.ExitCode; capture_complete=$result.CaptureComplete}
    if ($result.ExitCode -ne 0 -or -not $result.CaptureComplete -or $result.Stderr.Length) { throw ('PHASE_FAILED_'+$Name) }
    Check-Pins
    return $result.Stdout
}
try {
    $archive = [IO.Compression.ZipFile]::OpenRead($bundle)
    try {
        foreach ($file in $prior.candidate_bundle.files.PSObject.Properties) {
            $entry = @($archive.Entries | Where-Object { $_.FullName -ceq $file.Name })
            if ($entry.Count -ne 1) { throw 'BUNDLE_ENTRY_COUNT' }
            $stream = $entry[0].Open(); $memory = [IO.MemoryStream]::new()
            try { $stream.CopyTo($memory); $bytes=$memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
            $digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
            if ($digest -cne $file.Value) { throw 'BUNDLE_ENTRY_HASH' }
            if ($file.Name.StartsWith('Sources/')) {
                $current = Pin (Join-Path $repo $file.Name.Substring(8))
                $normal = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($current)).Replace("`r`n","`n")
                $old = [Text.Encoding]::UTF8.GetString($bytes).Replace("`r`n","`n")
                if ($normal -cne $old) { throw 'CURRENT_PRODUCT_SOURCE_DRIFT' }
            }
            if ($file.Name.StartsWith('Binaries/')) {
                $target = Join-Path $out ([IO.Path]::GetFileName($file.Name))
                [IO.File]::WriteAllBytes($target,$bytes); [void](Pin $target)
            }
        }
    } finally { $archive.Dispose() }
    # Die Abhängigkeits-DLL und ihre fünf kompilierten Quellen bleiben identisch.
    $zipRecordPath = Pin (Join-Path $repo 'Releases/1.0.0/XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.json')
    $zipRecord = Get-Content -LiteralPath $zipRecordPath -Raw | ConvertFrom-Json
    $zipPins = @($zipRecord.input_pins.pins | Where-Object { $_.path.StartsWith('Modules/toolbelt.archive.zip-memory/Clr/') })
    if ($zipPins.Count -ne 5) { throw 'ZIP_SOURCE_COUNT' }
    foreach ($pin in $zipPins) {
        $path = Pin (Join-Path $repo $pin.path)
        if ($pins[$path] -cne $pin.sha256) { throw 'ZIP_SOURCE_PIN_DRIFT' }
    }
    $fixtureDir = Join-Path $out 'Fixtures'
    $composed = Run 'Compose' $python @($composer,$fixtureDir) 120000
    if ($composed.Trim() -cne 'PASS XLSX FULL SIZE FIXTURES 8') { throw 'COMPOSER_MARKER' }
    foreach ($file in Get-ChildItem -LiteralPath $fixtureDir -File) { [void](Pin $file.FullName) }
    $executable = Join-Path $out 'XlsxFullSize.Framework.exe'
    $argv = @('/nologo','/noconfig','/nostdlib+','/target:exe',('/out:'+$executable))
    foreach ($ref in $refs) { $argv += '/reference:'+$ref }
    foreach ($name in @('Toolbelt.File.XlsxMemory.dll','Toolbelt.Archive.ZipMemory.dll')) { $argv += '/reference:'+(Join-Path $out $name) }
    $argv += $source
    if ((Run 'Compile' $compiler $argv 20000).Length) { throw 'COMPILER_NOT_QUIET' }
    [void](Pin $executable)
    $stdout = Run 'Boundary' $executable @($fixtureDir,$prior.candidate_dll_sha256,$prior.zip_dependency_sha256) 120000
    $fixtures = Get-Content -LiteralPath (Join-Path $fixtureDir 'fixtures.json') -Raw | ConvertFrom-Json
    $expected = @($fixtures.cases | ForEach-Object { 'PASS'+"`t"+$_.name+"`t"+$_.expected_error })
    if ((($stdout.TrimEnd() -split '\r?\n') -join "`n") -cne ($expected -join "`n")) { throw 'BOUNDARY_MARKERS' }
    $record.status = 'PASS_FRAMEWORK_ONLY'
    $record.cases = $fixtures.cases
    $record.xlsx_dll_sha256 = $prior.candidate_dll_sha256
    $record.zip_dll_sha256 = $prior.zip_dependency_sha256
} catch { $record.status='FAILED'; $record.failure=$_.Exception.Message; throw }
finally {
    $record.elapsed_seconds=$watch.Elapsed.TotalSeconds
    $record.private_pins=$pins
    [IO.File]::WriteAllText((Join-Path $out 'result.private.json'),($record|ConvertTo-Json -Depth 8))
}
Write-Output 'PASS XLSX FULL SIZE FRAMEWORK 8'
