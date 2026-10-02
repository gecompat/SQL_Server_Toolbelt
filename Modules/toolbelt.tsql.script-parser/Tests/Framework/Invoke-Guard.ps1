[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltParserPureGuard-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$executable = Join-Path $tempRoot 'GuardTests.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$compilerOutput = & $compiler /nologo /optimize+ /target:exe "/out:$executable" (Join-Path $moduleRoot 'Clr/PreparseGuard.cs') (Join-Path $PSScriptRoot 'GuardTests.cs') (Join-Path $PSScriptRoot 'TestInputs.cs') 2>&1
if ($LASTEXITCODE -ne 0) { throw 'GUARD_BUILD_FAILED' }
$psi = [Diagnostics.ProcessStartInfo]::new($executable)
$psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.WindowStyle = 'Hidden'; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
$child = [Diagnostics.Process]::Start($psi)
$stdout = $child.StandardOutput.ReadToEndAsync(); $stderr = $child.StandardError.ReadToEndAsync()
try {
    if (-not $child.WaitForExit(10000)) { $child.Kill(); throw 'GUARD_TIMEOUT' }
    $output = $stdout.GetAwaiter().GetResult()
    if ($child.ExitCode -ne 0 -or $output.Length -gt 4096 -or -not $output.StartsWith('GUARD_PASS ', [StringComparison]::Ordinal)) { throw 'GUARD_FAILED' }
    $output.Trim()
} finally { $child.Dispose() }
