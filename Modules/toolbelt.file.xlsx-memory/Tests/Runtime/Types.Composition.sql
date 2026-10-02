-- Ausschließlich synthetischer Workbookinhalt; Binary wird parametrisiert.
SET NOCOUNT ON;
CREATE TABLE #XlsxTypeRaw(RowOrdinal int NOT NULL,ColumnOrdinal int NOT NULL,StoredType nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,ValuePresent bit NOT NULL,RawValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,TextValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,FormulaPresent bit NOT NULL,FormulaText nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,FormulaKind nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,SharedFormulaIndex int NULL,CachePresent bit NOT NULL,CacheValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
EXEC [$(ToolbeltDatabase)].toolbelt_file.USP_ReadXlsxWorksheetCells
 @XlsxBinary=@Workbook,@SheetOrdinal=1,@ResultTable=N'#XlsxTypeRaw';
IF (SELECT COUNT(*) FROM #XlsxTypeRaw)<>9 THROW 51593,N'Raw composition count mismatch.',1;
IF NOT EXISTS(SELECT 1 FROM #XlsxTypeRaw WHERE RowOrdinal=1 AND ColumnOrdinal=6 AND FormulaPresent=1
 AND CONVERT(varbinary(max),FormulaText)=CONVERT(varbinary(max),N'SUM(A1)') AND CachePresent=1 AND DATALENGTH(CacheValue)=0)
 THROW 51593,N'Synthetic cached formula metadata mismatch.',2;
DECLARE @RawSchema TABLE(Ordinal int,Name sysname COLLATE DATABASE_DEFAULT,Kind sysname COLLATE DATABASE_DEFAULT);
INSERT @RawSchema VALUES(1,N'RowOrdinal',N'int'),(2,N'ColumnOrdinal',N'int'),(3,N'StoredType',N'nvarchar'),
 (4,N'ValuePresent',N'bit'),(5,N'RawValue',N'nvarchar'),(6,N'TextValue',N'nvarchar'),(7,N'FormulaPresent',N'bit'),
 (8,N'FormulaText',N'nvarchar'),(9,N'FormulaKind',N'nvarchar'),(10,N'SharedFormulaIndex',N'int'),(11,N'CachePresent',N'bit'),(12,N'CacheValue',N'nvarchar');
IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#XlsxTypeRaw'))<>12
 OR EXISTS(SELECT 1 FROM @RawSchema expected FULL JOIN
 (SELECT ROW_NUMBER() OVER(ORDER BY c.column_id) Ordinal,c.name,t.name Kind FROM tempdb.sys.columns c
 JOIN tempdb.sys.types t ON t.user_type_id=c.user_type_id WHERE c.object_id=OBJECT_ID(N'tempdb..#XlsxTypeRaw')) actual
 ON actual.Ordinal=expected.Ordinal
 WHERE expected.Ordinal IS NULL OR actual.Ordinal IS NULL OR CONVERT(varbinary(max),actual.name)<>CONVERT(varbinary(max),expected.Name)
 OR CONVERT(varbinary(max),actual.Kind)<>CONVERT(varbinary(max),expected.Kind))
 THROW 51593,N'Raw composition logical metadata mismatch.',3;

SELECT c.RowOrdinal,c.ColumnOrdinal,t.* INTO #XlsxTypeComposition
FROM #XlsxTypeRaw c CROSS APPLY [$(ToolbeltDatabase)].toolbelt_file.TVF_InterpretXlsxCell
 (c.StoredType,c.ValuePresent,c.RawValue,c.TextValue,NULL,NULL,1) t;
IF (SELECT COUNT(*) FROM #XlsxTypeComposition)<>9 THROW 51593,N'Type composition one-row cardinality mismatch.',4;
DECLARE @Expected TABLE(RowOrdinal int,ColumnOrdinal int,StoredType nvarchar(32) COLLATE Latin1_General_100_BIN2,
 ValuePresent bit,RawValue nvarchar(max) COLLATE Latin1_General_100_BIN2,TextValue nvarchar(max) COLLATE Latin1_General_100_BIN2,
 StatusCode int,ResolvedType nvarchar(16) COLLATE Latin1_General_100_BIN2,TypedTextValue nvarchar(max) COLLATE Latin1_General_100_BIN2,
 NumberValue decimal(38,0),BooleanValue bit);
INSERT @Expected VALUES
 (1,1,N's',1,N'0',N'tail ä😀',0,N'text',N'tail ä😀',NULL,NULL),
 (1,3,N'inlineStr',0,NULL,N'',0,N'text',N'',NULL,NULL),
 (1,4,N'n',1,N'',NULL,4,N'number',NULL,NULL,NULL),
 (1,5,N'n',0,NULL,NULL,1,NULL,NULL,NULL,NULL),
 (1,6,N'n',1,N'',NULL,4,N'number',NULL,NULL,NULL),
 (1,7,N'n',0,NULL,NULL,1,NULL,NULL,NULL,NULL),
 (1,8,N'b',1,N'1',NULL,0,N'boolean',NULL,NULL,1),
 (1,9,N'e',1,N'#DIV/0!',NULL,10,N'text',NULL,NULL,NULL),
 (1048576,16384,N'n',1,N'42',NULL,0,N'number',NULL,42,NULL);
IF EXISTS(SELECT RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),StoredType),ValuePresent,
 CONVERT(varbinary(max),RawValue),CONVERT(varbinary(max),TextValue),StatusCode,CONVERT(varbinary(max),ResolvedType),
 CONVERT(varbinary(max),TypedTextValue),TRY_CONVERT(decimal(38,0),NumberValue),BooleanValue FROM #XlsxTypeComposition
 EXCEPT SELECT RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),StoredType),ValuePresent,
 CONVERT(varbinary(max),RawValue),CONVERT(varbinary(max),TextValue),StatusCode,CONVERT(varbinary(max),ResolvedType),
 CONVERT(varbinary(max),TypedTextValue),NumberValue,BooleanValue FROM @Expected)
 OR EXISTS(SELECT RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),StoredType),ValuePresent,
 CONVERT(varbinary(max),RawValue),CONVERT(varbinary(max),TextValue),StatusCode,CONVERT(varbinary(max),ResolvedType),
 CONVERT(varbinary(max),TypedTextValue),NumberValue,BooleanValue FROM @Expected
 EXCEPT SELECT RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),StoredType),ValuePresent,
 CONVERT(varbinary(max),RawValue),CONVERT(varbinary(max),TextValue),StatusCode,CONVERT(varbinary(max),ResolvedType),
 CONVERT(varbinary(max),TypedTextValue),TRY_CONVERT(decimal(38,0),NumberValue),BooleanValue FROM #XlsxTypeComposition)
 THROW 51593,N'Raw to typed value or byte-exact echo mismatch.',5;
