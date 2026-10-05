-- Marker gehören zur selben eigenen Transaktion wie die CREATE-Anweisung.
IF @OwnTransaction<>1 OR @@TRANCOUNT<>1 OR XACT_STATE()<>1
 THROW 55529,N'Eigene JSON-Pointer-Deploymenttransaktion fehlt.',1;
SELECT @SchemaOwner=principal_id FROM sys.schemas WHERE schema_id=SCHEMA_ID(N'toolbelt_json');
IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
 WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name) OR o.type<>'TF'
 OR COALESCE(o.principal_id,@SchemaOwner)<>@SchemaOwner)
 THROW 55529,N'Vollständiger MSTVF-Bestand mit kohärentem Eigentümer fehlt.',2;
DECLARE @Property sysname,@Value sql_variant,@Object sysname;
DECLARE @Managed sql_variant=CONVERT(bit,1),@ModuleValue sql_variant=CONVERT(nvarchar(128),@Module),
 @VersionValue sql_variant=CONVERT(nvarchar(16),N'1.0.0'),@ModeValue sql_variant=CONVERT(nvarchar(16),@Mode),
 @Visibility sql_variant=CONVERT(nvarchar(16),N'public');
DECLARE @Properties TABLE(Name sysname,Value sql_variant);
INSERT @Properties VALUES(N'Toolbelt.Module.toolbelt.json.pointer.Version',@VersionValue),
 (N'Toolbelt.Module.toolbelt.json.pointer.DeploymentMode',@ModeValue);
DECLARE DatabaseMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Value FROM @Properties;
OPEN DatabaseMarkers;FETCH NEXT FROM DatabaseMarkers INTO @Property,@Value;
WHILE @@FETCH_STATUS=0
BEGIN
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Property)
  EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value;
 ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value;
 FETCH NEXT FROM DatabaseMarkers INTO @Property,@Value;
END;
CLOSE DatabaseMarkers;DEALLOCATE DatabaseMarkers;
DECLARE ObjectMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT s.Name,p.Name,p.Value FROM @Slots s
 CROSS APPLY(VALUES(N'Toolbelt.Managed',@Managed),(N'Toolbelt.ModuleId',@ModuleValue),
 (N'Toolbelt.ModuleVersion',@VersionValue),(N'Toolbelt.Visibility',@Visibility))p(Name,Value);
OPEN ObjectMarkers;FETCH NEXT FROM ObjectMarkers INTO @Object,@Property,@Value;
WHILE @@FETCH_STATUS=0
BEGIN
 EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=N'FUNCTION',@level1name=@Object;
 FETCH NEXT FROM ObjectMarkers INTO @Object,@Property,@Value;
END;
CLOSE ObjectMarkers;DEALLOCATE ObjectMarkers;
