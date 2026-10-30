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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RequestExecutionCancellation' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'52600-52606', NULL, NULL, NULL, NULL, CAST(N'Parameter-, Context-, Transaktions- oder Quotenfehler: 52605 bei 100000 DBrequests, 52606 bei 10000 je Principal; bestehende IDs bleiben idempotent.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; den Status liefert TVF_ExecutionCancellationStatus.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Fordert Cancellation für die aktuelle Ausführung an.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N''planned maintenance'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@ExecutionId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Explizite Ziel-ID darf nicht die Null-GUID sein. NULL/Default verwendet den aktiven Execution Context; fehlt dann eine ID, entsteht ein Fehler. Keine aktive Callertransaktion zulässig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@CancellationReason', N'nvarchar(512)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Grund nvarchar(512), keine Ausführung und keine automatische Redigierung; keine Secrets übergeben. NULL/leer bzw. LEN=0 (reine Spaces) wird NULL. Bei wiederholter Anforderung derselben ID bleiben erster Grund und Zeitpunkt erhalten.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
