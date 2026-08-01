-- ============================================================================
-- Natürlicher Enginefehler- und Savepoint-Vertrag für USP_PrepareResultTable
-- Daten und Objekte: ausschließlich synthetisch
-- Voraussetzung: aktuelle Datenbank ist case-sensitive; tempdb ist
--                case-insensitive. Der Linux-CI-Runner stellt dies gezielt her.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;

IF N'A' COLLATE DATABASE_DEFAULT = N'a' COLLATE DATABASE_DEFAULT
BEGIN
    THROW 52330, N'Der Savepoint-Contract benötigt eine case-sensitive Testdatenbank.', 1;
END;

DROP TABLE IF EXISTS dbo.tbx_ResultTableSavepoint_Source;

-- Die Referenztabelle ist in der case-sensitiven Testdatenbank zulässig.
-- Beim späteren ADD in die lokale Temp-Tabelle kollidieren die beiden Namen
-- unter der case-insensitiven tempdb-Collation mit Enginefehler 2705.
CREATE TABLE dbo.tbx_ResultTableSavepoint_Source
(
      [CaseValue]  int    NULL
    , [casevalue]  bigint NULL
);

CREATE TABLE #ResultTableSavepoint
(
    OriginalValue int NOT NULL
);

INSERT INTO #ResultTableSavepoint (OriginalValue)
VALUES (42);

CREATE TABLE #CallerSavepointMarker
(
    MarkerValue int NOT NULL
);

DECLARE
      @TargetObjectId      int = OBJECT_ID(N'tempdb..[#ResultTableSavepoint]', N'U')
    , @ObservedErrorNumber int
    , @ObservedErrorState  int
    , @ObservedErrorLine   int;

BEGIN TRANSACTION;

INSERT INTO #CallerSavepointMarker (MarkerValue)
VALUES (17);

BEGIN TRY
    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = N'#ResultTableSavepoint'
        , @LikeTable          = N'dbo.tbx_ResultTableSavepoint_Source'
        , @KeepData           = 0;
END TRY
BEGIN CATCH
    SELECT
          @ObservedErrorNumber = ERROR_NUMBER()
        , @ObservedErrorState  = ERROR_STATE()
        , @ObservedErrorLine   = ERROR_LINE();
END CATCH;

IF @ObservedErrorNumber IS NULL
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52331, N'Der erwartete natürliche Spaltennamenskollision ist ausgeblieben.', 1;
END;

IF @ObservedErrorNumber <> 2705
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52332, N'Die Procedure hat nicht den unveränderten Enginefehler 2705 weitergegeben.', 1;
END;

IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
BEGIN
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW 52333, N'Der Enginefehler hat die Caller-Transaktion uncommittable gemacht oder ihren Zähler verändert.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM #CallerSavepointMarker
       WHERE MarkerValue = 17
   )
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52334, N'Der Savepoint-Rollback hat Änderungen vor dem Procedure-Aufruf entfernt.', 1;
END;

IF OBJECT_ID(N'tempdb..[#ResultTableSavepoint]', N'U') <> @TargetObjectId
   OR
   (
       SELECT COUNT(*)
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = @TargetObjectId
   ) <> 1
   OR NOT EXISTS
      (
          SELECT 1
          FROM tempdb.sys.columns AS c
          WHERE c.object_id = @TargetObjectId
            AND c.name COLLATE Latin1_General_100_BIN2 = N'OriginalValue'
            AND c.system_type_id = TYPE_ID(N'int')
            AND c.is_nullable = 0
      )
   OR EXISTS
      (
          SELECT 1
          FROM tempdb.sys.columns AS c
          WHERE c.object_id = @TargetObjectId
            AND c.name LIKE N'tbx[_]anchor[_]%'
      )
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52335, N'Der Savepoint-Rollback hat das ursprüngliche Zielschema nicht vollständig wiederhergestellt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM #ResultTableSavepoint
       WHERE OriginalValue = 42
   )
   OR (SELECT COUNT(*) FROM #ResultTableSavepoint) <> 1
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52336, N'Der Savepoint-Rollback hat die vor TRUNCATE vorhandenen Zieldaten nicht wiederhergestellt.', 1;
END;

ROLLBACK TRANSACTION;

DROP TABLE #CallerSavepointMarker;
DROP TABLE #ResultTableSavepoint;
DROP TABLE dbo.tbx_ResultTableSavepoint_Source;

PRINT N'USP_PrepareResultTable natürlicher Savepoint-Enginefehler: erfolgreich';
GO
