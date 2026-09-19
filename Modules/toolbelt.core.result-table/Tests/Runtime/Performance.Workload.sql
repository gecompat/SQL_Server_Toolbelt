-- ============================================================================
-- Reproduzierbarer synthetischer Performance-Workload
-- Zweck: vergleichbare Regressionsevidenz, kein allgemeingültiger Benchmark
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
-- SQLCMD-Variablen:
--   PerformanceBaselineMedianMilliseconds: 0 deaktiviert den Vergleich.
--   PerformanceMaxMedianRegressionPercent: zulässige Verschlechterung,
--     standardmäßig 20; PerformanceMaxBatchMedianVariancePercent: zulässige
--     Streuung der Batch-Mediane, standardmäßig 20. Alle Werte bleiben
--     ausschließlich beim Aufrufer.
-- ============================================================================

SET NOCOUNT ON;

DECLARE @BaselineMedianMilliseconds bigint =
    TRY_CONVERT(bigint, N'$(PerformanceBaselineMedianMilliseconds)');
DECLARE @MaxMedianRegressionPercent decimal(9, 4) =
    TRY_CONVERT(decimal(9, 4), N'$(PerformanceMaxMedianRegressionPercent)');
DECLARE @MaxBatchMedianVariancePercent decimal(9, 4) =
    TRY_CONVERT(decimal(9, 4), N'$(PerformanceMaxBatchMedianVariancePercent)');

IF @BaselineMedianMilliseconds IS NULL OR @BaselineMedianMilliseconds < 0
   OR @MaxMedianRegressionPercent IS NULL
   OR @MaxMedianRegressionPercent < 0
   OR @MaxMedianRegressionPercent > 1000
   OR @MaxBatchMedianVariancePercent IS NULL
   OR @MaxBatchMedianVariancePercent < 0
   OR @MaxBatchMedianVariancePercent > 1000
BEGIN
    THROW 52120, N'Die Performance-Regression-Parameter sind ungültig.', 1;
END;

CREATE TABLE #ResultTablePerformance
(
    DummyValue int NULL
);

CREATE TABLE #tbx_ResultTablePerformance_ShapeA
(
      ItemOrdinal bigint        NOT NULL
    , ItemCode    varchar(40)   COLLATE Latin1_General_100_BIN2 NOT NULL
    , ItemText    nvarchar(200) COLLATE Latin1_General_100_CS_AS NULL
);

CREATE TABLE #tbx_ResultTablePerformance_ShapeB
(
      AlternateOrdinal int            NOT NULL
    , AlternateValue   decimal(19, 4) NULL
);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTablePerformance'
    , @LikeTable          = N'#tbx_ResultTablePerformance_ShapeA'
    , @KeepData           = 0;

CREATE INDEX IX_ResultTablePerformance_ItemCode
    ON #ResultTablePerformance (ItemCode);

DECLARE @Samples TABLE
(
      BatchOrdinal  int    NOT NULL
    , SampleOrdinal int    NOT NULL
    , DurationMs    bigint NOT NULL
    , PRIMARY KEY (BatchOrdinal, SampleOrdinal)
);
DECLARE @BatchMedians TABLE
(
      BatchOrdinal       int    NOT NULL PRIMARY KEY
    , MedianMilliseconds bigint NOT NULL
);
DECLARE @BatchOrdinal int = 1;

