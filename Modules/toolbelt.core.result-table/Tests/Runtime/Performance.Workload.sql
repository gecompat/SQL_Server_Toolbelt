-- ============================================================================
-- Reproduzierbarer synthetischer Performance-Workload
-- Zweck: vergleichbare Regressionsevidenz, kein allgemeingültiger Benchmark
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
-- SQLCMD-Variablen:
--   PerformanceBaselineMedianMilliseconds: 0 deaktiviert den Vergleich.
--   PerformanceMaxMedianRegressionPercent: zulässige Verschlechterung,
--     standardmäßig 20. Beide Werte werden ausschließlich vom Aufrufer gehalten.
-- ============================================================================

SET NOCOUNT ON;

DECLARE @BaselineMedianMilliseconds bigint =
    TRY_CONVERT(bigint, N'$(PerformanceBaselineMedianMilliseconds)');
DECLARE @MaxMedianRegressionPercent decimal(9, 4) =
    TRY_CONVERT(decimal(9, 4), N'$(PerformanceMaxMedianRegressionPercent)');

IF @BaselineMedianMilliseconds IS NULL OR @BaselineMedianMilliseconds < 0
   OR @MaxMedianRegressionPercent IS NULL
   OR @MaxMedianRegressionPercent < 0
   OR @MaxMedianRegressionPercent > 1000
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
      SampleOrdinal int    NOT NULL PRIMARY KEY
    , DurationMs    bigint NOT NULL
);
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
        INSERT INTO @Samples (SampleOrdinal, DurationMs)
        VALUES (@SampleOrdinal, DATEDIFF_BIG(millisecond, @StartedAt, SYSUTCDATETIME()));
    END;

    SET @SampleOrdinal += 1;
END;

DECLARE @MedianMilliseconds bigint =
(
    SELECT DurationMs
    FROM
    (
        SELECT
              DurationMs
            , ROW_NUMBER() OVER (ORDER BY DurationMs, SampleOrdinal) AS RowOrdinal
        FROM @Samples
    ) AS ranked
    WHERE RowOrdinal = 3
);

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
