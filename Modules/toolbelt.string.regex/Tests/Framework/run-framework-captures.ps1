[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Jeder synthetische Test läuft mit explizitem Stack im Framework-Kindprozess.
$assembly=(Resolve-Path -LiteralPath $AssemblyPath).Path
$csc=$null
$vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if(Test-Path -LiteralPath $vswhere -PathType Leaf){
    $csc=& $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild/**/Bin/Roslyn/csc.exe' | Select-Object -First 1
}
if(-not $csc){
    $frameworkCompiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
    if(Test-Path -LiteralPath $frameworkCompiler -PathType Leaf){$csc=$frameworkCompiler}
}
if(-not $csc){
    $ssmsCompiler=Join-Path $env:ProgramFiles 'Microsoft SQL Server Management Studio 22/Release/MSBuild/Current/Bin/Roslyn/csc.exe'
    if(Test-Path -LiteralPath $ssmsCompiler -PathType Leaf){$csc=$ssmsCompiler}
}
if(-not $csc){throw 'Framework-C#-Compiler fehlt.'}
$testRoot=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltRegexCaptureContract-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $testRoot
$privateAssembly=Join-Path $testRoot 'Toolbelt.String.Regex.dll'
Copy-Item -LiteralPath $assembly -Destination $privateAssembly
$exe=Join-Path $testRoot 'CaptureContract.exe'
& $csc /nologo /target:exe /optimize+ /out:$exe /reference:$privateAssembly /reference:System.Data.dll (Join-Path $PSScriptRoot 'CaptureContract.cs')
if($LASTEXITCODE -ne 0){throw 'Capture-Vertragsfixture kompiliert nicht.'}
foreach($case in @('legacy','budget','core','faults','history','output','exhaustive')){
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$exe; $info.Arguments=$case
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$info
    try {
        if(-not $process.Start()){throw 'Framework-Kindprozess startet nicht.'}
        $null=$process.Handle
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        if(-not $process.WaitForExit(10000)){ $process.Kill(); $process.WaitForExit(); throw 'Framework-Kindprozess überschreitet zehn Sekunden.' }
        $process.Refresh(); $code=$process.ExitCode
        if($code -ne 0 -or $stderr.Result.Length -ne 0){throw ('Capture-Vertragsfixture fehlgeschlagen: '+$case+' '+$stderr.Result)}
        if($stdout.Result -notmatch ('^PASS '+$case+' [0-9]+\s*$')){throw 'Ungültiger Framework-Ergebnisstatus.'}
        $stdout.Result.Trim()
    } finally {$process.Dispose()}
}
