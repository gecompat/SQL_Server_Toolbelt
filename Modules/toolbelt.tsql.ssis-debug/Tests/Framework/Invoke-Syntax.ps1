[CmdletBinding()]
param([Parameter(Mandatory)][string]$ScriptDomDllPath,[switch]$SourceOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $moduleRoot '../../Scripts/Clr/Resolve-ToolbeltScriptDom.ps1')
$ScriptDomDllPath=Resolve-ToolbeltScriptDom -Path $ScriptDomDllPath
$expected='634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813'
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
$files+=@('Examples/Installation/PrepareServer.sql','Examples/Installation/VerifyInstallation.sql')
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
