-- Globale DEFAULT-Snapshotgrenze des CSV-Writers mit unabhängigen Byteorakeln.
-- Bei zwei unquotierten Zellen benötigt CRLF zusätzlich sechs UTF16-Bytes.
-- Genau 16 MiB Rohwerte können deshalb nicht zugleich als gültige vollständige
-- Ausgabe unter derselben 16-MiB-Decke gelten. Beide Budgetpfade haben denselben
-- öffentlichen Fehler55303/State1. Dieser Test belegt die kombinierte Grenze,
-- keine unabhängig beobachtbare DEFAULT-Snapshotguard-Priorität und keine
-- Laufzeit-/Heapzusage. Die getrennten kleineren Wertbudgets bleiben separat.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE #ApiSnapshotCells
(
 RowKind varchar(6) COLLATE DATABASE_DEFAULT NOT NULL,
 RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,
 [Value] nvarchar(max) COLLATE DATABASE_DEFAULT NULL,
 PRIMARY KEY(RowOrdinal,ColumnOrdinal)
);
CREATE TABLE #ApiSnapshotOutput
(
 CsvText nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL,
 DataRows bigint NOT NULL,ColumnCount int NOT NULL
);
DECLARE @A nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),4194304);
DECLARE @B nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),4194301);
INSERT #ApiSnapshotCells VALUES('DATA',1,1,@A),('DATA',1,2,@B);
DECLARE @SourceId int=OBJECT_ID(N'tempdb..#ApiSnapshotCells',N'U');
DECLARE @TargetId int=OBJECT_ID(N'tempdb..#ApiSnapshotOutput',N'U');
DECLARE @Keep bit=0,@Actual nvarchar(max),@Expected nvarchar(max);
DECLARE @Progress TABLE(Id int NOT NULL PRIMARY KEY);

-- cap-6 Rohbytes ergeben genau cap Outputbytes; Replace und Append separat.
WHILE @Keep IS NOT NULL
BEGIN
 TRUNCATE TABLE #ApiSnapshotOutput;
 INSERT #ApiSnapshotOutput VALUES(N'preserved',73,7);
 SET @Expected=@A+N','+@B+NCHAR(13)+NCHAR(10);
 IF DATALENGTH(@A)+CONVERT(bigint,DATALENGTH(@B))<>16777210
    OR DATALENGTH(@Expected)<>16777216
  THROW 55396,N'CSV snapshot: unabhängige Erfolgsfixture ist falsch.',1;
 EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#ApiSnapshotCells',
  @ResultTable=N'#ApiSnapshotOutput',@KeepData=@Keep;
 IF (SELECT COUNT_BIG(*) FROM #ApiSnapshotOutput)<>1+CONVERT(int,@Keep)
    OR NOT EXISTS(SELECT 1 FROM #ApiSnapshotOutput WHERE DataRows=1 AND ColumnCount=2
       AND DATALENGTH(CsvText)=16777216
       AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
  THROW 55396,N'CSV snapshot: vollständige Ausgabe oder Metadaten falsch.',2;
 IF @Keep=1 AND NOT EXISTS(SELECT 1 FROM #ApiSnapshotOutput WHERE DataRows=73
       AND ColumnCount=7 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),N'preserved'))
  THROW 55396,N'CSV snapshot: Append verlor den Altwert.',3;
 INSERT @Progress VALUES(1+CONVERT(int,@Keep));
 SET @Keep=CASE WHEN @Keep=0 THEN 1 END;
END;

-- Omitted DEFAULT und ausdrückliches DEFAULT, je KeepData0/1 und cap/cap+2.
DECLARE @Case int=0,@AtCap bit,@Explicit bit,@Caught bit,@ExpectedState int;
WHILE @Case<8
BEGIN
 SET @AtCap=CASE WHEN @Case<4 THEN 1 ELSE 0 END;
 SET @Explicit=CONVERT(bit,(@Case/2)%2);
 SET @Keep=CONVERT(bit,@Case%2);
 SET @B=REPLICATE(CONVERT(nvarchar(max),N'b'),CASE WHEN @AtCap=1 THEN 4194304 ELSE 4194305 END);
 UPDATE #ApiSnapshotCells SET [Value]=@B WHERE ColumnOrdinal=2;
 IF DATALENGTH(@A)+CONVERT(bigint,DATALENGTH(@B))<>
       CASE WHEN @AtCap=1 THEN 16777216 ELSE 16777218 END
  THROW 55396,N'CSV snapshot: unabhängige Abweisungsfixture ist falsch.',4;
 TRUNCATE TABLE #ApiSnapshotOutput;
 INSERT #ApiSnapshotOutput VALUES(N'preserved',73,7);
 SET @Caught=0;
 SET @ExpectedState=1;
 BEGIN TRY
  IF @Explicit=1
   EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#ApiSnapshotCells',
    @MaxValueBytes=DEFAULT,@ResultTable=N'#ApiSnapshotOutput',@KeepData=@Keep;
  ELSE
   EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#ApiSnapshotCells',
    @ResultTable=N'#ApiSnapshotOutput',@KeepData=@Keep;
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>@ExpectedState THROW;
  SET @Caught=1;
 END CATCH;
 IF @Caught<>1 OR (SELECT COUNT_BIG(*) FROM #ApiSnapshotOutput)<>1
    OR NOT EXISTS(SELECT 1 FROM #ApiSnapshotOutput WHERE DataRows=73 AND ColumnCount=7
       AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),N'preserved'))
  THROW 55396,N'CSV snapshot: kombinierte Budgetablehnung oder Zielerhalt falsch.',5;
 IF (SELECT COUNT_BIG(*) FROM #ApiSnapshotCells)<>2
    OR NOT EXISTS(SELECT 1 FROM #ApiSnapshotCells WHERE RowKind='DATA' AND RowOrdinal=1 AND ColumnOrdinal=1
       AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@A))
    OR NOT EXISTS(SELECT 1 FROM #ApiSnapshotCells WHERE RowKind='DATA' AND RowOrdinal=1 AND ColumnOrdinal=2
       AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@B))
  THROW 55396,N'CSV snapshot: Quelle wurde verändert.',6;
 IF OBJECT_ID(N'tempdb..#ApiSnapshotCells',N'U')<>@SourceId
    OR OBJECT_ID(N'tempdb..#ApiSnapshotOutput',N'U')<>@TargetId OR @@TRANCOUNT<>0
  THROW 55396,N'CSV snapshot: Objektidentität oder Transaktion verändert.',7;
 INSERT @Progress VALUES(3+@Case);
 SET @Case+=1;
END;
IF (SELECT COUNT(*) FROM @Progress)<>10
 THROW 55396,N'CSV snapshot: nicht alle zehn Fälle erreicht.',8;
