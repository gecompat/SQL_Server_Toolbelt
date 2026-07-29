-- ============================================================================
-- Collation-Contract für toolbelt_core.USP_PrepareResultTable
-- Daten: ausschließlich synthetisch
-- Voraussetzung: Modul v1.0.0 ist in der aktuellen Datenbank installiert.
-- ============================================================================

SET NOCOUNT ON;

-- RT-L-013/RT-T-005/006/RT-E-009:
-- Zeichenspalten behalten ihre explizite Referenz-Collation.
CREATE TABLE #ResultTableCollation
(
    DummyValue varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

CREATE TABLE #tbx_ResultTableCollation_Shape
(
      CaseValue   varchar(40)  COLLATE Latin1_General_100_CS_AS   NOT NULL
    , BinaryValue nvarchar(40) COLLATE Latin1_General_100_BIN2    NULL
    , Utf8Value   varchar(40)  COLLATE Latin1_General_100_BIN2_UTF8 NULL
);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableCollation'
    , @LikeTable          = N'#tbx_ResultTableCollation_Shape'
    , @KeepData           = 0;

DECLARE @CollationObjectId int =
    OBJECT_ID(N'tempdb..[#ResultTableCollation]', N'U');

IF
(
    SELECT COUNT(*)
    FROM tempdb.sys.columns AS c
    WHERE c.object_id = @CollationObjectId
) <> 3
   OR NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = @CollationObjectId
         AND c.name COLLATE Latin1_General_100_BIN2 = N'CaseValue'
         AND c.collation_name COLLATE Latin1_General_100_BIN2
                 = N'Latin1_General_100_CS_AS'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = @CollationObjectId
         AND c.name COLLATE Latin1_General_100_BIN2 = N'BinaryValue'
         AND c.collation_name COLLATE Latin1_General_100_BIN2
                 = N'Latin1_General_100_BIN2'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = @CollationObjectId
         AND c.name COLLATE Latin1_General_100_BIN2 = N'Utf8Value'
         AND c.collation_name COLLATE Latin1_General_100_BIN2
                 = N'Latin1_General_100_BIN2_UTF8'
   )
BEGIN
    THROW 52300, N'Die Zieltable hat die Referenz-Collations nicht exakt übernommen.', 1;
END;

-- RT-E-013:
-- Technische Namen werden binär verglichen; ein reiner Case-Unterschied
-- erzwingt deshalb den dokumentierten Schemaumbau.
CREATE TABLE #ResultTableCase
(
    [ValueName] int NULL
);

CREATE TABLE #tbx_ResultTableCase_Shape
(
    [valuename] int NULL
);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableCase'
    , @LikeTable          = N'#tbx_ResultTableCase_Shape'
    , @KeepData           = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableCase]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'valuename'
   )
   OR EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableCase]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'ValueName'
   )
BEGIN
    THROW 52301, N'Der binäre Spaltennamenvergleich hat den Case-Unterschied nicht erkannt.', 1;
END;

DROP TABLE #tbx_ResultTableCase_Shape;
DROP TABLE #ResultTableCase;
DROP TABLE #tbx_ResultTableCollation_Shape;
DROP TABLE #ResultTableCollation;

PRINT N'USP_PrepareResultTable Collation-Contract: erfolgreich';
GO
