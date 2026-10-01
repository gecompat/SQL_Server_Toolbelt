-- ============================================================================
-- Objekt: toolbelt_file.USP_ListXlsxWorksheets
-- Typ: Stored Procedure
-- Zweck: Worksheetliste mit Workbook-Reihenfolge, Visibility und Date1904.
-- Vertrag: USP_CONTRACT 1.0; Documentation/USP_ListXlsxWorksheets.md
-- Parameter: @XlsxBinary varbinary(max)=NULL;
--   @MaxArchiveBytes bigint=16777216; @MaxPartBytes bigint=16777216;
--   @MaxTotalUncompressedBytes bigint=67108864; @MaxParts int=256;
--   @MaxSheets int=32; @MaxCells int=100000; @MaxSharedStrings int=50000;
--   @MaxSharedStringBytes bigint=8388608; @MaxXmlDepth int=64;
--   @MaxCompressionRatio decimal(18,4)=200; @BudgetMilliseconds int=5000;
--   @ResultTable sysname=NULL; @KeepData bit=0; @Debug tinyint=0; @Hilfe bit=0.
-- Resultset: SheetOrdinal int, SheetName nvarchar(max), Visibility nvarchar(16), Date1904 bit;
--   alle Spalten NOT NULL.
-- Dependencies: toolbelt.file.xlsx-memory 1.0.0 / SAFE CLR;
--   toolbelt.archive.zip-memory >=1.4.0; ResultTable-Helper >=1.0.0.
-- Rechte: EXECUTE auf USP; bei ResultTable zusätzlich Helper-EXECUTE.
-- Versionen: SQL Server 2019, 2022, 2025. Plattformen: Windows/Linux, SAFE CLR.
-- Fehlerverhalten: 51520 erwarteter Parser-/Input-/Limitfehler, 51529 Provider-/Dependencyfehler.
--   Keine Teilausgabe; Mutationsscope eigene Transaktion oder Caller-Savepoint.
--   Uncommittable Caller wird nicht zurückgerollt; ursprüngliche Enginefehler bleiben erhalten.
-- Performance: Input/Parts/gewählter Output werden materialisiert, keine Streaming- oder
--   SQL-Memory-Grant-Zusage. Reduzierbare Limits, kooperatives Budget, keine harte Wallclock.
-- Einschränkungen: Transitional XLSX, keine externen Beziehungen/ZIP64/Makros/Dateizugriffe,
--   Styles-/Datums-/Cultureinferenz oder Formelberechnung. NULL-Binary ist früher No-op.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_file.USP_ListXlsxWorksheets
(
    @XlsxBinary varbinary(max) = NULL,
    @MaxArchiveBytes bigint = 16777216,
    @MaxPartBytes bigint = 16777216,
    @MaxTotalUncompressedBytes bigint = 67108864,
    @MaxParts int = 256,
    @MaxSheets int = 32,
    @MaxCells int = 100000,
    @MaxSharedStrings int = 50000,
    @MaxSharedStringBytes bigint = 8388608,
    @MaxXmlDepth int = 64,
    @MaxCompressionRatio decimal(18,4) = 200,
    @BudgetMilliseconds int = 5000,
    @ResultTable sysname = NULL,
    @KeepData bit = 0,
    @Debug tinyint = 0,
    @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        DECLARE @Help TABLE
        (Section varchar(32) NOT NULL, Ordinal int NOT NULL, ItemName sysname NULL,
         SqlDataType varchar(256) NULL, IsRequired bit NULL, IsNullable bit NULL,
         DefaultValue nvarchar(4000) NULL, Description nvarchar(max) NOT NULL, ExampleSql nvarchar(max) NULL);
        INSERT @Help VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.',NULL),
        ('PARAMETER',1,N'@XlsxBinary','varbinary(max)',0,1,N'NULL',N'NULL liefert keine Zeilen und verändert kein ResultTable.',NULL),
        ('PARAMETER',2,N'@MaxArchiveBytes','bigint',0,0,N'16777216',N'Containerbytes, höchstens 16 MiB.',NULL),
        ('PARAMETER',3,N'@MaxPartBytes','bigint',0,0,N'16777216',N'Unkomprimierte Bytes je Part, höchstens 16 MiB.',NULL),
        ('PARAMETER',4,N'@MaxTotalUncompressedBytes','bigint',0,0,N'67108864',N'Deklarierte Gesamtbytes, höchstens 64 MiB.',NULL),
        ('PARAMETER',5,N'@MaxParts','int',0,0,N'256',N'ZIP-Parts, höchstens 256.',NULL),
        ('PARAMETER',6,N'@MaxSheets','int',0,0,N'32',N'Worksheets, höchstens 32.',NULL),
        ('PARAMETER',7,N'@MaxCells','int',0,0,N'100000',N'Vorhandene Zellen im gewählten Sheet, höchstens 100000.',NULL),
        ('PARAMETER',8,N'@MaxSharedStrings','int',0,0,N'50000',N'Shared Strings, höchstens 50000.',NULL),
        ('PARAMETER',9,N'@MaxSharedStringBytes','bigint',0,0,N'8388608',N'Dekodierter Shared-String-UTF16-Text, höchstens 8 MiB.',NULL),
        ('PARAMETER',10,N'@MaxXmlDepth','int',0,0,N'64',N'XML-Tiefe, höchstens 64.',NULL),
        ('PARAMETER',11,N'@MaxCompressionRatio','decimal(18,4)',0,0,N'200',N'Maximales deklarierter Ratio, höchstens 200.',NULL),
        ('PARAMETER',12,N'@BudgetMilliseconds','int',0,0,N'5000',N'Kooperatives Gesamtbudget, höchstens 5000 ms; keine harte Wallclockzusage.',NULL),
        ('PARAMETER',13,N'@ResultTable','sysname',0,1,N'NULL',N'Vorhandene caller-lokale Temp-Tabelle, sonst SELECT.',NULL),
        ('PARAMETER',14,N'@KeepData','bit',0,1,N'0',N'Replace 0 oder Append 1; NULL entspricht 0.',NULL),
        ('PARAMETER',15,N'@Debug','tinyint',0,1,N'0',N'Nur Messages ohne Workbookinhalte.',NULL),
        ('PARAMETER',16,N'@Hilfe','bit',0,1,N'0',N'Ausschließlich standardisierte Hilfe.',NULL),
        ('RESULT_COLUMN',1,N'SheetOrdinal','int',1,0,NULL,N'Einsbasierte Workbook-Reihenfolge.',NULL),
        ('RESULT_COLUMN',2,N'SheetName','nvarchar(max)',1,0,NULL,N'Unveränderter Worksheetname.',NULL),
        ('RESULT_COLUMN',3,N'Visibility','nvarchar(16)',1,0,NULL,N'visible, hidden oder veryHidden.',NULL),
        ('RESULT_COLUMN',4,N'Date1904','bit',1,0,NULL,N'Workbook-Datumsmodus; keine Datumsumrechnung.',NULL),
        ('ERROR',1,N'51520',NULL,NULL,NULL,NULL,N'Begrenzte Kategorie eines erwarteten Input-/Container-/XML-/Feature-/Ressourcenfehlers; keine Teilausgabe.',NULL),
        ('ERROR',2,N'51529',NULL,NULL,NULL,NULL,N'Fehlende oder inkonsistente registrierte Dependency bzw. interner Providervertrag.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE auf USP; ResultTable zusätzlich Helper-EXECUTE und Sichtbarkeit der caller-lokalen Tabelle. Keine Rechteausweitung.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Transitional XLSX, klassische Stored-/Deflate-ZIPs. Kein ZIP64, externe Beziehungen, Makros oder Strict Open XML. Unicode bleibt unverändert, Tabellen brauchen explizite Ordinals zum Sortieren.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hilfe ohne fachliche Eingaben.',N'EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;');
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_file' AS sysname) AS SchemaName,
               CAST(N'USP_ListXlsxWorksheets' AS sysname) AS ObjectName,
               Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
           WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5
           WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
        RETURN 0;
    END;
    -- NULL und Namespaceprüfung liegen vor der separaten Compilergrenze.
    IF @XlsxBinary IS NULL
    BEGIN
        -- Tablevariable hält auch bei null Zeilen die genaue Result-Nullability;
        -- keine private Temptabelle oder fachliche Core-Kompilierung entsteht.
        DECLARE @Empty TABLE ([SheetOrdinal] int NOT NULL,[SheetName] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,[Visibility] nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,[Date1904] bit NOT NULL);
        IF @ResultTable IS NULL SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM @Empty;
        RETURN 0;
    END;
    IF (@ResultTable IS NOT NULL AND LOWER(LEFT(@ResultTable COLLATE Latin1_General_100_BIN2,5))=N'#tbx_')
       OR OBJECT_ID(N'tempdb..#tbx_ListXlsxWorksheets_ResultSource') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_ReadXlsxWorksheetCells_ResultSource') IS NOT NULL
        THROW 51520,N'Reservierter interner XLSX-Tempnamensbereich.',1;
    -- Fachliche Tempstatements werden erst hinter dieser EXEC-Grenze kompiliert.
    EXEC toolbelt_file.USP_InternalXlsxRead @ReadCells=0,
         @XlsxBinary=@XlsxBinary,
         @MaxArchiveBytes=@MaxArchiveBytes,
         @MaxPartBytes=@MaxPartBytes,
         @MaxTotalUncompressedBytes=@MaxTotalUncompressedBytes,
         @MaxParts=@MaxParts,
         @MaxSheets=@MaxSheets,
         @MaxCells=@MaxCells,
         @MaxSharedStrings=@MaxSharedStrings,
         @MaxSharedStringBytes=@MaxSharedStringBytes,
         @MaxXmlDepth=@MaxXmlDepth,
         @MaxCompressionRatio=@MaxCompressionRatio,
         @BudgetMilliseconds=@BudgetMilliseconds,
         @ResultTable=@ResultTable,
         @KeepData=@KeepData,
         @Debug=@Debug,@SheetOrdinal=NULL;
    RETURN 0;
END;
GO

