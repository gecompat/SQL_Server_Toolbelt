[CmdletBinding()]
param([Parameter(Mandatory)][string]$Database)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Ausschließlich prozessgebundene Zugangsdaten; keine Server-/Connectionstringausgabe.
$builder=[System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source']="tcp:$($env:TBX_SQL_HOST),$($env:TBX_SQL_PORT)"
$builder['Initial Catalog']=$Database
$builder['User ID']=$env:TBX_SQL_USER
$builder['Password']=$env:TBX_SQL_PASSWORD
$builder['Encrypt']=$true
$builder['TrustServerCertificate']=$true
$builder['Connect Timeout']=15
$connection=[System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$messages=[System.Collections.Generic.List[string]]::new()
$connection.add_InfoMessage({param($sender,$event) $messages.Add($event.Message)}.GetNewClosure())
try {
    $connection.Open()
    foreach($sql in @(
        "EXEC toolbelt_string.USP_SplitAdvanced @Input=NULL;",
        "EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[`";`"]',@Debug=2;")) {
        $command=$connection.CreateCommand(); $command.CommandText=$sql; $command.CommandTimeout=120
        $reader=$command.ExecuteReader()
        try {
            $schema=$reader.GetSchemaTable()
            if($reader.FieldCount -ne 2 -or $schema.Rows[0].ColumnName -ne 'Value' -or
               $schema.Rows[1].ColumnName -ne 'Ordinal' -or
               $reader.GetDataTypeName(0) -ne 'nvarchar' -or $reader.GetDataTypeName(1) -ne 'bigint' -or
               $schema.Rows[0].AllowDBNull -or $schema.Rows[1].AllowDBNull) {
                throw 'USP SELECT-Metadatenvertrag falsch.'
            }
            $rowCount=0; while($reader.Read()){ $rowCount++ }
            if(($sql -like '*@Input=NULL*' -and $rowCount -ne 0) -or
               ($sql -notlike '*@Input=NULL*' -and $rowCount -ne 2) -or $reader.NextResult()) {
                throw 'USP SELECT-Zeilen-/Resultsetvertrag falsch.'
            }
        } finally { $reader.Dispose();$command.Dispose() }
    }
    $messages.Clear()
    $command=$connection.CreateCommand()
    $command.CommandText="EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1,@Debug=255,@SeparatorsJson=N'invalid',@ResultTable=N'invalid';"
    $reader=$command.ExecuteReader()
    try {
        if($reader.FieldCount -ne 12){ throw 'Help-Schema falsch.' }
        while($reader.Read()){}
        if($reader.NextResult() -or $messages.Count -ne 0){ throw 'Help erzeugte zusätzliche Ausgabe.' }
    } finally { $reader.Dispose();$command.Dispose() }
    $command=$connection.CreateCommand()
    $command.CommandText="CREATE TABLE #SelectContract(Dummy int NULL); EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[`";`"]',@ResultTable=N'#SelectContract',@Debug=2;"
    $reader=$command.ExecuteReader()
    try {
        if($reader.FieldCount -ne 0 -or $reader.NextResult()){ throw 'ResultTable erzeugte fachliches SELECT.' }
    } finally { $reader.Dispose();$command.Dispose() }
    Write-Output 'Split USP client metadata/resultset contracts: success'
} finally { $connection.Dispose() }
