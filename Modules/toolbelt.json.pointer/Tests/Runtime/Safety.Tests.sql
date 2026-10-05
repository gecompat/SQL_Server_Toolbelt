-- Synthetische Pointer-Oracles; keine Installation, Konfiguration oder Rechteänderung.
SET NOCOUNT ON;
DECLARE @Database sysname=NULLIF(N'$(ToolbeltDatabase)',N''),@Prefix nvarchar(520);
SET @Prefix=CASE WHEN @Database IS NULL THEN N'' ELSE QUOTENAME(@Database)+N'.' END+N'toolbelt_json.';
IF OBJECT_ID(N'tempdb..#tbx_Pointer_Cases') IS NOT NULL OR OBJECT_ID(N'tempdb..#tbx_Pointer_Actual') IS NOT NULL
 THROW 55590,N'Pointer: vorhandene private Fixturetemps werden nicht adoptiert.',4;
CREATE TABLE #tbx_Pointer_Cases(Id int NOT NULL PRIMARY KEY,Label nvarchar(128) NOT NULL,Json nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,Pointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,MaxInputBytes bigint NULL,MaxDepth int NULL,ExpectedStatus varchar(16) NOT NULL,ExpectedType varchar(8) NULL,ExpectedValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,ExpectedCode varchar(32) NULL,CompareMode varchar(16) NOT NULL);
DECLARE @High nvarchar(max)=CONVERT(nvarchar(max),0x3DD8),@Low nvarchar(max)=CONVERT(nvarchar(max),0x00DE),@Pair nvarchar(max)=CONVERT(nvarchar(max),0x3DD800DE),@Nul nvarchar(max)=CONVERT(nvarchar(max),0x0000);
IF CONVERT(varbinary(max),@Pair)<>0x3DD800DE OR DATALENGTH(@High)<>2 OR DATALENGTH(@Nul)<>2
 THROW 55591,N'Pointer: feste UTF16-Fixtures sind ungültig.',1;
DECLARE @Deep128 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'['),128)+N'0'+REPLICATE(CONVERT(nvarchar(max),N']'),128),
 @Deep129 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'['),129)+N'0'+REPLICATE(CONVERT(nvarchar(max),N']'),129),
 @DeepUnicode nvarchar(max)=N'[["\uD800"]]';
