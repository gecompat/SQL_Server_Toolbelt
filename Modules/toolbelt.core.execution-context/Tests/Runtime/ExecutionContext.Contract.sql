SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext())
 THROW 52420, N'Vor Testbeginn ist unerwartet ein Context aktiv.', 1;

DECLARE @Id uniqueidentifier;
DECLARE @Correlation uniqueidentifier = '11111111-2222-3333-4444-555555555555';
EXEC toolbelt_core.USP_BeginExecution
 @ExecutionId=@Id OUTPUT, @CorrelationId=@Correlation,
 @Actor=N'worker-a', @Tenant=N'tenant-a';
IF @Id IS NULL OR toolbelt_core.SVF_CurrentExecutionId() <> @Id
 THROW 52421, N'Execution-ID wurde nicht gesetzt.', 1;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ExecutionId=@Id AND CorrelationId=@Correlation AND Actor=N'worker-a' AND Tenant=N'tenant-a' AND ScopeDepth=1)
 THROW 52422, N'Root-Context ist inkonsistent.', 1;

DECLARE @NestedId uniqueidentifier = NULL;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@NestedId OUTPUT;
IF @NestedId <> @Id OR NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ScopeDepth=2)
 THROW 52423, N'Nested Context ist inkonsistent.', 1;

EXEC toolbelt_core.USP_SetExecutionContext
 @ExpectedExecutionId=@Id, @Actor=N'worker-b', @ClearTenant=1;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE Actor=N'worker-b' AND Tenant IS NULL)
 THROW 52424, N'Context-Update ist fehlgeschlagen.', 1;

BEGIN TRY
 DECLARE @Wrong uniqueidentifier = NEWID();
 EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Wrong;
 THROW 52425, N'Mismatch wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() <> 51431 THROW;
END CATCH;

EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ScopeDepth=1)
 THROW 52426, N'Nested End hat falsche Tiefe.', 1;
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
IF EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext()) OR toolbelt_core.SVF_CurrentExecutionId() IS NOT NULL
 THROW 52427, N'Root End hat Sessionwerte nicht gelöscht.', 1;

DECLARE @Help TABLE
(
 HelpContractVersion varchar(16), SchemaName sysname, ObjectName sysname,
 Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
 IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max), ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_BeginExecution @Hilfe=1;
IF NOT EXISTS (SELECT 1 FROM @Help WHERE ObjectName=N'USP_BeginExecution')
 THROW 52428, N'Help-Vertrag fehlt.', 1;
PRINT N'Execution Context Contract: erfolgreich';
