SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52097,N'Markierter eigener frischer Deterministic-Testscope erforderlich.',1;
IF USER_ID(N'ContosoDeterministicCaller') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#RightsInput') IS NOT NULL OR OBJECT_ID(N'tempdb..#RightsPool') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#RightsResult') IS NOT NULL
 THROW 52097,N'Vorhandene Deterministicfixture wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,PermissionName varchar(16),SqlText nvarchar(max),Probe nvarchar(max));
INSERT @Apis VALUES
 (1,N'TVF_DeterministicRange','SELECT',N'
  DECLARE @Rows table(Value bigint NULL,ErrorCode int NULL);
  INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203,1,DEFAULT,-10,10);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value=-9 AND ErrorCode=0)
   THROW 52097,N''Range-Festwert verletzt.'',3;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(NULL,0,NULL,NULL,NULL);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=0)
   THROW 52097,N''Range-NULL-Prioritaet verletzt.'',4;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x01,0,0,-10,10);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=1)
   THROW 52097,N''Range-Konfigurationsfehler verletzt.'',5;',
  N'SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x01,1,0,0,1);'),
 (2,N'TVF_DeterministicDateShift','SELECT',N'
  DECLARE @Rows table(Value datetime2(7) NULL,ErrorCode int NULL);
  INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),''20260101''),0x010203,1,DEFAULT,0);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value=CONVERT(datetime2(7),''20260101'') AND ErrorCode=0)
   THROW 52097,N''DateShift-Festwert verletzt.'',6;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(NULL,NULL,0,NULL,NULL);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=0)
   THROW 52097,N''DateShift-NULL-Prioritaet verletzt.'',7;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),''20260101''),0x01,0,0,0);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=1)
   THROW 52097,N''DateShift-Konfigurationsfehler verletzt.'',8;',
  N'SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),''20260101''),0x01,1,0,0);'),
 (3,N'TVF_DeterministicTranslate','SELECT',N'
  DECLARE @Rows table(Value nvarchar(max) NULL,ErrorCode int NULL);
  INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N''aA0'',1,DEFAULT,DEFAULT,DEFAULT);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''sS6'') AND ErrorCode=0)
   THROW 52097,N''Translate-Festwert verletzt.'',9;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(NULL,0,NULL,NULL,NULL);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=0)
   THROW 52097,N''Translate-NULL-Prioritaet verletzt.'',10;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N''aA0'',0,0,N'''',N''standard'');
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=1)
   THROW 52097,N''Translate-Konfigurationsfehler verletzt.'',11;',
  N'SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N''aA0'',1,0,N'''',N''standard'');'),
 (4,N'TVF_DeterministicGeoJitter','SELECT',N'
  DECLARE @Rows table(Value geography NULL,ErrorCode int NULL);
  INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(0,0,4326),0x436f6e746f736f,1,0,100);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE ErrorCode=0 AND Value IS NOT NULL
   AND ABS(Value.Lat-0.000093295597217)<=1E-9 AND ABS(Value.Long-(-0.000851220857243))<=1E-9
   AND Value.STIsValid()=1 AND Value.STIsEmpty()=0 AND Value.STGeometryType()=N''Point'' AND Value.STSrid=4326
   AND Value.Z IS NULL AND Value.M IS NULL AND Value.STDistance(geography::Point(0,0,4326)) BETWEEN 0. AND 100.)
   THROW 52097,N''Geo-Festwert oder Distanznachbedingung verletzt.'',12;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(NULL,NULL,0,NULL,0);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=0)
   THROW 52097,N''Geo-NULL-Prioritaet verletzt.'',13;
  DELETE @Rows; INSERT @Rows SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(0,0,4326),0x01,0,0,100);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE Value IS NULL AND ErrorCode=1)
   THROW 52097,N''Geo-Konfigurationsfehler verletzt.'',14;',
  N'SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(0,0,4326),0x01,1,0,100);'),
 (5,N'USP_DeterministicLookup','EXECUTE',N'
  CREATE TABLE #RightsInput(Ordinal bigint NULL,[Key] varbinary(max) NULL);
  CREATE TABLE #RightsPool(Ordinal bigint NULL,Value nvarchar(max) NULL);
  INSERT #RightsInput VALUES(1,0x01),(2,NULL); INSERT #RightsPool VALUES(7,N''synthetic'');
  DECLARE @Rows table(InputOrdinal bigint NULL,LookupOrdinal bigint NULL,Value nvarchar(max) NULL);
  IF @WithHelper=0
   INSERT @Rows EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N''#RightsInput'',@LookupTable=N''#RightsPool'',@MappingVersion=1,@LookupVersion=1;
  ELSE
  BEGIN
   CREATE TABLE #RightsResult(InputOrdinal bigint NULL,LookupOrdinal bigint NULL,Value nvarchar(max) NULL);
   EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N''#RightsInput'',@LookupTable=N''#RightsPool'',@MappingVersion=1,@LookupVersion=1,@ResultTable=N''#RightsResult'';
   INSERT @Rows SELECT InputOrdinal,LookupOrdinal,Value FROM #RightsResult;
   DROP TABLE #RightsResult;
  END;
  IF (SELECT COUNT(*) FROM @Rows)<>2
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE InputOrdinal=1 AND LookupOrdinal=7 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N''synthetic''))
   OR NOT EXISTS(SELECT 1 FROM @Rows WHERE InputOrdinal=2 AND LookupOrdinal IS NULL AND Value IS NULL)
   THROW 52097,N''Lookup-Festwert oder NULL-Key verletzt.'',15;
  DROP TABLE #RightsInput; DROP TABLE #RightsPool;',
  N'EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;');
