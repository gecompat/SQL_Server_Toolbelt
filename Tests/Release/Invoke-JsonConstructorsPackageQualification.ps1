[CmdletBinding()]
param([Parameter(Mandatory)][string]$CompilerPath,[Parameter(Mandatory)][string]$ReferenceDirectory,
 [Parameter(Mandatory)][string]$FrameworkPowerShell,[Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'JSON_PACKAGE_POWERSHELL7_REQUIRED'}
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$output=[IO.Path]::GetFullPath($OutputDirectory)
$privatePrefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not $output.StartsWith($privatePrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_PACKAGE_PRIVATE_OUTPUT_REQUIRED'}
if(Test-Path -LiteralPath $output){throw 'JSON_PACKAGE_OUTPUT_EXISTS'}
& git -C $repoRoot check-ignore --quiet -- $output
if($LASTEXITCODE -ne 0){throw 'JSON_PACKAGE_OUTPUT_NOT_IGNORED'}
$helper=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
. $helper
$python=(Get-Command python -ErrorAction Stop).Source
$frameworkHost=(Get-Process -Id $PID).Path
$pythonGate=Join-Path $repoRoot 'Scripts/Release/json_constructor_package.py'
$package=Join-Path $repoRoot 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$sidecar=$package+'.sha256'
$frameworkRunner=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Tests/Framework/Invoke-Framework.ps1'
$sourceRunner=Join-Path $repoRoot 'Modules/toolbelt.json.schema/Tests/Framework/Invoke-SourceQualification.ps1'
$ilGate=Join-Path $repoRoot 'Modules/toolbelt.json.core/Tests/Framework/Test-JsonClosureIL.ps1'
$goldens=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Tests/Framework/BridgeGoldens.tsv'
$packageOutput=Join-Path $output 'package'
$frameworkOutput=Join-Path $output 'framework'
$ilEvidence=Join-Path $output 'JsonConstructors.IL.private.json'
$pinned=@($package,$sidecar,$pythonGate,$PSCommandPath,$helper,$frameworkRunner,$frameworkHost,$sourceRunner,$ilGate,$goldens,
 (Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Tests/Framework/ProductHarness.cs'),
 (Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Clr/Toolbelt.JsonConstructors.csproj'),
 (Join-Path $repoRoot 'Modules/toolbelt.json.core/Clr/Toolbelt.JsonCore.csproj'),
 (Join-Path $repoRoot 'Modules/toolbelt.json.schema/Clr/Toolbelt.JsonSchema.csproj')) |
 ForEach-Object { [pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} }
$record=[ordered]@{schema_version=1;status='FAILED';scope='JSON_CONSTRUCTORS_RELEASE_PACKAGE_FRAMEWORK_AND_CORE_CLOSURE_IL';package_sha256=$null;constructor_sha256=$null;core_sha256=$null;framework_suite='existing JSON constructor bridge goldens and framework source comparison';package_il='constructor direct IL; Core IL via byte-identical rebuilt closure';schema_package_bound=$false;post_pins=$false}
try {
 [void][IO.Directory]::CreateDirectory($output)
 $bindingProcess=Invoke-OwnedProcess -FileName $python -Arguments @('-B',$pythonGate,'--root',$repoRoot,'--output',$packageOutput) -TimeoutMilliseconds 20000
 if($bindingProcess.ExitCode -ne 0 -or -not $bindingProcess.CaptureComplete -or $bindingProcess.Stderr.Length -ne 0){throw 'JSON_PACKAGE_BINDING_FAILED'}
 $binding=$bindingProcess.Stdout | ConvertFrom-Json -ErrorAction Stop
 $constructorPath=Join-Path $packageOutput 'Toolbelt.JsonConstructors.dll'
 $corePath=Join-Path $packageOutput 'Toolbelt.JsonCore.dll'
 $constructorSha=(Get-FileHash -LiteralPath $constructorPath -Algorithm SHA256).Hash.ToLowerInvariant()
 $coreSha=(Get-FileHash -LiteralPath $corePath -Algorithm SHA256).Hash.ToLowerInvariant()
 if($constructorSha -cne $binding.files.'Toolbelt.JsonConstructors.dll'.sha256 -or $coreSha -cne $binding.files.'Toolbelt.JsonCore.dll'.sha256){throw 'JSON_PACKAGE_EXTRACTED_DLL_DRIFT'}
 $record.package_sha256=$binding.archive_sha256
 $record.constructor_sha256=$constructorSha
 $record.core_sha256=$coreSha
 $framework=Invoke-OwnedProcess -FileName $frameworkHost -Arguments @('-NoProfile','-NonInteractive','-File',$frameworkRunner,
   '-AssemblyPath',$constructorPath,'-CoreAssemblyPath',$corePath,'-CompilerPath',$CompilerPath,
   '-ReferenceDirectory',$ReferenceDirectory,'-FrameworkPowerShell',$FrameworkPowerShell,'-OutputDirectory',$frameworkOutput) -TimeoutMilliseconds 600000
 [IO.File]::WriteAllText((Join-Path $output 'Framework.stdout.private.txt'),$framework.Stdout)
 [IO.File]::WriteAllText((Join-Path $output 'Framework.stderr.private.txt'),$framework.Stderr)
 if($framework.ExitCode -ne 0 -or -not $framework.CaptureComplete -or $framework.Stderr.Length -ne 0 -or $framework.Stdout -cnotmatch '(?:^|\r?\n)PASS JSON_FRAMEWORK_CURRENT_CLOSURE_ONLY\s*\z'){throw 'JSON_PACKAGE_FRAMEWORK_QUALIFICATION_FAILED'}
 $builtCtor=Join-Path $frameworkOutput 'Toolbelt.JsonConstructors.dll'
 $builtCore=Join-Path $frameworkOutput 'Toolbelt.JsonCore.dll'
 if((Get-FileHash -LiteralPath $builtCtor -Algorithm SHA256).Hash.ToLowerInvariant() -cne $constructorSha -or
    (Get-FileHash -LiteralPath $builtCore -Algorithm SHA256).Hash.ToLowerInvariant() -cne $coreSha){throw 'JSON_PACKAGE_SOURCE_BINARY_MISMATCH'}
 $il=Invoke-OwnedProcess -FileName $FrameworkPowerShell -Arguments @('-NoProfile','-NonInteractive','-File',$ilGate,
   '-BinaryPath',$constructorPath,'-ExpectedSha256',$constructorSha.ToUpperInvariant(),'-CorePath',$corePath,
   '-ExpectedCoreSha256',$coreSha.ToUpperInvariant(),'-EvidencePath',$ilEvidence) -TimeoutMilliseconds 20000
 [IO.File]::WriteAllText((Join-Path $output 'IL.stdout.private.txt'),$il.Stdout)
 [IO.File]::WriteAllText((Join-Path $output 'IL.stderr.private.txt'),$il.Stderr)
 if($il.ExitCode -ne 0 -or -not $il.CaptureComplete -or $il.Stderr.Length -ne 0 -or $il.Stdout -cnotmatch '(?:^|\r?\n)PASS JSON_SHARED_PRODUCT_IL\s*\z'){throw 'JSON_PACKAGE_CORE_IL_FAILED'}
 $ilRecord=Get-Content -LiteralPath $ilEvidence -Raw | ConvertFrom-Json -ErrorAction Stop
 if($ilRecord.status -cne 'PASS' -or $ilRecord.unknown.Count -ne 0 -or $ilRecord.scope -cne 'own product and pinned shared Core calls only'){throw 'JSON_PACKAGE_IL_EVIDENCE_INVALID'}
 $record.status='PASS'
} finally {
 try {
  foreach($pin in $pinned){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash -cne $pin.sha256){throw 'JSON_PACKAGE_INPUT_PIN_DRIFT'}}
  if(Test-Path -LiteralPath $packageOutput){
   if((Get-FileHash -LiteralPath $constructorPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.constructor_sha256 -or
      (Get-FileHash -LiteralPath $corePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.core_sha256){throw 'JSON_PACKAGE_EXTRACTED_DLL_POSTPIN_DRIFT'}
  }
  $record.post_pins=$true
 }
 catch { $record.status='FAILED';$record.post_pins=$false }
 [IO.File]::WriteAllText((Join-Path $output 'Result.private.json'),($record|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
}
if($record.status -cne 'PASS' -or -not $record.post_pins){throw 'JSON_PACKAGE_QUALIFICATION_FAILED'}
'PASS JSON_CONSTRUCTORS_RELEASE_PACKAGE_QUALIFICATION'