INSERT #tbx_Pointer_Cases VALUES
(1,N'NullPriority0',NULL,N'',NULL,0,N'SQL_NULL',NULL,NULL,NULL,N'TEXT'),
(2,N'NullPriority1',N'{}',NULL,NULL,0,N'SQL_NULL',NULL,NULL,NULL,N'TEXT'),
(3,N'NullPriority2',NULL,NULL,NULL,0,N'SQL_NULL',NULL,NULL,NULL,N'TEXT'),
(4,N'ByteBudgetNULL',N'{}',N'',NULL,128,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(5,N'ByteBudget0',N'{}',N'',0,128,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(6,N'ByteBudget-1',N'{}',N'',-1,128,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(7,N'ByteBudget16777217',N'{}',N'',16777217,128,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(8,N'ByteBudget9223372036854775807',N'{}',N'',9223372036854775807,128,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(9,N'DepthBudgetNULL',N'{}',N'',16777216,NULL,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(10,N'DepthBudget0',N'{}',N'',16777216,0,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(11,N'DepthBudget-1',N'{}',N'',16777216,-1,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(12,N'DepthBudget129',N'{}',N'',16777216,129,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(13,N'DepthBudget2147483647',N'{}',N'',16777216,2147483647,N'INVALID',NULL,NULL,N'PARAMETER',N'TEXT'),
(14,N'ByteExact',N'{}',N'',4,128,N'FOUND',N'OBJECT',N'{}',NULL,N'JSON_FLAT'),
(15,N'ByteBelow',N'{}',N'',3,128,N'INVALID',NULL,NULL,N'INPUT_LIMIT',N'TEXT'),
(16,N'BytesBeforePointer',N'[',N'x',1,128,N'INVALID',NULL,NULL,N'INPUT_LIMIT',N'TEXT'),
(17,N'BytesTrailingWhitespace',N'{} ',N'',4,128,N'INVALID',NULL,NULL,N'INPUT_LIMIT',N'TEXT'),
(18,N'PointerExact',N'{}',N'/'+REPLICATE(CONVERT(nvarchar(max),N'a'),3999),16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(19,N'PointerOver',N'{}',N'/'+REPLICATE(CONVERT(nvarchar(max),N'a'),4000),16777216,128,N'INVALID',NULL,NULL,N'POINTER_LIMIT',N'TEXT'),
(20,N'PointerLimitBeforeSyntax',N'[',REPLICATE(CONVERT(nvarchar(max),N'x'),4001),16777216,128,N'INVALID',NULL,NULL,N'POINTER_LIMIT',N'TEXT'),
(21,N'PointerSyntax/~',N'[',N'/~',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(22,N'PointerSyntax/~2',N'[',N'/~2',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(23,N'PointerSyntax/~00~',N'[',N'/~00~',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(24,N'PointerSyntaxa',N'[',N'a',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(25,N'PointerSyntax #',N'[',N' #',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(26,N'PointerUnicodeBeforeJson',N'[',N'/'+@High,16777216,128,N'INVALID',NULL,NULL,N'UNICODE',N'TEXT'),
(27,N'PointerSyntaxBeforeUnicode',N'{}',N'/~2'+@High,16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(28,N'JsonSyntax27',N'',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(29,N'JsonSyntax28',N' ',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(30,N'JsonSyntax29',N'[',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(31,N'JsonSyntax30',N'{} {}',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(32,N'JsonSyntax31',N'[1,]',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(33,N'JsonSyntax32',N'{"a":}',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(34,N'JsonSyntax33',N'01',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(35,N'JsonSyntax34',N'+1',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(36,N'JsonSyntax35',N'.1',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(37,N'JsonSyntax36',N'NaN',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(38,N'JsonSyntax37',N'["\x"]',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(39,N'InvalidUnselected',N'{"a":1,"z":[1,]}',N'/a',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(40,N'Depth128',@Deep128,N'',16777216,128,N'FOUND',N'ARRAY',NULL,NULL,N'JSON_VALID'),
(41,N'Depth129',@Deep129,N'',16777216,128,N'INVALID',NULL,NULL,N'DEPTH_LIMIT',N'TEXT'),
(42,N'DepthExactLower',N'[[]]',N'/0',16777216,2,N'FOUND',N'ARRAY',N'[]',NULL,N'JSON_FLAT'),
(43,N'DepthExceededLower',N'[[]]',N'/missing',16777216,1,N'INVALID',NULL,NULL,N'DEPTH_LIMIT',N'TEXT'),
(44,N'SyntaxBeforeDepth',@Deep129+N']',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(45,N'DepthBeforeUnicode',@DeepUnicode,N'',16777216,1,N'INVALID',NULL,NULL,N'DEPTH_LIMIT',N'TEXT'),
(46,N'Unpaired45',N'"\uD800"',N'/a',16777216,128,N'INVALID',NULL,NULL,N'UNICODE',N'TEXT'),
(47,N'Unpaired46',N'"\uDC00"',N'/a',16777216,128,N'INVALID',NULL,NULL,N'UNICODE',N'TEXT'),
(48,N'Unpaired47',N'{"a":1,"z":"\uD800"}',N'/a',16777216,128,N'INVALID',NULL,NULL,N'UNICODE',N'TEXT'),
(49,N'Unpaired48',N'{"\uD800":1,"a":2}',N'/a',16777216,128,N'INVALID',NULL,NULL,N'UNICODE',N'TEXT'),
(50,N'Pair49',N'"'+@Pair+N'"',N'',16777216,128,N'FOUND',N'STRING',NULL,NULL,N'PAIR'),
(51,N'Pair50',N'"\uD83D\uDE00"',N'',16777216,128,N'FOUND',N'STRING',NULL,NULL,N'PAIR'),
(52,N'Pair51',N'"'+@High+N'\uDE00"',N'',16777216,128,N'FOUND',N'STRING',NULL,NULL,N'PAIR'),
(53,N'Pair52',N'"\uD83D'+@Low+N'"',N'',16777216,128,N'FOUND',N'STRING',NULL,NULL,N'PAIR'),
(54,N'RawUnpaired',N'"'+@High+N'"',N'',16777216,128,N'INVALID',NULL,NULL,N'UNICODE',N'TEXT'),
(55,N'LiteralNul',N'"'+@Nul+N'"',N'',16777216,128,N'INVALID',NULL,NULL,N'JSON_SYNTAX',N'TEXT'),
(56,N'EscapedNul',N'"\u0000"',N'',16777216,128,N'FOUND',N'STRING',NULL,NULL,N'NUL'),
(57,N'NulKey',N'{"\u0000":1}',N'/'+@Nul,16777216,128,N'FOUND',N'NUMBER',N'1',NULL,N'TEXT'),
(58,N'NulBeforeTilde',N'{"\u0000~":2}',N'/'+@Nul+N'~0',16777216,128,N'FOUND',N'NUMBER',N'2',NULL,N'TEXT'),
(59,N'TrailingKey',N'{"a":1,"a ":2}',N'/a ',16777216,128,N'FOUND',N'NUMBER',N'2',NULL,N'TEXT'),
(60,N'PairKey',N'{"\uD83D\uDE00":3}',N'/'+@Pair,16777216,128,N'FOUND',N'NUMBER',N'3',NULL,N'TEXT'),
(61,N'PairChunkBoundary',N'"'+REPLICATE(CONVERT(nvarchar(max),N'a'),3998)+@Pair+N'"',N'',16777216,128,N'FOUND',N'STRING',NULL,NULL,N'LONGPAIR'),
(62,N'ScalarDepthZero',N'0',N'',16777216,1,N'FOUND',N'NUMBER',N'0',NULL,N'TEXT'),
(63,N'NulBeforeInvalidTilde',N'{}',N'/'+@Nul+N'~2',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT');
CREATE TABLE #tbx_Pointer_Actual(Id int NOT NULL,ApplyForm varchar(8) NOT NULL,Status varchar(16) NULL,JsonType varchar(8) NULL,Value nvarchar(max) NULL,ErrorCode varchar(32) NULL);
DECLARE @Collations TABLE(Id int PRIMARY KEY,Name sysname NOT NULL);
INSERT @Collations VALUES(1,N'Latin1_General_100_BIN2'),(2,N'Latin1_General_100_CI_AS'),(3,N'Latin1_General_100_CS_AS'),(4,N'Latin1_General_100_CI_AS_SC_UTF8');
DECLARE @Index int=1,@Collation sysname,@Sql nvarchar(max);
DECLARE @Containers TABLE(Actual nvarchar(max) NOT NULL,Expected nvarchar(max) NOT NULL);
WHILE @Index<=4
BEGIN
 SELECT @Collation=Name FROM @Collations WHERE Id=@Index;
 DELETE #tbx_Pointer_Actual;
 -- Die Collation stammt ausschließlich aus den vier festen Fixtures, kein Identifierquoting.
 SET @Sql=N'INSERT #tbx_Pointer_Actual SELECT c.Id,''CROSS'',r.Status,r.JsonType,r.Value,r.ErrorCode FROM #tbx_Pointer_Cases c CROSS APPLY '+@Prefix+N'TVF_ResolveJsonPointer(c.Json COLLATE '+@Collation+N',c.Pointer COLLATE '+@Collation+N',c.MaxInputBytes,c.MaxDepth) r;
 INSERT #tbx_Pointer_Actual SELECT c.Id,''OUTER'',r.Status,r.JsonType,r.Value,r.ErrorCode FROM #tbx_Pointer_Cases c OUTER APPLY '+@Prefix+N'TVF_ResolveJsonPointer(c.Json COLLATE '+@Collation+N',c.Pointer COLLATE '+@Collation+N',c.MaxInputBytes,c.MaxDepth) r;';
 BEGIN TRY
  EXEC sys.sp_executesql @Sql;
 END TRY
 BEGIN CATCH
  -- Nur nach tatsächlichem technischem FAIL: begrenzte Einzelreplays, niemals PASS daraus.
  DECLARE @OriginalNumber int=ERROR_NUMBER(),@OriginalState int=ERROR_STATE(),
   @DiagnosticCase int=1,@DiagnosticLast int=(SELECT MAX(Id) FROM #tbx_Pointer_Cases),
   @DiagnosticJson nvarchar(max),@DiagnosticPointer nvarchar(max),@DiagnosticBytes bigint,@DiagnosticDepth int,
   @DiagnosticSql nvarchar(max),@DiagnosticMessage nvarchar(2048);
  IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW;
  SET @DiagnosticSql=N'SELECT Status,JsonType,Value,ErrorCode FROM '+@Prefix+N'TVF_ResolveJsonPointer(@Json COLLATE '+@Collation+N',@Pointer COLLATE '+@Collation+N',@Bytes,@Depth);';
  WHILE @DiagnosticCase<=@DiagnosticLast AND @DiagnosticCase<=63
  BEGIN
   -- Skalare Parameter isolieren wirklich den einen Fall; kein WHERE vor einem APPLY.
   SELECT @DiagnosticJson=Json,@DiagnosticPointer=Pointer,@DiagnosticBytes=MaxInputBytes,@DiagnosticDepth=MaxDepth
    FROM #tbx_Pointer_Cases WHERE Id=@DiagnosticCase;
   BEGIN TRY
    EXEC sys.sp_executesql @DiagnosticSql,N'@Json nvarchar(max),@Pointer nvarchar(max),@Bytes bigint,@Depth int',
     @Json=@DiagnosticJson,@Pointer=@DiagnosticPointer,@Bytes=@DiagnosticBytes,@Depth=@DiagnosticDepth;
   END TRY
   BEGIN CATCH
    -- Nur synthetische Fallnummer plus originale Nummer/State, keine Eingabe- oder Enginepayloads.
    SET @DiagnosticMessage=N'Pointer: technischer Safetyfall; Originalnummer='+CONVERT(nvarchar(12),@OriginalNumber)+N'; Originalstate='+CONVERT(nvarchar(4),@OriginalState)+N'.';
    THROW 55591,@DiagnosticMessage,@DiagnosticCase;
   END CATCH;
   SET @DiagnosticCase+=1;
  END;
  -- Nicht reproduzierbarer technischer Fehler bleibt der Originalfehler.
  THROW;
 END CATCH;
 IF (SELECT COUNT(*) FROM #tbx_Pointer_Actual)<>2*(SELECT COUNT(*) FROM #tbx_Pointer_Cases)
  OR EXISTS(SELECT Id,ApplyForm FROM #tbx_Pointer_Actual GROUP BY Id,ApplyForm HAVING COUNT(*)<>1)
  THROW 55590,N'Pointer: genau eine Zeile pro APPLY-Eingabe erforderlich.',2;
 IF EXISTS(SELECT 1 FROM #tbx_Pointer_Actual a JOIN #tbx_Pointer_Cases c ON c.Id=a.Id
 WHERE a.Status IS NULL OR CONVERT(varbinary(max),a.Status)<>CONVERT(varbinary(max),c.ExpectedStatus)
  OR (a.JsonType IS NULL AND c.ExpectedType IS NOT NULL) OR (a.JsonType IS NOT NULL AND c.ExpectedType IS NULL)
  OR CONVERT(varbinary(max),a.JsonType)<>CONVERT(varbinary(max),c.ExpectedType)
  OR (a.ErrorCode IS NULL AND c.ExpectedCode IS NOT NULL) OR (a.ErrorCode IS NOT NULL AND c.ExpectedCode IS NULL)
  OR CONVERT(varbinary(max),a.ErrorCode)<>CONVERT(varbinary(max),c.ExpectedCode)
  OR (a.Value IS NULL AND c.ExpectedValue IS NOT NULL) OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL AND c.CompareMode='TEXT')
  OR (c.CompareMode='TEXT' AND CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue)))
  THROW 55590,N'Pointer: fester Status-/Typ-/Code-/Wertoracle weicht ab.',1;
 IF EXISTS(SELECT 1 FROM #tbx_Pointer_Actual a JOIN #tbx_Pointer_Cases c ON c.Id=a.Id WHERE
  (c.CompareMode='PAIR' AND (a.Value IS NULL OR CONVERT(varbinary(max),a.Value)<>0x3DD800DE))
  OR (c.CompareMode='NUL' AND (a.Value IS NULL OR CONVERT(varbinary(max),a.Value)<>0x0000))
  OR (c.CompareMode='LONGPAIR' AND (a.Value IS NULL OR CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),N'a'),3998)+@Pair)))
  OR (c.CompareMode='JSON_VALID' AND (ISNULL(ISJSON(a.Value),0)<>1
   OR CONVERT(varbinary(max),REPLACE(REPLACE(REPLACE(REPLACE(a.Value,N' ',N''),NCHAR(9),N''),NCHAR(10),N''),NCHAR(13),N''))<>CONVERT(varbinary(max),@Deep128))))
  THROW 55591,N'Pointer: UTF16-/Tiefenwertoracle weicht ab.',2;
 -- Nur flache Containerfixtures: semantischer Vergleich ohne Formatierungstreue zu fordern.
 IF EXISTS(SELECT 1 FROM #tbx_Pointer_Actual a JOIN #tbx_Pointer_Cases c ON c.Id=a.Id WHERE c.CompareMode='JSON_FLAT' AND ISNULL(ISJSON(a.Value),0)<>1)
  THROW 55590,N'Pointer: Containerfragment ist kein gültiges JSON.',5;
 DELETE @Containers;
 INSERT @Containers SELECT a.Value,c.ExpectedValue FROM #tbx_Pointer_Actual a JOIN #tbx_Pointer_Cases c ON c.Id=a.Id WHERE c.CompareMode='JSON_FLAT';
 -- OPENJSON sieht erst im Folgestatement ausschließlich bewiesen gültige Container.
 IF EXISTS(SELECT 1 FROM @Containers p WHERE
  (EXISTS(SELECT CONVERT(varbinary(max),[key]),type,CONVERT(varbinary(max),value) FROM OPENJSON(p.Actual)
    EXCEPT SELECT CONVERT(varbinary(max),[key]),type,CONVERT(varbinary(max),value) FROM OPENJSON(p.Expected))
   OR EXISTS(SELECT CONVERT(varbinary(max),[key]),type,CONVERT(varbinary(max),value) FROM OPENJSON(p.Expected)
    EXCEPT SELECT CONVERT(varbinary(max),[key]),type,CONVERT(varbinary(max),value) FROM OPENJSON(p.Actual))))
  THROW 55590,N'Pointer: Containerinhalt verändert.',6;
 SET @Index+=1;
END;
DECLARE @CaseCount int=(SELECT COUNT(*) FROM #tbx_Pointer_Cases);
DROP TABLE #tbx_Pointer_Actual;DROP TABLE #tbx_Pointer_Cases;
SELECT N'PASS' Status,@CaseCount Cases,4 InputCollations,2 ApplyForms;
GO
