SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DeleteEventsBefore]
(
      @BeforeOccurredAtUtc datetime2(7) = NULL
    , @BatchSize int = 1000
    , @MaxBatches int = 1
    , @DeletedRows bigint = NULL OUTPUT
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @BatchSize = ISNULL(@BatchSize, 1000);
    SET @MaxBatches = ISNULL(@MaxBatches, 1);
    SET @DeletedRows = 0;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_DeleteEventsBefore' AS sysname) AS ObjectName
            , v.Section, v.Ordinal, v.ItemName, v.SqlDataType
            , v.IsRequired, v.IsNullable, v.DefaultValue, v.Description, v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@BeforeOccurredAtUtc', 'datetime2(7)', 1, 0, NULL, N'Nur Events mit älterem OccurredAtUtc werden gelöscht.', NULL)
            , ('PARAMETER', 2, N'@BatchSize', 'int', 0, 0, N'1000', N'1 bis 10000 Zeilen je Batch.', NULL)
            , ('PARAMETER', 3, N'@MaxBatches', 'int', 0, 0, N'1', N'1 bis 100 Batches je Aufruf.', NULL)
            , ('ERROR', 1, N'51710-51714', NULL, NULL, NULL, NULL, N'Grenz-, Pflichtparameter- und Transaktionsfehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Löscht höchstens 5000 alte Events.', N'DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc=''2026-01-01'', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF @BeforeOccurredAtUtc IS NULL
        THROW 51710, N'@BeforeOccurredAtUtc ist erforderlich.', 1;
    IF @BatchSize NOT BETWEEN 1 AND 10000
        THROW 51711, N'@BatchSize muss zwischen 1 und 10000 liegen.', 1;
    IF @MaxBatches NOT BETWEEN 1 AND 100
        THROW 51712, N'@MaxBatches muss zwischen 1 und 100 liegen.', 1;
    IF XACT_STATE() = -1
        THROW 51713, N'Retention ist in einer uncommittable Transaktion nicht möglich.', 1;

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_EventLog_Retention;

    BEGIN TRY
        DECLARE @Batch int = 0;
        DECLARE @Rows int = 1;
        WHILE @Batch < @MaxBatches AND @Rows > 0
        BEGIN
            ;WITH Targets AS
            (
                SELECT TOP (@BatchSize) EventId
                FROM toolbelt_core.EventLog
                WHERE OccurredAtUtc < @BeforeOccurredAtUtc
                ORDER BY EventId
            )
            DELETE FROM Targets;
            SET @Rows = @@ROWCOUNT;
            SET @DeletedRows += @Rows;
            SET @Batch += 1;
        END;

        IF @InitialTranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_EventLog_Retention;
        THROW;
    END CATCH;

    IF @Debug > 0
    BEGIN
        DECLARE @DeletedForMessage varchar(32) = CONVERT(varchar(32), @DeletedRows);
        RAISERROR(N'USP_DeleteEventsBefore: %s Events gelöscht.', 10, 1, @DeletedForMessage) WITH NOWAIT;
    END;
    RETURN 0;
END;
GO
