# Synthetische Vertragseinträge; keine Labverbindung und keine Runnerinitialisierung.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot 'run-lab-local.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Runner hat PowerShell-Syntaxfehler.' }

# Nur die produktiven Selektionsfunktionen laden; Top-Level-Code darf keine
# Verträge auflösen, sqlcmd starten oder SQL-Ziele verändern.
foreach ($name in @('Test-LabTargetReady', 'Get-LabTargetsForSelector', 'Get-LabTargetsForSelectors')) {
    $definitions = @($ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
    }, $false))
    if ($definitions.Count -ne 1) { throw "Selektionsfunktion fehlt oder ist mehrdeutig: $name" }
    . ([scriptblock]::Create($definitions[0].Extent.Text))
}

function New-Entry {
    param($Key, $Patch, $Platform = 'windows', $Version = '2022', $Status = 'READY', $Runtime = 'READY')
    [pscustomobject]@{ key = $Key; patch = $Patch; platform = $Platform; sqlVersion = $Version; status = $Status; runtimeStatus = $Runtime }
}
function New-Selector {
    param($Patch, $Platform = 'windows', $Version = '2022')
    [pscustomobject]@{ Patch = $Patch; Platform = $Platform; Version = $Version }
}
function Assert-Keys {
    param($Actual, [string[]]$Expected, [string]$Case)
    $keys = @($Actual | ForEach-Object { $_.key })
    if (($keys -join '|') -cne ($Expected -join '|')) { throw "Selektionsfall fehlgeschlagen: $Case" }
    $script:caseCount++
}
$caseCount = 0
$contract = [pscustomobject]@{
    groupStatus = 'READY'
    environments = @(
        (New-Entry 'cu32' 'cu32'),
        (New-Entry 'cu8-b' 'CU8'),
        (New-Entry 'base-b' 'base'),
        (New-Entry 'cu26' 'Cu26'),
        (New-Entry 'cu8-a' 'cu8'),
        (New-Entry 'base-a' 'base'),
        (New-Entry 'other-version' 'cu32' -Version '2019'),
        (New-Entry 'other-platform' 'cu32' -Platform 'linux'),
        (New-Entry 'stopped' 'cu32' -Runtime 'STOPPED'),
        (New-Entry 'not-ready' 'cu32' -Status 'GROUP_INCOMPLETE'),
        (New-Entry 'latest' 'latest')
    )
}
foreach ($patch in @('CU32', 'Cu32', 'cu32')) {
    Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector $patch)) @('cu32') "CU-Schreibung $patch"
}
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'CU31')) @() 'Andere CU ausgeschlossen'
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'cu8')) @('cu8-b', 'cu8-a') 'CU-Eingabe trifft Groß-/Kleinschreibung im Vertrag'
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'base')) @('base-a', 'base-b', 'cu8-a', 'cu8-b', 'cu26', 'cu32') 'base numerisch und stabil'
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'CU32' -Version '2019')) @('other-version') 'Version exakt'
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'CU32' -Platform 'linux')) @('other-platform') 'Plattform exakt'
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'latest')) @('latest') 'latest exakt'
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'LATEST')) @() 'Andere Patchschreibung unverändert'
Assert-Keys @(Get-LabTargetsForSelector $contract (New-Selector 'base' -Platform 'linux')) @() 'Keine Linux-base-CU-Äquivalenz'
Assert-Keys @(Get-LabTargetsForSelectors $contract @((New-Selector 'base'), (New-Selector 'CU32'), (New-Selector 'cu32'))) @('base-a', 'base-b', 'cu8-a', 'cu8-b', 'cu26', 'cu32') 'Überlappende Auswahlen dedupliziert'
Assert-Keys @(Get-LabTargetsForSelectors $contract @((New-Selector 'CU32'), (New-Selector 'base'))) @('cu32', 'base-a', 'base-b', 'cu8-a', 'cu8-b', 'cu26') 'Erste Trefferreihenfolge bleibt erhalten'
$missingRejected = $false
try { Get-LabTargetsForSelectors $contract @((New-Selector 'base'), (New-Selector 'CU31')) | Out-Null }
catch { $missingRejected = $_.Exception.Message -like 'Keine passenden einzeln bereiten Ziele vorhanden:*' }
if (-not $missingRejected) { throw 'Fehlende explizite CU wurde durch base verdeckt.' }
$caseCount++

$incomplete = [pscustomobject]@{
    groupStatus = 'INCOMPLETE'
    environments = @(
        (New-Entry 'ready' 'cu32'),
        (New-Entry 'group-incomplete' 'Cu32' -Status 'GROUP_INCOMPLETE'),
        (New-Entry 'stopped' 'cu32' -Runtime 'STOPPED'),
        (New-Entry 'failed' 'cu32' -Status 'FAILED')
    )
}
Assert-Keys @(Get-LabTargetsForSelector $incomplete (New-Selector 'CU32')) @('ready', 'group-incomplete') 'INCOMPLETE-Einzelzielfreigabe'
$incomplete.groupStatus = 'EMPTY'
Assert-Keys @(Get-LabTargetsForSelector $incomplete (New-Selector 'CU32')) @() 'EMPTY ausgeschlossen'
$incomplete.groupStatus = 'UNKNOWN'
Assert-Keys @(Get-LabTargetsForSelector $incomplete (New-Selector 'CU32')) @() 'Unbekannte Gruppe ausgeschlossen'
Write-Output "Lab selector behavior: PASSED ($caseCount synthetic cases; no Lab access)"
