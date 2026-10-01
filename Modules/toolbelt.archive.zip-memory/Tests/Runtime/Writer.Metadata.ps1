[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Database,
    [string]$ToolbeltDatabase = $Database
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Eigene Sitzung und ausschließlich synthetische Caller-Temps. Zugangsdaten
# stammen nur aus Prozessvariablen; keine Connectionstrings/Infraausgabe.
foreach ($key in @('TBX_SQL_HOST', 'TBX_SQL_PORT', 'TBX_SQL_USER', 'TBX_SQL_PASSWORD')) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($key, 'Process'))) {
        throw 'ZIP Writer metadata: Prozesskonfiguration fehlt.'
    }
}
$builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source'] = "tcp:$($env:TBX_SQL_HOST),$($env:TBX_SQL_PORT)"
$builder['Initial Catalog'] = $Database
$builder['User ID'] = $env:TBX_SQL_USER
$builder['Password'] = $env:TBX_SQL_PASSWORD
$builder['Encrypt'] = $true
$builder['TrustServerCertificate'] = $true
$builder['Connect Timeout'] = 15
$connection = [System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$messages = [System.Collections.Generic.List[string]]::new()
# Inhalte nicht sammeln: Nur das Vorhandensein einer Message interessiert.
$connection.add_InfoMessage({ param($sender, $event) $messages.Add('message') }.GetNewClosure())
$procedure = '[' + $ToolbeltDatabase.Replace(']', ']]') + '].toolbelt_archive.USP_CreateZipFromEntries'

function Invoke-Fixture([string]$Sql) {
    $command = $connection.CreateCommand()
    try {
        $command.CommandText = $Sql
        $command.CommandTimeout = 120
        [void]$command.ExecuteNonQuery()
    } finally { $command.Dispose() }
}

function Assert-Shape($Reader, [object[]]$Expected) {
    $schema = $Reader.GetSchemaTable()
    if ($Reader.FieldCount -ne $Expected.Count -or $null -eq $schema -or
        $schema.Rows.Count -ne $Expected.Count) { throw 'Resultset-Spaltenzahl falsch.' }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        $column = $Expected[$index]
        $row = $schema.Rows[$index]
        if ($Reader.GetName($index) -cne $column[0] -or
            $Reader.GetDataTypeName($index) -cne $column[1] -or
            [int]$row.ColumnSize -ne $column[2] -or
            [bool]$row.AllowDBNull -ne $column[3]) { throw 'Resultset-Typ/Max/Nullability falsch.' }
    }
}

