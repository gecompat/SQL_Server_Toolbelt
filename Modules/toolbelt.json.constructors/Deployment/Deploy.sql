:On Error exit
-- Erst-/Repeat1.3 sowie explizite bekannte1.2→1.3-Migration; kein Downgrade.
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'JSON_LIFECYCLE_CALLER_TRANSACTION: aktive Callertransaktion ist ausgeschlossen.',16,1);
 RETURN;
END;
IF OBJECT_ID(N'tempdb..#tbx_JsonConstructorDeployState',N'U') IS NOT NULL
 THROW 53623,N'JSON lifecycle: reservierter Deploymentzustand ist belegt.',1;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
DECLARE @Mode nvarchar(max)=N'$(DeploymentMode)',@Version nvarchar(max),@InstalledMode nvarchar(max),
 @Registered bit,@ModeRegistered bit,@SchemaId int,@Pass int=0,@LockResult int,@PreviousCount int,
 @InitialVersion varbinary(max),@InitialMode varbinary(max),@InitialRegistered bit,@InitialSchemaId int,@InitialClrTuple varbinary(max),@CurrentClrTuple varbinary(max),
 @DependencyVersion nvarchar(max),@DependencyId int,@Major int,@Minor int,@Patch int;
DECLARE @Slots TABLE(Id int PRIMARY KEY,Name sysname COLLATE DATABASE_DEFAULT NOT NULL,Kind char(2) NOT NULL);
INSERT @Slots VALUES(1,N'USP_JsonConstructInternal','P'),(2,N'USP_JsonArray','P'),(3,N'USP_JsonObject','P'),
 (4,N'USP_JsonArraysByGroup','P'),(5,N'USP_JsonObjectsByGroup','P'),
 (6,N'FT_JsonEntryEvaluateInternal','FT'),(7,N'AGF_JsonArray','AF'),(8,N'AGF_JsonObject','AF');
:r ./KnownArtifact.sql
:r ./KnownArtifact1_3.sql
:r ../../toolbelt.json.core/Deployment/KnownArtifact.sql
DECLARE @TargetBits varbinary(max)=$(AssemblyBits);
IF @TargetBits IS NULL OR HASHBYTES(N'SHA2_512',@TargetBits)<>@TargetKnownHash
 THROW 53623,N'JSON lifecycle: Targetbinary ist kein qualifiziertes bekanntes Artefakt.',1;
