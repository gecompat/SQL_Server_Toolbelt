SET NOCOUNT ON;
CREATE TABLE #ZipInput(Ordinal int NULL,EntryName nvarchar(max) NULL,Payload varbinary(max) NULL);
CREATE TABLE #ZipOutput(Dummy int);
INSERT #ZipInput VALUES(3,N'empty.txt',0x),(9,N'unicode-ä.txt',0x0001FF),(15,N'space ',0x486920),(20,N'space',0x4869);
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ZipOutput',@KeepData=NULL,@Debug=NULL,@Hilfe=NULL;
IF (SELECT COUNT(*) FROM #ZipOutput)<>1 THROW 51389,N'Writer output row missing.',1;
DECLARE @Archive varbinary(max),@Count int,@Total bigint,@Size bigint;
EXEC sys.sp_executesql N'SELECT @a=ArchivePayload,@c=EntryCount,@t=TotalPayloadBytes,@s=ArchiveBytes FROM #ZipOutput',N'@a varbinary(max) OUTPUT,@c int OUTPUT,@t bigint OUTPUT,@s bigint OUTPUT',@Archive OUTPUT,@Count OUTPUT,@Total OUTPUT,@Size OUTPUT;
IF @Archive IS NULL OR @Count IS NULL OR @Count<>4 OR @Total IS NULL OR @Total<>8 OR @Size IS NULL OR @Size<>DATALENGTH(@Archive) THROW 51389,N'Writer output values wrong.',2;
CREATE TABLE #Extracted(Dummy int);
DECLARE @DirectEmpty varbinary(max),@EmptyCount int,@Payload varbinary(max);
DECLARE @EmptyPublic TABLE(EntryName nvarchar(1024),CompressedBytes bigint,UncompressedBytes bigint,CompressionMethod int,Crc32 int,IsEncrypted bit,EntryPayload varbinary(max));
SELECT @DirectEmpty=EntryPayload FROM [$(ToolbeltDatabase)].toolbelt_archive.TVF_InternalExtractZipEntryClr(@Archive,N'empty.txt',104857600,200,1);
IF @@ROWCOUNT<>1 OR @DirectEmpty IS NULL OR DATALENGTH(@DirectEmpty)<>0 THROW 51389,N'Empty Stored directFT contract failed.',30;
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'empty.txt',@ResultTable=N'#Extracted';
EXEC sys.sp_executesql N'SELECT @p=EntryPayload FROM #Extracted',N'@p varbinary(max) OUTPUT',@Payload OUTPUT;
IF (SELECT COUNT(*) FROM #Extracted)<>1 OR @Payload IS NULL OR DATALENGTH(@Payload)<>0 THROW 51389,N'Empty Stored resulttable failed.',48;
INSERT @EmptyPublic EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'empty.txt';
IF (SELECT COUNT(*) FROM @EmptyPublic)<>1 OR NOT EXISTS(SELECT 1 FROM @EmptyPublic WHERE EntryPayload IS NOT NULL AND DATALENGTH(EntryPayload)=0 AND CompressionMethod=0) THROW 51389,N'Empty Stored SELECT failed.',49;
DELETE @EmptyPublic;
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'space ',@ResultTable=N'#Extracted';
EXEC sys.sp_executesql N'SELECT @p=EntryPayload FROM #Extracted',N'@p varbinary(max) OUTPUT',@Payload OUTPUT;
IF @Payload IS NULL OR @Payload<>0x486920 THROW 51389,N'Writer trailing-space roundtrip failed.',3;
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@CompressionMethod='Deflate',@ResultTable=N'#ZipOutput';
EXEC sys.sp_executesql N'SELECT @a=ArchivePayload FROM #ZipOutput',N'@a varbinary(max) OUTPUT',@Archive OUTPUT;
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'empty.txt',@ResultTable=N'#Extracted';
EXEC sys.sp_executesql N'SELECT @p=EntryPayload FROM #Extracted',N'@p varbinary(max) OUTPUT',@Payload OUTPUT;
IF @Payload IS NULL BEGIN
 DECLARE @DirectPayload varbinary(max),@DirectLength bigint;
 SELECT @DirectPayload=EntryPayload,@DirectLength=UncompressedBytes FROM [$(ToolbeltDatabase)].toolbelt_archive.TVF_InternalExtractZipEntryClr(@Archive,N'empty.txt',104857600,200,1);
 IF @DirectPayload IS NULL AND @DirectLength=0 THROW 51389,N'Existing Reader direct FT marshals zero-byte payload as NULL.',4;
 THROW 51389,N'Writer empty Deflate USP/resulttable alone returned NULL.',4;
END;
IF DATALENGTH(@Payload)<>0 THROW 51389,N'Writer empty Deflate roundtrip returned nonempty payload.',4;
SELECT @DirectEmpty=EntryPayload FROM [$(ToolbeltDatabase)].toolbelt_archive.TVF_InternalExtractZipEntryClr(@Archive,N'empty.txt',104857600,200,1);
IF @@ROWCOUNT<>1 OR @DirectEmpty IS NULL OR DATALENGTH(@DirectEmpty)<>0 THROW 51389,N'Empty Deflate directFT contract failed.',31;
INSERT @EmptyPublic EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'empty.txt';
IF (SELECT COUNT(*) FROM @EmptyPublic)<>1 OR NOT EXISTS(SELECT 1 FROM @EmptyPublic WHERE EntryPayload IS NOT NULL AND DATALENGTH(EntryPayload)=0 AND UncompressedBytes=0 AND CompressionMethod=8) THROW 51389,N'Empty Deflate public SELECT contract failed.',32;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ZipInput'; THROW 51389,N'Same input/output accepted.',5; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51351 THROW; END CATCH;
INSERT #ZipInput VALUES(30,N'space',0x);
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput'; THROW 51389,N'Duplicate accepted.',6; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51353 THROW; END CATCH;
DELETE #ZipInput WHERE Ordinal=30;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@CompressionMethod='Stored '; THROW 51389,N'Method suffix accepted.',7; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51350 THROW; END CATCH;
DELETE #ZipInput;
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@MaxArchiveBytes=22,@ResultTable=N'#ZipOutput';
EXEC sys.sp_executesql N'SELECT @s=ArchiveBytes FROM #ZipOutput',N'@s bigint OUTPUT',@Size OUTPUT;
IF @Size IS NULL OR @Size<>22 THROW 51389,N'Empty ZIP must contain EOCD22.',8;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@MaxArchiveBytes=21,@ResultTable=N'#ZipOutput'; THROW 51389,N'Output limit accepted.',9; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51354 THROW; END CATCH;
EXEC sys.sp_executesql N'SELECT @s=ArchiveBytes FROM #ZipOutput',N'@s bigint OUTPUT',@Size OUTPUT;
IF @Size IS NULL OR @Size<>22 THROW 51389,N'Failure mutated output.',10;
-- Help-Vorrang: absichtlich ungültige fachliche/Steuerparameter.
DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
INSERT @Help EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1,@EntryTable=N'##missing',@CompressionMethod=NULL,@MaxEntries=NULL,@ResultTable=N'#missing',@KeepData=NULL;
IF (SELECT COUNT(*) FROM @Help WHERE Section='PARAMETER')<>13 OR (SELECT COUNT(*) FROM @Help WHERE Section='RESULT_COLUMN')<>5 THROW 51389,N'Helpcontract incomplete.',11;
INSERT #ZipInput VALUES(1,N'valid.txt',0x0102);
DECLARE @Cases TABLE(Id int IDENTITY PRIMARY KEY,Arguments nvarchar(2000),Expected int);
INSERT @Cases(Arguments,Expected) VALUES
(N'@EntryTable=NULL',51351),(N'@EntryTable=N''#missing''',51351),(N'@EntryTable=N''##global''',51351),
(N'@EntryTable=N''#ZipInput'',@MaxEntries=NULL',51350),(N'@EntryTable=N''#ZipInput'',@MaxEntries=0',51350),(N'@EntryTable=N''#ZipInput'',@MaxEntries=1025',51350),
(N'@EntryTable=N''#ZipInput'',@MaxEntryNameCodeUnits=NULL',51350),(N'@EntryTable=N''#ZipInput'',@MaxEntryNameCodeUnits=2049',51350),
(N'@EntryTable=N''#ZipInput'',@MaxEntryBytes=NULL',51350),(N'@EntryTable=N''#ZipInput'',@MaxEntryBytes=33554433',51350),
(N'@EntryTable=N''#ZipInput'',@MaxTotalPayloadBytes=NULL',51350),(N'@EntryTable=N''#ZipInput'',@MaxTotalPayloadBytes=134217729',51350),
(N'@EntryTable=N''#ZipInput'',@MaxArchiveBytes=NULL',51350),(N'@EntryTable=N''#ZipInput'',@MaxArchiveBytes=150994945',51350),
(N'@EntryTable=N''#ZipInput'',@MaxEnvelopeBytes=NULL',51350),(N'@EntryTable=N''#ZipInput'',@MaxEnvelopeBytes=142606337',51350),
(N'@EntryTable=N''#ZipInput'',@WriterBudgetMilliseconds=NULL',51350),(N'@EntryTable=N''#ZipInput'',@WriterBudgetMilliseconds=60001',51350),
(N'@EntryTable=N''#ZipInput'',@CompressionMethod=NULL',51350),(N'@EntryTable=N''#ZipInput'',@CompressionMethod=''stored''',51350),
(N'@EntryTable=N''#ZipInput'',@MaxEntryBytes=1',51354),(N'@EntryTable=N''#ZipInput'',@MaxTotalPayloadBytes=1',51354),(N'@EntryTable=N''#ZipInput'',@MaxEnvelopeBytes=1',51354),(N'@EntryTable=N''#ZipInput'',@MaxArchiveBytes=1',51354);
DECLARE @Id int=1,@Arguments nvarchar(2000),@Expected int,@Sql nvarchar(max);
WHILE @Id<=(SELECT MAX(Id) FROM @Cases)
BEGIN
 SELECT @Arguments=Arguments,@Expected=Expected FROM @Cases WHERE Id=@Id;
 SET @Sql=N'EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries '+@Arguments+N',@ResultTable=N''#ZipOutput'';';
 BEGIN TRY EXEC sys.sp_executesql @Sql; THROW 51389,N'Invalid argument accepted.',12; END TRY BEGIN CATCH IF ERROR_NUMBER()<>@Expected THROW; END CATCH;
 EXEC sys.sp_executesql N'SELECT @s=ArchiveBytes FROM #ZipOutput',N'@s bigint OUTPUT',@Size OUTPUT;
 IF @Size IS NULL OR @Size<>22 THROW 51389,N'Argument failure mutated output.',13;
 SET @Id+=1;
END;
-- Mutable input value contracts and exact names (including UTF16 surrogate).
DECLARE @BadNames TABLE(Id int IDENTITY,Name nvarchar(max));
INSERT @BadNames VALUES(N''),(N'../x'),(N'/x'),(N'x/'),(N'x//y'),(N'x\y'),(N'x:y'),(N'.'),(N'x/..'),(N'a'+NCHAR(0)+N'b'),(CONVERT(nvarchar(max),0x00D8));
SET @Id=1;
WHILE @Id<=(SELECT MAX(Id) FROM @BadNames)
BEGIN
 UPDATE #ZipInput SET EntryName=(SELECT Name FROM @BadNames WHERE Id=@Id);
 BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ZipOutput'; THROW 51389,N'Invalid name accepted.',14; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51352 THROW; END CATCH;
 SET @Id+=1;
END;
UPDATE #ZipInput SET EntryName=NULL;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput'; THROW 51389,N'NULL name accepted.',15; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51350 THROW; END CATCH;
UPDATE #ZipInput SET EntryName=N'valid',Payload=NULL;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput'; THROW 51389,N'NULL payload accepted.',16; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51350 THROW; END CATCH;
UPDATE #ZipInput SET Payload=0x,Ordinal=0;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput'; THROW 51389,N'Zero ordinal accepted.',17; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51350 THROW; END CATCH;
UPDATE #ZipInput SET Ordinal=1;
INSERT #ZipInput VALUES(1,N'other',0x);
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput'; THROW 51389,N'Duplicate ordinal accepted.',18; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51350 THROW; END CATCH;
DELETE #ZipInput WHERE EntryName=N'other';
-- Name lengths and unchanged reader cap; max writer names not a reader upgrade.
UPDATE #ZipInput SET EntryName=REPLICATE(CONVERT(nvarchar(max),N'a'),1024);
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ZipOutput';
UPDATE #ZipInput SET EntryName=REPLICATE(CONVERT(nvarchar(max),N'a'),1025);
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput'; THROW 51389,N'Default name limit bypass.',19; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51354 THROW; END CATCH;
UPDATE #ZipInput SET EntryName=REPLICATE(CONVERT(nvarchar(max),N'a'),2048);
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@MaxEntryNameCodeUnits=2048,@ResultTable=N'#ZipOutput';
EXEC sys.sp_executesql N'SELECT @a=ArchivePayload FROM #ZipOutput',N'@a varbinary(max) OUTPUT',@Archive OUTPUT;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@Archive; THROW 51389,N'Reader name1024 cap changed.',33; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51325 THROW; END CATCH;
-- Append and schema refusal leave original caller rows intact.
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@MaxEntryNameCodeUnits=2048,@ResultTable=N'#ZipOutput',@KeepData=1;
IF (SELECT COUNT(*) FROM #ZipOutput)<>2 THROW 51389,N'Append failed.',20;
CREATE TABLE #BadOutput(Existing int); INSERT #BadOutput VALUES(7);
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@MaxEntryNameCodeUnits=2048,@ResultTable=N'#BadOutput',@KeepData=1; THROW 51389,N'Schema blocker ignored.',21; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51025 THROW; END CATCH;
IF (SELECT COUNT(*) FROM #BadOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #BadOutput WHERE Existing=7) THROW 51389,N'Schema failure mutated caller rows.',22;
-- Caller transaction depth is preserved for committable and doomed errors.
UPDATE #ZipInput SET EntryName=N'valid',Payload=0x01;
-- Exakte lower Input-/Envelope-/Archive-Budgets und high-ratio Readeroverride.
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@MaxEntries=1,@MaxEntryNameCodeUnits=5,@MaxEntryBytes=1,@MaxTotalPayloadBytes=1,@MaxEnvelopeBytes=34,@MaxArchiveBytes=109,@ResultTable=N'#ZipOutput';
CREATE TABLE #WrongInput(Ordinal bigint,EntryName nvarchar(max),Payload varbinary(max));
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#WrongInput'; THROW 51389,N'Wrong schema accepted.',27; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51351 THROW; END CATCH;
DROP TABLE #WrongInput;
UPDATE #ZipInput SET Payload=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'a'),100000));
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@CompressionMethod='Deflate',@ResultTable=N'#ZipOutput';
EXEC sys.sp_executesql N'SELECT @a=ArchivePayload FROM #ZipOutput',N'@a varbinary(max) OUTPUT',@Archive OUTPUT;
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'valid'; THROW 51389,N'Reader ratio200 cap changed.',34; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51326 THROW; END CATCH;
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'valid',@MaxCompressionRatio=10000,@ResultTable=N'#Extracted';
EXEC sys.sp_executesql N'SELECT @p=EntryPayload FROM #Extracted',N'@p varbinary(max) OUTPUT',@Payload OUTPUT;
IF @Payload IS NULL OR DATALENGTH(@Payload)<>100000 THROW 51389,N'High ratio roundtrip failed.',28;
UPDATE #ZipInput SET Payload=0x01;
DECLARE @Abort int=0;
WHILE @Abort<2
BEGIN
 IF @Abort=0 SET XACT_ABORT OFF; ELSE SET XACT_ABORT ON;
 BEGIN TRANSACTION; INSERT #BadOutput VALUES(8);
 EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ZipOutput';
 IF @@TRANCOUNT<>1 THROW 51389,N'Writer changed caller transaction depth.',23;
 BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@MaxArchiveBytes=1,@ResultTable=N'#ZipOutput'; THROW 51389,N'Expected transaction failure.',24; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51354 THROW; END CATCH;
 IF @@TRANCOUNT<>1 OR XACT_STATE()=0 THROW 51389,N'Writer rolled back full caller transaction.',25;
 IF (@Abort=0 AND XACT_STATE()<>1) OR (@Abort=1 AND XACT_STATE()<>-1) THROW 51389,N'Caller XACT_ABORT contract failed.',29;
 ROLLBACK TRANSACTION;
 IF (SELECT COUNT(*) FROM #BadOutput)<>1 THROW 51389,N'Caller rollback failed.',26;
 SET @Abort+=1;
END;
SET XACT_ABORT OFF;
-- Echte Zielconstraint-Enginefehler statt nur fachlicher Vorabfehler.
CREATE TABLE #ConstraintOutput(ArchivePayload varbinary(max) NOT NULL,ArchiveBytes bigint NOT NULL,EntryCount int NOT NULL,TotalPayloadBytes bigint NOT NULL,CompressionMethod int NOT NULL CHECK(CompressionMethod=-1));
INSERT #ConstraintOutput VALUES(0xFF,1,1,1,-1);
BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ConstraintOutput'; THROW 51389,N'OwnTx CHECK failure missing.',35; END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51389,N'OwnTx state/depth failed.',36;
IF (SELECT COUNT(*) FROM #ConstraintOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #ConstraintOutput WHERE ArchivePayload=0xFF AND CompressionMethod=-1) THROW 51389,N'OwnTx mutation rollback failed.',36;
SET @Abort=0;
WHILE @Abort<2
BEGIN
 IF @Abort=0 SET XACT_ABORT OFF; ELSE SET XACT_ABORT ON;
 BEGIN TRANSACTION;
 BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ConstraintOutput'; THROW 51389,N'Caller CHECK failure missing.',37; END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
 IF @@TRANCOUNT<>1 OR (@Abort=0 AND XACT_STATE()<>1) OR (@Abort=1 AND XACT_STATE()<>-1) THROW 51389,N'Caller CHECK state/depth changed.',38;
 IF @Abort=0 AND ((SELECT COUNT(*) FROM #ConstraintOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #ConstraintOutput WHERE ArchivePayload=0xFF AND CompressionMethod=-1)) THROW 51389,N'Caller Savepoint restoration failed.',39;
 ROLLBACK TRANSACTION;
 IF (SELECT COUNT(*) FROM #ConstraintOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #ConstraintOutput WHERE ArchivePayload=0xFF AND CompressionMethod=-1) THROW 51389,N'Caller CHECK rollback failed.',40;
 SET @Abort+=1;
END;
SET XACT_ABORT OFF;
DROP TABLE #ConstraintOutput;
-- Count/Ordinal-Endianness über das niedrige Byte hinaus.
DELETE #ZipInput;
;WITH n AS(SELECT TOP(256) ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) i FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT #ZipInput SELECT CONVERT(int,i+1000),N'entry-'+CONVERT(nvarchar(10),i),0x FROM n;
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ZipOutput';
EXEC sys.sp_executesql N'SELECT @a=ArchivePayload,@c=EntryCount FROM #ZipOutput',N'@a varbinary(max) OUTPUT,@c int OUTPUT',@Archive OUTPUT,@Count OUTPUT;
IF @Count IS NULL OR @Count<>256 THROW 51389,N'Count byteorder failed.',41;
CREATE TABLE #Listed(Dummy int);
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@Archive,@ResultTable=N'#Listed';
IF (SELECT COUNT(*) FROM #Listed)<>256 THROW 51389,N'Independent reader count failed.',42;
DROP TABLE #Listed;
-- Tatsächliche Standard16MiB-LOBs, beide Methoden, Hash/Length-Oracles.
DELETE #ZipInput;
DECLARE @LargePayload varbinary(max)=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'synthetic0123456'),1048576)),@ExpectedDigest varbinary(32),@Compression varchar(7),@MethodIndex int=0;
IF DATALENGTH(@LargePayload)<>16777216 THROW 51389,N'Synthetic LOB fixture size wrong.',43;
SET @ExpectedDigest=HASHBYTES('SHA2_256',@LargePayload);
INSERT #ZipInput VALUES(1,N'large.bin',@LargePayload);
WHILE @MethodIndex<2
BEGIN
 SET @Compression=CASE WHEN @MethodIndex=0 THEN 'Stored' ELSE 'Deflate' END;
 EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@CompressionMethod=@Compression,@ResultTable=N'#ZipOutput';
 EXEC sys.sp_executesql N'SELECT @a=ArchivePayload FROM #ZipOutput',N'@a varbinary(max) OUTPUT',@Archive OUTPUT;
 EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'large.bin',@MaxCompressionRatio=10000,@ResultTable=N'#Extracted';
 EXEC sys.sp_executesql N'SELECT @p=EntryPayload FROM #Extracted',N'@p varbinary(max) OUTPUT',@Payload OUTPUT;
 IF @Payload IS NULL OR DATALENGTH(@Payload)<>16777216 OR HASHBYTES('SHA2_256',@Payload)<>@ExpectedDigest THROW 51389,N'Large payload marshalling/hash failed.',44;
 SET @MethodIndex+=1;
END;
-- Nichtkanonische Dependencyversion plus übereinstimmendem Objektmarker.
DECLARE @Malformed TABLE(Id int IDENTITY,Value nvarchar(64)); INSERT @Malformed VALUES(N'1.bad.xxx'),(N'1.01.0'),(N'+1.0.0');
SET @Id=1;
WHILE @Id<=3
BEGIN
 DECLARE @BadVersion nvarchar(64)=(SELECT Value FROM @Malformed WHERE Id=@Id);
 BEGIN TRANSACTION;
 SET @Sql=N'EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.Module.toolbelt.core.result-table.Version'',@value=@v; EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.ModuleVersion'',@value=@v,@level0type=N''SCHEMA'',@level0name=N''toolbelt_core'',@level1type=N''PROCEDURE'',@level1name=N''USP_PrepareResultTable'';';
 EXEC [$(ToolbeltDatabase)].sys.sp_executesql @Sql,N'@v nvarchar(64)',@BadVersion;
 DELETE @Help;
 INSERT @Help EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
 IF (SELECT COUNT(*) FROM @Help WHERE Section='PARAMETER')<>13 THROW 51389,N'Help depends on valid helper.',45;
 BEGIN TRY EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput',@ResultTable=N'#ZipOutput'; THROW 51389,N'Malformed dependency accepted.',46; END TRY BEGIN CATCH IF ERROR_NUMBER()<>51357 THROW; END CATCH;
 IF @@TRANCOUNT<>1 THROW 51389,N'Dependency error touched callertransaction.',47;
 ROLLBACK TRANSACTION;
 SET @Id+=1;
END;
DROP TABLE #ZipInput,#ZipOutput,#Extracted,#BadOutput;
PRINT N'ZIP Writer SQL local/central contract PASS.';
