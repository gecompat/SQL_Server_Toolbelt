DECLARE @ExpectedApiCount int=2;
INSERT @Apis VALUES
(1,N'toolbelt_file',N'TVF_InterpretXlsxCell','SELECT',N'SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(NULL,NULL,NULL,NULL,NULL,NULL,NULL);',N'DECLARE @BeforeTc int=@@TRANCOUNT,@BeforeXs int=XACT_STATE();
CREATE TABLE #ContosoTyped(Id int PRIMARY KEY,StoredType nvarchar(32),ValuePresent bit,RawValue nvarchar(max),
 TextValue nvarchar(max),EchoPreserved bit,ResolvedType nvarchar(16),NumberValue sql_variant,BooleanValue bit,
 DateValue date,DateTimeValue datetime2(7),TimeValue time(7),DurationTicks bigint,TypedTextValue nvarchar(max),StatusCode int);
INSERT #ContosoTyped SELECT 1,* FROM toolbelt_file.TVF_InterpretXlsxCell(N''n'',1,N''42.5'',NULL,N''number'',NULL,NULL);
INSERT #ContosoTyped SELECT 2,* FROM toolbelt_file.TVF_InterpretXlsxCell(N''n'',1,N''61'',NULL,N''date'',NULL,0);
INSERT #ContosoTyped SELECT 3,* FROM toolbelt_file.TVF_InterpretXlsxCell(N''b'',1,N''1'',NULL,N''boolean'',NULL,NULL);
DECLARE @ExpectedNumber decimal(38,10)=42.5;
IF (SELECT COUNT(*) FROM #ContosoTyped)<>3 OR EXISTS(SELECT 1 FROM #ContosoTyped a
 WHERE a.StoredType IS NULL OR CONVERT(varbinary(max),a.StoredType)<>CONVERT(varbinary(max),CASE a.Id WHEN 3 THEN N''b'' ELSE N''n'' END)
 OR ISNULL(a.ValuePresent,0)<>1 OR a.RawValue IS NULL
 OR CONVERT(varbinary(max),a.RawValue)<>CONVERT(varbinary(max),CASE a.Id WHEN 1 THEN N''42.5'' WHEN 2 THEN N''61'' ELSE N''1'' END)
 OR a.TextValue IS NOT NULL OR ISNULL(a.EchoPreserved,0)<>1 OR a.ResolvedType IS NULL
 OR CONVERT(varbinary(max),a.ResolvedType)<>CONVERT(varbinary(max),CASE a.Id WHEN 1 THEN N''number'' WHEN 2 THEN N''date'' ELSE N''boolean'' END)
 OR a.StatusCode IS NULL OR a.StatusCode<>0
 OR (a.Id=1 AND (a.NumberValue IS NULL OR CONVERT(nvarchar(32),SQL_VARIANT_PROPERTY(a.NumberValue,''BaseType'')) NOT IN(N''decimal'',N''numeric'')
  OR CONVERT(int,SQL_VARIANT_PROPERTY(a.NumberValue,''Precision'')) NOT BETWEEN 1 AND 38
  OR CONVERT(decimal(38,10),a.NumberValue)<>@ExpectedNumber))
 OR (a.Id<>1 AND a.NumberValue IS NOT NULL)
 OR (a.Id=2 AND (a.DateValue IS NULL OR a.DateValue<>CONVERT(date,''19000301'',112)))
 OR (a.Id<>2 AND a.DateValue IS NOT NULL)
 OR (a.Id=3 AND ISNULL(a.BooleanValue,0)<>1) OR (a.Id<>3 AND a.BooleanValue IS NOT NULL)
 OR a.DateTimeValue IS NOT NULL OR a.TimeValue IS NOT NULL OR a.DurationTicks IS NOT NULL OR a.TypedTextValue IS NOT NULL)
 THROW 52097,N''XLSX fixed interpretation oracle failed.'',21;
