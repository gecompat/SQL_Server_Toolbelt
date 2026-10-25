SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52094,N'Markierter eigener frischer Split-Testscope erforderlich.',1;
IF USER_ID(N'ContosoSplitCaller') IS NOT NULL OR OBJECT_ID(N'tempdb..#RightsSplitResult') IS NOT NULL
 THROW 52094,N'Vorhandene Splitfixture wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,PermissionName varchar(16),SqlText nvarchar(max),Probe nvarchar(max));
INSERT @Apis VALUES
 (1,N'TVF_SplitAdvanced','SELECT',N'
  DECLARE @Rows table(Value nvarchar(max) NULL,Ordinal bigint NULL,IsValid bit NULL,ErrorCode varchar(64) NULL,ErrorPosition bigint NULL);
  DECLARE @ExpectedTokens int=3;
  INSERT @Rows SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N''a;"b;c";d'',N''[";"]'',DEFAULT,DEFAULT,DEFAULT);
  IF (SELECT COUNT(*) FROM @Rows)<>@ExpectedTokens
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Ordinal=1 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''a'') AND IsValid=1 AND ErrorCode IS NULL AND ErrorPosition IS NULL)
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Ordinal=2 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''"b;c"'') AND IsValid=1 AND ErrorCode IS NULL AND ErrorPosition IS NULL)
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Ordinal=3 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''d'') AND IsValid=1 AND ErrorCode IS NULL AND ErrorPosition IS NULL)
   THROW 52094,N''Split-Originaltoken-Festwerte verletzt.'',3;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_string.TVF_SplitAdvanced(NULL,NULL,NULL,NULL,NULL);
  IF EXISTS(SELECT 1 FROM @Rows) THROW 52094,N''Split-NULL-Prioritaet verletzt.'',4;
  INSERT @Rows SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N''a'',NULL,DEFAULT,DEFAULT,DEFAULT);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND Ordinal IS NULL AND IsValid=0 AND ErrorCode=''INVALID_CONFIGURATION'' AND ErrorPosition IS NULL)
   THROW 52094,N''Split-Konfigurationsfehler verletzt.'',5;',
  N'SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N''a;b'',N''[";"]'',DEFAULT,DEFAULT,DEFAULT);'),
 (2,N'TVF_UnquoteToken','SELECT',N'
  DECLARE @Rows table(Value nvarchar(max) NULL,IsValid bit NULL,ErrorCode varchar(64) NULL,ErrorPosition bigint NULL);
  INSERT @Rows SELECT * FROM toolbelt_string.TVF_UnquoteToken(N''[a]]b]'',DEFAULT,DEFAULT,DEFAULT);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''a]b'') AND IsValid=1 AND ErrorCode IS NULL AND ErrorPosition IS NULL)
   THROW 52094,N''Unquote-Festwert verletzt.'',6;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_string.TVF_UnquoteToken(NULL,N''xx'',NULL,NULL);
  IF EXISTS(SELECT 1 FROM @Rows) THROW 52094,N''Unquote-NULL-Prioritaet verletzt.'',7;
  INSERT @Rows SELECT * FROM toolbelt_string.TVF_UnquoteToken(N''a'',N''xx'',NULL,0);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND IsValid=0 AND ErrorCode=''INVALID_CONFIGURATION'' AND ErrorPosition IS NULL)
   THROW 52094,N''Unquote-Konfigurationsfehler verletzt.'',8;',
  N'SELECT * FROM toolbelt_string.TVF_UnquoteToken(N''[a]]b]'',DEFAULT,DEFAULT,DEFAULT);'),
 (3,N'USP_SplitAdvanced','EXECUTE',N'
  DECLARE @Rows table(Value nvarchar(max) NULL,Ordinal bigint NULL);
  IF @WithHelper=0
   INSERT @Rows EXEC toolbelt_string.USP_SplitAdvanced @Input=N''a;"b;c";d'',@SeparatorsJson=N''[";"]'';
  ELSE
  BEGIN
   CREATE TABLE #RightsSplitResult(Value nvarchar(max) NULL,Ordinal bigint NULL);
   EXEC toolbelt_string.USP_SplitAdvanced @Input=N''a;"b;c";d'',@SeparatorsJson=N''[";"]'',@ResultTable=N''#RightsSplitResult'';
   INSERT @Rows SELECT Value,Ordinal FROM #RightsSplitResult;
  END;
  IF (SELECT COUNT(*) FROM @Rows)<>3
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Ordinal=1 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''a''))
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Ordinal=2 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''"b;c"''))
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Ordinal=3 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''d''))
   THROW 52094,N''USP-Originaltoken-Festwerte verletzt.'',9;
  DELETE @Rows;
  IF @WithHelper=0
  BEGIN
   INSERT @Rows EXEC toolbelt_string.USP_SplitAdvanced @Input=NULL,@SeparatorsJson=NULL;
   IF EXISTS(SELECT 1 FROM @Rows) THROW 52094,N''USP-NULL-Prioritaet verletzt.'',10;
  END;
  ELSE
  BEGIN
   EXEC toolbelt_string.USP_SplitAdvanced @Input=NULL,@SeparatorsJson=NULL,@ResultTable=N''#RightsSplitResult'';
   IF (SELECT COUNT(*) FROM #RightsSplitResult)<>3 THROW 52094,N''USP-NULL veraenderte ResultTable.'',11;
  END;
  DECLARE @Caught bit=0,@Target sysname=CASE WHEN @WithHelper=1 THEN N''#RightsSplitResult'' ELSE NULL END;
  BEGIN TRY
   EXEC toolbelt_string.USP_SplitAdvanced @Input=N''a'',@SeparatorsJson=NULL,
    @ResultTable=@Target;
  END TRY
  BEGIN CATCH IF ERROR_NUMBER()<>51680 THROW; SET @Caught=1; SET @BusinessDenied+=1; END CATCH;
  IF @Caught=0 THROW 52094,N''USP-Konfigurationsfehler wurde zugelassen.'',12;
  IF @WithHelper=1
  BEGIN
   IF (SELECT COUNT(*) FROM #RightsSplitResult)<>3 THROW 52094,N''USP-Fehler veraenderte ResultTable.'',13;
   DROP TABLE #RightsSplitResult;
  END;',
  N'EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;');
DECLARE @Profile int=1,@Api int,@Phase int,@Other int,@Name sysname,@Permission varchar(16),@Sql nvarchar(max),@Grant nvarchar(max),@Probe nvarchar(max),
 @Caught bit,@Created bit=0,@Impersonated bit=0,@Positive int=0,@Denied int=0,@BusinessDenied int=0,@WithHelper bit;
BEGIN TRY
 CREATE USER ContosoSplitCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Profile<=4
 BEGIN
  SET @Api=CASE WHEN @Profile=4 THEN 3 ELSE @Profile END;
  SET @WithHelper=CASE WHEN @Profile=4 THEN 1 ELSE 0 END;
  SELECT @Name=Name,@Permission=PermissionName,@Sql=SqlText FROM @Apis WHERE Id=@Api;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT '+@Permission+N' ON OBJECT::toolbelt_string.'+QUOTENAME(@Name)+N' TO ContosoSplitCaller;'
    WHEN 2 THEN N'REVOKE '+@Permission+N' ON OBJECT::toolbelt_string.'+QUOTENAME(@Name)+N' FROM ContosoSplitCaller;' END;
   IF @Grant IS NOT NULL EXEC sys.sp_executesql @Grant;
   IF @WithHelper=1 AND @Phase=1 GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO ContosoSplitCaller;
   IF @WithHelper=1 AND @Phase=2 REVOKE EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable FROM ContosoSplitCaller;
   EXECUTE AS USER=N'ContosoSplitCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string',N'SCHEMA',N'SELECT'),0)<>0
    THROW 52094,N'Unerwartete breite Split-Callerrechte.',14;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string.'+Name,N'OBJECT',PermissionName),0)
    <>CASE WHEN @Phase=1 AND Id=@Api THEN 1 ELSE 0 END)
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.USP_PrepareResultTable',N'OBJECT',N'EXECUTE'),0)<>CASE WHEN @Phase=1 AND @WithHelper=1 THEN 1 ELSE 0 END
    THROW 52094,N'Nicht exakt die vorgesehenen Split-Objektrechte.',15;
   SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Sql,N'@WithHelper bit,@BusinessDenied int OUTPUT',@WithHelper,@BusinessDenied OUTPUT; END TRY
   BEGIN CATCH IF @Phase=1 OR ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
   IF @Phase<>1 AND @Caught=0 THROW 52094,N'Fehlendes Split-Recht wurde zugelassen.',16;
   IF @Phase=1
   BEGIN
    SET @Positive+=1; SET @Other=1;
    WHILE @Other<=4
    BEGIN
     IF @Other<>@Api AND NOT(@Other=4 AND @WithHelper=1)
     BEGIN
      SET @Probe=CASE WHEN @Other=4 THEN N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;' ELSE (SELECT Probe FROM @Apis WHERE Id=@Other) END;
      SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
      IF @Caught=0 THROW 52094,N'Fremdes Split-API oder Helper war zugaenglich.',17;
     END;
     SET @Other+=1;
    END;
   END;
   REVERT; SET @Impersonated=0; SET @Phase+=1;
  END;
  SET @Profile+=1;
 END;
 IF @Positive<>4 OR @Denied<>19 OR @BusinessDenied<>2 THROW 52094,N'Unvollstaendige Split-Probenzahl.',18;
 DROP USER ContosoSplitCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF XACT_STATE()<>0 ROLLBACK;
 IF @Created=1 DROP USER ContosoSplitCaller;
 THROW;
END CATCH;
IF USER_ID(N'ContosoSplitCaller') IS NOT NULL OR OBJECT_ID(N'tempdb..#RightsSplitResult') IS NOT NULL OR @@TRANCOUNT<>0
 THROW 52094,N'Eigene Splitfixture nicht entfernt.',19;
PRINT N'Split-Rechte: drei Einzelgrantprofile, ein separater Helperpfad,19 SQL229 und zwei SQL51680-Abweisungen; eigener Principal bereinigt.';
