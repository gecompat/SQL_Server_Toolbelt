-- ============================================================================
-- Synthetischer Very-large-series-Performance-Workload
-- SQLCMD-Variablen: PerformanceBaselineMedianMilliseconds (0 deaktiviert den
-- Vergleich) und PerformanceMaxMedianRegressionPercent (standardmäßig 20).
-- ============================================================================

SET NOCOUNT ON;

DECLARE @BaselineMedianMilliseconds bigint = TRY_CONVERT(bigint, N'$(PerformanceBaselineMedianMilliseconds)');
DECLARE @MaxMedianRegressionPercent decimal(9, 4) = TRY_CONVERT(decimal(9, 4), N'$(PerformanceMaxMedianRegressionPercent)');
IF @BaselineMedianMilliseconds IS NULL OR @BaselineMedianMilliseconds < 0
   OR @MaxMedianRegressionPercent IS NULL OR @MaxMedianRegressionPercent < 0 OR @MaxMedianRegressionPercent > 1000
    THROW 52450, N'Die Performance-Regression-Parameter sind ungültig.', 1;

DECLARE @Samples TABLE (SampleOrdinal int NOT NULL PRIMARY KEY, DurationMs bigint NOT NULL);
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
        INSERT INTO @Samples (SampleOrdinal, DurationMs)
        VALUES (@SampleOrdinal, DATEDIFF_BIG(millisecond, @StartedAt, SYSUTCDATETIME()));
    SET @SampleOrdinal += 1;
END;

DECLARE @MedianMilliseconds bigint =
(
    SELECT DurationMs
    FROM
    (
        SELECT DurationMs, ROW_NUMBER() OVER (ORDER BY DurationMs, SampleOrdinal) AS RowOrdinal
        FROM @Samples
    ) AS ranked
    WHERE RowOrdinal = 3
);

IF @BaselineMedianMilliseconds > 0
   AND @MedianMilliseconds > @BaselineMedianMilliseconds * (1 + @MaxMedianRegressionPercent / 100.0)
    THROW 52452, N'Der Generate-Series-Performance-Median überschreitet die zulässige Regression.', 1;

PRINT N'Generate-Series Very-large-series-Performance-Workload: erfolgreich.';
GO
