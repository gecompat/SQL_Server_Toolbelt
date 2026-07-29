-- ============================================================================
-- Reproduzierbarer synthetischer Performance-Workload
-- Zweck: relative CI-Evidenz, kein allgemeingültiger Benchmark
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
-- ============================================================================

SET NOCOUNT ON;

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

DECLARE
      @StartedAt              datetime2(7) = SYSUTCDATETIME()
    , @CpuTimeBefore          int
    , @LogicalReadsBefore     bigint
    , @TempdbAllocatedBefore  bigint
    , @CpuTimeAfter           int
    , @LogicalReadsAfter      bigint
    , @TempdbAllocatedAfter   bigint
    , @Iteration              int = 0;

SELECT
      @CpuTimeBefore = s.cpu_time
    , @LogicalReadsBefore = s.logical_reads
FROM sys.dm_exec_sessions AS s
WHERE s.session_id = @@SPID;

SELECT @TempdbAllocatedBefore =
    su.user_objects_alloc_page_count - su.user_objects_dealloc_page_count
FROM tempdb.sys.dm_db_session_space_usage AS su
WHERE su.session_id = @@SPID;

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
    INSERT INTO #ResultTablePerformance
    (
          ItemOrdinal
        , ItemCode
        , ItemText
    )
    VALUES
    (
          @Iteration
        , 'SYNTHETIC'
        , N'Synthetic workload'
    );

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

SELECT
      @CpuTimeAfter = s.cpu_time
    , @LogicalReadsAfter = s.logical_reads
FROM sys.dm_exec_sessions AS s
WHERE s.session_id = @@SPID;

SELECT @TempdbAllocatedAfter =
    su.user_objects_alloc_page_count - su.user_objects_dealloc_page_count
FROM tempdb.sys.dm_db_session_space_usage AS su
WHERE su.session_id = @@SPID;

PRINT
      N'USP_PrepareResultTable Performance-Workload: erfolgreich; '
    + N'NoMutation=50; Truncate=20; ReshapePairs=10; '
    + N'DurationMs='
    + CONVERT(nvarchar(30), DATEDIFF_BIG(millisecond, @StartedAt, SYSUTCDATETIME()))
    + N'; CpuMs='
    + CONVERT(nvarchar(30), @CpuTimeAfter - @CpuTimeBefore)
    + N'; LogicalReads='
    + CONVERT(nvarchar(30), @LogicalReadsAfter - @LogicalReadsBefore)
    + N'; TempdbNetUserPages='
    + CONVERT
      (
          nvarchar(30)
        , @TempdbAllocatedAfter - @TempdbAllocatedBefore
      )
    + N'.';

DROP TABLE #tbx_ResultTablePerformance_ShapeB;
DROP TABLE #tbx_ResultTablePerformance_ShapeA;
DROP TABLE #ResultTablePerformance;
GO
