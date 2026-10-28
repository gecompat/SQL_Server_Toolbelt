-- Synthetic assertions composed before the unchanged SST boundary result.
SET NOCOUNT ON;
DECLARE @Help TABLE
(
 HelpContractVersion varchar(16) NOT NULL, SchemaName sysname NOT NULL,
 ObjectName sysname NOT NULL, Section varchar(32) NOT NULL, Ordinal int NOT NULL,
 ItemName sysname NULL, SqlDataType varchar(256) NULL, IsRequired bit NULL,
 IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max) NOT NULL, ExampleSql nvarchar(max) NULL
);
INSERT @Help EXEC toolbelt_file.USP_ListXlsxWorksheets
 @Hilfe=1,@ResultTable=N'not-a-local-temp-table',@KeepData=1,@Debug=255;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE Section='EXAMPLE' AND ExampleSql IS NOT NULL
 AND ExampleSql NOT LIKE N'%@Hilfe%')
 THROW 52097,N'List XLSX requires a functional example.',31;
IF EXISTS(SELECT 1 FROM @Help WHERE ObjectName<>N'USP_ListXlsxWorksheets')
 THROW 52097,N'List XLSX help identity differs.',32;
DELETE @Help;
INSERT @Help EXEC toolbelt_file.USP_ReadXlsxWorksheetCells
 @Hilfe=1,@ResultTable=N'not-a-local-temp-table',@KeepData=1,@Debug=255;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE Section='EXAMPLE' AND ExampleSql IS NOT NULL
 AND ExampleSql NOT LIKE N'%@Hilfe%')
 THROW 52097,N'Read XLSX requires a functional example.',33;
IF EXISTS(SELECT 1 FROM @Help WHERE ObjectName<>N'USP_ReadXlsxWorksheetCells')
 THROW 52097,N'Read XLSX help identity differs.',34;
IF EXISTS
(
 SELECT name FROM (VALUES(N'TVF_InterpretXlsxCell'),(N'TVF_FormatXlsxCell')) AS n(name)
 WHERE NOT EXISTS
 (
  SELECT 1 FROM sys.sql_modules AS m
  WHERE m.object_id=OBJECT_ID(N'toolbelt_file.'+n.name,N'IF')
    AND m.definition LIKE N'%-- Zweck:%'
    AND m.definition LIKE N'%-- Beispiel:%'
    AND m.definition LIKE N'%-- Parameter:%'
 )
)
 THROW 52097,N'Cell TVF help must remain in its stored DDL.',35;
