SET NOCOUNT ON;

DELETE FROM toolbelt_core.WorkType
WHERE WorkTypeName LIKE 'test.%';

EXEC(N'
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestWorkTypeNoParameters
AS
BEGIN
    SET NOCOUNT ON;
END;');

EXEC(N'
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestWorkTypeJson
    @PayloadJson nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISJSON(@PayloadJson) <> 1
        THROW 52590, N''Payload muss JSON sein.'', 1;
END;');

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'Test.Invalid'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_TestWorkTypeNoParameters';
    THROW 52500, N'Nichtkanonischer Name wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51500 THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'test.missing'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_DoesNotExist';
    THROW 52501, N'Fehlender Handler wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51507 THROW;
END CATCH;

DECLARE @First TABLE
(
      WorkTypeId bigint, WorkTypeName varchar(128), HandlerSchema sysname
    , HandlerProcedure sysname, HandlerQualifiedName nvarchar(517)
    , ParameterMode varchar(16), PayloadContractJson nvarchar(4000) NULL
    , DefaultTimeoutSeconds int, IsIdempotent bit, IsEnabled bit
    , Description nvarchar(1000) NULL, CreatedAtUtc datetime2(7), CreatedBy sysname
    , ModifiedAtUtc datetime2(7), ModifiedBy sysname, DisabledAtUtc datetime2(7) NULL
    , DisabledBy sysname NULL, DisabledReason nvarchar(1000) NULL
    , RowVersion binary(8), HandlerExists bit
);

INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'synthetic';

IF NOT EXISTS
(
    SELECT 1 FROM @First
    WHERE WorkTypeName = 'test.noop'
      AND IsEnabled = 1
      AND ParameterMode = 'NONE'
      AND HandlerExists = 1
)
    THROW 52502, N'Registrierung ist inkonsistent.', 1;

DECLARE @InitialRowVersion binary(8) = (SELECT RowVersion FROM @First);

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'synthetic';

IF (SELECT RowVersion FROM @First) <> @InitialRowVersion
    THROW 52503, N'Idempotente Registrierung änderte RowVersion.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'test.noop'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
        , @Description = N'changed';
    THROW 52504, N'Unfreigegebenes Update wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51511 THROW;
END CATCH;

IF @@TRANCOUNT <> 0 OR XACT_STATE() <> 0
    THROW 52514, N'Validierungsfehler hinterließ einen offenen oder uncommittable Transaktionszustand.', 1;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'changed'
    , @AllowUpdate = 1
    , @ExpectedRowVersion = @InitialRowVersion;

DECLARE @UpdatedRowVersion binary(8) = (SELECT RowVersion FROM @First);
IF @UpdatedRowVersion = @InitialRowVersion
    THROW 52505, N'Update änderte RowVersion nicht.', 1;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_DisableWorkType
      @WorkTypeName = 'test.noop'
    , @DisabledReason = N'synthetic stop'
    , @ExpectedRowVersion = @UpdatedRowVersion;

IF NOT EXISTS (SELECT 1 FROM @First WHERE IsEnabled = 0 AND DisabledReason = N'synthetic stop')
    THROW 52506, N'Disable-Vertrag ist inkonsistent.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName = 'test.noop';
    THROW 52507, N'Deaktivierter Work Type wurde aufgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51532 THROW;
END CATCH;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'test.noop'
    , @RequireEnabled = 0;

IF NOT EXISTS (SELECT 1 FROM @First WHERE IsEnabled = 0)
    THROW 52508, N'Resolve mit RequireEnabled=0 ist inkonsistent.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'test.noop'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
        , @Description = N'changed'
        , @AllowUpdate = 1;
    THROW 52509, N'Reaktivierung ohne Flag wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51512 THROW;
END CATCH;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'changed'
    , @AllowUpdate = 1
    , @Reactivate = 1;

IF NOT EXISTS (SELECT 1 FROM @First WHERE IsEnabled = 1 AND DisabledAtUtc IS NULL)
    THROW 52510, N'Reaktivierung ist inkonsistent.', 1;

EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.json'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeJson'
    , @ParameterMode = 'JSON_PAYLOAD'
    , @PayloadContractJson = N'{"type":"object","required":["value"]}'
    , @DefaultTimeoutSeconds = 30
    , @IsIdempotent = 1;

IF NOT EXISTS
(
    SELECT 1 FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeName = 'test.json'
      AND ParameterMode = 'JSON_PAYLOAD'
      AND IsIdempotent = 1
)
    THROW 52511, N'JSON-Work-Type fehlt.', 1;

CREATE TABLE #CallerResult (Dummy int NULL);
EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'test.noop'
    , @ResultTable = N'#CallerResult'
    , @KeepData = 0;
EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'test.json'
    , @ResultTable = N'#CallerResult'
    , @KeepData = 1;

IF (SELECT COUNT(*) FROM #CallerResult) <> 2
    THROW 52512, N'ResultTable Append ist inkonsistent.', 1;

DECLARE @Help TABLE
(
 HelpContractVersion varchar(16), SchemaName sysname, ObjectName sysname,
 Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
 IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max), ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
IF NOT EXISTS (SELECT 1 FROM @Help WHERE ObjectName=N'USP_RegisterWorkType')
    THROW 52513, N'Help-Vertrag fehlt.', 1;

DROP TABLE #CallerResult;
DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName LIKE 'test.%';
DROP PROCEDURE toolbelt_core.USP_TestWorkTypeJson;
DROP PROCEDURE toolbelt_core.USP_TestWorkTypeNoParameters;

PRINT N'Work Type Contract: erfolgreich';
