[CmdletBinding()]
param(
    [string[]]$Versions = @('2019', '2022', '2025'),
    [string[]]$Platforms = @('linux', 'windows'),
    [string[]]$LinuxPatches = @('latest'),
    [string[]]$WindowsPatches = @('base'),
    [string]$TestSuite = 'full',
    [string[]]$RunScripts = @(
        'run-result-table-linux.sh',
        'run-base64-linux.sh',
        'run-generate-series-linux.sh',
        'run-identifier-linux.sh',
        'run-split-characters-linux.sh',
        'run-semantic-version-linux.sh',
        'run-integer-base-linux.sh',
        'run-w1-linux.sh',
        'run-w2a-linux.sh',
        'run-w2b-json-path-linux.sh',
        'run-w2c-linux.sh',
        'run-w4a-execution-foundations-linux.sh',
        'run-w4b-work-type-linux.sh',
        'run-w5a-second-session-linux.sh',
        'run-w5b-event-log-linux.sh',
        'run-zip-memory-linux.sh'
    ),
    [string]$ZipMemoryAssemblyRoot = '.runtime/zip-memory-release',
    [switch]$StopOnFailure,
    [switch]$PreserveFailureLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Bei Aufruf über `pwsh -File` werden kommagetrennte Werte als ein Argument
# übergeben. Die Normalisierung hält CLI- und interaktive Aufrufe gleichwertig.
$Versions = @($Versions | ForEach-Object { $_ -split ',' })
$Platforms = @($Platforms | ForEach-Object { $_ -split ',' })
$LinuxPatches = @($LinuxPatches | ForEach-Object { $_ -split ',' })
$WindowsPatches = @($WindowsPatches | ForEach-Object { $_ -split ',' })
$RunScripts = @($RunScripts | ForEach-Object { $_ -split ',' })

function Get-EnvironmentVariableValue {
    param([Parameter(Mandatory)][string]$Name)

    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, 'User')
    }

    return $value
}

function Resolve-LabContract {
    $contractPath = Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_FILE'
    if ([string]::IsNullOrWhiteSpace($contractPath)) {
        $dataRoot = Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_DATA_ROOT'
        if (-not [string]::IsNullOrWhiteSpace($dataRoot)) {
            $contractPath = Join-Path $dataRoot 'Exports/TestUmgebung.json'
        }
    }

    if ([string]::IsNullOrWhiteSpace($contractPath) -or
        -not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
        throw 'Kein SQL_Server_Lab-Testvertrag über die vorgesehenen Variablen gefunden.'
    }

    $schemaPath = Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE'
    if ([string]::IsNullOrWhiteSpace($schemaPath)) {
        $schemaPath = Join-Path (Split-Path -Parent $contractPath) 'TestUmgebung.schema.json'
    }

    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
        throw 'Das JSON Schema des SQL_Server_Lab-Testvertrags wurde nicht gefunden.'
    }

    $promptPath = Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
    if (-not [string]::IsNullOrWhiteSpace($promptPath) -and
        -not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
        throw 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE verweist nicht auf eine lesbare Datei.'
    }

    $json = Get-Content -LiteralPath $contractPath -Raw
    if (-not (Test-Json -Json $json -SchemaFile $schemaPath -ErrorAction Stop)) {
        throw 'Der SQL_Server_Lab-Testvertrag ist nicht schema-valide.'
    }

    $contract = $json | ConvertFrom-Json
    if ([string]$contract.groupStatus -cne 'READY') {
        throw 'Die SQL_Server_Lab-Gruppe ist nicht READY.'
    }

    return [PSCustomObject]@{
        Contract = $contract
        Path = $contractPath
        SchemaPath = $schemaPath
    }
}

function Resolve-GitBash {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Git/bin/bash.exe'),
        $(if (${env:ProgramFiles(x86)}) {
            Join-Path ${env:ProgramFiles(x86)} 'Git/bin/bash.exe'
        })
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return $candidate
        }
    }

    throw 'Git Bash wurde nicht gefunden.'
}

function ConvertTo-BashPath {
    param(
        [Parameter(Mandatory)][string]$Bash,
        [Parameter(Mandatory)][string]$Path
    )

    $converted = & $Bash -lc "cygpath -u '$($Path -replace "'", "'\\''")'"
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($converted)) {
        throw 'Ein lokaler Pfad konnte nicht für Git Bash konvertiert werden.'
    }

    return $converted.Trim()
}

