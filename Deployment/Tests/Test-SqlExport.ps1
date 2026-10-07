# Exportregression ohne SQL-Verbindung, CLR-Build oder Truständerung.
# Nur eigene kleine Fixtures werden angelegt; sämtliche SQL-Dateien bleiben Daten.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:cases = 0
$script:assertions = 0
$script:caseId = 'setup'
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runner = Join-Path $repositoryRoot 'Deployment/Deploy-All.ps1'
$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$ownedRoot = Join-Path $tempParent ('toolbelt-export-test-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$oldPath = $env:PATH

function Assert-Export([bool]$Condition, [string]$Id) {
    $script:assertions++
    if (-not $Condition) { throw "SQL_EXPORT_ASSERT:$($script:caseId):$Id" }
}

function Start-ExportCase([string]$Id) {
    $script:caseId = $Id
    $script:cases++
}

function Write-Fixture([string]$Path, [string]$Text) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Invoke-Export([string]$ScriptPath, [hashtable]$Parameters) {
    # Selbst ein versehentlicher Wechsel in den Ausführungspfad darf keinen
    # echten sqlcmd im PATH finden oder eine Passwortabfrage auslösen.
    & $ScriptPath @Parameters *> $null
}

function Assert-Rejected([string]$ScriptPath, [hashtable]$Parameters, [string]$Reason, [string]$OutputPath) {
    $caught = $null
    try { Invoke-Export $ScriptPath $Parameters } catch { $caught = $_ }
    Assert-Export ($null -ne $caught) 'rejected'
    Assert-Export ($caught.Exception.Message -match $Reason) 'specific-reason'
    if ($OutputPath) { Assert-Export (-not [IO.File]::Exists($OutputPath)) 'no-output' }
    Assert-Export (@(Get-ChildItem -LiteralPath $ownedRoot -Recurse -File -Filter '.toolbelt-export-*.tmp').Count -eq 0) 'no-partial-export'
}

function Read-Export([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    Assert-Export ($bytes.Length -gt 3) 'nonempty'
    Assert-Export (-not ($bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)) 'no-bom'
    $text = $utf8.GetString($bytes)
    Assert-Export (-not $text.Contains("`r")) 'lf-only'
    Assert-Export ($text -notmatch '(?m)^[ \t]*:r(?:[ \t]|$)') 'no-includes'
    Assert-Export ($text -notmatch '\$\(') 'no-variables'
    foreach ($privatePath in @($repositoryRoot, $ownedRoot)) {
        Assert-Export (-not $text.Contains($privatePath)) 'no-absolute-path'
        Assert-Export (-not $text.Contains($privatePath.Replace('\', '/'))) 'no-normalized-path'
    }
    Assert-Export ($text -match '(?m)^:ON ERROR EXIT$') 'sqlcmd-abort'
    return $text
}

function Get-MarkedIds([string]$Text) {
    return @([regex]::Matches($Text, '(?m)^-- BEGIN MODULE ([a-z0-9.-]+)$') | ForEach-Object { $_.Groups[1].Value })
}

function New-FixtureModule([string]$Id, [string]$Dependencies, [string]$Sql) {
    $moduleRoot = Join-Path $fixtureRoot "Modules/$Id"
    Write-Fixture (Join-Path $moduleRoot 'module.yaml') ("module_id: $Id`ndependencies: $Dependencies`n")
    Write-Fixture (Join-Path $moduleRoot 'Deployment/Deploy.sql') $Sql
    return $moduleRoot
}

# Diese kleinen Hex-Literale sind ausschließlich Exporteingaben, keine
# installierbaren Assemblies oder freigegebenen Binary-/Trusthashes.
$allInputs = @{}
foreach ($id in @(
    'toolbelt.archive.zip-memory', 'toolbelt.file.csv-memory',
    'toolbelt.file.xlsx-memory', 'toolbelt.filesystem.windows',
    'toolbelt.json.constructors', 'toolbelt.json.core', 'toolbelt.json.schema',
    'toolbelt.string.edit-distance', 'toolbelt.string.phonetic',
    'toolbelt.string.regex', 'toolbelt.tsql.script-parser'
)) { $allInputs[$id] = @{ AssemblyBits = '0x0102' } }
$allInputs['toolbelt.tsql.script-parser']['ScriptDomAssemblyBits'] = '0x0304'
$allInputs['toolbelt.string.edit-distance']['ExpectedInstalledAssemblyHash'] = '0x'
$allInputs['toolbelt.string.phonetic']['ExpectedInstalledAssemblyHash'] = '0x'
$allInputs['toolbelt.string.regex']['ExpectedInstalledAssemblyHash'] = '0x'
$allInputs['toolbelt.string.text-pairs'] = @{ ExpectedComparisonAssemblyHash = '0x' + ('AB' * 64) }
$schemaInputs = @{
    'toolbelt.json.core' = @{ AssemblyBits = '0x0102' }
    'toolbelt.json.schema' = @{ AssemblyBits = '0x0304' }
}

try {
    [void][IO.Directory]::CreateDirectory($ownedRoot)
    $env:PATH = ''
    function Read-Host { throw 'SQL_EXPORT_FORBIDDEN_PROMPT' }

    Start-ExportCase 'actual-all-local'
    $allPath = Join-Path $ownedRoot 'all-local.sql'
    Invoke-Export $runner @{ DeploymentMode = 'local'; OutputSqlFile = $allPath; ModuleVariables = $allInputs }
    $allText = Read-Export $allPath
    $allIds = @(Get-MarkedIds $allText)
    $manifestIds = @(Get-ChildItem (Join-Path $repositoryRoot 'Modules') -Directory | Where-Object {
        [IO.File]::Exists((Join-Path $_.FullName 'Deployment/Deploy.sql'))
    } | ForEach-Object {
        $manifest = [IO.File]::ReadAllText((Join-Path $_.FullName 'module.yaml'), $utf8)
        [regex]::Match($manifest, '(?m)^module_id:\s*["'']?([^"''\s]+)').Groups[1].Value
    })
    Assert-Export ($manifestIds.Count -eq 44) 'inventory44'
    Assert-Export ($allIds.Count -eq 44) 'closure44'
    Assert-Export (@($allIds | Sort-Object -Unique).Count -eq 44) 'unique44'
    Assert-Export ((@($allIds | Sort-Object) -join ',') -ceq (@($manifestIds | Sort-Object) -join ',')) 'exact-inventory'
    Assert-Export ([regex]::Matches($allText, '(?m)^-- END MODULE ').Count -eq 44) 'end44'
    Assert-Export ([regex]::Matches($allText, 'IF @@TRANCOUNT <> 0 OR \(2 & @@OPTIONS\) <> 0').Count -eq 45) 'guards45'
    Assert-Export ([regex]::Matches($allText, '(?m)^GO\n-- END MODULE ').Count -eq 44) 'batch-boundaries44'
    Assert-Export ($allText -match '0x0102' -and $allText -match '0x0304') 'synthetic-binaries'

    Start-ExportCase 'actual-determinism'
    $repeatPath = Join-Path $ownedRoot 'repeat.sql'
    Invoke-Export $runner @{ DeploymentMode = 'local'; OutputSqlFile = $repeatPath; ModuleVariables = $allInputs }
    Assert-Export ([Convert]::ToBase64String([IO.File]::ReadAllBytes($allPath)) -ceq [Convert]::ToBase64String([IO.File]::ReadAllBytes($repeatPath))) 'byte-identical'

    Start-ExportCase 'actual-selected-central'
    $schemaPath = Join-Path $ownedRoot 'schema.sql'
    Invoke-Export $runner @{ DeploymentMode = 'CENTRAL'; ModuleId = @('toolbelt.json.schema'); ModuleVariables = $schemaInputs; OutputSqlFile = $schemaPath }
    $schemaText = Read-Export $schemaPath
    Assert-Export ((@(Get-MarkedIds $schemaText) -join ',') -ceq 'toolbelt.core.result-table,toolbelt.json.core,toolbelt.json.schema') 'dependency-order'
    Assert-Export ($schemaText.Contains('-- DeploymentMode: central')) 'normalized-mode'
    Assert-Export (-not $schemaText.Contains('toolbelt.string.regex')) 'selection-only'
    Assert-Export ([regex]::Matches($schemaText, 'IF @@TRANCOUNT <> 0 OR \(2 & @@OPTIONS\) <> 0').Count -eq 4) 'selected-guards4'

    $rejectCases = @(
        @{ Id = 'missing-binary'; Args = @{ModuleId = @('toolbelt.json.schema')}; Reason = 'Fehlende SQLCMD-Eingaben' },
        @{ Id = 'invalid-binary'; Args = @{ModuleId = @('toolbelt.json.core'); ModuleVariables = @{'toolbelt.json.core' = @{AssemblyBits = '0x1'}}}; Reason = 'gerades.*Hex-Binary' },
        @{ Id = 'invalid-hash'; Args = @{ModuleId = @('toolbelt.string.regex'); ModuleVariables = @{'toolbelt.string.regex' = @{AssemblyBits = '0x01'; ExpectedInstalledAssemblyHash = '0x12'}}}; Reason = 'SHA2-512-Hash' },
        @{ Id = 'reserved-variable'; Args = @{ModuleId = @('toolbelt.json.core'); ModuleVariables = @{'toolbelt.json.core' = @{AssemblyBits = '0x01'; DeploymentMode = 'central'}}}; Reason = 'reservierte SQLCMD-Variable' },
        @{ Id = 'unknown-variable'; Args = @{ModuleId = @('toolbelt.json.core'); ModuleVariables = @{'toolbelt.json.core' = @{AssemblyBits = '0x01'; Unknown = 'Contoso'}}}; Reason = 'Unbekannte.*SQLCMD-Variable' },
        @{ Id = 'unknown-module'; Args = @{ModuleId = @('toolbelt.contoso.missing')}; Reason = 'Unbekanntes Deployment-Modul' },
        @{ Id = 'unselected-input'; Args = @{ModuleId = @('toolbelt.json.core'); ModuleVariables = $schemaInputs}; Reason = 'nicht ausgewähltes Modul' }
    )
    foreach ($case in $rejectCases) {
        Start-ExportCase $case.Id
        $output = Join-Path $ownedRoot ($case.Id + '.sql')
        $parameters = @{ DeploymentMode = 'local'; OutputSqlFile = $output }
        foreach ($key in $case.Args.Keys) { $parameters[$key] = $case.Args[$key] }
        Assert-Rejected $runner $parameters $case.Reason $output
    }

    foreach ($pair in @(
        @{Name = 'PlanOnly'; Value = $true}, @{Name = 'ServerInstance'; Value = 'Contoso'},
        @{Name = 'Database'; Value = 'Contoso'}, @{Name = 'Authentication'; Value = 'Windows'},
        @{Name = 'SqlUsername'; Value = 'Contoso'}, @{Name = 'CreateDatabaseIfMissing'; Value = $false}
    )) {
        Start-ExportCase ('incompatible-' + $pair.Name)
        $output = Join-Path $ownedRoot ($script:caseId + '.sql')
        $parameters = @{DeploymentMode = 'local'; OutputSqlFile = $output}
        $parameters[$pair.Name] = $pair.Value
        Assert-Rejected $runner $parameters ('kann nicht mit -' + $pair.Name) $output
    }

    Start-ExportCase 'no-overwrite'
    $sentinelPath = Join-Path $ownedRoot 'sentinel.sql'
    $sentinel = [byte[]]@(0, 1, 2, 255)
    [IO.File]::WriteAllBytes($sentinelPath, $sentinel)
    Assert-Rejected $runner @{DeploymentMode = 'local'; ModuleId = @('toolbelt.json.core'); ModuleVariables = @{'toolbelt.json.core' = @{AssemblyBits = '0x01'}}; OutputSqlFile = $sentinelPath} 'existiert bereits' ''
    Assert-Export ([Convert]::ToBase64String([IO.File]::ReadAllBytes($sentinelPath)) -ceq [Convert]::ToBase64String($sentinel)) 'sentinel-preserved'

    Start-ExportCase 'wrong-extension'
    $wrongPath = Join-Path $ownedRoot 'output.txt'
    Assert-Rejected $runner @{DeploymentMode = 'local'; ModuleId = @('toolbelt.json.core'); ModuleVariables = @{'toolbelt.json.core' = @{AssemblyBits = '0x01'}}; OutputSqlFile = $wrongPath} 'Dateiendung .sql' $wrongPath

    Start-ExportCase 'missing-directory'
    $missingPath = Join-Path $ownedRoot 'missing/output.sql'
    Assert-Rejected $runner @{DeploymentMode = 'local'; ModuleId = @('toolbelt.json.core'); ModuleVariables = @{'toolbelt.json.core' = @{AssemblyBits = '0x01'}}; OutputSqlFile = $missingPath} 'Zielverzeichnis.*existieren' $missingPath
    Assert-Export (-not [IO.Directory]::Exists((Join-Path $ownedRoot 'missing'))) 'no-directory-created'

    # Die Kopie bindet dieselben Runnerbytes an eine kleine, kontrollierte
    # Modulclosure und prüft echte Discovery, Expansion und Veröffentlichung.
    $fixtureRoot = Join-Path $ownedRoot 'fixture'
    $fixtureRunner = Join-Path $fixtureRoot 'Deployment/Deploy-All.ps1'
    Write-Fixture $fixtureRunner ([IO.File]::ReadAllText($runner, $utf8))
    $a = New-FixtureModule 'toolbelt.contoso.a' '[]' "SELECT 'ORDER_A';`nGO`n"
    $b = New-FixtureModule 'toolbelt.contoso.b' '[{module_id: toolbelt.contoso.a}]' @'
SELECT 'ORDER_B0';
:r "../Source/Outer File.sql"
SELECT 'ORDER_B1';
'@
    Write-Fixture (Join-Path $b 'Source/Outer File.sql') @'
SELECT 'ORDER_OUTER0', '$(Token)';
:r './Inner.sql'
SELECT 'ORDER_OUTER1';
'@
    Write-Fixture (Join-Path $b 'Source/Inner.sql') "SELECT 'ORDER_INNER', '`$(tOkEn)', N'Grüße';`n"

    Start-ExportCase 'recursive-order'
    $fixtureOutput = Join-Path $ownedRoot 'fixture.sql'
    $fixtureArgs = @{DeploymentMode = 'local'; ModuleId = @('toolbelt.contoso.b'); ModuleVariables = @{'toolbelt.contoso.b' = @{TOKEN = 'Contoso'}}; OutputSqlFile = $fixtureOutput}
    Invoke-Export $fixtureRunner $fixtureArgs
    $fixtureText = Read-Export $fixtureOutput
    Assert-Export ((@(Get-MarkedIds $fixtureText) -join ',') -ceq 'toolbelt.contoso.a,toolbelt.contoso.b') 'fixture-dependency'
    $previous = -1
    foreach ($token in @('ORDER_A', 'ORDER_B0', 'ORDER_OUTER0', 'ORDER_INNER', 'ORDER_OUTER1', 'ORDER_B1')) {
        $position = $fixtureText.IndexOf($token, [StringComparison]::Ordinal)
        Assert-Export ($position -gt $previous) 'include-order'
        $previous = $position
    }
    Assert-Export ([regex]::Matches($fixtureText, "'Contoso'").Count -eq 2) 'case-insensitive-variable'
    Assert-Export ($fixtureText.Contains("N'Grüße'")) 'utf8-content'

    foreach ($directive in @(':connect Contoso', ':setvar Token Fabrikam', ':out Contoso.sql', '!! echo Contoso')) {
        Start-ExportCase ('directive-' + $script:cases)
        Write-Fixture (Join-Path $b 'Source/Inner.sql') ($directive + "`n")
        $output = Join-Path $ownedRoot ($script:caseId + '.sql')
        Assert-Rejected $fixtureRunner @{DeploymentMode = 'local'; OutputSqlFile = $output; ModuleVariables = @{'toolbelt.contoso.b' = @{Token = 'Contoso'}}} 'nicht unterstützte SQLCMD-Direktive' $output
    }

    Start-ExportCase 'unsupported-variable-syntax'
    Write-Fixture (Join-Path $b 'Source/Inner.sql') "SELECT '`$(Unknown-Name)';`n"
    $output = Join-Path $ownedRoot 'unsupported-variable.sql'
    Assert-Rejected $fixtureRunner @{DeploymentMode = 'local'; OutputSqlFile = $output; ModuleVariables = @{'toolbelt.contoso.b' = @{Token = 'Contoso'}}} 'nicht unterstützte SQLCMD-Variablensyntax' $output

    Start-ExportCase 'nested-unknown-variable'
    Write-Fixture (Join-Path $b 'Source/Inner.sql') "SELECT '`$(Unknown)';`n"
    $output = Join-Path $ownedRoot 'nested-missing.sql'
    Assert-Rejected $fixtureRunner @{DeploymentMode = 'local'; OutputSqlFile = $output; ModuleVariables = @{'toolbelt.contoso.b' = @{Token = 'Contoso'}}} 'Fehlende SQLCMD-Eingaben' $output

    Start-ExportCase 'nested-missing-include'
    Write-Fixture (Join-Path $b 'Source/Inner.sql') ":r Missing.sql`n"
    $output = Join-Path $ownedRoot 'missing-include.sql'
    Assert-Rejected $fixtureRunner @{DeploymentMode = 'local'; OutputSqlFile = $output} 'SQLCMD-Include fehlt' $output

    Start-ExportCase 'nested-cycle'
    Write-Fixture (Join-Path $b 'Source/Inner.sql') ":r './Outer File.sql'`n"
    $output = Join-Path $ownedRoot 'cycle.sql'
    Assert-Rejected $fixtureRunner @{DeploymentMode = 'local'; OutputSqlFile = $output} 'Zyklisches SQLCMD-Include' $output

    Start-ExportCase 'include-outside-modules'
    Write-Fixture (Join-Path $fixtureRoot 'Outside.sql') "SELECT 'Contoso';`n"
    Write-Fixture (Join-Path $b 'Deployment/Deploy.sql') ":r ../../../Outside.sql`n"
    $output = Join-Path $ownedRoot 'outside.sql'
    Assert-Rejected $fixtureRunner @{DeploymentMode = 'local'; OutputSqlFile = $output} 'nur Includes innerhalb von Modules' $output
}
catch {
    # Ausschließlich feste Kennungen, keine Pfade oder originale Fehltexte.
    if ($_.Exception.Message -match '^SQL_EXPORT_ASSERT:[a-zA-Z0-9.-]+:[a-zA-Z0-9.-]+$') {
        [Console]::Out.WriteLine($_.Exception.Message)
    }
    else { [Console]::Out.WriteLine("SQL_EXPORT_TEST_FAILED:$($script:caseId)") }
    exit 1
}
finally {
    $env:PATH = $oldPath
    # Der vollständig aufgelöste Zielpfad muss genau unser direktes temporäres
    # Kind bleiben. Keine zusammengesetzten Shellbefehle oder fremden Ziele.
    $resolved = [IO.Path]::GetFullPath($ownedRoot)
    if ([IO.Path]::GetDirectoryName($resolved).TrimEnd([IO.Path]::DirectorySeparatorChar) -ceq $tempParent.TrimEnd([IO.Path]::DirectorySeparatorChar) -and
        [IO.Path]::GetFileName($resolved) -match '^toolbelt-export-test-[0-9a-f]{32}$' -and [IO.Directory]::Exists($resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
    else { throw 'SQL_EXPORT_CLEANUP_BOUNDARY' }
}
[Console]::Out.WriteLine("SQL_EXPORT_TEST_PASS cases=$($script:cases) assertions=$($script:assertions)")
