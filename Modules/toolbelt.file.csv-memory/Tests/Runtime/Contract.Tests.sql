-- Öffentlicher synthetischer CSV-Vertrag; alle Fachaufrufe über ResultTable, kein INSERT EXEC.
SET NOCOUNT ON;
CREATE TABLE #CsvContractCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
CREATE TABLE #CsvContractOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
DECLARE @Text nvarchar(max)=N'h,h'+NCHAR(13)+NCHAR(10)+N'NULL,"NULL"'+NCHAR(10)+N'"a,b","q""x"'+NCHAR(13)+NCHAR(10);
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@NullToken=N'NULL',@ResultTable=N'#CsvContractCells';
IF (SELECT COUNT_BIG(*) FROM #CsvContractCells)<>6
 OR NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE RowKind='HEADER' AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value]=N'h')
 OR NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE RowKind='DATA' AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NULL)
 OR NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),N'NULL'))
 OR NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE RowOrdinal=2 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),N'q"x'))
 THROW 55390,N'CSV contract: Header/NULL/Quote-Decoding weicht ab.',1;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvContractCells',@HasHeader=1,@NullToken=N'NULL',@ResultTable=N'#CsvContractOutput';
DECLARE @Expected nvarchar(max)=N'h,h'+NCHAR(13)+NCHAR(10)+N'NULL,"NULL"'+NCHAR(13)+NCHAR(10)+N'"a,b","q""x"'+NCHAR(13)+NCHAR(10);
IF (SELECT COUNT(*) FROM #CsvContractOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvContractOutput WHERE DataRows=2 AND ColumnCount=2 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 THROW 55390,N'CSV contract: kanonischer Writer weicht ab.',2;
CREATE TABLE #CsvContractRoundTrip(RowKind varchar(6) NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) NULL);
DECLARE @Written nvarchar(max)=(SELECT CsvText FROM #CsvContractOutput);
EXEC toolbelt_file.USP_ParseCsv @Text=@Written,@HasHeader=1,@NullToken=N'NULL',@ResultTable=N'#CsvContractRoundTrip';
IF EXISTS(SELECT RowKind,RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),[Value]) FROM #CsvContractCells EXCEPT SELECT RowKind,RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),[Value]) FROM #CsvContractRoundTrip)
 OR EXISTS(SELECT RowKind,RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),[Value]) FROM #CsvContractRoundTrip EXCEPT SELECT RowKind,RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),[Value]) FROM #CsvContractCells)
 THROW 55390,N'CSV contract: Roundtrip verliert Zellbytes.',3;
-- Trailing spaces sind Tokeninhalt; quoted Token bleibt Text.
EXEC toolbelt_file.USP_ParseCsv @Text=N'NULL ,"NULL ",NULL',@NullToken=N'NULL ',@ResultTable=N'#CsvContractCells';
IF NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE ColumnOrdinal=1 AND [Value] IS NULL)
 OR NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE ColumnOrdinal=2 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),N'NULL '))
 OR NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE ColumnOrdinal=3 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),N'NULL'))
 THROW 55390,N'CSV contract: Tokenpadding wurde verändert.',4;
