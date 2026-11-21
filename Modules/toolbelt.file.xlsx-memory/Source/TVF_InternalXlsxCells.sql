/*
Interner Statusrow-Provider für USP_ReadXlsxWorksheetCells; keine öffentliche Neben-API.
Dependency tlblt_File_XlsxMemory 1.0.0 und tlblt_Archive_ZipMemory 1.4.0.
SAFE, DataAccess/SystemDataAccess None. Vollständige Materialisierung vor Rows.
Erwartete Inputfehler: eine ErrorNumber/ErrorMessage-Zeile; unerwartete CLR-Fehler
bleiben Originalfehler. Keine Dateisystem- oder Netzwerkzugriffe.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.TVF_InternalXlsxCells
(
    @XlsxBinary varbinary(max),
    @SheetOrdinal int,
    @MaxArchiveBytes bigint,
    @MaxPartBytes bigint,
    @MaxTotalUncompressedBytes bigint,
    @MaxParts int,
    @MaxSheets int,
    @MaxCells int,
    @MaxSharedStrings int,
    @MaxSharedStringBytes bigint,
    @MaxXmlDepth int,
    @MaxCompressionRatio decimal(18,4),
    @BudgetMilliseconds int
)
RETURNS TABLE
(
    ErrorNumber int NULL, ErrorMessage nvarchar(4000) NULL,
    RowOrdinal int NULL,
    ColumnOrdinal int NULL,
    StoredType nvarchar(16) NULL,
    ValuePresent bit NULL,
    RawValue nvarchar(max) NULL,
    TextValue nvarchar(max) NULL,
    FormulaPresent bit NULL,
    FormulaText nvarchar(max) NULL,
    FormulaKind nvarchar(16) NULL,
    SharedFormulaIndex int NULL,
    CachePresent bit NULL,
    CacheValue nvarchar(max) NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-tvf-internalxlsxcells"
-- description: "Interner SAFE-Statusprovider für rohe Zellen genau eines Worksheets."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.file.xlsx-memory"
-- schema_name: "toolbelt_file"
-- object_name: "TVF_InternalXlsxCells"
-- object_type: "CLR_TVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@XlsxBinary", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vollständige XLSX-ZIPbytes, kein Dateipfad. NULL liefert leer erst nach gültigen Limits und im Zellenmodus gültiger positiver SheetOrdinal. Der TSQL-Core legt zuvor eine private Ergebnistemp an; der direkte CLR-Provider nicht. Eingabelänge vor SqlBytes.Value prüfen; kein Datei-/Netzwerkzugriff."}, {"name": "@SheetOrdinal", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "1-basierter Worksheetindex. Interner Zellenprovider verlangt NichtNULL und >=1 vor NULL-Binary; obere Grenze erst am Workbook. Im TSQL-Core-Modus0 ungenutzt, Modus1 reicht den Wert weiter. Öffentliche Zellenfassade überspringt ihn bei NULL-Binary."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Öffentlicher Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxPartBytes", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Öffentlicher Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxTotalUncompressedBytes", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864, Öffentlicher Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxParts", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..256, Öffentlicher Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxSheets", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..32, Öffentlicher Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxCells", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000, Öffentlicher Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxSharedStrings", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..50000, Öffentlicher Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxSharedStringBytes", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..8388608, Öffentlicher Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxXmlDepth", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..64, Öffentlicher Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(18,4)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "decimal(18,4) im inklusiven Bereich 1..200, Öffentlicher Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig auch bei NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}, {"name": "@BudgetMilliseconds", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..5000, Öffentlicher Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary."}]
-- source_paths: ["Modules/toolbelt.file.xlsx-memory/Source/TVF_InternalXlsxCells.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- public_entrypoints: ["toolbelt_file.USP_ReadXlsxWorksheetCells"]
-- ---
--
-- # TVF_InternalXlsxCells
--
-- ## Zweck und Einsatzfälle
--
-- Interner SAFE-Statusprovider für rohe Zellen genau eines Worksheets.
--
-- ## Voraussetzungen
--
-- Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@XlsxBinary` | `varbinary(max)` | kein Default | Input | Vollständige XLSX-ZIPbytes, kein Dateipfad. NULL liefert leer erst nach gültigen Limits und im Zellenmodus gültiger positiver SheetOrdinal. Der TSQL-Core legt zuvor eine private Ergebnistemp an; der direkte CLR-Provider nicht. Eingabelänge vor SqlBytes.Value prüfen; kein Datei-/Netzwerkzugriff. |
-- | `@SheetOrdinal` | `int` | kein Default | Input | 1-basierter Worksheetindex. Interner Zellenprovider verlangt NichtNULL und >=1 vor NULL-Binary; obere Grenze erst am Workbook. Im TSQL-Core-Modus0 ungenutzt, Modus1 reicht den Wert weiter. Öffentliche Zellenfassade überspringt ihn bei NULL-Binary. |
-- | `@MaxArchiveBytes` | `bigint` | kein Default | Input | Ganzzahl 1..16777216, Öffentlicher Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxPartBytes` | `bigint` | kein Default | Input | Ganzzahl 1..16777216, Öffentlicher Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxTotalUncompressedBytes` | `bigint` | kein Default | Input | Ganzzahl 1..67108864, Öffentlicher Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxParts` | `int` | kein Default | Input | Ganzzahl 1..256, Öffentlicher Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxSheets` | `int` | kein Default | Input | Ganzzahl 1..32, Öffentlicher Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxCells` | `int` | kein Default | Input | Ganzzahl 1..100000, Öffentlicher Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxSharedStrings` | `int` | kein Default | Input | Ganzzahl 1..50000, Öffentlicher Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxSharedStringBytes` | `bigint` | kein Default | Input | Ganzzahl 1..8388608, Öffentlicher Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxXmlDepth` | `int` | kein Default | Input | Ganzzahl 1..64, Öffentlicher Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@MaxCompressionRatio` | `decimal(18,4)` | kein Default | Input | decimal(18,4) im inklusiven Bereich 1..200, Öffentlicher Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig auch bei NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
-- | `@BudgetMilliseconds` | `int` | kein Default | Input | Ganzzahl 1..5000, Öffentlicher Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig auch bei NULL-XlsxBinary. Nur absenkbar; Der interne Provider prüft Limits vor dem NULL-Binary-Pfad. Interner SQL-Parameter ohne Default, explizit NichtNULL angeben; Limitprüfung auch bei NULL-Binary. |
--
-- CLR-FT:alle Argumente explizit,keine SQL-Defaults.
--
-- ## Ergebnisse
--
-- Raw-Schema: ErrorNumber int NULL,ErrorMessage nvarchar(4000) NULL gefolgt von RowOrdinal int NOT NULL, ColumnOrdinal int NOT NULL, StoredType nvarchar(16) NOT NULL, ValuePresent bit NOT NULL, RawValue nvarchar(max) NULL, TextValue nvarchar(max) NULL, FormulaPresent bit NOT NULL, FormulaText nvarchar(max) NULL, FormulaKind nvarchar(16) NULL, SharedFormulaIndex int NULL, CachePresent bit NOT NULL, CacheValue nvarchar(max) NULL. SQL-Snapshottexte Latin1_General_100_BIN2. Im internen SQL-FT-Vertrag sind sämtliche Fachspalten nullable; die genannten NOTNULL-Invarianten gelten erst für erfolgreiche Fachzeilen. Erfolg ErrorNumberNULL, Fehler eine51520-Zeile ohne Fachwerte. Keine Reihenfolgegarantie ohne ORDER BY.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Interner Provider: öffentliche Fassade bevorzugen.
-- EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf öffentliche TVF und gegebenenfalls gezielte interne Providerrechte entsprechend tatsächlicher Ownershipchain. Interne Direktrechte sind keine Empfehlung für eine öffentliche Neben-API. DataAccess/SystemDataAccess=None im CLR; kein Datenbankkatalog-, Datei- oder Netzwerkzugriff für die Zellberechnung. Keine Rechte werden erteilt.
--
-- ## Ressourcenbedarf
--
-- Alle Readerlimits sind positiv und nur absenkbar: Archiv/Part16777216Bytes, entpackte Summe67108864Bytes, Parts256,Sheets32,Cells100000,SharedStrings50000,decodierte SharedString-UTF16Bytes8388608,XML-Tiefe64,Ratio decimal1..200,Budget1..5000ms. Limits werden auch bei Sheetlisten konfigurationsgeprüft, ohne dass dort alle Zell-/SST-Payloads gelesen werden. Interner gezählter Allokationscharge134217728Bytes umfasst Eingabe sowie XML-/Part-/Ergebnisanteile; kein Peakheap/Memorygrant. Workbooktimer startet nach SqlBytes.Value-Kopie, SQL-Bindung/Transport liegen außerhalb. Kooperative Checkpoints mit präzisem Abschluss sind keine harte Gesamtabbruchfrist. Native XML-Reads, Allokation und GC bleiben zusätzlicher Aufwand.
--
-- ## Nebenwirkungen
--
-- Interner CLR-Provider: alle SQL-Argumente explizit, keine SQL-Defaults. Zuerst sämtliche Limits prüfen, im Zellenmodus zusätzlich SheetOrdinal NichtNULL/>=1, danach NULL-Binary ->0Zeilen. Eingabelänge vor SqlBytes.Value-Kopie prüfen. Lokales Workbook/Index und gewählten Snapshot vollständig materialisieren; abschließender Budgetcheckpoint vor Enumeration. Success ErrorNumber/ErrorMessage=NULL, nicht0. Erwarteter Container-/XML-/Encoding-/IO-Fehler genau eine51520-Statuszeile ohne Fachwerte. Kein TSQL-ResultTable-Routing, keine Tempanlage, keine fachliche SQL-Abfrage im CLR.
--
-- Vollständiges begrenztes Transitional-OOXML-XLSX aus ZIPbytes. Ein kanonischer ZIP-Index pro Workbook, eindeutige ordinale Partnamen, Methoden0/8, keine Encryption/Verzeichnisentries/ZIP64/Multi-Disk. Relative Relationships bleiben innerhalb des Pakets; externe Targets, relevante Makro-/ActiveX-/OLE-/Connections-/ExternalLink-Relationshiptypen und entsprechende ContentTypes werden abgewiesen. Kein Strict-OOXML/XLS/XLSB-Parser und keine Malwareprüfung beliebiger unreferenzierter Bytes. Alle .rels, Rootrelationships, ContentTypes und Workbook werden gelesen. Nur tatsächlich gelesene Parts erhalten Payload-/CRC-Prüfung; Sheetlisten sind kein Nachweis aller Worksheet-/SST-Payloads. Keine Pfade/URLs auf dem Server auflösen. XML mit XmlResolver=NULL, DTD verboten, festen Zeichen-/Tiefengrenzen.
--
-- Genau ein Worksheet per1-basiertem Index. SharedStrings vollständig begrenzt einlesen, rich-text t zusammenführen und phonetic rPh überspringen. Nur tatsächlich gespeicherte sparse Zellen, kein aufgefülltes Rechteck. Explizite positive Row-r und passende uppercase A..XFD-Zellreferenz, Zeilen bis1048576/Spalten bis16384, keine doppelten Koordinaten. StoredType n(default),s,inlineStr,str,b,e,d. s wird per nichtnegativem Int32-Index aus SST aufgelöst; inlineStr ohne v; str übernimmt v als Text; b erlaubt bei nichtleerem v nur0/1. Rohtext bleibt erhalten. Formeln normal/shared/array/dataTable und Cache werden beschrieben, nicht berechnet oder expandiert. CachePresent bedeutet f und v vorhanden, CacheValue=RawValue. Keine Workbook-Styles oder automatische Datums-/Kulturinferenz. Nach Zeile/Spalte sortierter vollständiger Snapshot, keine Teilresultate vor erfolgreicher Materialisierung.
--
-- ## Fehlerbehandlung
--
-- 51520: erwarteter Reader-/Inputfehler oder reservierter öffentlicher Tempnamensbereich. 51529: fehlende/abweichende Dependency, ungültiger interner Modus oder inkohärenter Status. Rohe erwartete CLR-Fehler werden in eine51520-Zeile mit begrenzter TBX_XLSX_-Kategorie übersetzt; unbekannte/zu lange Kategorien werden TBX_XLSX_CONTAINER_INVALID. Öffentlich wird geworfen, keine Teilresultate. Unerwartete Engine-/CLR-/Helperfehler bleiben erhalten.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/XLSX-Gesamtabnahme. Historische Nachweise bleiben an ihre ursprünglichen Artefakte gebunden. Keine Installations-/Rechteattestation oder volle Excel-/SSIS-Runtimeparität. Workbookinhalte, Formeln und Runtimebefunde privat halten.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_File_XlsxMemory].[Toolbelt.Xlsx.Qualification.XlsxEntryPoints].[ReadCells];
GO