BEGIN TRY
 WHILE @Pass<2
 BEGIN
  -- Vollständiger identischer Preflight vor und unter der AppLock.
  IF COALESCE(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
   THROW 53620,N'JSON lifecycle: SQL-Version wird nicht unterstützt.',1;
  IF CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
   THROW 53621,N'JSON lifecycle: Deployment-Modus ist ungültig.',1;
  IF COALESCE((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
   THROW 53629,N'JSON lifecycle: Compatibility Level wird nicht unterstützt.',1;
  IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
   OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
   THROW 53622,N'JSON lifecycle: vollständige Metadatensicht fehlt.',1;
  SELECT @Version=NULL,@InstalledMode=NULL,@Registered=0,@ModeRegistered=0,@SchemaId=SCHEMA_ID(N'toolbelt_json');
  SELECT @Registered=1,@Version=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version';
  SELECT @ModeRegistered=1,@InstalledMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';
  IF @Pass=1 AND(@Registered<>@InitialRegistered
   OR COALESCE(CONVERT(varbinary(max),@Version),0x)<>COALESCE(@InitialVersion,0x)
   OR COALESCE(CONVERT(varbinary(max),@InstalledMode),0x)<>COALESCE(@InitialMode,0x)
   OR COALESCE(@SchemaId,-1)<>COALESCE(@InitialSchemaId,-1))
   THROW 53627,N'JSON lifecycle: Zustand hat sich unter Lock verändert.',1;
  IF (@Registered=0 AND @ModeRegistered=1) OR(@Registered=1 AND
   (@Version IS NULL OR CONVERT(varbinary(max),@Version) NOT IN(CONVERT(varbinary(max),N'1.2.0'),CONVERT(varbinary(max),N'1.3.0'))
    OR @ModeRegistered=0 OR @InstalledMode IS NULL
    OR CONVERT(varbinary(max),@InstalledMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
    OR @SchemaId IS NULL))
  BEGIN
   IF @Pass=1 THROW 53627,N'JSON lifecycle: Releasezustand unter Lock ist inkohärent.',1;
   THROW 53623,N'JSON lifecycle: Releasezustand ist unbekannt oder inkohärent.',1;
  END;
  SET @PreviousCount=CASE WHEN @Registered=0 THEN 0 WHEN CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.0.0') THEN 3 WHEN CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.1.0') THEN 5 ELSE 8 END;
  IF EXISTS(SELECT 1 FROM @Slots s WHERE s.Id>@PreviousCount AND OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name)) IS NOT NULL)
  BEGIN
   IF @Pass=1 THROW 53627,N'JSON lifecycle: neuer Zielslot unter Lock ist fremd.',1;
   THROW 53624,N'JSON lifecycle: neuer Zielslot ist bereits fremd belegt.',1;
  END;
  -- Bekannte Namen ohne vollständige Marker/Proceduretyp sind keine Ownership.
  IF EXISTS(SELECT 1 FROM @Slots s WHERE s.Id<=@PreviousCount AND NOT EXISTS
   (SELECT 1 FROM sys.objects o WHERE o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
    AND CONVERT(varbinary(2),o.type)=CONVERT(varbinary(2),s.Kind) AND CONVERT(varbinary(256),o.name)=CONVERT(varbinary(256),s.Name)
    AND EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
     AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.json.constructors'))
    AND EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
     AND ep.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),@Version))
    AND EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
     AND ep.name=N'Toolbelt.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),@InstalledMode))))
  BEGIN
   IF @Pass=1 THROW 53627,N'JSON lifecycle: Ownership unter Lock ist inkohärent.',1;
   THROW 53623,N'JSON lifecycle: Release-Ownership ist inkohärent.',1;
  END;
  SELECT @KnownMode=CONVERT(nvarchar(16),@InstalledMode),@KnownCount=@PreviousCount,@CreatingSlots=1;
