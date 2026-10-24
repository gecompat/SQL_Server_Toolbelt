SET NOCOUNT ON;
SET XACT_ABORT OFF;

-- Nur eine eigene disposable Qualifikationsdatenbank und diese frische Session.
-- Jeweils genau ein oeffentliches Objektrecht, keine Rollen-/Schemagrants.
IF USER_ID(N'ContosoContextCaller') IS NOT NULL
 THROW 52095,N'Vorhandener Testprincipal wird nicht uebernommen.',1;
IF SESSION_CONTEXT(N'toolbelt.execution.id') IS NOT NULL
 OR SESSION_CONTEXT(N'toolbelt.execution.correlation_id') IS NOT NULL
 OR SESSION_CONTEXT(N'toolbelt.execution.actor') IS NOT NULL
 OR SESSION_CONTEXT(N'toolbelt.execution.tenant') IS NOT NULL
 OR SESSION_CONTEXT(N'toolbelt.execution.started_at_utc') IS NOT NULL
 OR SESSION_CONTEXT(N'toolbelt.execution.depth') IS NOT NULL
 THROW 52095,N'Vorhandener Sessioncontext wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,PermissionName varchar(16),SqlText nvarchar(max));
INSERT @Apis VALUES
(1,N'USP_BeginExecution','EXECUTE',N'
 DECLARE @Id uniqueidentifier=''11111111-1111-1111-1111-111111111111'',@Rc int;
 EXEC @Rc=toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,
  @CorrelationId=''22222222-2222-2222-2222-222222222222'',@Actor=N''Contoso'',@Tenant=N''Fabrikam'';
 IF @Rc<>0 OR @Id<>''11111111-1111-1111-1111-111111111111''
  OR ISNULL(CONVERT(nvarchar(36),SESSION_CONTEXT(N''toolbelt.execution.id'')),N'''')<>CONVERT(nvarchar(36),@Id)
  OR ISNULL(CONVERT(nvarchar(36),SESSION_CONTEXT(N''toolbelt.execution.correlation_id'')),N'''')<>N''22222222-2222-2222-2222-222222222222''
  OR ISNULL(CONVERT(nvarchar(256),SESSION_CONTEXT(N''toolbelt.execution.actor'')),N'''') COLLATE Latin1_General_100_BIN2<>N''Contoso''
  OR ISNULL(CONVERT(nvarchar(256),SESSION_CONTEXT(N''toolbelt.execution.tenant'')),N'''') COLLATE Latin1_General_100_BIN2<>N''Fabrikam''
  OR ISNULL(TRY_CONVERT(int,SESSION_CONTEXT(N''toolbelt.execution.depth'')),-1)<>1
  OR TRY_CONVERT(datetime2(7),CONVERT(nvarchar(33),SESSION_CONTEXT(N''toolbelt.execution.started_at_utc'')),126) IS NULL
  THROW 52095,N''Begin-Wertorakel verletzt.'',3;
 SET @Id=NULL;
 EXEC @Rc=toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;
 IF @Rc<>0 OR @Id IS NULL OR @Id<>''11111111-1111-1111-1111-111111111111''
  OR ISNULL(TRY_CONVERT(int,SESSION_CONTEXT(N''toolbelt.execution.depth'')),-1)<>2
  THROW 52095,N''Nested-Begin-Wertorakel verletzt.'',4;'),
(2,N'USP_SetExecutionContext','EXECUTE',N'
 DECLARE @Rc int;
 EXEC @Rc=toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=''11111111-1111-1111-1111-111111111111'',
  @CorrelationId=''33333333-3333-3333-3333-333333333333'',@Actor=N''Contoso'',@Tenant=N''Fabrikam'';
 IF @Rc<>0 OR ISNULL(CONVERT(nvarchar(36),SESSION_CONTEXT(N''toolbelt.execution.correlation_id'')),N'''')<>N''33333333-3333-3333-3333-333333333333''
  OR ISNULL(CONVERT(nvarchar(256),SESSION_CONTEXT(N''toolbelt.execution.actor'')),N'''') COLLATE Latin1_General_100_BIN2<>N''Contoso''
  OR ISNULL(CONVERT(nvarchar(256),SESSION_CONTEXT(N''toolbelt.execution.tenant'')),N'''') COLLATE Latin1_General_100_BIN2<>N''Fabrikam''
  THROW 52095,N''Set-Wertorakel verletzt.'',5;
 EXEC @Rc=toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=''11111111-1111-1111-1111-111111111111'',@ClearActor=1,@ClearTenant=1;
 IF @Rc<>0 OR SESSION_CONTEXT(N''toolbelt.execution.actor'') IS NOT NULL OR SESSION_CONTEXT(N''toolbelt.execution.tenant'') IS NOT NULL
  THROW 52095,N''Clear-Wertorakel verletzt.'',6;'),
(3,N'USP_EndExecution','EXECUTE',N'
 DECLARE @Rc int;
 EXEC @Rc=toolbelt_core.USP_EndExecution @ExpectedExecutionId=''11111111-1111-1111-1111-111111111111'';
 IF @Rc<>0 OR ISNULL(TRY_CONVERT(int,SESSION_CONTEXT(N''toolbelt.execution.depth'')),-1)<>1
  OR ISNULL(CONVERT(nvarchar(36),SESSION_CONTEXT(N''toolbelt.execution.id'')),N'''')<>N''11111111-1111-1111-1111-111111111111''
  THROW 52095,N''End-Depth-Wertorakel verletzt.'',7;
 EXEC @Rc=toolbelt_core.USP_EndExecution @ExpectedExecutionId=''11111111-1111-1111-1111-111111111111'';
 IF @Rc<>0 OR SESSION_CONTEXT(N''toolbelt.execution.id'') IS NOT NULL OR SESSION_CONTEXT(N''toolbelt.execution.correlation_id'') IS NOT NULL
  OR SESSION_CONTEXT(N''toolbelt.execution.actor'') IS NOT NULL OR SESSION_CONTEXT(N''toolbelt.execution.tenant'') IS NOT NULL
  OR SESSION_CONTEXT(N''toolbelt.execution.started_at_utc'') IS NOT NULL OR SESSION_CONTEXT(N''toolbelt.execution.depth'') IS NOT NULL
  THROW 52095,N''End-Cleanup-Wertorakel verletzt.'',8;'),
(4,N'TVF_CurrentExecutionContext','SELECT',N'
 DECLARE @Rows table(ExecutionId uniqueidentifier,CorrelationId uniqueidentifier,Actor nvarchar(256),Tenant nvarchar(256),StartedAtUtc datetime2(7),ScopeDepth int);
 INSERT @Rows SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
 IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows
  WHERE ExecutionId=''11111111-1111-1111-1111-111111111111'' AND CorrelationId=''22222222-2222-2222-2222-222222222222''
   AND Actor COLLATE Latin1_General_100_BIN2=N''SeedActor'' AND Tenant COLLATE Latin1_General_100_BIN2=N''SeedTenant''
   AND StartedAtUtc=CONVERT(datetime2(7),''2026-01-01T00:00:00.0000000'',126) AND ScopeDepth=1)
  THROW 52095,N''TVF-Wertorakel verletzt.'',9;
 EXEC sys.sp_set_session_context @key=N''toolbelt.execution.id'',@value=NULL;
 IF EXISTS(SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext())
  THROW 52095,N''Leerer TVF-Context wurde nicht erhalten.'',10;'),
(5,N'SVF_CurrentExecutionId','EXECUTE',N'
 DECLARE @Got uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
 IF @Got IS NULL OR @Got<>''11111111-1111-1111-1111-111111111111''
  THROW 52095,N''SVF-Wertorakel verletzt.'',11;
 EXEC sys.sp_set_session_context @key=N''toolbelt.execution.id'',@value=NULL;
 SET @Got=toolbelt_core.SVF_CurrentExecutionId();
 IF @Got IS NOT NULL THROW 52095,N''Leerer SVF-Context wurde nicht erhalten.'',12;');

DECLARE @Keys table(Id int PRIMARY KEY,Name sysname);
INSERT @Keys VALUES(1,N'toolbelt.execution.id'),(2,N'toolbelt.execution.correlation_id'),
 (3,N'toolbelt.execution.actor'),(4,N'toolbelt.execution.tenant'),
 (5,N'toolbelt.execution.started_at_utc'),(6,N'toolbelt.execution.depth');
DECLARE @Created bit=0,@Impersonated bit=0,@Phase int,@Call int=1,@Other int,
 @Sql nvarchar(max),@GrantSql nvarchar(max),@Name sysname,@Permission varchar(16),
 @Caught bit,@ExpectedError int,@Depth int,@KeyIndex int,@Key sysname,
 @Positive int=0,@Denied int=0;
BEGIN TRY
 CREATE USER ContosoContextCaller WITHOUT LOGIN;
 SET @Created=1;
 WHILE @Call<=5
 BEGIN
  SELECT @Name=Name,@Permission=PermissionName FROM @Apis WHERE Id=@Call;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   SET @GrantSql=CASE @Phase WHEN 1 THEN N'GRANT '+@Permission+N' ON OBJECT::toolbelt_core.'+QUOTENAME(@Name)+N' TO ContosoContextCaller;'
    WHEN 2 THEN N'REVOKE '+@Permission+N' ON OBJECT::toolbelt_core.'+QUOTENAME(@Name)+N' FROM ContosoContextCaller;' END;
   IF @GrantSql IS NOT NULL EXEC sys.sp_executesql @GrantSql;
   -- Nur die eigenen zuvor leeren sechs Sessionkeys vorbereiten.
   SET @KeyIndex=1;
   WHILE @KeyIndex<=6
   BEGIN
    SELECT @Key=Name FROM @Keys WHERE Id=@KeyIndex;
    EXEC sys.sp_set_session_context @key=@Key,@value=NULL;
    SET @KeyIndex+=1;
   END;
   IF @Call<>1
   BEGIN
    SET @Depth=CASE WHEN @Call=3 THEN 2 ELSE 1 END;
    EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id',@value=N'11111111-1111-1111-1111-111111111111';
    EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id',@value=N'22222222-2222-2222-2222-222222222222';
    EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor',@value=N'SeedActor';
    EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant',@value=N'SeedTenant';
    EXEC sys.sp_set_session_context @key=N'toolbelt.execution.started_at_utc',@value=N'2026-01-01T00:00:00.0000000';
    EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth',@value=@Depth;
   END;
   SELECT @Sql=SqlText FROM @Apis WHERE Id=@Call;
   SET @ExpectedError=CASE WHEN @Phase=1 THEN 0 ELSE 229 END;
   SET @Caught=0;
   EXECUTE AS USER=N'ContosoContextCaller';
   SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
    THROW 52095,N'Unerwartete Rollen-, Datenbank- oder Schemarechte.',13;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.'+Name,N'OBJECT',PermissionName),0)
    <>CASE WHEN @Phase=1 AND Id=@Call THEN 1 ELSE 0 END)
    THROW 52095,N'Nicht exakt das einzelne vorgesehene Objektrecht.',14;
   BEGIN TRY
    EXEC sys.sp_executesql @Sql;
   END TRY
   BEGIN CATCH
    IF @ExpectedError=0 OR ERROR_NUMBER()<>@ExpectedError THROW;
    SET @Caught=1; SET @Denied+=1;
   END CATCH;
   IF @ExpectedError<>0 AND @Caught=0 THROW 52095,N'Fehlendes Objektrecht wurde nicht abgewiesen.',15;
   IF @Phase=1
   BEGIN
    SET @Positive+=1; SET @Other=1;
    WHILE @Other<=5
    BEGIN
     IF @Other<>@Call
     BEGIN
      SELECT @Sql=SqlText FROM @Apis WHERE Id=@Other;
      SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
      BEGIN CATCH
       IF ERROR_NUMBER()<>229 THROW;
       SET @Caught=1; SET @Denied+=1;
      END CATCH;
      IF @Caught=0 THROW 52095,N'Ein anderes API wurde mit fremdem Objektrecht zugelassen.',16;
     END;
     SET @Other+=1;
    END;
   END;
   REVERT; SET @Impersonated=0;
   SET @Phase+=1;
  END;
  SET @Call+=1;
 END;
 IF @Positive<>5 OR @Denied<>30 THROW 52095,N'Unvollstaendige Rechte-Probenzahl.',17;
 SET @KeyIndex=1;
 WHILE @KeyIndex<=6
 BEGIN
  SELECT @Key=Name FROM @Keys WHERE Id=@KeyIndex;
  EXEC sys.sp_set_session_context @key=@Key,@value=NULL;
  SET @KeyIndex+=1;
 END;
 DROP USER ContosoContextCaller; SET @Created=0;
 IF USER_ID(N'ContosoContextCaller') IS NOT NULL OR EXISTS(SELECT 1 FROM @Keys WHERE SESSION_CONTEXT(Name) IS NOT NULL)
  THROW 52095,N'Eigener Principal oder Sessioncontext wurde nicht entfernt.',18;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 SET @KeyIndex=1;
 WHILE @KeyIndex<=6
 BEGIN
  SELECT @Key=Name FROM @Keys WHERE Id=@KeyIndex;
  EXEC sys.sp_set_session_context @key=@Key,@value=NULL;
  SET @KeyIndex+=1;
 END;
 IF @Created=1 DROP USER ContosoContextCaller;
 THROW;
END CATCH;
PRINT N'Execution-Context-Rechte: fuenf isolierte positive API-Proben und dreissig strikte SQL229-Abweisungen; eigener Principal und Sessioncontext bereinigt.';
