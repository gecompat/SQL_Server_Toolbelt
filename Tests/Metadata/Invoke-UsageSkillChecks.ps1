# Use a dedicated, already-open connection to an installed test database.
param(
    [Parameter(Mandatory)] [System.Data.Common.DbConnection] $Connection,
    [Parameter(Mandatory)] [string] $ExpectedCatalogue,
    [Parameter(Mandatory)] [datetime] $Deadline,
    [switch] $WithWindowsLocalProviders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($Connection.State -ne [Data.ConnectionState]::Open) { throw 'SKILL_CONNECTION_NOT_OPEN' }
$catalogue = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
foreach ($row in (Get-Content -LiteralPath $ExpectedCatalogue -Raw -Encoding utf8 | ConvertFrom-Json)) {
    $catalogue.Add(($row.DatabaseRole, $row.SchemaName, $row.ObjectName -join ':'), $row)
}
if ($catalogue.Count -eq 0) { throw 'SKILL_EXPECTED_CATALOGUE_EMPTY' }

$command = $Connection.CreateCommand()
function Set-Command([string] $Sql) {
    $remaining = [Math]::Floor(($Deadline.ToUniversalTime() - [datetime]::UtcNow).TotalSeconds)
    if ($remaining -lt 1) { throw 'SKILL_CHECK_DEADLINE' }
    $command.CommandText = $Sql
    $command.CommandTimeout = [int][Math]::Min(30, $remaining)
}
function Assert-Row($Reader, [string[]] $Columns, $Expected) {
    if ($Reader.FieldCount -ne $Columns.Count) { throw 'SKILL_COLUMN_COUNT' }
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $name = $Columns[$i]
        if (-not [string]::Equals($Reader.GetName($i), $name, [StringComparison]::Ordinal)) {
            throw 'SKILL_COLUMN_NAME'
        }
        if ($name -ceq 'IsInternal') {
            if ($Reader.GetBoolean($i) -ne $Expected.IsInternal) { throw 'SKILL_VISIBILITY' }
        } elseif (-not [string]::Equals($Reader.GetString($i), $Expected.$name, [StringComparison]::Ordinal)) {
            throw 'SKILL_TEXT_DIFFERS'
        }
    }
}

$viewColumns = @('SchemaName', 'ObjectName', 'ObjectType', 'DatabaseRole', 'IsInternal',
    'Description', 'SkillFormatVersion', 'SkillMarkdown')
$helpColumns = @('SkillFormatVersion', 'SchemaName', 'ObjectName', 'SkillMarkdown')
$helpCases = @(
    @{ Key = 'toolbelt:toolbelt_core:USP_PrepareResultTable'; Standard = $true
       Sql = "EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1, @ResultTableToAlter=N'#UsageSkillWitness', @LikeTable=N'invalid';" }
    @{ Key = 'toolbelt:toolbelt_core:USP_SecondSessionProbe'; Standard = $true
       Sql = @'
DECLARE @SessionId int=17, @DatabaseName sysname=N'Contoso';
EXEC toolbelt_core.USP_SecondSessionProbe @Hilfe=1, @RemoteSessionId=@SessionId OUTPUT,
    @RemoteDatabaseName=@DatabaseName OUTPUT;
IF @SessionId IS NULL OR @SessionId<>17 OR @DatabaseName IS NULL OR @DatabaseName<>N'Contoso'
    THROW 52821,N'SKILL_HELP_CHANGED_OUTPUT',1;
'@ }
)
if ($WithWindowsLocalProviders) {
    $helpCases += @{
        Key = 'toolbelt:toolbelt_filesystem:CLR_ReadBinaryFileChunk'; Standard = $false
        Sql = "EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk @Hilfe=1, @ByteOffset=-1;"
    }
    $helpCases += @{
        Key = 'toolbelt:toolbelt_tsql:USP_ExplainSsisDataFlowInternal'; Standard = $true
        Sql = @'
EXEC toolbelt_tsql.USP_ExplainSsisDataFlowInternal @PackageBytes=NULL,@ProjectContext=NULL,@Bindings=NULL,
    @CatalogBindings=NULL,@LookupPolicies=NULL,@ProcedureSchema=NULL,@ProcedureName=NULL,
    @PackageXml=NULL,@StartValues=NULL,@Hilfe=1;
'@
    }
}
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
try {
    Set-Command "IF @@TRANCOUNT<>0 OR (@@OPTIONS & 2)<>0 OR OBJECT_ID(N'tempdb..#UsageSkillWitness') IS NOT NULL THROW 52819,N'SKILL_CONNECTION_NOT_DEDICATED',1;"
    [void]$command.ExecuteNonQuery()
    Set-Command 'SELECT @@OPTIONS;'
    $options = [int]$command.ExecuteScalar()

    Set-Command 'SELECT * FROM toolbelt_metadata.VW_ObjectUsageSkills;'
    $reader = $command.ExecuteReader()
    try {
        while ($reader.Read()) {
            if ([datetime]::UtcNow -ge $Deadline.ToUniversalTime()) { throw 'SKILL_CHECK_READ_DEADLINE' }
            $key = $reader.GetString(3), $reader.GetString(0), $reader.GetString(1) -join ':'
            if (-not $seen.Add($key) -or -not $catalogue.ContainsKey($key)) { throw 'SKILL_CATALOGUE_IDENTITY' }
            Assert-Row $reader $viewColumns $catalogue[$key]
        }
        if ($reader.NextResult() -or $seen.Count -ne $catalogue.Count) { throw 'SKILL_CATALOGUE_COVERAGE' }
    } finally { $reader.Dispose() }

    if ($WithWindowsLocalProviders) {
        Set-Command @'
BEGIN TRY
    EXEC sys.sp_executesql N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlowInternal @Hilfe=1;';
    THROW 52822,N'SKILL_HELP_MANDATORY_ARGUMENT_BYPASSED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>201 THROW;
END CATCH;
'@
        [void]$command.ExecuteNonQuery()
    }

    foreach ($case in $helpCases) {
        try {
            Set-Command ('BEGIN TRANSACTION; CREATE TABLE #UsageSkillWitness(Value int NOT NULL); ' +
                'INSERT #UsageSkillWitness VALUES(17); ' + $case.Sql)
            $reader = $command.ExecuteReader()
            try {
                if ($case.Standard -and ($reader.FieldCount -ne 12 -or $reader.GetName(0) -cne 'HelpContractVersion' -or
                        -not $reader.Read() -or -not $reader.NextResult())) { throw 'SKILL_STANDARD_HELP' }
                if (-not $reader.Read()) { throw 'SKILL_HELP_NO_ROW' }
                Assert-Row $reader $helpColumns $catalogue[$case.Key]
                if ($reader.Read() -or $reader.NextResult()) { throw 'SKILL_HELP_EXTRA_OUTPUT' }
            } finally { $reader.Dispose() }
            Set-Command "IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR @@OPTIONS<>$options OR (SELECT COUNT(*) FROM #UsageSkillWitness WHERE Value=17)<>1 OR (SELECT COUNT(*) FROM #UsageSkillWitness)<>1 THROW 52820,N'SKILL_HELP_CHANGED_CALLER',1;"
            [void]$command.ExecuteNonQuery()
        } finally {
            $command.CommandTimeout = 10
            $command.CommandText = 'IF @@TRANCOUNT>0 ROLLBACK;'
            [void]$command.ExecuteNonQuery()
        }
    }
    [pscustomobject]@{ CatalogueRows = $seen.Count; HelpCases = $helpCases.Count }
} finally { $command.Dispose() }
