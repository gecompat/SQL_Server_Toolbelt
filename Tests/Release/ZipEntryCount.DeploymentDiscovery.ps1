# Liest nur die Modul- und Deploy-Dateipfade, die Deploy-All bei der Auswahl scannt.
function Get-ZipEntryCountDeploymentDiscovery([string]$ModulesRoot) {
    $root = [IO.Path]::GetFullPath($ModulesRoot)
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw 'ZIP_ENTRY_COUNT_DEPLOY_DISCOVERY_ROOT' }
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($directory in Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name) {
        $deploy = Join-Path $directory.FullName 'Deployment/Deploy.sql'
        if (-not (Test-Path -LiteralPath $deploy -PathType Leaf)) { continue }
        $manifest = Join-Path $directory.FullName 'module.yaml'
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw 'ZIP_ENTRY_COUNT_DEPLOY_DISCOVERY_INVALID' }
        $module = 'Modules/' + $directory.Name
        $paths.Add($module + '/module.yaml')
        $paths.Add($module + '/Deployment/Deploy.sql')
    }
    return @($paths | Sort-Object -Unique)
}

function Assert-ZipEntryCountDeploymentDiscovery([string]$ModulesRoot, [string[]]$Expected) {
    $actual = @(Get-ZipEntryCountDeploymentDiscovery $ModulesRoot)
    $set = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($path in $Expected) {
        if (-not $set.Add($path)) { throw 'ZIP_ENTRY_COUNT_DEPLOY_DISCOVERY_INVALID' }
    }
    foreach ($path in $actual) {
        if (-not $set.Remove($path)) { throw 'ZIP_ENTRY_COUNT_DEPLOY_DISCOVERY_DRIFT' }
    }
    if ($set.Count -ne 0) { throw 'ZIP_ENTRY_COUNT_DEPLOY_DISCOVERY_DRIFT' }
    return $actual
}
