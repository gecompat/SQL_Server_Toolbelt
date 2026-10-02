SET NOCOUNT ON;
-- Ausschließlich eigene synthetische Wegwerf-DB. Adapter prüft Fehler + unveränderten Snapshot.
DECLARE @Case nvarchar(64)=N'$(FaultCase)',@RestoreSql nvarchar(max)=N'',@Expected int,
 @RawVersion nvarchar(max),@RawMode nvarchar(max),@Version nvarchar(64),@Mode nvarchar(16),@Sql nvarchar(4000),@FutureName sysname;
SELECT @RawVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version';
SELECT @RawMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';
IF @RawVersion IS NULL OR @RawMode IS NULL
 OR CONVERT(varbinary(max),@RawVersion) NOT IN(CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0'))
 OR CONVERT(varbinary(max),@RawMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
 THROW 54600,N'JSON collision: bekannte synthetische Basis erforderlich.',50;
SET @Version=CONVERT(nvarchar(64),@RawVersion);
SET @Mode=CONVERT(nvarchar(16),@RawMode);
IF @Case IN(N'FutureSlot',N'ImitatedFutureSlot',N'ObjectFutureSlot',N'ObjectImitatedFutureSlot')
BEGIN
 IF CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0')
  THROW 54600,N'JSON collision: echter historischer Scope erforderlich.',51;
 SET @FutureName=CASE WHEN @Case IN(N'ObjectFutureSlot',N'ObjectImitatedFutureSlot') THEN N'USP_JsonObjectsByGroup' ELSE N'USP_JsonArraysByGroup' END;
 SET @Sql=N'CREATE PROCEDURE toolbelt_json.'+QUOTENAME(@FutureName)+N' AS SELECT CONVERT(int,1) GroupOrdinal,CONVERT(nvarchar(max),N''["Contoso"]'') JsonValue;';
 EXEC sys.sp_executesql @Sql;
 IF @Case IN(N'ImitatedFutureSlot',N'ObjectImitatedFutureSlot')
 BEGIN
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.json.constructors',@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=N'PROCEDURE',@level1name=@FutureName;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=N'PROCEDURE',@level1name=@FutureName;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.DeploymentMode',@value=@Mode,@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=N'PROCEDURE',@level1name=@FutureName;
 END;
 SET @Expected=53624;SET @RestoreSql=N'DROP PROCEDURE toolbelt_json.'+QUOTENAME(@FutureName)+N';';
END
ELSE IF @Case IN(N'VersionUnknown',N'VersionPadded')
BEGIN
 SET @Sql=CASE WHEN @Case=N'VersionUnknown' THEN N'9.9.9' ELSE @Version+N' ' END;
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.Version',@value=@Sql;
 SET @Expected=53623;SET @RestoreSql=N'EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.Module.toolbelt.json.constructors.Version'',@value=N'''+REPLACE(@Version,N'''',N'''''')+N''';';
END
ELSE IF @Case=N'ModePadded'
BEGIN
 SET @Sql=@Mode+N' ';
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode',@value=@Sql;
 SET @Expected=53623;SET @RestoreSql=N'EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.Module.toolbelt.json.constructors.DeploymentMode'',@value=N'''+REPLACE(@Mode,N'''',N'''''')+N''';';
END
ELSE IF @Case=N'MarkerPadded'
BEGIN
 SET @Sql=@Version+N' ';
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Sql,@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=N'PROCEDURE',@level1name=N'USP_JsonArray';
 SET @Expected=53623;SET @RestoreSql=N'EXEC sys.sp_updateextendedproperty @name=N''Toolbelt.ModuleVersion'',@value=N'''+REPLACE(@Version,N'''',N'''''')+N''',@level0type=N''SCHEMA'',@level0name=N''toolbelt_json'',@level1type=N''PROCEDURE'',@level1name=N''USP_JsonArray'';';
END
ELSE IF @Case=N'MarkerMissing'
BEGIN
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.ModuleId',@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=N'PROCEDURE',@level1name=N'USP_JsonArray';
 SET @Expected=53623;SET @RestoreSql=N'EXEC sys.sp_addextendedproperty @name=N''Toolbelt.ModuleId'',@value=N''toolbelt.json.constructors'',@level0type=N''SCHEMA'',@level0name=N''toolbelt_json'',@level1type=N''PROCEDURE'',@level1name=N''USP_JsonArray'';';
END
ELSE IF @Case=N'WrongType'
BEGIN
 -- Dieser Fall wird ausschließlich durch Auflösen seiner eigenen Wegwerf-DB bereinigt.
 DROP PROCEDURE toolbelt_json.USP_JsonArray;
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_json.USP_JsonArray() RETURNS int AS BEGIN RETURN 73; END;';
 SET @Expected=53623;
END
ELSE IF @Case=N'Dependency'
BEGIN
 EXEC sys.sp_executesql N'CREATE PROCEDURE dbo.SyntheticJsonDependency AS EXEC toolbelt_json.USP_JsonArray @Hilfe=1;';
 SET @Expected=53626;SET @RestoreSql=N'DROP PROCEDURE dbo.SyntheticJsonDependency;';
END
ELSE THROW 54600,N'JSON collision: unbekannter synthetischer Fall.',52;
SELECT @Expected ExpectedError,@RestoreSql RestoreSql;
