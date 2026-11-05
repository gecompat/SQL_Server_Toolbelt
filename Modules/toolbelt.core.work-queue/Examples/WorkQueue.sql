-- In SSMS als EINEN Batch ausführen; vorher einmal Setup.sql in eigener Demo-DB.
-- Pro Lauf genau ein Szenario, ohne konkurrierenden Worker in dieser Datenbank.
-- Anleitung/Ergebnisse/Bereinigung: ../Documentation/USAGE.md
SET NOCOUNT ON;
DECLARE @Scenario varchar(16) = 'success'; -- success | retry | dead-letter | fail | recovery
IF DB_NAME() <> N'ToolbeltQueueDemo'
    THROW 50000, N'Zuerst die eigene Datenbank ToolbeltQueueDemo auswählen.', 1;
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 50000, N'Eine frische Sitzung ohne Callertransaktion verwenden.', 1;
IF @Scenario IS NULL OR @Scenario NOT IN ('success','retry','dead-letter','fail','recovery')
    THROW 50000, N'Unbekanntes Demoszenario.', 1;
IF OBJECT_ID(N'dbo.USP_QueueGuideHandler', N'P') IS NULL
    THROW 50000, N'Zuerst Setup.sql ausführen.', 1;
IF EXISTS (SELECT 1 FROM toolbelt_core.VW_WorkQueue
           WHERE Status NOT IN ('COMPLETED','FAILED','DEAD_LETTER'))
    THROW 50000, N'Es gibt offene Arbeit. Vor einem neuen Beispiel deren Zustand klären.', 1;
DROP TABLE IF EXISTS #GuideEnqueue;
DROP TABLE IF EXISTS #GuideClaim;
CREATE TABLE #GuideEnqueue (Placeholder bit);
CREATE TABLE #GuideClaim
(
    WorkItemId bigint NOT NULL,
    WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,
    PayloadJson nvarchar(max) NULL, ClaimToken uniqueidentifier NOT NULL,
    ClaimedAtUtc datetime2(7) NOT NULL, ClaimGeneration bigint NOT NULL,
    LeaseUntilUtc datetime2(7) NOT NULL, LastHeartbeatAtUtc datetime2(7) NOT NULL
);
DECLARE @BusinessKey uniqueidentifier = NEWID();
DECLARE @Key varchar(128) = CONVERT(varchar(36), @BusinessKey);
DECLARE @Payload nvarchar(max) = N'{"businessKey":"' + CONVERT(nvarchar(36), @BusinessKey) + N'"}';
DECLARE @WorkItemId bigint, @Token uniqueidentifier, @ClaimedId bigint,
        @ClaimedType varchar(128), @ClaimedPayload nvarchar(max);
DECLARE @Attempts tinyint = CASE WHEN @Scenario = 'dead-letter' THEN 1 ELSE 3 END;
DECLARE @Lease int = CASE WHEN @Scenario = 'recovery' THEN 5 ELSE 300 END;

-- ResultTable bestimmt die aktuelle Ausgabeform; keine kopierte breite Statusstruktur.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
    @WorkTypeName = 'demo.queue-guide', @PayloadJson = @Payload,
    @IdempotencyKey = @Key, @ExecutionGroup = @Key, @Priority = 10,
    @MaxAttempts = @Attempts, @RetryBaseDelaySeconds = 1, @RetryMaxDelaySeconds = 4,
    @ResultTable = N'#GuideEnqueue';
-- Nachträglich angelegte ResultTable-Spalten erst nach dem Aufruf kompilieren.
EXEC sys.sp_executesql N'SELECT @Id = WorkItemId FROM #GuideEnqueue;
    SELECT WasCreated, WorkItemId, Status FROM #GuideEnqueue;',
    N'@Id bigint OUTPUT', @Id = @WorkItemId OUTPUT;

-- Gleiche Einreichung erneut: gleiche ID, WasCreated = 0; kein zweiter Auftrag.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
    @WorkTypeName = 'demo.queue-guide', @PayloadJson = @Payload,
    @IdempotencyKey = @Key, @ExecutionGroup = @Key, @Priority = 10,
    @MaxAttempts = @Attempts, @RetryBaseDelaySeconds = 1, @RetryMaxDelaySeconds = 4,
    @ResultTable = N'#GuideEnqueue';
