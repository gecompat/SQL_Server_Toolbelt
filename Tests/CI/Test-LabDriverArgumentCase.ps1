[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path

function New-ParameterProbe([string]$Path) {
    $tokens = $null
    $errors = $null
    $tree = [Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    if ($errors.Count -ne 0 -or $null -eq $tree.ParamBlock) {
        throw 'LAB_DRIVER_PARAMETER_PARSE_FAILED'
    }

    # Nur den geparsten Paramblock ausführen; der Labtreiber-Body bleibt unberührt.
    return [scriptblock]::Create("[CmdletBinding()]`n" + $tree.ParamBlock.Extent.Text + "`n'BOUND'")
}

function Assert-Bound($Probe, [hashtable]$Arguments, [string]$Case) {
    $result = @(& $Probe @Arguments)
    if ($result.Count -ne 1 -or [string]$result[0] -cne 'BOUND') {
        throw ('LAB_DRIVER_CANONICAL_ARGUMENT_REJECTED: ' + $Case)
    }
}

function Assert-Rejected($Probe, [hashtable]$Arguments, [string]$Case) {
    try {
        [void]@(& $Probe @Arguments)
    }
    catch {
        return
    }
    throw ('LAB_DRIVER_CASE_VARIANT_ACCEPTED: ' + $Case)
}

$hash = '0' * 64
$common = @{
    Platform = 'linux'
    Version = '2019'
    Patch = 'latest'
    CompatibilityLevel = 150
    JournalManifestPath = 'synthetic-empty-journal'
    ExpectedPromptSHA256 = $hash
    ExpectedDriverSHA256 = $hash
    DeploymentModes = @('local', 'central')
}

foreach ($name in @('run-safe-cast-lab.ps1', 'run-json-pointer-lab.ps1')) {
    $probe = New-ParameterProbe (Join-Path $PSScriptRoot $name)
    $accepted = $common.Clone()
    if ($name -ceq 'run-json-pointer-lab.ps1') {
        $accepted['QualificationScope'] = 'full'
    }
    Assert-Bound $probe $accepted ($name + '/canonical')

    foreach ($change in @(
        @{ Key = 'Platform'; Value = 'LiNuX' },
        @{ Key = 'Platform'; Value = 'Windows' },
        @{ Key = 'DeploymentModes'; Value = @('LoCaL') },
        @{ Key = 'DeploymentModes'; Value = @('Central') }
    )) {
        $variant = $accepted.Clone()
        $variant[$change.Key] = $change.Value
        Assert-Rejected $probe $variant ($name + '/' + $change.Key)
    }

    if ($name -ceq 'run-json-pointer-lab.ps1') {
        $lifecycle = $accepted.Clone()
        $lifecycle['QualificationScope'] = 'lifecycle'
        Assert-Bound $probe $lifecycle ($name + '/lifecycle')
        foreach ($value in @('FuLl', 'LifeCycle')) {
            $variant = $accepted.Clone()
            $variant['QualificationScope'] = $value
            Assert-Rejected $probe $variant ($name + '/QualificationScope')
        }
    }
}

Write-Output 'PASS: SAFE_CAST_JSON_POINTER_STRICT_ARGUMENT_BINDING_NO_LAB'
