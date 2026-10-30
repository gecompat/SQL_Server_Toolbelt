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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RemoveWorkType' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51523-51528', NULL, NULL, NULL, NULL, CAST(N'Pflichtparameter-, Concurrency-, Status-, Freigabe- und Transaktionsfehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Entfernt einen zuvor deaktivierten Work Type.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName=''demo.noop'', @AllowDelete=1;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WorkTypeId', N'bigint', NULL, 0, NULL, CAST(N'WorkTypeId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', NULL, 0, NULL, CAST(N'WorkTypeName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'HandlerSchema', N'sysname', NULL, 0, NULL, CAST(N'HandlerSchema: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'HandlerProcedure', N'sysname', NULL, 0, NULL, CAST(N'HandlerProcedure: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'HandlerQualifiedName', N'nvarchar(517)', NULL, 0, NULL, CAST(N'HandlerQualifiedName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ParameterMode', N'varchar(16)', NULL, 0, NULL, CAST(N'ParameterMode: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'PayloadContractJson', N'nvarchar(4000)', NULL, 1, NULL, CAST(N'PayloadContractJson: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'DefaultTimeoutSeconds', N'int', NULL, 0, NULL, CAST(N'DefaultTimeoutSeconds: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'IsIdempotent', N'bit', NULL, 0, NULL, CAST(N'IsIdempotent: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'IsEnabled', N'bit', NULL, 0, NULL, CAST(N'IsEnabled: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'Description', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'Description: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'CreatedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'CreatedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'CreatedBy', N'sysname', NULL, 0, NULL, CAST(N'CreatedBy: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'ModifiedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'ModifiedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ModifiedBy', N'sysname', NULL, 0, NULL, CAST(N'ModifiedBy: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'DisabledAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'DisabledAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'DisabledBy', N'sysname', NULL, 1, NULL, CAST(N'DisabledBy: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'DisabledReason', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'DisabledReason: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'RowVersion', N'binary(8)', NULL, 0, NULL, CAST(N'RowVersion: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'HandlerExists', N'bit', NULL, 0, NULL, CAST(N'HandlerExists: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss bereits deaktiviert sein; aktive Einträge sind nicht entfernbar.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ExpectedRowVersion', N'binary(8)', 0, 1, N'NULL', CAST(N'Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@AllowDelete', N'bit', 1, 1, N'0', CAST(N'Taxativ für bit: 1 ist die ausdrückliche Zustimmung zum irreversiblen Entfernen; 0 (Default) und NULL werden vor der Entfernung abgewiesen. Der Work Type muss zusätzlich deaktiviert sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
