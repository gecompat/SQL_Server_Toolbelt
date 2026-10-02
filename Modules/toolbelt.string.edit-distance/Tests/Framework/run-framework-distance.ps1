[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$csc=$null
$vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if(Test-Path -LiteralPath $vswhere){$csc=& $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild/**/Bin/Roslyn/csc.exe' | Select-Object -First 1}
if(-not $csc){$candidate=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe';if(Test-Path -LiteralPath $candidate){$csc=$candidate}}
if(-not $csc){throw 'Framework-C#-Compiler fehlt.'}
$privateRoot=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltDistanceContract-'+[guid]::NewGuid().ToString('N'))
$null=[IO.Directory]::CreateDirectory($privateRoot)
$exe=Join-Path $privateRoot 'DistanceContract.exe'
$goldens=Join-Path $privateRoot 'goldens.txt'
& python -B (Join-Path $PSScriptRoot 'reference.py')
if($LASTEXITCODE-ne0){throw 'Unabhängige Matrixreferenz fehlgeschlagen.'}
& python -B (Join-Path $PSScriptRoot 'make_goldens.py') $goldens
if($LASTEXITCODE-ne0){throw 'Goldenerzeugung fehlgeschlagen.'}
& $csc /nologo /target:exe /checked+ /optimize+ /reference:System.Data.dll /out:$exe (Join-Path $moduleRoot 'Clr/DistanceKernel.cs') (Join-Path $moduleRoot 'Clr/DistanceProvider.cs') (Join-Path $PSScriptRoot 'DistanceContract.cs')
if($LASTEXITCODE-ne0){throw 'Framework-Vertragsfixture kompiliert nicht.'}
foreach($case in @('goldens','validation','lev_standard','osa_standard','lev_large','osa_large','lev_band','osa_band','osa_supplementary_band')){
 $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$exe
 $info.Arguments=if($case-eq'goldens'){'goldens "'+$goldens+'"'}else{$case}
 $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
 $child=[Diagnostics.Process]::new();$child.StartInfo=$info
 try{
  if(-not $child.Start()){throw 'Framework-Kind startet nicht.'};$null=$child.Handle
  $stdout=$child.StandardOutput.ReadToEndAsync();$stderr=$child.StandardError.ReadToEndAsync()
  if(-not $child.WaitForExit(45000)){$child.Kill();$child.WaitForExit();throw 'Framework-Test überschreitet 45 Sekunden.'}
  $child.Refresh();if($child.ExitCode-ne0-or$stderr.Result.Length-ne0-or$stdout.Result-notmatch'PASS;ASSERTIONS=\d+'){throw ('Framework-Test fehlgeschlagen: '+$case)}
  $case+': '+$stdout.Result.Trim()
 }finally{$child.Dispose()}
}