SET NOCOUNT ON;
SET XACT_ABORT OFF;

-- Nur synthetische Parameter; der Korpus führt keine Pattern-Statements aus.
CREATE TABLE #CaptureActual
(CaseId int, MatchOrdinal bigint, GroupOrdinal int, CaptureOrdinal bigint,
 GroupName nvarchar(128), Matched bit, StartPosition bigint, Length bigint, Value nvarchar(max));
CREATE TABLE #CaptureExpected
(CaseId int, MatchOrdinal bigint, GroupOrdinal int, CaptureOrdinal bigint,
 GroupName nvarchar(128), Matched bit, StartPosition bigint, Length bigint, Value nvarchar(max));
DECLARE @Cases table
(CaseId int PRIMARY KEY, Input nvarchar(max), Pattern nvarchar(max), Start int,
 Flags nvarchar(max), Profile nvarchar(max), MaxRows int);
INSERT @Cases VALUES
 (1,N'abc abc',N'(a)(?<Mid>b)(c)',1,N'c',N'standard',10000),
 (2,N'aaab',N'((a)+)(b)',1,N'c',N'standard',10000),
 (3,N'b',N'(a)?(b)',1,N'c',N'standard',10000),
 (4,N'',N'(a?)',1,N'c',N'standard',10000),
 (5,N'ab',N'(a?)',1,N'c',N'standard',10000),
 (6,N'A'+CONVERT(nvarchar(max),0x3DD800DE)+N'B',N'(.)',2,N'c',N'standard',10000),
 (7,N'a1a2a3',N'(a)([0-9])',3,N'c',N'standard',10000),
 (8,N'x',N'(a?)',2,N'c',N'standard',10000),
 (9,N'x',N'x',1,N'c',N'standard',10000),
 (10,N'x',N'(z)',1,N'c',N'standard',10000),
 (11,NULL,N'[',0,NULL,NULL,NULL),
 (12,N'aaab',N'(a)+ab',1,N'c',N'standard',10000),
 (13,N'ab',N'(a)|(b)',1,N'c',N'standard',10000),
 (14,N'A'+NCHAR(10)+N'b',N'(?<Letter>[a-z])',1,N'i',N'standard',10000),
 (15,N'(()',N'([()])',1,N'c',N'standard',10000),
 (16,N'x',NULL,0,NULL,NULL,NULL),
 (17,N'x  ',N'(?<Text>.+)',1,N'c',N'standard',10000),
 (18,N'x',N'(x)',3,N'c',N'standard',10000);
INSERT #CaptureExpected VALUES
 (1,1,1,1,N'1',1,1,1,N'a'),(1,1,2,1,N'Mid',1,2,1,N'b'),(1,1,3,1,N'3',1,3,1,N'c'),
 (1,2,1,1,N'1',1,5,1,N'a'),(1,2,2,1,N'Mid',1,6,1,N'b'),(1,2,3,1,N'3',1,7,1,N'c'),
 (2,1,1,1,N'1',1,1,3,N'aaa'),(2,1,2,1,N'2',1,1,1,N'a'),
 (2,1,2,2,N'2',1,2,1,N'a'),(2,1,2,3,N'2',1,3,1,N'a'),(2,1,3,1,N'3',1,4,1,N'b'),
 (3,1,1,0,N'1',0,NULL,NULL,NULL),(3,1,2,1,N'2',1,1,1,N'b'),
 (4,1,1,1,N'1',1,1,0,N''),
 (5,1,1,1,N'1',1,1,1,N'a'),(5,2,1,1,N'1',1,2,0,N''),(5,3,1,1,N'1',1,3,0,N''),
 (6,1,1,1,N'1',1,2,1,CONVERT(nvarchar(max),0x3DD8)),
 (6,2,1,1,N'1',1,3,1,CONVERT(nvarchar(max),0x00DE)),(6,3,1,1,N'1',1,4,1,N'B'),
 (7,1,1,1,N'1',1,3,1,N'a'),(7,1,2,1,N'2',1,4,1,N'2'),
 (7,2,1,1,N'1',1,5,1,N'a'),(7,2,2,1,N'2',1,6,1,N'3'),
 (8,1,1,1,N'1',1,2,0,N''),
 (12,1,1,1,N'1',1,1,1,N'a'),(12,1,1,2,N'1',1,2,1,N'a'),
 (13,1,1,1,N'1',1,1,1,N'a'),(13,1,2,0,N'2',0,NULL,NULL,NULL),
 (13,2,1,0,N'1',0,NULL,NULL,NULL),(13,2,2,1,N'2',1,2,1,N'b'),
 (14,1,1,1,N'Letter',1,1,1,N'A'),(14,2,1,1,N'Letter',1,3,1,N'b'),
 (15,1,1,1,N'1',1,1,1,N'('),(15,2,1,1,N'1',1,2,1,N'('),(15,3,1,1,N'1',1,3,1,N')'),
 (17,1,1,1,N'Text',1,1,3,N'x  ');
