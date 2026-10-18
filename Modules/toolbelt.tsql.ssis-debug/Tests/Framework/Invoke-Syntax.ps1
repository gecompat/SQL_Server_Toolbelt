[CmdletBinding()]
param([Parameter(Mandatory)][string]$ScriptDomDllPath,[switch]$SourceOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$expected='459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7'
if((Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $expected){throw 'SYNTAX_DEPENDENCY_PIN_MISMATCH'}
$tempRoot=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSsisSyntax-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot|Out-Null
Copy-Item -LiteralPath $ScriptDomDllPath -Destination $tempRoot
$exe=Join-Path $tempRoot 'SqlSyntaxTests.exe'
$compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
& $compiler /nologo /optimize+ /target:exe "/out:$exe" "/reference:$ScriptDomDllPath" (Join-Path $PSScriptRoot 'SqlSyntaxTests.cs')
if($LASTEXITCODE -ne 0){throw 'SYNTAX_HARNESS_BUILD_FAILED'}
$checks=0
$files=@('Source/USP_ExplainSsisDataFlow.sql','Source/USP_ExplainSsisDataFlowInternal.sql','Examples/SsmsDebugWalkthrough.sql')
if(-not $SourceOnly){$files+=@('Artifacts/Deploy.WithAssembly.sql','Artifacts/Uninstall.Expanded.sql')}
foreach($relative in $files){
 $path=Join-Path $moduleRoot $relative
 foreach($version in @(150,160,170)){
  $psi=[Diagnostics.ProcessStartInfo]::new($exe);$psi.Arguments='"'+$path+'" '+$version
  $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.WindowStyle='Hidden';$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  $child=[Diagnostics.Process]::Start($psi);$stdout=$child.StandardOutput.ReadToEndAsync();$stderr=$child.StandardError.ReadToEndAsync()
  try{if(-not $child.WaitForExit(40000)){$child.Kill();throw 'SYNTAX_WATCHDOG_TIMEOUT'};$output=$stdout.GetAwaiter().GetResult();$errorText=$stderr.GetAwaiter().GetResult();if($child.ExitCode -ne 0 -or $output.Trim() -ne 'SQL_SYNTAX_PASS' -or $errorText.Length -ne 0){throw ('SYNTAX_FAILED_'+$relative+'_'+$version+' '+$errorText)};$checks++}finally{$child.Dispose()}
 }
}
"SSIS_SQL_SYNTAX_PASS $checks bounded children; binary literal normalized; no SQL executed"
