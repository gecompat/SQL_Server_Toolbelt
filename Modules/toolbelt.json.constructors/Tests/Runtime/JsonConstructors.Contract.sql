SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE #JsonEntries(Ordinal int NULL,[Key] nvarchar(max) NULL,ValueKind nvarchar(max) NULL,[Value] nvarchar(max) NULL,Ignored int NULL);
CREATE TABLE #JsonOutput(Dummy int);
INSERT #JsonEntries VALUES(20,N'a ',N'null',NULL,0),(9,N'A',N'number',N'-0.125E+20',0),(3,N'a',N'string',N'quote"\'+NCHAR(0)+NCHAR(9)+NCHAR(10),0),(12,N'boolean',N'boolean',N'false',0),(15,N'json',N'json',N'{"nested":[1,null]}',0);
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
DECLARE @Actual nvarchar(max),@Expected nvarchar(max)=N'{"a":"quote\"\\\u0000\t\n","A":-0.125E+20,"boolean":false,"json":{"nested":[1,null]},"a ":null}';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@Expected) THROW 54600,N'Object byte oracle failed.',1;
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
SET @Expected=N'["quote\"\\\u0000\t\n",-0.125E+20,false,{"nested":[1,null]},null]';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@Expected) THROW 54600,N'Array byte oracle failed.',2;
IF (SELECT COUNT(*) FROM #JsonEntries)<>5 THROW 54600,N'Input mutated.',3;
DELETE #JsonEntries;
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),N'[]') THROW 54600,N'Empty array wrong.',4;
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),N'{}') THROW 54600,N'Empty object wrong.',5;

DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
INSERT @Help EXEC toolbelt_json.USP_JsonArray @Hilfe=1,@EntriesTable=N'##missing',@MaxEntries=0,@MaxResultBytes=NULL,@ResultTable=N'#JsonEntries',@KeepData=1,@Debug=255;
IF (SELECT COUNT(*) FROM @Help WHERE Section='PARAMETER')<>8 OR NOT EXISTS(SELECT 1 FROM @Help WHERE Section='EXAMPLE') THROW 54600,N'Help contract wrong.',6;
IF EXISTS(SELECT 1 FROM @Help WHERE SchemaName<>N'toolbelt_json' OR ObjectName<>N'USP_JsonArray') THROW 54600,N'Help identity wrong.',7;
IF (SELECT COUNT(*) FROM #JsonOutput)<>1 THROW 54600,N'Help mutated target.',8;
DELETE @Help;
INSERT @Help EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
IF (SELECT COUNT(*) FROM @Help WHERE Section='PARAMETER')<>8 THROW 54600,N'Object Help wrong.',9;

-- Bad literals, NULL contracts and Unicode must leave the previous output unchanged.
DECLARE @Cases TABLE(Id int IDENTITY(1,1),Kind nvarchar(max),Val nvarchar(max),ExpectedError int);
INSERT @Cases(Kind,Val,ExpectedError) VALUES
(N'number',N'',53608),(N'number',N'-',53608),(N'number',N'01',53608),(N'number',N'1.',53608),(N'number',N'.1',53608),(N'number',N'1e',53608),(N'number',N'1e+',53608),(N'number',N'+1',53608),(N'number',N'1 ',53608),(N'number',N' 1',53608),(N'number',N'NaN',53608),(N'number',N'1,2',53608),
(N'boolean',N'True',53608),(N'boolean',N'true ',53608),(N'json',N'1',53608),(N'json',N'null',53608),(N'json',N'{',53608),
(N'null',N'null',53606),(N'string',NULL,53606),(N'NULL',NULL,53605),(N'string ',N'x',53605),(NULL,N'x',53605),
(N'string',NCHAR(55296),53607),(N'string',NCHAR(56320),53607),(N'string',NCHAR(55296)+N'x',53607);
INSERT @Cases(Kind,Val,ExpectedError) VALUES
(N'string',NCHAR(0)+NCHAR(55296),53607),
(N'json',N'{"x":"\uD800"}',53607),(N'json',N'{"\uDC00":0}',53607),
(N'json',N'{"x":[{"nested":"\uD800\n\uDC00"}]}',53607),
(N'json',N'{"x":"\uD800\uD800"}',53607);
DECLARE @Id int=1,@MaxId int=(SELECT MAX(Id) FROM @Cases),@Kind nvarchar(max),@Val nvarchar(max),@Error int;
WHILE @Id<=@MaxId
BEGIN
 SELECT @Kind=Kind,@Val=Val,@Error=ExpectedError FROM @Cases WHERE Id=@Id;
 DELETE #JsonEntries; INSERT #JsonEntries VALUES(1,N'key',@Kind,@Val,0);
 BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput'; THROW 54600,N'Invalid value accepted.',10; END TRY
 BEGIN CATCH IF ERROR_NUMBER()<>@Error THROW; END CATCH;
 EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
 IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),N'{}') THROW 54600,N'Failure changed output.',11;
 SET @Id+=1;
