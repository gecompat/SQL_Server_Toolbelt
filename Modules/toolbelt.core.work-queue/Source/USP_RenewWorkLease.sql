SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RenewWorkLease]
(
      @WorkItemId bigint           = NULL
    , @ClaimToken uniqueidentifier = NULL
    , @ResultTable sysname         = NULL
    , @KeepData    bit             = 0
    , @Debug       tinyint         = 0
    , @Hilfe       bit             = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RenewWorkLease' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Aktuelle Ownership-Generation.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'LeaseUntilUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Neue exklusive UTC-Grenze der Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Engine-Zeit dieses Heartbeats.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51950-51954', NULL, NULL, NULL, NULL, CAST(N'Caller-Transaktions-, Parameter-, Ownership-, Ablauf- oder ResultTable-Fehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Verlängert einen synthetischen aktiven Claim.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken=''00000000-0000-0000-0000-000000000001'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkItemId', N'bigint', 1, 0, N'NULL', CAST(N'Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ClaimToken', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51950,N'USP_RenewWorkLease darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF @WorkItemId IS NULL OR @WorkItemId<=0 OR @ClaimToken IS NULL THROW 51951,N'@WorkItemId und @ClaimToken sind erforderlich.',1;

    CREATE TABLE #tbx_WorkQueue_LeaseShape(WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
    CREATE TABLE #tbx_WorkQueue_LeaseResult(WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
    DECLARE @NowUtc datetime2(7),@Status varchar(16),@CurrentToken uniqueidentifier,@LeaseUntilUtc datetime2(7),@LeaseDurationSeconds int;
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @Status=Status,@CurrentToken=ClaimToken,@LeaseUntilUtc=LeaseUntilUtc,@LeaseDurationSeconds=LeaseDurationSeconds
        FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId;
        IF @Status IS NULL THROW 51952,N'Das Work Item existiert nicht.',1;
        IF @Status<>'CLAIMED' OR @CurrentToken<>@ClaimToken THROW 51952,N'Der Claim ist nicht aktiv oder @ClaimToken besitzt ihn nicht.',2;
        SET @NowUtc=SYSUTCDATETIME();
        IF @LeaseUntilUtc<=@NowUtc THROW 51953,N'Die Lease ist bereits abgelaufen und kann nicht wiederbelebt werden.',1;
        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51954,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_LeaseShape',@KeepData=@KeepData;
        END;
        UPDATE toolbelt_core.WorkItem SET LastHeartbeatAtUtc=@NowUtc,LeaseUntilUtc=DATEADD(SECOND,@LeaseDurationSeconds,@NowUtc)
        OUTPUT inserted.WorkItemId,inserted.ClaimGeneration,inserted.LeaseUntilUtc,inserted.LastHeartbeatAtUtc INTO #tbx_WorkQueue_LeaseResult
        WHERE WorkItemId=@WorkItemId AND Status='CLAIMED' AND ClaimToken=@ClaimToken AND LeaseUntilUtc>@NowUtc;
        IF @@ROWCOUNT<>1 THROW 51952,N'Der Claim-Zustand hat sich konkurrierend verändert.',3;
        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc) SELECT WorkItemId,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc FROM #tbx_WorkQueue_LeaseResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_RenewWorkLease: aktive Lease verlängert.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_LeaseResult;
    RETURN 0;
END;
GO
