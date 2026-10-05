-- Marker gehören zur selben eigenen Transaktion wie alle sechs CREATE-Anweisungen.
IF @OwnTransaction<>1 OR @@TRANCOUNT<>1 OR XACT_STATE()<>1
 THROW 55429,N'Eigene Safe-Cast-Deploymenttransaktion fehlt.',1;
SELECT @SchemaOwner=principal_id FROM sys.schemas WHERE schema_id=SCHEMA_ID(N'toolbelt_conversion');
IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_conversion.'+QUOTENAME(s.Name))
 WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name) OR o.type<>'IF'
 OR COALESCE(o.principal_id,@SchemaOwner)<>@SchemaOwner)
 THROW 55429,N'Vollständiger sechsfacher Inline-TVF-Bestand mit kohärentem Eigentümer fehlt.',2;
DECLARE @Property sysname,@Value sql_variant,@Object sysname;
DECLARE @Managed sql_variant=CONVERT(bit,1),@ModuleValue sql_variant=CONVERT(nvarchar(128),@Module),
 @VersionValue sql_variant=CONVERT(nvarchar(16),N'1.0.0'),@ModeValue sql_variant=CONVERT(nvarchar(16),@Mode),
 @Visibility sql_variant=CONVERT(nvarchar(16),N'public');
DECLARE @Properties TABLE(Name sysname,Value sql_variant);
INSERT @Properties VALUES(N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version',@VersionValue),
 (N'Toolbelt.Module.toolbelt.conversion.safe-cast.DeploymentMode',@ModeValue);
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
 EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_conversion',@level1type=N'FUNCTION',@level1name=@Object;
 FETCH NEXT FROM ObjectMarkers INTO @Object,@Property,@Value;
END;
CLOSE ObjectMarkers;DEALLOCATE ObjectMarkers;
