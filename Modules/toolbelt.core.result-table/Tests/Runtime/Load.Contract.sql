-- Pflicht-Lastfall: 100000 synthetische Zeilen, 50 KeepData-Aufrufe,
-- 20 Leerungen und zehn Schemawechsel in beide Richtungen.
-- Daten, Schema und Indexerhalt werden geprüft; keine Zeitmessung.
SET NOCOUNT ON;

CREATE TABLE #ResultTableLoad (DummyValue int NULL);
CREATE TABLE #tbx_ResultTableLoad_ShapeA
(
    ItemOrdinal bigint NOT NULL,
    ItemCode varchar(40) COLLATE Latin1_General_100_BIN2 NOT NULL,
    ItemText nvarchar(200) COLLATE Latin1_General_100_CS_AS NULL
);
CREATE TABLE #tbx_ResultTableLoad_ShapeB
(
    AlternateOrdinal int NOT NULL,
    AlternateValue decimal(19, 4) NULL
);

DECLARE @ReturnCode int;
EXEC @ReturnCode = toolbelt_core.USP_PrepareResultTable
    @ResultTableToAlter=N'#ResultTableLoad', @LikeTable=N'#tbx_ResultTableLoad_ShapeA', @KeepData=0;
IF @ReturnCode IS NULL OR @ReturnCode <> 0
    THROW 52122, N'Der Lastfall konnte die Ergebnistabelle nicht vorbereiten.', 1;

CREATE INDEX IX_ResultTableLoad_ItemCode ON #ResultTableLoad(ItemCode);
DECLARE @ObjectId int = OBJECT_ID(N'tempdb..#ResultTableLoad', N'U');
DECLARE @IndexId int = (SELECT index_id FROM tempdb.sys.indexes
    WHERE object_id=@ObjectId AND name=N'IX_ResultTableLoad_ItemCode');

;WITH digits AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS v(n))
INSERT INTO #ResultTableLoad(ItemOrdinal, ItemCode, ItemText)
SELECT CONVERT(bigint, 1 + a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n),
       'SYNTHETIC', N'Synthetic workload'
FROM digits AS a CROSS JOIN digits AS b CROSS JOIN digits AS c
CROSS JOIN digits AS d CROSS JOIN digits AS e;

DECLARE @Iteration int=0;
WHILE @Iteration < 50
BEGIN
    EXEC @ReturnCode = toolbelt_core.USP_PrepareResultTable
        @ResultTableToAlter=N'#ResultTableLoad', @LikeTable=N'#tbx_ResultTableLoad_ShapeA', @KeepData=1;
    IF @ReturnCode IS NULL OR @ReturnCode <> 0
        THROW 52123, N'Ein KeepData-Aufruf im Lastfall schlug fehl.', 1;
    SET @Iteration += 1;
END;

IF (SELECT COUNT_BIG(*) FROM #ResultTableLoad) <> 100000
   OR (SELECT COUNT_BIG(DISTINCT ItemOrdinal) FROM #ResultTableLoad) <> 100000
   OR (SELECT MIN(ItemOrdinal) FROM #ResultTableLoad) <> 1
   OR (SELECT MAX(ItemOrdinal) FROM #ResultTableLoad) <> 100000
   OR EXISTS (SELECT 1 FROM #ResultTableLoad WHERE ItemOrdinal IS NULL
       OR ItemCode IS NULL OR ItemCode <> 'SYNTHETIC' OR DATALENGTH(ItemCode) <> 9
       OR ItemText IS NULL OR ItemText <> N'Synthetic workload' OR DATALENGTH(ItemText) <> 36)
    THROW 52124, N'KeepData veränderte die synthetische Wertemenge im Lastfall.', 1;

SET @Iteration=0;
WHILE @Iteration < 20
BEGIN
    EXEC @ReturnCode = toolbelt_core.USP_PrepareResultTable
        @ResultTableToAlter=N'#ResultTableLoad', @LikeTable=N'#tbx_ResultTableLoad_ShapeA', @KeepData=0;
    IF @ReturnCode IS NULL OR @ReturnCode <> 0 OR EXISTS (SELECT 1 FROM #ResultTableLoad)
        THROW 52125, N'Der Lastfall leerte die Ergebnistabelle nicht vollständig.', 1;
    IF NOT EXISTS (SELECT 1 FROM tempdb.sys.indexes
        WHERE object_id=@ObjectId AND index_id=@IndexId AND name=N'IX_ResultTableLoad_ItemCode')
        THROW 52126, N'Eine schemaidentische Operation verlor den Index im Lastfall.', 1;
    INSERT INTO #ResultTableLoad(ItemOrdinal, ItemCode, ItemText)
    VALUES(@Iteration, 'SYNTHETIC', N'Synthetic workload');
    SET @Iteration += 1;
END;

DROP INDEX IX_ResultTableLoad_ItemCode ON #ResultTableLoad;
SET @Iteration=0;
WHILE @Iteration < 20
BEGIN
    DECLARE @LikeTable sysname = CASE WHEN @Iteration % 2 = 0
        THEN N'#tbx_ResultTableLoad_ShapeB' ELSE N'#tbx_ResultTableLoad_ShapeA' END;
    EXEC @ReturnCode = toolbelt_core.USP_PrepareResultTable
        @ResultTableToAlter=N'#ResultTableLoad', @LikeTable=@LikeTable, @KeepData=0;
    IF @ReturnCode IS NULL OR @ReturnCode <> 0 OR EXISTS (SELECT 1 FROM #ResultTableLoad)
        THROW 52127, N'Der Schemawechsel im Lastfall schlug fehl oder ließ Daten zurück.', 1;

    -- Beidseitiger Vergleich erfasst auch zusätzliche oder fehlende Spalten.
    DECLARE @ReferenceId int = OBJECT_ID(N'tempdb..' + @LikeTable, N'U');
    IF EXISTS (
        SELECT ROW_NUMBER() OVER (ORDER BY column_id), name, system_type_id, max_length, precision, scale, is_nullable, collation_name
        FROM tempdb.sys.columns WHERE object_id=@ObjectId
        EXCEPT
        SELECT ROW_NUMBER() OVER (ORDER BY column_id), name, system_type_id, max_length, precision, scale, is_nullable, collation_name
        FROM tempdb.sys.columns WHERE object_id=@ReferenceId)
       OR EXISTS (
        SELECT ROW_NUMBER() OVER (ORDER BY column_id), name, system_type_id, max_length, precision, scale, is_nullable, collation_name
        FROM tempdb.sys.columns WHERE object_id=@ReferenceId
        EXCEPT
        SELECT ROW_NUMBER() OVER (ORDER BY column_id), name, system_type_id, max_length, precision, scale, is_nullable, collation_name
        FROM tempdb.sys.columns WHERE object_id=@ObjectId)
        THROW 52128, N'Das Lastfallschema entspricht nicht der Referenz.', 1;
    SET @Iteration += 1;
END;

DROP TABLE #ResultTableLoad, #tbx_ResultTableLoad_ShapeA, #tbx_ResultTableLoad_ShapeB;
PRINT N'ResultTable Pflicht-Lastfall mit Ergebnisprüfung: erfolgreich.';
GO
