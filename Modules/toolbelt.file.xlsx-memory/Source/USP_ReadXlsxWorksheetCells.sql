-- ============================================================================
-- Objekt: toolbelt_file.USP_ReadXlsxWorksheetCells
-- Typ: Stored Procedure
-- Zweck: Sparse vorhandene Zellen mit Rohtext, aufgelöstem Stringtext, Formel und Cache.
-- Vertrag: USP_CONTRACT 1.0; Documentation/USP_ReadXlsxWorksheetCells.md
-- Parameter: @XlsxBinary varbinary(max)=NULL, @SheetOrdinal int=NULL;
--   @MaxArchiveBytes bigint=16777216; @MaxPartBytes bigint=16777216;
--   @MaxTotalUncompressedBytes bigint=67108864; @MaxParts int=256;
--   @MaxSheets int=32; @MaxCells int=100000; @MaxSharedStrings int=50000;
--   @MaxSharedStringBytes bigint=8388608; @MaxXmlDepth int=64;
--   @MaxCompressionRatio decimal(18,4)=200; @BudgetMilliseconds int=5000;
--   @ResultTable sysname=NULL; @KeepData bit=0; @Debug tinyint=0; @Hilfe bit=0.
-- Resultset: RowOrdinal int, ColumnOrdinal int, StoredType nvarchar(16), ValuePresent bit,
--   RawValue/TextValue nvarchar(max) NULL, FormulaPresent bit, FormulaText nvarchar(max) NULL,
--   FormulaKind nvarchar(16) NULL, SharedFormulaIndex int NULL, CachePresent bit,
--   CacheValue nvarchar(max) NULL; übrige Spalten NOT NULL.
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
CREATE OR ALTER PROCEDURE toolbelt_file.USP_ReadXlsxWorksheetCells
(
    @XlsxBinary varbinary(max) = NULL,
    @SheetOrdinal int = NULL,
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
            CAST(N'USP_ReadXlsxWorksheetCells' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'RowOrdinal', N'int', 1, 0, NULL, CAST(N'Einsbasierte Zeile.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ColumnOrdinal', N'int', 1, 0, NULL, CAST(N'Einsbasierte Spalte.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'StoredType', N'nvarchar(16)', 1, 0, NULL, CAST(N'Gespeicherter Zelltyp, keine Typinferenz.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ValuePresent', N'bit', 1, 0, NULL, CAST(N'Gespeichertes v-Element vorhanden, auch wenn leer.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'RawValue', N'nvarchar(max)', 1, 1, NULL, CAST(N'Rohtext aus v, NULL bei fehlendem v.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'TextValue', N'nvarchar(max)', 1, 1, NULL, CAST(N'Shared-/Inline-/str-Text, kein Excel-Anzeigeformat.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'FormulaPresent', N'bit', 1, 0, NULL, CAST(N'f-Element vorhanden.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'FormulaText', N'nvarchar(max)', 1, 1, NULL, CAST(N'Unveränderter Formeltext, keine Berechnung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'FormulaKind', N'nvarchar(16)', 1, 1, NULL, CAST(N'normal, shared, array oder dataTable.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'SharedFormulaIndex', N'int', 1, 1, NULL, CAST(N'Gespeichertes si, keine Formelrekonstruktion.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'CachePresent', N'bit', 1, 0, NULL, CAST(N'Formel und v-Element vorhanden.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'CacheValue', N'nvarchar(max)', 1, 1, NULL, CAST(N'Gespeicherter Formelcache-Rohtext.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51520', NULL, NULL, NULL, NULL, CAST(N'Begrenzte Kategorie eines erwarteten Input-/Container-/XML-/Feature-/Ressourcenfehlers; keine Teilausgabe.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'51529', NULL, NULL, NULL, NULL, CAST(N'Fehlende oder inkonsistente registrierte Dependency bzw. interner Providervertrag.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE auf USP; ResultTable zusätzlich Helper-EXECUTE und Sichtbarkeit der caller-lokalen Tabelle. Keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Transitional XLSX, klassische Stored-/Deflate-ZIPs. Kein ZIP64, externe Beziehungen, Makros oder Strict Open XML. Unicode bleibt unverändert, Tabellen brauchen explizite Ordinals zum Sortieren.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest sparse Zellen aus Sheet 1 eines vom Caller bereitgestellten synthetischen XLSX-Binarys.' AS nvarchar(max)), CAST(N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@SyntheticWorkbook,@SheetOrdinal=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@XlsxBinary', N'varbinary(max)', 0, 1, N'NULL', CAST(N'Vollständiger XLSX-Bytepuffer varbinary(max), kein Pfad/Base64text. Unterstützt Transitional-XLSX mit kanonischen Stored-/Deflate-ZIP-Parts, sicheren lokalen Relationships und XML ohne DTD/externe Auflösung; keine XLS/XLSB-/verschlüsselten Workbooks oder Makroausführung. Leer ist ungültig. NULL (Default) liefert keine Zeilen vor Sheet-/Limit-/Dependency-/Zielprüfung und lässt ResultTable unverändert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@SheetOrdinal', N'int', 1, 0, N'NULL', CAST(N'Fachlich erforderliche positive int-Worksheetnummer aus USP_ListXlsxWorksheets, 1-basiert in Workbookreihenfolge; keine SheetId, kein Name und keine nullbasierte Position. Muss tatsächlich existieren. NULL (technischer Default)/0/negativ ungültig bei nicht-NULL-XlsxBinary; bei NULL-Binary ignoriert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxArchiveBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxPartBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxTotalUncompressedBytes', N'bigint', 0, 0, N'67108864', CAST(N'Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxParts', N'int', 0, 0, N'256', CAST(N'Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxSheets', N'int', 0, 0, N'32', CAST(N'Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxCells', N'int', 0, 0, N'100000', CAST(N'Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@MaxSharedStrings', N'int', 0, 0, N'50000', CAST(N'Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@MaxSharedStringBytes', N'bigint', 0, 0, N'8388608', CAST(N'Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@MaxXmlDepth', N'int', 0, 0, N'64', CAST(N'Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@MaxCompressionRatio', N'decimal(18,4)', 0, 0, N'200', CAST(N'decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@BudgetMilliseconds', N'int', 0, 0, N'5000', CAST(N'Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 14, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 15, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 16, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 17, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
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
        DECLARE @Empty TABLE ([RowOrdinal] int NOT NULL,[ColumnOrdinal] int NOT NULL,[StoredType] nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,[ValuePresent] bit NOT NULL,[RawValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,[TextValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,[FormulaPresent] bit NOT NULL,[FormulaText] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,[FormulaKind] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,[SharedFormulaIndex] int NULL,[CachePresent] bit NOT NULL,[CacheValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
        IF @ResultTable IS NULL SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM @Empty;
        RETURN 0;
    END;
    IF (@ResultTable IS NOT NULL AND LOWER(LEFT(@ResultTable COLLATE Latin1_General_100_BIN2,5))=N'#tbx_')
       OR OBJECT_ID(N'tempdb..#tbx_ListXlsxWorksheets_ResultSource') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_ReadXlsxWorksheetCells_ResultSource') IS NOT NULL
        THROW 51520,N'Reservierter interner XLSX-Tempnamensbereich.',1;
    -- Fachliche Tempstatements werden erst hinter dieser EXEC-Grenze kompiliert.
    EXEC toolbelt_file.USP_InternalXlsxRead @ReadCells=1,
         @XlsxBinary=@XlsxBinary,
         @SheetOrdinal=@SheetOrdinal,
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
         @Debug=@Debug;
    RETURN 0;
END;
GO
