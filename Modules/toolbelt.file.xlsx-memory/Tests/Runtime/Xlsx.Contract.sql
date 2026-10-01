SET NOCOUNT ON;
DECLARE @Binary varbinary(max)=$(XlsxFixture);
CREATE TABLE #Sheets(Dummy int);
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#Sheets';
IF (SELECT COUNT(*) FROM #Sheets)<>1 THROW 51590,N'Sheet count oracle failed.',1;
IF EXISTS(SELECT 1 FROM #Sheets WHERE SheetOrdinal<>1 OR SheetName IS NULL OR SheetName<>N'Synthetic' OR Visibility<>N'hidden' OR Date1904<>1)
 THROW 51590,N'Sheet metadata oracle failed.',1;
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#Sheets',@KeepData=1;
IF (SELECT COUNT(*) FROM #Sheets)<>2 THROW 51590,N'Append oracle failed.',1;
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#Sheets',@KeepData=0;
IF (SELECT COUNT(*) FROM #Sheets)<>1 THROW 51590,N'Replace oracle failed.',1;

CREATE TABLE #Cells(Dummy uniqueidentifier);
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Binary,@SheetOrdinal=1,@ResultTable=N'#Cells';
IF (SELECT COUNT(*) FROM #Cells)<>9 THROW 51590,N'Sparse cell count oracle failed.',1;
IF NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND StoredType=N's'
 AND ValuePresent=1 AND RawValue=N'0' AND TextValue=N'tail ä😀' AND FormulaPresent=0 AND CachePresent=0)
 THROW 51590,N'Unicode shared string oracle failed.',1;
IF NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1 AND ColumnOrdinal=3 AND StoredType=N'inlineStr'
 AND ValuePresent=0 AND RawValue IS NULL AND TextValue IS NOT NULL AND DATALENGTH(TextValue)=0)
 THROW 51590,N'Empty inline oracle failed.',1;
IF NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1 AND ColumnOrdinal=4 AND ValuePresent=1
 AND RawValue IS NOT NULL AND DATALENGTH(RawValue)=0)
 THROW 51590,N'Empty value oracle failed.',1;
IF NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1 AND ColumnOrdinal=5 AND ValuePresent=0 AND RawValue IS NULL)
 THROW 51590,N'Missing value oracle failed.',1;
IF NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1 AND ColumnOrdinal=6 AND FormulaPresent=1
 AND FormulaText=N'SUM(A1)' AND FormulaKind=N'shared' AND SharedFormulaIndex=0 AND CachePresent=1
 AND CacheValue IS NOT NULL AND DATALENGTH(CacheValue)=0)
 THROW 51590,N'Formula cache oracle failed.',1;
IF NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1 AND ColumnOrdinal=7 AND FormulaPresent=1
 AND FormulaText IS NOT NULL AND DATALENGTH(FormulaText)=0 AND CachePresent=0 AND CacheValue IS NULL)
 THROW 51590,N'Empty shared formula oracle failed.',1;
IF NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1048576 AND ColumnOrdinal=16384 AND RawValue=N'42')
 THROW 51590,N'Coordinate oracle failed.',1;

