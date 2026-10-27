[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$FrameworkRoot,
 [Parameter(Mandatory)][string]$FrameworkPowerShell,
 [Parameter(Mandatory)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'JSON_SCHEMA_PACKAGE_POWERSHELL7_REQUIRED'}
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$output=[IO.Path]::GetFullPath($OutputDirectory)
$privatePrefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not $output.StartsWith($privatePrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_SCHEMA_PRIVATE_OUTPUT_REQUIRED'}
if(Test-Path -LiteralPath $output){throw 'JSON_SCHEMA_OUTPUT_EXISTS'}
$framework=[IO.Path]::GetFullPath($FrameworkRoot)
if(-not $framework.StartsWith($privatePrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_SCHEMA_FRAMEWORK_RECEIPT_REQUIRED'}
& git -C $repoRoot check-ignore --quiet -- $output
if($LASTEXITCODE -ne 0){throw 'JSON_SCHEMA_OUTPUT_NOT_IGNORED'}
& git -C $repoRoot check-ignore --quiet -- $framework
if($LASTEXITCODE -ne 0){throw 'JSON_SCHEMA_FRAMEWORK_RECEIPT_NOT_IGNORED'}
$helper=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
. $helper
$python=(Get-Command python -ErrorAction Stop).Source
$pythonGate=Join-Path $repoRoot 'Scripts/Release/json_schema_package.py'
$package=Join-Path $repoRoot 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$sidecar=$package+'.sha256'
$predecessor=Join-Path $repoRoot 'Releases/1.0.0/JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.json'
$ilGate=Join-Path $repoRoot 'Modules/toolbelt.json.core/Tests/Framework/Test-JsonClosureIL.ps1'
$ilRecord=Join-Path $output 'Toolbelt.JsonSchema.IL.private.json'
$schemaPath=Join-Path (Join-Path $output 'package') 'Toolbelt.JsonSchema.dll'
$corePath=Join-Path (Join-Path $output 'package') 'Toolbelt.JsonCore.dll'
$pinned=@($python,$FrameworkPowerShell,$package,$sidecar,$predecessor,$pythonGate,$PSCommandPath,$helper,$ilGate) |
 ForEach-Object { if(-not (Test-Path -LiteralPath $_ -PathType Leaf)){throw 'JSON_SCHEMA_PINNED_INPUT_MISSING'};[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} }
$record=[ordered]@{schema_version=1;status='FAILED';failure=$null;scope='JSON_SCHEMA_RELEASE_PACKAGE_DIRECT_IL';package_sha256=$null;schema_sha256=$null;core_sha256=$null;predecessor_commit='e559896b4f9e4f496a09bfa7b7c5d690512bc433';source_framework_reused=$false;source_framework_phases=0;source_framework_post_pins=$false;package_schema_il_direct=$false;post_pins=$false}
try {
 $hostCheck=Invoke-OwnedProcess -FileName $FrameworkPowerShell -Arguments @('-NoProfile','-NonInteractive','-Command','[Console]::WriteLine($PSVersionTable.PSVersion.ToString())') -TimeoutMilliseconds 10000
 if($hostCheck.ExitCode -ne 0 -or -not $hostCheck.CaptureComplete -or $hostCheck.Stderr.Length -ne 0 -or $hostCheck.Stdout -notmatch '^5\.1\.[0-9.]+\r?\n?\z'){throw 'JSON_SCHEMA_FRAMEWORK_POWERSHELL_HOST_INVALID'}
 $bindingProcess=Invoke-OwnedProcess -FileName $python -Arguments @('-B',$pythonGate,'--root',$repoRoot,'--framework-root',$framework,'--output',$output) -TimeoutMilliseconds 30000
 if(Test-Path -LiteralPath $output -PathType Container){
  [IO.File]::WriteAllText((Join-Path $output 'Binding.stdout.private.txt'),$bindingProcess.Stdout)
  [IO.File]::WriteAllText((Join-Path $output 'Binding.stderr.private.txt'),$bindingProcess.Stderr)
 }
 if($bindingProcess.ExitCode -ne 0 -or -not $bindingProcess.CaptureComplete -or $bindingProcess.Stderr.Length -ne 0){throw 'JSON_SCHEMA_PACKAGE_BINDING_FAILED'}
 $binding=$bindingProcess.Stdout | ConvertFrom-Json -ErrorAction Stop
 if($binding.status -cne 'PREPARED' -or $binding.scope -cne $record.scope -or $binding.source_framework_phases -ne 27 -or -not $binding.source_framework_post_pins){throw 'JSON_SCHEMA_SOURCE_RECEIPT_INVALID'}
 $record.package_sha256=$binding.package_sha256
 $record.schema_sha256=$binding.schema_sha256
 $record.core_sha256=$binding.core_sha256
 $record.source_framework_reused=$true
 $record.source_framework_phases=$binding.source_framework_phases
 $record.source_framework_post_pins=[bool]$binding.source_framework_post_pins
 $il=Invoke-OwnedProcess -FileName $FrameworkPowerShell -Arguments @('-NoProfile','-NonInteractive','-File',$ilGate,
   '-BinaryPath',$schemaPath,'-ExpectedSha256',$binding.schema_sha256.ToUpperInvariant(),
   '-CorePath',$corePath,'-ExpectedCoreSha256',$binding.core_sha256.ToUpperInvariant(),
   '-EvidencePath',$ilRecord) -TimeoutMilliseconds 60000
 [IO.File]::WriteAllText((Join-Path $output 'SchemaIL.stdout.private.txt'),$il.Stdout)
 [IO.File]::WriteAllText((Join-Path $output 'SchemaIL.stderr.private.txt'),$il.Stderr)
 if($il.ExitCode -ne 0 -or -not $il.CaptureComplete -or $il.Stderr.Length -ne 0 -or $il.Stdout -cnotmatch '(?:^|\r?\n)PASS JSON_SHARED_PRODUCT_IL\s*\z'){throw 'JSON_SCHEMA_PACKAGE_IL_FAILED'}
 $post=Invoke-OwnedProcess -FileName $python -Arguments @('-B',$pythonGate,'--root',$repoRoot,'--framework-root',$framework,'--output',$output,'--postvalidate') -TimeoutMilliseconds 30000
 [IO.File]::WriteAllText((Join-Path $output 'Postvalidation.stdout.private.txt'),$post.Stdout)
 [IO.File]::WriteAllText((Join-Path $output 'Postvalidation.stderr.private.txt'),$post.Stderr)
 if($post.ExitCode -ne 0 -or -not $post.CaptureComplete -or $post.Stderr.Length -ne 0){throw 'JSON_SCHEMA_POSTVALIDATION_FAILED'}
 $result=$post.Stdout | ConvertFrom-Json -ErrorAction Stop
 if($result.status -cne 'PASS' -or -not $result.package_schema_il_direct_package -or $result.package_schema_il_unknown_bindings -ne 0){throw 'JSON_SCHEMA_FINAL_RECEIPT_INVALID'}
 $record.status='PASS'
 $record.package_schema_il_direct=$true
} catch {
 $record.failure=$_.Exception.Message
 throw
} finally {
 if(Test-Path -LiteralPath $output -PathType Container){
  try {
   foreach($pin in $pinned){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash -cne $pin.sha256){throw 'JSON_SCHEMA_INPUT_PIN_DRIFT'}}
   $packageDirectory=Join-Path $output 'package'
   if(Test-Path -LiteralPath $packageDirectory -PathType Container){
    if(-not (Test-Path -LiteralPath $schemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $corePath -PathType Leaf)){throw 'JSON_SCHEMA_PACKAGE_BINARY_POSTPIN_MISSING'}
    if((Get-FileHash -LiteralPath $schemaPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.schema_sha256 -or
       (Get-FileHash -LiteralPath $corePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.core_sha256){throw 'JSON_SCHEMA_PACKAGE_BINARY_POSTPIN_DRIFT'}
   }
   elseif($record.status -eq 'PASS'){throw 'JSON_SCHEMA_PACKAGE_BINARY_POSTPIN_MISSING'}
   $record.post_pins=$true
  }
  catch {$record.status='FAILED';$record.post_pins=$false;if(-not $record.failure){$record.failure=$_.Exception.Message}}
  [IO.File]::WriteAllText((Join-Path $output 'Result.private.json'),($record|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
 }
}
if($record.status -cne 'PASS' -or -not $record.post_pins){throw 'JSON_SCHEMA_PACKAGE_QUALIFICATION_FAILED'}
'PASS JSON_SCHEMA_RELEASE_PACKAGE_DIRECT_IL'
