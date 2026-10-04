SET NOCOUNT ON;
-- Nur eigene synthetische Wegwerf-DB; Adapter vergleicht vor/nach dem abgewiesenen Lifecycle.
DECLARE @Case nvarchar(64)=N'$(FaultCase)',@VersionRaw nvarchar(max),@ModeRaw nvarchar(max),
 @Version nvarchar(64),@Mode nvarchar(16),@Value nvarchar(4000),@Expected int=51534,
 @RestoreSql nvarchar(max)=N'',@FutureName sysname;
SELECT @VersionRaw=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version';
SELECT @ModeRaw=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode';
IF @VersionRaw IS NULL OR CONVERT(varbinary(max),@VersionRaw) NOT IN(CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0'),CONVERT(varbinary(max),N'1.2.0'))
 OR @ModeRaw IS NULL OR CONVERT(varbinary(max),@ModeRaw) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
 THROW 51590,N'Collisionfixture benötigt bekannte synthetische Basis.',13;
SELECT @Version=CONVERT(nvarchar(64),@VersionRaw),@Mode=CONVERT(nvarchar(16),@ModeRaw);
IF @Case IN(N'FuturePublic',N'ImitatedFuturePublic',N'FutureInternal',N'ImitatedFutureInternal')
BEGIN
 IF CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0') THROW 51590,N'Futurefixture benötigt genuine1.0.',14;
 SET @FutureName=CASE WHEN @Case IN(N'FuturePublic',N'ImitatedFuturePublic') THEN N'TVF_InterpretXlsxCell' ELSE N'TVF_InternalInterpretXlsxCell' END;
 DECLARE @Create nvarchar(max)=N'CREATE FUNCTION toolbelt_file.'+QUOTENAME(@FutureName)+N'() RETURNS TABLE AS RETURN SELECT CONVERT(int,73) SyntheticValue;';
 EXEC sys.sp_executesql @Create;
 IF @Case IN(N'ImitatedFuturePublic',N'ImitatedFutureInternal')
 BEGIN
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.file.xlsx-memory',@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'FUNCTION',@level1name=@FutureName;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'FUNCTION',@level1name=@FutureName;
 END;
 SET @RestoreSql=N'DROP FUNCTION toolbelt_file.'+QUOTENAME(@FutureName)+N';';
END
ELSE IF @Case IN(N'VersionUnknown',N'VersionPadded')
BEGIN
 SET @Value=CASE WHEN @Case=N'VersionUnknown' THEN N'9.9.9' ELSE @Version+N' ' END;
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version',@value=@Value;
 SET @RestoreSql=N'EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.Module.toolbelt.file.xlsx-memory.Version'',@value=N'''+@Version+N''';';
END
ELSE IF @Case=N'ModePadded'
BEGIN
 SET @Value=@Mode+N' ';
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode',@value=@Value;
 SET @RestoreSql=N'EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode'',@value=N'''+@Mode+N''';';
END
ELSE IF @Case=N'MarkerPadded'
BEGIN
 SET @Value=@Version+N' ';
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'PROCEDURE',@level1name=N'USP_ListXlsxWorksheets';
 SET @RestoreSql=N'EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.ModuleVersion'',@value=N'''+@Version+N''',@level0type=N''SCHEMA'',@level0name=N''toolbelt_file'',@level1type=N''PROCEDURE'',@level1name=N''USP_ListXlsxWorksheets'';';
END
ELSE IF @Case=N'MarkerMissing'
BEGIN
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.ModuleId',@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'PROCEDURE',@level1name=N'USP_ListXlsxWorksheets';
 SET @RestoreSql=N'EXEC sys.sp_addextendedproperty @name=N''Toolbelt.ModuleId'',@value=N''toolbelt.file.xlsx-memory'',@level0type=N''SCHEMA'',@level0name=N''toolbelt_file'',@level1type=N''PROCEDURE'',@level1name=N''USP_ListXlsxWorksheets'';';
END
ELSE IF @Case=N'WrongType'
BEGIN
 DROP PROCEDURE toolbelt_file.USP_ListXlsxWorksheets;
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_file.USP_ListXlsxWorksheets() RETURNS int AS BEGIN RETURN 73; END;';
 -- Dieser letzte Fall benötigt ausschließlich Cleanup der eigenen Wegwerf-DB.
END
ELSE IF @Case=N'Dependency'
BEGIN
 EXEC sys.sp_executesql N'CREATE VIEW dbo.SyntheticXlsxDependency AS SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(NULL,NULL,NULL,NULL,NULL,NULL,NULL);';
 SET @Expected=51535;SET @RestoreSql=N'DROP VIEW dbo.SyntheticXlsxDependency;';
END
ELSE THROW 51590,N'Unbekannte synthetische Collisionklasse.',15;
SELECT @Expected ExpectedError,@RestoreSql RestoreSql;
GO
