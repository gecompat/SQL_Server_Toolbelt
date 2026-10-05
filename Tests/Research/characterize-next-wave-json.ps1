# Lesende Engine-Charakterisierung für vorgeschlagene JSON-Pointer-/Safe-Cast-Wellen.
# Keine öffentliche API, Installation, Datenbankanlage oder Konfigurationsänderung.
# Ziele und Credentials bleiben ausschließlich im Speicher; Fehlertexte werden redigiert.
[CmdletBinding()]
param([ValidateSet('json-baseline','decimal-range','pointer-policy')][string]$ProbeSet='json-baseline')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$runExit = 0
# Substantive Assertionfehler dominieren UNKNOWN und fehlende Ausführung.
function Set-CharacterizationExit {
    param([int]$Code)
    if ($script:runExit -eq 1) { return }
    if ($Code -eq 1 -or $script:runExit -ne 3) { $script:runExit = $Code }
}
function Get-CharacterizationFailureKind {
    param([System.Exception]$Exception)
    $current = $Exception
    while ($current) {
        if ($current -is [System.Data.SqlClient.SqlException]) {
            if ($current.Number -eq -2) { return 'NOT_EXECUTED_TIMEOUT' }
            if ($current.Number -in @(53, 10053, 10054, 10060, 10061)) {
                return 'NOT_EXECUTED_CONNECTION'
            }
            return 'INCONCLUSIVE_SQL'
        }
        if ($current -is [System.IO.FileNotFoundException]) {
            return 'NOT_EXECUTED_INPUT'
        }
        $current = $current.InnerException
    }
    return 'INCONCLUSIVE_REDACTED'
}
function Write-CharacterizationFailure {
    param([string]$Label, [System.Exception]$Exception)
    $kind = Get-CharacterizationFailureKind -Exception $Exception
    Write-Output ($Label + ':' + $kind)
    if ($kind.StartsWith('NOT_EXECUTED_', [StringComparison]::Ordinal)) {
        Set-CharacterizationExit -Code 2
    } else { Set-CharacterizationExit -Code 3 }
}
try {
    # Nur die fünf kanonischen Discovery-/Selectorfunktionen laden; den Runner nicht starten.
    $tokens = $null
    $errors = $null
    $runnerPath = Join-Path $PSScriptRoot '../CI/run-lab-local.ps1'
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $runnerPath, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw 'RUNNER_PARSE_FAILED' }
    $names = @('Get-EnvironmentVariableValue', 'Resolve-LabContract',
        'New-LabConnectionString', 'Test-LabTargetReady', 'Get-LabTargetsForSelector')
    $definitions = @($ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $false) | Where-Object { $_.Name -in $names })
    foreach ($name in $names) {
        if (@($definitions | Where-Object { $_.Name -ceq $name }).Count -ne 1) {
            throw 'RUNNER_DEFINITION_AMBIGUOUS'
        }
    }
    foreach ($definition in $definitions) { Invoke-Expression $definition.Extent.Text }
    $resolved = Resolve-LabContract
    $targets = @(Get-LabTargetsForSelector -Contract $resolved.Contract -Selector (
        [pscustomobject]@{ Platform = 'linux'; Version = '2019'; Patch = 'latest' }))
    if ($targets.Count -eq 0) {
        Write-Output 'CHARACTERIZATION_NOT_EXECUTED_NO_SELECTED_READY_TARGET'
        Set-CharacterizationExit -Code 2
    }
    $probes = if($ProbeSet -eq 'pointer-policy') { @(
        # Neue synthetische Engineproben; keine Implementierung des Policywalkers.
        @{ Name = 'NUL_KEY_IDENTITY'; Expected = 'EXACT_ONE'; Sql = 'DECLARE @k nvarchar(3)=CONVERT(nvarchar(3),0x610000006200); SELECT CASE WHEN (SELECT COUNT(*) FROM OPENJSON(N''{"a\u0000b":1,"ab\u0000":2,"\u0000ab":3,"a\u0000c":4}'') WHERE [key] COLLATE Latin1_General_100_BIN2=@k COLLATE Latin1_General_100_BIN2 AND DATALENGTH([key])=DATALENGTH(@k))=1 THEN ''EXACT_ONE'' ELSE ''OTHER'' END' },
        @{ Name = 'RAW_HIGH_ESCAPED_LOW'; Expected = 'PAIRED_UNITS'; Sql = 'DECLARE @h nvarchar(max)=CONVERT(nvarchar(max),0x3DD8); DECLARE @j nvarchar(max)=N''["''+@h+N''\uDE00"]''; SELECT CASE WHEN DATALENGTH(@h)=2 AND ISJSON(@j)=1 AND (SELECT CONVERT(varbinary(max),[value]) FROM OPENJSON(@j))=0x3DD800DE THEN ''PAIRED_UNITS'' ELSE ''OTHER'' END' },
        @{ Name = 'ESCAPED_HIGH_RAW_LOW'; Expected = 'PAIRED_UNITS'; Sql = 'DECLARE @l nvarchar(max)=CONVERT(nvarchar(max),0x00DE); DECLARE @j nvarchar(max)=N''["\uD83D''+@l+N''"]''; SELECT CASE WHEN DATALENGTH(@l)=2 AND ISJSON(@j)=1 AND (SELECT CONVERT(varbinary(max),[value]) FROM OPENJSON(@j))=0x3DD800DE THEN ''PAIRED_UNITS'' ELSE ''OTHER'' END' },
        @{ Name = 'NUMBER_HUGE_EXPONENT_LITERAL'; Expected = 'LITERAL_PRESERVED'; Sql = 'DECLARE @n nvarchar(max)=N''1e1000000''; SELECT CASE WHEN (SELECT CONVERT(varbinary(max),[value]) FROM OPENJSON(N''[''+@n+N'']''))=CONVERT(varbinary(max),@n) THEN ''LITERAL_PRESERVED'' ELSE ''OTHER'' END' },
        @{ Name = 'NUMBER_NEGATIVE_ZERO_LITERAL'; Expected = 'LITERAL_PRESERVED'; Sql = 'DECLARE @n nvarchar(max)=N''-0.000e-999''; SELECT CASE WHEN (SELECT CONVERT(varbinary(max),[value]) FROM OPENJSON(N''[''+@n+N'']''))=CONVERT(varbinary(max),@n) THEN ''LITERAL_PRESERVED'' ELSE ''OTHER'' END' },
        @{ Name = 'DEPTH_128_DIRECT'; Expected = 'VALID_CONTAINER'; Sql = 'DECLARE @j nvarchar(max)=REPLICATE(CAST(N''['' AS nvarchar(max)),128)+N''0''+REPLICATE(CAST(N'']'' AS nvarchar(max)),128); SELECT CASE WHEN ISJSON(@j)=1 THEN ''VALID_CONTAINER'' ELSE ''OTHER'' END' }
    ) } elseif($ProbeSet -eq 'decimal-range') { @(
        @{ Name = 'DECIMAL_MAX_ZERO_TAIL'; Expected = 'EXACT_MAX'; Sql = 'SELECT CASE WHEN TRY_CONVERT(decimal(38,18),N''99999999999999999999.9999999999999999990'')=CONVERT(decimal(38,18),N''99999999999999999999.999999999999999999'') THEN ''EXACT_MAX'' ELSE ''OTHER'' END' },
        @{ Name = 'DECIMAL_MAX_NONZERO_TAIL'; Expected = 'ROUNDED_BACK_TO_MAX'; Sql = 'SELECT CASE WHEN TRY_CONVERT(decimal(38,18),N''99999999999999999999.9999999999999999991'')=CONVERT(decimal(38,18),N''99999999999999999999.999999999999999999'') THEN ''ROUNDED_BACK_TO_MAX'' ELSE ''OTHER'' END' },
        @{ Name = 'DECIMAL_MIN_NONZERO_TAIL'; Expected = 'ROUNDED_BACK_TO_MIN'; Sql = 'SELECT CASE WHEN TRY_CONVERT(decimal(38,18),N''-99999999999999999999.9999999999999999991'')=CONVERT(decimal(38,18),N''-99999999999999999999.999999999999999999'') THEN ''ROUNDED_BACK_TO_MIN'' ELSE ''OTHER'' END' },
        @{ Name = 'DECIMAL_INSIDE_NONZERO_TAIL'; Expected = 'ROUNDED_INSIDE'; Sql = 'SELECT CASE WHEN TRY_CONVERT(decimal(38,18),N''99999999999999999998.9999999999999999991'')=CONVERT(decimal(38,18),N''99999999999999999998.999999999999999999'') THEN ''ROUNDED_INSIDE'' ELSE ''OTHER'' END' },
        @{ Name = 'DECIMAL_MAX_ROUNDUP'; Expected = 'NATIVE_OVERFLOW_NULL'; Sql = 'SELECT CASE WHEN TRY_CONVERT(decimal(38,18),N''99999999999999999999.9999999999999999995'') IS NULL THEN ''NATIVE_OVERFLOW_NULL'' ELSE ''OTHER'' END' },
        @{ Name = 'DECIMAL_INTEGER_OVERFLOW'; Expected = 'NATIVE_OVERFLOW_NULL'; Sql = 'SELECT CASE WHEN TRY_CONVERT(decimal(38,18),N''100000000000000000000'') IS NULL THEN ''NATIVE_OVERFLOW_NULL'' ELSE ''OTHER'' END' }
    ) } else { @(
        @{ Name = 'SCALAR_WRAPPER'; Expected = 'EXPECTED'; Sql = 'SELECT CASE WHEN ISJSON(N''[1]'')=1 AND (SELECT COUNT(*) FROM OPENJSON(N''[1]''))=1 THEN ''EXPECTED'' ELSE ''UNEXPECTED'' END' },
        @{ Name = 'MULTIROOT_WRAPPER'; Expected = 'CARDINALITY_REQUIRED'; Sql = 'SELECT CASE WHEN ISJSON(N''[1,2]'')=1 AND (SELECT COUNT(*) FROM OPENJSON(N''[1,2]''))=2 THEN ''CARDINALITY_REQUIRED'' ELSE ''UNEXPECTED'' END' },
        @{ Name = 'PADDED_KEY_EQUALITY'; Expected = 'LENGTH_REQUIRED'; Sql = 'SELECT CASE WHEN N''a'' COLLATE Latin1_General_100_BIN2=N''a '' COLLATE Latin1_General_100_BIN2 AND DATALENGTH(N''a'')<>DATALENGTH(N''a '') THEN ''LENGTH_REQUIRED'' ELSE ''UNEXPECTED'' END' },
        @{ Name = 'DECODED_DUPLICATE_KEYS'; Expected = 'DUPLICATES_VISIBLE'; Sql = 'SELECT CASE WHEN (SELECT COUNT(*) FROM OPENJSON(N''{"a":1,"\u0061":2}'') WHERE [key] COLLATE Latin1_General_100_BIN2=N''a'' AND DATALENGTH([key])=2)=2 THEN ''DUPLICATES_VISIBLE'' ELSE ''UNEXPECTED'' END' },
        @{ Name = 'LONG_KEY_4000'; Expected = 'FULL_4000'; Sql = 'DECLARE @j nvarchar(max)=N''{"''+REPLICATE(CAST(N''x'' AS nvarchar(max)),4000)+N''":1}''; SELECT CASE WHEN (SELECT MAX(DATALENGTH([key])) FROM OPENJSON(@j))=8000 THEN ''FULL_4000'' ELSE ''UNEXPECTED'' END' },
        @{ Name = 'LONG_KEY_4001'; Expected = 'TRUNCATED_4000'; Sql = 'DECLARE @j nvarchar(max)=N''{"''+REPLICATE(CAST(N''x'' AS nvarchar(max)),4001)+N''":1}''; SELECT CASE (SELECT MAX(DATALENGTH([key])) FROM OPENJSON(@j)) WHEN 8000 THEN ''TRUNCATED_4000'' WHEN 8002 THEN ''FULL_4001'' ELSE ''OTHER'' END' },
        @{ Name = 'UNPAIRED_ESCAPE'; Expected = 'ENGINE_ACCEPTS_SYNTAX'; Sql = 'SELECT CASE WHEN ISJSON(N''["\uD800"]'')=1 THEN ''ENGINE_ACCEPTS_SYNTAX'' ELSE ''ENGINE_REJECTS_SYNTAX'' END' },
        @{ Name = 'DECIMAL_SCALE_LOSS'; Expected = 'ROUNDED_TO_ZERO'; Sql = 'SELECT CASE WHEN TRY_CONVERT(decimal(38,18),N''0.0000000000000000001'')=0 THEN ''ROUNDED_TO_ZERO'' ELSE ''OTHER'' END' },
        @{ Name = 'GUID_SUFFIX'; Expected = 'SUFFIX_ACCEPTED'; Sql = 'SELECT CASE WHEN TRY_CONVERT(uniqueidentifier,N''00000000-0000-0000-0000-000000000001suffix'') IS NOT NULL THEN ''SUFFIX_ACCEPTED'' ELSE ''SUFFIX_REJECTED'' END' },
        @{ Name = 'LONG_KEY_SURROGATE_BOUNDARY'; Expected = 'NO_SHORT_PREFIX_MATCH'; Sql = 'DECLARE @j nvarchar(max)=N''{"''+REPLICATE(CAST(N''x'' AS nvarchar(max)),3999)+N''\uD83D\uDE00":1}''; SELECT CASE WHEN EXISTS (SELECT 1 FROM OPENJSON(@j) WHERE [key] COLLATE Latin1_General_100_BIN2=REPLICATE(CAST(N''x'' AS nvarchar(max)),3999) COLLATE Latin1_General_100_BIN2 AND DATALENGTH([key])=7998) THEN ''FALSE_PREFIX_MATCH'' ELSE ''NO_SHORT_PREFIX_MATCH'' END' },
        @{ Name = 'LONG_KEY_NUL_BOUNDARY'; Expected = 'NO_SHORT_PREFIX_MATCH'; Sql = 'DECLARE @j nvarchar(max)=N''{"''+REPLICATE(CAST(N''x'' AS nvarchar(max)),3999)+N''\u0000z":1}''; SELECT CASE WHEN EXISTS (SELECT 1 FROM OPENJSON(@j) WHERE [key] COLLATE Latin1_General_100_BIN2=REPLICATE(CAST(N''x'' AS nvarchar(max)),3999) COLLATE Latin1_General_100_BIN2 AND DATALENGTH([key])=7998) THEN ''FALSE_PREFIX_MATCH'' ELSE ''NO_SHORT_PREFIX_MATCH'' END' }
    ) }
    foreach ($entry in $targets) {
        $connection = $null
        try {
            $connection = [System.Data.SqlClient.SqlConnection]::new(
                (New-LabConnectionString -Entry $entry))
            $connection.Open()
            # Zusatzprompt: echte Anmeldung und Inventarabfragen; Ergebnisse nicht protokollieren.
            $preflight = $connection.CreateCommand()
            try {
                $preflight.CommandTimeout = 10
                $preflight.CommandText = 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
                $reader = $preflight.ExecuteReader()
                try { do { while ($reader.Read()) {} } while ($reader.NextResult()) }
                finally { $reader.Dispose() }
            } finally { $preflight.Dispose() }
            $check = $connection.CreateCommand()
            try {
                $check.CommandTimeout = 10
                $check.CommandText = 'SELECT CASE WHEN CONVERT(int,SERVERPROPERTY(''ProductMajorVersion''))=15 AND (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())=150 THEN 1 ELSE 0 END'
                $matchesContext = $check.ExecuteScalar()
            } finally { $check.Dispose() }
            if ($matchesContext -ne 1) {
                Write-Output 'CHARACTERIZATION_NOT_EXECUTED_TARGET_CONTEXT'
                Set-CharacterizationExit -Code 2
                continue
            }
            foreach ($probe in $probes) {
                $query = $connection.CreateCommand()
                try {
                    $query.CommandTimeout = 5
                    $query.CommandText = $probe.Sql
                    $answer = [string]$query.ExecuteScalar()
                    if ($answer -cne $probe.Expected) {
                        Write-Output ($probe.Name + ':FAIL')
                        Set-CharacterizationExit -Code 1
                    } else { Write-Output ($probe.Name + ':PASS') }
                } catch {
                    Write-CharacterizationFailure -Label $probe.Name -Exception $_.Exception
                } finally { $query.Dispose() }
            }
        } catch {
            Write-CharacterizationFailure -Label 'CHARACTERIZATION_TARGET' -Exception $_.Exception
        } finally { if ($connection) { $connection.Dispose() } }
    }
} catch {
    Write-CharacterizationFailure -Label 'CHARACTERIZATION_DISCOVERY' -Exception $_.Exception
} finally {
    Remove-Variable resolved, targets, entry, connection -ErrorAction SilentlyContinue
}
exit $runExit