DECLARE @Profile int=1,@Api int,@Phase int,@Other int,@Name sysname,@Permission varchar(16),@Sql nvarchar(max),@Grant nvarchar(max),@Probe nvarchar(max),
 @Caught bit,@Created bit=0,@Impersonated bit=0,@Positive int=0,@Denied int=0,@WithHelper bit;
BEGIN TRY
 CREATE USER ContosoDeterministicCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Profile<=6
 BEGIN
  SET @Api=CASE WHEN @Profile=6 THEN 5 ELSE @Profile END;
  SET @WithHelper=CASE WHEN @Profile=6 THEN 1 ELSE 0 END;
  SELECT @Name=Name,@Permission=PermissionName,@Sql=SqlText FROM @Apis WHERE Id=@Api;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT '+@Permission+N' ON OBJECT::toolbelt_pseudonymization.'+QUOTENAME(@Name)+N' TO ContosoDeterministicCaller;'
    WHEN 2 THEN N'REVOKE '+@Permission+N' ON OBJECT::toolbelt_pseudonymization.'+QUOTENAME(@Name)+N' FROM ContosoDeterministicCaller;' END;
   IF @Grant IS NOT NULL EXEC sys.sp_executesql @Grant;
   IF @WithHelper=1 AND @Phase=1 GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO ContosoDeterministicCaller;
   IF @WithHelper=1 AND @Phase=2 REVOKE EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable FROM ContosoDeterministicCaller;
   EXECUTE AS USER=N'ContosoDeterministicCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_pseudonymization',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_pseudonymization',N'SCHEMA',N'SELECT'),0)<>0
    THROW 52097,N'Unerwartete breite Deterministic-Callerrechte.',16;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_pseudonymization.'+Name,N'OBJECT',PermissionName),0)
    <>CASE WHEN @Phase=1 AND Id=@Api THEN 1 ELSE 0 END)
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.USP_PrepareResultTable',N'OBJECT',N'EXECUTE'),0)<>CASE WHEN @Phase=1 AND @WithHelper=1 THEN 1 ELSE 0 END
    THROW 52097,N'Nicht exakt das vorgesehene Deterministic-Objektrecht.',17;
   SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Sql,N'@WithHelper bit',@WithHelper; END TRY
   BEGIN CATCH IF @Phase=1 OR ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
   IF @Phase<>1 AND @Caught=0 THROW 52097,N'Fehlendes Deterministic-Recht wurde zugelassen.',18;
   IF @Phase=1
   BEGIN
    SET @Positive+=1;
    SET @Other=1;
    WHILE @Other<=9
    BEGIN
     IF @Other<>@Api AND NOT(@Other=6 AND @WithHelper=1)
     BEGIN
      SET @Probe=CASE @Other WHEN 6 THEN N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;'
       WHEN 7 THEN N'SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicIntegerBytes(0);'
       WHEN 8 THEN N'SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRangeCore(0x0000000000000000,0,0x01,1,0,0,1);'
       WHEN 9 THEN N'EXEC toolbelt_pseudonymization.USP_DeterministicLookupCore @Hilfe=1;'
       ELSE (SELECT Probe FROM @Apis WHERE Id=@Other) END;
      SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
      IF @Caught=0 THROW 52097,N'Fremdes Deterministic-API oder interner Kern war zugaenglich.',19;
     END;
     SET @Other+=1;
    END;
   END;
   REVERT; SET @Impersonated=0; SET @Phase+=1;
  END;
  SET @Profile+=1;
 END;
 IF @Positive<>6 OR @Denied<>59 THROW 52097,N'Unvollstaendige Deterministic-Probenzahl.',20;
 DROP USER ContosoDeterministicCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF XACT_STATE()<>0 ROLLBACK;
 IF @Created=1 DROP USER ContosoDeterministicCaller;
 THROW;
END CATCH;
IF USER_ID(N'ContosoDeterministicCaller') IS NOT NULL OR @@TRANCOUNT<>0
 THROW 52097,N'Eigene Deterministicfixture nicht entfernt.',21;
PRINT N'Deterministic-Rechte: sechs API-Profile und 59 strikte SQL229-Abweisungen; eigener Principal bereinigt.';
