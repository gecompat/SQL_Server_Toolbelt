SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RemoveWorkType]
(
      @WorkTypeName       varchar(128) = NULL
    , @ExpectedRowVersion binary(8)    = NULL
    , @AllowDelete        bit          = 0
    , @ResultTable        sysname      = NULL
    , @KeepData           bit          = 0
    , @Debug              tinyint      = 0
    , @Hilfe              bit          = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    SET @AllowDelete = ISNULL(@AllowDelete, 0);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_RemoveWorkType' AS sysname) AS ObjectName
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
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@WorkTypeName', 'varchar(128)', 1, 0, NULL, N'Kanonischer Name des zu entfernenden Work Types.', NULL)
            , ('PARAMETER', 2, N'@ExpectedRowVersion', 'binary(8)', 0, 1, NULL, N'Optionale Optimistic-Concurrency-Prüfung.', NULL)
            , ('PARAMETER', 3, N'@AllowDelete', 'bit', 1, 0, N'0', N'Muss für die irreversible Entfernung ausdrücklich 1 sein.', NULL)
            , ('PARAMETER', 4, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für die entfernte Katalogzeile.', NULL)
            , ('ERROR', 1, N'51523-51528', NULL, NULL, NULL, NULL, N'Pflichtparameter-, Concurrency-, Status-, Freigabe- und Transaktionsfehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Entfernt einen zuvor deaktivierten Work Type.', N'EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName=''demo.noop'', @AllowDelete=1;')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51523, N'@WorkTypeName ist erforderlich.', 1;
    IF @AllowDelete <> 1
        THROW 51527, N'@AllowDelete = 1 ist für die irreversible Entfernung erforderlich.', 1;
    IF XACT_STATE() = -1
        THROW 51528, N'Ein Work Type kann nicht aus einer uncommittable Transaktion entfernt werden.', 1;

    CREATE TABLE #tbx_Core_WorkType_RemoveResultShape
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

    CREATE TABLE #tbx_Core_WorkType_RemoveResult
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

    DECLARE
          @WorkTypeId bigint
        , @CurrentRowVersion binary(8)
        , @CurrentEnabled bit;

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_WorkType_Remove;

    BEGIN TRY
        SELECT
              @WorkTypeId = wt.WorkTypeId
            , @CurrentRowVersion = CONVERT(binary(8), wt.RowVersion)
            , @CurrentEnabled = wt.IsEnabled
        FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
        WHERE wt.WorkTypeName = @WorkTypeName;

        IF @WorkTypeId IS NULL
            THROW 51524, N'Der Work Type ist nicht registriert.', 1;
        IF @ExpectedRowVersion IS NOT NULL AND @ExpectedRowVersion <> @CurrentRowVersion
            THROW 51525, N'@ExpectedRowVersion stimmt nicht mit dem aktuellen Work Type überein.', 1;
        IF @CurrentEnabled = 1
            THROW 51526, N'Der Work Type muss vor der Entfernung deaktiviert werden.', 1;

        INSERT INTO #tbx_Core_WorkType_RemoveResult
        SELECT *
        FROM toolbelt_core.VW_WorkTypes
        WHERE WorkTypeId = @WorkTypeId;

        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
                THROW 51518, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = @ResultTable
                , @LikeTable = N'#tbx_Core_WorkType_RemoveResultShape'
                , @KeepData = @KeepData;

            DECLARE @InsertSql nvarchar(max) =
                N'INSERT INTO ' + QUOTENAME(@ResultTable)
                + N' (WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists)'
                + N' SELECT WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists FROM #tbx_Core_WorkType_RemoveResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;

        DELETE FROM toolbelt_core.WorkType
        WHERE WorkTypeId = @WorkTypeId;

        IF @InitialTranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_WorkType_Remove;
        THROW;
    END CATCH;

    IF @Debug > 0
        RAISERROR(N'USP_RemoveWorkType: Der deaktivierte Work Type wurde entfernt.', 10, 1) WITH NOWAIT;

    IF @ResultTable IS NULL
        SELECT * FROM #tbx_Core_WorkType_RemoveResult;

    RETURN 0;
END;
GO
