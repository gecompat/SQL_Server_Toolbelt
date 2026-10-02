[CmdletBinding()]
param([string]$CompilerPath,[int]$DeadlineSeconds=20)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($DeadlineSeconds -lt 1 -or $DeadlineSeconds -gt 60){throw 'Ungültige Testdeadline.'}
if(-not $CompilerPath){
 $vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
 if(Test-Path -LiteralPath $vswhere){$CompilerPath=@(& $vswhere -latest -products '*' -find 'MSBuild/**/Bin/Roslyn/csc.exe')[0]}
}
if(-not $CompilerPath -or -not(Test-Path -LiteralPath $CompilerPath)){throw 'Vorhandener Frameworkcompiler erforderlich; keine Installation.'}
$refs=Join-Path ${env:ProgramFiles(x86)} 'Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8'
$moduleRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltXlsxTypeFramework-'+[guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $scratch)
$exe=Join-Path $scratch 'Types.exe'
$arguments=@('/nologo','/target:exe','/optimize+','/deterministic+','/langversion:7.3','/nostdlib+',('/out:'+ $exe),
 ('/reference:'+ (Join-Path $refs 'mscorlib.dll')),('/reference:'+ (Join-Path $refs 'System.dll')),('/reference:'+ (Join-Path $refs 'System.Data.dll')),
 (Join-Path $moduleRoot 'Clr/XlsxCellType.cs'),(Join-Path $PSScriptRoot 'TypeHarness.cs'))
$compiler=[Diagnostics.ProcessStartInfo]::new($CompilerPath)
$compiler.UseShellExecute=$false;$compiler.CreateNoWindow=$true;$compiler.RedirectStandardOutput=$true;$compiler.RedirectStandardError=$true
$compiler.Arguments=($arguments|ForEach-Object {'"'+$_+'"'}) -join ' '
$process=[Diagnostics.Process]::Start($compiler)
if(-not $process.WaitForExit($DeadlineSeconds*1000)){$process.Kill();throw 'Frameworkcompile überschritt Deadline.'}
$compileExit=$process.ExitCode;$compileText=$process.StandardOutput.ReadToEnd()+$process.StandardError.ReadToEnd();$process.Dispose()
if($compileExit){throw 'Frameworkcompile fehlgeschlagen; keine Runtimequalifikation.'}
foreach($culture in @('de-DE','en-US','tr-TR')){
 $start=[Diagnostics.ProcessStartInfo]::new($exe)
 $start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
 $start.Arguments='"'+(Join-Path $PSScriptRoot 'api-goldens.tsv')+'" "'+(Join-Path $PSScriptRoot 'numeric-goldens.txt')+'" '+$culture
 $child=[Diagnostics.Process]::Start($start)
 if(-not $child.WaitForExit($DeadlineSeconds*1000)){$child.Kill();throw 'Frameworktest überschritt Deadline.'}
 $output=$child.StandardOutput.ReadToEnd();$stderr=$child.StandardError.ReadToEnd();$exit=$child.ExitCode;$child.Dispose()
 if($exit -ne 0 -or $stderr -or $output -notmatch '^PASS API=652 NUMERIC=370 ASSERTIONS=\d+\s*$'){throw 'Frameworktest fehlgeschlagen.'}
 Write-Output ($culture+': '+$output.Trim())
}
Write-Output 'PASS: Nur Zellkern-Frameworktests; keine SQL-/SAFE-/Lifecycle-/Heapqualifikation.'