END;
DELETE #JsonEntries;
INSERT #JsonEntries VALUES(1,N'k',N'string',NCHAR(55296)+NCHAR(56320)+N' ',0);
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
SET @Expected=N'["'+NCHAR(55296)+NCHAR(56320)+N' "]';
IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@Expected) THROW 54600,N'Supplementary/trailing space changed.',12;
INSERT #JsonEntries VALUES(3,N'k',N'null',NULL,0);
BEGIN TRY EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries'; THROW 54600,N'Duplicate key accepted.',13; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53604 THROW; END CATCH;
UPDATE #JsonEntries SET [Key]=N'k ' WHERE Ordinal=3;
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
UPDATE #JsonEntries SET [Key]=CASE WHEN Ordinal=1 THEN N'k'+NCHAR(0) ELSE N'k'+NCHAR(1) END;
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
UPDATE #JsonEntries SET [Key]=N'k'+NCHAR(0);
BEGIN TRY EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries'; THROW 54600,N'Exact binary NUL-key duplicate accepted.',60; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53604 THROW; END CATCH;
UPDATE #JsonEntries SET Ordinal=1;
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries'; THROW 54600,N'Duplicate ordinal accepted.',14; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53602 THROW; END CATCH;
DELETE #JsonEntries;
INSERT #JsonEntries VALUES(0,NULL,N'INVALID',NULL,0);
BEGIN TRY EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries'; THROW 54600,N'Ordinal priority wrong.',15; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53602 THROW; END CATCH;
UPDATE #JsonEntries SET Ordinal=1;
BEGIN TRY EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries'; THROW 54600,N'Key priority wrong.',16; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53603 THROW; END CATCH;
UPDATE #JsonEntries SET [Key]=N'key',ValueKind=N'null',[Value]=NULL;
BEGIN TRY EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries',@MaxEntries=0; THROW 54600,N'Zero limit accepted.',17; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53600 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonEntries'; THROW 54600,N'Same object accepted.',18; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53601 THROW; END CATCH;
CREATE TABLE #WrongTypes(Ordinal bigint,ValueKind nvarchar(max),[Value] nvarchar(max));
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#WrongTypes'; THROW 54600,N'Wrong type accepted.',19; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53601 THROW; END CATCH;

