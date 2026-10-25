SET NOCOUNT ON;
SET XACT_ABORT OFF;
-- Nur in einer eigenen markierten Qualifikationsdatenbank ausfuehren.
-- Sechs APIs, getrennte Handler-/Policyrechte und kein Rollen-/Schemagrant.
DECLARE @FixtureOwner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value)
 FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner');
IF @FixtureOwner IS NULL OR LEN(@FixtureOwner)<>32
 OR @FixtureOwner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@FixtureOwner+N'_l',N'Toolbelt_Release_'+@FixtureOwner+N'_c')
 THROW 52096,N'Markierte eigene Qualifikationsdatenbank erforderlich.',12;
IF USER_ID(N'ContosoWorkTypeCaller') IS NOT NULL
 OR OBJECT_ID(N'dbo.USP_ContosoWorkTypeRightsHandler') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName LIKE 'contoso.rights.%')
 THROW 52096,N'Vorhandene Rechtefixture wird nicht uebernommen.',1;
IF @@TRANCOUNT<>0 THROW 52096,N'Frische Testsession erforderlich.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,PermissionName varchar(16));
INSERT @Apis VALUES
 (1,N'USP_RegisterWorkType','EXECUTE'),(2,N'USP_DisableWorkType','EXECUTE'),
 (3,N'USP_RemoveWorkType','EXECUTE'),(4,N'USP_ResolveWorkType','EXECUTE'),
 (5,N'VW_WorkTypes','SELECT'),(6,N'USP_SetWorkTypePermission','EXECUTE');
DECLARE @Shape nvarchar(max)=N'DECLARE @Rows table(
 WorkTypeId bigint NULL,WorkTypeName varchar(128) NULL,HandlerSchema sysname NULL,HandlerProcedure sysname NULL,
 HandlerQualifiedName nvarchar(517) NULL,ParameterMode varchar(16) NULL,PayloadContractJson nvarchar(4000) NULL,
 DefaultTimeoutSeconds int NULL,IsIdempotent bit NULL,IsEnabled bit NULL,Description nvarchar(1000) NULL,
 CreatedAtUtc datetime2(7) NULL,CreatedBy sysname NULL,ModifiedAtUtc datetime2(7) NULL,ModifiedBy sysname NULL,
 DisabledAtUtc datetime2(7) NULL,DisabledBy sysname NULL,DisabledReason nvarchar(1000) NULL,RowVersion binary(8) NULL,HandlerExists bit NULL);';
DECLARE @Call int=1,@Phase int,@Other int,@Name sysname,@Permission varchar(16),
 @Sql nvarchar(max),@Grant nvarchar(max),@Probe nvarchar(max),@Caught bit,@Expected int,
 @Positive int=0,@Denied int=0,@Created bit=0,@Handler bit=0,@Impersonated bit=0;