function New-LabConnectionString {
    param([Parameter(Mandatory)]$Entry)

    if (-not $Entry.encrypt -or -not $Entry.trustServerCertificate) {
        throw 'Der ausgewählte Eintrag erfüllt den TLS-Vertrag nicht.'
    }

    $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source'] = 'tcp:{0},{1}' -f [string]$Entry.host, [int]$Entry.port
    $builder['Initial Catalog'] = [string]$Entry.database
    $builder['User ID'] = [string]$Entry.username
    $builder['Password'] = [string]$Entry.password
    $builder['Encrypt'] = $true
    $builder['TrustServerCertificate'] = $true
    $builder['Connect Timeout'] = 15
    $builder['Application Name'] = 'SQL_Server_Toolbelt_Lab'
    return $builder.ConnectionString
}

function Invoke-LabPreflight {
    param([Parameter(Mandatory)]$Entry)

    $started = [DateTimeOffset]::UtcNow
    $connection = $null
    try {
        $connection = [System.Data.SqlClient.SqlConnection]::new(
            (New-LabConnectionString -Entry $Entry))
        $connection.Open()

        $command = $connection.CreateCommand()
        $command.CommandTimeout = 30
        $command.CommandText = 'SELECT @@VERSION;'
        [void]$command.ExecuteScalar()

        $command.CommandText =
            'SELECT name, state_desc FROM sys.databases ORDER BY database_id;'
        $reader = $command.ExecuteReader()
        while ($reader.Read()) {
            [void]$reader.GetString(0)
            [void]$reader.GetString(1)
        }
        $reader.Close()

        $command.CommandText =
            "SELECT CONVERT(nvarchar(128), SERVERPROPERTY('ProductVersion'));"
        $actualVersion = [string]$command.ExecuteScalar()
        $expectedMajor = @{
            '2019' = 15
            '2022' = 16
            '2025' = 17
        }[[string]$Entry.sqlVersion]
        $actualMajor = [int]($actualVersion.Split('.')[0])
        if ($actualMajor -ne $expectedMajor) {
            throw 'Die erkannte SQL-Hauptversion entspricht nicht der Auswahl.'
        }

        return [PSCustomObject]@{
            ActualVersion = $actualVersion
            DurationMs = [int]([DateTimeOffset]::UtcNow - $started).TotalMilliseconds
        }
    }
    finally {
        if ($null -ne $connection) {
            $connection.Dispose()
        }
    }
}

function Get-ZipCompatibilityLevels {
    param([Parameter(Mandatory)][string]$Version)

    switch ($Version) {
        '2019' { return @('150') }
        '2022' { return @('160') }
        '2025' { return @('150', '160', '170') }
        default { throw 'Nicht unterstützte SQL-Version für ZIP-Memory.' }
    }
}

