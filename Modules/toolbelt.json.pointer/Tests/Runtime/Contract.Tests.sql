-- Synthetische Pointer-Oracles; keine Installation, Konfiguration oder Rechteänderung.
SET NOCOUNT ON;
DECLARE @Database sysname=NULLIF(N'$(ToolbeltDatabase)',N''),@Prefix nvarchar(520);
SET @Prefix=CASE WHEN @Database IS NULL THEN N'' ELSE QUOTENAME(@Database)+N'.' END+N'toolbelt_json.';
IF OBJECT_ID(N'tempdb..#tbx_Pointer_Cases') IS NOT NULL OR OBJECT_ID(N'tempdb..#tbx_Pointer_Actual') IS NOT NULL
 THROW 55590,N'Pointer: vorhandene private Fixturetemps werden nicht adoptiert.',4;
CREATE TABLE #tbx_Pointer_Cases(Id int NOT NULL PRIMARY KEY,Label nvarchar(128) NOT NULL,Json nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,Pointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,MaxInputBytes bigint NULL,MaxDepth int NULL,ExpectedStatus varchar(16) NOT NULL,ExpectedType varchar(8) NULL,ExpectedValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,ExpectedCode varchar(32) NULL,CompareMode varchar(16) NOT NULL);
INSERT #tbx_Pointer_Cases VALUES
(1,N'RootObject',N'{}',N'',16777216,128,N'FOUND',N'OBJECT',N'{}',NULL,N'JSON_FLAT'),
(2,N'RootArray',N'[]',N'',16777216,128,N'FOUND',N'ARRAY',N'[]',NULL,N'JSON_FLAT'),
(3,N'RfcFoo',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/foo',16777216,128,N'FOUND',N'ARRAY',N'["bar","baz"]',NULL,N'JSON_FLAT'),
(4,N'Rfc/foo/0',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/foo/0',16777216,128,N'FOUND',N'STRING',N'bar',NULL,N'TEXT'),
(5,N'Rfc/foo/1',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/foo/1',16777216,128,N'FOUND',N'STRING',N'baz',NULL,N'TEXT'),
(6,N'RfcEmpty',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/',16777216,128,N'FOUND',N'ARRAY',N'[0]',NULL,N'JSON_FLAT'),
(7,N'Rfc/a~1b',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/a~1b',16777216,128,N'FOUND',N'NUMBER',N'1',NULL,N'TEXT'),
(8,N'Rfc/c%d',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/c%d',16777216,128,N'FOUND',N'NUMBER',N'2',NULL,N'TEXT'),
(9,N'Rfc/e^f',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/e^f',16777216,128,N'FOUND',N'NUMBER',N'3',NULL,N'TEXT'),
(10,N'Rfc/g|h',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/g|h',16777216,128,N'FOUND',N'NUMBER',N'4',NULL,N'TEXT'),
(11,N'Rfc/i\j',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/i\j',16777216,128,N'FOUND',N'NUMBER',N'5',NULL,N'TEXT'),
(12,N'Rfc/k"l',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/k"l',16777216,128,N'FOUND',N'NUMBER',N'6',NULL,N'TEXT'),
(13,N'Rfc/ ',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/ ',16777216,128,N'FOUND',N'NUMBER',N'7',NULL,N'TEXT'),
(14,N'Rfc/m~0n',N'{"foo":["bar","baz"],"":[0],"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\j":5,"k\"l":6," ":7,"m~n":8}',N'/m~0n',16777216,128,N'FOUND',N'NUMBER',N'8',NULL,N'TEXT'),
(15,N'ScalarSTRING"1"',N'"1"',N'',16777216,128,N'FOUND',N'STRING',N'1',NULL,N'TEXT'),
(16,N'ScalarNUMBER1',N'1',N'',16777216,128,N'FOUND',N'NUMBER',N'1',NULL,N'TEXT'),
(17,N'ScalarBOOLEANtrue',N'true',N'',16777216,128,N'FOUND',N'BOOLEAN',N'true',NULL,N'TEXT'),
(18,N'ScalarBOOLEANfalse',N'false',N'',16777216,128,N'FOUND',N'BOOLEAN',N'false',NULL,N'TEXT'),
(19,N'ScalarSTRING""',N'""',N'',16777216,128,N'FOUND',N'STRING',N'',NULL,N'TEXT'),
(20,N'ScalarNUMBER-0.00e+9999999999',N'-0.00e+9999999999',N'',16777216,128,N'FOUND',N'NUMBER',N'-0.00e+9999999999',NULL,N'TEXT'),
(21,N'ScalarNUMBER1.2345678901234567890123456789e-999999',N'1.2345678901234567890123456789e-999999',N'',16777216,128,N'FOUND',N'NUMBER',N'1.2345678901234567890123456789e-999999',NULL,N'TEXT'),
(22,N'NullRoot',N'null',N'',16777216,128,N'JSON_NULL',N'NULL',NULL,NULL,N'TEXT'),
(23,N'NullTerminal',N'{"a":null}',N'/a',16777216,128,N'JSON_NULL',N'NULL',NULL,NULL,N'TEXT'),
(24,N'ContinueScalarnull',N'null',N'/x',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(25,N'ContinueScalar1',N'1',N'/x',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(26,N'ContinueScalar""',N'""',N'/x',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(27,N'ContinueScalartrue',N'true',N'/x',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(28,N'NoSqlPath',N'{"a":1}',N'$.a',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(29,N'NoUriFragment',N'{"a":1}',N'#/a',16777216,128,N'INVALID',NULL,NULL,N'POINTER_SYNTAX',N'TEXT'),
(30,N'ObjectLeadingZero',N'{"01":"x","-":"y"}',N'/01',16777216,128,N'FOUND',N'STRING',N'x',NULL,N'TEXT'),
(31,N'ObjectDash',N'{"01":"x","-":"y"}',N'/-',16777216,128,N'FOUND',N'STRING',N'y',NULL,N'TEXT'),
(32,N'ArrayDash',N'[1]',N'/-',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(33,N'ArrayOutside',N'[1]',N'/1',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(34,N'ArrayHuge',N'[1]',N'/99999999999999999999999999999999999999',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(35,N'ArrayLex/00',N'[1]',N'/00',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(36,N'ArrayLex/01',N'[1]',N'/01',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(37,N'ArrayLex/-1',N'[1]',N'/-1',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(38,N'ArrayLex/+1',N'[1]',N'/+1',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(39,N'ArrayLex/1.0',N'[1]',N'/1.0',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(40,N'ArrayLex/ 0',N'[1]',N'/ 0',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(41,N'ArrayLex/１',N'[1]',N'/１',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(42,N'OrdinalCase',N'{"A":1,"a":2}',N'/A',16777216,128,N'FOUND',N'NUMBER',N'1',NULL,N'TEXT'),
(43,N'OrdinalAccent',N'{"é":1,"e":2}',N'/e',16777216,128,N'FOUND',N'NUMBER',N'2',NULL,N'TEXT'),
(44,N'NoNormalization',N'{"é":1}',N'/é',16777216,128,N'MISSING',NULL,NULL,NULL,N'TEXT'),
(45,N'TokenDecodeOrder',N'{"~1":1,"/":2}',N'/~01',16777216,128,N'FOUND',N'NUMBER',N'1',NULL,N'TEXT'),
(46,N'RepeatedEmpty',N'{"":{"":1}}',N'//',16777216,128,N'FOUND',N'NUMBER',N'1',NULL,N'TEXT'),
(47,N'DecodedKey',N'{"\u0061":1}',N'/a',16777216,128,N'FOUND',N'NUMBER',N'1',NULL,N'TEXT'),
(48,N'UnrelatedDuplicate',N'{"x":1,"x":2,"a":3}',N'/a',16777216,128,N'FOUND',N'NUMBER',N'3',NULL,N'TEXT'),
(49,N'MatchingDuplicate',N'{"a":1,"a":2}',N'/a',16777216,128,N'INVALID',NULL,NULL,N'DUPLICATE_KEY',N'TEXT'),
(50,N'EscapedMatchingDuplicate',N'{"a":1,"\u0061":2}',N'/a',16777216,128,N'INVALID',NULL,NULL,N'DUPLICATE_KEY',N'TEXT'),
(51,N'EarlierDuplicateBeforeMissing',N'{"a":{},"a":{}}',N'/a/missing',16777216,128,N'INVALID',NULL,NULL,N'DUPLICATE_KEY',N'TEXT'),
(52,N'WhitespaceScalar',N' '+NCHAR(9)+N' 42 '+NCHAR(13)+NCHAR(10),N'',16777216,128,N'FOUND',N'NUMBER',N'42',NULL,N'TEXT'),
(53,N'ArrayEmptyIndex',N'[]',N'/',16777216,128,N'INVALID',NULL,NULL,N'ARRAY_INDEX',N'TEXT'),
(54,N'LongObjectKey',N'{"'+REPLICATE(CONVERT(nvarchar(max),N'a'),1500)+N'":7}',N'/'+REPLICATE(CONVERT(nvarchar(max),N'a'),1500),16777216,128,N'FOUND',N'NUMBER',N'7',NULL,N'TEXT');
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
 EXEC sys.sp_executesql @Sql;
 IF (SELECT COUNT(*) FROM #tbx_Pointer_Actual)<>2*(SELECT COUNT(*) FROM #tbx_Pointer_Cases)
  OR EXISTS(SELECT Id,ApplyForm FROM #tbx_Pointer_Actual GROUP BY Id,ApplyForm HAVING COUNT(*)<>1)
  THROW 55590,N'Pointer: genau eine Zeile pro APPLY-Eingabe erforderlich.',2;
 IF EXISTS(SELECT 1 FROM #tbx_Pointer_Actual a JOIN #tbx_Pointer_Cases c ON c.Id=a.Id
 WHERE a.Status IS NULL OR CONVERT(varbinary(max),a.Status)<>CONVERT(varbinary(max),c.ExpectedStatus)
  OR (a.JsonType IS NULL AND c.ExpectedType IS NOT NULL) OR (a.JsonType IS NOT NULL AND c.ExpectedType IS NULL)
  OR CONVERT(varbinary(max),a.JsonType)<>CONVERT(varbinary(max),c.ExpectedType)
  OR (a.ErrorCode IS NULL AND c.ExpectedCode IS NOT NULL) OR (a.ErrorCode IS NOT NULL AND c.ExpectedCode IS NULL)
  OR CONVERT(varbinary(max),a.ErrorCode)<>CONVERT(varbinary(max),c.ExpectedCode)
  OR (a.Value IS NULL AND c.ExpectedValue IS NOT NULL) OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL)
  OR (c.CompareMode='TEXT' AND CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue)))
  THROW 55590,N'Pointer: fester Status-/Typ-/Code-/Wertoracle weicht ab.',1;
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
