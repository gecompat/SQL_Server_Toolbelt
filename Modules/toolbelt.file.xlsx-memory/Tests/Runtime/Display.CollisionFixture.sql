SET NOCOUNT ON;
-- Nur eigene synthetische Wegwerf-DB; Adapter vergleicht vor/nach dem abgewiesenen Lifecycle.
DECLARE @Case nvarchar(64)=N'$(FaultCase)',@VersionRaw nvarchar(max),@ModeRaw nvarchar(max),
 @Version nvarchar(64),@Mode nvarchar(16),@Value nvarchar(4000),@Expected int=51534,
 @RestoreSql nvarchar(max)=N'',@FutureName sysname;
SELECT @VersionRaw=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version';
SELECT @ModeRaw=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode';
IF @VersionRaw IS NULL OR CONVERT(varbinary(max),@VersionRaw) NOT IN(CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0'))
 OR @ModeRaw IS NULL OR CONVERT(varbinary(max),@ModeRaw) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
 THROW 51590,N'Collisionfixture benötigt bekannte synthetische Basis.',13;
SELECT @Version=CONVERT(nvarchar(64),@VersionRaw),@Mode=CONVERT(nvarchar(16),@ModeRaw);
IF @Case IN(N'FuturePublic',N'ImitatedFuturePublic',N'FutureInternal',N'ImitatedFutureInternal')
BEGIN
 SET @FutureName=CASE WHEN @Case IN(N'FuturePublic',N'ImitatedFuturePublic') THEN N'TVF_FormatXlsxCell' ELSE N'TVF_InternalFormatXlsxCell' END;
 DECLARE @Create nvarchar(max)=N'CREATE FUNCTION toolbelt_file.'+QUOTENAME(@FutureName)+N'() RETURNS TABLE AS RETURN SELECT CONVERT(int,73) SyntheticValue;';
 EXEC sys.sp_executesql @Create;
 IF @Case IN(N'ImitatedFuturePublic',N'ImitatedFutureInternal')
 BEGIN
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.file.xlsx-memory',@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'FUNCTION',@level1name=@FutureName;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'FUNCTION',@level1name=@FutureName;
 END;
 SET @RestoreSql=N'DROP FUNCTION toolbelt_file.'+QUOTENAME(@FutureName)+N';';
END
ELSE THROW 51590,N'Unknown display collision case.',15;
SELECT @Expected ExpectedError,@RestoreSql RestoreSql;
GO