:r ./ClrPreflight.sql
  -- SQL6282 verhindert ALTER bei neuer Core-Referenz. Der bekannte1.2-Pfad
  -- ersetzt daher nur drei eigene CLR-Slots/Assembly atomar. Fremde Rechte,
  -- Zusatzmetadaten oder explizite Owner dürfen dabei niemals verloren gehen.
  -- In beiden Pässen vor dem ersten DROP prüfen; keine GRANT-/Ownerreparatur.
  IF @AssemblyId IS NOT NULL AND CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.2.0')
  BEGIN
   IF EXISTS(SELECT 1 FROM sys.database_permissions p WHERE
      (p.class=5 AND p.major_id=@AssemblyId) OR
      (p.class=1 AND p.major_id IN(SELECT OBJECT_ID(N'toolbelt_json.'+QUOTENAME(Name)) FROM @Slots WHERE Kind IN('FT','AF'))))
    OR EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
      WHERE s.Kind IN('FT','AF') AND o.principal_id IS NOT NULL)
    OR @EffectiveOwner<>(SELECT principal_id FROM sys.schemas WHERE schema_id=@SchemaId)
    OR EXISTS(SELECT 1 FROM sys.extended_properties e WHERE
      (e.class=5 AND e.major_id=@AssemblyId AND (e.minor_id<>0 OR e.name NOT IN
       (N'Toolbelt.Managed',N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion',N'Toolbelt.DeploymentMode',N'Toolbelt.AssemblySha512',N'Toolbelt.ArtifactId')))
      OR (e.class=1 AND e.major_id IN(SELECT OBJECT_ID(N'toolbelt_json.'+QUOTENAME(Name)) FROM @Slots WHERE Kind IN('FT','AF'))
       AND (e.minor_id<>0 OR e.name NOT IN(N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion',N'Toolbelt.ContractVersion',N'Toolbelt.DeploymentMode',N'Toolbelt.SourceHash'))))
    THROW 53622,N'JSON lifecycle:1.2-Migration würde direkte Rechte, explizite Owner oder zusätzliche CLR-Metadaten verlieren; kein automatischer Austausch.',1;
  END;
  SELECT @CurrentClrTuple=CONVERT(varbinary(max),(SELECT s.Id,OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name)) ObjectId,
   o.principal_id ObjectOwner,sc.principal_id SchemaOwner,@AssemblyId AssemblyId,@AssemblyOwner AssemblyOwner,
   @JsonCoreId CoreId,@JsonCoreOwner CoreOwner
   FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
   LEFT JOIN sys.schemas sc ON sc.schema_id=o.schema_id ORDER BY s.Id FOR XML RAW,BINARY BASE64));
  IF @Pass=0 SET @InitialClrTuple=@CurrentClrTuple;
  ELSE IF @CurrentClrTuple<>@InitialClrTuple THROW 53627,N'JSON lifecycle: Objekt-/Assemblyidentität hat sich unter Lock verändert.',1;
  IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
   OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
   OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE ASSEMBLY'),0)<>1
   OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE FUNCTION'),0)<>1
   THROW 53622,N'JSON lifecycle: CLR-Konfiguration oder vorhandene Installationsrechte fehlen.',1;
  IF @AssemblyId IS NOT NULL AND COALESCE(HAS_PERMS_BY_NAME(N'Toolbelt_JsonConstructors',N'ASSEMBLY',N'ALTER'),0)<>1
   THROW 53622,N'JSON lifecycle: vorhandenes Assembly-ALTER-Recht fehlt.',1;
  IF (@SchemaId IS NULL AND COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE SCHEMA'),0)<>1)
   OR(@SchemaId IS NOT NULL AND COALESCE(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'ALTER'),0)<>1)
   OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE'),0)<>1
   THROW 53622,N'JSON lifecycle: erforderliche Installationsrechte fehlen.',1;
  SET @DependencyVersion=NULL;
  SELECT @DependencyVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
  SELECT @DependencyId=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),
   @Major=TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)),@Minor=TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)),@Patch=TRY_CONVERT(int,PARSENAME(@DependencyVersion,1));
  IF @DependencyId IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
   OR CONVERT(varbinary(max),@DependencyVersion)<>CONVERT(varbinary(max),CONCAT(@Major,N'.',@Minor,N'.',@Patch))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleId'
    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@DependencyVersion))
   THROW 53622,N'JSON lifecycle: registrierte ResultTable-Dependency ist ungeeignet.',1;
  IF @Pass=0
  BEGIN
   SELECT @InitialRegistered=@Registered,@InitialVersion=CONVERT(varbinary(max),@Version),
    @InitialMode=CONVERT(varbinary(max),@InstalledMode),@InitialSchemaId=@SchemaId;
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
 -- Die fünf Procedures behalten ihre ObjectIds und vorhandenen Rechte.
 -- Drei eigene CLR-ObjectIds und AssemblyId werden neu erzeugt; Namen,
 -- Signaturen, effektiver Owner und AGF-Wireform bleiben erhalten.
 -- Alle Fremdverbraucher/verlustgefährdeten Tupel wurden zweimal ausgeschlossen.
 -- DROP/CREATE/Marker bleiben bis zur finalen Prüfung in derselben Transaktion.
 IF @AssemblyId IS NOT NULL AND CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.2.0')
 BEGIN
  DROP AGGREGATE toolbelt_json.AGF_JsonArray;
  DROP AGGREGATE toolbelt_json.AGF_JsonObject;
  DROP FUNCTION toolbelt_json.FT_JsonEntryEvaluateInternal;
  DROP ASSEMBLY [Toolbelt_JsonConstructors] WITH NO DEPENDENTS;
  SET @AssemblyId=NULL;
 END;
 IF @SchemaId IS NULL
 BEGIN
  EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_json];';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_json';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'json',@level0type=N'SCHEMA',@level0name=N'toolbelt_json';
 END;
 -- Neue Assembly erhält den bereits vorhandenen Schemaowner, niemals Ownerreparatur.
 IF @AssemblyId IS NULL
 BEGIN
  SELECT @EffectiveOwner=principal_id FROM sys.schemas WHERE name=N'toolbelt_json';
  DECLARE @AssemblyOwnerName sysname=USER_NAME(@EffectiveOwner),@AssemblySql nvarchar(max);
  IF @AssemblyOwnerName IS NULL THROW 53622,N'JSON lifecycle: vorhandener Schemaowner ist nicht sichtbar.',1;
  SET @AssemblySql=N'CREATE ASSEMBLY [Toolbelt_JsonConstructors] AUTHORIZATION '+QUOTENAME(@AssemblyOwnerName)
   +N' FROM '+CONVERT(nvarchar(max),@TargetBits,1)+N' WITH PERMISSION_SET=SAFE;';
  EXEC sys.sp_executesql @AssemblySql;
 END;
 -- Eigener über GO erreichbarer Zustand; kein Löschen gleichnamiger Callertemps.
 CREATE TABLE #tbx_JsonConstructorDeployState(DeploymentMode nvarchar(16) NOT NULL);
 DECLARE @StateMode nvarchar(16)=CONVERT(nvarchar(16),@Mode);
 -- Erst nach Caller- und Namensraumprüfung gegen die eigene Tempstruktur kompilieren.
 EXEC sys.sp_executesql N'INSERT #tbx_JsonConstructorDeployState(DeploymentMode) VALUES(@Mode);',
  N'@Mode nvarchar(16)',@Mode=@StateMode;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