$successShape = @(
    @('ArchivePayload', 'varbinary', [int]::MaxValue, $false),
    @('ArchiveBytes', 'bigint', 8, $false),
    @('EntryCount', 'int', 4, $false),
    @('TotalPayloadBytes', 'bigint', 8, $false),
    @('CompressionMethod', 'int', 4, $false)
)
# SqlClient meldet MAX mit Int32.MaxValue, auch für Unicode; feste
# nvarchar-Spalten werden dagegen in Zeichen statt Bytes angegeben.
$helpShape = @(
    @('HelpContractVersion', 'varchar', 16, $false),
    @('SchemaName', 'nvarchar', 128, $false),
    @('ObjectName', 'nvarchar', 128, $false),
    @('Section', 'varchar', 32, $false),
    @('Ordinal', 'int', 4, $false),
    @('ItemName', 'nvarchar', 128, $true),
    @('SqlDataType', 'varchar', 256, $true),
    @('IsRequired', 'bit', 1, $true),
    @('IsNullable', 'bit', 1, $true),
    @('DefaultValue', 'nvarchar', 4000, $true),
    @('Description', 'nvarchar', [int]::MaxValue, $false),
    @('ExampleSql', 'nvarchar', [int]::MaxValue, $true)
)
try {
    $connection.Open()
    Invoke-Fixture 'SET NOCOUNT ON; CREATE TABLE #WriterMetadataInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); CREATE TABLE #WriterMetadataOutput(Dummy uniqueidentifier NULL); CREATE TABLE #WriterMetadataHelpTarget(Dummy int); INSERT #WriterMetadataHelpTarget VALUES(17);'
    foreach ($empty in @($false, $true)) {
        Invoke-Fixture 'DELETE #WriterMetadataInput;'
        if (-not $empty) { Invoke-Fixture "INSERT #WriterMetadataInput VALUES(7,N'synthetic.txt',0x4869);" }
        foreach ($method in @('Stored', 'Deflate')) {
            $command = $connection.CreateCommand()
            $command.CommandText = "EXEC $procedure @EntryTable=N'#WriterMetadataInput', @CompressionMethod='$method';"
            $command.CommandTimeout = 120
            $reader = $command.ExecuteReader()
            try {
                Assert-Shape $reader $successShape
                if (-not $reader.Read()) { throw 'Erfolgszeile fehlt.' }
                for ($index = 0; $index -lt 5; $index++) {
                    if ($reader.IsDBNull($index)) { throw 'Erfolgswert ist NULL.' }
                }
                $expectedCount = if ($empty) { 0 } else { 1 }
                $expectedTotal = if ($empty) { 0L } else { 2L }
                $expectedMethod = if ($method -eq 'Stored') { 0 } else { 8 }
                if ($reader.GetInt64(1) -ne $reader.GetBytes(0, 0, $null, 0, 0) -or
                    $reader.GetInt32(2) -ne $expectedCount -or
                    $reader.GetInt64(3) -ne $expectedTotal -or
                    $reader.GetInt32(4) -ne $expectedMethod -or
                    ($empty -and $reader.GetInt64(1) -ne 22) -or
                    $reader.Read() -or $reader.NextResult()) { throw 'Erfolgszeilen/Resultsets/Werte falsch.' }
            } finally { $reader.Dispose(); $command.Dispose() }
        }
    }

    $messages.Clear()
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 120
    $command.CommandText = "EXEC $procedure @Hilfe=1, @Debug=255, @EntryTable=N'#MissingWriterMetadataInput', @CompressionMethod='invalid', @MaxEntries=0, @ResultTable=N'#WriterMetadataHelpTarget', @KeepData=0;"
    $reader = $command.ExecuteReader()
    try {
        Assert-Shape $reader $helpShape
        $parameters = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        $results = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        $parameterCount = 0; $resultCount = 0
        $description = $false; $example = $false
        while ($reader.Read()) {
            if ($reader.GetString(0) -cne '1.0' -or $reader.GetString(1) -cne 'toolbelt_archive' -or
                $reader.GetString(2) -cne 'USP_CreateZipFromEntries') { throw 'Help-Identität falsch.' }
            switch ($reader.GetString(3)) {
                'PARAMETER' { $parameterCount++; [void]$parameters.Add($reader.GetString(5)) }
                'RESULT_COLUMN' { $resultCount++; [void]$results.Add($reader.GetString(5)) }
                'DESCRIPTION' { $description = $true }
                'EXAMPLE' { $example = $true }
            }
        }
        $expectedParameters = @('@EntryTable', '@CompressionMethod', '@MaxEntries', '@MaxEntryNameCodeUnits', '@MaxEntryBytes', '@MaxTotalPayloadBytes', '@MaxArchiveBytes', '@MaxEnvelopeBytes', '@WriterBudgetMilliseconds', '@ResultTable', '@KeepData', '@Debug', '@Hilfe')
        if ($parameterCount -ne 13 -or $resultCount -ne 5 -or
            -not $parameters.SetEquals([string[]]$expectedParameters) -or
            -not $results.SetEquals([string[]]($successShape | ForEach-Object { $_[0] })) -or
            -not $description -or -not $example -or $reader.NextResult() -or $messages.Count -ne 0) {
            throw 'Help-Sections/Messages/Resultsets falsch.'
        }
    } finally { $reader.Dispose(); $command.Dispose() }
    Invoke-Fixture "IF (SELECT COUNT(*) FROM #WriterMetadataHelpTarget)<>1 OR NOT EXISTS(SELECT 1 FROM #WriterMetadataHelpTarget WHERE Dummy=17) THROW 51389,N'Help veränderte synthetisches Ziel.',1; INSERT #WriterMetadataInput VALUES(7,N'synthetic.txt',0x4869);"

    $command = $connection.CreateCommand()
    $command.CommandTimeout = 120
    $command.CommandText = "EXEC $procedure @EntryTable=N'#WriterMetadataInput', @ResultTable=N'#WriterMetadataOutput', @Debug=2;"
    $reader = $command.ExecuteReader()
    try {
        if ($reader.FieldCount -ne 0 -or $reader.NextResult()) { throw 'ResultTable erzeugte fachliches SELECT.' }
    } finally { $reader.Dispose(); $command.Dispose() }
    Invoke-Fixture "IF (SELECT COUNT(*) FROM #WriterMetadataOutput)<>1 THROW 51389,N'ResultTable-Zeile fehlt.',1;"
    Write-Output 'ZIP Writer client SELECT/Help/ResultTable metadata contracts: success'
} catch {
    # Keine Original-SQL-/Connectionexception, Endpoint- oder Laufzeitwerte ausgeben.
    throw 'ZIP Writer client metadata contracts: failed (redacted).'
} finally {
    $connection.Dispose()
    $builder.Clear()
}
