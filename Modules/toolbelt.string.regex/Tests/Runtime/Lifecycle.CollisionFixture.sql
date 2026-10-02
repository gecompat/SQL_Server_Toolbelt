SET NOCOUNT ON;
-- Nur in einer vom Testtreiber neu angelegten, synthetischen Datenbank ausführen.
-- Pro FaultCase eigener Installationsstand; keine Reparatur fremder Objekte.
DECLARE @FaultCase nvarchar(64)=N'$(FaultCase)';
IF @FaultCase=N'ForeignFunctionMarker' SET @FaultCase=N'FunctionModuleId';
IF @FaultCase=N'ForeignProviderMarker' SET @FaultCase=N'AssemblyModuleId';
IF @FaultCase=N'InconsistentFunctionVersion' SET @FaultCase=N'FunctionVersion';
IF @FaultCase=N'MissingVersion'
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.string.regex.Version';
ELSE IF @FaultCase=N'UnknownVersion'
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.regex.Version',@value=N'9.9.9';
ELSE IF @FaultCase IN(N'FunctionManaged',N'FunctionModuleId',N'FunctionVersion')
BEGIN
 DECLARE @FunctionName sysname=CASE WHEN OBJECT_ID(N'toolbelt_string.TVF_RegexCaptures') IS NOT NULL
 THEN N'TVF_RegexCaptures' ELSE N'SVF_RegexIsMatch' END;
 DECLARE @Property sysname=CASE @FaultCase WHEN N'FunctionManaged' THEN N'Toolbelt.Managed'
 WHEN N'FunctionModuleId' THEN N'Toolbelt.ModuleId' ELSE N'Toolbelt.ModuleVersion' END;
 EXEC sys.sp_updateextendedproperty @name=@Property,@value=N'fixture.foreign',
 @level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=@FunctionName;
END;
ELSE IF @FaultCase IN(N'AssemblyManaged',N'AssemblyModuleId',N'AssemblyVersion')
BEGIN
 DECLARE @AssemblyProperty sysname=CASE @FaultCase WHEN N'AssemblyManaged' THEN N'Toolbelt.Managed'
 WHEN N'AssemblyModuleId' THEN N'Toolbelt.ModuleId' ELSE N'Toolbelt.ModuleVersion' END;
 EXEC sys.sp_updateextendedproperty @name=@AssemblyProperty,@value=N'fixture.foreign',
 @level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Regex';
END;
ELSE IF @FaultCase=N'ForeignSchema'
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'fixture.foreign',
 @level0type=N'SCHEMA',@level0name=N'toolbelt_string';
ELSE IF @FaultCase IN(N'ForeignNewSlot',N'ImitatedNewSlot')
BEGIN
 IF OBJECT_ID(N'toolbelt_string.SVF_RegexReplaceGroups') IS NOT NULL
  THROW 52088,N'Dieser Test benötigt einen historischen Release-Stand.',1;
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_string.SVF_RegexReplaceGroups() RETURNS int AS BEGIN RETURN 73; END;';
 IF @FaultCase=N'ImitatedNewSlot'
 BEGIN
  DECLARE @Version nvarchar(64)=(SELECT CONVERT(nvarchar(64),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.regex.Version');
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,
   @level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'SVF_RegexReplaceGroups';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.string.regex',
   @level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'SVF_RegexReplaceGroups';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Version,
   @level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'SVF_RegexReplaceGroups';
 END;
END;
ELSE IF @FaultCase=N'Dependency'
 EXEC sys.sp_executesql N'CREATE VIEW dbo.ToolbeltRegexFixtureDependency AS SELECT toolbelt_string.SVF_RegexCount(N''a'',N''a'',1,N''c'') AS Value;';
ELSE
 THROW 52088,N'Unbekannter synthetischer Lifecycle-FaultCase.',2;
