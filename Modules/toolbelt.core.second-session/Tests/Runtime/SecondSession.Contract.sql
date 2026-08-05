:on error exit
SET NOCOUNT ON;

DELETE FROM toolbelt_core.WorkType
WHERE WorkTypeName LIKE 'test.second-session.%';
GO
DROP TABLE IF EXISTS toolbelt_core.SecondSessionTestChild;
DROP TABLE IF EXISTS toolbelt_core.SecondSessionTestParent;
DROP TABLE IF EXISTS toolbelt_core.SecondSessionTestEvidence;
GO
CREATE TABLE toolbelt_core.SecondSessionTestEvidence
(
      EvidenceId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_SecondSessionTestEvidence PRIMARY KEY
    , EventName varchar(64) NOT NULL
    , PayloadJson nvarchar(max) NULL
    , RemoteSessionId int NOT NULL
    , ExecutionId uniqueidentifier NULL
    , CorrelationId uniqueidentifier NULL
    , Actor nvarchar(256) NULL
    , Tenant nvarchar(256) NULL
    , CreatedAtUtc datetime2(7) NOT NULL CONSTRAINT DF_SecondSessionTestEvidence_CreatedAtUtc DEFAULT SYSUTCDATETIME()
);
CREATE TABLE toolbelt_core.SecondSessionTestParent
(
    Id int NOT NULL CONSTRAINT PK_SecondSessionTestParent PRIMARY KEY
);
CREATE TABLE toolbelt_core.SecondSessionTestChild
(
      Id int NOT NULL CONSTRAINT PK_SecondSessionTestChild PRIMARY KEY
    , ParentId int NOT NULL
    , CONSTRAINT FK_SecondSessionTestChild_Parent
        FOREIGN KEY(ParentId) REFERENCES toolbelt_core.SecondSessionTestParent(Id)
);
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestSecondSessionNone
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ExecutionId uniqueidentifier;
    DECLARE @CorrelationId uniqueidentifier;
    DECLARE @Actor nvarchar(256);
    DECLARE @Tenant nvarchar(256);
    SELECT
          @ExecutionId = c.ExecutionId
        , @CorrelationId = c.CorrelationId
        , @Actor = c.Actor
        , @Tenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    INSERT INTO toolbelt_core.SecondSessionTestEvidence
    (
          EventName, RemoteSessionId, ExecutionId, CorrelationId, Actor, Tenant
    )
    VALUES
    (
          'none', @@SPID, @ExecutionId, @CorrelationId, @Actor, @Tenant
    );
    RETURN 7;
END;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestSecondSessionJson
    @PayloadJson nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ExecutionId uniqueidentifier;
    DECLARE @CorrelationId uniqueidentifier;
    DECLARE @Actor nvarchar(256);
    DECLARE @Tenant nvarchar(256);
    SELECT
          @ExecutionId = c.ExecutionId
        , @CorrelationId = c.CorrelationId
        , @Actor = c.Actor
        , @Tenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    INSERT INTO toolbelt_core.SecondSessionTestEvidence
    (
          EventName, PayloadJson, RemoteSessionId
        , ExecutionId, CorrelationId, Actor, Tenant
    )
    VALUES
    (
          COALESCE(JSON_VALUE(@PayloadJson, '$.event'), 'json')
        , @PayloadJson, @@SPID
        , @ExecutionId, @CorrelationId, @Actor, @Tenant
    );
    RETURN 0;
END;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestSecondSessionFailure
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO toolbelt_core.SecondSessionTestEvidence(EventName, RemoteSessionId)
    VALUES ('failure', @@SPID);
    THROW 52670, N'Synthetischer Remote-Handlerfehler.', 1;
END;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestSecondSessionResultSet
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS int) AS UnexpectedResult;
    RETURN 0;
END;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestSecondSessionBadSignature
    @Unexpected int
AS
BEGIN
    SET NOCOUNT ON;
    RETURN 0;
END;
GO

EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.second-session.none'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestSecondSessionNone';
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.second-session.json'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestSecondSessionJson'
    , @ParameterMode = 'JSON_PAYLOAD'
    , @PayloadContractJson = N'{"type":"object"}';
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.second-session.failure'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestSecondSessionFailure';
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.second-session.resultset'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestSecondSessionResultSet';
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.second-session.bad-signature'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestSecondSessionBadSignature';
GO

