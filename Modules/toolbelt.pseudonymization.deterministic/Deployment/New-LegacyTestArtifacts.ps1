[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$OutputDirectory,
    [ValidateSet('1.0.0','1.1.0')][string]$Version='1.0.0'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$revision = if($Version -eq '1.0.0') {'9c77df2761db469ed9b2c20b48a4c909c69f7700'} else {'76851e45f407089e062792c010176ae35a0ee77b'}
$repoRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) { throw 'LEGACY_REPOSITORY_UNAVAILABLE' }
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) {
    if (-not (Test-Path -LiteralPath $output -PathType Container) -or @(Get-ChildItem -LiteralPath $output -Force).Count) {
        throw 'LEGACY_OUTPUT_MUST_BE_NEW_OR_EMPTY'
    }
}
New-Item -ItemType Directory -Path $output -Force | Out-Null
$staging = Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltDeterministicLegacy-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging | Out-Null
$archive = Join-Path $staging 'source.tar'
& git -C $repoRoot archive --format=tar "--output=$archive" $revision Modules/toolbelt.pseudonymization.deterministic
if ($LASTEXITCODE -ne 0) { throw 'GENUINE_LEGACY_COMMIT_UNAVAILABLE' }
& tar -xf $archive -C $staging
if ($LASTEXITCODE -ne 0) { throw 'GENUINE_LEGACY_ARCHIVE_INVALID' }
$module = Join-Path $staging 'Modules/toolbelt.pseudonymization.deterministic'
# Kanonischer historischer SQLCMD-Layout bleibt ohne Marker-/Source-Umschreibung.
foreach ($directory in @('Deployment','Source')) {
    Copy-Item -LiteralPath (Join-Path $module $directory) -Destination $output -Recurse
}
$hashes = @(Get-ChildItem -LiteralPath $output -Recurse -File | Sort-Object FullName | ForEach-Object {
    [ordered]@{path=[IO.Path]::GetRelativePath($output,$_.FullName).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
[ordered]@{moduleId='toolbelt.pseudonymization.deterministic';moduleVersion=$Version;publicCommit=$revision;files=$hashes} |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'legacy-provenance.json') -Encoding utf8
Write-Output ('PASS: genuine deterministic ' + $Version + ' SQLCMD fixture packaged')
