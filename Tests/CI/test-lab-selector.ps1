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

# Fachtests und authentifizierte TLS-Prüfung: echte Builderfunktion, kein Netzwerk.
$tlsNode = @($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'New-LabConnectionString'}, $false))
if ($tlsNode.Count -ne 1) { throw 'LAB_TLS_BUILDER_MISSING' }
. ([scriptblock]::Create($tlsNode[0].Extent.Text))
$entry = [pscustomobject]@{host='localhost';port=1433;database='Contoso';username='Contoso';password='synthetic';encrypt=$true;trustServerCertificate=$false}
$tlsCases=0
foreach($purpose in @('Functional','AuthenticatedTls')) {
    foreach($trust in @($false,$true)) {
        $entry.trustServerCertificate=$trust
        if($purpose -ceq 'AuthenticatedTls' -and $trust) {
            $rejected=$false
            try {[void](New-LabConnectionString -Entry $entry -TestPurpose $purpose)} catch {$rejected=$true}
            if(-not $rejected){throw 'AUTHENTICATED_TLS_OVERRIDE_ACCEPTED'}
        } else {
            $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $entry -TestPurpose $purpose))
            if(-not $builder.Encrypt -or $builder.TrustServerCertificate -ne $trust -or $builder.DataSource -cne 'tcp:localhost,1433'){throw 'LAB_BUILDER_CONTRACT_CHANGED'}
        }
        $tlsCases++
    }
}
$entry.trustServerCertificate=$true
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $entry))
if(-not $builder.TrustServerCertificate){throw 'FUNCTIONAL_DEFAULT_CHANGED'}
$tlsCases++
foreach($purpose in @('Functional','AuthenticatedTls')) {
    foreach($pair in @(@($false,$false),@('true',$false),@($true,'false'),@($null,$false),@($true,$null),@(1,$false),@($true,0))) {
        $entry.encrypt=$pair[0];$entry.trustServerCertificate=$pair[1];$rejected=$false
        try {[void](New-LabConnectionString -Entry $entry -TestPurpose $purpose)} catch {$rejected=$true}
        if(-not $rejected){throw 'LAB_INVALID_CONTRACT_ACCEPTED'}
        $tlsCases++
    }
}
$entry.encrypt=$true;$entry.trustServerCertificate=$true
foreach($purpose in @('Unknown','authenticatedtls')) {
    $rejected=$false
    try {[void](New-LabConnectionString -Entry $entry -TestPurpose $purpose)} catch {$rejected=$true}
    if(-not $rejected){throw 'LAB_INVALID_PURPOSE_ACCEPTED'}
    $tlsCases++
}
Write-Output "LAB_TLS_CONTRACT_PASS cases=$tlsCases"

$tlsHelper=Join-Path $PSScriptRoot 'Set-SqlClientTlsPolicy.ps1'
$tlsNames=@('TBX_SQL_TARGET','TBX_SQL_ENCRYPT','TBX_SQL_TRUST_SERVER_CERTIFICATE','TBX_SQL_TEST_PURPOSE','GITHUB_ACTIONS')
$savedTls=@{};foreach($name in $tlsNames){$savedTls[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try {
    $policyCases=@(
        @('lab','Functional','True','False','false','tcp:localhost,1433',$false,$false),
        @('lab','Functional','True','True','false','tcp:localhost,1433',$true,$false),
        @('lab','AuthenticatedTls','True','False','false','tcp:localhost,1433',$false,$false),
        @('lab','AuthenticatedTls','True','True','false','tcp:localhost,1433',$false,$true),
        @('lab','Unknown','True','False','false','tcp:localhost,1433',$false,$true),
        @('lab','Functional','True','false','false','tcp:localhost,1433',$false,$true),
        @('lab','Functional','True','','false','tcp:localhost,1433',$false,$true),
        @('lab','Functional','False','True','false','tcp:localhost,1433',$false,$true),
        @('lab','','True','True','false','tcp:localhost,1433',$true,$false),
        @('runner','','True','True','false','tcp:127.0.0.1,1433',$true,$false),
        @('runner','','True','True','false','tcp:database.example,1433',$false,$false),
        @('','','True','True','false','tcp:127.0.0.1,1433',$false,$false),
        @('lab','AuthenticatedTls','True','False','true','tcp:localhost,1433',$false,$false)
    )
    foreach($test in $policyCases) {
        $env:TBX_SQL_TARGET=$test[0];$env:TBX_SQL_TEST_PURPOSE=$test[1];$env:TBX_SQL_ENCRYPT=$test[2]
        $env:TBX_SQL_TRUST_SERVER_CERTIFICATE=$test[3];$env:GITHUB_ACTIONS=$test[4]
        $builder['Data Source']=$test[5];$rejected=$false
        try {& $tlsHelper -Builder $builder} catch {$rejected=$true}
        if($rejected -ne $test[7]){throw 'SQLCLIENT_PURPOSE_GATE_CHANGED'}
        if(-not $rejected -and (-not $builder.Encrypt -or $builder.TrustServerCertificate -ne $test[6])){throw 'SQLCLIENT_TRANSPORT_CHANGED'}
    }
    Write-Output ('SQLCLIENT_TLS_POLICY_PASS cases='+$policyCases.Count)
} finally {foreach($name in $tlsNames){[Environment]::SetEnvironmentVariable($name,$savedTls[$name],'Process')}}
