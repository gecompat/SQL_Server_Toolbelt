-- ============================================================================
-- Grenz- und Transaktionsvertrag für USP_PrepareResultTable
-- Daten und Objekte: ausschließlich synthetisch
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;

-- RT-A-008:
-- Der geteilte Anchor-Umbau muss sowohl eine 1024-spaltige Quelle als auch
-- ein bereits 1024-spaltiges Ziel verarbeiten, ohne das Engine-Limit von
-- 1024 Spalten zwischenzeitlich zu überschreiten.
DROP TABLE IF EXISTS dbo.tbx_ResultTableBoundary_Source1024;

DECLARE
      @CreateSourceSql nvarchar(max)
    , @ColumnList      nvarchar(max);

;WITH Numbers AS
(
    SELECT TOP (1024)
        ROW_NUMBER() OVER (ORDER BY ao1.object_id, ao2.object_id) AS NumberValue
    FROM sys.all_objects AS ao1
    CROSS JOIN sys.all_objects AS ao2
)
SELECT @ColumnList =
    STUFF
    (
        (
            SELECT
                  N', [C'
                + RIGHT(N'0000' + CONVERT(nvarchar(4), n.NumberValue), 4)
                + N'] int NULL'
            FROM Numbers AS n
            ORDER BY n.NumberValue
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)')
      , 1
      , 2
      , N''
    );

SET @CreateSourceSql =
    N'CREATE TABLE dbo.tbx_ResultTableBoundary_Source1024 ('
    + @ColumnList
    + N');';

EXEC sys.sp_executesql @CreateSourceSql;

CREATE TABLE #ResultTableBoundary
(
    DummyValue int NULL
);

DECLARE @BoundaryObjectId int =
    OBJECT_ID(N'tempdb..[#ResultTableBoundary]', N'U');

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableBoundary'
    , @LikeTable          = N'dbo.tbx_ResultTableBoundary_Source1024'
    , @KeepData           = 0;

IF OBJECT_ID(N'tempdb..[#ResultTableBoundary]', N'U') <> @BoundaryObjectId
   OR
   (
       SELECT COUNT(*)
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = @BoundaryObjectId
   ) <> 1024
   OR NOT EXISTS
   (
       SELECT 1
       FROM
       (
           SELECT
                 ROW_NUMBER() OVER (ORDER BY c.column_id) AS ColumnOrdinal
               , c.name AS ColumnName
           FROM tempdb.sys.columns AS c
           WHERE c.object_id = @BoundaryObjectId
       ) AS actual
       WHERE actual.ColumnOrdinal = 1024
         AND actual.ColumnName COLLATE Latin1_General_100_BIN2 = N'C1024'
   )
BEGIN
    THROW 52310, N'Der Umbau auf exakt 1024 Spalten ist fehlgeschlagen.', 1;
END;

CREATE TABLE #tbx_ResultTableBoundary_OneColumn
(
    OnlyValue bigint NOT NULL
);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableBoundary'
    , @LikeTable          = N'#tbx_ResultTableBoundary_OneColumn'
    , @KeepData           = 0;

IF OBJECT_ID(N'tempdb..[#ResultTableBoundary]', N'U') <> @BoundaryObjectId
   OR
   (
       SELECT COUNT(*)
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = @BoundaryObjectId
   ) <> 1
   OR NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = @BoundaryObjectId
         AND c.name COLLATE Latin1_General_100_BIN2 = N'OnlyValue'
         AND c.is_nullable = 0
   )
BEGIN
    THROW 52311, N'Der Umbau von exakt 1024 Spalten ist fehlgeschlagen.', 1;
END;

DROP TABLE dbo.tbx_ResultTableBoundary_Source1024;
DROP TABLE #tbx_ResultTableBoundary_OneColumn;
DROP TABLE #ResultTableBoundary;

-- RT-X-003:
-- Eine erfolgreiche Mutation in einer Caller-Transaktion lässt deren
-- Transaktionszähler und bereits vorhandene Änderungen unangetastet.
CREATE TABLE #ResultTableTransaction
(
    DummyValue int NULL
);

CREATE TABLE #tbx_ResultTableTransaction_Shape
(
    PreparedValue bigint NOT NULL
);

CREATE TABLE #CallerTransactionMarker
(
    MarkerValue int NOT NULL
);

BEGIN TRANSACTION;

INSERT INTO #CallerTransactionMarker (MarkerValue)
VALUES (17);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableTransaction'
    , @LikeTable          = N'#tbx_ResultTableTransaction_Shape'
    , @KeepData           = 0;

IF @@TRANCOUNT <> 1
   OR NOT EXISTS
      (
          SELECT 1
          FROM #CallerTransactionMarker
          WHERE MarkerValue = 17
      )
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52312, N'Die Procedure hat den Scope der Caller-Transaktion verändert.', 1;
END;

ROLLBACK TRANSACTION;

-- RT-X-005/006:
-- Im uncommittable Zustand erfolgt Fehler 51028 vor der ResultTable-Mutation.
CREATE TABLE #DoomedTransactionSource
(
    KeyValue int NOT NULL PRIMARY KEY
);

INSERT INTO #DoomedTransactionSource (KeyValue)
VALUES (1);

CREATE TABLE #ResultTableDoomed
(
    OriginalValue int NULL
);

CREATE TABLE #tbx_ResultTableDoomed_Shape
(
    ReplacementValue bigint NOT NULL
);

DECLARE
      @DoomedStateObserved bit = 0
    , @DoomedErrorNumber  int;

SET XACT_ABORT ON;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO #DoomedTransactionSource (KeyValue)
    VALUES (1);
END TRY
BEGIN CATCH
    SET @DoomedStateObserved =
        CONVERT(bit, CASE WHEN XACT_STATE() = -1 THEN 1 ELSE 0 END);

    IF @DoomedStateObserved = 1
    BEGIN
        BEGIN TRY
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = N'#ResultTableDoomed'
                , @LikeTable          = N'#tbx_ResultTableDoomed_Shape'
                , @KeepData           = 0;
        END TRY
        BEGIN CATCH
            SET @DoomedErrorNumber = ERROR_NUMBER();
        END CATCH;
    END;
END CATCH;

IF XACT_STATE() <> 0
BEGIN
    ROLLBACK TRANSACTION;
END;

SET XACT_ABORT OFF;

IF @DoomedStateObserved <> 1
BEGIN
    THROW 52313, N'Die synthetische Vorbereitung erzeugte keinen uncommittable Zustand.', 1;
END;

IF @DoomedErrorNumber <> 51028
BEGIN
    THROW 52314, N'Im uncommittable Zustand wurde nicht Fehler 51028 geliefert.', 1;
END;

IF
(
    SELECT COUNT(*)
    FROM tempdb.sys.columns AS c
    WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableDoomed]', N'U')
) <> 1
   OR NOT EXISTS
      (
          SELECT 1
          FROM tempdb.sys.columns AS c
          WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableDoomed]', N'U')
            AND c.name COLLATE Latin1_General_100_BIN2 = N'OriginalValue'
      )
BEGIN
    THROW 52315, N'Der uncommittable Aufruf hat die Zieltable verändert.', 1;
END;

DROP TABLE #tbx_ResultTableDoomed_Shape;
DROP TABLE #ResultTableDoomed;
DROP TABLE #DoomedTransactionSource;
DROP TABLE #CallerTransactionMarker;
DROP TABLE #tbx_ResultTableTransaction_Shape;
DROP TABLE #ResultTableTransaction;

PRINT N'USP_PrepareResultTable Grenz- und Transaktionsvertrag: erfolgreich';
GO