:r ../Source/JsonEntryEvaluate.sql
:r ../Source/JsonAggregates.sql
:r ../Source/USP_JsonConstructInternal.sql
:r ../Source/USP_JsonArray.sql
:r ../Source/USP_JsonObject.sql
:r ../Source/USP_JsonArraysByGroup.sql
:r ../Source/USP_JsonObjectsByGroup.sql

BEGIN TRY
 IF XACT_STATE()<>1 OR @@TRANCOUNT<>1 OR OBJECT_ID(N'tempdb..#tbx_JsonConstructorDeployState',N'U') IS NULL
  THROW 53628,N'JSON lifecycle: eigene Deploymenttransaktion ist unvollständig.',1;
 DECLARE @Slots TABLE(Id int PRIMARY KEY,Name sysname COLLATE DATABASE_DEFAULT NOT NULL,Kind char(2) NOT NULL);
 INSERT @Slots VALUES(1,N'USP_JsonConstructInternal','P'),(2,N'USP_JsonArray','P'),(3,N'USP_JsonObject','P'),
 (4,N'USP_JsonArraysByGroup','P'),(5,N'USP_JsonObjectsByGroup','P'),
 (6,N'FT_JsonEntryEvaluateInternal','FT'),(7,N'AGF_JsonArray','AF'),(8,N'AGF_JsonObject','AF');
 IF EXISTS(SELECT 1 FROM @Slots WHERE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(Name),Kind) IS NULL)
  THROW 53628,N'JSON lifecycle: Releaseobjekte sind unvollständig.',1;
 DECLARE @Mode nvarchar(16)=(SELECT DeploymentMode FROM #tbx_JsonConstructorDeployState),@Id int=1,@Name sysname,@ObjectId int,
  @LevelType varchar(16),@Kind char(2),@PropertyId int,@PropertyName sysname,@PropertyValue nvarchar(4000);
 DECLARE @Properties TABLE(Id int PRIMARY KEY,Name sysname,Value nvarchar(4000));
 WHILE @Id<=8
 BEGIN
  SELECT @Name=Name,@Kind=Kind FROM @Slots WHERE Id=@Id;
  SET @ObjectId=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Name),@Kind);
  SET @LevelType=CASE @Kind WHEN 'P' THEN 'PROCEDURE' WHEN 'AF' THEN 'AGGREGATE' ELSE 'FUNCTION' END;
  INSERT @Properties VALUES(1,N'Toolbelt.ModuleId',N'toolbelt.json.constructors'),(2,N'Toolbelt.ModuleVersion',N'1.3.0'),
   (3,N'Toolbelt.ContractVersion',N'1.0'),(4,N'Toolbelt.DeploymentMode',@Mode),
   (5,N'Toolbelt.SourceHash',CASE WHEN @Kind='P' THEN CONVERT(nvarchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@ObjectId))),2)
    WHEN @Kind='FT' THEN N'FCB13D767B7E0E449F8C7BDADCCE8344D4D4953D7EA098D07A3D4D115FCD868E'
    ELSE N'6A87B485C7862097A46164C077C875CBD32B76F2336A0757B25729684772350C' END);
  SET @PropertyId=1;
  WHILE @PropertyId<=5
  BEGIN
   SELECT @PropertyName=Name,@PropertyValue=Value FROM @Properties WHERE Id=@PropertyId;
   IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@PropertyName)
    EXEC sys.sp_updateextendedproperty @name=@PropertyName,@value=@PropertyValue,@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=@LevelType,@level1name=@Name;
   ELSE EXEC sys.sp_addextendedproperty @name=@PropertyName,@value=@PropertyValue,@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=@LevelType,@level1name=@Name;
   SET @PropertyId+=1;
  END;
  DELETE FROM @Properties;
  SET @Id+=1;
 END;
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version')
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.Version',@value=N'1.3.0';
 ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.Version',@value=N'1.3.0';
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode')
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode',@value=@Mode;
 ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode',@value=@Mode;