-- NULL is deliberately early, including invalid limits, sheet and target.
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=NULL,@SheetOrdinal=NULL,@MaxCells=NULL,@ResultTable=N'#Cells';
IF (SELECT COUNT(*) FROM #Cells)<>9 THROW 51590,N'NULL target no-op oracle failed.',1;
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=NULL,@MaxParts=0,@ResultTable=N'not a temp table';

-- Compilergrenze: absichtlich fremdes Caller-Privatschema darf keine Engine207
-- auslösen. Help und NULL umgehen Namespace und Core-Kompilierung weiterhin.
CREATE TABLE #tbx_ListXlsxWorksheets_ResultSource(Sentinel int NOT NULL);
INSERT #tbx_ListXlsxWorksheets_ResultSource VALUES(7);
EXEC sys.sp_recompile N'toolbelt_file.USP_InternalXlsxRead';
BEGIN TRY EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary;
 THROW 51590,N'Expected private caller namespace rejection absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@Hilfe=1,@ResultTable=N'#TBX_BAD';
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=NULL,@SheetOrdinal=NULL,@ResultTable=N'#TBX_BAD';
IF (SELECT COUNT(*) FROM #tbx_ListXlsxWorksheets_ResultSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #tbx_ListXlsxWorksheets_ResultSource WHERE Sentinel=7)
 THROW 51590,N'Private caller namespace contents changed.',1;
DROP TABLE #tbx_ListXlsxWorksheets_ResultSource;
CREATE TABLE #tbx_ReadXlsxWorksheetCells_ResultSource(Sentinel int NOT NULL);
INSERT #tbx_ReadXlsxWorksheetCells_ResultSource VALUES(8);
EXEC sys.sp_recompile N'toolbelt_file.USP_InternalXlsxRead';
BEGIN TRY EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Binary,@SheetOrdinal=1;
 THROW 51590,N'Expected cell private caller namespace rejection absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;
DROP TABLE #tbx_ReadXlsxWorksheetCells_ResultSource;
BEGIN TRY EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#TBX_BAD';
 THROW 51590,N'Expected uppercase reserved result namespace rejection absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;

BEGIN TRY
 EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Binary,@SheetOrdinal=0,@ResultTable=N'#Cells';
 THROW 51590,N'Expected sheet error absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;
BEGIN TRY
 EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Binary,@SheetOrdinal=1,@MaxCells=8,@ResultTable=N'#Cells';
 THROW 51590,N'Expected cell limit error absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;
BEGIN TRY
 EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=0x010203,@SheetOrdinal=1,@ResultTable=N'#Cells';
 THROW 51590,N'Expected invalid ZIP error absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;
IF (SELECT COUNT(*) FROM #Cells)<>9 THROW 51590,N'Provider failure mutated target.',1;
DECLARE @Repeated varbinary(max)=$(XlsxRepeatedFixture);
BEGIN TRY
 EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Repeated,@SheetOrdinal=1,@ResultTable=N'#Cells';
 THROW 51590,N'Expected repeated SharedString output expansion rejection absent.',1;
END TRY BEGIN CATCH
 IF ERROR_NUMBER()<>51520 OR ERROR_MESSAGE()<>N'TBX_XLSX_COUNTED_ALLOCATION_LIMIT' THROW;
END CATCH;
IF (SELECT COUNT(*) FROM #Cells)<>9 OR NOT EXISTS(SELECT 1 FROM #Cells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND TextValue=N'tail ä😀')
 THROW 51590,N'Output expansion error mutated original result.',1;

-- Every configurable ceiling is strict, NULL and above ceiling rejected.
DECLARE @LimitName sysname,@Ceiling bigint,@Sql nvarchar(max);
DECLARE ConfigCases CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Ceiling FROM(VALUES
 (N'MaxArchiveBytes',CONVERT(bigint,16777216)),(N'MaxPartBytes',16777216),(N'MaxTotalUncompressedBytes',67108864),
 (N'MaxParts',256),(N'MaxSheets',32),(N'MaxCells',100000),(N'MaxSharedStrings',50000),
 (N'MaxSharedStringBytes',8388608),(N'MaxXmlDepth',64),(N'MaxCompressionRatio',200),(N'BudgetMilliseconds',5000))p(Name,Ceiling);
OPEN ConfigCases;FETCH NEXT FROM ConfigCases INTO @LimitName,@Ceiling;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Sql=N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@B,@SheetOrdinal=1,@'
   +@LimitName+N'='+CONVERT(nvarchar(32),@Ceiling+1)+N',@ResultTable=N''#Cells'';';
 BEGIN TRY EXEC sys.sp_executesql @Sql,N'@B varbinary(max)',@B=@Binary;THROW 51590,N'Ceiling +1 accepted.',1;
 END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;
 SET @Sql=N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@B,@SheetOrdinal=1,@'
   +@LimitName+N'=NULL,@ResultTable=N''#Cells'';';
 BEGIN TRY EXEC sys.sp_executesql @Sql,N'@B varbinary(max)',@B=@Binary;THROW 51590,N'NULL configuration accepted.',1;
 END TRY BEGIN CATCH IF ERROR_NUMBER()<>51520 THROW; END CATCH;
 FETCH NEXT FROM ConfigCases INTO @LimitName,@Ceiling;
END;
CLOSE ConfigCases;DEALLOCATE ConfigCases;
IF (SELECT COUNT(*) FROM #Cells)<>9 THROW 51590,N'Configuration failures mutated target.',1;

-- KeepData/schema incompatibility and real engine insert failure.
CREATE TABLE #Wrong(Dummy int);INSERT #Wrong VALUES(7);
BEGIN TRY EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#Wrong',@KeepData=1;
 THROW 51590,N'Expected schema blocker absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51025 THROW; END CATCH;
IF (SELECT COUNT(*) FROM #Wrong)<>1 OR NOT EXISTS(SELECT 1 FROM #Wrong WHERE Dummy=7)
 THROW 51590,N'Schema blocker mutated target.',1;
CREATE TABLE #Checked
 (SheetOrdinal int NOT NULL,SheetName nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
 Visibility nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,Date1904 bit NOT NULL,
 CHECK(SheetOrdinal=99));
INSERT #Checked VALUES(99,N'original',N'visible',0);
SET XACT_ABORT OFF;
BEGIN TRY EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#Checked';
 THROW 51590,N'Expected own transaction engine error absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51590,N'Own transaction restoration failed.',1;
IF (SELECT COUNT(*) FROM #Checked)<>1 OR NOT EXISTS(SELECT 1 FROM #Checked WHERE SheetOrdinal=99 AND SheetName=N'original')
 THROW 51590,N'Own transaction data restoration failed.',1;
BEGIN TRANSACTION;
BEGIN TRY EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#Checked';
 THROW 51590,N'Expected caller transaction engine error absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51590,N'Caller savepoint restoration failed.',1;
IF (SELECT COUNT(*) FROM #Checked)<>1 OR NOT EXISTS(SELECT 1 FROM #Checked WHERE SheetOrdinal=99 AND SheetName=N'original')
 THROW 51590,N'Caller data restoration failed.',1;
ROLLBACK TRANSACTION;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Binary,@ResultTable=N'#Checked';
 THROW 51590,N'Expected doomed caller engine error absent.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 THROW 51590,N'Doomed caller state failed.',1;
ROLLBACK TRANSACTION;
SET XACT_ABORT OFF;
IF (SELECT COUNT(*) FROM #Checked)<>1 OR NOT EXISTS(SELECT 1 FROM #Checked WHERE SheetOrdinal=99 AND SheetName=N'original')
 THROW 51590,N'Doomed caller postrollback data failed.',1;
PRINT N'PASS: XLSX public sparse/raw/text/formula/cache/NULL/configuration/ResultTable/transaction contracts.';
DROP TABLE #Checked;
DROP TABLE #Wrong;
DROP TABLE #Cells;
DROP TABLE #Sheets;

