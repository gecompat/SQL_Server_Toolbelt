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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_file' AS sysname) AS SchemaName,
            CAST(N'USP_ListXlsxWorksheets' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'SheetOrdinal', N'int', 1, 0, NULL, CAST(N'Einsbasierte Workbook-Reihenfolge.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'SheetName', N'nvarchar(max)', 1, 0, NULL, CAST(N'Unveränderter Worksheetname.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Visibility', N'nvarchar(16)', 1, 0, NULL, CAST(N'visible, hidden oder veryHidden.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'Date1904', N'bit', 1, 0, NULL, CAST(N'Workbook-Datumsmodus; keine Datumsumrechnung.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51520', NULL, NULL, NULL, NULL, CAST(N'Begrenzte Kategorie eines erwarteten Input-/Container-/XML-/Feature-/Ressourcenfehlers; keine Teilausgabe.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'51529', NULL, NULL, NULL, NULL, CAST(N'Fehlende oder inkonsistente registrierte Dependency bzw. interner Providervertrag.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE auf USP; ResultTable zusätzlich Helper-EXECUTE und Sichtbarkeit der caller-lokalen Tabelle. Keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Transitional XLSX, klassische Stored-/Deflate-ZIPs. Kein ZIP64, externe Beziehungen, Makros oder Strict Open XML. Unicode bleibt unverändert, Tabellen brauchen explizite Ordinals zum Sortieren.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Listet die Sheets eines vom Caller bereitgestellten synthetischen XLSX-Binarys.' AS nvarchar(max)), CAST(N'EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@SyntheticWorkbook;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@XlsxBinary', N'varbinary(max)', 0, 1, N'NULL', CAST(N'Vollständiger XLSX-Bytepuffer varbinary(max), kein Pfad/Base64text. Unterstützt Transitional-XLSX mit kanonischen Stored-/Deflate-ZIP-Parts, sicheren lokalen Relationships und XML ohne DTD/externe Auflösung; keine XLS/XLSB-/verschlüsselten Workbooks oder Makroausführung. Leer ist ungültig. NULL (Default) liefert keine Zeilen vor Sheet-/Limit-/Dependency-/Zielprüfung und lässt ResultTable unverändert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@MaxArchiveBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxPartBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxTotalUncompressedBytes', N'bigint', 0, 0, N'67108864', CAST(N'Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxParts', N'int', 0, 0, N'256', CAST(N'Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxSheets', N'int', 0, 0, N'32', CAST(N'Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxCells', N'int', 0, 0, N'100000', CAST(N'Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxSharedStrings', N'int', 0, 0, N'50000', CAST(N'Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@MaxSharedStringBytes', N'bigint', 0, 0, N'8388608', CAST(N'Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@MaxXmlDepth', N'int', 0, 0, N'64', CAST(N'Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@MaxCompressionRatio', N'decimal(18,4)', 0, 0, N'200', CAST(N'decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@BudgetMilliseconds', N'int', 0, 0, N'5000', CAST(N'Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 14, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 15, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 16, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
