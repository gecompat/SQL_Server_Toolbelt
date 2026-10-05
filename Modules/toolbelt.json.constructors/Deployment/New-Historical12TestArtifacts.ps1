[CmdletBinding()]
param([Parameter(Mandatory)][string]$MSBuildPath,[Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent $PSScriptRoot
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
$helper=Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1'
. $helper
$revision='46b2f078662a3203a8da67bfe331b33607962082'
$registryPath=Join-Path $moduleRoot 'Documentation/KNOWN_CLR_ARTIFACTS.json'
$registry=Get-Content -LiteralPath $registryPath -Raw|ConvertFrom-Json
if($registry.artifacts.Count-ne1-or$registry.artifacts[0].Fields.moduleVersion-cne'1.2.0'){throw 'HISTORICAL12_REGISTRY'}
$row=$registry.artifacts[0]
$sources=@($row.Fields.psobject.Properties|Where-Object{$_.Name.StartsWith('source/',[StringComparison]::Ordinal)}|ForEach-Object{'Clr/'+$_.Name.Substring(7)})
$files=$sources+@('Clr/Toolbelt.JsonConstructors.csproj','Deployment/Deploy.sql','Deployment/Uninstall.sql',
 'Deployment/KnownArtifact.sql','Deployment/ClrPreflight.sql','Documentation/KNOWN_CLR_ARTIFACTS.json',
 'Scripts/New-ClrReleaseArtifacts.ps1','Source/JsonEntryEvaluate.sql','Source/JsonAggregates.sql',
 'Source/USP_JsonConstructInternal.sql','Source/USP_JsonArray.sql','Source/USP_JsonObject.sql',
 'Source/USP_JsonArraysByGroup.sql','Source/USP_JsonObjectsByGroup.sql')
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or(Test-Path -LiteralPath $output)){throw 'HISTORICAL12_OUTPUT'}
& git -C $repoRoot check-ignore --quiet -- $output
if($LASTEXITCODE-ne0){throw 'HISTORICAL12_NOT_IGNORED'}
$git=(Get-Command git -CommandType Application|Select-Object -First 1).Source
$inputs=@($PSCommandPath,$helper,$registryPath,$git,$MSBuildPath)|ForEach-Object{[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}}
[void][IO.Directory]::CreateDirectory($output)
$sourceRoot=Join-Path $output 'genuine-source'
$blobPins=@()
foreach($relative in $files){
 $path=Join-Path $sourceRoot $relative
 [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
 $run=Invoke-OwnedProcess -FileName $git -Arguments @('-C',$repoRoot,'show',($revision+':Modules/toolbelt.json.constructors/'+$relative)) -TimeoutMilliseconds 10000 -BinaryOutputPath $path
 if($run.ExitCode-ne0-or-not$run.CaptureComplete-or$run.Stderr.Length-ne0){throw 'HISTORICAL12_GIT_BLOB'}
 $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
 if($relative.StartsWith('Clr/',[StringComparison]::Ordinal)-and$relative.EndsWith('.cs',[StringComparison]::Ordinal)){
  if($hash-cne$row.Fields.psobject.Properties['source/'+$relative.Substring(4)].Value){throw 'HISTORICAL12_SOURCE'}
 }
 $blobPins+=@([pscustomobject]@{path=$path;sha256=$hash})
}
if((Get-FileHash -LiteralPath (Join-Path $sourceRoot 'Documentation/KNOWN_CLR_ARTIFACTS.json') -Algorithm SHA256).Hash-cne(Get-FileHash -LiteralPath $registryPath -Algorithm SHA256).Hash){throw 'HISTORICAL12_REGISTRY_DRIFT'}
$build=Invoke-OwnedProcess -FileName $MSBuildPath -Arguments @((Join-Path $sourceRoot 'Clr/Toolbelt.JsonConstructors.csproj'),'/t:Rebuild','/p:Configuration=Release','/p:Platform=AnyCPU','/m:1','/nr:false','/nologo','/noAutoResponse') -TimeoutMilliseconds 45000
[IO.File]::WriteAllText((Join-Path $output 'Build.stdout.private'),$build.Stdout)
[IO.File]::WriteAllText((Join-Path $output 'Build.stderr.private'),$build.Stderr)
if($build.ExitCode-ne0-or-not$build.CaptureComplete-or$build.Stderr.Length-ne0){throw 'HISTORICAL12_BUILD'}
$dll=Join-Path $sourceRoot 'Clr/bin/Release/Toolbelt.JsonConstructors.dll'
if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLowerInvariant()-cne$row.Fields.binarySha256-or
 (Get-FileHash -LiteralPath $dll -Algorithm SHA512).Hash.ToLowerInvariant()-cne$row.Fields.binarySha512){throw 'HISTORICAL12_UNKNOWN_BINARY'}
& (Join-Path $sourceRoot 'Scripts/New-ClrReleaseArtifacts.ps1') -AssemblyPath $dll -OutputDirectory (Join-Path $output 'release') | Out-Null
foreach($pin in @($inputs)+@($blobPins)){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$pin.sha256.ToLowerInvariant()){throw 'HISTORICAL12_POST_PIN'}}
[ordered]@{scope='GENUINE_KNOWN_CONSTRUCTOR12_ONLY';status='COMPLETE';revision=$revision;artifactId=$row.ArtifactId;
 binarySha256=$row.Fields.binarySha256;binarySha512=$row.Fields.binarySha512;actualBuildExitCode=$build.ExitCode;captureComplete=$build.CaptureComplete;sourcePins=$blobPins}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $output 'Receipt.private.json') -Encoding UTF8
'PASS GENUINE_KNOWN_CONSTRUCTOR12_ONLY'
