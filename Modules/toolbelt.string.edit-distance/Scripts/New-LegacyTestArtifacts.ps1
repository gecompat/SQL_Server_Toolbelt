[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Invoke-OwnedProcess.ps1')
# Genuine öffentliche 1.0-Blobs; weder Marker noch historische Quellen werden umgeschrieben.
$revision='e7b0e543d40b8876d5d2a08cf776f2c32947429f'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$prefix='Modules/toolbelt.string.edit-distance/'
$files=@('Clr/Toolbelt.String.EditDistance.csproj','Clr/Properties/AssemblyInfo.cs',
 'Clr/DistanceKernel.cs','Clr/DistanceProvider.cs','Source/EditDistance.sql',
 'Deployment/Deploy.sql','Deployment/Uninstall.sql','Scripts/New-ClrReleaseArtifacts.ps1')
if(Test-Path -LiteralPath $OutputDirectory){throw 'LEGACY_OUTPUT_MUST_BE_ABSENT'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
$null=[IO.Directory]::CreateDirectory($output)
$pins=@()
foreach($relative in $files){
 $identity=Invoke-OwnedProcess -FileName 'git' -Arguments @('-C',$repoRoot,'rev-parse',($revision+':'+$prefix+$relative)) -TimeoutMilliseconds 15000
 $blob=$identity.Stdout.Trim()
 if($identity.ExitCode -ne 0 -or $identity.Stderr.Length -ne 0 -or $blob -cnotmatch '^[0-9a-f]{40}$'){throw 'LEGACY_BLOB_ID'}
 $path=Join-Path $output $relative;$null=[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
 $copy=Invoke-OwnedProcess -FileName 'git' -Arguments @('-C',$repoRoot,'cat-file','blob',$blob) -TimeoutMilliseconds 15000 -BinaryOutputPath $path
 if($copy.ExitCode -ne 0 -or $copy.Stderr.Length -ne 0){throw 'LEGACY_CHILD_FAILED'}
 $hash=Invoke-OwnedProcess -FileName 'git' -Arguments @('-C',$repoRoot,'hash-object','--no-filters',$path) -TimeoutMilliseconds 15000
 if($hash.ExitCode -ne 0 -or $hash.Stderr.Length -ne 0 -or $hash.Stdout.Trim() -cne $blob){throw 'LEGACY_BLOB_BYTES'}
 $pins+=,[ordered]@{path=$relative;gitBlob=$blob;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
}
[IO.File]::WriteAllText((Join-Path $output 'LegacySourceProvenance.json'),
 ([ordered]@{Version='1.0.0';Revision=$revision;Status='SOURCE_ONLY_NOT_BUILT';Files=$pins}|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
Write-Output 'PASS genuine 1.0 source package; build and native qualification separate'
