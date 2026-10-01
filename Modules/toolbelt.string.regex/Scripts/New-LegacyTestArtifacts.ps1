[CmdletBinding()]
param([string]$OutputDirectory = '.runtime/regex-release/legacy',
      [ValidateSet('1.0.0','1.1.0')][string]$ReleaseVersion = '1.0.0')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (& git rev-parse --show-toplevel).Trim()
# Öffentlicher, unveränderlicher Vorgängerstand. Kein nachgebauter Versionsmarker:
# der Upgrade-Test installiert das tatsächlich aus R1b gebaute Binary.
$revision = if($ReleaseVersion -eq '1.0.0'){'b3ab071efb218e6d3aee4542343db26d098e1dab'}else{'1b0f16c767b1c8a12c7fa0b3014108e6e120c23e'}
$sourceRoot = Join-Path $repoRoot ".runtime/regex-legacy-source-$ReleaseVersion"
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
$manifest=Get-Content -LiteralPath (Join-Path $outputPath 'Toolbelt.String.Regex.trust-manifest.json') -Raw | ConvertFrom-Json
if($manifest.moduleVersion -ne $ReleaseVersion){throw 'Historischer Build hat nicht die gepinnte Releaseversion.'}
Write-Output 'Regex Legacy-Upgrade-Testartefakte erzeugt.'
