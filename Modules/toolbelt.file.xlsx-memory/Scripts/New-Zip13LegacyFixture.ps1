[CmdletBinding()]
param([string]$OutputDirectory='.runtime/xlsx-zip13-legacy')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Tatsächlicher voriger ZIP-Release; kein nachträglich ummarkierter neuer Build.
$revision='677e68c269b084379143c058cad0f03baee1bf79'
$destination=[IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
if(Test-Path -LiteralPath $destination){throw 'Legacy-Fixture-Ziel existiert; kein automatisches Überschreiben.'}
[void](New-Item -ItemType Directory -Path $destination)
$source=Join-Path $destination 'source';[void](New-Item -ItemType Directory -Path $source)
$archive=Join-Path $destination 'source.zip'
& git archive --format=zip "--output=$archive" $revision Modules/toolbelt.archive.zip-memory
if($LASTEXITCODE){throw 'Gepinnter echter ZIP-1.3-Source fehlt; kein Fallback.'}
Expand-Archive -LiteralPath $archive -DestinationPath $source
& pwsh -NoProfile -File (Join-Path $source 'Modules/toolbelt.archive.zip-memory/Scripts/New-ClrReleaseArtifacts.ps1') -OutputDirectory (Join-Path $destination 'artifacts')
if($LASTEXITCODE){throw 'Gepinnter ZIP-1.3-Build fehlgeschlagen.'}
$manifest=Get-Content -LiteralPath (Join-Path $destination 'artifacts/Toolbelt.Archive.ZipMemory.trust-manifest.json') -Raw|ConvertFrom-Json
if($manifest.moduleVersion-cne'1.3.0'){throw 'Keine echte ZIP-1.3-Fixture.'}
'PASS: pinned real ZIP 1.3.0 fixture built; not an SQL upgrade claim.'
