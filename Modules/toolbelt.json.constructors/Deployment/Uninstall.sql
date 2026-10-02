:On Error exit
-- Historischer/aktueller Uninstall entfernt ausschließlich kohärent eigene Slots.
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'JSON_LIFECYCLE_CALLER_TRANSACTION: aktive Callertransaktion ist ausgeschlossen.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Confirmation nvarchar(max)=N'$(ConfirmNoExternalConsumers)',@Version nvarchar(max),@Mode nvarchar(max),
 @Registered bit,@ModeRegistered bit,@Pass int=0,@Count int,@SchemaId int,@LockResult int,
 @InitialVersion varbinary(max),@InitialMode varbinary(max),@InitialSchemaId int,@Id int,@Name sysname,@Sql nvarchar(max);
DECLARE @Slots TABLE(Id int PRIMARY KEY,Name sysname COLLATE DATABASE_DEFAULT NOT NULL,ObjectId int NULL);
INSERT @Slots VALUES(1,N'USP_JsonConstructInternal',NULL),(2,N'USP_JsonArray',NULL),(3,N'USP_JsonObject',NULL),
 (4,N'USP_JsonArraysByGroup',NULL),(5,N'USP_JsonObjectsByGroup',NULL);
IF CONVERT(varbinary(max),@Confirmation) NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
 THROW 53625,N'JSON lifecycle: Consumer-Bestätigung ist ungültig.',1;
BEGIN TRY
 WHILE @Pass<2
 BEGIN
  IF COALESCE(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
   THROW 53620,N'JSON lifecycle: SQL-Version wird nicht unterstützt.',1;
  IF COALESCE((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
   THROW 53629,N'JSON lifecycle: Compatibility Level wird nicht unterstützt.',1;
  SELECT @Version=NULL,@Mode=NULL,@Registered=0,@ModeRegistered=0,@SchemaId=SCHEMA_ID(N'toolbelt_json');
  SELECT @Registered=1,@Version=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version';
  SELECT @ModeRegistered=1,@Mode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';
  IF @Pass=1 AND(@Registered=0 OR COALESCE(CONVERT(varbinary(max),@Version),0x)<>@InitialVersion
   OR COALESCE(CONVERT(varbinary(max),@Mode),0x)<>@InitialMode OR COALESCE(@SchemaId,-1)<>@InitialSchemaId)
   THROW 53627,N'JSON lifecycle: Zustand hat sich unter Lock verändert.',1;
  IF @Registered=0 AND @ModeRegistered=0 RETURN;
  IF @Registered=0 OR @ModeRegistered=0 OR @SchemaId IS NULL OR @Version IS NULL OR @Mode IS NULL
   OR CONVERT(varbinary(max),@Version) NOT IN(CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0'))
   OR CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
  BEGIN
   IF @Pass=1 THROW 53627,N'JSON lifecycle: Releasezustand unter Lock ist inkohärent.',1;
   THROW 53623,N'JSON lifecycle: Releasezustand ist unbekannt oder inkohärent.',1;
  END;
  IF CONVERT(varbinary(max),@Mode)=CONVERT(varbinary(max),N'central') AND @Confirmation=N'0'
   THROW 53625,N'JSON lifecycle: zentrale Consumer-Bestätigung fehlt.',1;
  -- Vor der Dependencyabfrage, im Preflight und erneut unter derselben AppLock.
  IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
   OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
   THROW 53622,N'JSON lifecycle: erforderliche Metadatenrechte für Uninstall fehlen.',1;
  IF COALESCE(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'ALTER'),0)<>1
   THROW 53622,N'JSON lifecycle: erforderliche Uninstallrechte fehlen.',1;
  SET @Count=CASE WHEN CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.0.0') THEN 3 ELSE 5 END;
  UPDATE @Slots SET ObjectId=CASE WHEN Id<=@Count THEN OBJECT_ID(N'toolbelt_json.'+QUOTENAME(Name)) ELSE NULL END;
  IF EXISTS(SELECT 1 FROM @Slots s WHERE s.Id<=@Count AND NOT EXISTS
   (SELECT 1 FROM sys.objects o WHERE o.object_id=s.ObjectId AND o.type='P'
    AND CONVERT(varbinary(256),o.name)=CONVERT(varbinary(256),s.Name)
    AND EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
     AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.json.constructors'))
    AND EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
     AND ep.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),@Version))
    AND EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
     AND ep.name=N'Toolbelt.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),@Mode))))
  BEGIN
   IF @Pass=1 THROW 53627,N'JSON lifecycle: Ownership unter Lock ist inkohärent.',1;
   THROW 53623,N'JSON lifecycle: Release-Ownership ist inkohärent.',1;
  END;
  IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN @Slots target ON target.ObjectId=d.referenced_id
   WHERE target.Id<=@Count AND NOT EXISTS(SELECT 1 FROM @Slots source WHERE source.Id<=@Count AND source.ObjectId=d.referencing_id))
   THROW 53626,N'JSON lifecycle: same-database Dependency blockiert Uninstall.',1;
  IF @Pass=0
  BEGIN
   SELECT @InitialVersion=CONVERT(varbinary(max),@Version),@InitialMode=CONVERT(varbinary(max),@Mode),@InitialSchemaId=@SchemaId;
   BEGIN TRANSACTION;
   EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.json.constructors',@LockMode=N'Exclusive',
    @LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @LockResult IS NULL OR @LockResult<0 THROW 53627,N'JSON lifecycle: AppLock ist nicht verfügbar.',1;
  END;
  SET @Pass+=1;
 END;
 -- Zukunftsslots bei installiertem 1.0 gehören nicht zu diesem Dropplan.
 SET @Id=@Count;
 WHILE @Id>=1
 BEGIN
  SELECT @Name=Name FROM @Slots WHERE Id=@Id;
  SET @Sql=N'DROP PROCEDURE [toolbelt_json].'+QUOTENAME(@Name)+N';';
  EXEC sys.sp_executesql @Sql;
  SET @Id-=1;
 END;
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.Version';
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';
 -- Unmarkiertes oder nichtleeres fremdes Schema niemals entfernen.
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0
   AND name=N'Toolbelt.Managed' AND TRY_CONVERT(int,value)=1)
  AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0
   AND name=N'Toolbelt.SchemaCategory' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'json'))
  AND NOT EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=@SchemaId)
  AND NOT EXISTS(SELECT 1 FROM sys.types WHERE schema_id=@SchemaId AND is_user_defined=1)
  AND NOT EXISTS(SELECT 1 FROM sys.xml_schema_collections WHERE schema_id=@SchemaId AND xml_collection_id>0)
  DROP SCHEMA [toolbelt_json];
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
