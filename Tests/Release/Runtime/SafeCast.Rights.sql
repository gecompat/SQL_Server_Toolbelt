SET NOCOUNT ON;
SET XACT_ABORT OFF;
-- Eigene markierte Testdatenbank; nur je ein SELECT auf eine der sechs TVFs.
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52097,N'Markierter eigener Safe-Cast-Testscope erforderlich.',1;
IF USER_ID(N'ContosoSafeCastCaller') IS NOT NULL
 THROW 52097,N'Vorhandener Safe-Cast-Principal wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,ValueType varchar(32),TextValue nvarchar(80),ExpectedValue nvarchar(80),
 SpecialInput nvarchar(80),SpecialStatus varchar(16),SpecialError varchar(32));
INSERT @Apis VALUES
 (1,N'TVF_TryCastBigInt','bigint',N'-9223372036854775808',N'-9223372036854775808',N'9223372036854775808','OUT_OF_RANGE','RANGE'),
 (2,N'TVF_TryCastDecimal','decimal(38,18)',N'123.000000000000000001',N'123.000000000000000001',N'1.0000000000000000001','LOSSY','SCALE'),
 (3,N'TVF_TryCastDate','date',N'2024-02-29',N'2024-02-29',N'2023-02-29','OUT_OF_RANGE','RANGE'),
 (4,N'TVF_TryCastDateTime2','datetime2(7)',N'2024-02-29T01:02:03.1234567',N'2024-02-29T01:02:03.1234567',N'2024-02-29T24:00:00','OUT_OF_RANGE','RANGE'),
 (5,N'TVF_TryCastBit','bit',N'1',N'1',N'2','INVALID_FORMAT','FORMAT'),
 (6,N'TVF_TryCastUniqueIdentifier','uniqueidentifier',N'11111111-2222-3333-4444-555555555555',N'11111111-2222-3333-4444-555555555555',N'{11111111-2222-3333-4444-555555555555}','INVALID_FORMAT','FORMAT');
DECLARE @Cases table(Id int PRIMARY KEY,TextValue nvarchar(80) NULL,Budget int NULL,ExpectedStatus varchar(16),ExpectedError varchar(32) NULL);
DECLARE @Call int=1,@Phase int,@Other int,@Probe int,@Name sysname,@ValueType varchar(32),@Text nvarchar(80),@Value nvarchar(80),
 @Special nvarchar(80),@Status varchar(16),@Error varchar(32),@Budget int,@Sql nvarchar(max),@Grant nvarchar(max),@DeniedSql nvarchar(max),
 @Caught bit,@Created bit=0,@Impersonated bit=0,@Positive int=0,@ValueCases int=0,@Denied int=0;
BEGIN TRY
 CREATE USER ContosoSafeCastCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Call<=6
 BEGIN
  SELECT @Name=Name,@ValueType=ValueType,@Text=TextValue,@Value=ExpectedValue,
   @Special=SpecialInput,@Status=SpecialStatus,@Error=SpecialError FROM @Apis WHERE Id=@Call;
  DELETE @Cases;
  INSERT @Cases VALUES(1,@Text,8192,'OK',NULL),(2,NULL,0,'SQL_NULL',NULL),(3,N'',8192,'EMPTY','EMPTY'),
   (4,N'x',8192,'INVALID_FORMAT','FORMAT'),(5,@Text,1,'LIMIT','INPUT_LIMIT'),
   (6,@Text,NULL,'INVALID_ARGUMENT','PARAMETER'),(7,@Special,8192,@Status,@Error);
  SET @Sql=N'DECLARE @Rows table(Value '+@ValueType+N' NULL,Status varchar(16) NULL,ErrorCode varchar(32) NULL);
   INSERT @Rows SELECT Value,Status,ErrorCode FROM toolbelt_conversion.'+QUOTENAME(@Name)+N'(@Text,@Budget);
   IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows
    WHERE Status COLLATE Latin1_General_100_BIN2=@Status
     AND (ErrorCode COLLATE Latin1_General_100_BIN2=@Error OR (ErrorCode IS NULL AND @Error IS NULL))
     AND ((@Status=''OK'' AND Value=CONVERT('+@ValueType+N',@Value)) OR (@Status<>''OK'' AND Value IS NULL)))
    THROW 52097,N''Safe-Cast-Wertorakel verletzt.'',3;';
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT SELECT ON OBJECT::toolbelt_conversion.'+QUOTENAME(@Name)+N' TO ContosoSafeCastCaller;'
    WHEN 2 THEN N'REVOKE SELECT ON OBJECT::toolbelt_conversion.'+QUOTENAME(@Name)+N' FROM ContosoSafeCastCaller;' END;
   IF @Grant IS NOT NULL EXEC sys.sp_executesql @Grant;
   EXECUTE AS USER=N'ContosoSafeCastCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_conversion',N'SCHEMA',N'SELECT'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_conversion',N'SCHEMA',N'EXECUTE'),0)<>0
    THROW 52097,N'Unerwartete breite Callerrechte.',4;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_conversion.'+Name,N'OBJECT',N'SELECT'),0)
    <>CASE WHEN @Phase=1 AND Id=@Call THEN 1 ELSE 0 END)
    THROW 52097,N'Nicht exakt das einzelne Safe-Cast-Objektrecht.',5;
   IF @Phase=1
   BEGIN
    SET @Probe=1;
    WHILE @Probe<=7
    BEGIN
     SELECT @Text=TextValue,@Budget=Budget,@Status=ExpectedStatus,@Error=ExpectedError FROM @Cases WHERE Id=@Probe;
     EXEC sys.sp_executesql @Sql,N'@Text nvarchar(80),@Budget int,@Value nvarchar(80),@Status varchar(16),@Error varchar(32)',@Text,@Budget,@Value,@Status,@Error;
     SET @ValueCases+=1; SET @Probe+=1;
    END;
    SET @Positive+=1; SET @Other=1;
    WHILE @Other<=6
    BEGIN
     IF @Other<>@Call
     BEGIN
      SELECT @DeniedSql=N'SELECT * FROM toolbelt_conversion.'+QUOTENAME(Name)+N'(N''0'',DEFAULT);' FROM @Apis WHERE Id=@Other;
      SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @DeniedSql; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
      IF @Caught=0 THROW 52097,N'Ein anderes Safe-Cast-API war zugaenglich.',6;
     END;
     SET @Other+=1;
    END;
   END ELSE
   BEGIN
    SET @Caught=0;SET @DeniedSql=N'SELECT * FROM toolbelt_conversion.'+QUOTENAME(@Name)+N'(N''0'',DEFAULT);';
    BEGIN TRY EXEC sys.sp_executesql @DeniedSql; END TRY
    BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
    IF @Caught=0 THROW 52097,N'Fehlendes oder entzogenes Safe-Cast-Recht wurde zugelassen.',7;
   END;
   REVERT; SET @Impersonated=0; SET @Phase+=1;
  END;
  SET @Call+=1;
 END;
 IF @Positive<>6 OR @ValueCases<>42 OR @Denied<>42 THROW 52097,N'Unvollstaendige Safe-Cast-Probenzahl.',8;
 DROP USER ContosoSafeCastCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoSafeCastCaller;
 THROW;
END CATCH;
IF USER_ID(N'ContosoSafeCastCaller') IS NOT NULL THROW 52097,N'Eigener Principal nicht entfernt.',9;
PRINT N'Safe-Cast-Rechte: sechs isolierte Profile,42 Wertfaelle und42 strikte SQL229-Abweisungen; eigener Principal bereinigt.';
