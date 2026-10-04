SET NOCOUNT ON;
DECLARE @Expected TABLE(Name sysname,Ordinal int,ParamName sysname,TypeId int,MaxLength int,PrecisionValue int,ScaleValue int);
INSERT @Expected VALUES
(N'USP_CreateZipFileFromEntries',1,N'@EntryTable',231,256,0,0),
(N'USP_CreateZipFileFromEntries',2,N'@RootAlias',231,256,0,0),
(N'USP_CreateZipFileFromEntries',3,N'@RelativePath',231,8000,0,0),
(N'USP_CreateZipFileFromEntries',4,N'@CompressionMethod',167,-1,0,0),
(N'USP_CreateZipFileFromEntries',5,N'@MaxEntries',56,4,0,0),
(N'USP_CreateZipFileFromEntries',6,N'@MaxEntryNameCodeUnits',56,4,0,0),
(N'USP_CreateZipFileFromEntries',7,N'@MaxEntryBytes',127,8,0,0),
(N'USP_CreateZipFileFromEntries',8,N'@MaxTotalPayloadBytes',127,8,0,0),
(N'USP_CreateZipFileFromEntries',9,N'@MaxArchiveBytes',127,8,0,0),
(N'USP_CreateZipFileFromEntries',10,N'@MaxEnvelopeBytes',127,8,0,0),
(N'USP_CreateZipFileFromEntries',11,N'@WriterBudgetMilliseconds',56,4,0,0),
(N'USP_CreateZipFileFromEntries',12,N'@Overwrite',104,1,0,0),
(N'USP_CreateZipFileFromEntries',13,N'@ExecutionIdentity',167,16,0,0),
(N'USP_CreateZipFileFromEntries',14,N'@ResultTable',231,256,0,0),
(N'USP_CreateZipFileFromEntries',15,N'@KeepData',104,1,0,0),
(N'USP_CreateZipFileFromEntries',16,N'@Debug',48,1,0,0),
(N'USP_CreateZipFileFromEntries',17,N'@Hilfe',104,1,0,0),
(N'USP_ExtractZipEntryToFile',1,N'@ZipArchive',165,-1,0,0),
(N'USP_ExtractZipEntryToFile',2,N'@EntryName',231,2048,0,0),
(N'USP_ExtractZipEntryToFile',3,N'@RootAlias',231,256,0,0),
(N'USP_ExtractZipEntryToFile',4,N'@RelativePath',231,8000,0,0),
(N'USP_ExtractZipEntryToFile',5,N'@MaxEntryBytes',127,8,0,0),
(N'USP_ExtractZipEntryToFile',6,N'@MaxCompressionRatio',106,5,9,2),
(N'USP_ExtractZipEntryToFile',7,N'@Overwrite',104,1,0,0),
(N'USP_ExtractZipEntryToFile',8,N'@ExecutionIdentity',167,16,0,0),
(N'USP_ExtractZipEntryToFile',9,N'@ResultTable',231,256,0,0),
(N'USP_ExtractZipEntryToFile',10,N'@KeepData',104,1,0,0),
(N'USP_ExtractZipEntryToFile',11,N'@Debug',48,1,0,0),
(N'USP_ExtractZipEntryToFile',12,N'@Hilfe',104,1,0,0);
IF EXISTS(SELECT 1 FROM @Expected e LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_archive') AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),e.Name)
   LEFT JOIN sys.parameters p ON p.object_id=o.object_id AND p.parameter_id=e.Ordinal
   WHERE o.object_id IS NULL OR o.type<>N'P' OR p.parameter_id IS NULL
      OR CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),e.ParamName)
      OR p.system_type_id<>e.TypeId OR p.max_length<>e.MaxLength OR p.is_output<>0
      OR (e.TypeId=106 AND (p.precision<>e.PrecisionValue OR p.scale<>e.ScaleValue)))
   OR EXISTS(SELECT 1 FROM (VALUES(N'USP_CreateZipFileFromEntries',17),(N'USP_ExtractZipEntryToFile',12)) x(Name,CountValue)
      WHERE (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_archive.'+QUOTENAME(x.Name)) AND parameter_id>0)<>x.CountValue)
    THROW 54690,N'ZIP_FILES_INSTALLED_METADATA',1;
IF EXISTS(SELECT 1 FROM (VALUES(N'USP_CreateZipFileFromEntries'),(N'USP_ExtractZipEntryToFile')) x(Name)
    WHERE NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE d.referencing_id=OBJECT_ID(N'toolbelt_archive.'+QUOTENAME(x.Name)) AND d.referenced_id=OBJECT_ID(N'toolbelt_filesystem.USP_WriteBinaryFile')))
    THROW 54690,N'ZIP_FILES_STATIC_FILESYSTEM_CONSUMER',1;
IF NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'toolbelt_archive.USP_CreateZipFileFromEntries') AND referenced_id=OBJECT_ID(N'toolbelt_archive.USP_CreateZipFromEntries'))
   OR NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryToFile') AND referenced_id=OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary'))
    THROW 54690,N'ZIP_FILES_STATIC_ZIP_CONSUMER',1;
IF EXISTS(SELECT 1 FROM (VALUES(N'USP_CreateZipFileFromEntries'),(N'USP_ExtractZipEntryToFile')) x(Name)
    CROSS JOIN (VALUES(N'Toolbelt.ModuleId',N'toolbelt.archive.zip-files'),(N'Toolbelt.ModuleVersion',N'1.0.0'),(N'Toolbelt.ContractVersion',N'1.0'),(N'Toolbelt.DeploymentMode',N'local')) p(Name,Value)
    WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(N'toolbelt_archive.'+QUOTENAME(x.Name)) AND e.minor_id=0
        AND CONVERT(varbinary(max),e.name)=CONVERT(varbinary(max),p.Name) AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),p.Value)))
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-files.Version' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'1.0.0'))
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-files.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'local'))
    THROW 54690,N'ZIP_FILES_INSTALLED_MARKERS',1;
PRINT N'PASS ZIP_FILES_INSTALLED_METADATA';
GO