DECLARE @ProviderRows TABLE
(
      ProviderName varchar(32), LinkedServerName sysname, IsEnabled bit
    , RowVersion binary(8), LinkedServerExists bit, RpcOutEnabled bit
    , RemoteProcTransactionPromotionEnabled bit, ProbeRemoteSessionId int
    , ProbeDatabaseName sysname
);
INSERT INTO @ProviderRows
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback
    @LinkedServerName = N'$(LinkedServerName)';

IF NOT EXISTS
(
    SELECT 1 FROM @ProviderRows
    WHERE ProviderName = 'loopback'
      AND IsEnabled = 1
      AND LinkedServerExists = 1
      AND RpcOutEnabled = 1
      AND RemoteProcTransactionPromotionEnabled = 0
      AND ProbeRemoteSessionId <> @@SPID
      AND ProbeDatabaseName = DB_NAME()
)
    THROW 52630, N'Providerkonfiguration oder Remote-Probe ist inkonsistent.', 1;

DECLARE @ProviderRowVersion binary(8) = (SELECT RowVersion FROM @ProviderRows);
DELETE FROM @ProviderRows;
INSERT INTO @ProviderRows
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback
      @LinkedServerName = N'$(LinkedServerName)'
    , @ExpectedRowVersion = @ProviderRowVersion;
IF (SELECT RowVersion FROM @ProviderRows) <> @ProviderRowVersion
    THROW 52631, N'Idempotente Providerkonfiguration änderte RowVersion.', 1;

DECLARE @Help TABLE
(
 HelpContractVersion varchar(16), SchemaName sysname, ObjectName sysname,
 Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
 IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max), ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
IF NOT EXISTS (SELECT 1 FROM @Help WHERE ObjectName=N'USP_ExecuteWorkTypeInNewSession')
    THROW 52632, N'Help-Vertrag fehlt.', 1;

DECLARE @RollbackExecution uniqueidentifier = '11111111-1111-1111-1111-111111111111';
DECLARE @RollbackCorrelation uniqueidentifier = '11111111-2222-2222-2222-222222222222';
BEGIN TRANSACTION;
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.none'
    , @ExecutionId = @RollbackExecution
    , @CorrelationId = @RollbackCorrelation
    , @Actor = N'rollback-actor'
    , @Tenant = N'rollback-tenant';
ROLLBACK TRANSACTION;

IF NOT EXISTS
(
    SELECT 1 FROM toolbelt_core.SecondSessionTestEvidence
    WHERE EventName = 'none'
      AND ExecutionId = @RollbackExecution
      AND CorrelationId = @RollbackCorrelation
      AND Actor = N'rollback-actor'
      AND Tenant = N'rollback-tenant'
      AND RemoteSessionId <> @@SPID
)
    THROW 52633, N'Remote Commit überlebte den Caller-Rollback nicht oder Context fehlt.', 1;

DECLARE @ContextExecution uniqueidentifier = '22222222-1111-1111-1111-111111111111';
DECLARE @ContextCorrelation uniqueidentifier = '22222222-2222-2222-2222-222222222222';
EXEC toolbelt_core.USP_BeginExecution
      @ExecutionId = @ContextExecution OUTPUT
    , @CorrelationId = @ContextCorrelation
    , @Actor = N'context-actor'
    , @Tenant = N'context-tenant';
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.json'
    , @PayloadJson = N'{"event":"context-json","value":42}';
EXEC toolbelt_core.USP_EndExecution
    @ExpectedExecutionId = @ContextExecution;

IF NOT EXISTS
(
    SELECT 1 FROM toolbelt_core.SecondSessionTestEvidence
    WHERE EventName = 'context-json'
      AND ExecutionId = @ContextExecution
      AND CorrelationId = @ContextCorrelation
      AND Actor = N'context-actor'
      AND Tenant = N'context-tenant'
      AND JSON_VALUE(PayloadJson, '$.value') = '42'
      AND RemoteSessionId <> @@SPID
)
    THROW 52634, N'Remote Context- oder JSON-Propagation ist inkonsistent.', 1;

DECLARE @DoomedExecution uniqueidentifier = '33333333-1111-1111-1111-111111111111';
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO toolbelt_core.SecondSessionTestChild(Id, ParentId) VALUES (1, 999);
    THROW 52635, N'Der synthetische Constraintfehler blieb aus.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52635
        THROW;
    IF XACT_STATE() <> -1
        THROW 52636, N'Der Caller ist nicht uncommittable.', 1;

    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
          @WorkTypeName = 'test.second-session.none'
        , @ExecutionId = @DoomedExecution
        , @CorrelationId = @DoomedExecution
        , @Actor = N'doomed-actor';

    ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;

