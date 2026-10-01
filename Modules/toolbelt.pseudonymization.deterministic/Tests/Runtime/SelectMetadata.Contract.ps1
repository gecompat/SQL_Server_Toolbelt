[CmdletBinding()]
param([Parameter(Mandatory)][string]$Database)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Credentials ausschließlich im Prozess/Memory, keine Verbindungsausgabe.
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
$connection.add_InfoMessage({param($sender,$event) $messages.Add($event.Message)}.GetNewClosure())
function Assert-Columns {
    param($Reader,[string[]]$Names,[string[]]$Types,[bool[]]$Nullable)
    if ($Reader.FieldCount -ne $Names.Count) { throw 'PROBE_COLUMN_COUNT' }
    $schema = $Reader.GetSchemaTable()
    for ($index=0; $index -lt $Names.Count; $index++) {
        if ($Reader.GetName($index) -cne $Names[$index] -or $Reader.GetDataTypeName($index) -cne $Types[$index] -or
            [bool]$schema.Rows[$index].AllowDBNull -ne $Nullable[$index]) { throw ('PROBE_COLUMN_CONTRACT_' + $index) }
        if ($Types[$index] -eq 'nvarchar' -and $Names[$index] -in @('Value','Description','ExampleSql') -and
            $schema.Rows[$index].ColumnSize -ne [int]::MaxValue) { throw ('PROBE_COLUMN_MAXSIZE_' + $index) }
    }
}
function Invoke-NonQuery([string]$Sql) {
    $probeCommand=$connection.CreateCommand()
    try {$probeCommand.CommandText=$Sql; $probeCommand.CommandTimeout=120; [void]$probeCommand.ExecuteNonQuery()}
    finally {$probeCommand.Dispose()}
}
function Unwrap-SqlException($Failure) {
    while($null -ne $Failure.InnerException) {$Failure=$Failure.InnerException}
    return $Failure
}
$probeStage='CONNECT'
try {
    $connection.Open()
    foreach ($api in @('TVF_DeterministicRange','TVF_DeterministicDateShift')) {
        $probeStage=$api
        $command=$connection.CreateCommand(); $command.CommandTimeout=120
        $arguments=if($api -eq 'TVF_DeterministicRange') {'0x010203,1,DEFAULT,-10,10'} else {"CONVERT(datetime2(7),'2026-01-02T03:04:05.1234567'),0x010203,1,DEFAULT,DEFAULT"}
        $command.CommandText="SELECT Value,ErrorCode FROM toolbelt_pseudonymization.$api($arguments);"
        $reader=$command.ExecuteReader()
        try {
            $type=if($api -eq 'TVF_DeterministicRange') {'bigint'} else {'datetime2'}
            Assert-Columns $reader @('Value','ErrorCode') @($type,'int') @($true,$false)
            if(-not $reader.Read() -or $reader.IsDBNull(0) -or $reader.GetInt32(1) -ne 0 -or $reader.Read() -or $reader.NextResult()) { throw 'TVF: genau eine Erfolgszeile erforderlich.' }
        } finally {$reader.Dispose();$command.Dispose()}
    }
    foreach ($mode in @('nonnull','null','empty')) {
        $probeStage='LOOKUP_' + $mode
        $command=$connection.CreateCommand(); $command.CommandTimeout=120
        $command.CommandText="CREATE TABLE #MetadataInput(Ordinal bigint,[Key] varbinary(max)); CREATE TABLE #MetadataPool(Ordinal bigint,[Value] nvarchar(max)); INSERT #MetadataPool VALUES(20,N'synthetic');"
        if($mode -ne 'empty') {$command.CommandText += if($mode -eq 'null') {'INSERT #MetadataInput VALUES(10,NULL);'} else {'INSERT #MetadataInput VALUES(10,0x01);'}}
        $command.CommandText+="EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#MetadataInput',@LookupTable=N'#MetadataPool',@MappingVersion=1,@LookupVersion=1,@Debug=2; DROP TABLE #MetadataInput; DROP TABLE #MetadataPool;"
        $reader=$command.ExecuteReader()
        try {
            Assert-Columns $reader @('InputOrdinal','LookupOrdinal','Value') @('bigint','bigint','nvarchar') @($false,$true,$true)
            $count=0
            while($reader.Read()) {
                $count++
                if($reader.GetInt64(0) -ne 10) {throw 'Lookup: Eingabeordinal verletzt.'}
                if($mode -eq 'null') {if(-not $reader.IsDBNull(1) -or -not $reader.IsDBNull(2)) {throw 'Lookup: NULL-Key verletzt.'}}
                elseif($reader.IsDBNull(1) -or $reader.IsDBNull(2) -or $reader.GetInt64(1) -ne 20 -or $reader.GetString(2) -cne 'synthetic') {throw 'Lookup: synthetische Poolzeile verletzt.'}
            }
            $expected=if($mode -eq 'empty'){0}else{1}
            if($count -ne $expected -or $reader.NextResult()) {throw 'Lookup: Zeilen-/Resultsetanzahl verletzt.'}
        } finally {$reader.Dispose();$command.Dispose()}
    }
    $messages.Clear()
    $probeStage='HELP'
    $command=$connection.CreateCommand()
    $command.CommandText="EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1,@InputTable=N'##missing',@LookupTable=N'invalid',@MappingVersion=0,@LookupVersion=0,@MaxInputRows=0,@ResultTable=N'invalid',@Debug=255;"
    $reader=$command.ExecuteReader()
    try {
        Assert-Columns $reader @('HelpContractVersion','SchemaName','ObjectName','Section','Ordinal','ItemName','SqlDataType','IsRequired','IsNullable','DefaultValue','Description','ExampleSql') @('varchar','nvarchar','nvarchar','varchar','int','nvarchar','varchar','bit','bit','nvarchar','nvarchar','nvarchar') @($false,$false,$false,$false,$false,$true,$true,$true,$true,$true,$false,$true)
        $defaults=@('NULL','NULL','NULL','0','NULL','10000','10000','2097152','16777216','NULL','0','0','0')
        $parameters=[System.Collections.Generic.HashSet[int]]::new(); $results=[System.Collections.Generic.HashSet[int]]::new()
        while($reader.Read()) {
            if($reader.GetString(3) -ceq 'PARAMETER') {
                $ordinal=$reader.GetInt32(4)
                if($ordinal -lt 1 -or $ordinal -gt 13 -or -not $parameters.Add($ordinal) -or $reader.IsDBNull(9) -or $reader.GetString(9) -cne $defaults[$ordinal-1]) {throw 'Help: Parameter/Defaults verletzt.'}
            }
            elseif($reader.GetString(3) -ceq 'RESULT_COLUMN') {
                $ordinal=$reader.GetInt32(4)
                if($ordinal -lt 1 -or $ordinal -gt 3 -or -not $results.Add($ordinal)) {throw 'Help: Resultspaltenordinal verletzt.'}
            }
        }
        if($parameters.Count -ne 13 -or $results.Count -ne 3 -or $reader.NextResult() -or $messages.Count -ne 0) {throw 'Help: Inventar oder zusätzliche Ausgabe verletzt.'}
    } finally {$reader.Dispose();$command.Dispose()}
    $probeStage='RESULTTABLE'
    $command=$connection.CreateCommand(); $command.CommandTimeout=120
    $command.CommandText="CREATE TABLE #MetadataInput(Ordinal bigint,[Key] varbinary(max)); CREATE TABLE #MetadataPool(Ordinal bigint,[Value] nvarchar(max)); INSERT #MetadataPool VALUES(20,N'synthetic'); CREATE TABLE #MetadataOutput(Dummy int); EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#MetadataInput',@LookupTable=N'#MetadataPool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#MetadataOutput'; DROP TABLE #MetadataInput; DROP TABLE #MetadataPool; DROP TABLE #MetadataOutput;"
    $reader=$command.ExecuteReader()
    try {if($reader.FieldCount -ne 0 -or $reader.NextResult()) {throw 'ResultTable: kein fachliches SELECT erlaubt.'}}
    finally {$reader.Dispose();$command.Dispose()}
    $probeStage='PRIVATE_TEMP_ECLIPSE'
    Invoke-NonQuery "CREATE TABLE #MetadataInput(Ordinal bigint,[Key] varbinary(max)); CREATE TABLE #MetadataPool(Ordinal bigint,[Value] nvarchar(max)); CREATE TABLE #MetadataOutput(Dummy int); INSERT #MetadataInput VALUES(10,0x01); INSERT #MetadataPool VALUES(20,N'synthetic'); INSERT #MetadataOutput VALUES(71);"
    foreach($privateName in @('#tbx_DeterministicLookup_Input','#tbx_DeterministicLookup_Pool','#tbx_DeterministicLookup_Map','#tbx_DeterministicLookup_ResultSource')) {
        Invoke-NonQuery ('CREATE TABLE [' + $privateName + '] (WrongShape int);')
        $messages.Clear()
        $command=$connection.CreateCommand();$command.CommandText='EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1,@Debug=255;'
        $reader=$command.ExecuteReader()
        try {if($reader.FieldCount -ne 12){throw 'ECLIPSE_HELP_FAILED'};while($reader.Read()){};if($reader.NextResult() -or $messages.Count){throw 'ECLIPSE_HELP_FAILED'}}
        finally {$reader.Dispose();$command.Dispose()}
        $caught=$false
        try {Invoke-NonQuery "EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#MetadataInput',@LookupTable=N'#MetadataPool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#MetadataOutput';"}
        catch {$errorDetail=Unwrap-SqlException $_.Exception; if($errorDetail -isnot [System.Data.SqlClient.SqlException] -or $errorDetail.Number -ne 54009 -or $errorDetail.State -ne 1){throw 'ECLIPSE_GUARD_FAILED'};$caught=$true}
        if(-not $caught){throw 'ECLIPSE_GUARD_FAILED'}
        $command=$connection.CreateCommand();$command.CommandText='SELECT COUNT_BIG(*),MIN(Dummy),@@TRANCOUNT FROM #MetadataOutput;';$reader=$command.ExecuteReader()
        try {if(-not $reader.Read() -or $reader.GetInt64(0) -ne 1 -or $reader.GetInt32(1) -ne 71 -or $reader.GetInt32(2) -ne 0){throw 'ECLIPSE_ATOMICITY_FAILED'}}
        finally {$reader.Dispose();$command.Dispose()}
        Invoke-NonQuery ('DROP TABLE [' + $privateName + '];')
    }
    Invoke-NonQuery 'DROP TABLE #MetadataInput;DROP TABLE #MetadataPool;DROP TABLE #MetadataOutput;'
    $probeStage='LIFECYCLE_CALLER_GUARD'
    foreach($installer in @('Deploy.sql','Uninstall.sql')) {
        $installerPath=Join-Path $PSScriptRoot ('../../Deployment/' + $installer)
        # Tatsächlichen frühesten Installerbatch verwenden, keine Guardkopie.
        $guard=([IO.File]::ReadAllText($installerPath) -split ':r ReleaseManifest.sql',2)[0] -replace '(?m)^:On Error exit\r?\n',''
        foreach($abort in @('ON','OFF')) {
            Invoke-NonQuery ('SET XACT_ABORT ' + $abort + '; CREATE TABLE #CallerMarker(Value int);INSERT #CallerMarker VALUES(11);BEGIN TRANSACTION;INSERT #CallerMarker VALUES(22);')
            $command=$connection.CreateCommand();$command.CommandText='SELECT @@OPTIONS;';$options=[int]$command.ExecuteScalar();$command.Dispose()
            $caught=$false
            try {Invoke-NonQuery $guard}
            catch {$errorDetail=Unwrap-SqlException $_.Exception; if($errorDetail -isnot [System.Data.SqlClient.SqlException] -or $errorDetail.Number -ne 50000 -or $errorDetail.State -ne 1 -or -not $errorDetail.Message.StartsWith('DETERMINISTIC_LIFECYCLE_CALLER_TRANSACTION:')){throw 'CALLER_GUARD_SIGNATURE_FAILED'};$caught=$true}
            if(-not $caught){throw 'CALLER_GUARD_SIGNATURE_FAILED'}
            $command=$connection.CreateCommand();$command.CommandText='SELECT @@TRANCOUNT,CONVERT(int,XACT_STATE()),@@OPTIONS,(SELECT COUNT_BIG(*) FROM #CallerMarker),(SELECT SUM(Value) FROM #CallerMarker);';$reader=$command.ExecuteReader()
            try {if(-not $reader.Read() -or $reader.GetInt32(0) -ne 1 -or $reader.GetInt32(1) -ne 1 -or $reader.GetInt32(2) -ne $options -or $reader.GetInt64(3) -ne 2 -or $reader.GetInt32(4) -ne 33){throw 'CALLER_GUARD_STATE_FAILED'}}
            finally {$reader.Dispose();$command.Dispose()}
            Invoke-NonQuery 'ROLLBACK TRANSACTION;DROP TABLE #CallerMarker;'
        }
    }
    Write-Output 'PASS: Deterministic client SELECT/Help/ResultTable metadata'
} catch {
    # Aufrufwrapper können SqlException verschachteln. Weder äußere Meldung
    # noch Verbindungsdiagnostik ausgeben; nur konstante Probe-/Fehlerklassen.
    $failure=$_.Exception
    while($null -ne $failure.InnerException) {$failure=$failure.InnerException}
    if ($failure -is [System.Data.SqlClient.SqlException]) {throw ('SQL_CLIENT_OR_SERVER_' + $failure.Number)}
    if($failure.Message -cmatch '^PROBE_COLUMN_(COUNT|CONTRACT_[0-9]+|MAXSIZE_[0-9]+)$') {throw ('METADATA_PROBE_FAILED_' + $failure.Message + '_' + $probeStage)}
    if($failure.Message -cmatch '^(ECLIPSE_(HELP|GUARD|ATOMICITY)_FAILED|CALLER_GUARD_(SIGNATURE|STATE)_FAILED)$'){throw ('METADATA_PROBE_FAILED_' + $failure.Message)}
    throw ('METADATA_PROBE_FAILED_' + $failure.GetType().Name + '_' + $probeStage)
} finally {$connection.Dispose()}
