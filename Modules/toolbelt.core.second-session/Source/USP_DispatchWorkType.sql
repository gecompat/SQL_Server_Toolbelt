SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DispatchWorkType]
(
      @WorkTypeName       varchar(128)
    , @PayloadJson        nvarchar(max) = NULL
    , @ExecutionId        uniqueidentifier
    , @CorrelationId      uniqueidentifier
    , @Actor              nvarchar(256) = NULL
    , @Tenant             nvarchar(256) = NULL
    , @RemoteSessionId    int OUTPUT
    , @HandlerReturnCode  int OUTPUT
    , @StartedAtUtc       datetime2(7) OUTPUT
    , @CompletedAtUtc     datetime2(7) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @RemoteSessionId = @@SPID;
    SET @HandlerReturnCode = NULL;
    SET @StartedAtUtc = SYSUTCDATETIME();
    SET @CompletedAtUtc = NULL;

    IF @ExecutionId IS NULL OR @CorrelationId IS NULL
        THROW 51630, N'ExecutionId und CorrelationId sind für den Remote-Dispatcher erforderlich.', 1;

    DECLARE
          @HandlerSchema sysname
        , @HandlerProcedure sysname
        , @ParameterMode varchar(16)
        , @IsEnabled bit;

    SELECT
          @HandlerSchema = wt.HandlerSchema
        , @HandlerProcedure = wt.HandlerProcedure
        , @ParameterMode = wt.ParameterMode
        , @IsEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @HandlerSchema IS NULL
        THROW 51631, N'Der Work Type ist in der Remote-Datenbank nicht registriert.', 1;
    IF @IsEnabled = 0
        THROW 51632, N'Der Work Type ist in der Remote-Datenbank deaktiviert.', 1;

    IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
        THROW 51633, N'Der Work Type akzeptiert keine JSON-Payload.', 1;
    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @PayloadJson IS NULL
           OR ISJSON(@PayloadJson) <> 1
           OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
       )
        THROW 51634, N'Der Work Type benötigt eine JSON-Objekt-Payload.', 1;

    DECLARE @HandlerQualifiedName nvarchar(517) =
        QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure);
    DECLARE @HandlerObjectId int = COALESCE
    (
          OBJECT_ID(@HandlerQualifiedName, N'P')
        , OBJECT_ID(@HandlerQualifiedName, N'PC')
    );

    IF @HandlerObjectId IS NULL
        THROW 51635, N'Die registrierte Remote-Zielprocedure existiert nicht.', 1;
    IF ISNULL(HAS_PERMS_BY_NAME(@HandlerQualifiedName, N'OBJECT', N'EXECUTE'), 0) <> 1
        THROW 51636, N'Der Remote-Principal besitzt kein EXECUTE auf die Zielprocedure.', 1;

    DECLARE @InputParameterCount int =
    (
        SELECT COUNT(*)
        FROM sys.parameters AS p
        WHERE p.object_id = @HandlerObjectId
          AND p.parameter_id > 0
    );

    IF @ParameterMode = 'NONE' AND @InputParameterCount <> 0
        THROW 51637, N'Ein NONE-Handler darf keine Eingabe- oder Ausgabeparameter besitzen.', 1;

    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @InputParameterCount <> 1
           OR NOT EXISTS
              (
                  SELECT 1
                  FROM sys.parameters AS p
                  WHERE p.object_id = @HandlerObjectId
                    AND p.parameter_id = 1
                    AND p.name = N'@PayloadJson'
                    AND TYPE_NAME(p.user_type_id) = N'nvarchar'
                    AND p.max_length = -1
                    AND p.is_output = 0
              )
       )
        THROW 51638, N'Ein JSON_PAYLOAD-Handler muss exakt @PayloadJson nvarchar(max) als einzigen Eingabeparameter besitzen.', 1;

    DECLARE @RemoteExecutionId uniqueidentifier = @ExecutionId;
    DECLARE @ContextStarted bit = 0;

    BEGIN TRY
        EXEC toolbelt_core.USP_BeginExecution
              @ExecutionId = @RemoteExecutionId OUTPUT
            , @CorrelationId = @CorrelationId
            , @Actor = @Actor
            , @Tenant = @Tenant
            , @AllowNested = 0;
        SET @ContextStarted = 1;

        BEGIN TRANSACTION;

        DECLARE @HandlerSql nvarchar(max);
        IF @ParameterMode = 'NONE'
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' WITH RESULT SETS NONE;';
        ELSE
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' @PayloadJson = @PayloadJson WITH RESULT SETS NONE;';

        EXEC sys.sp_executesql
              @HandlerSql
            , N'@PayloadJson nvarchar(max), @HandlerReturnCode int OUTPUT'
            , @PayloadJson = @PayloadJson
            , @HandlerReturnCode = @HandlerReturnCode OUTPUT;

        COMMIT TRANSACTION;
        SET @CompletedAtUtc = SYSUTCDATETIME();

        EXEC toolbelt_core.USP_EndExecution
            @ExpectedExecutionId = @ExecutionId;
        SET @ContextStarted = 0;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        IF @ContextStarted = 1
        BEGIN
            BEGIN TRY
                EXEC toolbelt_core.USP_EndExecution
                    @ExpectedExecutionId = @ExecutionId;
            END TRY
            BEGIN CATCH
                -- Der ursprüngliche Handler-/Providerfehler behält Vorrang.
            END CATCH;
        END;

        THROW;
    END CATCH;
END;
GO
