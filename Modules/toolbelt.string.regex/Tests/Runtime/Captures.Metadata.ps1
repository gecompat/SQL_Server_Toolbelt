[CmdletBinding()]
param(
    [Data.SqlClient.SqlConnection]$Connection,
    [string]$Database,
    [string]$ToolbeltDatabase,
    [string]$ConnectionStringEnvironmentVariable,
    [switch]$IncludeLargeBoundary
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ownsConnection = $false
$builder = $null
$messages = [Collections.Generic.List[string]]::new()
$handler = { param($sender, $eventArgs) $messages.Add('message') }

function Assert-CaptureColumns {
    param([Data.SqlClient.SqlDataReader]$Reader)
    $schema = $Reader.GetSchemaTable()
    $names = @('MatchOrdinal','GroupOrdinal','CaptureOrdinal','GroupName','Matched','StartPosition','Length','Value')
    $types = @('bigint','int','bigint','nvarchar','bit','bigint','bigint','nvarchar')
    $sizes = @(8,4,8,128,1,8,8,[int]::MaxValue)
    if ($Reader.FieldCount -ne 8 -or $schema.Rows.Count -ne 8) { throw 'CAPTURE_COLUMN_COUNT_INVALID' }
    for ($i=0; $i -lt 8; $i++) {
        if ($Reader.GetName($i) -cne $names[$i] -or $Reader.GetDataTypeName($i) -cne $types[$i] -or
            [int]$schema.Rows[$i].ColumnSize -ne $sizes[$i] -or -not [bool]$schema.Rows[$i].AllowDBNull) {
            throw 'CAPTURE_COLUMN_METADATA_INVALID'
        }
    }
}

function Assert-CaptureFailure {
    param([string]$Sql, [string]$Prefix)
    $command = $Connection.CreateCommand()
    $command.CommandText = $Sql
    $command.CommandTimeout = 120
    $reader = $null
    $seen = 0
    $caught = $false
    try {
        $reader = $command.ExecuteReader()
        do { while ($reader.Read()) { $seen++ } } while ($reader.NextResult())
    } catch {
        $failure = $_.Exception
        while ($null -ne $failure -and $failure -isnot [Data.SqlClient.SqlException]) { $failure = $failure.InnerException }
        if ($null -eq $failure -or $failure.Number -ne 6522 -or -not $failure.Message.Contains($Prefix)) {
            throw 'CAPTURE_CLIENT_ERROR_SIGNATURE_INVALID'
        }
        $caught = $true
    } finally {
        if ($reader) { $reader.Dispose() }
        $command.Dispose()
    }
    if (-not $caught -or $seen -ne 0 -or $messages.Count -ne 0) { throw 'CAPTURE_CLIENT_ATOMICITY_INVALID' }
}

try {
    if ($null -eq $Connection) {
        $builder = [Data.SqlClient.SqlConnectionStringBuilder]::new()
        if ($ConnectionStringEnvironmentVariable) {
            $privateValue = [Environment]::GetEnvironmentVariable($ConnectionStringEnvironmentVariable,'Process')
            if ([string]::IsNullOrWhiteSpace($privateValue)) { throw 'CAPTURE_CONNECTION_CONFIGURATION_MISSING' }
            $builder.ConnectionString = $privateValue
            $privateValue = $null
        } else {
            foreach ($name in @('TBX_SQL_HOST','TBX_SQL_PORT','TBX_SQL_USER','TBX_SQL_PASSWORD')) {
                if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name,'Process'))) {
                    throw 'CAPTURE_CONNECTION_CONFIGURATION_MISSING'
                }
            }
            $builder['Data Source'] = 'tcp:{0},{1}' -f $env:TBX_SQL_HOST,$env:TBX_SQL_PORT
            $builder['User ID'] = $env:TBX_SQL_USER
            $builder['Password'] = $env:TBX_SQL_PASSWORD
        }
        if ([string]::IsNullOrWhiteSpace($Database)) { throw 'CAPTURE_DATABASE_ARGUMENT_REQUIRED' }
        $builder['Initial Catalog'] = $Database
        $builder['Encrypt'] = $true
        $builder['TrustServerCertificate'] = $true
        $builder['Connect Timeout'] = 15
        $builder['Pooling'] = $false
        $Connection = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
        $ownsConnection = $true
        $Connection.Open()
    }
    if ($Connection.State -ne 'Open') { throw 'CAPTURE_OPEN_CONNECTION_REQUIRED' }
    if ([string]::IsNullOrWhiteSpace($ToolbeltDatabase)) { $ToolbeltDatabase = $Connection.Database }
    $quotedDatabase = '[' + $ToolbeltDatabase.Replace(']',']]') + ']'
    $qualified = $quotedDatabase + '.toolbelt_string.'
    $Connection.add_InfoMessage($handler)

    foreach ($case in @(
        @{ Call="TVF_RegexCaptures(N'b',N'(a)?(b)',DEFAULT,DEFAULT,DEFAULT,DEFAULT)"; Kind='sentinel'; Rows=2 },
        @{ Call="TVF_RegexCaptures(N'',N'(a?)',DEFAULT,DEFAULT,DEFAULT,DEFAULT)"; Kind='empty'; Rows=1 },
        @{ Call="TVF_RegexCaptures(NULL,N'[',NULL,NULL,NULL,NULL)"; Kind='null'; Rows=0 }
    )) {
        $command = $Connection.CreateCommand()
        $command.CommandTimeout = 120
        $command.CommandText = 'SELECT * FROM ' + $qualified + $case.Call + ' ORDER BY MatchOrdinal,GroupOrdinal,CaptureOrdinal;'
        $reader = $null
        try {
            $reader = $command.ExecuteReader()
            Assert-CaptureColumns $reader
            $count = 0
            while ($reader.Read()) {
                $count++
                if ($reader.IsDBNull(0) -or $reader.IsDBNull(1) -or $reader.IsDBNull(2) -or
                    $reader.IsDBNull(3) -or $reader.IsDBNull(4)) { throw 'CAPTURE_IDENTITY_NULL_INVALID' }
                if ($case.Kind -eq 'sentinel' -and $reader.GetInt32(1) -eq 1) {
                    if ($reader.GetInt64(2) -ne 0 -or $reader.GetBoolean(4) -or
                        -not $reader.IsDBNull(5) -or -not $reader.IsDBNull(6) -or -not $reader.IsDBNull(7)) {
                        throw 'CAPTURE_SENTINEL_CLIENT_INVALID'
                    }
                } else {
                    if (-not $reader.GetBoolean(4) -or $reader.IsDBNull(5) -or $reader.IsDBNull(6) -or $reader.IsDBNull(7)) {
                        throw 'CAPTURE_ACTUAL_CLIENT_INVALID'
                    }
                    if ($case.Kind -eq 'empty' -and ($reader.GetInt64(2) -ne 1 -or $reader.GetInt64(5) -ne 1 -or
                        $reader.GetInt64(6) -ne 0 -or $reader.GetString(7).Length -ne 0)) { throw 'CAPTURE_EMPTY_CLIENT_INVALID' }
                }
            }
            if ($count -ne $case.Rows -or $reader.NextResult()) { throw 'CAPTURE_RESULT_COUNT_INVALID' }
        } finally {
            if ($reader) { $reader.Dispose() }
            $command.Dispose()
        }
    }

    # Katalogtypen und Reihenfolge; T-SQL-Defaults werden durch echte Aufrufe geprüft.
    foreach ($function in @(
        @{Name='TVF_RegexCaptures'; Parameters=@('@Input','@Pattern','@Start','@Flags','@Profile','@MaxRows'); Types=@('nvarchar','nvarchar','int','nvarchar','nvarchar','int')},
        @{Name='SVF_RegexReplaceGroups'; Parameters=@('@Input','@Pattern','@Replacement','@Start','@Occurrence','@Flags','@Profile'); Types=@('nvarchar','nvarchar','nvarchar','int','int','nvarchar','nvarchar')}
    )) {
        $command = $Connection.CreateCommand()
        $command.CommandText = 'SELECT p.name,t.name,p.max_length FROM ' + $quotedDatabase +
            '.sys.parameters p JOIN ' + $quotedDatabase + '.sys.objects o ON o.object_id=p.object_id JOIN ' +
            $quotedDatabase + '.sys.schemas s ON s.schema_id=o.schema_id JOIN ' + $quotedDatabase +
            ".sys.types t ON t.user_type_id=p.user_type_id WHERE s.name=N'toolbelt_string' AND o.name=@Name AND p.parameter_id>0 ORDER BY p.parameter_id;"
        [void]$command.Parameters.Add('@Name',[Data.SqlDbType]::NVarChar,128)
        $command.Parameters['@Name'].Value = $function.Name
        $reader = $null
        try {
            $reader = $command.ExecuteReader()
            $index = 0
            while ($reader.Read()) {
                if ($index -ge $function.Parameters.Count -or $reader.GetString(0) -cne $function.Parameters[$index] -or
                    $reader.GetString(1) -cne $function.Types[$index] -or
                    $reader.GetInt16(2) -ne $(if ($function.Types[$index] -eq 'nvarchar') {-1} else {4})) {
                    throw 'CAPTURE_PARAMETER_METADATA_INVALID'
                }
                $index++
            }
            if ($index -ne $function.Parameters.Count) { throw 'CAPTURE_PARAMETER_COUNT_INVALID' }
        } finally {
            if ($reader) { $reader.Dispose() }
            $command.Dispose()
        }
    }
    $command = $Connection.CreateCommand()
    $command.CommandText = 'SELECT ' + $qualified + 'SVF_RegexReplaceGroups(N''aa'',N''(a)'',N''[$1]'',DEFAULT,DEFAULT,DEFAULT,DEFAULT);'
    try {
        if ([string]$command.ExecuteScalar() -cne '[a][a]') { throw 'CAPTURE_SCALAR_DEFAULTS_INVALID' }
    } finally { $command.Dispose() }

    Assert-CaptureFailure ('SELECT * FROM ' + $qualified + "TVF_RegexCaptures(N'aa',N'(a)',1,N'c',N'standard',1);") 'TBX_REGEX_TOO_MANY_ROWS'
    Assert-CaptureFailure ('SELECT * FROM ' + $qualified + "TVF_RegexCaptures(N'b',N'(a)?(b)',1,N'c',N'standard',1);") 'TBX_REGEX_TOO_MANY_ROWS'
    Assert-CaptureFailure ('SELECT * FROM ' + $qualified + "TVF_RegexCaptures(N'x',N'(a?)*',1,N'c',N'standard',100);") 'TBX_REGEX_CAPTURE_HISTORY_LIMIT'
    Assert-CaptureFailure ('SELECT ' + $qualified + 'SVF_RegexReplaceGroups(N''x'',N''(z)'',N''$10'',3,0,N''c'',N''standard'');') 'TBX_REGEX_INVALID_REPLACEMENT'
    Assert-CaptureFailure ('SELECT * FROM ' + $qualified + "TVF_RegexCaptures(REPLICATE(CONVERT(nvarchar(max),N'a'),20000)+N'!',N'^(a|aa)+$',1,N'c',N'standard',10000);") 'TBX_REGEX_TIMEOUT'

    # Genau eine Capture: die Grenze entsteht durch GroupName plus Value,
    # nicht durch Zeilenexplosion oder Capture-History. Große Proben sind opt-in.
    $longName = 'N' + ('a' * 127)
    $profiles = @(@{Name='standard';Units=1048576})
    if ($IncludeLargeBoundary) { $profiles += @{Name='large';Units=8388608} }
    foreach ($profileCase in $profiles) {
        $command = $Connection.CreateCommand()
        $command.CommandTimeout = 120
        $command.CommandText = 'SELECT * FROM ' + $qualified +
            "TVF_RegexCaptures(REPLICATE(CONVERT(nvarchar(max),N'a'),@Units),@Pattern,1,N'c',@Profile,1);"
        [void]$command.Parameters.Add('@Units',[Data.SqlDbType]::Int)
        [void]$command.Parameters.Add('@Pattern',[Data.SqlDbType]::NVarChar,-1)
        [void]$command.Parameters.Add('@Profile',[Data.SqlDbType]::NVarChar,16)
        $command.Parameters['@Units'].Value = $profileCase.Units - 128
        $command.Parameters['@Pattern'].Value = '^(?<' + $longName + '>a*)$'
        $command.Parameters['@Profile'].Value = $profileCase.Name
        $reader = $null
        try {
            $reader = $command.ExecuteReader()
            if (-not $reader.Read() -or $reader.GetString(3) -cne $longName -or $reader.GetString(7).Length -ne $profileCase.Units-128 -or
                $reader.GetInt64(6) -ne $profileCase.Units-128 -or $reader.Read() -or $reader.NextResult()) {
                throw 'CAPTURE_NAME_CHARGE_BOUNDARY_INVALID'
            }
        } finally {
            if ($reader) { $reader.Dispose() }
            $command.Dispose()
        }
        $units = $profileCase.Units - 127
        Assert-CaptureFailure ('SELECT * FROM ' + $qualified +
            "TVF_RegexCaptures(REPLICATE(CONVERT(nvarchar(max),N'a'),$units),N'^(?<$longName>a*)$',1,N'c',N'$($profileCase.Name)',1);") 'TBX_REGEX_OUTPUT_TOO_LARGE'
    }
    if ($messages.Count) { throw 'CAPTURE_UNEXPECTED_INFO_MESSAGE' }
    'Regex Capture SQLClient metadata, defaults and atomic errors PASS.'
} catch {
    throw 'Regex Capture SQLClient-Vertrag fehlgeschlagen; private Verbindung und Runtime-Ausgabe unterdrückt.'
} finally {
    if ($Connection) { $Connection.remove_InfoMessage($handler) }
    if ($ownsConnection -and $Connection) { $Connection.Dispose() }
    if ($builder) { $builder.Clear() }
}
