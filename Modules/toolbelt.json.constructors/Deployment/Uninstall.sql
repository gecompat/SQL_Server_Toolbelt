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
 @InitialVersion varbinary(max),@InitialMode varbinary(max),@InitialSchemaId int,@InitialClrTuple varbinary(max),@CurrentClrTuple varbinary(max),@Id int,@Name sysname,@DropKind char(2),@Sql nvarchar(max);
DECLARE @Slots TABLE(Id int PRIMARY KEY,Name sysname COLLATE DATABASE_DEFAULT NOT NULL,ObjectId int NULL,Kind char(2) NOT NULL);
INSERT @Slots VALUES(1,N'USP_JsonConstructInternal',NULL,'P'),(2,N'USP_JsonArray',NULL,'P'),(3,N'USP_JsonObject',NULL,'P'),
 (4,N'USP_JsonArraysByGroup',NULL,'P'),(5,N'USP_JsonObjectsByGroup',NULL,'P'),
 (6,N'FT_JsonEntryEvaluateInternal',NULL,'FT'),(7,N'AGF_JsonArray',NULL,'AF'),(8,N'AGF_JsonObject',NULL,'AF');
:r ./KnownArtifact.sql
:r ./KnownArtifact1_3.sql
:r ../../toolbelt.json.core/Deployment/KnownArtifact.sql
IF CONVERT(varbinary(max),@Confirmation) NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
 THROW 53625,N'JSON lifecycle: Consumer-Bestätigung ist ungültig.',1;
BEGIN TRY
 WHILE @Pass<2
 BEGIN
  IF COALESCE(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
   THROW 53620,N'JSON lifecycle: SQL-Version wird nicht unterstützt.',1;
  IF COALESCE((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
   THROW 53629,N'JSON lifecycle: Compatibility Level wird nicht unterstützt.',1;
  IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
   OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
   THROW 53622,N'JSON lifecycle: vollständige Metadatensicht fehlt.',1;
  SELECT @Version=NULL,@Mode=NULL,@Registered=0,@ModeRegistered=0,@SchemaId=SCHEMA_ID(N'toolbelt_json');
  SELECT @Registered=1,@Version=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version';
  SELECT @ModeRegistered=1,@Mode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';
  IF @Pass=1 AND(@Registered=0 OR COALESCE(CONVERT(varbinary(max),@Version),0x)<>@InitialVersion
   OR COALESCE(CONVERT(varbinary(max),@Mode),0x)<>@InitialMode OR COALESCE(@SchemaId,-1)<>@InitialSchemaId)
   THROW 53627,N'JSON lifecycle: Zustand hat sich unter Lock verändert.',1;
  IF @Registered=0 AND @ModeRegistered=0
  BEGIN
   IF EXISTS(SELECT 1 FROM @Slots WHERE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(Name)) IS NOT NULL)
    OR EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors')
    THROW 53623,N'JSON lifecycle: unregistrierter Zielzustand ist nicht absent.',1;
   RETURN;
  END;
  IF @Registered=0 OR @ModeRegistered=0 OR @SchemaId IS NULL OR @Version IS NULL OR @Mode IS NULL
   OR CONVERT(varbinary(max),@Version) NOT IN(CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0'),CONVERT(varbinary(max),N'1.2.0'),CONVERT(varbinary(max),N'1.3.0'))
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
  SET @Count=CASE WHEN CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.0.0') THEN 3 WHEN CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.1.0') THEN 5 ELSE 8 END;
  UPDATE @Slots SET ObjectId=CASE WHEN Id<=@Count THEN OBJECT_ID(N'toolbelt_json.'+QUOTENAME(Name)) ELSE NULL END;
  IF EXISTS(SELECT 1 FROM @Slots s WHERE s.Id<=@Count AND NOT EXISTS
   (SELECT 1 FROM sys.objects o WHERE o.object_id=s.ObjectId AND CONVERT(varbinary(2),o.type)=CONVERT(varbinary(2),s.Kind)
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
  SELECT @KnownMode=CONVERT(nvarchar(16),@Mode),@KnownCount=@Count;
:r ./ClrPreflight.sql
  SELECT @CurrentClrTuple=CONVERT(varbinary(max),(SELECT s.Id,OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name)) ObjectId,
   o.principal_id ObjectOwner,sc.principal_id SchemaOwner,@AssemblyId AssemblyId,@AssemblyOwner AssemblyOwner,
   @JsonCoreId CoreId,@JsonCoreOwner CoreOwner
   FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
   LEFT JOIN sys.schemas sc ON sc.schema_id=o.schema_id ORDER BY s.Id FOR XML RAW,BINARY BASE64));
  IF @Pass=0 SET @InitialClrTuple=@CurrentClrTuple;
  ELSE IF @CurrentClrTuple<>@InitialClrTuple THROW 53627,N'JSON lifecycle: Objekt-/Assemblyidentität hat sich unter Lock verändert.',1;
  IF @AssemblyId IS NOT NULL AND COALESCE(HAS_PERMS_BY_NAME(N'Toolbelt_JsonConstructors',N'ASSEMBLY',N'ALTER'),0)<>1
   THROW 53622,N'JSON lifecycle: vorhandenes Assembly-ALTER-Recht fehlt.',1;
  IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN @Slots target ON target.ObjectId=d.referenced_id
   WHERE target.Id<=@Count AND NOT EXISTS(SELECT 1 FROM @Slots source WHERE source.Id<=@Count AND source.ObjectId=d.referencing_id))
   THROW 53626,N'JSON lifecycle: same-database Dependency blockiert Uninstall.',1;
  IF @Pass=0
  BEGIN
   SELECT @InitialVersion=CONVERT(varbinary(max),@Version),@InitialMode=CONVERT(varbinary(max),@Mode),@InitialSchemaId=@SchemaId;
   BEGIN TRANSACTION;
   EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.json.shared-core',@LockMode=N'Shared',
    @LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @LockResult IS NULL OR @LockResult<0 THROW 53627,N'JSON lifecycle: gemeinsame Core-AppLock ist nicht verfügbar.',1;
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
  SELECT @Name=Name,@DropKind=Kind FROM @Slots WHERE Id=@Id;
  SET @Sql=N'DROP '+CASE @DropKind WHEN 'P' THEN N'PROCEDURE' WHEN 'AF' THEN N'AGGREGATE' ELSE N'FUNCTION' END
   +N' [toolbelt_json].'+QUOTENAME(@Name)+N';';
  EXEC sys.sp_executesql @Sql;
  SET @Id-=1;
 END;
 IF @Count=8 DROP ASSEMBLY [Toolbelt_JsonConstructors] WITH NO DEPENDENTS;
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
