-- Eigene bereits installierte Test-DBs. Windows-Anmeldung wird vom öffentlichen
-- Labzugang im gebundenen Gast geöffnet; keine Identität wird impersoniert.
SET NOCOUNT ON;
IF DB_NAME()<>@ConsumerDatabase OR @@TRANCOUNT<>0
    THROW 51000,N'SSIS_WINDOWS_CALLER_CONTEXT',1;
IF CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) NOT IN(N'NTLM',N'KERBEROS')
    THROW 51000,N'SSIS_WINDOWS_AUTHENTICATION_REQUIRED',1;
IF NOT EXISTS(SELECT 1 FROM sys.dm_exec_connections WHERE session_id=@@SPID AND encrypt_option=N'TRUE')
    THROW 51000,N'SSIS_WINDOWS_ENCRYPT_REQUIRED',1;
DECLARE @identitySql nvarchar(max)=N'SELECT @n=COUNT(*) FROM '+QUOTENAME(@ModuleDatabase)+N'.sys.assembly_files AS f JOIN '+QUOTENAME(@ModuleDatabase)+N'.sys.assemblies AS a ON a.assembly_id=f.assembly_id WHERE a.name=N''Toolbelt_Tsql_SsisDebug'' AND f.file_id=1 AND HASHBYTES(''SHA2_512'',f.content)=@hash;';
DECLARE @identityCount int;
EXEC sys.sp_executesql @identitySql,N'@hash varbinary(max),@n int OUTPUT',@ExpectedAssembly,@identityCount OUTPUT;
IF @identityCount<>1 THROW 51000,N'SSIS_WINDOWS_CURRENT_BINARY_REQUIRED',1;
DECLARE @parameterCount int;
SET @identitySql=N'SELECT @n=COUNT(*) FROM '+QUOTENAME(@ModuleDatabase)+N'.sys.parameters AS p JOIN '+QUOTENAME(@ModuleDatabase)+N'.sys.objects AS o ON o.object_id=p.object_id JOIN '+QUOTENAME(@ModuleDatabase)+N'.sys.schemas AS s ON s.schema_id=o.schema_id WHERE s.name=N''toolbelt_tsql'' AND o.name=N''USP_ExplainSsisDataFlow'';';
EXEC sys.sp_executesql @identitySql,N'@n int OUTPUT',@parameterCount OUTPUT;
IF @parameterCount<>38 THROW 51000,N'SSIS_WINDOWS_CURRENT_API_REQUIRED',1;
CREATE TABLE #WindowsAccessArtifacts(Dummy bit NULL);
DECLARE @call nvarchar(max)=N'EXEC '+QUOTENAME(@ModuleDatabase)+N'.toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@bytes,@Operation=@operation,@Bindings=@bindings,@CatalogBindings=@catalog,@TSqlVersion=@cl,@ResultTable=N''#WindowsAccessArtifacts'',@KeepData=0;';
DECLARE @bindings nvarchar(max),@cl smallint=(SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID());
EXEC sys.sp_executesql @call,N'@bytes varbinary(max),@operation varchar(32),@bindings nvarchar(max),@catalog nvarchar(max),@cl smallint',@PackageBytes,'bindings-template',NULL,NULL,@cl;
IF (SELECT COUNT(*) FROM #WindowsAccessArtifacts WHERE ArtifactKind='BindingsTemplate')<>1
    THROW 51000,N'SSIS_WINDOWS_TEMPLATE_REQUIRED',1;
SELECT @bindings=Content FROM #WindowsAccessArtifacts WHERE ArtifactKind='BindingsTemplate';
EXEC sys.sp_executesql @call,N'@bytes varbinary(max),@operation varchar(32),@bindings nvarchar(max),@catalog nvarchar(max),@cl smallint',@PackageBytes,'explain',@bindings,@Catalog,@cl;
IF (SELECT COUNT(*) FROM #WindowsAccessArtifacts WHERE ArtifactKind='DebugScript' AND IsComplete=1 AND IsExecutable=1 AND SafetyStatus='passed')<>2
    THROW 51000,N'SSIS_WINDOWS_DEBUGSCRIPT_REQUIRED',1;
IF (SELECT COUNT(*) FROM #WindowsAccessArtifacts WHERE ArtifactKind='TargetSql' AND IsExecutable=1)<>2
    THROW 51000,N'SSIS_WINDOWS_TARGETS_REQUIRED',1;
-- Der öffentliche Labzugang begrenzt einzelne Zellen und die Gesamtausgabe.
-- Umfangreiche Scripts werden nicht als Transportprobe zurückkopiert. Ihre
-- unveränderten bereits gebundenen Bytes führt der Caller separat mit Windows aus.
SELECT N'SSIS_WINDOWS_ANALYSIS_PASS' AS Result,@parameterCount AS ParameterCount,CONVERT(int,@cl) AS CompatibilityLevel,
       (SELECT COUNT(*) FROM #WindowsAccessArtifacts WHERE ArtifactKind='DebugScript' AND IsExecutable=1) AS DebugScripts,
       N'Grüße Ω' AS UnicodeWitness;
DROP TABLE #WindowsAccessArtifacts;
