SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ExecuteWorkTypeInNewSession]
(
      @WorkTypeName  varchar(128) = NULL
    , @PayloadJson   nvarchar(max) = NULL
    , @ExecutionId   uniqueidentifier = NULL
    , @CorrelationId uniqueidentifier = NULL
    , @Actor         nvarchar(256) = NULL
    , @Tenant        nvarchar(256) = NULL
    , @ResultTable   sysname = NULL
    , @KeepData      bit = 0
    , @SuppressResult bit = 0
    , @Debug         tinyint = 0
    , @Hilfe         bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @KeepData = ISNULL(@KeepData, 0);
    SET @SuppressResult = ISNULL(@SuppressResult, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_ExecuteWorkTypeInNewSession' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51610-51620,51628-51629', NULL, NULL, NULL, NULL, CAST(N'Provider-, Work-Type-, Payload- und ResultTable-Fehler; 51628: Payloadlimit, 51629: fehlende lokale EXECUTE_NEW_SESSION-Policy. Remote ist zusätzlich Handler-EXECUTE erforderlich.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Führt einen NONE-Handler in einer neuen Session aus.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName=''demo.noop'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'ExecutedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'ExecutedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ProviderName', N'varchar(32)', NULL, 0, NULL, CAST(N'ProviderName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'LinkedServerName', N'sysname', NULL, 0, NULL, CAST(N'LinkedServerName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'TargetDatabaseName', N'sysname', NULL, 0, NULL, CAST(N'TargetDatabaseName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'WorkTypeName', N'varchar(128)', NULL, 0, NULL, CAST(N'WorkTypeName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ParameterMode', N'varchar(16)', NULL, 0, NULL, CAST(N'ParameterMode: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'CallerSessionId', N'int', NULL, 0, NULL, CAST(N'CallerSessionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'RemoteSessionId', N'int', NULL, 0, NULL, CAST(N'RemoteSessionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'CallerXactState', N'smallint', NULL, 0, NULL, CAST(N'CallerXactState: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'CallerTransactionCount', N'int', NULL, 0, NULL, CAST(N'CallerTransactionCount: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'ExecutionId', N'uniqueidentifier', NULL, 0, NULL, CAST(N'ExecutionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'CorrelationId', N'uniqueidentifier', NULL, 0, NULL, CAST(N'CorrelationId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'HandlerReturnCode', N'int', NULL, 1, NULL, CAST(N'HandlerReturnCode: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'RemoteStartedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'RemoteStartedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'RemoteCompletedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'RemoteCompletedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'DurationMilliseconds', N'decimal(19,3)', NULL, 0, NULL, CAST(N'DurationMilliseconds: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@PayloadJson', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExecutionId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@CorrelationId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Actor', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Tenant', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@SuppressResult', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 liefert die Infrastruktur-Ergebniszeile oder routet sie nach ResultTable (Default/NULL); 1 unterdrückt nur diese Ausgabe nach erfolgreichem Remote-Handlerlauf und Returncodeprüfung. Mit nicht-NULL ResultTable unvereinbar.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51610, N'@WorkTypeName ist erforderlich.', 1;
    IF @ResultTable IS NOT NULL AND XACT_STATE() = -1
        THROW 51611, N'@ResultTable ist in einer uncommittable Caller-Transaktion nicht zulässig.', 1;
    IF @SuppressResult = 1 AND @ResultTable IS NOT NULL
        THROW 51620, N'@SuppressResult = 1 kann nicht mit @ResultTable kombiniert werden.', 1;

    DECLARE @ParameterMode varchar(16);
    DECLARE @WorkTypeEnabled bit,@WorkTypeId bigint;
    SELECT
          @WorkTypeId=wt.WorkTypeId
        , @ParameterMode = wt.ParameterMode
        , @WorkTypeEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @ParameterMode IS NULL
        THROW 51615, N'Der Work Type ist nicht registriert.', 1;
    IF @WorkTypeEnabled = 0
        THROW 51616, N'Der Work Type ist deaktiviert.', 1;
    IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@WorkTypeId,'EXECUTE_NEW_SESSION') WHERE IsAllowed=1)
        THROW 51629,N'Keine lokale Startberechtigung für diesen Work Type.',1;
    IF DATALENGTH(@PayloadJson)>1048576 THROW 51628,N'Payload überschreitet 1 MiB.',1;
    IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
        THROW 51617, N'Der Work Type akzeptiert keine JSON-Payload.', 1;
    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @PayloadJson IS NULL
           OR ISJSON(@PayloadJson) <> 1
           OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
       )
        THROW 51618, N'Der Work Type benötigt eine JSON-Objekt-Payload.', 1;

    DECLARE
          @LinkedServerName sysname
        , @ProviderEnabled bit
        , @LinkedServerExists bit
        , @RpcOutEnabled bit
        , @PromotionEnabled bit;

    SELECT
          @LinkedServerName = p.LinkedServerName
        , @ProviderEnabled = p.IsEnabled
        , @LinkedServerExists = p.LinkedServerExists
        , @RpcOutEnabled = p.RpcOutEnabled
        , @PromotionEnabled = p.RemoteProcTransactionPromotionEnabled
    FROM toolbelt_core.VW_SecondSessionProviders AS p
    WHERE p.ProviderName = 'loopback';

    IF @LinkedServerName IS NULL
        THROW 51612, N'Es ist kein Loopback-Second-Session-Provider konfiguriert.', 1;
    IF @ProviderEnabled = 0
        THROW 51613, N'Der Loopback-Second-Session-Provider ist deaktiviert.', 1;
    IF @LinkedServerExists = 0 OR @RpcOutEnabled = 0 OR @PromotionEnabled = 1
        THROW 51614, N'Die aktuelle Linked-Server-Konfiguration verletzt den Second-Session-Vertrag.', 1;

    DECLARE
          @CurrentExecutionId uniqueidentifier
        , @CurrentCorrelationId uniqueidentifier
        , @CurrentActor nvarchar(256)
        , @CurrentTenant nvarchar(256);

    SELECT
          @CurrentExecutionId = c.ExecutionId
        , @CurrentCorrelationId = c.CorrelationId
        , @CurrentActor = c.Actor
        , @CurrentTenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    SET @ExecutionId = COALESCE(@ExecutionId, @CurrentExecutionId, NEWID());
    SET @CorrelationId = COALESCE(@CorrelationId, @CurrentCorrelationId, @ExecutionId);
    SET @Actor = COALESCE(@Actor, @CurrentActor, CONVERT(nvarchar(256), ORIGINAL_LOGIN()));
    SET @Tenant = COALESCE(@Tenant, @CurrentTenant);

    DECLARE @TargetDatabaseName sysname = DB_NAME();
    DECLARE @CallerSessionId int = @@SPID;
    DECLARE @CallerXactState smallint = CONVERT(smallint, XACT_STATE());
    DECLARE @CallerTransactionCount int = @@TRANCOUNT;
    DECLARE @RemoteSessionId int;
    DECLARE @HandlerReturnCode int;
    DECLARE @RemoteStartedAtUtc datetime2(7);
    DECLARE @RemoteCompletedAtUtc datetime2(7);
    DECLARE @ProviderReturnCode int;

    DECLARE @RpcSql nvarchar(max) =
        N'EXEC @ProviderReturnCode = '
        + QUOTENAME(@LinkedServerName) + N'.' + QUOTENAME(@TargetDatabaseName)
        + N'.[toolbelt_core].[USP_DispatchWorkType]'
        + N' @WorkTypeName=@WorkTypeName,'
        + N' @PayloadJson=@PayloadJson,'
        + N' @ExecutionId=@ExecutionId,'
        + N' @CorrelationId=@CorrelationId,'
        + N' @Actor=@Actor,'
        + N' @Tenant=@Tenant,'
        + N' @RemoteSessionId=@RemoteSessionId OUTPUT,'
        + N' @HandlerReturnCode=@HandlerReturnCode OUTPUT,'
        + N' @StartedAtUtc=@RemoteStartedAtUtc OUTPUT,'
        + N' @CompletedAtUtc=@RemoteCompletedAtUtc OUTPUT'
        + N' WITH RESULT SETS NONE;';

    EXEC sys.sp_executesql
          @RpcSql
        , N'@WorkTypeName varchar(128), @PayloadJson nvarchar(max), @ExecutionId uniqueidentifier, @CorrelationId uniqueidentifier, @Actor nvarchar(256), @Tenant nvarchar(256), @RemoteSessionId int OUTPUT, @HandlerReturnCode int OUTPUT, @RemoteStartedAtUtc datetime2(7) OUTPUT, @RemoteCompletedAtUtc datetime2(7) OUTPUT, @ProviderReturnCode int OUTPUT'
        , @WorkTypeName = @WorkTypeName
        , @PayloadJson = @PayloadJson
        , @ExecutionId = @ExecutionId
        , @CorrelationId = @CorrelationId
        , @Actor = @Actor
        , @Tenant = @Tenant
        , @RemoteSessionId = @RemoteSessionId OUTPUT
        , @HandlerReturnCode = @HandlerReturnCode OUTPUT
        , @RemoteStartedAtUtc = @RemoteStartedAtUtc OUTPUT
        , @RemoteCompletedAtUtc = @RemoteCompletedAtUtc OUTPUT
        , @ProviderReturnCode = @ProviderReturnCode OUTPUT;

    IF ISNULL(@ProviderReturnCode, -1) <> 0
        THROW 51619, N'Der Remote-Dispatcher lieferte keinen erfolgreichen Returncode.', 1;

    DECLARE @DurationMilliseconds decimal(19,3) =
        CONVERT(decimal(19,3), DATEDIFF_BIG(MICROSECOND, @RemoteStartedAtUtc, @RemoteCompletedAtUtc) / 1000.0);

    IF @SuppressResult = 1
    BEGIN
        IF @Debug > 0
            RAISERROR(N'USP_ExecuteWorkTypeInNewSession: Work Type wurde ohne Infrastruktur-Resultset ausgeführt.', 10, 1) WITH NOWAIT;
        RETURN 0;
    END;

    IF @ResultTable IS NULL
    BEGIN
        SELECT
              SYSUTCDATETIME() AS ExecutedAtUtc
            , CAST('loopback' AS varchar(32)) AS ProviderName
            , @LinkedServerName AS LinkedServerName
            , @TargetDatabaseName AS TargetDatabaseName
            , @WorkTypeName AS WorkTypeName
            , @ParameterMode AS ParameterMode
            , @CallerSessionId AS CallerSessionId
            , @RemoteSessionId AS RemoteSessionId
            , @CallerXactState AS CallerXactState
            , @CallerTransactionCount AS CallerTransactionCount
            , @ExecutionId AS ExecutionId
            , @CorrelationId AS CorrelationId
            , @HandlerReturnCode AS HandlerReturnCode
            , @RemoteStartedAtUtc AS RemoteStartedAtUtc
            , @RemoteCompletedAtUtc AS RemoteCompletedAtUtc
            , @DurationMilliseconds AS DurationMilliseconds;
        RETURN 0;
    END;

    CREATE TABLE #tbx_SecondSessionResultShape
    (
          ExecutedAtUtc datetime2(7) NOT NULL
        , ProviderName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL
        , LinkedServerName sysname NOT NULL
        , TargetDatabaseName sysname NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , ParameterMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , CallerSessionId int NOT NULL
        , RemoteSessionId int NOT NULL
        , CallerXactState smallint NOT NULL
        , CallerTransactionCount int NOT NULL
        , ExecutionId uniqueidentifier NOT NULL
        , CorrelationId uniqueidentifier NOT NULL
        , HandlerReturnCode int NULL
        , RemoteStartedAtUtc datetime2(7) NOT NULL
        , RemoteCompletedAtUtc datetime2(7) NOT NULL
        , DurationMilliseconds decimal(19,3) NOT NULL
    );

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51619, N'Für @ResultTable fehlt toolbelt.core.result-table.', 2;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_SecondSessionResultShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (ExecutedAtUtc, ProviderName, LinkedServerName, TargetDatabaseName, WorkTypeName, ParameterMode, CallerSessionId, RemoteSessionId, CallerXactState, CallerTransactionCount, ExecutionId, CorrelationId, HandlerReturnCode, RemoteStartedAtUtc, RemoteCompletedAtUtc, DurationMilliseconds)'
        + N' VALUES (SYSUTCDATETIME(), ''loopback'', @LinkedServerName, @TargetDatabaseName, @WorkTypeName, @ParameterMode, @CallerSessionId, @RemoteSessionId, @CallerXactState, @CallerTransactionCount, @ExecutionId, @CorrelationId, @HandlerReturnCode, @RemoteStartedAtUtc, @RemoteCompletedAtUtc, @DurationMilliseconds);';

    EXEC sys.sp_executesql
          @InsertSql
        , N'@LinkedServerName sysname, @TargetDatabaseName sysname, @WorkTypeName varchar(128), @ParameterMode varchar(16), @CallerSessionId int, @RemoteSessionId int, @CallerXactState smallint, @CallerTransactionCount int, @ExecutionId uniqueidentifier, @CorrelationId uniqueidentifier, @HandlerReturnCode int, @RemoteStartedAtUtc datetime2(7), @RemoteCompletedAtUtc datetime2(7), @DurationMilliseconds decimal(19,3)'
        , @LinkedServerName = @LinkedServerName
        , @TargetDatabaseName = @TargetDatabaseName
        , @WorkTypeName = @WorkTypeName
        , @ParameterMode = @ParameterMode
        , @CallerSessionId = @CallerSessionId
        , @RemoteSessionId = @RemoteSessionId
        , @CallerXactState = @CallerXactState
        , @CallerTransactionCount = @CallerTransactionCount
        , @ExecutionId = @ExecutionId
        , @CorrelationId = @CorrelationId
        , @HandlerReturnCode = @HandlerReturnCode
        , @RemoteStartedAtUtc = @RemoteStartedAtUtc
        , @RemoteCompletedAtUtc = @RemoteCompletedAtUtc
        , @DurationMilliseconds = @DurationMilliseconds;

    IF @Debug > 0
        RAISERROR(N'USP_ExecuteWorkTypeInNewSession: Work Type wurde in einer zweiten Session ausgeführt.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
