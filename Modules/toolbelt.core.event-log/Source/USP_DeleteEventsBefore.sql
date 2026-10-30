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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_DeleteEventsBefore' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51710-51714', NULL, NULL, NULL, NULL, CAST(N'Grenz-, Pflichtparameter- und Transaktionsfehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Löscht höchstens 5000 alte Events.' AS nvarchar(max)), CAST(N'DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc=''2026-01-01'', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@BeforeOccurredAtUtc', N'datetime2(7)', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),''2026-10-30T00:00:00'',126). Löscht ausschließlich OccurredAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@BatchSize', N'int', 0, 1, N'1000', CAST(N'Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxBatches', N'int', 0, 1, N'1', CAST(N'Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@DeletedRows', N'bigint', 0, 1, N'NULL', CAST(N'bigint OUTPUT: Der Eingabewert wird immer auf 0 gesetzt, auch im Hilfemodus; danach Anzahl der in diesem Aufruf gelöschten Zeilen. Zum Empfangen eine bigint-Variable mit OUTPUT übergeben; Eingabe-NULL ist kein Löschlimit.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