IF NOT EXISTS
(
    SELECT 1 FROM toolbelt_core.SecondSessionTestEvidence
    WHERE EventName = 'none'
      AND ExecutionId = @DoomedExecution
      AND Actor = N'doomed-actor'
      AND RemoteSessionId <> @@SPID
)
    THROW 52637, N'Remote Commit aus uncommittable Caller fehlt.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
        @WorkTypeName = 'test.second-session.failure';
    THROW 52638, N'Der Remote-Handlerfehler blieb aus.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52638
        THROW;
END CATCH;
IF EXISTS (SELECT 1 FROM toolbelt_core.SecondSessionTestEvidence WHERE EventName='failure')
    THROW 52639, N'Die Remote-Handlertransaktion wurde nicht zurückgerollt.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
        @WorkTypeName = 'test.second-session.resultset';
    THROW 52640, N'Der Resultset-Verstoß blieb aus.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52640
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
        @WorkTypeName = 'test.second-session.bad-signature';
    THROW 52641, N'Die ungültige Handler-Signatur wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51637
        THROW;
END CATCH;

CREATE TABLE #SuppressedSecondSessionResult(Dummy int NULL);
INSERT INTO #SuppressedSecondSessionResult
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.none'
    , @SuppressResult = 1;
IF EXISTS (SELECT 1 FROM #SuppressedSecondSessionResult)
    THROW 52645, N'@SuppressResult erzeugte unerwartete Infrastrukturzeilen.', 1;
DROP TABLE #SuppressedSecondSessionResult;

BEGIN TRY
    CREATE TABLE #InvalidSuppressResult(Dummy int NULL);
    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
          @WorkTypeName = 'test.second-session.none'
        , @ResultTable = N'#InvalidSuppressResult'
        , @SuppressResult = 1;
    DROP TABLE #InvalidSuppressResult;
    THROW 52646, N'@SuppressResult mit @ResultTable wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF OBJECT_ID(N'tempdb..#InvalidSuppressResult') IS NOT NULL
        DROP TABLE #InvalidSuppressResult;
    IF ERROR_NUMBER() = 52646 OR ERROR_NUMBER() <> 51620
        THROW;
END CATCH;

CREATE TABLE #SecondSessionResult(Dummy int NULL);
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.none'
    , @ResultTable = N'#SecondSessionResult'
    , @KeepData = 0;
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.json'
    , @PayloadJson = N'{"event":"result-table"}'
    , @ResultTable = N'#SecondSessionResult'
    , @KeepData = 1;
IF (SELECT COUNT(*) FROM #SecondSessionResult) <> 2
    THROW 52642, N'ResultTable Replace/Append ist inkonsistent.', 1;
IF EXISTS (SELECT 1 FROM #SecondSessionResult WHERE RemoteSessionId = CallerSessionId)
    THROW 52643, N'ResultTable weist keine getrennte Session aus.', 1;
DROP TABLE #SecondSessionResult;

EXEC master.dbo.sp_serveroption N'$(LinkedServerName)', N'remote proc transaction promotion', N'true';
BEGIN TRY
    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
        @WorkTypeName = 'test.second-session.none';
    EXEC master.dbo.sp_serveroption N'$(LinkedServerName)', N'remote proc transaction promotion', N'false';
    THROW 52644, N'Providerdrift wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    DECLARE @DriftError int = ERROR_NUMBER();
    EXEC master.dbo.sp_serveroption N'$(LinkedServerName)', N'remote proc transaction promotion', N'false';
    IF @DriftError <> 51614
        THROW;
END CATCH;

DELETE FROM toolbelt_core.WorkType
WHERE WorkTypeName LIKE 'test.second-session.%';
DROP PROCEDURE toolbelt_core.USP_TestSecondSessionBadSignature;
DROP PROCEDURE toolbelt_core.USP_TestSecondSessionResultSet;
DROP PROCEDURE toolbelt_core.USP_TestSecondSessionFailure;
DROP PROCEDURE toolbelt_core.USP_TestSecondSessionJson;
DROP PROCEDURE toolbelt_core.USP_TestSecondSessionNone;
DROP TABLE toolbelt_core.SecondSessionTestChild;
DROP TABLE toolbelt_core.SecondSessionTestParent;
DROP TABLE toolbelt_core.SecondSessionTestEvidence;

PRINT N'Second Session Contract: erfolgreich';
GO
