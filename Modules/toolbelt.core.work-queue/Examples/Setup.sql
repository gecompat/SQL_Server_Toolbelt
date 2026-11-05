-- Einmalige Vorbereitung für WorkQueue.sql in einer eigenen Demodatenbank.
-- Installation, Voraussetzungen und Bereinigung: ../Documentation/USAGE.md
-- Der Handler ist ausschließlich ein Lernbeispiel, kein Toolbelt-Produktobjekt.
SET NOCOUNT ON;
IF DB_NAME() <> N'ToolbeltQueueDemo'
    THROW 50000, N'Zuerst die eigene Datenbank ToolbeltQueueDemo auswählen.', 1;
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) = 2
    THROW 50000, N'Eine frische Sitzung ohne explizite oder implizite Transaktion verwenden.', 1;
IF OBJECT_ID(N'toolbelt_core.USP_EnqueueWorkWithPolicy', N'P') IS NULL
    THROW 50000, N'Zuerst Work Queue samt Dependencies installieren.', 1;
IF OBJECT_ID(N'dbo.QueueGuideEffect') IS NOT NULL
   OR OBJECT_ID(N'dbo.USP_QueueGuideHandler') IS NOT NULL
   OR EXISTS (SELECT 1 FROM toolbelt_core.VW_WorkTypes WHERE WorkTypeName = 'demo.queue-guide')
    THROW 50000, N'Demonstrationsobjekte existieren bereits; nichts überschreiben.', 1;

BEGIN TRANSACTION;
BEGIN TRY
    CREATE TABLE dbo.QueueGuideEffect
    (
        BusinessKey uniqueidentifier NOT NULL PRIMARY KEY,
        AppliedAtUtc datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME()
    );
    -- Ein fachlicher Schlüssel verhindert doppelte Wirkungen dieses Beispiels.
    -- Der Handler besitzt weder COMMIT/ROLLBACK noch externe Seiteneffekte.
    EXEC(N'CREATE PROCEDURE dbo.USP_QueueGuideHandler @PayloadJson nvarchar(max)
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Key uniqueidentifier = TRY_CONVERT(uniqueidentifier, JSON_VALUE(@PayloadJson, ''$.businessKey''));
        IF @Key IS NULL THROW 50000, N''businessKey muss eine GUID sein.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.QueueGuideEffect WITH (UPDLOCK, HOLDLOCK) WHERE BusinessKey = @Key)
            INSERT dbo.QueueGuideEffect(BusinessKey) VALUES (@Key);
    END;');
    EXEC toolbelt_core.USP_RegisterWorkType
        @WorkTypeName = 'demo.queue-guide',
        @HandlerSchema = N'dbo', @HandlerProcedure = N'USP_QueueGuideHandler',
        @ParameterMode = 'JSON_PAYLOAD',
        @PayloadContractJson = N'{"businessKey":"GUID als Zeichenfolge; Pflichtfeld"}',
        @DefaultTimeoutSeconds = 30, @IsIdempotent = 1,
        @Description = N'Synthetischer Queue-Lernhandler';
    -- Nur der aktuelle Demo-Datenbankbenutzer erhält diese Policy, auch dbo.
    -- Keine SQL-GRANTs, Logins oder Rollen werden erzeugt.
    DECLARE @DemoPrincipal sysname = USER_NAME();
    EXEC toolbelt_core.USP_SetWorkTypePermission
        @WorkTypeName = 'demo.queue-guide', @Principal = @DemoPrincipal,
        @PermissionName = 'ENQUEUE', @PermissionState = 'ALLOW';
    EXEC toolbelt_core.USP_SetWorkTypePermission
        @WorkTypeName = 'demo.queue-guide', @Principal = @DemoPrincipal,
        @PermissionName = 'CLAIM', @PermissionState = 'ALLOW';
    COMMIT;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
END CATCH;
SELECT WorkTypeName, ParameterMode, IsEnabled FROM toolbelt_core.VW_WorkTypes
WHERE WorkTypeName = 'demo.queue-guide';
