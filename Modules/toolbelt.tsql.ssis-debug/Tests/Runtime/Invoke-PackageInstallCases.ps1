param(
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
 [Parameter(Mandatory)][ValidateSet('local','central')][string]$Mode,
 [Parameter(Mandatory)][string]$Release,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$ExpectedHash,
 [Parameter(Mandatory)][string]$Fixture
)
# Ausschließlich innerhalb der eigenen DB-/Trust-/Deadlinegrenzen des Labadapters.
$script:packageChecks=0
function PackageCheck([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_PACKAGE_ASSERT_'+$Name)};$script:packageChecks++}
function PackageState {
 Query $Connection @'
SELECT (SELECT COUNT_BIG(*) FROM sys.assemblies WITH(NOLOCK) WHERE name=N'Toolbelt_Tsql_SsisDebug') AS AssemblyCount,
 (SELECT CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) FROM sys.assemblies a WITH(NOLOCK)
 JOIN sys.assembly_files f WITH(NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_Tsql_SsisDebug') AS BinaryHash,
 OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow',N'P') AS PublicId,
 OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal',N'PC') AS InternalId,
 (SELECT COUNT_BIG(*) FROM sys.extended_properties WITH(NOLOCK) WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version') AS MarkerCount;
'@
}
$before=PackageState
PackageCheck ($before.Rows[0].AssemblyCount -eq 0 -and $before.Rows[0].PublicId -is [DBNull] -and $before.Rows[0].InternalId -is [DBNull]) 'FRESH_SCOPE'
Batches $Connection ([IO.File]::ReadAllText((Join-Path $Release 'Deploy.WithAssembly.sql'))) $Mode
$fresh=PackageState
PackageCheck ([string]$fresh.Rows[0].BinaryHash -ceq $ExpectedHash -and $fresh.Rows[0].AssemblyCount -eq 1) 'EXACT_INSTALLED_BINARY'
$versions=Query $Connection "SELECT COUNT_BIG(*) AS N FROM sys.extended_properties WITH(NOLOCK) WHERE class=0 AND ((name=N'Toolbelt.Module.toolbelt.core.result-table.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0') OR (name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version' AND CONVERT(nvarchar(64),value)=N'2.0.1') OR (name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0'));"
PackageCheck ($versions.Rows[0].N -eq 3) 'THREE_MODULE_VERSIONS'
$cmd=$Connection.CreateCommand();$cmd.CommandTimeout=Get-SsisNativeTimeout 40;$cmd.CommandType='StoredProcedure';$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'
try{
 [void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@PackageBytes'].Value=[IO.File]::ReadAllBytes($Fixture)
 [void]$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32);$cmd.Parameters['@Operation'].Value='bindings-template'
 $reader=$cmd.ExecuteReader();try{$template=[Data.DataTable]::new();$template.Load($reader)}finally{$reader.Dispose()}
 PackageCheck ($template.Columns.Count -eq 13 -and $template.Rows.Count -eq 1 -and [string]$template.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'REAL_PUBLIC_CLR_TEMPLATE'
}finally{$cmd.Dispose()}
Batches $Connection ([IO.File]::ReadAllText((Join-Path $Release 'Deploy.WithAssembly.sql'))) $Mode
$repeat=PackageState
PackageCheck ($repeat.Rows[0].PublicId -eq $fresh.Rows[0].PublicId -and $repeat.Rows[0].InternalId -eq $fresh.Rows[0].InternalId -and [string]$repeat.Rows[0].BinaryHash -ceq $ExpectedHash) 'REPEAT_IDENTITIES'
Batches $Connection ([IO.File]::ReadAllText((Join-Path $Release 'Uninstall.Expanded.sql'))) $Mode
$absent=PackageState
PackageCheck ($absent.Rows[0].AssemblyCount -eq 0 -and $absent.Rows[0].MarkerCount -eq 0 -and $absent.Rows[0].PublicId -is [DBNull] -and $absent.Rows[0].InternalId -is [DBNull]) 'UNINSTALL'
Batches $Connection ([IO.File]::ReadAllText((Join-Path $Release 'Uninstall.Expanded.sql'))) $Mode
$absent=PackageState
PackageCheck ($absent.Rows[0].AssemblyCount -eq 0 -and $absent.Rows[0].MarkerCount -eq 0) 'ABSENT_REPEAT'
$dependencies=Query $Connection "SELECT OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') AS ResultTableId,(SELECT COUNT_BIG(*) FROM sys.assemblies WITH(NOLOCK) WHERE name IN(N'Toolbelt_Tsql_ScriptParser',N'Microsoft.SqlServer.TransactSql.ScriptDom')) AS N;"
PackageCheck ($dependencies.Rows[0].ResultTableId -isnot [DBNull] -and $dependencies.Rows[0].N -eq 2) 'SHARED_DEPENDENCIES_RETAINED'
"SSIS_NATIVE_PACKAGE_INSTALL_PASS $script:packageChecks assertions; extracted fresh/repeat/uninstall and actual CLR invocation"
