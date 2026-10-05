[CmdletBinding()]
param([Parameter(Mandatory)][string]$QualifiedDirectory,[Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$helper=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
. $helper
$packager=Join-Path $repoRoot 'Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1'
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not $output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'PACKAGING_TEST_OUTPUT'}
& git -C $repoRoot check-ignore --quiet -- $output
if($LASTEXITCODE -ne 0){throw 'PACKAGING_TEST_NOT_IGNORED'}
[void][IO.Directory]::CreateDirectory($output)
$core=Join-Path $QualifiedDirectory 'Toolbelt.JsonCore.dll'
$ctor=Join-Path $QualifiedDirectory 'Toolbelt.JsonConstructors.dll'
$schema=Join-Path $QualifiedDirectory 'Toolbelt.JsonSchema.dll'
$process=(Get-Process -Id $PID).Path
$pins=@($core,$ctor,$schema,$packager,$helper,$PSCommandPath,$process)|ForEach-Object{
 [pscustomobject]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}
}
$record=[ordered]@{scope='OFFLINE_RELEASE_PACKAGING_ONLY';status='FAILED';postPins=$false;phases=@()}
function Run-Case([string]$Name,[string]$Module,[string]$Assembly,[string]$Core,[string]$Expected){
 $destination=Join-Path $output $Name
 $arguments=@('-NoProfile','-NonInteractive','-File',$packager,'-ModuleId',$Module,'-AssemblyPath',$Assembly,'-OutputDirectory',$destination)
 if($Core){$arguments+=@('-CoreAssemblyPath',$Core)}
 $run=Invoke-OwnedProcess -FileName $process -Arguments $arguments -TimeoutMilliseconds 15000
 [IO.File]::WriteAllText((Join-Path $output ($Name+'.stdout.private')),$run.Stdout)
 [IO.File]::WriteAllText((Join-Path $output ($Name+'.stderr.private')),$run.Stderr)
 $positive=$Expected -ceq 'PASS JSON_KNOWN_CLOSURE_PACKAGING_ONLY'
 if(-not $run.CaptureComplete -or ($positive -and ($run.ExitCode -ne 0 -or $run.Stderr.Length -ne 0 -or $run.Stdout.Trim() -cne $Expected)) -or
  (-not $positive -and ($run.ExitCode -eq 0 -or ($run.Stdout+$run.Stderr).IndexOf($Expected,[StringComparison]::Ordinal) -lt 0))){throw 'PACKAGING_TEST_CASE'}
 if(-not $positive -and (Test-Path -LiteralPath $destination)){throw 'PACKAGING_TEST_REJECTION_WROTE_OUTPUT'}
 $record.phases+=@([ordered]@{name=$Name;actualExitCode=$run.ExitCode;captureComplete=$run.CaptureComplete;expected=$Expected})
}
try{
 Run-Case 'core' 'toolbelt.json.core' $core '' 'PASS JSON_KNOWN_CLOSURE_PACKAGING_ONLY'
 Run-Case 'constructors' 'toolbelt.json.constructors' $ctor $core 'PASS JSON_KNOWN_CLOSURE_PACKAGING_ONLY'
 Run-Case 'schema' 'toolbelt.json.schema' $schema $core 'PASS JSON_KNOWN_CLOSURE_PACKAGING_ONLY'
 Run-Case 'wrong-product' 'toolbelt.json.constructors' $schema $core 'JSON_CLOSURE_BINARY'
 Run-Case 'wrong-core' 'toolbelt.json.schema' $schema $ctor 'JSON_CLOSURE_BINARY'
 Run-Case 'missing-core' 'toolbelt.json.schema' $schema '' 'JSON_CLOSURE_CORE_REQUIRED'
 $bytes=[IO.File]::ReadAllBytes($schema);$bytes[$bytes.Length-1]=$bytes[$bytes.Length-1] -bxor 1
 $foreign=Join-Path $output 'altered.dll';[IO.File]::WriteAllBytes($foreign,$bytes)
 Run-Case 'altered-bytes' 'toolbelt.json.schema' $foreign $core 'JSON_CLOSURE_BINARY'
 foreach($module in @('core','constructors','schema')){
  $sql=[IO.File]::ReadAllText((Join-Path $output ($module+'/Deploy.WithAssembly.sql')))
  if($sql -match '(?m)^:r ' -or $sql.Contains('$(AssemblyBits)')){throw 'PACKAGING_TEST_UNEXPANDED'}
  $suffix=switch($module){'core'{'Core'};'constructors'{'Constructors'};'schema'{'Schema'}}
  $manifest=Get-Content -LiteralPath (Join-Path $output ($module+'/Toolbelt.Json'+$suffix+'.trust-manifest.json')) -Raw|ConvertFrom-Json
  if($manifest.trustAuthorization -cne 'NOT_GRANTED' -or $manifest.nativeQualification -cne 'NOT_EXECUTED'){throw 'PACKAGING_TEST_STATUS'}
 }
 foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash -cne $pin.sha256){throw 'PACKAGING_TEST_DRIFT'}}
 $record.postPins=$true;$record.status='COMPLETE'
 'PASS JSON_PACKAGING CASES 7'
}finally{
 $record|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $output 'Receipt.private.json') -Encoding UTF8
}
