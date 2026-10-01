[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if (-not $msbuild) {
    $candidate = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild/**/Bin/MSBuild.exe' | Select-Object -First 1
    if ($candidate) { $msbuild = [pscustomobject]@{ Source = $candidate } }
}
if (-not $msbuild) { throw 'Vorhandene Framework-4.8-Toolchain nicht verfügbar.' }
$zip = Join-Path $PSScriptRoot '../../Modules/toolbelt.archive.zip-memory/Clr/Toolbelt.Archive.ZipMemory.csproj'
& $msbuild.Source $zip /t:Rebuild /p:Configuration=Release /m:1 /v:minimal
if ($LASTEXITCODE) { throw 'ZIP-Build fehlgeschlagen.' }
& $msbuild.Source (Join-Path $PSScriptRoot '../../Modules/toolbelt.file.xlsx-memory/Clr/Toolbelt.File.XlsxMemory.csproj') /t:Rebuild /m:1 /v:minimal
if ($LASTEXITCODE) { throw 'XLSX-Produktionskernbuild fehlgeschlagen.' }
& $msbuild.Source (Join-Path $PSScriptRoot 'Qualification.csproj') /t:Rebuild /m:1 /v:minimal
if ($LASTEXITCODE) { throw 'XLSX-Qualifizierungsbuild fehlgeschlagen.' }
& $msbuild.Source (Join-Path $PSScriptRoot 'Sandbox.csproj') /t:Rebuild /m:1 /v:minimal
if ($LASTEXITCODE) { throw 'Sandbox-Build fehlgeschlagen.' }
# Der Harness ist Framework-only und verwendet ZipArchive ausschließlich als
# unabhängigen synthetischen Fixture-Writer, niemals im Workbookprovider.
$frameworkShell = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
# Separater Harness-Watchdog, kein öffentlicher Runtime-Timeout. Asynchrones
# Lesen vermeidet volle stdout-/stderr-Pipes beim Warten auf den Kindprozess.
$start=[Diagnostics.ProcessStartInfo]::new()
$start.FileName=$frameworkShell
$start.Arguments='-NoProfile -File "'+(Join-Path $PSScriptRoot 'Test-Framework.ps1')+'"'
$start.UseShellExecute=$false;$start.CreateNoWindow=$true
$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
$process=[Diagnostics.Process]::new();$process.StartInfo=$start
try {
    [void]$process.Start()
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
    if(-not $process.WaitForExit(15000)) {
        $process.Kill();$process.WaitForExit()
        throw 'INCONCLUSIVE: Framework-Harness-Watchdog überschritten; keine Runtime-Wallclockzusage.'
    }
    $output=$stdout.GetAwaiter().GetResult();[void]$stderr.GetAwaiter().GetResult()
    if($process.ExitCode-ne0){throw 'Framework-Qualifizierung fehlgeschlagen; nur lokale synthetische Diagnose prüfen.'}
    $output.TrimEnd()
} finally {$process.Dispose()}