-- Exact byte budgets and expansion: raw x requires ["x"] =10 UTF-16 bytes.
UPDATE #JsonEntries SET ValueKind=N'string',[Value]=N'x';
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxTotalValueBytes=2,@MaxResultBytes=10,@ResultTable=N'#JsonOutput';
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxTotalValueBytes=1; THROW 54600,N'Value budget accepted.',20; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxResultBytes=9; THROW 54600,N'Output budget accepted.',21; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
UPDATE #JsonEntries SET [Value]=REPLICATE(CAST(N'x' AS nvarchar(max)),1048572);
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR DATALENGTH(@Actual)<>2097152 THROW 54600,N'2MiB output boundary failed.',22;
UPDATE #JsonEntries SET [Value]=[Value]+N'x';
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries'; THROW 54600,N'2MiB output overflow accepted.',23; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
UPDATE #JsonEntries SET [Value]=N'x';
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
UPDATE #JsonEntries SET ValueKind=N'json',[Value]=N'{"\uD800\uDC00":"\uD83D\uDE00","literal":"\\uD800"}';
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
SET @Expected=N'[{"\uD800\uDC00":"\uD83D\uDE00","literal":"\\uD800"}]';
IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@Expected) THROW 54600,N'Escaped Unicode fragment changed.',48;
UPDATE #JsonEntries SET ValueKind=N'string',[Value]=N'x';
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput',@KeepData=1;
IF (SELECT COUNT(*) FROM #JsonOutput)<>2 THROW 54600,N'Append failed.',24;
CREATE TABLE #WrongOutput(Dummy int); INSERT #WrongOutput VALUES(7);
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#WrongOutput',@KeepData=1; THROW 54600,N'Wrong schema append accepted.',25; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51025 THROW; END CATCH;
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#WrongOutput',@KeepData=0;
IF (SELECT COUNT(*) FROM #WrongOutput)<>1 THROW 54600,N'Wrong schema replace failed.',26;
CREATE TABLE #JsonBlocked(Dummy int CHECK(Dummy>0)); INSERT #JsonBlocked VALUES(7);
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonBlocked'; THROW 54600,N'Blocked schema replaced.',27; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51026 THROW; END CATCH;
IF (SELECT Dummy FROM #JsonBlocked)<>7 THROW 54600,N'Blocked schema data changed.',28;
CREATE TABLE #JsonConstrained(JsonValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL CHECK(JsonValue=N'old'));
INSERT #JsonConstrained VALUES(N'old');
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonConstrained'; THROW 54600,N'Constraint bypassed.',29; END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54600,N'Own transaction leaked.',30;
IF (SELECT COUNT(*) FROM #JsonConstrained)<>1 OR NOT EXISTS(SELECT 1 FROM #JsonConstrained WHERE CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'old')) THROW 54600,N'Own rollback did not restore target.',31;
BEGIN TRAN;
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonConstrained'; THROW 54600,N'Caller constraint bypassed.',32; END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 BEGIN ROLLBACK; THROW; END; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 BEGIN ROLLBACK; THROW 54600,N'Caller state lost.',33; END;
IF NOT EXISTS(SELECT 1 FROM #JsonConstrained WHERE JsonValue=N'old') BEGIN ROLLBACK; THROW 54600,N'Caller savepoint did not restore.',34; END;
ROLLBACK;
-- Ressourcen werden bereits vor privater LOB-Kopie geprüft.
UPDATE #JsonEntries SET [Value]=REPLICATE(CAST(N'x' AS nvarchar(max)),4194304);
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries'; THROW 54600,N'Precopy value limit missing.',49; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
UPDATE #JsonEntries SET [Value]=N'x',[Key]=REPLICATE(CAST(N'k' AS nvarchar(max)),1025);
BEGIN TRY EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries'; THROW 54600,N'Key1025 accepted.',50; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53603 THROW; END CATCH;
UPDATE #JsonEntries SET [Key]=REPLICATE(CAST(N'k' AS nvarchar(max)),1024);
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
UPDATE #JsonEntries SET [Key]=NCHAR(0)+NCHAR(55296);
BEGIN TRY EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#JsonEntries'; THROW 54600,N'Key invalid Unicode accepted.',51; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53607 THROW; END CATCH;
UPDATE #JsonEntries SET [Key]=N'key',[Value]=REPLICATE(CAST(NCHAR(1) AS nvarchar(max)),100);
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxResultBytes=1208,@ResultTable=N'#JsonOutput';
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxResultBytes=1207; THROW 54600,N'Escape budget missing.',52; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
UPDATE #JsonEntries SET [Value]=REPLICATE(CAST(N'x' AS nvarchar(max)),8388604);
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxTotalValueBytes=16777216,@MaxResultBytes=16777216,@ResultTable=N'#JsonOutput';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR DATALENGTH(@Actual)<>16777216 THROW 54600,N'16MiB output boundary failed.',53;
UPDATE #JsonEntries SET [Value]=[Value]+N'x';
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxTotalValueBytes=16777216,@MaxResultBytes=16777216; THROW 54600,N'16MiB output overflow accepted.',54; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
DELETE #JsonEntries;
;WITH D AS(SELECT n FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) x(n))
INSERT #JsonEntries SELECT 1+a.n+10*b.n+100*c.n+1000*d.n+10000*e.n,N'ignored',N'null',NULL,0
FROM D a CROSS JOIN D b CROSS JOIN D c CROSS JOIN D d CROSS JOIN D e;
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries'; THROW 54600,N'Default entry limit missing.',55; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxEntries=100000,@ResultTable=N'#JsonOutput';
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR DATALENGTH(@Actual)<>1000002 THROW 54600,N'100000 entries contract failed.',56;
INSERT #JsonEntries VALUES(100001,N'ignored',N'null',NULL,0);
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@MaxEntries=100000; THROW 54600,N'100001 entries accepted.',57; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 THROW; END CATCH;
DELETE #JsonEntries;INSERT #JsonEntries VALUES(1,N'key',N'string',N'x',0);
SET XACT_ABORT ON;
BEGIN TRAN;
BEGIN TRY EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonConstrained'; THROW 54600,N'Doomed insert accepted.',58; END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 BEGIN IF XACT_STATE()<>0 ROLLBACK; THROW; END; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 BEGIN IF XACT_STATE()<>0 ROLLBACK; THROW 54600,N'Doomed caller state wrong.',59; END;
ROLLBACK;SET XACT_ABORT OFF;
DECLARE @ValidNumbers TABLE(Id int IDENTITY(1,1),Literal nvarchar(max));
INSERT @ValidNumbers VALUES(N'0'),(N'-0'),(N'123456789012345678901234567890'),(N'1e4000'),(N'1E-4000'),(N'1.0'),(N'-10.25e+02');
SELECT @Id=1,@MaxId=MAX(Id) FROM @ValidNumbers;
WHILE @Id<=@MaxId
BEGIN
 SELECT @Val=Literal FROM @ValidNumbers WHERE Id=@Id;
 UPDATE #JsonEntries SET ValueKind=N'number',[Value]=@Val;
 EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput';
 EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
 SET @Expected=N'['+@Val+N']';
 IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@Expected) THROW 54600,N'Valid number rewritten.',61;
 SET @Id+=1;
END;
UPDATE #JsonEntries SET ValueKind=N'boolean',[Value]=N'true';
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#JsonEntries',@ResultTable=N'#JsonOutput',@KeepData=NULL,@Debug=NULL,@Hilfe=NULL;
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #JsonOutput',N'@x nvarchar(max) OUTPUT',@Actual OUTPUT;
IF @Actual IS NULL OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),N'[true]') THROW 54600,N'Boolean true/NULL defaults wrong.',62;
PRINT N'JSON Constructors synthetic contract PASS.';
