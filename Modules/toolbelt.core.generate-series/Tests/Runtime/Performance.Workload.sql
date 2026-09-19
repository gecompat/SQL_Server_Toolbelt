-- ============================================================================
-- Synthetischer Very-large-series-Performance-Workload
-- SQLCMD-Variablen: PerformanceBaselineMedianMilliseconds (0 deaktiviert den
-- Vergleich), PerformanceMaxMedianRegressionPercent und
-- PerformanceMaxBatchMedianVariancePercent (jeweils standardmäßig 20).
-- ============================================================================

SET NOCOUNT ON;

DECLARE @BaselineMedianMilliseconds bigint = TRY_CONVERT(bigint, N'$(PerformanceBaselineMedianMilliseconds)');
DECLARE @MaxMedianRegressionPercent decimal(9, 4) = TRY_CONVERT(decimal(9, 4), N'$(PerformanceMaxMedianRegressionPercent)');
DECLARE @MaxBatchMedianVariancePercent decimal(9, 4) = TRY_CONVERT(decimal(9, 4), N'$(PerformanceMaxBatchMedianVariancePercent)');
IF @BaselineMedianMilliseconds IS NULL OR @BaselineMedianMilliseconds < 0
   OR @MaxMedianRegressionPercent IS NULL OR @MaxMedianRegressionPercent < 0 OR @MaxMedianRegressionPercent > 1000
   OR @MaxBatchMedianVariancePercent IS NULL OR @MaxBatchMedianVariancePercent < 0 OR @MaxBatchMedianVariancePercent > 1000
    THROW 52450, N'Die Performance-Regression-Parameter sind ungültig.', 1;

DECLARE @BatchMedians TABLE (BatchOrdinal int NOT NULL PRIMARY KEY, MedianMilliseconds bigint NOT NULL);
DECLARE @Samples TABLE
(
    BatchOrdinal int NOT NULL,
    SampleOrdinal int NOT NULL,
    DurationMs bigint NOT NULL,
    PRIMARY KEY (BatchOrdinal, SampleOrdinal)
);
DECLARE @BatchOrdinal int = 1;

WHILE @BatchOrdinal <= 3
BEGIN
    DECLARE @SampleOrdinal int = 0;

    WHILE @SampleOrdinal < 6
    BEGIN
        DECLARE @StartedAt datetime2(7) = SYSUTCDATETIME();
        DECLARE @Count bigint;
        SELECT @Count = COUNT_BIG(*)
        FROM toolbelt_core.TVF_GenerateSeriesBigInt(1, 10000000, 1);

        IF @Count <> 10000000
            THROW 52451, N'Der Very-large-series-Performance-Workload lieferte eine falsche Zeilenzahl.', 1;

        IF @SampleOrdinal > 0
            INSERT INTO @Samples (BatchOrdinal, SampleOrdinal, DurationMs)
            VALUES (@BatchOrdinal, @SampleOrdinal, DATEDIFF_BIG(millisecond, @StartedAt, SYSUTCDATETIME()));
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
    THROW 52453, N'Die Generate-Series-Performance-Mediane sind für einen Regressionsvergleich nicht stabil.', 1;

IF @BaselineMedianMilliseconds > 0
   AND @MedianMilliseconds > @BaselineMedianMilliseconds * (1 + @MaxMedianRegressionPercent / 100.0)
    THROW 52452, N'Der Generate-Series-Performance-Median überschreitet die zulässige Regression.', 1;

PRINT N'Generate-Series Very-large-series-Performance-Workload: erfolgreich.';
GO
