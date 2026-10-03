[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1')
$csc=$null
$vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if(Test-Path -LiteralPath $vswhere){
 $discovery=Invoke-OwnedProcess -FileName $vswhere -Arguments @('-latest','-products','*','-requires','Microsoft.Component.MSBuild','-find','MSBuild/**/Bin/Roslyn/csc.exe') -TimeoutMilliseconds 15000
 if($discovery.ExitCode -ne 0 -or $discovery.Stderr.Length -ne 0){throw 'FRAMEWORK_COMPILER_DISCOVERY_FAILED'}
 $csc=($discovery.Stdout -split '\r?\n' | Where-Object {$_ -ne ''} | Select-Object -First 1)
}
if(-not $csc){$candidate=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe';if(Test-Path -LiteralPath $candidate){$csc=$candidate}}
if(-not $csc){throw 'Framework-C#-Compiler fehlt.'}
$privateRoot=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltDistanceContract-'+[guid]::NewGuid().ToString('N'))
$null=[IO.Directory]::CreateDirectory($privateRoot)
$exe=Join-Path $privateRoot 'DistanceContract.exe'
$goldens=Join-Path $privateRoot 'goldens.txt'
$reference=Invoke-OwnedProcess -FileName 'python' -Arguments @('-B',(Join-Path $PSScriptRoot 'reference.py')) -TimeoutMilliseconds 45000
if($reference.ExitCode -ne 0 -or $reference.Stderr.Length -ne 0){throw 'Unabhängige Matrixreferenz fehlgeschlagen.'}
$generated=Invoke-OwnedProcess -FileName 'python' -Arguments @('-B',(Join-Path $PSScriptRoot 'make_goldens.py'),$goldens) -TimeoutMilliseconds 45000
if($generated.ExitCode -ne 0 -or $generated.Stderr.Length -ne 0){throw 'Goldenerzeugung fehlgeschlagen.'}
$compiled=Invoke-OwnedProcess -FileName $csc -Arguments @('/nologo','/target:exe','/checked+','/optimize+','/reference:System.Data.dll',('/out:'+$exe),(Join-Path $moduleRoot 'Clr/UnicodeScalar.cs'),(Join-Path $moduleRoot 'Clr/DistanceKernel.cs'),(Join-Path $moduleRoot 'Clr/DistanceProvider.cs'),(Join-Path $PSScriptRoot 'DistanceContract.cs')) -TimeoutMilliseconds 15000
if($compiled.ExitCode -ne 0 -or $compiled.Stderr.Length -ne 0){throw 'Framework-Vertragsfixture kompiliert nicht.'}
foreach($case in @('goldens','validation','lev_standard','osa_standard','lev_large','osa_large','lev_band','osa_band','osa_supplementary_band')){
 $arguments=if($case -eq 'goldens'){@('goldens',$goldens)}else{@($case)}
 $result=Invoke-OwnedProcess -FileName $exe -Arguments $arguments -TimeoutMilliseconds 45000
 if($result.ExitCode -ne 0 -or $result.Stderr.Length -ne 0 -or $result.Stdout -cnotmatch '(?:^|\r?\n)PASS;ASSERTIONS=[0-9]+\s*\z'){throw ('Framework-Test fehlgeschlagen: '+$case)}
 $case+': '+$result.Stdout.Trim()
}
# Eigene Jaro-Vertragsfixture; die neun bestehenden Distanzkinder bleiben vollständig.
$jaroExe=Join-Path $privateRoot 'JaroContract.exe'
$compiled=Invoke-OwnedProcess -FileName $csc -Arguments @('/nologo','/target:exe','/checked+','/optimize+','/reference:System.Data.dll',('/out:'+$jaroExe),(Join-Path $moduleRoot 'Clr/UnicodeScalar.cs'),(Join-Path $moduleRoot 'Clr/JaroKernel.cs'),(Join-Path $moduleRoot 'Clr/JaroProvider.cs'),(Join-Path $PSScriptRoot 'JaroContract.cs')) -TimeoutMilliseconds 15000
if($compiled.ExitCode -ne 0 -or $compiled.Stderr.Length -ne 0){throw 'Jaro-Vertragsfixture kompiliert nicht.'}
foreach($culture in @('de-DE','en-US','tr-TR')){
 $result=Invoke-OwnedProcess -FileName $jaroExe -Arguments @($culture) -TimeoutMilliseconds 45000
 if($result.ExitCode -ne 0 -or $result.Stderr.Length -ne 0 -or $result.Stdout -cnotmatch '^PASS;ASSERTIONS=[0-9]+\s*\z'){throw 'Jaro-Vertragsfixture fehlgeschlagen.'}
 $culture+': '+$result.Stdout.Trim()
}
