SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ScheduleWorkRetry]
      @WorkItemId bigint=NULL,@ClaimToken uniqueidentifier=NULL,@FailureCode varchar(64)=NULL,@FailureMessage nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_ScheduleWorkRetry' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Plant anhand eines aktiven Claim-Tokens den nächsten Retry oder verschiebt nach ausgeschöpften Versuchen in Dead Letter.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51985-51989', NULL, NULL, NULL, NULL, CAST(N'Fehlende Argumente, ungültige Fehlerdaten, inaktiver Claim oder nicht unterstütztes ResultTable.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE sowie die Queue-Claim-Autorisierung des aufrufenden Pfades.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Diese Version unterstützt kein ResultTable-Routing; der Aufruf gibt eine Statuszeile aus toolbelt_core.VW_WorkQueue zurück.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beispielaufruf nach einem gültigen Claim.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=42,@ClaimToken=''00000000-0000-0000-0000-000000000001'',@FailureCode=''Transient'';' AS nvarchar(max))),
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
        (N'PARAMETER', 1, N'@WorkItemId', N'bigint', 1, 0, N'NULL', CAST(N'Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ClaimToken', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@FailureCode', N'varchar(64)', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@FailureMessage', N'nvarchar(1000)', 0, 1, N'NULL', CAST(N'Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    EXEC toolbelt_core.USP_ScheduleWorkRetryCore @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode,@FailureMessage=@FailureMessage,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
    RETURN 0;
END;
GO
