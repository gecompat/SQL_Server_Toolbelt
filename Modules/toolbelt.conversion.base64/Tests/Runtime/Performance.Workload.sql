-- ============================================================================
-- Synthetischer Large-LOB-Performance-Workload
-- SQLCMD-Variablen: PerformanceBaselineMedianMilliseconds (0 deaktiviert den
-- Vergleich) und PerformanceMaxMedianRegressionPercent (standardmäßig 20).
-- ============================================================================

SET NOCOUNT ON;

DECLARE @BaselineMedianMilliseconds bigint = TRY_CONVERT(bigint, N'$(PerformanceBaselineMedianMilliseconds)');
DECLARE @MaxMedianRegressionPercent decimal(9, 4) = TRY_CONVERT(decimal(9, 4), N'$(PerformanceMaxMedianRegressionPercent)');
IF @BaselineMedianMilliseconds IS NULL OR @BaselineMedianMilliseconds < 0
   OR @MaxMedianRegressionPercent IS NULL OR @MaxMedianRegressionPercent < 0 OR @MaxMedianRegressionPercent > 1000
    THROW 52350, N'Die Performance-Regression-Parameter sind ungültig.', 1;

DECLARE @Samples TABLE (SampleOrdinal int NOT NULL PRIMARY KEY, DurationMs bigint NOT NULL);
DECLARE @SampleOrdinal int = 0;
DECLARE @Synthetic varbinary(max) = CONVERT(varbinary(max), REPLICATE(CONVERT(varchar(max), 'A'), 4194304));

WHILE @SampleOrdinal < 6
BEGIN
    DECLARE @StartedAt datetime2(7) = SYSUTCDATETIME();
    DECLARE @Encoded varchar(max) = toolbelt_conversion.SVF_Base64Encode(@Synthetic, 0);
    DECLARE @Decoded varbinary(max) = toolbelt_conversion.SVF_Base64Decode(@Encoded);

    IF @Decoded <> @Synthetic
        THROW 52351, N'Der Large-LOB-Performance-Workload verlor synthetische Daten.', 1;

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
    THROW 52352, N'Der Base64-Large-LOB-Performance-Median überschreitet die zulässige Regression.', 1;

PRINT N'Base64 Large-LOB-Performance-Workload: erfolgreich.';
GO