IF EXISTS(SELECT 1 FROM #XlsxTypeComposition WHERE EchoPreserved IS NULL OR EchoPreserved<>1 OR DateValue IS NOT NULL
 OR DateTimeValue IS NOT NULL OR TimeValue IS NOT NULL OR DurationTicks IS NOT NULL)
 THROW 51593,N'Raw composition atomic typed fields mismatch.',6;
IF EXISTS(SELECT 1 FROM #XlsxTypeComposition WHERE (RowOrdinal<>1048576 OR ColumnOrdinal<>16384) AND NumberValue IS NOT NULL)
 THROW 51593,N'Raw composition unexpected numeric typed value.',6;
IF NOT EXISTS(SELECT 1 FROM #XlsxTypeComposition WHERE RowOrdinal=1048576 AND ColumnOrdinal=16384
 AND SQL_VARIANT_PROPERTY(NumberValue,'BaseType') IN(N'decimal',N'numeric')
 AND SQL_VARIANT_PROPERTY(NumberValue,'Precision')=2 AND SQL_VARIANT_PROPERTY(NumberValue,'Scale')=0
 AND CONVERT(decimal(38,0),NumberValue)=42)
 THROW 51593,N'Raw composition exact numeric metadata mismatch.',7;
DECLARE @TypedSchema TABLE(Ordinal int,Name sysname COLLATE DATABASE_DEFAULT,Kind sysname COLLATE DATABASE_DEFAULT);
INSERT @TypedSchema VALUES(1,N'RowOrdinal',N'int'),(2,N'ColumnOrdinal',N'int'),(3,N'StoredType',N'nvarchar'),(4,N'ValuePresent',N'bit'),
 (5,N'RawValue',N'nvarchar'),(6,N'TextValue',N'nvarchar'),(7,N'EchoPreserved',N'bit'),(8,N'ResolvedType',N'nvarchar'),
 (9,N'NumberValue',N'sql_variant'),(10,N'BooleanValue',N'bit'),(11,N'DateValue',N'date'),(12,N'DateTimeValue',N'datetime2'),
 (13,N'TimeValue',N'time'),(14,N'DurationTicks',N'bigint'),(15,N'TypedTextValue',N'nvarchar'),(16,N'StatusCode',N'int');
IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#XlsxTypeComposition'))<>16
 OR EXISTS(SELECT 1 FROM @TypedSchema expected FULL JOIN
 (SELECT ROW_NUMBER() OVER(ORDER BY c.column_id) Ordinal,c.name,t.name Kind FROM tempdb.sys.columns c
 JOIN tempdb.sys.types t ON t.user_type_id=c.user_type_id WHERE c.object_id=OBJECT_ID(N'tempdb..#XlsxTypeComposition')) actual
 ON actual.Ordinal=expected.Ordinal
 WHERE expected.Ordinal IS NULL OR actual.Ordinal IS NULL OR CONVERT(varbinary(max),actual.name)<>CONVERT(varbinary(max),expected.Name)
 OR CONVERT(varbinary(max),actual.Kind)<>CONVERT(varbinary(max),expected.Kind))
 THROW 51593,N'Typed composition logical metadata mismatch.',8;
DROP TABLE #XlsxTypeComposition;DROP TABLE #XlsxTypeRaw;
