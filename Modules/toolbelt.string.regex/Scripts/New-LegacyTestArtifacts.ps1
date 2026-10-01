[CmdletBinding()]
param([string]$OutputDirectory = '.runtime/regex-release/legacy')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (& git rev-parse --show-toplevel).Trim()
# Öffentlicher, unveränderlicher Vorgängerstand. Kein nachgebauter Versionsmarker:
# der Upgrade-Test installiert das tatsächlich aus R1b gebaute Binary.
$revision = 'b3ab071efb218e6d3aee4542343db26d098e1dab'
$sourceRoot = Join-Path $repoRoot '.runtime/regex-legacy-source'
New-Item -ItemType Directory -Force -Path $sourceRoot | Out-Null
$archive = Join-Path $sourceRoot 'source.tar'
& git archive --format=tar "--output=$archive" $revision Modules/toolbelt.string.regex
if ($LASTEXITCODE -ne 0) { throw 'Historischer Regex-Quellstand fehlt; Git-History bereitstellen.' }
& tar -xf $archive -C $sourceRoot
if ($LASTEXITCODE -ne 0) { throw 'Historischer Quellstand konnte nicht extrahiert werden.' }
$legacyModule = Join-Path $sourceRoot 'Modules/toolbelt.string.regex'
$outputPath = [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
& (Join-Path $legacyModule 'Scripts/New-ClrReleaseArtifacts.ps1') -OutputDirectory $outputPath | Out-Null
$sourceOutput = Join-Path $outputPath 'Source'
New-Item -ItemType Directory -Force -Path $sourceOutput | Out-Null
Copy-Item -LiteralPath (Join-Path $legacyModule 'Source/RegexFunctions.sql') -Destination $sourceOutput
# Generiertes SQLCMD-Artefakt ist selbstständig; Legacy-Include darf nicht auf
# die aktuellen R2a-Entry-Points zeigen.
$deployPath = Join-Path $outputPath 'Deploy.WithAssembly.sql'
$scriptText = (Get-Content -LiteralPath $deployPath -Raw).Replace(':r ../Source/RegexFunctions.sql', ':r Source/RegexFunctions.sql')
$scriptText | Set-Content -LiteralPath $deployPath -Encoding utf8
Write-Output 'Regex Legacy-Upgrade-Testartefakte erzeugt.'