-- Header-only und alternative Separator-/Abschlussform.
EXEC toolbelt_file.USP_ParseCsv @Text=N'NULL;h',@Separator=N';',@HasHeader=1,@NullToken=N'NULL',@ResultTable=N'#CsvContractCells';
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvContractCells',@Separator=N';',@HasHeader=1,@NullToken=N'NULL',@LineEnding='LF',@ResultTable=N'#CsvContractOutput';
SET @Expected=N'"NULL";h'+NCHAR(10);
IF (SELECT COUNT_BIG(*) FROM #CsvContractOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvContractOutput WHERE DataRows=0)
 THROW 55390,N'CSV contract: Header-only DATA-Recordzahl weicht ab.',15;
IF NOT EXISTS(SELECT 1 FROM #CsvContractOutput WHERE ColumnCount=2)
 THROW 55390,N'CSV contract: Header-only Spaltenzahl weicht ab.',16;
IF NOT EXISTS(SELECT 1 FROM #CsvContractOutput WHERE CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 THROW 55390,N'CSV contract: Header-only Tokenquotingbytes weichen ab.',17;
-- Leerer Input und finaler Recordabschluss erzeugen keinen zusätzlichen Record.
EXEC toolbelt_file.USP_ParseCsv @Text=N'',@HasHeader=1,@ResultTable=N'#CsvContractCells';
IF EXISTS(SELECT 1 FROM #CsvContractCells) THROW 55390,N'CSV contract: leerer Input erzeugt Zellen.',6;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvContractCells',@ResultTable=N'#CsvContractOutput';
IF NOT EXISTS(SELECT 1 FROM #CsvContractOutput WHERE DATALENGTH(CsvText)=0 AND DataRows=0 AND ColumnCount=0) THROW 55390,N'CSV contract: leere Writerquelle weicht ab.',7;
DECLARE @EmptyRecord nvarchar(1)=NCHAR(10);
EXEC toolbelt_file.USP_ParseCsv @Text=@EmptyRecord,@ResultTable=N'#CsvContractCells';
IF (SELECT COUNT(*) FROM #CsvContractCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvContractCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=0)
 THROW 55390,N'CSV contract: leerer Einspaltenrecord weicht ab.',8;
-- UTF-16-Codeeinheiten einschließlich NUL, ungepaartem Surrogat und BOM bleiben erhalten.
DECLARE @Raw nvarchar(max)=CONVERT(nvarchar(max),0x6100000000D86200)+NCHAR(65279)+N' ';
TRUNCATE TABLE #CsvContractCells;
INSERT #CsvContractCells VALUES('DATA',1,1,@Raw);
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvContractCells',@LineEnding='LF',@ResultTable=N'#CsvContractOutput';
SET @Written=(SELECT CsvText FROM #CsvContractOutput);
EXEC toolbelt_file.USP_ParseCsv @Text=@Written,@ResultTable=N'#CsvContractRoundTrip';
IF NOT EXISTS(SELECT 1 FROM #CsvContractRoundTrip WHERE CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Raw))
 THROW 55390,N'CSV contract: rohe UTF-16-Codeeinheiten wurden ersetzt.',9;
-- Anhängen verwendet dieselbe Zielschemaform; zusätzlicher Index ist kein Verbot.
CREATE INDEX IX_CsvContractRoundTrip_Row ON #CsvContractRoundTrip(RowOrdinal,ColumnOrdinal);
EXEC toolbelt_file.USP_ParseCsv @Text=N'x',@ResultTable=N'#CsvContractRoundTrip',@KeepData=1;
IF (SELECT COUNT(*) FROM #CsvContractRoundTrip)<>2 THROW 55390,N'CSV contract: Append weicht ab.',10;
-- Alle Schema-/KeepData-Konstellationen verwenden die kanonische Infrastruktur.
CREATE TABLE #CsvContractRebuildA(ArbitraryBinary varbinary(8));
CREATE TABLE #CsvContractRebuildB(ArbitraryBinary varbinary(8));
EXEC toolbelt_file.USP_ParseCsv @Text=N'x',@ResultTable=N'#CsvContractRebuildA',@KeepData=0;
EXEC toolbelt_file.USP_ParseCsv @Text=N'y',@ResultTable=N'#CsvContractRebuildB',@KeepData=1;
CREATE TABLE #CsvContractWrongData(Marker int NOT NULL);
INSERT #CsvContractWrongData VALUES(73);
DECLARE @Caught bit=0;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'x',@ResultTable=N'#CsvContractWrongData',@KeepData=1; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>51025 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR NOT EXISTS(SELECT 1 FROM #CsvContractWrongData WHERE Marker=73) THROW 55390,N'CSV contract: Append bei falschem belegtem Schema wurde akzeptiert.',11;
EXEC toolbelt_file.USP_ParseCsv @Text=N'z',@ResultTable=N'#CsvContractWrongData',@KeepData=0;
-- Getrennte Compilergrenze: diese Tabellen besaßen vor dem Helper andere Spalten.
EXEC sys.sp_executesql N'IF NOT EXISTS(SELECT 1 FROM #CsvContractRebuildA WHERE [Value]=N''x'') OR NOT EXISTS(SELECT 1 FROM #CsvContractRebuildB WHERE [Value]=N''y'') OR NOT EXISTS(SELECT 1 FROM #CsvContractWrongData WHERE [Value]=N''z'') THROW 55390,N''CSV contract: freigegebener Schemaumbau weicht ab.'',12;';
-- Ein zulässiger Tempname mit Punkt und schließender Klammer bleibt ein einzelner Bezeichner.
CREATE TABLE [#Csv.Dot]]Cell](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
EXEC toolbelt_file.USP_ParseCsv @Text=N'x',@ResultTable=N'#Csv.Dot]Cell';
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#Csv.Dot]Cell',@LineEnding='LF',@ResultTable=N'#CsvContractOutput';
IF NOT EXISTS(SELECT 1 FROM #CsvContractOutput WHERE CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),N'x'+NCHAR(10)) AND DataRows=1 AND ColumnCount=1)
 THROW 55390,N'CSV contract: zulässiger Tempbezeichner wurde falsch aufgelöst.',13;
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#Csv.Dot]Cell',@ResultTable=N'#Csv.Dot]Cell'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT(*) FROM [#Csv.Dot]]Cell])<>1 OR NOT EXISTS(SELECT 1 FROM [#Csv.Dot]]Cell] WHERE [Value]=N'x')
 THROW 55390,N'CSV contract: identische ungewöhnliche Quelle/Ziel wurde nicht unverändert abgewiesen.',14;
DROP TABLE [#Csv.Dot]]Cell];
DROP TABLE #CsvContractWrongData;
DROP TABLE #CsvContractRebuildB;
DROP TABLE #CsvContractRebuildA;
DROP TABLE #CsvContractRoundTrip;
DROP TABLE #CsvContractOutput;
DROP TABLE #CsvContractCells;
SELECT N'PASS' AS Status;
GO
