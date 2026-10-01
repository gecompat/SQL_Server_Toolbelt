[CmdletBinding()]
param([string]$OutputDirectory='.runtime/zip-memory-release/legacy')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$revision='3bc644e964b8a35c4e38d3eb2d58e2b1b18631eb'
$taskRoot=Join-Path (Get-Location) '.runtime/zip-memory-legacy-source'
if(Test-Path -LiteralPath $taskRoot){throw 'Legacy-Fixture-Ziel existiert bereits; kein automatisches Überschreiben.'}
New-Item -ItemType Directory -Path $taskRoot | Out-Null
$archive=Join-Path $taskRoot 'source.zip'
& git archive --format=zip "--output=$archive" $revision Modules/toolbelt.archive.zip-memory
if($LASTEXITCODE -ne 0){throw 'Gepinnter historischer Source fehlt; keine Ersatzfixture.'}
Expand-Archive -LiteralPath $archive -DestinationPath $taskRoot
$legacyScript=Join-Path $taskRoot 'Modules/toolbelt.archive.zip-memory/Scripts/New-ClrReleaseArtifacts.ps1'
$destination=[IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
& pwsh -NoProfile -File $legacyScript -OutputDirectory $destination
if($LASTEXITCODE -ne 0){throw 'Historischer CLR-Releasebuild fehlgeschlagen.'}
$manifest=Get-Content -Raw -LiteralPath (Join-Path $destination 'Toolbelt.Archive.ZipMemory.trust-manifest.json') | ConvertFrom-Json
if($manifest.moduleVersion -ne '1.2.0'){throw 'Fixture ist kein echtes 1.2.0 Release.'}
'Gepinnte historische 1.2.0-Fixture gebaut; dies allein ist kein Upgrade-Runtime-Nachweis.'