DECLARE @AfterTc int=@@TRANCOUNT,@AfterXs int=XACT_STATE();
IF @BeforeTc<>@AfterTc OR @BeforeXs<>@AfterXs THROW 52097,N''XLSX interpretation transaction state changed.'',22;'),
(2,N'toolbelt_file',N'TVF_FormatXlsxCell','SELECT',N'SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);',N'DECLARE @BeforeTc int=@@TRANCOUNT,@BeforeXs int=XACT_STATE();
CREATE TABLE #ContosoDisplay(Id int PRIMARY KEY,DisplayText nvarchar(max),StatusCode int NOT NULL);
INSERT #ContosoDisplay SELECT 1,* FROM toolbelt_file.TVF_FormatXlsxCell(N''n'',1,N''1.235'',NULL,N''number'',N''0.00'',NULL,N''en-US'');
INSERT #ContosoDisplay SELECT 2,* FROM toolbelt_file.TVF_FormatXlsxCell(N''n'',1,N''-1.235'',NULL,N''number'',N''0.00'',NULL,N''de-DE'');
INSERT #ContosoDisplay SELECT 3,* FROM toolbelt_file.TVF_FormatXlsxCell(N''n'',1,N''60'',NULL,N''date'',N''yyyy-mm-dd'',0,N''en-US'');
IF (SELECT COUNT(*) FROM #ContosoDisplay)<>3 OR EXISTS(SELECT 1 FROM #ContosoDisplay a
 WHERE (a.Id IN(1,2) AND (a.StatusCode<>0 OR a.DisplayText IS NULL
  OR CONVERT(varbinary(max),a.DisplayText)<>CONVERT(varbinary(max),CASE a.Id WHEN 1 THEN N''1.24'' ELSE N''-1,24'' END)))
 OR (a.Id=3 AND (a.StatusCode<>7 OR a.DisplayText IS NOT NULL)))
 THROW 52097,N''XLSX fixed display oracle failed.'',23;
DECLARE @AfterTc int=@@TRANCOUNT,@AfterXs int=XACT_STATE();
IF @BeforeTc<>@AfterTc OR @BeforeXs<>@AfterXs THROW 52097,N''XLSX display transaction state changed.'',24;');
INSERT @Denied VALUES
(1,N'toolbelt_file',N'TVF_InternalXlsxSheets','SELECT',N'SELECT * FROM toolbelt_file.TVF_InternalXlsxSheets(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);'),
(2,N'toolbelt_file',N'TVF_InternalXlsxCells','SELECT',N'SELECT * FROM toolbelt_file.TVF_InternalXlsxCells(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);'),
(3,N'toolbelt_file',N'TVF_InternalInterpretXlsxCell','SELECT',N'SELECT * FROM toolbelt_file.TVF_InternalInterpretXlsxCell(NULL,NULL,NULL,NULL,NULL,NULL,NULL);'),
(4,N'toolbelt_file',N'TVF_InternalFormatXlsxCell','SELECT',N'SELECT * FROM toolbelt_file.TVF_InternalFormatXlsxCell(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);'),
(5,N'toolbelt_file',N'USP_ListXlsxWorksheets','EXECUTE',N'EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;'),
(6,N'toolbelt_file',N'USP_ReadXlsxWorksheetCells','EXECUTE',N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;'),
(7,N'toolbelt_file',N'USP_InternalXlsxRead','EXECUTE',N'EXEC toolbelt_file.USP_InternalXlsxRead @Hilfe=1;'),
(8,N'toolbelt_archive',N'USP_CreateZipFromEntries','EXECUTE',N'EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;'),
(9,N'toolbelt_archive',N'USP_ExtractZipEntryFromBinary','EXECUTE',N'EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;'),
(10,N'toolbelt_archive',N'USP_ListZipEntriesFromBinary','EXECUTE',N'EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @Hilfe=1;'),
(11,N'toolbelt_core',N'USP_PrepareResultTable','EXECUTE',N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;');