DECLARE @Case int=1,@Input nvarchar(max),@Pattern nvarchar(max),@Start int,
 @Flags nvarchar(max),@Profile nvarchar(max),@MaxRows int;
WHILE @Case<=18
BEGIN
 SELECT @Input=Input,@Pattern=Pattern,@Start=Start,@Flags=Flags,@Profile=Profile,@MaxRows=MaxRows FROM @Cases WHERE CaseId=@Case;
 INSERT #CaptureActual
 SELECT @Case,MatchOrdinal,GroupOrdinal,CaptureOrdinal,GroupName,Matched,StartPosition,Length,Value
 FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexCaptures(@Input,@Pattern,@Start,@Flags,@Profile,@MaxRows);
 SET @Case+=1;
END;
-- Binärvergleich erhält Case, Surrogate, NULL und nachgestellte Leerzeichen.
IF (SELECT COUNT(*) FROM #CaptureActual)<>(SELECT COUNT(*) FROM #CaptureExpected)
 OR EXISTS
 (SELECT CaseId,MatchOrdinal,GroupOrdinal,CaptureOrdinal,CONVERT(varbinary(max),GroupName),Matched,StartPosition,Length,CONVERT(varbinary(max),Value) FROM #CaptureActual
  EXCEPT
  SELECT CaseId,MatchOrdinal,GroupOrdinal,CaptureOrdinal,CONVERT(varbinary(max),GroupName),Matched,StartPosition,Length,CONVERT(varbinary(max),Value) FROM #CaptureExpected)
 OR EXISTS
 (SELECT CaseId,MatchOrdinal,GroupOrdinal,CaptureOrdinal,CONVERT(varbinary(max),GroupName),Matched,StartPosition,Length,CONVERT(varbinary(max),Value) FROM #CaptureExpected
  EXCEPT
  SELECT CaseId,MatchOrdinal,GroupOrdinal,CaptureOrdinal,CONVERT(varbinary(max),GroupName),Matched,StartPosition,Length,CONVERT(varbinary(max),Value) FROM #CaptureActual)
 THROW 52097,N'Capture-Semantik weicht vom unabhängigen Zeilenorakel ab.',1;
IF EXISTS(SELECT MatchOrdinal,GroupOrdinal,CaptureOrdinal FROM #CaptureActual GROUP BY CaseId,MatchOrdinal,GroupOrdinal,CaptureOrdinal HAVING COUNT(*)<>1)
 THROW 52097,N'Capture-Schlüssel sind nicht eindeutig.',2;

DECLARE @Replace table
(Id int IDENTITY,Input nvarchar(max),Pattern nvarchar(max),Replacement nvarchar(max),
 Start int,Occurrence int,Flags nvarchar(max),Profile nvarchar(max),Expected nvarchar(max));
INSERT @Replace VALUES
 (N'abc',N'(a)(?<Mid>b)(c)',N'$3${Mid}$1',1,0,N'c',N'standard',N'cba'),
 (N'aaab',N'((a)+)(b)',N'$2:$1:$3',1,0,N'c',N'standard',N'a:aaa:b'),
 (N'b',N'(a)?(b)',N'$1/$2',1,0,N'c',N'standard',N'/b'),
 (N'ab',N'(a?)',N'[$1]',1,0,N'c',N'standard',N'[a][]b[]'),
 (N'a1a2a3',N'(a)([0-9])',N'$2$1',3,2,N'c',N'standard',N'a1a23a'),
 (N'a',N'(?<A>a)',N'$$1/$${A}/$$$1',1,0,N'c',N'standard',N'$1/${A}/$a'),
 (N'a',N'(a)',N'\$1',1,0,N'c',N'standard',N'\a'),
 (N'a',N'(z)',N'$1',1,0,N'c',N'standard',N'a'),
 (N'a',N'(a)',N'$1',3,0,N'c',N'standard',N'a'),
 (N'a',N'(a)',N'X',1,2,N'c',N'standard',N'a'),
 (NULL,N'[',N'$',0,-1,NULL,NULL,NULL),
 (N'a',NULL,N'$',0,-1,NULL,NULL,NULL),
 (N'a',N'[',NULL,0,-1,NULL,NULL,NULL);
DECLARE @Replacement nvarchar(max),@Occurrence int,@Expected nvarchar(max),@Result nvarchar(max);
SET @Case=1;
WHILE @Case<=(SELECT COUNT(*) FROM @Replace)
BEGIN
 SELECT @Input=Input,@Pattern=Pattern,@Replacement=Replacement,@Start=Start,@Occurrence=Occurrence,@Flags=Flags,@Profile=Profile,@Expected=Expected FROM @Replace WHERE Id=@Case;
 SET @Result=[$(ToolbeltDatabase)].toolbelt_string.SVF_RegexReplaceGroups(@Input,@Pattern,@Replacement,@Start,@Occurrence,@Flags,@Profile);
 IF (@Result IS NULL AND @Expected IS NOT NULL) OR (@Result IS NOT NULL AND @Expected IS NULL)
  OR CONVERT(varbinary(max),@Result)<>CONVERT(varbinary(max),@Expected)
  THROW 52097,N'Gruppen-Replace weicht vom unabhängigen Textorakel ab.',3;
 SET @Case+=1;
END;
IF [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexReplace(N'a',N'(a)',N'$1',DEFAULT,DEFAULT,DEFAULT,DEFAULT)<>N'$1'
 THROW 52097,N'Bestehendes literales Replace wurde verändert.',4;
IF NOT EXISTS(SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_RegexCaptures(N'a',N'(a)',DEFAULT,DEFAULT,DEFAULT,DEFAULT)
 WHERE MatchOrdinal=1 AND GroupOrdinal=1 AND CaptureOrdinal=1 AND GroupName=N'1')
 THROW 52097,N'Capture-Defaults fehlen.',5;

-- Fehlerprioritäten und unbekannte Referenzen gelten auch vor einer leeren Suche.
DECLARE @Errors table(Id int IDENTITY,Expression nvarchar(max),IsScalar bit,Prefix nvarchar(80));
INSERT @Errors VALUES
 (N'TVF_RegexCaptures(N''x'',N''['',0,N''bad'',N''bad'',0)',0,N'TBX_REGEX_INVALID_ARGUMENT'),
 (N'TVF_RegexCaptures(N''x'',N''['',0,N''bad'',N''standard'',1)',0,N'TBX_REGEX_INVALID_ARGUMENT'),
 (N'TVF_RegexCaptures(N''x'',N''['',1,N''bad'',N''standard'',1)',0,N'TBX_REGEX_INVALID_FLAGS'),
 (N'TVF_RegexCaptures(N''x'',N''['',3,N''c'',N''standard'',1)',0,N'TBX_REGEX_INVALID_PATTERN'),
 (N'TVF_RegexCaptures(N''x'',N''(?<A>x)(?<a>x)'',1,N''c'',N''standard'',10)',0,N'TBX_REGEX_INVALID_PATTERN'),
 (N'TVF_RegexCaptures(N''x'',N''(?<1>x)'',1,N''c'',N''standard'',10)',0,N'TBX_REGEX_INVALID_PATTERN'),
 (N'TVF_RegexCaptures(N''x'',N''(x)\1'',1,N''c'',N''standard'',10)',0,N'TBX_REGEX_INVALID_PATTERN'),
 (N'TVF_RegexCaptures(N''x'',N''(?:x)'',1,N''c'',N''standard'',10)',0,N'TBX_REGEX_INVALID_PATTERN'),
 (N'TVF_RegexCaptures(N''aa'',N''(a)'',1,N''c'',N''standard'',1)',0,N'TBX_REGEX_TOO_MANY_ROWS'),
 (N'TVF_RegexCaptures(N''b'',N''(a)?(b)'',1,N''c'',N''standard'',1)',0,N'TBX_REGEX_TOO_MANY_ROWS'),
 (N'TVF_RegexCaptures(N''x'',REPLICATE(CONVERT(nvarchar(max),N''(x)''),65),1,N''c'',N''standard'',100)',0,N'TBX_REGEX_PATTERN_TOO_COMPLEX'),
 (N'TVF_RegexCaptures(N''x'',N''(a?)*'',1,N''c'',N''standard'',100)',0,N'TBX_REGEX_CAPTURE_HISTORY_LIMIT'),
 (N'TVF_RegexCaptures(N''x'',N''((a?){1000}){1000}'',1,N''c'',N''standard'',100)',0,N'TBX_REGEX_CAPTURE_HISTORY_LIMIT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''['',N''$0'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_PATTERN'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(z)'',N''$10'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''${Unknown}'',3,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(?<Name>x)'',N''${name}'',1,0,N''i'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''${1}'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''$0'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''$01'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''$2147483648'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''$'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''${Name'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''$&'',1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'SVF_RegexReplaceGroups(N''x'',N''(x)'',N''$''+NCHAR(0x0661),1,0,N''c'',N''standard'')',1,N'TBX_REGEX_INVALID_REPLACEMENT'),
 (N'TVF_RegexCaptures(REPLICATE(CONVERT(nvarchar(max),N''a''),1048576),N''(a*)'',1,N''c'',N''standard'',10)',0,N'TBX_REGEX_OUTPUT_TOO_LARGE'),
 (N'SVF_RegexReplaceGroups(N''xx'',N''(x)'',REPLICATE(CONVERT(nvarchar(max),N''a''),1048576),1,0,N''c'',N''standard'')',1,N'TBX_REGEX_OUTPUT_TOO_LARGE');
DECLARE @Expression nvarchar(max),@IsScalar bit,@Prefix nvarchar(80),@Sql nvarchar(max),@Caught bit;
SET @Case=1;
WHILE @Case<=(SELECT COUNT(*) FROM @Errors)
BEGIN
 SELECT @Expression=Expression,@IsScalar=IsScalar,@Prefix=Prefix FROM @Errors WHERE Id=@Case;
 SET @Sql=CASE WHEN @IsScalar=1 THEN N'DECLARE @Value nvarchar(max)=[$(ToolbeltDatabase)].toolbelt_string.'+@Expression+N';'
 ELSE N'DECLARE @Count bigint; SELECT @Count=COUNT_BIG(*) FROM [$(ToolbeltDatabase)].toolbelt_string.'+@Expression+N';' END;
 SET @Caught=0;
 BEGIN TRY
  EXEC sys.sp_executesql @Sql;
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()<>6522 OR CHARINDEX(@Prefix,ERROR_MESSAGE())=0 THROW;
  SET @Caught=1;
 END CATCH;
 IF @Caught=0 THROW 52097,N'Capture-Fehlerpräfix wurde nicht ausgelöst.',6;
 SET @Case+=1;
END;
DROP TABLE #CaptureActual;
DROP TABLE #CaptureExpected;
PRINT N'Capture-/Replace-Vertragsorakel erfolgreich.';
