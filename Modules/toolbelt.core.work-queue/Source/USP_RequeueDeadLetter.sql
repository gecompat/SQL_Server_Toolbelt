SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RequeueDeadLetter]
      @WorkItemId bigint=NULL,@ExpectedRowVersion binary(8)=NULL,@RequeueReason nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RequeueDeadLetter' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus. Callertransaktionen sind nicht erlaubt; verwaltete/gehaltene Arbeit benötigt den geschützten Freigabepfad.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51908,51990-51993', NULL, NULL, NULL, NULL, CAST(N'Fehlende ResultTable-Dependency, ungültige ID, nicht requeuebarer Zustand oder Callertransaktion.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und die vorgesehenen Queue-Autorisierungen; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Bei Fehlern entsteht keine fachliche Statuszeile. Managed-Holds benötigen den geschützten Freigabepfad.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Requeue eines Dead-Letter-Items mit Rowversion-Schutz.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=42,@ExpectedRowVersion=0x0000000000000001;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'QUEUED, CLAIMED, COMPLETED oder FAILED.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EnqueuedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'EnqueuedBy', N'sysname', 0, 0, NULL, CAST(N'Original-Login der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ClaimedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt des Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'ClaimedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Claimers.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'CompletedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt eines erfolgreichen Abschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'CompletedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des erfolgreichen Abschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'FailedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt eines Fehlabschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'FailedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Fehlabschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'FailureCode', N'varchar(64)', 0, 1, NULL, CAST(N'Optionaler stabiler Fehlercode.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'FailureMessage', N'nvarchar(1000)', 0, 1, NULL, CAST(N'Optionale bereinigte Fehlermeldung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'RowVersion', N'binary(8)', 0, 0, NULL, CAST(N'Aktueller Concurrency-Marker.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Monotoner Ownership-Zähler.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'LeaseDurationSeconds', N'int', 0, 1, NULL, CAST(N'Dauer der aktuellen oder letzten Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'LeaseUntilUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Exklusive UTC-Grenze der aktuellen oder letzten Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Zeitpunkt des letzten Heartbeats.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'IsLeaseExpired', N'bit', 0, 0, NULL, CAST(N'1 nur bei aktuell CLAIMED und abgelaufener Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'RecoveryCount', N'bigint', 0, 0, NULL, CAST(N'Kumulierte kontrollierte Recoveries.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 21, N'LastRecoveredAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Zeitpunkt der letzten Recovery.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 22, N'LastRecoveredBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login der letzten Recovery.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 23, N'ExecutionGroup', N'varchar(128)', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 24, N'Priority', N'tinyint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 25, N'ExecutionMode', N'varchar(16)', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 26, N'MaxAttempts', N'tinyint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 27, N'RetryBaseDelaySeconds', N'int', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 28, N'RetryMaxDelaySeconds', N'int', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 29, N'RetryCycleNumber', N'bigint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 30, N'CycleAttemptCount', N'bigint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 31, N'NextAttemptAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 32, N'LastErrorCode', N'varchar(64)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 33, N'LastErrorMessage', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 34, N'LastRetryScheduledAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 35, N'LastRetryScheduledBy', N'sysname', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 36, N'DeadLetteredAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 37, N'DeadLetteredBy', N'sysname', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 38, N'LastRequeuedAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 39, N'LastRequeuedBy', N'sysname', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 40, N'LastRequeueReason', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 41, N'BarrierEpoch', N'bigint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkItemId', N'bigint', 1, 0, N'NULL', CAST(N'Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ExpectedRowVersion', N'binary(8)', 0, 1, N'NULL', CAST(N'Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@RequeueReason', N'nvarchar(1000)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51993,N'USP_RequeueDeadLetter darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND (ManagedHold=1 OR ManagedReservationId IS NOT NULL))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
 IF @WorkItemId IS NULL OR @WorkItemId<=0 THROW 51990,N'@WorkItemId ist erforderlich.',1;
 DECLARE @Now datetime2(7)=SYSUTCDATETIME(),@Mode varchar(16),@Group varchar(128),@Priority tinyint,@Epoch bigint,@InsertResultSql nvarchar(max);
 SELECT TOP (0) v.* INTO #tbx_WorkQueue_RequeueResult FROM toolbelt_core.VW_WorkQueue AS v;
 BEGIN TRANSACTION;
 BEGIN TRY
  IF @ResultTable IS NOT NULL
  BEGIN
   IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51908,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
   EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_RequeueResult',@KeepData=@KeepData,@Debug=@Debug;
  END;
  DECLARE @SchedulerId tinyint; SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
  SELECT @Mode=ExecutionMode,@Group=ExecutionGroup,@Priority=Priority,@Epoch=BarrierEpoch FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND Status='DEAD_LETTER' AND (@ExpectedRowVersion IS NULL OR RowVersion=@ExpectedRowVersion);
  IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND (ManagedHold=1 OR ManagedReservationId IS NOT NULL)) THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Freigabepfad.',2;
  IF @Mode IS NULL THROW 51991,N'Das Item ist nicht requeuebar.',1;
  SET @Epoch=CASE WHEN @Mode='DRAIN_BARRIER' THEN @Epoch+1 ELSE @Epoch END;
  UPDATE toolbelt_core.WorkItem SET Status=CASE WHEN @Mode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,RetryCycleNumber=RetryCycleNumber+1,CycleAttemptCount=0,NextAttemptAtUtc=NULL,BarrierEpoch=@Epoch,ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,FailedAtUtc=NULL,FailedBy=NULL,FailureCode=NULL,FailureMessage=NULL,DeadLetteredAtUtc=NULL,DeadLetteredBy=NULL,LastRequeuedAtUtc=@Now,LastRequeuedBy=ORIGINAL_LOGIN(),LastRequeueReason=@RequeueReason WHERE WorkItemId=@WorkItemId;
  IF @Mode='DRAIN_BARRIER' INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration) SELECT @WorkItemId,@Epoch,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@Group AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
  IF @ResultTable IS NOT NULL
  BEGIN
   INSERT #tbx_WorkQueue_RequeueResult SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
   SET @InsertResultSql=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' SELECT * FROM #tbx_WorkQueue_RequeueResult;';
   EXEC sys.sp_executesql @InsertResultSql;
  END;
  COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
END;
GO
