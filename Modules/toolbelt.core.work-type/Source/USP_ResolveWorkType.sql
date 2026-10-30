SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ResolveWorkType]
(
      @WorkTypeName              varchar(128) = NULL
    , @RequireEnabled            bit          = 1
    , @RequireExecutableByCaller bit          = 1
    , @RequiredPermission        varchar(32)  = NULL
    , @SuppressResult            bit          = 0
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_ResolveWorkType' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName=''demo.noop'';' AS nvarchar(max))),
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
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RequireEnabled', N'bit', 0, 1, N'1', CAST(N'Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@RequireExecutableByCaller', N'bit', 0, 1, N'1', CAST(N'Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@RequiredPermission', N'varchar(32)', 0, 1, N'NULL', CAST(N'Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@SuppressResult', N'bit', 0, 0, N'0', CAST(N'Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597).' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @RequiredPermission IS NOT NULL AND @RequiredPermission COLLATE Latin1_General_100_BIN2 NOT IN('ENQUEUE','CLAIM','EXECUTE_NEW_SESSION')
        THROW 51595,N'Die angeforderte Work-Type-Aktion ist ungültig.',1;
    IF @SuppressResult IS NULL OR (@SuppressResult=1 AND @ResultTable IS NOT NULL)
        THROW 51597,N'SuppressResult ist ungültig oder mit ResultTable kombiniert.',1;
    IF @RequiredPermission IS NOT NULL
    BEGIN
        DECLARE @PermissionWorkTypeId bigint;
        -- In einer Workertransaktion bleibt die Policy-/Registrierungsbindung
        -- bis zum Handlerabschluss stabil. Ohne Caller-TX nur Statementscope.
        SELECT @PermissionWorkTypeId=WorkTypeId FROM toolbelt_core.WorkType WITH(HOLDLOCK) WHERE WorkTypeName=@WorkTypeName;
        IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@PermissionWorkTypeId,@RequiredPermission) WHERE IsAllowed=1)
            THROW 51596,N'Die erforderliche Work-Type-Autorität fehlt.',1;
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


    IF @SuppressResult=1 RETURN 0;
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
