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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RegisterWorkType' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51500-51518', NULL, NULL, NULL, NULL, CAST(N'Validierungs-, Berechtigungs-, Concurrency- und Dependencyfehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Registriert eine synthetische Procedure ohne Parameter.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName=''demo.noop'', @HandlerSchema=N''dbo'', @HandlerProcedure=N''USP_DemoNoop'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WorkTypeId', N'bigint', NULL, 0, NULL, CAST(N'WorkTypeId.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', NULL, 0, NULL, CAST(N'WorkTypeName.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'HandlerSchema', N'sysname', NULL, 0, NULL, CAST(N'HandlerSchema.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'HandlerProcedure', N'sysname', NULL, 0, NULL, CAST(N'HandlerProcedure.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'HandlerQualifiedName', N'nvarchar(517)', NULL, 0, NULL, CAST(N'HandlerQualifiedName.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ParameterMode', N'varchar(16)', NULL, 0, NULL, CAST(N'ParameterMode.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'PayloadContractJson', N'nvarchar(4000)', NULL, 1, NULL, CAST(N'PayloadContractJson.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'DefaultTimeoutSeconds', N'int', NULL, 0, NULL, CAST(N'DefaultTimeoutSeconds.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'IsIdempotent', N'bit', NULL, 0, NULL, CAST(N'IsIdempotent.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'IsEnabled', N'bit', NULL, 0, NULL, CAST(N'IsEnabled.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'Description', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'Description.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'CreatedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'CreatedAtUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'CreatedBy', N'sysname', NULL, 0, NULL, CAST(N'CreatedBy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'ModifiedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'ModifiedAtUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ModifiedBy', N'sysname', NULL, 0, NULL, CAST(N'ModifiedBy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'DisabledAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'DisabledAtUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'DisabledBy', N'sysname', NULL, 1, NULL, CAST(N'DisabledBy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'DisabledReason', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'DisabledReason.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'RowVersion', N'binary(8)', NULL, 0, NULL, CAST(N'RowVersion.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'HandlerExists', N'bit', NULL, 0, NULL, CAST(N'HandlerExists.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Erforderlicher kanonischer varchar(128)-Schlüssel: LEN 3..128, beginnt a-z, danach ausschließlich a-z/0-9/Punkt/Unterstrich/Bindestrich. Lowercase wird verlangt, nicht hergestellt; keine abschließenden oder doppelten Punkte. Z.B. app.import.rows. NULL/leer ungültig; bestehende Registrierung folgt AllowUpdate/Reactivate/RowVersion.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@HandlerSchema', N'sysname', 1, 0, N'NULL', CAST(N'Einzelner unquotierter Schemaname als sysname in der aktuellen Datenbank, nicht mehrteilig und kein SQL-Ausdruck. NULL/leer oder Schema sys ist unzulässig. Mit HandlerProcedure muss eine vorhandene, nicht von Microsoft ausgelieferte T-SQL- oder CLR-Procedure entstehen; Caller benötigt EXECUTE.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@HandlerProcedure', N'sysname', 1, 0, N'NULL', CAST(N'Einzelner unquotierter Procedurename als sysname in HandlerSchema; keine Argumentliste oder Datenbankqualifikation. NULL/leer/fehlende Procedure bzw. fehlende Metadatensicht/EXECUTE wird abgewiesen. Registrierung führt den Handler nicht aus; der Dispatcher prüft den zum ParameterMode gehörenden Aufrufvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ParameterMode', N'varchar(16)', 0, 1, N'''NONE''', CAST(N'Taxativ nach UPPER-Normalisierung: NONE = Handleraufruf ohne Payload, PayloadContractJson muss NULL sein (Default und NULL); JSON_PAYLOAD = JSON-Payload-Modus, PayloadContractJson muss ein JSON-Objekt sein. Keine weiteren Modi; SQL-Space-Padding gilt beim Vergleich.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@PayloadContractJson', N'nvarchar(4000)', 0, 1, N'NULL', CAST(N'Bei NONE ausschließlich NULL. Bei JSON_PAYLOAD erforderlicher JSON-Objekttext als nvarchar(4000), z.B. N''{"description":"synthetic payload"}''; nach LTRIM normaler Spaces muss { folgen. Leer/Array/Scalar/ungültiges JSON ist ungültig. Die Felder sind deklarative Metadaten; diese Procedure führt weder SQL noch eine allgemeine JSON-Schema-Validierung daraus aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@DefaultTimeoutSeconds', N'int', 0, 1, N'300', CAST(N'Ganzzahl 1..86400 Sekunden einschließlich; Default/NULL=300. Wird als Work-Type-Metadatum gespeichert, nicht als Garantie eines autonomen harten Serverabbruchs. Andere Werte ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@IsIdempotent', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 = Handler nicht als idempotent gekennzeichnet (Default/NULL); 1 = deklarativ idempotent gekennzeichnet. Das Flag implementiert selbst keine Idempotenz oder Exactly-once-Ausführung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Description', N'nvarchar(1000)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Freitext nvarchar(1000), NULL/leer erlaubt; keine besonderen Felder, keine Ausführung, keine automatische Redigierung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@AllowUpdate', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 weist eine abweichende vorhandene Konfiguration ab (Default/NULL); 1 erlaubt deren Update. Ein identischer aktiver Eintrag bleibt auch mit 0 idempotent. Für die Reaktivierung eines deaktivierten Eintrags zusätzlich Reactivate beachten.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Reactivate', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 lässt eine deaktivierte Registrierung nicht still reaktivieren (Default/NULL); 1 erlaubt ihre Reaktivierung. Bei gleichzeitig abweichender Konfiguration ist außerdem AllowUpdate=1 erforderlich.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@ExpectedRowVersion', N'binary(8)', 0, 1, N'NULL', CAST(N'Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Wird nur gegen einen vorhandenen Work Type geprüft; kein Eingabewert für die neue RowVersion.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 14, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 15, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