BEGIN TRY
 EXEC(N'CREATE PROCEDURE dbo.USP_ContosoWorkTypeRightsHandler AS RETURN 0;'); SET @Handler=1;
 CREATE USER ContosoWorkTypeCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Call<=6
 BEGIN
  SELECT @Name=Name,@Permission=PermissionName FROM @Apis WHERE Id=@Call;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   DELETE toolbelt_core.WorkType WHERE WorkTypeName LIKE 'contoso.rights.%';
   EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='contoso.rights.seed',
    @HandlerSchema=N'dbo',@HandlerProcedure=N'USP_ContosoWorkTypeRightsHandler',
    @DefaultTimeoutSeconds=45,@Description=N'Contoso rights fixture';
   IF @Call=3 EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='contoso.rights.seed';
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT '+@Permission+N' ON OBJECT::toolbelt_core.'+QUOTENAME(@Name)+N' TO ContosoWorkTypeCaller;'
    WHEN 2 THEN N'REVOKE '+@Permission+N' ON OBJECT::toolbelt_core.'+QUOTENAME(@Name)+N' FROM ContosoWorkTypeCaller;' END;
   IF @Grant IS NOT NULL EXEC sys.sp_executesql @Grant;
   -- Sichtbarkeit allein ersetzt weder Handlerausfuehrung noch Policyverwaltung.
   IF @Phase=1 AND @Call IN(1,4) GRANT VIEW DEFINITION ON OBJECT::dbo.USP_ContosoWorkTypeRightsHandler TO ContosoWorkTypeCaller;
   SET @Sql=CASE @Call
    WHEN 1 THEN @Shape+N'INSERT @Rows EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName=''contoso.rights.new'',@HandlerSchema=N''dbo'',@HandlerProcedure=N''USP_ContosoWorkTypeRightsHandler'',@DefaultTimeoutSeconds=45,@Description=N''Contoso rights fixture'';'
    WHEN 2 THEN @Shape+N'INSERT @Rows EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName=''contoso.rights.seed'';'
    WHEN 3 THEN @Shape+N'INSERT @Rows EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName=''contoso.rights.seed'',@AllowDelete=1;'
    WHEN 4 THEN @Shape+N'INSERT @Rows EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName=''contoso.rights.seed'';'
    WHEN 5 THEN @Shape+N'INSERT @Rows SELECT * FROM toolbelt_core.VW_WorkTypes WHERE WorkTypeName=''contoso.rights.seed'';'
    ELSE N'EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName=''contoso.rights.seed'',@Principal=N''ContosoWorkTypeCaller'',@PermissionName=''ENQUEUE'';'
   END;
   IF @Call<6 SET @Sql+=N'
    IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows
     WHERE WorkTypeName='''+CASE WHEN @Call=1 THEN N'contoso.rights.new' ELSE N'contoso.rights.seed' END+N'''
      AND HandlerSchema=N''dbo'' AND HandlerProcedure=N''USP_ContosoWorkTypeRightsHandler''
      AND HandlerQualifiedName=N''[dbo].[USP_ContosoWorkTypeRightsHandler]''
      AND ParameterMode=''NONE'' AND DefaultTimeoutSeconds=45 AND IsIdempotent=0
      AND IsEnabled='+CASE WHEN @Call IN(2,3) THEN N'0' ELSE N'1' END+N'
      AND Description=N''Contoso rights fixture'' AND WorkTypeId>0 AND RowVersion IS NOT NULL)
     THROW 52096,N''Work-Type-Wertorakel verletzt.'',3;';
   IF @Phase=1 AND @Call IN(1,4,6)
   BEGIN
    SET @Expected=CASE @Call WHEN 1 THEN 51509 WHEN 4 THEN 51534 ELSE 51591 END;
    EXECUTE AS USER=N'ContosoWorkTypeCaller'; SET @Impersonated=1; SET @Caught=0;
    BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
    BEGIN CATCH IF ERROR_NUMBER()<>@Expected THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
    IF @Caught=0 THROW 52096,N'Zusaetzliches Handler-/Policyrecht wurde nicht verlangt.',4;
    REVERT; SET @Impersonated=0;
    IF @Call IN(1,4) GRANT EXECUTE ON OBJECT::dbo.USP_ContosoWorkTypeRightsHandler TO ContosoWorkTypeCaller;
    ELSE GRANT CONTROL ON OBJECT::toolbelt_core.WorkTypePermission TO ContosoWorkTypeCaller;
   END;
   IF @Phase=2
   BEGIN
    IF @Call IN(1,4)
    BEGIN
     REVOKE EXECUTE ON OBJECT::dbo.USP_ContosoWorkTypeRightsHandler FROM ContosoWorkTypeCaller;
     REVOKE VIEW DEFINITION ON OBJECT::dbo.USP_ContosoWorkTypeRightsHandler FROM ContosoWorkTypeCaller;
    END;
    IF @Call=6 REVOKE CONTROL ON OBJECT::toolbelt_core.WorkTypePermission FROM ContosoWorkTypeCaller;
   END;
   EXECUTE AS USER=N'ContosoWorkTypeCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
    THROW 52096,N'Unerwartetes Rollen-, Datenbank- oder Schemarecht.',5;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.'+Name,N'OBJECT',PermissionName),0)
    <>CASE WHEN @Phase=1 AND Id=@Call THEN 1 ELSE 0 END)
    THROW 52096,N'Nicht exakt das vorgesehene oeffentliche Objektrecht.',6;
   SET @Expected=CASE WHEN @Phase=1 THEN 0 ELSE 229 END; SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
   BEGIN CATCH IF @Expected=0 OR ERROR_NUMBER()<>@Expected THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
   IF @Expected<>0 AND @Caught=0 THROW 52096,N'Fehlendes Objektrecht wurde nicht abgewiesen.',7;
   IF @Phase=1
   BEGIN
    SET @Positive+=1; SET @Other=1;
    WHILE @Other<=8
    BEGIN
     IF @Other<>@Call
     BEGIN
      SET @Probe=CASE @Other
       WHEN 5 THEN N'SELECT TOP(0) * FROM toolbelt_core.VW_WorkTypes;'
       WHEN 7 THEN N'SELECT TOP(0) * FROM toolbelt_core.WorkType;'
       WHEN 8 THEN N'UPDATE toolbelt_core.WorkType SET Description=Description WHERE 1=0;'
       ELSE (SELECT N'EXEC toolbelt_core.'+QUOTENAME(Name)+N' @Hilfe=1;' FROM @Apis WHERE Id=@Other) END;
      SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
      IF @Caught=0 THROW 52096,N'Fremdes API oder interne Tabelle war zugaenglich.',8;
     END;
     SET @Other+=1;
    END;
   END;
   REVERT; SET @Impersonated=0;
   IF @Phase=1 AND @Call=6 AND (SELECT COUNT(*) FROM toolbelt_core.WorkTypePermission
    WHERE PrincipalId=USER_ID(N'ContosoWorkTypeCaller') AND PermissionName='ENQUEUE' AND IsDenied=0)<>1
    THROW 52096,N'Policy-Wertorakel verletzt.',9;
   SET @Phase+=1;
  END;
  SET @Call+=1;
 END;
 IF @Positive<>6 OR @Denied<>57 THROW 52096,N'Unvollstaendige Rechte-Probenzahl.',10;
 DELETE toolbelt_core.WorkType WHERE WorkTypeName LIKE 'contoso.rights.%';
 DROP USER ContosoWorkTypeCaller; SET @Created=0;
 DROP PROCEDURE dbo.USP_ContosoWorkTypeRightsHandler; SET @Handler=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF XACT_STATE()<>0 ROLLBACK;
 DELETE toolbelt_core.WorkType WHERE WorkTypeName LIKE 'contoso.rights.%';
 IF @Created=1 DROP USER ContosoWorkTypeCaller;
 IF @Handler=1 DROP PROCEDURE dbo.USP_ContosoWorkTypeRightsHandler;
 THROW;
END CATCH;
IF USER_ID(N'ContosoWorkTypeCaller') IS NOT NULL OR OBJECT_ID(N'dbo.USP_ContosoWorkTypeRightsHandler') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName LIKE 'contoso.rights.%')
 THROW 52096,N'Eigene Rechtefixture nicht vollstaendig entfernt.',11;
PRINT N'Work-Type-Rechte: sechs positive Profile und 57 strikte Abweisungen; eigene Fixture bereinigt.';
