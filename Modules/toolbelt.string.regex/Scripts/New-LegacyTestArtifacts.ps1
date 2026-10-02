[CmdletBinding()]
param([string]$OutputDirectory = '.runtime/regex-release/legacy',
      [ValidateSet('1.0.0','1.1.0','1.2.0')][string]$ReleaseVersion = '1.0.0')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (& git rev-parse --show-toplevel).Trim()
# Öffentlicher, unveränderlicher Vorgängerstand. Kein nachgebauter Versionsmarker:
# der Upgrade-Test installiert das tatsächlich aus R1b gebaute Binary.
$revision = @{
    '1.0.0' = 'b3ab071efb218e6d3aee4542343db26d098e1dab'
    '1.1.0' = '1b0f16c767b1c8a12c7fa0b3014108e6e120c23e'
    '1.2.0' = '1b838df8e54a211b16f7f1c303c21b66b673940e'
}[$ReleaseVersion]
$sourceRoot = Join-Path $repoRoot ".runtime/regex-legacy-source-$ReleaseVersion"
New-Item -ItemType Directory -Force -Path $sourceRoot | Out-Null
$archive = Join-Path $sourceRoot 'source.tar'
& git archive --format=tar "--output=$archive" $revision Modules/toolbelt.string.regex
if ($LASTEXITCODE -ne 0) { throw 'Historischer Regex-Quellstand fehlt; Git-History bereitstellen.' }
& tar -xf $archive -C $sourceRoot
if ($LASTEXITCODE -ne 0) { throw 'Historischer Quellstand konnte nicht extrahiert werden.' }
$legacyModule = Join-Path $sourceRoot 'Modules/toolbelt.string.regex'
$outputPath = if ([IO.Path]::IsPathRooted($OutputDirectory)) { [IO.Path]::GetFullPath($OutputDirectory) }
              else { [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory)) }
& (Join-Path $legacyModule 'Scripts/New-ClrReleaseArtifacts.ps1') -OutputDirectory $outputPath | Out-Null
$sourceOutput = Join-Path $outputPath 'Source'
New-Item -ItemType Directory -Force -Path $sourceOutput | Out-Null
$sourceNames = @('RegexFunctions.sql')
if ($ReleaseVersion -eq '1.2.0') { $sourceNames += 'RegexRelations.sql' }
foreach ($sourceName in $sourceNames) {
    Copy-Item -LiteralPath (Join-Path $legacyModule "Source/$sourceName") -Destination $sourceOutput
}
Copy-Item -LiteralPath (Join-Path $legacyModule 'Deployment/Uninstall.sql') -Destination (Join-Path $outputPath 'Uninstall.sql')
# Generiertes SQLCMD-Artefakt ist selbstständig; Legacy-Include darf nicht auf
# die aktuellen R2a-Entry-Points zeigen.
$deployPath = Join-Path $outputPath 'Deploy.WithAssembly.sql'
$scriptText = (Get-Content -LiteralPath $deployPath -Raw).Replace(':r ../Source/RegexFunctions.sql', ':r Source/RegexFunctions.sql')
$scriptText = $scriptText.Replace(':r ../Source/RegexRelations.sql', ':r Source/RegexRelations.sql')
$scriptText | Set-Content -LiteralPath $deployPath -Encoding utf8
$manifest=Get-Content -LiteralPath (Join-Path $outputPath 'Toolbelt.String.Regex.trust-manifest.json') -Raw | ConvertFrom-Json
if($manifest.moduleVersion -ne $ReleaseVersion){throw 'Historischer Build hat nicht die gepinnte Releaseversion.'}
# Nur öffentliche Provenienz und Artefaktidentitäten; keine lokalen Pfade.
$provenance = [ordered]@{
    moduleVersion = $ReleaseVersion; publicCommit = $revision
    providerSha512 = (Get-FileHash -LiteralPath (Join-Path $outputPath 'Toolbelt.String.Regex.dll') -Algorithm SHA512).Hash
    deploymentSha256 = (Get-FileHash -LiteralPath $deployPath -Algorithm SHA256).Hash
    sourceSha256 = @($sourceNames | ForEach-Object {
        [ordered]@{name=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $sourceOutput $_) -Algorithm SHA256).Hash}
    })
}
$provenance | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outputPath 'legacy-provenance.json') -Encoding utf8
Write-Output 'Regex Legacy-Upgrade-Testartefakte erzeugt.'
