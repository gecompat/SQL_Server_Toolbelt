[CmdletBinding()]
param([Parameter(Mandatory)][string]$Database)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Verbindung ausschließlich im Prozess; keine Credential-/Exception-Rohdaten als Artefakt.
$builder=[System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source']="tcp:$($env:TBX_SQL_HOST),$($env:TBX_SQL_PORT)"
$builder['Initial Catalog']=$Database
$builder['User ID']=$env:TBX_SQL_USER
$builder['Password']=$env:TBX_SQL_PASSWORD
$builder['Pooling']=$false
$builder['Enlist']=$false
$builder['ConnectRetryCount']=0
$builder['Encrypt']=$true
$builder['TrustServerCertificate']=$true
$connection=[System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$command=$null
$messages=[System.Collections.Generic.List[string]]::new()
$connection.add_InfoMessage({param($sender,$event) $messages.Add($event.Message)}.GetNewClosure())
try {
    $connection.Open()
    $command=$connection.CreateCommand()
    # Exakte früheste Guard-Batches aus beiden kanonischen Lifecycle-Dateien;
    # SQLCMD-Abbruch des kompletten Includes wird zusätzlich im Adapter geprüft.
    foreach($lifecycle in @('Deploy.sql','Uninstall.sql')) {
        $lifecycleText=Get-Content (Join-Path $PSScriptRoot "../../Deployment/$lifecycle") -Raw
        $guardStart=$lifecycleText.IndexOf('-- RAISERROR statt THROW:')
        $guardEnd=$lifecycleText.IndexOf('SET NOCOUNT ON;')
        if($guardStart -lt 0 -or $guardEnd -le $guardStart){throw 'Lifecycle guard boundary missing.'}
        $guard=$lifecycleText.Substring($guardStart,$guardEnd-$guardStart)
        foreach($abortMode in @('OFF','ON')) {
            $command.CommandText="SET XACT_ABORT $abortMode; BEGIN TRANSACTION; CREATE TABLE #CallerLifecycle(Value int NOT NULL); INSERT #CallerLifecycle VALUES(37);"
            $command.ExecuteNonQuery() | Out-Null
            $command.CommandText="SELECT CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version';"
            $markerBefore=$command.ExecuteScalar()
            $command.CommandText=$guard
            $rejected=$false
            try {$command.ExecuteNonQuery() | Out-Null}
            catch {
                $failure=$_.Exception
                while($null -ne $failure.InnerException){$failure=$failure.InnerException}
                if($failure -isnot [System.Data.SqlClient.SqlException] -or $failure.Number -ne 50000 -or -not $failure.Message.StartsWith('TBX_TABLE_CLONE_CALLER_TRANSACTION:')){throw 'Lifecycle caller rejection category failed.'}
                $rejected=$true
            }
            if(-not $rejected){throw 'Lifecycle caller transaction accepted.'}
            $command.CommandText="SELECT CASE WHEN @@TRANCOUNT=1 AND XACT_STATE()=1 AND (SELECT COUNT(*) FROM #CallerLifecycle)=1 AND (SELECT Value FROM #CallerLifecycle)=37 AND CONVERT(nvarchar(64),(SELECT value FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version'))=N'$markerBefore' AND CASE WHEN (16384 & @@OPTIONS)=16384 THEN 1 ELSE 0 END=$(if($abortMode -eq 'ON'){1}else{0}) THEN 1 ELSE 0 END;"
            if($command.ExecuteScalar() -ne 1){throw 'Lifecycle changed caller state/data/marker.'}
            $command.CommandText='ROLLBACK TRANSACTION; SET XACT_ABORT OFF;'
            $command.ExecuteNonQuery() | Out-Null
        }
    }
    $command.CommandText='CREATE TABLE dbo.SyntheticMetadataSource(Id int NOT NULL);'
    $command.ExecuteNonQuery() | Out-Null
    $command.CommandText="EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticMetadataSource',N'dbo',N'SyntheticMetadataTarget',@Debug=2;"
    $reader=$command.ExecuteReader()
    try {
        $schema=$reader.GetSchemaTable()
        $names=@('Ordinal','ObjectKind','TargetName','ScriptText')
        $types=@('int','varchar','nvarchar','nvarchar')
        $sizes=@(4,32,776,[int]::MaxValue)
        if($reader.FieldCount -ne 4){throw 'Clone result column count failed.'}
        for($i=0;$i -lt 4;$i++) {
            if($schema.Rows[$i].ColumnName -ne $names[$i] -or $reader.GetDataTypeName($i) -ne $types[$i] -or $schema.Rows[$i].AllowDBNull){throw 'Clone result metadata failed.'}
            if($i -gt 0 -and $schema.Rows[$i].ColumnSize -ne $sizes[$i]){throw 'Clone result length metadata failed.'}
        }
                $expectedSet=@('SET ANSI_NULLS ON;','SET ANSI_PADDING ON;','SET ANSI_WARNINGS ON;','SET ARITHABORT ON;','SET CONCAT_NULL_YIELDS_NULL ON;','SET QUOTED_IDENTIFIER ON;','SET NUMERIC_ROUNDABORT OFF;')
        $rows=0; while($reader.Read()){
            $rows++
            if($reader.GetInt32(0) -ne $rows){throw 'Clone plan ordinal failed.'}
            if($rows -le 7){if($reader.GetString(1) -ne 'SESSION_OPTION' -or $reader.GetString(3) -cne $expectedSet[$rows-1]){throw 'Clone SET row failed.'}}
            elseif($rows -ne 8 -or $reader.GetString(1) -ne 'TABLE'){throw 'Clone TABLE row failed.'}
        }
        if($rows -ne 8 -or $reader.NextResult()){throw 'Clone SELECT resultset count failed.'}
    } finally {$reader.Dispose()}
    $messages.Clear()
    $command.CommandText="EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1,@Debug=255,@IncludeIdentity=NULL,@IncludeExtendedProperties=NULL,@ResultTable=N'invalid';"
    $reader=$command.ExecuteReader()
    try {
        $helpNames=@('HelpContractVersion','SchemaName','ObjectName','Section','Ordinal','ItemName','SqlDataType','IsRequired','IsNullable','DefaultValue','Description','ExampleSql')
        if($reader.FieldCount -ne 12){throw 'Clone Help metadata failed.'}
        for($i=0;$i -lt 12;$i++){if($reader.GetName($i) -ne $helpNames[$i]){throw 'Clone Help fields failed.'}}
        $sections=[System.Collections.Generic.HashSet[string]]::new()
        $parameters=0; while($reader.Read()){$sections.Add($reader.GetString(3)) | Out-Null; if($reader.GetString(3) -eq 'PARAMETER'){$parameters++}}
        foreach($section in @('DESCRIPTION','PARAMETER','RESULT_COLUMN','EXAMPLE')){if(-not $sections.Contains($section)){throw 'Clone Help sections failed.'}}
        if($parameters -ne 10 -or $reader.NextResult() -or $messages.Count -ne 0){throw 'Clone Help bypass/output failed.'}
    } finally {$reader.Dispose()}
    $command.CommandText="CREATE TABLE #MetadataPlan(Dummy int); EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticMetadataSource',N'dbo',N'SyntheticMetadataTarget',@ResultTable=N'#MetadataPlan';"
    $reader=$command.ExecuteReader()
    try {if($reader.FieldCount -ne 0 -or $reader.NextResult()){throw 'Clone ResultTable emitted SELECT.'}} finally {$reader.Dispose()}
    $command.CommandText='DROP TABLE dbo.SyntheticMetadataSource;'
    $command.ExecuteNonQuery() | Out-Null
    $command.Dispose()
    'TableClone client metadata/Help/ResultTable PASS'
} finally {try{if($null -ne $command){$command.Dispose()}}finally{try{$connection.Dispose()}finally{$builder.Clear()}}}
