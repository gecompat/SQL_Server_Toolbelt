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

# SC-045: TLS-Vertrag an der echten Builderfunktion, ohne Netzwerkzugriff.
$tlsNode = @($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'New-LabConnectionString'}, $false))
if ($tlsNode.Count -ne 1) { throw 'LAB_TLS_BUILDER_MISSING' }
. ([scriptblock]::Create($tlsNode[0].Extent.Text))
$entry = [pscustomobject]@{host='localhost';port=1433;database='Contoso';username='Contoso';password='synthetic';encrypt=$true;trustServerCertificate=$false}
$builder = [Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $entry))
if (-not $builder.Encrypt -or $builder.TrustServerCertificate -or $builder.DataSource -cne 'tcp:localhost,1433') { throw 'LAB_TLS_BUILDER_POLICY' }
$tlsCases = 1
foreach ($pair in @(@($false,$false),@($true,$true),@('true',$false),@($true,'false'),@($null,$false),@($true,$null),@(1,$false),@($true,0))) {
    $entry.encrypt=$pair[0];$entry.trustServerCertificate=$pair[1];$rejected=$false
    try { [void](New-LabConnectionString -Entry $entry) } catch { $rejected=$true }
    if (-not $rejected) { throw 'LAB_TLS_INVALID_CONTRACT_ACCEPTED' }
    $tlsCases++
}
Write-Output "LAB_TLS_CONTRACT_PASS cases=$tlsCases"

$tlsHelper=Join-Path $PSScriptRoot 'Set-SqlClientTlsPolicy.ps1'
$tlsNames=@('TBX_SQL_TARGET','TBX_SQL_ENCRYPT','TBX_SQL_TRUST_SERVER_CERTIFICATE')
$savedTls=@{};foreach($name in $tlsNames){$savedTls[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try {
    $env:TBX_SQL_TARGET='lab';$env:TBX_SQL_ENCRYPT='True';$env:TBX_SQL_TRUST_SERVER_CERTIFICATE='False'
    & $tlsHelper -Builder $builder
    if (-not $builder.Encrypt -or $builder.TrustServerCertificate) {throw 'LAB_METADATA_TLS_BYPASS'}
    $env:TBX_SQL_TRUST_SERVER_CERTIFICATE='True';$rejected=$false
    try {& $tlsHelper -Builder $builder} catch {$rejected=$true}
    if (-not $rejected) {throw 'LAB_METADATA_TLS_INVALID_ACCEPTED'}
    $env:TBX_SQL_TARGET='runner';$builder['Data Source']='tcp:127.0.0.1,1433'
    & $tlsHelper -Builder $builder
    if (-not $builder.TrustServerCertificate) {throw 'DISPOSABLE_LOOPBACK_TLS_CHANGED'}
    $builder['Data Source']='tcp:database.example,1433'
    & $tlsHelper -Builder $builder
    if ($builder.TrustServerCertificate) {throw 'NON_LOOPBACK_TLS_BYPASS'}
    Write-Output 'SQLCLIENT_TLS_POLICY_PASS cases=4'
} finally {foreach($name in $tlsNames){[Environment]::SetEnvironmentVariable($name,$savedTls[$name],'Process')}}
