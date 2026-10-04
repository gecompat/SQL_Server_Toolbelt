-- Abschluss derselben eigenen SQLCMD-Transaktion; kein separater EntryPoint.
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1
    THROW 55270,N'Der eigene Lifecycle-Transaktionszustand fehlt.',2;
BEGIN TRY
 DECLARE @AssemblyMarkerId int=(SELECT assembly_id FROM sys.assemblies WHERE CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_String_Phonetic'));
 DECLARE @Version sql_variant=CONVERT(nvarchar(16),N'1.0.0'),
         @Module sql_variant=CONVERT(nvarchar(128),N'toolbelt.string.phonetic'),
         @Managed sql_variant=CONVERT(bit,1),
         @Mode sql_variant=CONVERT(nvarchar(16),N'$(DeploymentMode)'),
         @Schema sysname=N'toolbelt_string',@Name sysname,@Visibility sql_variant;
 DECLARE @Properties TABLE(Name sysname,Value sql_variant);
 INSERT @Properties VALUES
 (N'Toolbelt.Module.toolbelt.string.phonetic.Version',@Version),
 (N'Toolbelt.Module.toolbelt.string.phonetic.DeploymentMode',@Mode);
 DECLARE @Property sysname,@Value sql_variant;
 DECLARE DatabaseMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Value FROM @Properties;
 OPEN DatabaseMarkers;FETCH NEXT FROM DatabaseMarkers INTO @Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@Property)
   EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value;
  ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value;
  FETCH NEXT FROM DatabaseMarkers INTO @Property,@Value;
 END;
 CLOSE DatabaseMarkers;DEALLOCATE DatabaseMarkers;
 DECLARE ObjectMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.objects WHERE schema_id=SCHEMA_ID(@Schema) AND name IN
  (N'TVF_ColognePhonetic',N'TVF_DoubleMetaphone',N'TVF_ColognePhoneticCore',N'TVF_DoubleMetaphoneCore');
 OPEN ObjectMarkers;FETCH NEXT FROM ObjectMarkers INTO @Name;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @Visibility=CONVERT(nvarchar(16),CASE WHEN RIGHT(@Name,4)=N'Core' THEN N'internal' ELSE N'public' END);
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=@Managed,@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'FUNCTION',@level1name=@Name;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=@Module,@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'FUNCTION',@level1name=@Name;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Version,@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'FUNCTION',@level1name=@Name;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Visibility',@value=@Visibility,@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'FUNCTION',@level1name=@Name;
  FETCH NEXT FROM ObjectMarkers INTO @Name;
 END;
 CLOSE ObjectMarkers;DEALLOCATE ObjectMarkers;
 IF (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(@Schema) AND name IN
 (N'TVF_ColognePhonetic',N'TVF_DoubleMetaphone',N'TVF_ColognePhoneticCore',N'TVF_DoubleMetaphoneCore'))<>4
  THROW 55264,N'Der vollständige Zielslotbestand fehlt.',8;
 -- Die Assembly bleibt bei gleichem Binary bestehen; vorhandene bekannte
 -- Marker werden aktualisiert, die Funktionen wurden atomar neu angelegt.
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyMarkerId AND name=N'Toolbelt.Managed')
 BEGIN
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Managed',@value=@Managed,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Phonetic';
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=@Module,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Phonetic';
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Version,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Phonetic';
 END
 ELSE
 BEGIN
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=@Managed,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Phonetic';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=@Module,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Phonetic';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Version,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Phonetic';
 END;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO