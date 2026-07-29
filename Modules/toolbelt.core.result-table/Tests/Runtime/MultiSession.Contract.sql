:ON ERROR EXIT

-- ============================================================================
-- Multi-Session-Vertrag für USP_PrepareResultTable
-- Daten und Objekte: ausschließlich synthetisch
-- SQLCMD-Variable: WorkerId
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @WorkerId int = TRY_CONVERT(int, N'$(WorkerId)');

IF @WorkerId IS NULL OR @WorkerId < 1 OR @WorkerId > 4
BEGIN
    THROW 52330, N'Der synthetische WorkerId liegt außerhalb 1 bis 4.', 1;
END;

CREATE TABLE #ResultTableParallel
(
    OriginalValue int NULL
);

CREATE TABLE #tbx_ResultTableParallel_ShapeA
(
      WorkerId  int           NOT NULL
    , Iteration int           NOT NULL
    , Payload   nvarchar(80)  COLLATE Latin1_General_100_BIN2 NULL
);

CREATE TABLE #tbx_ResultTableParallel_ShapeB
(
      WorkerId  bigint        NOT NULL
    , Iteration bigint        NOT NULL
    , Payload   varchar(80)   COLLATE Latin1_General_100_CS_AS NULL
);

DECLARE
      @TargetObjectId int =
          OBJECT_ID(N'tempdb..[#ResultTableParallel]', N'U')
    , @Iteration      int = 1;

WHILE @Iteration <= 24
BEGIN
    IF @Iteration % 2 = 1
    BEGIN
        EXEC toolbelt_core.USP_PrepareResultTable
              @ResultTableToAlter = N'#ResultTableParallel'
            , @LikeTable          = N'#tbx_ResultTableParallel_ShapeA'
            , @KeepData           = 0;
    END;
    ELSE
    BEGIN
        EXEC toolbelt_core.USP_PrepareResultTable
              @ResultTableToAlter = N'#ResultTableParallel'
            , @LikeTable          = N'#tbx_ResultTableParallel_ShapeB'
            , @KeepData           = 0;
    END;

    INSERT INTO #ResultTableParallel
    (
          WorkerId
        , Iteration
        , Payload
    )
    VALUES
    (
          @WorkerId
        , @Iteration
        , CONCAT(N'synthetic-worker-', @WorkerId)
    );

    IF OBJECT_ID(N'tempdb..[#ResultTableParallel]', N'U') <> @TargetObjectId
       OR
       (
           SELECT COUNT(*)
           FROM #ResultTableParallel
           WHERE WorkerId = @WorkerId
             AND Iteration = @Iteration
       ) <> 1
       OR EXISTS
       (
           SELECT 1
           FROM #ResultTableParallel
           WHERE WorkerId <> @WorkerId
       )
    BEGIN
        THROW 52331, N'Die parallele lokale ResultTable ist nicht vollständig sitzungsisoliert.', 1;
    END;

    WAITFOR DELAY '00:00:00.025';
    SET @Iteration += 1;
END;

DROP TABLE #tbx_ResultTableParallel_ShapeB;
DROP TABLE #tbx_ResultTableParallel_ShapeA;
DROP TABLE #ResultTableParallel;

PRINT
      N'USP_PrepareResultTable Multi-Session-Worker '
    + CONVERT(nvarchar(10), @WorkerId)
    + N': erfolgreich';
GO
