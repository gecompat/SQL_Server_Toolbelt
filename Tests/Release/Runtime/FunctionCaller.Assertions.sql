IF (SELECT COUNT(*) FROM @Apis)<>@ExpectedApiCount OR @ExpectedApiCount<1
 OR (SELECT COUNT(*) FROM @Denied)<1
 OR EXISTS(SELECT 1 FROM @Apis WHERE PermissionName NOT IN('SELECT','EXECUTE') OR OracleSql IS NULL OR ProbeSql IS NULL)
 OR EXISTS(SELECT 1 FROM @Apis a WHERE OBJECT_ID(QUOTENAME(a.SchemaName)+N'.'+QUOTENAME(a.Name)) IS NULL)
 OR EXISTS(SELECT 1 FROM @Denied d WHERE OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.Name)) IS NULL)
 THROW 52097,N'Unvollstaendige feste Funktionsfixture.',3;
DECLARE @Schemas table(Name sysname PRIMARY KEY);
INSERT @Schemas SELECT SchemaName FROM @Apis UNION SELECT SchemaName FROM @Denied;
DECLARE @Api int=1,@Phase int,@Other int,@Name sysname,@Schema sysname,@Permission varchar(16),
 @Sql nvarchar(max),@Grant nvarchar(max),@Probe nvarchar(max),@Oracle nvarchar(max),
 @Created bit=0,@Impersonated bit=0,@Caught bit,@Positive int=0,@Rejections int=0;
BEGIN TRY
 CREATE USER ContosoFunctionCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Api<=@ExpectedApiCount
 BEGIN
  SELECT @Name=Name,@Schema=SchemaName,@Permission=PermissionName,@Probe=ProbeSql,@Oracle=OracleSql FROM @Apis WHERE Id=@Api;
  IF @Name IS NULL THROW 52097,N'Nicht fortlaufende API-Auswahl.',4;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT ' WHEN 2 THEN N'REVOKE ' END;
   IF @Grant IS NOT NULL
   BEGIN
    SET @Grant+=@Permission+N' ON OBJECT::'+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Name)
     +CASE @Phase WHEN 1 THEN N' TO ' ELSE N' FROM ' END+N'ContosoFunctionCaller;';
    EXEC sys.sp_executesql @Grant;
   END;
   EXECUTE AS USER=N'ContosoFunctionCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0
    OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0
    OR ISNULL(IS_MEMBER(N'db_securityadmin'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'SELECT'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'EXECUTE'),0)<>0
    OR EXISTS(SELECT 1 FROM @Schemas WHERE ISNULL(HAS_PERMS_BY_NAME(Name,N'SCHEMA',N'SELECT'),0)<>0
     OR ISNULL(HAS_PERMS_BY_NAME(Name,N'SCHEMA',N'EXECUTE'),0)<>0
     OR ISNULL(HAS_PERMS_BY_NAME(Name,N'SCHEMA',N'CONTROL'),0)<>0)
    THROW 52097,N'Unerwartete breite Funktions-Callerrechte.',5;
   IF EXISTS(SELECT 1 FROM @Apis WHERE
     ISNULL(HAS_PERMS_BY_NAME(QUOTENAME(SchemaName)+N'.'+QUOTENAME(Name),N'OBJECT',PermissionName),0)
     <>CASE WHEN @Phase=1 AND Id=@Api THEN 1 ELSE 0 END)
    OR EXISTS(SELECT 1 FROM @Denied WHERE
     ISNULL(HAS_PERMS_BY_NAME(QUOTENAME(SchemaName)+N'.'+QUOTENAME(Name),N'OBJECT',PermissionName),0)<>0)
    THROW 52097,N'Nicht exakt das einzelne Funktions-Objektrecht.',6;
   IF @Phase=1
   BEGIN
    EXEC sys.sp_executesql @Oracle; SET @Positive+=1;
    SET @Other=1;
    WHILE @Other<=@ExpectedApiCount
    BEGIN
     IF @Other<>@Api
     BEGIN
      SELECT @Sql=ProbeSql FROM @Apis WHERE Id=@Other;
      SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Rejections+=1; END CATCH;
      IF @Caught=0 THROW 52097,N'Anderes Funktions-API war zugaenglich.',7;
     END;
     SET @Other+=1;
    END;
    SET @Other=1;
    WHILE @Other<=(SELECT COUNT(*) FROM @Denied)
    BEGIN
     SELECT @Sql=ProbeSql FROM @Denied WHERE Id=@Other;
     SET @Caught=0;
     BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
     BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Rejections+=1; END CATCH;
     IF @Caught=0 THROW 52097,N'Nicht benoetigte Dependency oder Helper war zugaenglich.',8;
     SET @Other+=1;
    END;
   END ELSE
   BEGIN
    SET @Caught=0;
    BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY
    BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Rejections+=1; END CATCH;
    IF @Caught=0 THROW 52097,N'Fehlendes oder entzogenes Funktionsrecht wurde zugelassen.',9;
   END;
   REVERT; SET @Impersonated=0; SET @Phase+=1;
  END;
  SET @Api+=1;
 END;
 IF @Positive<>@ExpectedApiCount
  OR @Rejections<>@ExpectedApiCount*(@ExpectedApiCount+1+(SELECT COUNT(*) FROM @Denied))
  THROW 52097,N'Unvollstaendige Funktions-Probenzahl.',10;
 DROP USER ContosoFunctionCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoFunctionCaller;
 THROW;
END CATCH;
IF USER_ID(N'ContosoFunctionCaller') IS NOT NULL THROW 52097,N'Eigener Funktions-Principal nicht entfernt.',11;
PRINT N'Funktions-Callerprofile und strikte SQL229-Abweisungen bestanden; eigener Principal bereinigt.';
