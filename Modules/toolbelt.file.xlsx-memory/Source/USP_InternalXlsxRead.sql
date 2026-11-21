/*
Interne Compiler-/Routinggrenze der beiden öffentlichen XLSX-USPs.
Kein zusätzlicher öffentlicher Funktionsvertrag. Dependency: SAFE Status-TVFs
und ResultTable-Helper. Reservierte Tempnamen prüft der öffentliche Wrapper
vor EXEC; hier erfolgt die erste Kompilierung der fachlichen Tempstatements.
Erwartete Inputfehler vor Mutation; eigene Transaktion oder Caller-Savepoint.
Direkter Aufruf ist intern, keine Grant-Zusage.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_file.USP_InternalXlsxRead
(
    @ReadCells bit = NULL,
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
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-usp-internalxlsxread"
-- description: "Interne Compiler-, Snapshot- und ResultTable-Routinggrenze der beiden XLSX-Prozeduren."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.file.xlsx-memory"
-- schema_name: "toolbelt_file"
-- object_name: "USP_InternalXlsxRead"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@ReadCells", "sql_type": "bit", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "0 liest Sheetmetadaten; 1 liest rohe Zellen. NULL ist nach früher Hilfe ungültig (51529), auch bei NULL-Binary. Interner Einstieg; öffentliche Wrapper übernehmen reservierte Tempnamen vor der Compilergrenze."}, {"name": "@XlsxBinary", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vollständige XLSX-ZIPbytes, kein Dateipfad. NULL liefert leer erst nach gültigen Limits und im Zellenmodus gültiger positiver SheetOrdinal. Der TSQL-Core legt zuvor eine private Ergebnistemp an; der direkte CLR-Provider nicht. Eingabelänge vor SqlBytes.Value prüfen; kein Datei-/Netzwerkzugriff."}, {"name": "@SheetOrdinal", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1-basierter Worksheetindex. Interner Zellenprovider verlangt NichtNULL und >=1 vor NULL-Binary; obere Grenze erst am Workbook. Im TSQL-Core-Modus0 ungenutzt, Modus1 reicht den Wert weiter. Öffentliche Zellenfassade überspringt ihn bei NULL-Binary."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxPartBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxTotalUncompressedBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxParts", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxSheets", "sql_type": "int", "sql_default": "32", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxCells", "sql_type": "int", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxSharedStrings", "sql_type": "int", "sql_default": "50000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxSharedStringBytes", "sql_type": "bigint", "sql_default": "8388608", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxXmlDepth", "sql_type": "int", "sql_default": "64", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(18,4)", "sql_default": "200", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie."}, {"name": "@BudgetMilliseconds", "sql_type": "int", "sql_default": "5000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.file.xlsx-memory/Source/USP_InternalXlsxRead.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- public_entrypoints: ["toolbelt_file.USP_ListXlsxWorksheets", "toolbelt_file.USP_ReadXlsxWorksheetCells"]
-- ---
--
-- # USP_InternalXlsxRead
--
-- ## Zweck und Einsatzfälle
--
-- Interne Compiler-, Snapshot- und ResultTable-Routinggrenze der beiden XLSX-Prozeduren.
--
-- ## Voraussetzungen
--
-- Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@ReadCells` | `bit` | `NULL` | Input | 0 liest Sheetmetadaten; 1 liest rohe Zellen. NULL ist nach früher Hilfe ungültig (51529), auch bei NULL-Binary. Interner Einstieg; öffentliche Wrapper übernehmen reservierte Tempnamen vor der Compilergrenze. |
-- | `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | Vollständige XLSX-ZIPbytes, kein Dateipfad. NULL liefert leer erst nach gültigen Limits und im Zellenmodus gültiger positiver SheetOrdinal. Der TSQL-Core legt zuvor eine private Ergebnistemp an; der direkte CLR-Provider nicht. Eingabelänge vor SqlBytes.Value prüfen; kein Datei-/Netzwerkzugriff. |
-- | `@SheetOrdinal` | `int` | `NULL` | Input | 1-basierter Worksheetindex. Interner Zellenprovider verlangt NichtNULL und >=1 vor NULL-Binary; obere Grenze erst am Workbook. Im TSQL-Core-Modus0 ungenutzt, Modus1 reicht den Wert weiter. Öffentliche Zellenfassade überspringt ihn bei NULL-Binary. |
-- | `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxPartBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxParts` | `int` | `256` | Input | Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxSheets` | `int` | `32` | Input | Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxCells` | `int` | `100000` | Input | Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxSharedStrings` | `int` | `50000` | Input | Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxXmlDepth` | `int` | `64` | Input | Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. |
-- | `@BudgetMilliseconds` | `int` | `5000` | Input | Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- Alle technischen Defaults erhalten Hilfeaufrufe;fachliche NULL-Gültigkeit folgt dem einzelnen Parameter und früher NULL-Binary-Priorität.
--
-- ## Ergebnisse
--
-- Modus0: SheetOrdinal int NOT NULL (Workbookreihenfolge,1-basiert), SheetName nvarchar(max) NOT NULL, Visibility nvarchar(16) NOT NULL (visible/hidden/veryHidden), Date1904 bit NOT NULL. Texte im öffentlichen SQL-Snapshot Latin1_General_100_BIN2.
--
-- Modus1: RowOrdinal int NOT NULL, ColumnOrdinal int NOT NULL, StoredType nvarchar(16) NOT NULL, ValuePresent bit NOT NULL, RawValue nvarchar(max) NULL, TextValue nvarchar(max) NULL, FormulaPresent bit NOT NULL, FormulaText nvarchar(max) NULL, FormulaKind nvarchar(16) NULL, SharedFormulaIndex int NULL, CachePresent bit NOT NULL, CacheValue nvarchar(max) NULL. SQL-Snapshottexte Latin1_General_100_BIN2. ResultTableNULL liefert den Fachresultset, sonst ausschließlich Routing in bestehendes Caller-#Tempziel. Hilfe liefert bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); frühes RETURN0. Normaler Erfolgsreturn0.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
-- -- Vollständige Client-Workbookbytes binden, keinen Serverpfad.
-- DECLARE @Workbook varbinary(max)=NULL;
-- EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Workbook,@SheetOrdinal=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf öffentliche XLSX-USP und notwendige interne Ausführung/Ownershipchain. Gezielt nötiges SELECT auf benutzte CLR-FT gemäß tatsächlichem Ausführungskontext; interner Name ist keine automatische Rechteübertragung. Bei ResultTable zusätzlich Helper-EXECUTE, Sichtbarkeit seiner exakten sys.parameters-Signatur und Änderungs-/Schreibrechte auf die eigene lokale Temp. Keine Leserechte auf fachliche Quelldatenbanken, Dateipfade oder Systemkataloge im Workbook-CLR erforderlich.
--
-- ## Ressourcenbedarf
--
-- Alle Readerlimits sind positiv und nur absenkbar: Archiv/Part16777216Bytes, entpackte Summe67108864Bytes, Parts256,Sheets32,Cells100000,SharedStrings50000,decodierte SharedString-UTF16Bytes8388608,XML-Tiefe64,Ratio decimal1..200,Budget1..5000ms. Limits werden auch bei Sheetlisten konfigurationsgeprüft, ohne dass dort alle Zell-/SST-Payloads gelesen werden. Interner gezählter Allokationscharge134217728Bytes umfasst Eingabe sowie XML-/Part-/Ergebnisanteile; kein Peakheap/Memorygrant. Workbooktimer startet nach SqlBytes.Value-Kopie, SQL-Bindung/Transport liegen außerhalb. Kooperative Checkpoints mit präzisem Abschluss sind keine harte Gesamtabbruchfrist. Native XML-Reads, Allokation und GC bleiben zusätzlicher Aufwand.
--
-- ## Nebenwirkungen
--
-- Interner TSQL-Core: frühe Hilfe vor Modusprüfung. ReadCells0=Sheets,1=Cells,NULL ->51529. Private Ergebnistemp pro Modus anlegen; NULL-Binary liefert jetzt leer beziehungsweise unverändertes Ziel, ohne Provider-/Limitprüfung. NichtNULL: passenden internen CLR-Provider verlangen, vollständigen Raw-Snapshot materialisieren. Eine Fehlerzeile muss ErrorNumber51520 und Meldung besitzen; inkohärente Status-/Pflichtfelder ->51529. Debug>0 meldet abstrakten validierten Snapshot mit Severity10/NOWAIT. ResultTableNULL liefert direkt sortiert, ohne ResultTable-Helperprüfung. Sonst exakte fünfparametrige USP_PrepareResultTable-Signatur über sys.parameters prüfen und nur Vorbereitung/INSERT im eigenen TX oder zufälligen Caller-Savepoint ausführen. Eigener Commit, bei Fehler eigener Rollback beziehungsweise nur committable eigener Savepoint; kein eigenes XACT_ABORT. Fehler werden erhalten. Die privaten Temps und reservierten Namen schützt der öffentliche Wrapper vor Corekompilierung; Direktaufruf umgeht diese Fassade und ist kein unterstützter öffentlicher Weg.
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
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        DECLARE @Help TABLE
        (HelpContractVersion varchar(16) NOT NULL DEFAULT '1.0',
         SchemaName sysname NOT NULL DEFAULT N'toolbelt_file',
         ObjectName sysname NOT NULL DEFAULT N'USP_InternalXlsxRead',
         Section varchar(32) NOT NULL, Ordinal int NOT NULL, ItemName sysname NULL,
         SqlDataType varchar(256) NULL, IsRequired bit NULL, IsNullable bit NULL,
         DefaultValue nvarchar(4000) NULL, Description nvarchar(max) NOT NULL, ExampleSql nvarchar(max) NULL);
        INSERT @Help (Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql) VALUES
        ('PARAMETER',1,N'@ReadCells','bit',1,0,N'NULL',N'Interner Modus: 0 Sheetliste, 1 Zellliste; öffentliche USPs bevorzugen.',NULL),
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.',NULL),
        ('PARAMETER',2,N'@XlsxBinary','varbinary(max)',0,1,N'NULL',N'NULL liefert keine Zeilen und verändert kein ResultTable.',NULL),
        ('PARAMETER',3,N'@SheetOrdinal','int',1,0,N'NULL',N'Positive Worksheetposition aus ListXlsxWorksheets.',NULL),
        ('PARAMETER',4,N'@MaxArchiveBytes','bigint',0,0,N'16777216',N'Containerbytes, höchstens 16 MiB.',NULL),
        ('PARAMETER',5,N'@MaxPartBytes','bigint',0,0,N'16777216',N'Unkomprimierte Bytes je Part, höchstens 16 MiB.',NULL),
        ('PARAMETER',6,N'@MaxTotalUncompressedBytes','bigint',0,0,N'67108864',N'Deklarierte Gesamtbytes, höchstens 64 MiB.',NULL),
        ('PARAMETER',7,N'@MaxParts','int',0,0,N'256',N'ZIP-Parts, höchstens 256.',NULL),
        ('PARAMETER',8,N'@MaxSheets','int',0,0,N'32',N'Worksheets, höchstens 32.',NULL),
        ('PARAMETER',9,N'@MaxCells','int',0,0,N'100000',N'Vorhandene Zellen im gewählten Sheet, höchstens 100000.',NULL),
        ('PARAMETER',10,N'@MaxSharedStrings','int',0,0,N'50000',N'Shared Strings, höchstens 50000.',NULL),
        ('PARAMETER',11,N'@MaxSharedStringBytes','bigint',0,0,N'8388608',N'Dekodierter Shared-String-UTF16-Text, höchstens 8 MiB.',NULL),
        ('PARAMETER',12,N'@MaxXmlDepth','int',0,0,N'64',N'XML-Tiefe, höchstens 64.',NULL),
        ('PARAMETER',13,N'@MaxCompressionRatio','decimal(18,4)',0,0,N'200',N'Maximales deklarierter Ratio, höchstens 200.',NULL),
        ('PARAMETER',14,N'@BudgetMilliseconds','int',0,0,N'5000',N'Kooperatives Gesamtbudget, höchstens 5000 ms; keine harte Wallclockzusage.',NULL),
        ('PARAMETER',15,N'@ResultTable','sysname',0,1,N'NULL',N'Vorhandene caller-lokale Temp-Tabelle, sonst SELECT.',NULL),
        ('PARAMETER',16,N'@KeepData','bit',0,1,N'0',N'Replace 0 oder Append 1; NULL entspricht 0.',NULL),
        ('PARAMETER',17,N'@Debug','tinyint',0,1,N'0',N'Nur Messages ohne Workbookinhalte.',NULL),
        ('PARAMETER',18,N'@Hilfe','bit',0,1,N'0',N'Ausschließlich standardisierte Hilfe.',NULL),
        ('RESULT_COLUMN',1,N'RowOrdinal','int',1,0,NULL,N'Einsbasierte Zeile.',NULL),
        ('RESULT_COLUMN',2,N'ColumnOrdinal','int',1,0,NULL,N'Einsbasierte Spalte.',NULL),
        ('RESULT_COLUMN',3,N'StoredType','nvarchar(16)',1,0,NULL,N'Gespeicherter Zelltyp, keine Typinferenz.',NULL),
        ('RESULT_COLUMN',4,N'ValuePresent','bit',1,0,NULL,N'Gespeichertes v-Element vorhanden, auch wenn leer.',NULL),
        ('RESULT_COLUMN',5,N'RawValue','nvarchar(max)',1,1,NULL,N'Rohtext aus v, NULL bei fehlendem v.',NULL),
        ('RESULT_COLUMN',6,N'TextValue','nvarchar(max)',1,1,NULL,N'Shared-/Inline-/str-Text, kein Excel-Anzeigeformat.',NULL),
        ('RESULT_COLUMN',7,N'FormulaPresent','bit',1,0,NULL,N'f-Element vorhanden.',NULL),
        ('RESULT_COLUMN',8,N'FormulaText','nvarchar(max)',1,1,NULL,N'Unveränderter Formeltext, keine Berechnung.',NULL),
        ('RESULT_COLUMN',9,N'FormulaKind','nvarchar(16)',1,1,NULL,N'normal, shared, array oder dataTable.',NULL),
        ('RESULT_COLUMN',10,N'SharedFormulaIndex','int',1,1,NULL,N'Gespeichertes si, keine Formelrekonstruktion.',NULL),
        ('RESULT_COLUMN',11,N'CachePresent','bit',1,0,NULL,N'Formel und v-Element vorhanden.',NULL),
        ('RESULT_COLUMN',12,N'CacheValue','nvarchar(max)',1,1,NULL,N'Gespeicherter Formelcache-Rohtext.',NULL),
        ('ERROR',1,N'51520',NULL,NULL,NULL,NULL,N'Begrenzte Kategorie eines erwarteten Input-/Container-/XML-/Feature-/Ressourcenfehlers; keine Teilausgabe.',NULL),
        ('ERROR',2,N'51529',NULL,NULL,NULL,NULL,N'Fehlende oder inkonsistente registrierte Dependency bzw. interner Providervertrag.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE auf USP; ResultTable zusätzlich Helper-EXECUTE und Sichtbarkeit der caller-lokalen Tabelle. Keine Rechteausweitung.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Transitional XLSX, klassische Stored-/Deflate-ZIPs. Kein ZIP64, externe Beziehungen, Makros oder Strict Open XML. Unicode bleibt unverändert, Tabellen brauchen explizite Ordinals zum Sortieren.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hilfe ohne fachliche Eingaben.',N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;');
        -- Technische Hilfe benennt die tatsächliche Modus-0-Resultshape;
        -- ohne expliziten Modus bleibt die dokumentierte Zellshape sichtbar.
        IF @ReadCells=0
        BEGIN
            DELETE FROM @Help WHERE Section='RESULT_COLUMN';
            UPDATE @Help SET IsRequired=0,IsNullable=1,
                Description=N'Für den Sheetlistenmodus nicht verwendet.'
                WHERE Section='PARAMETER' AND ItemName=N'@SheetOrdinal';
            INSERT @Help (Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql) VALUES
            ('RESULT_COLUMN',1,N'SheetOrdinal','int',1,0,NULL,N'Einsbasierte Worksheetposition.',NULL),
            ('RESULT_COLUMN',2,N'SheetName','nvarchar(max)',1,0,NULL,N'Unveränderter Worksheetname.',NULL),
            ('RESULT_COLUMN',3,N'Visibility','nvarchar(16)',1,0,NULL,N'visible, hidden oder veryHidden.',NULL),
            ('RESULT_COLUMN',4,N'Date1904','bit',1,0,NULL,N'Gespeichertes Workbook-Datumssystem.',NULL);
        END;
        SELECT HelpContractVersion,SchemaName,ObjectName,
               Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
           WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5
           WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_file' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_InternalXlsxRead' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-usp-internalxlsxread"
description: "Interne Compiler-, Snapshot- und ResultTable-Routinggrenze der beiden XLSX-Prozeduren."
skill_format_version: "1.0"
module_id: "toolbelt.file.xlsx-memory"
schema_name: "toolbelt_file"
object_name: "USP_InternalXlsxRead"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ReadCells", "sql_type": "bit", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "0 liest Sheetmetadaten; 1 liest rohe Zellen. NULL ist nach früher Hilfe ungültig (51529), auch bei NULL-Binary. Interner Einstieg; öffentliche Wrapper übernehmen reservierte Tempnamen vor der Compilergrenze."}, {"name": "@XlsxBinary", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vollständige XLSX-ZIPbytes, kein Dateipfad. NULL liefert leer erst nach gültigen Limits und im Zellenmodus gültiger positiver SheetOrdinal. Der TSQL-Core legt zuvor eine private Ergebnistemp an; der direkte CLR-Provider nicht. Eingabelänge vor SqlBytes.Value prüfen; kein Datei-/Netzwerkzugriff."}, {"name": "@SheetOrdinal", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1-basierter Worksheetindex. Interner Zellenprovider verlangt NichtNULL und >=1 vor NULL-Binary; obere Grenze erst am Workbook. Im TSQL-Core-Modus0 ungenutzt, Modus1 reicht den Wert weiter. Öffentliche Zellenfassade überspringt ihn bei NULL-Binary."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. ' AS nvarchar(max)) + N'Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxPartBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxTotalUncompressedBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxParts", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxSheets", "sql_type": "int", "sql_default": "32", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanla' + N'ge."}, {"name": "@MaxCells", "sql_type": "int", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxSharedStrings", "sql_type": "int", "sql_default": "50000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxSharedStringBytes", "sql_type": "bigint", "sql_default": "8388608", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxXmlDepth", "sql_type": "int", "sql_default": "64", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(18,4)", "sql_default": "200", "is_output": false, "argument_required": false, "busine' + N'ss_required": false, "nullable": false, "description": "decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie."}, {"name": "@BudgetMilliseconds", "sql_type": "int", "sql_default": "5000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, ' + N'"business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.file.xlsx-memory/Source/USP_InternalXlsxRead.sql"]
review_status: "verified"
source_module_version: "1.2.0"
public_entrypoints: ["toolbelt_file.USP_ListXlsxWorksheets", "toolbelt_file.USP_ReadXlsxWorksheetCells"]
---

# USP_InternalXlsxRead

## Zweck und Einsatzfälle

Interne Compiler-, Snapshot- und ResultTable-Routinggrenze der beiden XLSX-Prozeduren.

## Voraussetzungen

Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@ReadCells` | `bit` | `NULL` | Input | 0 liest Sheetmetadaten; 1 liest rohe Zellen. NULL ist nach früher Hilfe ungültig (51529), auch bei NULL-Binary. Interner Einstieg; öffentliche Wrapper übernehmen reservierte Tempnamen vor der Compilergrenze. |
| `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | Vollständige XLSX-ZIPbytes, kein Dateipfad. NULL liefert leer erst nach gültigen Limits und im Z' + N'ellenmodus gültiger positiver SheetOrdinal. Der TSQL-Core legt zuvor eine private Ergebnistemp an; der direkte CLR-Provider nicht. Eingabelänge vor SqlBytes.Value prüfen; kein Datei-/Netzwerkzugriff. |
| `@SheetOrdinal` | `int` | `NULL` | Input | 1-basierter Worksheetindex. Interner Zellenprovider verlangt NichtNULL und >=1 vor NULL-Binary; obere Grenze erst am Workbook. Im TSQL-Core-Modus0 ungenutzt, Modus1 reicht den Wert weiter. Öffentliche Zellenfassade überspringt ihn bei NULL-Binary. |
| `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxPartBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxParts` | `int` | `256` | Input | Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxSheets` | `int` | `32` | Input | Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites' + N' NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxCells` | `int` | `100000` | Input | Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxSharedStrings` | `int` | `50000` | Input | Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxXmlDepth` | `int` | `64` | Input | Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. |
| `@BudgetMilliseconds` | `int` | `5000` | Input | Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/' + N'negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; Der TSQL-Core überspringt Provider/Limits bei NULL-Binary nach Modusprüfung und privater Tempanlage. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults erhalten Hilfeaufrufe;fachliche NULL-Gültigkeit folgt dem einzelnen Parameter und früher NULL-Binary-Priorität.

## Ergebnisse

Modus0: SheetOrdinal int NOT NULL (Workbookreihenfolge,1-basiert), SheetName nvarchar(max) NOT NULL, Visibility nvarchar(16) NOT NULL (visible/hidden/veryHidden), Date1904 bit NOT NULL. Texte im öffentlichen SQL-Snapshot Latin1_General_100_BIN2.

Modus1: RowOrdinal int NOT NULL, ColumnO' + N'rdinal int NOT NULL, StoredType nvarchar(16) NOT NULL, ValuePresent bit NOT NULL, RawValue nvarchar(max) NULL, TextValue nvarchar(max) NULL, FormulaPresent bit NOT NULL, FormulaText nvarchar(max) NULL, FormulaKind nvarchar(16) NULL, SharedFormulaIndex int NULL, CachePresent bit NOT NULL, CacheValue nvarchar(max) NULL. SQL-Snapshottexte Latin1_General_100_BIN2. ResultTableNULL liefert den Fachresultset, sonst ausschließlich Routing in bestehendes Caller-#Tempziel. Hilfe liefert bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); frühes RETURN0. Normaler Erfolgsreturn0.

## Aufrufbeispiele

```sql
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;
-- Vollständige Client-Workbookbytes binden, keinen Serverpfad.
DECLARE @Workbook varbinary(max)=NULL;
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Workbook,@SheetOrdinal=1;
```

## Rechte

Vorhandenes EXECUTE auf öffentliche XLSX-USP und notwendige interne Ausführung/Ownershipchain. Gezielt nötiges SELECT auf benutzte CLR-FT gemäß tatsächlichem Ausführungskontext; interner Name ist keine automatische Rechteübertragung. Bei ResultTable zusätzlich Helper-EXECUTE, Sichtbarkeit seiner exakten sys.parameters-Signatur und Änderungs-/Schreibrechte auf die eigene lokale Temp. Keine Leserechte auf fachliche Quelldatenbanken, Dateipfade oder Systemkataloge im Workbook-CLR erforderlich.

## Ressourcenbedarf

Alle Readerlimits sind positiv und nur absenkbar: Archiv/Part16777216Bytes, entpackte Summe67108864Bytes, Parts256,Sheets32,Cells100000,SharedStrings50000,decodierte SharedString-UTF16Bytes8388608,XML-Tiefe64,Ratio decimal1..200,Budget1..5000ms. Limits werden auch bei Sheetlisten konfigurationsgeprüft, ohne dass dort alle Zell-/SST-Payloads gelesen werden. Interner gezählter Allokationscharge134217728Bytes umfasst Eingabe sowie XML-/Part-/Ergebnisanteile; kein Peakheap/Memorygrant. Workbooktimer sta' + N'rtet nach SqlBytes.Value-Kopie, SQL-Bindung/Transport liegen außerhalb. Kooperative Checkpoints mit präzisem Abschluss sind keine harte Gesamtabbruchfrist. Native XML-Reads, Allokation und GC bleiben zusätzlicher Aufwand.

## Nebenwirkungen

Interner TSQL-Core: frühe Hilfe vor Modusprüfung. ReadCells0=Sheets,1=Cells,NULL ->51529. Private Ergebnistemp pro Modus anlegen; NULL-Binary liefert jetzt leer beziehungsweise unverändertes Ziel, ohne Provider-/Limitprüfung. NichtNULL: passenden internen CLR-Provider verlangen, vollständigen Raw-Snapshot materialisieren. Eine Fehlerzeile muss ErrorNumber51520 und Meldung besitzen; inkohärente Status-/Pflichtfelder ->51529. Debug>0 meldet abstrakten validierten Snapshot mit Severity10/NOWAIT. ResultTableNULL liefert direkt sortiert, ohne ResultTable-Helperprüfung. Sonst exakte fünfparametrige USP_PrepareResultTable-Signatur über sys.parameters prüfen und nur Vorbereitung/INSERT im eigenen TX oder zufälligen Caller-Savepoint ausführen. Eigener Commit, bei Fehler eigener Rollback beziehungsweise nur committable eigener Savepoint; kein eigenes XACT_ABORT. Fehler werden erhalten. Die privaten Temps und reservierten Namen schützt der öffentliche Wrapper vor Corekompilierung; Direktaufruf umgeht diese Fassade und ist kein unterstützter öffentlicher Weg.

Vollständiges begrenztes Transitional-OOXML-XLSX aus ZIPbytes. Ein kanonischer ZIP-Index pro Workbook, eindeutige ordinale Partnamen, Methoden0/8, keine Encryption/Verzeichnisentries/ZIP64/Multi-Disk. Relative Relationships bleiben innerhalb des Pakets; externe Targets, relevante Makro-/ActiveX-/OLE-/Connections-/ExternalLink-Relationshiptypen und entsprechende ContentTypes werden abgewiesen. Kein Strict-OOXML/XLS/XLSB-Parser und keine Malwareprüfung beliebiger unreferenzierter Bytes. Alle .rels, Rootrelationships, ContentTypes und Workbook werden gelesen. Nur tatsächlich gelesene Parts erhalten Payload-/CRC-Prüfung; Sheetlisten sind kein Nachweis aller Worksheet-/SST-Payloads. Keine ' + N'Pfade/URLs auf dem Server auflösen. XML mit XmlResolver=NULL, DTD verboten, festen Zeichen-/Tiefengrenzen.

Genau ein Worksheet per1-basiertem Index. SharedStrings vollständig begrenzt einlesen, rich-text t zusammenführen und phonetic rPh überspringen. Nur tatsächlich gespeicherte sparse Zellen, kein aufgefülltes Rechteck. Explizite positive Row-r und passende uppercase A..XFD-Zellreferenz, Zeilen bis1048576/Spalten bis16384, keine doppelten Koordinaten. StoredType n(default),s,inlineStr,str,b,e,d. s wird per nichtnegativem Int32-Index aus SST aufgelöst; inlineStr ohne v; str übernimmt v als Text; b erlaubt bei nichtleerem v nur0/1. Rohtext bleibt erhalten. Formeln normal/shared/array/dataTable und Cache werden beschrieben, nicht berechnet oder expandiert. CachePresent bedeutet f und v vorhanden, CacheValue=RawValue. Keine Workbook-Styles oder automatische Datums-/Kulturinferenz. Nach Zeile/Spalte sortierter vollständiger Snapshot, keine Teilresultate vor erfolgreicher Materialisierung.

## Fehlerbehandlung

51520: erwarteter Reader-/Inputfehler oder reservierter öffentlicher Tempnamensbereich. 51529: fehlende/abweichende Dependency, ungültiger interner Modus oder inkohärenter Status. Rohe erwartete CLR-Fehler werden in eine51520-Zeile mit begrenzter TBX_XLSX_-Kategorie übersetzt; unbekannte/zu lange Kategorien werden TBX_XLSX_CONTAINER_INVALID. Öffentlich wird geworfen, keine Teilresultate. Unerwartete Engine-/CLR-/Helperfehler bleiben erhalten.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/XLSX-Gesamtabnahme. Historische Nachweise bleiben an ihre ursprünglichen Artefakte gebunden. Keine Installations-/Rechteattestation oder volle Excel-/SSIS-Runtimeparität. Workbookinhalte, Formeln und Runtimebefunde privat halten.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0);
    IF @ReadCells IS NULL THROW 51529,N'Interner XLSX-Routingmodus fehlt.',1;
    IF @ReadCells=0
    BEGIN
    CREATE TABLE #tbx_ListXlsxWorksheets_ResultSource
    (
        [SheetOrdinal] int NOT NULL,
        [SheetName] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
        [Visibility] nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
        [Date1904] bit NOT NULL
    );
    IF @XlsxBinary IS NULL
    BEGIN
        IF @ResultTable IS NULL SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM #tbx_ListXlsxWorksheets_ResultSource;
        RETURN 0;
    END;
    IF OBJECT_ID(N'toolbelt_file.TVF_InternalXlsxSheets',N'FT') IS NULL
        THROW 51529,N'Der interne XLSX-Provider fehlt.',1;
    DECLARE @SheetsSnapshot TABLE
    (ErrorNumber int NULL, ErrorMessage nvarchar(4000) NULL,
        [SheetOrdinal] int NULL,
        [SheetName] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [Visibility] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [Date1904] bit NULL
    );
    INSERT @SheetsSnapshot SELECT ErrorNumber,ErrorMessage,[SheetOrdinal],[SheetName],[Visibility],[Date1904]
    FROM toolbelt_file.TVF_InternalXlsxSheets(@XlsxBinary,@MaxArchiveBytes,@MaxPartBytes,@MaxTotalUncompressedBytes,@MaxParts,@MaxSheets,@MaxCells,@MaxSharedStrings,@MaxSharedStringBytes,@MaxXmlDepth,@MaxCompressionRatio,@BudgetMilliseconds);
    IF EXISTS(SELECT 1 FROM @SheetsSnapshot WHERE ErrorNumber IS NOT NULL)
    BEGIN
        IF (SELECT COUNT_BIG(*) FROM @SheetsSnapshot)<>1
            THROW 51529,N'Inkonsistenter XLSX-Statusvertrag.',1;
        DECLARE @SheetsError int,@SheetsMessage nvarchar(2048);
        SELECT @SheetsError=ErrorNumber,@SheetsMessage=CONVERT(nvarchar(2048),ErrorMessage) FROM @SheetsSnapshot;
        IF @SheetsError<>51520 OR @SheetsMessage IS NULL
            THROW 51529,N'Ungültiger XLSX-Statusvertrag.',1;
        THROW @SheetsError,@SheetsMessage,1;
    END;
    IF EXISTS(SELECT 1 FROM @SheetsSnapshot WHERE [SheetOrdinal] IS NULL OR [SheetName] IS NULL OR [Visibility] IS NULL OR [Date1904] IS NULL)
        THROW 51529,N'Unvollständige XLSX-Datenzeile.',1;
    INSERT #tbx_ListXlsxWorksheets_ResultSource([SheetOrdinal],[SheetName],[Visibility],[Date1904]) SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM @SheetsSnapshot;
    IF @Debug>0 RAISERROR(N'XLSX: validierter Ergebnissnapshot bereit.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM #tbx_ListXlsxWorksheets_ResultSource ORDER BY SheetOrdinal;
        RETURN 0;
    END;

 DECLARE @SheetsDependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
 IF @SheetsDependencyId IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@SheetsDependencyId)<>5
 OR EXISTS(SELECT 1 FROM (VALUES (1,N'@ResultTableToAlter',231,256),(2,N'@LikeTable',231,1552),
(3,N'@KeepData',104,1),(4,N'@Debug',48,1),(5,N'@Hilfe',104,1)) expected(id,name,typeid,bytes)
     WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=@SheetsDependencyId
       AND p.parameter_id=expected.id AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.name)
       AND p.system_type_id=expected.typeid AND p.max_length=expected.bytes AND p.is_output=0))
 THROW 51529,N'ResultTable-Schnittstelle fehlt oder ist abweichend.',1;
    DECLARE @SheetsOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @SheetsSavepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-',''),@SheetsSavepointSet bit=0;
    BEGIN TRY
        IF @SheetsOwnTransaction=1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @SheetsSavepoint; SET @SheetsSavepointSet=1; END;
        EXEC toolbelt_core.USP_PrepareResultTable
             @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ListXlsxWorksheets_ResultSource',
             @KeepData=@KeepData,@Debug=@Debug;
        DECLARE @SheetsSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)
           +N' ([SheetOrdinal],[SheetName],[Visibility],[Date1904]) SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM #tbx_ListXlsxWorksheets_ResultSource;';
        EXEC sys.sp_executesql @SheetsSql;
        IF @SheetsOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SheetsOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @SheetsSavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @SheetsSavepoint;
        THROW;
    END CATCH;
    RETURN 0;

    END
    ELSE
    BEGIN
    CREATE TABLE #tbx_ReadXlsxWorksheetCells_ResultSource
    (
        [RowOrdinal] int NOT NULL,
        [ColumnOrdinal] int NOT NULL,
        [StoredType] nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
        [ValuePresent] bit NOT NULL,
        [RawValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [TextValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaPresent] bit NOT NULL,
        [FormulaText] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaKind] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [SharedFormulaIndex] int NULL,
        [CachePresent] bit NOT NULL,
        [CacheValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL
    );
    IF @XlsxBinary IS NULL
    BEGIN
        IF @ResultTable IS NULL SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM #tbx_ReadXlsxWorksheetCells_ResultSource;
        RETURN 0;
    END;
    IF OBJECT_ID(N'toolbelt_file.TVF_InternalXlsxCells',N'FT') IS NULL
        THROW 51529,N'Der interne XLSX-Provider fehlt.',1;
    DECLARE @CellsSnapshot TABLE
    (ErrorNumber int NULL, ErrorMessage nvarchar(4000) NULL,
        [RowOrdinal] int NULL,
        [ColumnOrdinal] int NULL,
        [StoredType] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [ValuePresent] bit NULL,
        [RawValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [TextValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaPresent] bit NULL,
        [FormulaText] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaKind] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [SharedFormulaIndex] int NULL,
        [CachePresent] bit NULL,
        [CacheValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL
    );
    INSERT @CellsSnapshot SELECT ErrorNumber,ErrorMessage,[RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue]
    FROM toolbelt_file.TVF_InternalXlsxCells(@XlsxBinary,@SheetOrdinal,@MaxArchiveBytes,@MaxPartBytes,@MaxTotalUncompressedBytes,@MaxParts,@MaxSheets,@MaxCells,@MaxSharedStrings,@MaxSharedStringBytes,@MaxXmlDepth,@MaxCompressionRatio,@BudgetMilliseconds);
    IF EXISTS(SELECT 1 FROM @CellsSnapshot WHERE ErrorNumber IS NOT NULL)
    BEGIN
        IF (SELECT COUNT_BIG(*) FROM @CellsSnapshot)<>1
            THROW 51529,N'Inkonsistenter XLSX-Statusvertrag.',1;
        DECLARE @CellsError int,@CellsMessage nvarchar(2048);
        SELECT @CellsError=ErrorNumber,@CellsMessage=CONVERT(nvarchar(2048),ErrorMessage) FROM @CellsSnapshot;
        IF @CellsError<>51520 OR @CellsMessage IS NULL
            THROW 51529,N'Ungültiger XLSX-Statusvertrag.',1;
        THROW @CellsError,@CellsMessage,1;
    END;
    IF EXISTS(SELECT 1 FROM @CellsSnapshot WHERE [RowOrdinal] IS NULL OR [ColumnOrdinal] IS NULL OR [StoredType] IS NULL OR [ValuePresent] IS NULL OR [FormulaPresent] IS NULL OR [CachePresent] IS NULL)
        THROW 51529,N'Unvollständige XLSX-Datenzeile.',1;
    INSERT #tbx_ReadXlsxWorksheetCells_ResultSource([RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue]) SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM @CellsSnapshot;
    IF @Debug>0 RAISERROR(N'XLSX: validierter Ergebnissnapshot bereit.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM #tbx_ReadXlsxWorksheetCells_ResultSource ORDER BY RowOrdinal,ColumnOrdinal;
        RETURN 0;
    END;

 DECLARE @CellsDependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
 IF @CellsDependencyId IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@CellsDependencyId)<>5
 OR EXISTS(SELECT 1 FROM (VALUES (1,N'@ResultTableToAlter',231,256),(2,N'@LikeTable',231,1552),
(3,N'@KeepData',104,1),(4,N'@Debug',48,1),(5,N'@Hilfe',104,1)) expected(id,name,typeid,bytes)
     WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=@CellsDependencyId
       AND p.parameter_id=expected.id AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.name)
       AND p.system_type_id=expected.typeid AND p.max_length=expected.bytes AND p.is_output=0))
 THROW 51529,N'ResultTable-Schnittstelle fehlt oder ist abweichend.',1;
    DECLARE @CellsOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @CellsSavepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-',''),@CellsSavepointSet bit=0;
    BEGIN TRY
        IF @CellsOwnTransaction=1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @CellsSavepoint; SET @CellsSavepointSet=1; END;
        EXEC toolbelt_core.USP_PrepareResultTable
             @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ReadXlsxWorksheetCells_ResultSource',
             @KeepData=@KeepData,@Debug=@Debug;
        DECLARE @CellsSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)
           +N' ([RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue]) SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM #tbx_ReadXlsxWorksheetCells_ResultSource;';
        EXEC sys.sp_executesql @CellsSql;
        IF @CellsOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @CellsOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @CellsSavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @CellsSavepoint;
        THROW;
    END CATCH;
    RETURN 0;

    END;
END;
GO
