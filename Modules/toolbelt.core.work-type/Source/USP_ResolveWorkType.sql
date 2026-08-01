SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ResolveWorkType]
(
      @WorkTypeName              varchar(128) = NULL
    , @RequireEnabled            bit          = 1
    , @RequireExecutableByCaller bit          = 1
    , @ResultTable               sysname      = NULL
    , @KeepData                  bit          = 0
    , @Debug                     tinyint      = 0
    , @Hilfe                     bit          = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @RequireEnabled = ISNULL(@RequireEnabled, 1);
    SET @RequireExecutableByCaller = ISNULL(@RequireExecutableByCaller, 1);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_ResolveWorkType' AS sysname) AS ObjectName
            , CAST('DESCRIPTION' AS varchar(32)) AS Section
            , 1 AS Ordinal
            , CAST(NULL AS sysname) AS ItemName
            , CAST(NULL AS varchar(256)) AS SqlDataType
            , CAST(NULL AS bit) AS IsRequired
            , CAST(NULL AS bit) AS IsNullable
            , CAST(NULL AS nvarchar(4000)) AS DefaultValue
            , CAST(N'Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.' AS nvarchar(max)) AS Description
            , CAST(N'EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName=''demo.noop'';' AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51530, N'@WorkTypeName ist erforderlich.', 1;


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


    INSERT INTO #tbx_Core_WorkType_Result
    SELECT *
    FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeName = @WorkTypeName;

    IF @@ROWCOUNT = 0
        THROW 51531, N'Der Work Type ist nicht registriert.', 1;

    DECLARE @Enabled bit;
    DECLARE @HandlerExists bit;
    DECLARE @QualifiedName nvarchar(517);
    SELECT
          @Enabled = IsEnabled
        , @HandlerExists = HandlerExists
        , @QualifiedName = HandlerQualifiedName
    FROM #tbx_Core_WorkType_Result;

    IF @RequireEnabled = 1 AND @Enabled = 0
        THROW 51532, N'Der Work Type ist deaktiviert.', 1;
    IF @HandlerExists = 0
        THROW 51533, N'Die registrierte Zielprocedure existiert nicht mehr.', 1;
    IF @RequireExecutableByCaller = 1
       AND ISNULL(HAS_PERMS_BY_NAME(@QualifiedName, N'OBJECT', N'EXECUTE'), 0) <> 1
        THROW 51534, N'Der aktuelle Principal besitzt kein EXECUTE auf die Zielprocedure.', 1;

    IF @Debug > 0
        RAISERROR(N'USP_ResolveWorkType: Work Type wurde aufgelöst.', 10, 1) WITH NOWAIT;


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
