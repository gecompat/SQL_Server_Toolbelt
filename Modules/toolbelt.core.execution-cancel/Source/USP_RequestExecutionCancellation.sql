SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RequestExecutionCancellation]
      @ExecutionId uniqueidentifier = NULL
    , @CancellationReason nvarchar(512) = NULL
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT CONVERT(varchar(16), '1.0') AS HelpContractVersion,
               CONVERT(sysname, N'toolbelt_core') AS SchemaName,
               CONVERT(sysname, N'USP_RequestExecutionCancellation') AS ObjectName,
               v.Section, v.Ordinal, v.ItemName, v.SqlDataType, v.IsRequired,
               v.IsNullable, v.DefaultValue, v.Description, v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
        , ('PARAMETER', 1, N'@ExecutionId', 'uniqueidentifier', 0, 1, NULL, N'Zielausführung; ohne Wert wird die aktuelle sessiongebundene ExecutionId verwendet.', NULL)
        , ('PARAMETER', 2, N'@CancellationReason', 'nvarchar(512)', 0, 1, NULL, N'Optionaler, nicht sensibler Grund. Nur die erste Anforderung speichert ihn.', NULL)
        , ('PARAMETER', 3, N'@Debug', 'tinyint', 0, 0, N'0', N'Gibt eine Fortschrittsmeldung aus.', NULL)
        , ('PARAMETER', 4, N'@Hilfe', 'bit', 0, 0, N'0', N'1 liefert ausschließlich dieses Help-Resultset und überspringt fachliche Prüfungen und Änderungen.', NULL)
        , ('ERROR', 1, N'52600-52606', NULL, NULL, NULL, NULL, N'Parameter-, Context-, Transaktions- oder Quotenfehler: 52605 bei 100000 DBrequests, 52606 bei 10000 je Principal; bestehende IDs bleiben idempotent.', NULL)
        , ('RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, N'Kein fachliches Resultset; den Status liefert TVF_ExecutionCancellationStatus.', NULL)
        , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Fordert Cancellation für die aktuelle Ausführung an.', N'EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N''planned maintenance'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 WHEN 'RESULT_COLUMN' THEN 4 ELSE 5 END, v.Ordinal;
        RETURN 0;
    END;

    IF @@TRANCOUNT <> 0
        THROW 52600, N'Eine Cancellation-Anforderung benötigt eine Session ohne aktive Caller-Transaktion.', 1;

    SET @ExecutionId = COALESCE(@ExecutionId, toolbelt_core.SVF_CurrentExecutionId());
    IF @ExecutionId IS NULL
        THROW 52601, N'@ExecutionId fehlt und in dieser Session ist kein Execution Context aktiv.', 1;
    IF @ExecutionId = '00000000-0000-0000-0000-000000000000'
        THROW 52602, N'@ExecutionId darf nicht die Null-GUID sein.', 1;
    IF @CancellationReason IS NOT NULL AND LEN(@CancellationReason) = 0
        SET @CancellationReason = NULL;

    DECLARE @WasCreated bit = 0, @LockResult int,
            @PrincipalId int = USER_ID(), @PrincipalSid varbinary(85), @PrincipalCreatedAt datetime;
    SELECT @PrincipalSid=sid,@PrincipalCreatedAt=create_date
    FROM sys.database_principals WHERE principal_id=@PrincipalId;
    IF @PrincipalSid IS NULL OR @PrincipalCreatedAt IS NULL
        THROW 52604,N'Anfordernder Datenbankprincipal konnte nicht gebunden werden.',1;
    BEGIN TRANSACTION;
    BEGIN TRY
        EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.execution-cancellation.quota',
            @LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=10000,@DbPrincipal=N'public';
        IF @LockResult<0 THROW 52603,N'Cancellationquote konnte nicht atomar geprüft werden.',1;
        IF NOT EXISTS
        (
            SELECT 1 FROM toolbelt_core.ExecutionCancellation WITH (UPDLOCK, HOLDLOCK)
            WHERE ExecutionId = @ExecutionId
        )
        BEGIN
            IF (SELECT COUNT_BIG(*) FROM toolbelt_core.ExecutionCancellation)>=100000
                THROW 52605,N'Die Datenbankquote von 100000 Cancellation-Anforderungen ist erreicht.',1;
            IF (SELECT COUNT_BIG(*) FROM toolbelt_core.ExecutionCancellation
                WHERE RequestedByPrincipalId=@PrincipalId AND RequestedByPrincipalSid=@PrincipalSid
                  AND RequestedByPrincipalCreatedAt=@PrincipalCreatedAt)>=10000
                THROW 52606,N'Die Principalquote von 10000 Cancellation-Anforderungen ist erreicht.',1;
            INSERT INTO toolbelt_core.ExecutionCancellation
                (ExecutionId, RequestedBy, CancellationReason, RequestedByPrincipalId, RequestedByPrincipalSid, RequestedByPrincipalCreatedAt)
            VALUES
                (@ExecutionId, ORIGINAL_LOGIN(), @CancellationReason, @PrincipalId, @PrincipalSid, @PrincipalCreatedAt);
            SET @WasCreated = 1;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    IF @Debug > 0
    BEGIN
        DECLARE @WasCreatedForMessage int = CONVERT(int, @WasCreated);
        RAISERROR(N'USP_RequestExecutionCancellation: Anforderung verarbeitet; neu=%d.', 10, 1, @WasCreatedForMessage) WITH NOWAIT;
    END;
    RETURN 0;
END;
GO
