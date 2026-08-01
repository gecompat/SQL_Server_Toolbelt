SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DisableWorkType]
(
      @WorkTypeName       varchar(128)   = NULL
    , @DisabledReason     nvarchar(1000) = NULL
    , @ExpectedRowVersion binary(8)      = NULL
    , @ResultTable        sysname        = NULL
    , @KeepData           bit            = 0
    , @Debug              tinyint        = 0
    , @Hilfe              bit            = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_DisableWorkType' AS sysname) AS ObjectName
            , CAST('DESCRIPTION' AS varchar(32)) AS Section
            , 1 AS Ordinal
            , CAST(NULL AS sysname) AS ItemName
            , CAST(NULL AS varchar(256)) AS SqlDataType
            , CAST(NULL AS bit) AS IsRequired
            , CAST(NULL AS bit) AS IsNullable
            , CAST(NULL AS nvarchar(4000)) AS DefaultValue
            , CAST(N'Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.' AS nvarchar(max)) AS Description
            , CAST(N'EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName=''demo.noop'';' AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51520, N'@WorkTypeName ist erforderlich.', 1;


    CREATE TABLE #tbx_Core_WorkType_ResultShape
    (
          WorkTypeId            bigint NOT NULL
        , WorkTypeName          varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , HandlerSchema         sysname NOT NULL
        , HandlerProcedure      sysname NOT NULL
        , HandlerQualifiedName  nvarchar(517) NOT NULL
        , ParameterMode         varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadContractJson   nvarchar(4000) NULL
        , DefaultTimeoutSeconds int NOT NULL
        , IsIdempotent          bit NOT NULL
        , IsEnabled             bit NOT NULL
        , Description           nvarchar(1000) NULL
        , CreatedAtUtc          datetime2(7) NOT NULL
        , CreatedBy             sysname NOT NULL
        , ModifiedAtUtc         datetime2(7) NOT NULL
        , ModifiedBy            sysname NOT NULL
        , DisabledAtUtc         datetime2(7) NULL
        , DisabledBy            sysname NULL
        , DisabledReason        nvarchar(1000) NULL
        , RowVersion            binary(8) NOT NULL
        , HandlerExists         bit NOT NULL
    );

    CREATE TABLE #tbx_Core_WorkType_Result
    (
          WorkTypeId            bigint NOT NULL
        , WorkTypeName          varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , HandlerSchema         sysname NOT NULL
        , HandlerProcedure      sysname NOT NULL
        , HandlerQualifiedName  nvarchar(517) NOT NULL
        , ParameterMode         varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadContractJson   nvarchar(4000) NULL
        , DefaultTimeoutSeconds int NOT NULL
        , IsIdempotent          bit NOT NULL
        , IsEnabled             bit NOT NULL
        , Description           nvarchar(1000) NULL
        , CreatedAtUtc          datetime2(7) NOT NULL
        , CreatedBy             sysname NOT NULL
        , ModifiedAtUtc         datetime2(7) NOT NULL
        , ModifiedBy            sysname NOT NULL
        , DisabledAtUtc         datetime2(7) NULL
        , DisabledBy            sysname NULL
        , DisabledReason        nvarchar(1000) NULL
        , RowVersion            binary(8) NOT NULL
        , HandlerExists         bit NOT NULL
    );


    DECLARE @WorkTypeId bigint;
    DECLARE @CurrentRowVersion binary(8);
    DECLARE @CurrentEnabled bit;
    DECLARE @Now datetime2(7) = SYSUTCDATETIME();
    DECLARE @Principal sysname = ORIGINAL_LOGIN();

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_WorkType_Disable;

    BEGIN TRY

    SELECT
          @WorkTypeId = wt.WorkTypeId
        , @CurrentRowVersion = CONVERT(binary(8), wt.RowVersion)
        , @CurrentEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @WorkTypeId IS NULL
        THROW 51521, N'Der Work Type ist nicht registriert.', 1;
    IF @ExpectedRowVersion IS NOT NULL AND @ExpectedRowVersion <> @CurrentRowVersion
        THROW 51522, N'@ExpectedRowVersion stimmt nicht mit dem aktuellen Work Type überein.', 1;

    IF @CurrentEnabled = 1
    BEGIN
        UPDATE toolbelt_core.WorkType
        SET
              IsEnabled = 0
            , DisabledAtUtc = @Now
            , DisabledBy = @Principal
            , DisabledReason = @DisabledReason
            , ModifiedAtUtc = @Now
            , ModifiedBy = @Principal
        WHERE WorkTypeId = @WorkTypeId;
    END
    ELSE IF @DisabledReason IS NOT NULL
    BEGIN
        UPDATE toolbelt_core.WorkType
        SET
              DisabledReason = @DisabledReason
            , ModifiedAtUtc = @Now
            , ModifiedBy = @Principal
        WHERE WorkTypeId = @WorkTypeId
          AND ISNULL(DisabledReason, N'') <> ISNULL(@DisabledReason, N'');
    END;

    INSERT INTO #tbx_Core_WorkType_Result
    SELECT *
    FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeId = @WorkTypeId;

    IF @InitialTranCount = 0
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_WorkType_Disable;
        THROW;
    END CATCH;

    IF @Debug > 0
        RAISERROR(N'USP_DisableWorkType: Work Type ist deaktiviert.', 10, 1) WITH NOWAIT;


    IF @ResultTable IS NULL
    BEGIN
        SELECT * FROM #tbx_Core_WorkType_Result;
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51518, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_Core_WorkType_ResultShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists)'
        + N' SELECT WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists FROM #tbx_Core_WorkType_Result;';
    EXEC sys.sp_executesql @InsertSql;
    RETURN 0;

END;
GO