WHILE @BatchOrdinal <= 3
BEGIN
    DECLARE @SampleOrdinal int = 0;

    WHILE @SampleOrdinal < 6
    BEGIN
        DECLARE @StartedAt datetime2(7) = SYSUTCDATETIME();
        DECLARE @Iteration int = 0;

        -- Passendes Schema ohne Mutation.
        WHILE @Iteration < 50
        BEGIN
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = N'#ResultTablePerformance'
                , @LikeTable          = N'#tbx_ResultTablePerformance_ShapeA'
                , @KeepData           = 1;
            SET @Iteration += 1;
        END;

        -- Passendes Schema mit TRUNCATE.
        SET @Iteration = 0;
        WHILE @Iteration < 20
        BEGIN
            INSERT INTO #ResultTablePerformance (ItemOrdinal, ItemCode, ItemText)
            VALUES (@Iteration, 'SYNTHETIC', N'Synthetic workload');

            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = N'#ResultTablePerformance'
                , @LikeTable          = N'#tbx_ResultTablePerformance_ShapeA'
                , @KeepData           = 0;
            SET @Iteration += 1;
        END;

        EXEC sys.sp_executesql
            N'DROP INDEX IX_ResultTablePerformance_ItemCode ON #ResultTablePerformance;';

        -- Kleiner Schemaumbau in beide Richtungen.
        SET @Iteration = 0;
        WHILE @Iteration < 10
        BEGIN
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = N'#ResultTablePerformance'
                , @LikeTable          = N'#tbx_ResultTablePerformance_ShapeB'
                , @KeepData           = 0;
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = N'#ResultTablePerformance'
                , @LikeTable          = N'#tbx_ResultTablePerformance_ShapeA'
                , @KeepData           = 0;
            SET @Iteration += 1;
        END;

        CREATE INDEX IX_ResultTablePerformance_ItemCode
            ON #ResultTablePerformance (ItemCode);

        IF @SampleOrdinal > 0
        BEGIN
            INSERT INTO @Samples (BatchOrdinal, SampleOrdinal, DurationMs)
            VALUES (@BatchOrdinal, @SampleOrdinal, DATEDIFF_BIG(millisecond, @StartedAt, SYSUTCDATETIME()));
        END;

        SET @SampleOrdinal += 1;
    END;

    INSERT INTO @BatchMedians (BatchOrdinal, MedianMilliseconds)
    SELECT @BatchOrdinal, DurationMs
    FROM
    (
        SELECT DurationMs, ROW_NUMBER() OVER (ORDER BY DurationMs, SampleOrdinal) AS RowOrdinal
        FROM @Samples
        WHERE BatchOrdinal = @BatchOrdinal
    ) AS ranked
    WHERE RowOrdinal = 3;

    SET @BatchOrdinal += 1;
END;

DECLARE @MedianMilliseconds bigint =
(
    SELECT MedianMilliseconds
    FROM
    (
        SELECT MedianMilliseconds, ROW_NUMBER() OVER (ORDER BY MedianMilliseconds, BatchOrdinal) AS RowOrdinal
        FROM @BatchMedians
    ) AS ranked
    WHERE RowOrdinal = 2
);

DECLARE @MinimumBatchMedianMilliseconds bigint = (SELECT MIN(MedianMilliseconds) FROM @BatchMedians);
DECLARE @MaximumBatchMedianMilliseconds bigint = (SELECT MAX(MedianMilliseconds) FROM @BatchMedians);

IF @MinimumBatchMedianMilliseconds IS NULL OR @MinimumBatchMedianMilliseconds <= 0
   OR @MaximumBatchMedianMilliseconds IS NULL
   OR CONVERT(decimal(38, 10), @MaximumBatchMedianMilliseconds - @MinimumBatchMedianMilliseconds) * 100
      / CONVERT(decimal(38, 10), @MinimumBatchMedianMilliseconds) > @MaxBatchMedianVariancePercent
BEGIN
    THROW 52453, N'Die Result-Table-Performance-Mediane sind für einen Regressionsvergleich nicht stabil.', 1;
END;

IF @BaselineMedianMilliseconds > 0
   AND @MedianMilliseconds >
       @BaselineMedianMilliseconds * (1 + @MaxMedianRegressionPercent / 100.0)
BEGIN
    THROW 52121, N'Der Result-Table-Performance-Median überschreitet die zulässige Regression.', 1;
END;

PRINT N'USP_PrepareResultTable Performance-Workload: erfolgreich.';

DROP TABLE #tbx_ResultTablePerformance_ShapeB;
DROP TABLE #tbx_ResultTablePerformance_ShapeA;
DROP TABLE #ResultTablePerformance;
GO
