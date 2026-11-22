#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$CasesPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$document = Get-Content -LiteralPath $CasesPath -Raw -Encoding utf8 | ConvertFrom-Json
$converter = Join-Path $PSScriptRoot 'convert_query.py'
if ((Get-FileHash -LiteralPath $converter -Algorithm SHA256).Hash -ine $document.converter_sha256) {
    throw 'NATIVE_SQL_CONVERTER_BINDING'
}
$port = [int]$env:TBX_DIALECT_SQL_PORT
if ($port -lt 1024 -or $port -gt 65535 -or [string]::IsNullOrEmpty($env:MSSQL_SA_PASSWORD)) {
    throw 'NATIVE_SQL_CONTAINER_CONTEXT'
}
$builder = [Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source'] = "tcp:127.0.0.1,$port"
$builder['Initial Catalog'] = 'master'
$builder['User ID'] = 'sa'
$builder['Password'] = $env:MSSQL_SA_PASSWORD
$builder['Encrypt'] = $true
$builder['TrustServerCertificate'] = $true
$builder['Pooling'] = $false
$builder['ConnectRetryCount'] = 0
$builder['Connect Timeout'] = 5
$connection = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$builder.Clear()
$caseName = 'engine'
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    try {
        $command.CommandTimeout = 12
        $command.CommandText = "SELECT CASE WHEN CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))=17 AND EXISTS (SELECT 1 FROM sys.dm_os_host_info WHERE host_platform='Linux') THEN 1 ELSE 0 END;"
        if ($command.ExecuteScalar() -ne 1) { throw 'NATIVE_SQL_ENGINE' }
        foreach ($case in $document.cases) {
            $caseName = $case.name
            $command.CommandText = [string]$case.tsql
            $reader = $command.ExecuteReader()
            try {
                if ($reader.FieldCount -ne @($case.columns).Count) { throw 'NATIVE_SQL_COLUMN_COUNT' }
                $schema = $reader.GetSchemaTable()
                for ($index=0; $index -lt $reader.FieldCount; $index++) {
                    $name = $reader.GetName($index)
                    $type = $reader.GetDataTypeName($index).ToUpperInvariant()
                    if ($type -ceq 'DECIMAL') {
                        $meta = $schema.Rows[$index]
                        $type = "DECIMAL($($meta.NumericPrecision),$($meta.NumericScale))"
                    }
                    if ($name -cne $case.columns[$index].name -or $type -cne $case.columns[$index].type) {
                        throw 'NATIVE_SQL_SCHEMA'
                    }
                }
                $rows = [Collections.Generic.List[string]]::new()
                while ($reader.Read()) {
                    if ($rows.Count -ge 100) { throw 'NATIVE_SQL_ROW_LIMIT' }
                    $row = [object[]]::new($reader.FieldCount)
                    for ($index=0; $index -lt $reader.FieldCount; $index++) {
                        if ($reader.IsDBNull($index)) { continue }
                        $value = $reader.GetValue($index)
                        $row[$index] = if ($value -is [datetime]) {
                            $value.ToString('yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
                        } elseif ($value -is [IFormattable]) {
                            $value.ToString($null,[Globalization.CultureInfo]::InvariantCulture)
                        } else { throw 'NATIVE_SQL_VALUE_TYPE' }
                    }
                    $rows.Add((ConvertTo-Json -InputObject $row -Compress))
                }
                if ($reader.NextResult()) { throw 'NATIVE_SQL_UNEXPECTED_RESULT' }
                $expected = @(
                    foreach ($row in $case.expected_rows) { ConvertTo-Json -InputObject @($row) -Compress }
                )
                $actual = @($rows.ToArray())
                if (-not $case.ordered) {
                    [Array]::Sort($actual,[StringComparer]::Ordinal)
                    [Array]::Sort($expected,[StringComparer]::Ordinal)
                }
                if (($actual -join "`n") -cne ($expected -join "`n")) { throw 'NATIVE_SQL_VALUES' }
                "NATIVE_SQL_SERVER_CASE_PASS $caseName"
            } finally { $reader.Dispose() }
        }
    } finally { $command.Dispose() }
} catch {
    $errorCode = $_.Exception
    while ($errorCode.InnerException) { $errorCode = $errorCode.InnerException }
    $detail = if ($errorCode -is [Data.SqlClient.SqlException]) {
        "SQL_$($errorCode.Number)"
    } elseif ($errorCode.Message -cmatch '^NATIVE_SQL_[A-Z_]+$') { $errorCode.Message } else {
        $errorCode.GetType().Name
    }
    throw "NATIVE_SQL_SERVER_FAILED $caseName $detail"
} finally { $connection.Dispose() }
"NATIVE_SQL_SERVER_PASS cases=$(@($document.cases).Count)"