:r ./KnownArtifact.sql
:r ./KnownArtifact1_3.sql
:r ../../toolbelt.json.core/Deployment/KnownArtifact.sql
 DECLARE @Version nvarchar(max)=N'1.3.0',@SchemaId int=SCHEMA_ID(N'toolbelt_json');
 SELECT @KnownMode=@Mode,@KnownCount=8;
 DECLARE @MarkerId int=1,@MarkerName sysname,@MarkerValue sql_variant,
  @ModuleIdValue nvarchar(64)=N'toolbelt.json.constructors',@ModuleVersionValue nvarchar(16)=N'1.3.0',
  @ModeValue nvarchar(16)=@Mode,@ArtifactValue varchar(64)=@TargetArtifactId;
 DECLARE @AssemblyMarkers TABLE(Id int PRIMARY KEY,Name sysname,Value sql_variant);
 INSERT @AssemblyMarkers VALUES(1,N'Toolbelt.Managed',CONVERT(sql_variant,CONVERT(int,1))),(2,N'Toolbelt.ModuleId',CONVERT(sql_variant,@ModuleIdValue)),
  (3,N'Toolbelt.ModuleVersion',CONVERT(sql_variant,@ModuleVersionValue)),(4,N'Toolbelt.DeploymentMode',CONVERT(sql_variant,@ModeValue)),
  (5,N'Toolbelt.AssemblySha512',CONVERT(sql_variant,@TargetKnownHash)),(6,N'Toolbelt.ArtifactId',CONVERT(sql_variant,@ArtifactValue));
 WHILE @MarkerId<=6
 BEGIN
  SELECT @MarkerName=Name,@MarkerValue=Value FROM @AssemblyMarkers WHERE Id=@MarkerId;
  IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors') AND minor_id=0 AND name=@MarkerName)
   EXEC sys.sp_updateextendedproperty @name=@MarkerName,@value=@MarkerValue,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonConstructors';
  ELSE EXEC sys.sp_addextendedproperty @name=@MarkerName,@value=@MarkerValue,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonConstructors';
  SET @MarkerId+=1;
 END;
:r ./ClrPreflight.sql
 DROP TABLE #tbx_JsonConstructorDeployState;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