EXEC(N'SELECT WasCreated, WorkItemId, Status FROM #GuideEnqueue;');

-- Claim führt KEINEN Handler aus und hat keinen WorkType-/Gruppenfilter.
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds = @Lease, @ResultTable = N'#GuideClaim';
SELECT @ClaimedId = WorkItemId, @Token = ClaimToken, @ClaimedType = WorkTypeName,
       @ClaimedPayload = PayloadJson FROM #GuideClaim;
IF @ClaimedId IS NULL OR @ClaimedId <> @WorkItemId OR @ClaimedType <> 'demo.queue-guide'
    THROW 50000, N'Nicht der erwartete Demoauftrag: keine fremde Arbeit ausführen oder abschließen.', 1;

IF @Scenario = 'fail'
    EXEC toolbelt_core.USP_FailWork @WorkItemId = @WorkItemId, @ClaimToken = @Token,
        @FailureCode = 'DEMO.PERMANENT', @FailureMessage = N'Synthetischer dauerhafter Fehler';
ELSE
BEGIN
    IF @Scenario IN ('retry','dead-letter','recovery')
    BEGIN
        IF @Scenario = 'recovery'
        BEGIN
            -- Nur Demo: noch KEIN Handler gestartet; Lease absichtlich auslaufen lassen.
            WAITFOR DELAY '00:00:06';
            SELECT WorkItemId, Status, IsLeaseExpired FROM toolbelt_core.VW_WorkQueue
            WHERE WorkItemId = @WorkItemId; -- CLAIMED / 1, keine automatische Recovery
            EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems = 1;
        END
        ELSE
            EXEC toolbelt_core.USP_ScheduleWorkRetry
                @WorkItemId = @WorkItemId, @ClaimToken = @Token, @FailureCode = 'DEMO.TRANSIENT';
        IF @Scenario = 'dead-letter'
        BEGIN
            -- MaxAttempts=1: erster Retrywunsch endet bereits in DEAD_LETTER.
            DECLARE @Version binary(8);
            SELECT @Version = RowVersion FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId = @WorkItemId;
            EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId = @WorkItemId,
                @ExpectedRowVersion = @Version, @RequeueReason = N'Synthetische Ursache behoben';
        END
        ELSE
            WAITFOR DELAY '00:00:02'; -- erster Backoff der Demo: eine Sekunde
        SET @ClaimedId = NULL;
        EXEC toolbelt_core.USP_ClaimWork @ResultTable = N'#GuideClaim';
        SELECT @ClaimedId = WorkItemId, @Token = ClaimToken, @ClaimedPayload = PayloadJson FROM #GuideClaim;
        IF @ClaimedId IS NULL OR @ClaimedId <> @WorkItemId
            THROW 50000, N'Erwarteten erneuten Claim nicht erhalten; Status prüfen.', 1;
        -- Ausschließlich das NEUE Token verwenden; das alte ist nicht mehr gültig.
    END;
    EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId = @WorkItemId, @ClaimToken = @Token;
    -- Fachliche Wirkung und Complete in derselben eigenen kurzen Transaktion.
    BEGIN TRANSACTION;
    BEGIN TRY
        EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName = 'demo.queue-guide',
            @RequiredPermission = 'CLAIM', @SuppressResult = 1;
        EXEC dbo.USP_QueueGuideHandler @PayloadJson = @ClaimedPayload;
        EXEC toolbelt_core.USP_CompleteWork @WorkItemId = @WorkItemId, @ClaimToken = @Token;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW; -- kein automatischer Retry unbekannter Ausgänge
    END CATCH;
END;
EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId = @WorkItemId;
SELECT WorkItemId, Status, ClaimGeneration, CycleAttemptCount, RetryCycleNumber,
       RecoveryCount, LastErrorCode, LastRequeueReason
FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId = @WorkItemId;
SELECT COUNT(*) AS BusinessEffects FROM dbo.QueueGuideEffect WHERE BusinessKey = @BusinessKey;
-- Erwartung: fail = 0 Effekte / FAILED; sonst 1 Effekt / COMPLETED.
-- Keine Payloads oder ClaimTokens in öffentliche Ausgaben/Logs übernehmen.
DROP TABLE #GuideClaim;
DROP TABLE #GuideEnqueue;
