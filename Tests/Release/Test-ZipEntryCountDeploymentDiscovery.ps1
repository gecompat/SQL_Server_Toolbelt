[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtime = Join-Path $repo '.runtime'
if (-not (Test-Path -LiteralPath $runtime -PathType Container) -or
    ((Get-Item -LiteralPath $runtime -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'ZIP_ENTRY_COUNT_TEST_RUNTIME_INVALID'
}
. (Join-Path $PSScriptRoot 'ZipEntryCount.DeploymentDiscovery.ps1')
$scope = Join-Path $runtime ('zip-entry-discovery-' + [guid]::NewGuid().ToString('N'))
$modules = Join-Path $scope 'Modules'
$alpha = Join-Path $modules 'alpha'
$alphaDeployment = Join-Path $alpha 'Deployment'
$beta = Join-Path $modules 'beta'
$betaDeployment = Join-Path $beta 'Deployment'
try {
    New-Item -ItemType Directory -Path $alphaDeployment -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $alpha 'module.yaml'), 'module_id: alpha' + "`n")
    [IO.File]::WriteAllText((Join-Path $alphaDeployment 'Deploy.sql'), 'SELECT 1;' + "`n")
    $baseline = @(Get-ZipEntryCountDeploymentDiscovery $modules)
    if ($baseline.Count -ne 2) { throw 'ZIP_ENTRY_COUNT_TEST_BASELINE' }
    [void](Assert-ZipEntryCountDeploymentDiscovery $modules $baseline)

    New-Item -ItemType Directory -Path $betaDeployment -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $beta 'module.yaml'), 'module_id: beta' + "`n")
    [IO.File]::WriteAllText((Join-Path $betaDeployment 'Deploy.sql'), 'SELECT 2;' + "`n")
    try { [void](Assert-ZipEntryCountDeploymentDiscovery $modules $baseline); throw 'ZIP_ENTRY_COUNT_TEST_ADD_NOT_REJECTED' }
    catch { if ($_.Exception.Message -cne 'ZIP_ENTRY_COUNT_DEPLOY_DISCOVERY_DRIFT') { throw } }

    Remove-Item -LiteralPath (Join-Path $betaDeployment 'Deploy.sql')
    Remove-Item -LiteralPath (Join-Path $beta 'module.yaml')
    Remove-Item -LiteralPath $betaDeployment
    Remove-Item -LiteralPath $beta
    Remove-Item -LiteralPath (Join-Path $alphaDeployment 'Deploy.sql')
    try { [void](Assert-ZipEntryCountDeploymentDiscovery $modules $baseline); throw 'ZIP_ENTRY_COUNT_TEST_REMOVE_NOT_REJECTED' }
    catch { if ($_.Exception.Message -cne 'ZIP_ENTRY_COUNT_DEPLOY_DISCOVERY_DRIFT') { throw } }
    'PASS ZIP_ENTRY_COUNT deployment discovery rejects additions and removals'
} finally {
    $resolvedScope = [IO.Path]::GetFullPath($scope)
    if ([IO.Path]::GetDirectoryName($resolvedScope) -cne [IO.Path]::GetFullPath($runtime) -or
        -not (Test-Path -LiteralPath $resolvedScope -PathType Container)) { throw 'ZIP_ENTRY_COUNT_TEST_CLEANUP_SCOPE' }
    if (@(Get-ChildItem -LiteralPath $resolvedScope -Force -Recurse | Where-Object {
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    }).Count) { throw 'ZIP_ENTRY_COUNT_TEST_CLEANUP_REPARSE' }
    Remove-Item -LiteralPath $resolvedScope -Recurse -Force
}