function Get-SafeFailureCause {
    param([Parameter(Mandatory)][System.Management.Automation.ErrorRecord]$ErrorRecord)

    if ($ErrorRecord.Exception -is [System.Data.SqlClient.SqlException]) {
        return 'SQL_CLIENT_OR_NETWORK_{0}' -f $ErrorRecord.Exception.Number
    }

    return 'LOCAL_RUNNER_{0}' -f $ErrorRecord.Exception.GetType().Name
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$bash = Resolve-GitBash
$sqlcmd = Get-Command sqlcmd -ErrorAction Stop
$adapterPath = Join-Path $PSScriptRoot 'run-lab-target.sh'
$adapterBashPath = ConvertTo-BashPath -Bash $bash -Path $adapterPath
$zipReleaseRoot = $null
$resolvedZipReleaseRoot = Resolve-Path `
    (Join-Path $repoRoot $ZipMemoryAssemblyRoot) `
    -ErrorAction SilentlyContinue
if ($null -ne $resolvedZipReleaseRoot) {
    $zipReleaseRoot = $resolvedZipReleaseRoot.Path
}
$lab = Resolve-LabContract

$requestedSelectors = [System.Collections.Generic.List[object]]::new()
foreach ($platform in $Platforms) {
    $platformPatches = switch -CaseSensitive ($platform) {
        'linux' { $LinuxPatches }
        'windows' { $WindowsPatches }
        default { throw "Nicht unterstützte Plattformauswahl: $platform" }
    }

    foreach ($version in $Versions) {
        foreach ($patch in $platformPatches) {
            $requestedSelectors.Add([PSCustomObject]@{
                Platform = $platform
                Version = $version
                Patch = $patch
            })
        }
    }
}

$targets = [System.Collections.Generic.List[object]]::new()
$missingSelectors = [System.Collections.Generic.List[string]]::new()
foreach ($selector in $requestedSelectors) {
    $matches = @($lab.Contract.environments | Where-Object {
        [string]$_.status -ceq 'READY' -and
        [string]$_.platform -ceq [string]$selector.Platform -and
        [string]$_.sqlVersion -ceq [string]$selector.Version -and
        [string]$_.patch -ceq [string]$selector.Patch
    })

    if ($matches.Count -eq 0) {
        $missingSelectors.Add('{0}/{1}/{2}' -f
            $selector.Platform, $selector.Version, $selector.Patch)
        continue
    }

    foreach ($match in $matches) {
        $targets.Add($match)
    }
}

if ($missingSelectors.Count -gt 0) {
    throw ('Keine passenden READY-Ziele vorhanden: {0}' -f
        ($missingSelectors -join ', '))
}

$sql2025OnlyAdapters = @()

$managedEnvironmentNames = @(
    'TBX_SQL_TARGET',
    'TBX_SQL_HOST',
    'TBX_SQL_PORT',
    'TBX_SQL_USER',
    'TBX_SQL_PASSWORD',
    'TBX_SQL_DATABASE',
    'TBX_SQL_KEY',
    'TBX_SQL_VERSION',
    'TBX_SQL_PATCH',
    'TBX_SQL_ENCRYPT',
    'TBX_SQL_TRUST_SERVER_CERTIFICATE',
    'TBX_TEST_DB_SUFFIX',
    'TBX_TEST_SQLCMD_BIN',
    'TBX_TEST_SUITE',
    'TBX_SQL_IMAGE',
    'TBX_COMPATIBILITY_LEVEL',
    'TBX_ASSEMBLY_ROOT',
    'TBX_ZIP_ASSEMBLY_HASH',
    'GITHUB_RUN_ID',
    'GITHUB_WORKSPACE'
)
$originalEnvironment = @{}
foreach ($name in $managedEnvironmentNames) {
    $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

$results = [System.Collections.Generic.List[object]]::new()
$adapterResults = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($target in $targets) {
        $targetStarted = [DateTimeOffset]::UtcNow
        $actualVersion = '-'
        $targetStatus = 'PASSED'
        $cause = ''
        $passedTests = 0
        $failedTests = 0
        $notExecutedTests = 0

        try {
            $preflight = Invoke-LabPreflight -Entry $target
            $actualVersion = $preflight.ActualVersion

            foreach ($runScript in $RunScripts) {
                $runScriptPath = Join-Path $PSScriptRoot $runScript
                if (-not (Test-Path -LiteralPath $runScriptPath -PathType Leaf)) {
                    throw "Unbekanntes Run-Skript: $runScript"
                }

                if ($sql2025OnlyAdapters -ccontains $runScript -and
                    [string]$target.sqlVersion -cne '2025') {
                    $notExecutedTests++
                    continue
                }

                $compatibilityLevels = @('')
                if ($runScript -ceq 'run-zip-memory-linux.sh') {
                    if ([string]::IsNullOrWhiteSpace($zipReleaseRoot)) {
                        throw 'Die ZIP-Memory-Release-Artefakte fehlen.'
                    }
                    $manifestPath = Join-Path $zipReleaseRoot 'Toolbelt.Archive.ZipMemory.trust-manifest.json'
                    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
                    $compatibilityLevels = Get-ZipCompatibilityLevels -Version ([string]$target.sqlVersion)
                    $env:TBX_ASSEMBLY_ROOT = $zipReleaseRoot
                    $env:TBX_ZIP_ASSEMBLY_HASH = [string]$manifest.sqlServerHexLiteral
                }

                foreach ($compatibilityLevel in $compatibilityLevels) {
                    $runSuffix = [Guid]::NewGuid().ToString('N').Substring(0, 12)
                    $env:TBX_SQL_TARGET = 'lab'
                    $env:TBX_SQL_HOST = [string]$target.host
                    $env:TBX_SQL_PORT = [string]$target.port
                    $env:TBX_SQL_USER = [string]$target.username
                    $env:TBX_SQL_PASSWORD = [string]$target.password
                    $env:TBX_SQL_DATABASE = [string]$target.database
                    $env:TBX_SQL_KEY = [string]$target.key
                    $env:TBX_SQL_VERSION = [string]$target.sqlVersion
                    $env:TBX_SQL_PATCH = [string]$target.patch
                    $env:TBX_SQL_ENCRYPT = 'True'
                    $env:TBX_SQL_TRUST_SERVER_CERTIFICATE = 'True'
                    $env:TBX_TEST_DB_SUFFIX = $runSuffix
                    $env:TBX_TEST_SQLCMD_BIN = $sqlcmd.Source
                    $env:TBX_TEST_SUITE = $TestSuite
                    $env:TBX_SQL_IMAGE = 'mcr.microsoft.com/mssql/server:{0}-latest' -f [string]$target.sqlVersion
                    $env:GITHUB_RUN_ID = $runSuffix
                    $env:GITHUB_WORKSPACE = $repoRoot

                    if ([string]::IsNullOrWhiteSpace($compatibilityLevel)) {
                        Remove-Item Env:TBX_COMPATIBILITY_LEVEL -ErrorAction SilentlyContinue
                    }
                    else {
                        $env:TBX_COMPATIBILITY_LEVEL = $compatibilityLevel
                    }

                    $runScriptBashPath = ConvertTo-BashPath -Bash $bash -Path $runScriptPath
                    $logPath = Join-Path ([IO.Path]::GetTempPath()) ("tbx-lab-{0}.log" -f $runSuffix)
                    $runFailed = $false
                    try {
                        & $bash $adapterBashPath $runScriptBashPath *> $logPath
                        if ($LASTEXITCODE -ne 0) {
                            throw "Testadapter meldete Exitcode $LASTEXITCODE."
                        }
                        $passedTests++
                        $adapterResults.Add([PSCustomObject]@{
                            Key = [string]$target.key
                            Adapter = $runScript
                            Compatibility = if ($compatibilityLevel) { $compatibilityLevel } else { '-' }
                            Status = 'PASSED'
                            Cause = ''
                        })
                    }
                    catch {
                        $runFailed = $true
                        $failedTests++
                        $targetStatus = 'FAILED'
                        $cause = 'TEST_SCRIPT_EXIT'
                        $adapterResults.Add([PSCustomObject]@{
                            Key = [string]$target.key
                            Adapter = $runScript
                            Compatibility = if ($compatibilityLevel) { $compatibilityLevel } else { '-' }
                            Status = 'FAILED'
                            Cause = 'TEST_SCRIPT_EXIT'
                        })
                        $diagnosticTail = @(
                            Get-Content -LiteralPath $logPath -Tail 80 -ErrorAction SilentlyContinue)
                        $diagnosticLines = [System.Collections.Generic.List[string]]::new()
                        for ($lineIndex = 0; $lineIndex -lt $diagnosticTail.Count; $lineIndex++) {
                            $line = [string]$diagnosticTail[$lineIndex]
                            if ($line -match '^(Msg |Sqlcmd:)') {
                                $diagnosticLines.Add($line)
                                if ($line -match '^Msg ' -and $lineIndex + 1 -lt $diagnosticTail.Count) {
                                    $detailLine = [string]$diagnosticTail[$lineIndex + 1]
                                    if ($detailLine.Length -le 500) {
                                        $diagnosticLines.Add($detailLine)
                                    }
                                }
                            }
                            elseif ($line.Length -le 500 -and
                                    $line -match '(?i)(error|failed|fehler|timeout|invalid|cannot|ungültig|fehlt|erwartet|exitcode|verlor|ließ|blieb|nicht bereit|unbound|command not found|syntax|no such)') {
                                $diagnosticLines.Add($line)
                            }
                        }
                        $safeDiagnostic = @($diagnosticLines | ForEach-Object {
                            if (-not [string]::IsNullOrEmpty([string]$target.password)) {
                                ($_ -replace [regex]::Escape([string]$target.password), '[REDACTED]') `
                                   -replace 'Server\s+[^,\r\n]+,', 'Server [REDACTED],'
                            }
                            else {
                                $_ -replace 'Server\s+[^,\r\n]+,', 'Server [REDACTED],'
                            }
                        })
                        if ($safeDiagnostic.Count -gt 0) {
                            Write-Error ($safeDiagnostic -join [Environment]::NewLine) -ErrorAction Continue
                        }
                        if ($StopOnFailure) {
                            throw
                        }
                    }
                    finally {
                        if (-not ($runFailed -and $PreserveFailureLogs)) {
                            Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        }
        catch {
            $targetStatus = 'FAILED'
            $failedTests++
            if ([string]::IsNullOrWhiteSpace($cause)) {
                $cause = Get-SafeFailureCause -ErrorRecord $_
            }
            if ($StopOnFailure) {
                throw
            }
        }

        if ($targetStatus -ceq 'PASSED' -and
            $passedTests -eq 0 -and
            $notExecutedTests -gt 0) {
            $targetStatus = 'NOT_EXECUTED'
            $cause = 'ADAPTER_VERSION_GAP'
        }

        $results.Add([PSCustomObject]@{
            Key = [string]$target.key
            Platform = [string]$target.platform
            RequestedVersion = [string]$target.sqlVersion
            RequestedPatch = [string]$target.patch
            ActualVersion = $actualVersion
            Status = $targetStatus
            DurationMs = [int]([DateTimeOffset]::UtcNow - $targetStarted).TotalMilliseconds
            Cause = $cause
            PassedTests = $passedTests
            FailedTests = $failedTests
            NotExecutedTests = $notExecutedTests
        })
    }
}
finally {
    foreach ($name in $managedEnvironmentNames) {
        if ($null -eq $originalEnvironment[$name]) {
            Remove-Item "Env:$name" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item "Env:$name" $originalEnvironment[$name]
        }
    }
}

$results | Format-Table -AutoSize
$adapterResults | Format-Table -AutoSize
if (@($results | Where-Object Status -ne 'PASSED').Count -gt 0) {
    exit 1
}
