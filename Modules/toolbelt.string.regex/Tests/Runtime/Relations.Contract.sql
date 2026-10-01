SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE #RegexRelationRows(Ordinal bigint,StartPosition bigint,Length bigint,Value nvarchar(max));
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(N'a12 b3 ',N'[0-9]+',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>2 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=1 AND StartPosition=2 AND Length=2 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'12')) OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=2 AND StartPosition=6 AND Length=1 AND Value=N'3') THROW 52096,N'Matches row contract failed.',1;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(N'a,,b,',N',',DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>4 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=2 AND StartPosition=3 AND Length=0 AND Value IS NOT NULL AND DATALENGTH(Value)=0) OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=4 AND StartPosition=6 AND Length=0 AND Value IS NOT NULL AND DATALENGTH(Value)=0) THROW 52096,N'Split edge/intermediate empty failed.',2;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(N'abc',N'',DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>5 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=1 AND StartPosition=1 AND Length=0 AND Value IS NOT NULL AND DATALENGTH(Value)=0) OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=2 AND StartPosition=1 AND Length=1 AND Value=N'a') OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=3 AND StartPosition=2 AND Length=1 AND Value=N'b') OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=4 AND StartPosition=3 AND Length=1 AND Value=N'c') OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=5 AND StartPosition=4 AND Length=0 AND Value IS NOT NULL AND DATALENGTH(Value)=0) THROW 52096,N'Zero separator lost input/terminal position.',3;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(N'abc',N'',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>4 OR EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal<>StartPosition OR Length<>0 OR Value IS NULL OR DATALENGTH(Value)<>0) THROW 52096,N'Zero matches UTF16 advance failed.',4;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(N'abc',N'',4,DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>1 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=1 AND StartPosition=4 AND Length=0 AND Value IS NOT NULL) THROW 52096,N'Terminal start failed.',5;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(N'abc',N'Z',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
IF EXISTS(SELECT 1 FROM #RegexRelationRows) THROW 52096,N'No-match is not empty.',6;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(NULL,N'[',NULL,NULL,NULL,NULL);
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(N'x',NULL,NULL,NULL,NULL);
IF EXISTS(SELECT 1 FROM #RegexRelationRows) THROW 52096,N'NULL priority failed.',7;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(N'',N'Z',DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>1 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=1 AND StartPosition=1 AND Length=0 AND Value IS NOT NULL AND DATALENGTH(Value)=0) THROW 52096,N'Empty no-separator input failed.',8;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(N'',N'',DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>2 OR EXISTS(SELECT 1 FROM #RegexRelationRows WHERE StartPosition<>1 OR Length<>0 OR Value IS NULL OR DATALENGTH(Value)<>0) THROW 52096,N'Empty separator on empty input failed.',9;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(N'abc',N'a*',DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>5 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=3 AND StartPosition=2 AND Value=N'b') OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=4 AND StartPosition=3 AND Value=N'c') THROW 52096,N'Mixed empty/consumed separators failed.',10;
DELETE #RegexRelationRows;
DECLARE @Supplementary nvarchar(max)=N'A'+CONVERT(nvarchar(max),0x3DD800DE)+N'B';
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(@Supplementary,N'',DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>6 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=3 AND StartPosition=2 AND Length=1 AND CONVERT(varbinary(max),Value)=0x3DD8) OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Ordinal=4 AND StartPosition=3 AND Length=1 AND CONVERT(varbinary(max),Value)=0x00DE) THROW 52096,N'UTF16 surrogate unit preservation failed.',11;
DELETE #RegexRelationRows;
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexSplit(N'x  ',N'Z',DEFAULT,DEFAULT,DEFAULT);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>1 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Length=3 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'x  ')) THROW 52096,N'Trailing spaces lost.',12;
DELETE #RegexRelationRows;
-- Fehlersignaturen exakt; keine Vertragsfehler werden als Null/Teilmenge maskiert.
DECLARE @Errors TABLE(Id int IDENTITY,Expression nvarchar(max),Prefix nvarchar(80));
INSERT @Errors VALUES
(N'TVF_RegexMatches(N''x'',N''['',0,N''bad'',N''bad'',0)',N'TBX_REGEX_INVALID_ARGUMENT'),
(N'TVF_RegexMatches(N''x'',N''['',0,N''bad'',N''standard'',0)',N'TBX_REGEX_INVALID_ARGUMENT'),
(N'TVF_RegexMatches(N''x'',N''['',1,N''bad'',N''standard'',10)',N'TBX_REGEX_INVALID_FLAGS'),
(N'TVF_RegexMatches(N''x'',N''['',3,N''c'',N''standard'',10)',N'TBX_REGEX_INVALID_PATTERN'),
(N'TVF_RegexMatches(N''abc'',N'''',1,N''c'',N''standard'',3)',N'TBX_REGEX_TOO_MANY_ROWS'),
(N'TVF_RegexSplit(N''abc'',N'''',N''c'',N''standard'',4)',N'TBX_REGEX_TOO_MANY_ROWS'),
(N'TVF_RegexMatches(N''x'',N''x'',1,N''c'',N''standard'',100001)',N'TBX_REGEX_INVALID_ARGUMENT'),
(N'TVF_RegexSplit(N''x'',N''x'',N''c'',NULL,1)',N'TBX_REGEX_INVALID_ARGUMENT'),
(N'TVF_RegexMatches(REPLICATE(CONVERT(nvarchar(max),N''x''),1048577),N''x'',1,N''c'',N''standard'',1)',N'TBX_REGEX_INPUT_TOO_LARGE'),
(N'TVF_RegexMatches(N''x'',REPLICATE(CONVERT(nvarchar(max),N''x''),8001),1,N''c'',N''standard'',1)',N'TBX_REGEX_PATTERN_TOO_LARGE'),
(N'TVF_RegexMatches(REPLICATE(CONVERT(nvarchar(max),N''a''),100000)+N''!'',N''^(a|aa)+$'',1,N''c'',N''standard'',10000)',N'TBX_REGEX_TIMEOUT');
DECLARE @Id int=1,@Expression nvarchar(max),@Prefix nvarchar(80),@Sql nvarchar(max);
WHILE @Id<=(SELECT COUNT(*) FROM @Errors)
BEGIN
 SELECT @Expression=Expression,@Prefix=Prefix FROM @Errors WHERE Id=@Id;
 SET @Sql=N'INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.'+@Expression;
 BEGIN TRY EXEC sys.sp_executesql @Sql; THROW 52096,N'Expected relation error missing.',13; END TRY
 BEGIN CATCH IF ERROR_NUMBER()<>6522 OR CHARINDEX(@Prefix,ERROR_MESSAGE())=0 THROW; END CATCH;
 IF EXISTS(SELECT 1 FROM #RegexRelationRows) THROW 52096,N'Business error exposed partial rows.',14;
 SET @Id+=1;
END;
-- Tatsächliche Profil-/Zeilenzahlgrenzen, keine unbegrenzte max-Zusage.
-- Ceiling ist eine zulässige Obergrenze, keine Laufzeitgarantie für Standard.
DECLARE @CeilingTimedOut bit=0;
BEGIN TRY
 INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(REPLICATE(CONVERT(nvarchar(max),N'x'),99999),N'',1,N'c',N'large',100000);
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>6522 OR CHARINDEX(N'TBX_REGEX_TIMEOUT',ERROR_MESSAGE())=0 THROW;
 IF EXISTS(SELECT 1 FROM #RegexRelationRows) THROW 52096,N'Ceiling timeout exposed partial rows.',15;
 SET @CeilingTimedOut=1;
 PRINT N'R2b SQL 100000-row stress: atomic timeout, not throughput evidence.';
END CATCH;
IF @CeilingTimedOut=0 AND (SELECT COUNT(*) FROM #RegexRelationRows)<>100000 THROW 52096,N'Actual row ceiling failed.',15;
DELETE #RegexRelationRows;
-- Die Ceiling-Konfiguration selbst ist zulässig, unabhängig vom Durchsatz.
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(N'x',N'x',1,N'c',N'large',100000);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>1 THROW 52096,N'Ceiling configuration rejected.',17;
DELETE #RegexRelationRows;
DECLARE @Large nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388608);
INSERT #RegexRelationRows SELECT * FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexMatches(@Large,N'^.*$',1,N'c',N'large',1);
IF (SELECT COUNT(*) FROM #RegexRelationRows)<>1 OR NOT EXISTS(SELECT 1 FROM #RegexRelationRows WHERE Length=8388608 AND DATALENGTH(Value)=16777216 AND HASHBYTES('SHA2_256',CONVERT(varbinary(max),Value))=HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Large))) THROW 52096,N'Large output hash/length failed.',16;
DROP TABLE #RegexRelationRows;
PRINT N'Regex R2b local/central contracts PASS.';
