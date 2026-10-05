-- Abschluss der eigenen Deploymenttransaktion; nur exakt fünf bekannte Slots markieren.
BEGIN TRY
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55329,N'Eigene CSV-Deploymenttransaktion fehlt.',1;
 DECLARE @Module sql_variant=CONVERT(nvarchar(128),N'toolbelt.file.csv-memory'),@Version sql_variant=CONVERT(nvarchar(16),N'1.0.0'),@Managed sql_variant=CONVERT(bit,1),@Mode sql_variant=CONVERT(nvarchar(16),N'$(DeploymentMode)');
 DECLARE @Property sysname,@Value sql_variant,@Object sysname,@Type varchar(16);
 DECLARE @Properties TABLE(Name sysname,Value sql_variant);
 INSERT @Properties VALUES(N'Toolbelt.Module.toolbelt.file.csv-memory.Version',@Version),(N'Toolbelt.Module.toolbelt.file.csv-memory.DeploymentMode',@Mode);
 DECLARE DatabaseMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Value FROM @Properties;
 OPEN DatabaseMarkers;FETCH NEXT FROM DatabaseMarkers INTO @Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Property) EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value;
  ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value;
  FETCH NEXT FROM DatabaseMarkers INTO @Property,@Value;
 END;
 CLOSE DatabaseMarkers;DEALLOCATE DatabaseMarkers;
 DECLARE @Slots TABLE(Name sysname,Kind char(2));
 INSERT @Slots VALUES(N'USP_ParseCsv','P'),(N'USP_WriteCsv','P'),(N'TVF_InternalParseCsv','FT'),(N'SVF_InternalQuoteCsvCell','FS'),(N'SVF_InternalMeasureCsvCell','FS');
 IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(s.Name)) WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name) OR CONVERT(varbinary(max),o.type)<>CONVERT(varbinary(max),s.Kind))
  THROW 55329,N'Der vollständige fünfteilige CSV-Zielslotbestand fehlt.',2;
 DECLARE ObjectMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT s.Name,CASE WHEN s.Kind='P' THEN 'PROCEDURE' ELSE 'FUNCTION' END,p.Name,p.Value FROM @Slots s CROSS APPLY(VALUES(N'Toolbelt.Managed',@Managed),(N'Toolbelt.ModuleId',@Module),(N'Toolbelt.ModuleVersion',@Version),(N'Toolbelt.Visibility',CONVERT(sql_variant,CONVERT(nvarchar(16),CASE WHEN s.Kind='P' THEN N'public' ELSE N'internal' END))))p(Name,Value);
 OPEN ObjectMarkers;FETCH NEXT FROM ObjectMarkers INTO @Object,@Type,@Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=@Type,@level1name=@Object;
  FETCH NEXT FROM ObjectMarkers INTO @Object,@Type,@Property,@Value;
 END;
 CLOSE ObjectMarkers;DEALLOCATE ObjectMarkers;
 DECLARE @AssemblyId int=(SELECT assembly_id FROM sys.assemblies WHERE CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_File_CsvMemory'));
 IF @AssemblyId IS NULL THROW 55329,N'Die CSV-Zielassembly fehlt.',3;
 DELETE FROM @Properties;INSERT @Properties VALUES(N'Toolbelt.Managed',@Managed),(N'Toolbelt.ModuleId',@Module),(N'Toolbelt.ModuleVersion',@Version);
 DECLARE AssemblyMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Value FROM @Properties;
 OPEN AssemblyMarkers;FETCH NEXT FROM AssemblyMarkers INTO @Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND name=@Property)
   EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_File_CsvMemory';
  ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_File_CsvMemory';
  FETCH NEXT FROM AssemblyMarkers INTO @Property,@Value;
 END;
 CLOSE AssemblyMarkers;DEALLOCATE AssemblyMarkers;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
