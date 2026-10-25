SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52097,N'Markierter eigener Funktions-Testscope erforderlich.',1;
IF USER_ID(N'ContosoFunctionCaller') IS NOT NULL
 THROW 52097,N'Vorhandener Funktions-Principal wird nicht uebernommen.',2;
-- Seven fixed permission states; no role, database or schema grant.
DECLARE @Phase int=0,@Impersonated bit=0,@Created bit=0,@Caught bit,
 @Expected int,@Rejections int=0,@Positive int=0;
DECLARE @Oracle nvarchar(max)=N'
CREATE TABLE #SchemaAnswer(RowKind varchar(8) NOT NULL,ErrorOrdinal int NOT NULL,Status varchar(24) NOT NULL,
 Profile varchar(32) NOT NULL,IsValid bit NULL,DocumentPointer nvarchar(max) NULL,SchemaPointer nvarchar(max) NULL,
 Keyword nvarchar(128) NULL,ErrorCode varchar(32) NULL,ErrorsTruncated bit NOT NULL);
CREATE TABLE #Destination(Sentinel int);
DECLARE @Cases table(Id int PRIMARY KEY,Json nvarchar(max),[Schema] nvarchar(max),Status varchar(24),IsValid bit,Code varchar(32));
INSERT @Cases VALUES(1,N''1'',N''true'',''VALID'',1,NULL),
 (2,N''1'',N''false'',''INVALID_INSTANCE'',0,''INSTANCE_VIOLATION''),
 (3,NULL,N''true'',''SQL_NULL'',NULL,''SQL_NULL''),
 (4,N''{'',N''true'',''INVALID_JSON'',NULL,''JSON_SYNTAX''),
 (5,N''1'',N''{'',''INVALID_SCHEMA'',NULL,''JSON_SYNTAX'');
DECLARE @Route int=0,@I int,@Json nvarchar(max),@Schema nvarchar(max),@Status varchar(24),@Valid bit,@Code varchar(32);
WHILE @Route<2
BEGIN
 SET @I=1;
 WHILE @I<=5
 BEGIN
  SELECT @Json=Json,@Schema=[Schema],@Status=Status,@Valid=IsValid,@Code=Code FROM @Cases WHERE Id=@I;
  DELETE #SchemaAnswer;
  IF @Route=0 INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=@Json,@Schema=@Schema;
  ELSE
  BEGIN
   EXEC toolbelt_json.USP_ValidateJsonSchema @Json=@Json,@Schema=@Schema,@ResultTable=N''#Destination'';
   EXEC sys.sp_executesql N''INSERT #SchemaAnswer SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated FROM #Destination;'';
  END;
  IF (SELECT COUNT(*) FROM #SchemaAnswer WHERE RowKind=''SUMMARY'' AND ErrorOrdinal=0)<>1
   OR NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE RowKind=''SUMMARY'' AND Status=@Status
    AND (IsValid=@Valid OR (IsValid IS NULL AND @Valid IS NULL))
    AND (ErrorCode=@Code OR (ErrorCode IS NULL AND @Code IS NULL)))
   OR EXISTS(SELECT 1 FROM #SchemaAnswer WHERE Status<>@Status OR Profile<>''toolbelt-2020-12-v1''
    OR ErrorsTruncated<>0 OR ErrorOrdinal NOT BETWEEN 0 AND 1
    OR (IsValid<>@Valid) OR (IsValid IS NULL AND @Valid IS NOT NULL) OR (IsValid IS NOT NULL AND @Valid IS NULL))
   OR (SELECT COUNT(*) FROM #SchemaAnswer) NOT BETWEEN 1 AND 2
   THROW 52097,N''Fixed JSON Schema status/value/NULL/shape oracle.'',12;
  SET @I+=1;
 END;
 SET @Route+=1;
END;';
BEGIN TRY
 CREATE USER ContosoFunctionCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Phase<=6
 BEGIN
  IF @Phase=1 GRANT EXECUTE ON OBJECT::toolbelt_json.USP_ValidateJsonSchema TO ContosoFunctionCaller;
  IF @Phase IN(2,5) GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO ContosoFunctionCaller;
  IF @Phase=3 GRANT SELECT ON OBJECT::toolbelt_json.FT_ValidateJsonSchemaInternal TO ContosoFunctionCaller;
  IF @Phase=4 REVOKE EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable FROM ContosoFunctionCaller;
  IF @Phase=5 REVOKE SELECT ON OBJECT::toolbelt_json.FT_ValidateJsonSchemaInternal FROM ContosoFunctionCaller;
  IF @Phase=6 REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_ValidateJsonSchema FROM ContosoFunctionCaller;
  EXECUTE AS USER=N'ContosoFunctionCaller'; SET @Impersonated=1;
  IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0
   OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0
   OR ISNULL(IS_MEMBER(N'db_securityadmin'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
   THROW 52097,N'Broad JSON Schema caller rights.',5;
  IF ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json.USP_ValidateJsonSchema',N'OBJECT',N'EXECUTE'),0)
    <>CASE WHEN @Phase BETWEEN 1 AND 5 THEN 1 ELSE 0 END
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.USP_PrepareResultTable',N'OBJECT',N'EXECUTE'),0)
    <>CASE WHEN @Phase IN(2,3,5,6) THEN 1 ELSE 0 END
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json.FT_ValidateJsonSchemaInternal',N'OBJECT',N'SELECT'),0)
    <>CASE WHEN @Phase IN(3,4) THEN 1 ELSE 0 END
   THROW 52097,N'Exact JSON Schema caller rights drift.',6;
  IF @Phase=3
  BEGIN EXEC sys.sp_executesql @Oracle; SET @Positive+=1; END
  ELSE
  BEGIN
   SET @Expected=CASE WHEN @Phase IN(1,4) THEN 55601 ELSE 229 END;
   SET @Caught=0;
   BEGIN TRY EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true'; END TRY
   BEGIN CATCH IF ERROR_NUMBER()<>@Expected THROW; SET @Caught=1; SET @Rejections+=1; END CATCH;
   IF @Caught=0 THROW 52097,N'Missing JSON Schema object permission was accepted.',7;
  END;
  REVERT; SET @Impersonated=0; SET @Phase+=1;
 END;
 IF @Positive<>1 OR @Rejections<>6 THROW 52097,N'Incomplete JSON Schema permission sequence.',8;
 DROP USER ContosoFunctionCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoFunctionCaller;
 THROW;
END CATCH;
IF USER_ID(N'ContosoFunctionCaller') IS NOT NULL OR @@TRANCOUNT<>0
 THROW 52097,N'JSON Schema fixture cleanup incomplete.',9;
