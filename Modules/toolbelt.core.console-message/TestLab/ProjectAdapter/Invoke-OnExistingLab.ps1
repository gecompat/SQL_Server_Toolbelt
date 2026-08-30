[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $RunId,

    [Parameter(Mandatory)]
    [string] $StateRoot,

    [Parameter(Mandatory)]
    [SecureString] $SaPassword,

    [Parameter(Mandatory)]
    [string] $LabRepositoryRoot,

    [string] $InstanceId = 'primary',

    [switch] $KeepProjectStateOnFailure
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$adapterRoot = $PSScriptRoot
$labRoot = (Resolve-Path -LiteralPath $LabRepositoryRoot).Path
$labManifest = Join-Path $labRoot 'SqlServerLab.psd1'
if (-not (Test-Path -LiteralPath $labManifest -PathType Leaf)) {
    throw "SQL_Server_Lab-Modulmanifest fehlt: $labManifest"
}

Import-Module $labManifest -Force

$offlineValidation = Test-SqlServerLabAdapter -Path $adapterRoot
if (-not $offlineValidation.IsReady) {
    throw "Der Toolbelt-Adapter ist ungültig: $($offlineValidation.Errors -join '; ')"
}

$runtimeValidation = Test-SqlServerLabAdapter `
    -Path $adapterRoot `
    -RunId $RunId `
    -InstanceId $InstanceId `
    -StateRoot $StateRoot
if (-not $runtimeValidation.IsReady) {
    throw "Der Toolbelt-Adapter ist mit dem gebundenen Lab-Run inkompatibel: $($runtimeValidation.Errors -join '; ')"
}

$failed = $false
$cleanupCompleted = $false
$result = $null
try {
    foreach ($entrypoint in @('install', 'update', 'validate')) {
        $entrypointResult = Install-SqlServerLabAdapter `
            -Path $adapterRoot `
            -RunId $RunId `
            -InstanceId $InstanceId `
            -SaPassword $SaPassword `
            -Entrypoint $entrypoint `
            -StateRoot $StateRoot
        if (-not $entrypointResult.Success -or
            $entrypointResult.Status -ne 'ADAPTER_APPLIED') {
            throw "Adapter-Entrypoint '$entrypoint' fehlgeschlagen ($($entrypointResult.Status)): $($entrypointResult.Message)"
        }
    }

    $result = [PSCustomObject]@{
        Status = 'PASS'
        WorkItem = 'ADP-008'
        ModuleId = 'toolbelt.core.console-message'
        ModuleVersion = '1.0.0'
        AdapterProjectId = $offlineValidation.ProjectId
        AdapterContractVersion = $offlineValidation.Adapter.adapterContractVersion
        RunId = $RunId
        ProjectCleanup = 'PENDING'
    }
}
catch {
    $failed = $true
    throw
}
finally {
    if (-not ($failed -and $KeepProjectStateOnFailure)) {
        try {
            $cleanupResult = Install-SqlServerLabAdapter `
                -Path $adapterRoot `
                -RunId $RunId `
                -InstanceId $InstanceId `
                -SaPassword $SaPassword `
                -Entrypoint cleanup `
                -StateRoot $StateRoot
            $cleanupCompleted = $cleanupResult.Success -and
                $cleanupResult.Status -eq 'ADAPTER_APPLIED'
            if (-not $cleanupCompleted) {
                Write-Warning "Adapter-Cleanup meldete $($cleanupResult.Status)."
            }
        }
        catch {
            Write-Warning "Adapter-Cleanup fehlgeschlagen: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Der fehlgeschlagene Projektzustand im bestehenden Lab-Run wurde absichtlich erhalten."
    }
}

if ($result) {
    if (-not $cleanupCompleted) {
        throw 'Der fachliche Adapterlauf war erfolgreich, aber der markergebundene Projekt-Cleanup blieb unvollständig.'
    }
    $result.ProjectCleanup = 'REMOVED'
    $result
}
