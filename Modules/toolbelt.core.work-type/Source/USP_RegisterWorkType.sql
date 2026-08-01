SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RegisterWorkType]
(
      @WorkTypeName          varchar(128)   = NULL
    , @HandlerSchema         sysname        = NULL
    , @HandlerProcedure      sysname        = NULL
    , @ParameterMode         varchar(16)    = 'NONE'
    , @PayloadContractJson   nvarchar(4000) = NULL
    , @DefaultTimeoutSeconds int            = 300
    , @IsIdempotent          bit            = 0
    , @Description           nvarchar(1000) = NULL
    , @AllowUpdate           bit            = 0
    , @Reactivate            bit            = 0
    , @ExpectedRowVersion    binary(8)      = NULL
    , @ResultTable           sysname        = NULL
    , @KeepData              bit            = 0
    , @Debug                 tinyint        = 0
    , @Hilfe                 bit            = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    SET @ParameterMode = UPPER(ISNULL(@ParameterMode, 'NONE'));
    SET @DefaultTimeoutSeconds = ISNULL(@DefaultTimeoutSeconds, 300);
    SET @IsIdempotent = ISNULL(@IsIdempotent, 0);
    SET @AllowUpdate = ISNULL(@AllowUpdate, 0);
    SET @Reactivate = ISNULL(@Reactivate, 0);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_RegisterWorkType' AS sysname) AS ObjectName
            , v.Section
            , v.Ordinal
            , v.ItemName
            , v.SqlDataType
            , v.IsRequired
            , v.IsNullable
            , v.DefaultValue
            , v.Description
            , v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@WorkTypeName', 'varchar(128)', 1, 0, NULL, N'Kanonischer kleingeschriebener Work-Type-Name.', NULL)
            , ('PARAMETER', 2, N'@HandlerSchema', 'sysname', 1, 0, NULL, N'Schema der vorhandenen Zielprocedure in derselben Datenbank.', NULL)
            , ('PARAMETER', 3, N'@HandlerProcedure', 'sysname', 1, 0, NULL, N'Name der vorhandenen Zielprocedure.', NULL)
            , ('PARAMETER', 4, N'@ParameterMode', 'varchar(16)', 0, 0, N'NONE', N'NONE oder JSON_PAYLOAD.', NULL)
            , ('PARAMETER', 5, N'@PayloadContractJson', 'nvarchar(4000)', 0, 1, NULL, N'JSON-Objekt mit deklarativem Payloadvertrag; wird nicht als Code ausgeführt.', NULL)
            , ('PARAMETER', 6, N'@AllowUpdate', 'bit', 0, 0, N'0', N'Erlaubt eine Änderung einer vorhandenen Registrierung.', NULL)
            , ('PARAMETER', 7, N'@Reactivate', 'bit', 0, 0, N'0', N'Reaktiviert einen deaktivierten Work Type.', NULL)
            , ('PARAMETER', 8, N'@ExpectedRowVersion', 'binary(8)', 0, 1, NULL, N'Optionale Optimistic-Concurrency-Prüfung.', NULL)
            , ('PARAMETER', 9, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für die Ergebniszeile.', NULL)
            , ('ERROR', 1, N'51500-51518', NULL, NULL, NULL, NULL, N'Validierungs-, Berechtigungs-, Concurrency- und Dependencyfehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Registriert eine synthetische Procedure ohne Parameter.', N'EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName=''demo.noop'', @HandlerSchema=N''dbo'', @HandlerProcedure=N''USP_DemoNoop'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF @WorkTypeName IS NULL
       OR LEN(@WorkTypeName) NOT BETWEEN 3 AND 128
       OR @WorkTypeName <> LOWER(@WorkTypeName) COLLATE Latin1_General_100_BIN2
       OR @WorkTypeName NOT LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
       OR @WorkTypeName LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
       OR @WorkTypeName LIKE '.%'
       OR @WorkTypeName LIKE '%.'
       OR @WorkTypeName LIKE '%..%'
        THROW 51500, N'@WorkTypeName muss kanonisch kleingeschrieben sein und darf nur a-z, 0-9, Punkt, Unterstrich und Bindestrich enthalten.', 1;
    IF NULLIF(@HandlerSchema, N'') IS NULL OR NULLIF(@HandlerProcedure, N'') IS NULL
        THROW 51501, N'@HandlerSchema und @HandlerProcedure sind erforderlich.', 1;
    IF @HandlerSchema = N'sys'
        THROW 51502, N'Systemprocedures dürfen nicht als Work Type registriert werden.', 1;
    IF @ParameterMode NOT IN ('NONE', 'JSON_PAYLOAD')
        THROW 51503, N'@ParameterMode muss NONE oder JSON_PAYLOAD sein.', 1;
    IF @ParameterMode = 'NONE' AND @PayloadContractJson IS NOT NULL
        THROW 51504, N'@PayloadContractJson ist bei ParameterMode NONE nicht zulässig.', 1;
    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @PayloadContractJson IS NULL
           OR ISJSON(@PayloadContractJson) <> 1
           OR LEFT(LTRIM(@PayloadContractJson), 1) <> N'{'
       )
        THROW 51505, N'@PayloadContractJson muss bei JSON_PAYLOAD ein JSON-Objekt sein.', 1;
    IF @DefaultTimeoutSeconds NOT BETWEEN 1 AND 86400
        THROW 51506, N'@DefaultTimeoutSeconds muss zwischen 1 und 86400 liegen.', 1;

    DECLARE @QualifiedName nvarchar(517) = QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure);
    DECLARE @HandlerObjectId int = COALESCE(OBJECT_ID(@QualifiedName, N'P'), OBJECT_ID(@QualifiedName, N'PC'));
    IF @HandlerObjectId IS NULL
        THROW 51507, N'Die Zielprocedure existiert in der aktuellen Datenbank nicht.', 1;
    IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = @HandlerObjectId AND is_ms_shipped = 1)
        THROW 51508, N'Als Work Type sind keine von Microsoft ausgelieferten Procedures zulässig.', 1;
    IF ISNULL(HAS_PERMS_BY_NAME(@QualifiedName, N'OBJECT', N'EXECUTE'), 0) <> 1
        THROW 51509, N'Der registrierende Principal besitzt kein EXECUTE auf die Zielprocedure.', 1;


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


    DECLARE @Now datetime2(7) = SYSUTCDATETIME();
    DECLARE @Principal sysname = ORIGINAL_LOGIN();
    DECLARE @WorkTypeId bigint;
    DECLARE @CurrentRowVersion binary(8);
    DECLARE @CurrentEnabled bit;
    DECLARE @CurrentHandlerSchema sysname;
    DECLARE @CurrentHandlerProcedure sysname;
    DECLARE @CurrentParameterMode varchar(16);
    DECLARE @CurrentPayloadContractJson nvarchar(4000);
    DECLARE @CurrentTimeout int;
    DECLARE @CurrentIdempotent bit;
    DECLARE @CurrentDescription nvarchar(1000);
    DECLARE @Changed bit = 0;

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_WorkType_Register;

    BEGIN TRY

    SELECT
          @WorkTypeId = wt.WorkTypeId
        , @CurrentRowVersion = CONVERT(binary(8), wt.RowVersion)
        , @CurrentEnabled = wt.IsEnabled
        , @CurrentHandlerSchema = wt.HandlerSchema
        , @CurrentHandlerProcedure = wt.HandlerProcedure
        , @CurrentParameterMode = wt.ParameterMode
        , @CurrentPayloadContractJson = wt.PayloadContractJson
        , @CurrentTimeout = wt.DefaultTimeoutSeconds
        , @CurrentIdempotent = wt.IsIdempotent
        , @CurrentDescription = wt.Description
    FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @WorkTypeId IS NULL
    BEGIN
        INSERT INTO toolbelt_core.WorkType
        (
              WorkTypeName, HandlerSchema, HandlerProcedure, ParameterMode
            , PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent
            , IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy
        )
        VALUES
        (
              @WorkTypeName, @HandlerSchema, @HandlerProcedure, @ParameterMode
            , @PayloadContractJson, @DefaultTimeoutSeconds, @IsIdempotent
            , 1, @Description, @Now, @Principal, @Now, @Principal
        );
        SET @WorkTypeId = SCOPE_IDENTITY();
        SET @Changed = 1;
    END
    ELSE
    BEGIN
        IF @ExpectedRowVersion IS NOT NULL AND @ExpectedRowVersion <> @CurrentRowVersion
            THROW 51510, N'@ExpectedRowVersion stimmt nicht mit dem aktuellen Work Type überein.', 1;

        DECLARE @ConfigurationDiffers bit = CONVERT(bit, CASE WHEN
               @CurrentHandlerSchema <> @HandlerSchema
            OR @CurrentHandlerProcedure <> @HandlerProcedure
            OR @CurrentParameterMode <> @ParameterMode
            OR ISNULL(@CurrentPayloadContractJson, N'') <> ISNULL(@PayloadContractJson, N'')
            OR @CurrentTimeout <> @DefaultTimeoutSeconds
            OR @CurrentIdempotent <> @IsIdempotent
            OR ISNULL(@CurrentDescription, N'') <> ISNULL(@Description, N'')
            THEN 1 ELSE 0 END);

        IF @ConfigurationDiffers = 1 AND @AllowUpdate = 0
            THROW 51511, N'Der Work Type existiert mit abweichender Konfiguration; @AllowUpdate = 1 ist erforderlich.', 1;
        IF @CurrentEnabled = 0 AND @Reactivate = 0
            THROW 51512, N'Der Work Type ist deaktiviert; @Reactivate = 1 ist erforderlich.', 1;

        IF @ConfigurationDiffers = 1 OR @CurrentEnabled = 0
        BEGIN
            UPDATE toolbelt_core.WorkType
            SET
                  HandlerSchema = @HandlerSchema
                , HandlerProcedure = @HandlerProcedure
                , ParameterMode = @ParameterMode
                , PayloadContractJson = @PayloadContractJson
                , DefaultTimeoutSeconds = @DefaultTimeoutSeconds
                , IsIdempotent = @IsIdempotent
                , IsEnabled = 1
                , Description = @Description
                , ModifiedAtUtc = @Now
                , ModifiedBy = @Principal
                , DisabledAtUtc = NULL
                , DisabledBy = NULL
                , DisabledReason = NULL
            WHERE WorkTypeId = @WorkTypeId;
            SET @Changed = 1;
        END;
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
            ROLLBACK TRANSACTION TBX_WorkType_Register;
        THROW;
    END CATCH;

    IF @Debug > 0
    BEGIN
        DECLARE @ChangedForMessage int = CONVERT(int, @Changed);
        RAISERROR(N'USP_RegisterWorkType: Registrierung verarbeitet; Änderung=%d.', 10, 1, @ChangedForMessage) WITH NOWAIT;
    END;


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
