-- ============================================================================
-- Objekt: toolbelt_archive.USP_CreateZipFileFromEntries; Typ: Stored Procedure
-- Zweck: Vollständiges ZIP/Entry-Binary über den vorhandenen Windowsprovider schreiben.
-- Vertrag: ZIP_FILES_CONTRACT.md; USP 1.0; Version 1.0.0.
-- Dependencies: ZIP Memory >=1.4.0, Windows Filesystem/ResultTable >=1.0.0 lokal.
-- Rechte: bestehende EXECUTE-/NTFS-Rechte; kein GRANT/Owner-/Trust-/Configwechsel.
-- Plattform: Windows, SQL Server 2019/2022/2025; aktive Caller-TX abgewiesen.
-- Fehler: 54620-54624; kanonische Provider-/Enginefehler bleiben erhalten.
-- Performance: begrenzte vollständige Materialisierung; keine harte Gesamtfrist.
-- Einschränkung: keine SQL-/Dateisystematomarität, keine Verzeichnisanlage.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_archive.USP_CreateZipFileFromEntries
      @EntryTable sysname = NULL
    , @RootAlias sysname = NULL
    , @RelativePath nvarchar(4000) = NULL
    , @CompressionMethod varchar(max) = 'Stored'
    , @MaxEntries int = 256
    , @MaxEntryNameCodeUnits int = 1024
    , @MaxEntryBytes bigint = 16777216
    , @MaxTotalPayloadBytes bigint = 67108864
    , @MaxArchiveBytes bigint = 71303168
    , @MaxEnvelopeBytes bigint = 71303168
    , @WriterBudgetMilliseconds int = 30000
    , @Overwrite bit = 0
    , @ExecutionIdentity varchar(16) = 'Caller'
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-archive-usp-createzipfilefromentries"
-- description: "Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.archive.zip-files"
-- schema_name: "toolbelt_archive"
-- object_name: "USP_CreateZipFileFromEntries"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@EntryTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. Im Dateifassadenpfad zusätzlich kein #tbx_-Präfix oder eigener #ZipFiles_*Stage-Name."}, {"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; explizite Zieldatei, deren Verzeichnis bereits bestehen muss. ZIP-Namen werden nicht zu Zielpfaden."}, {"name": "@CompressionMethod", "sql_type": "varchar(max)", "sql_default": "'Stored'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryNameCodeUnits", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxTotalPayloadBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEnvelopeBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@WriterBudgetMilliseconds", "sql_type": "int", "sql_default": "30000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt."}, {"name": "@ExecutionIdentity", "sql_type": "varchar(16)", "sql_default": "'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. Dateifassade verlangt Namen 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Dateipublikation erfolgt vor SQL-Ausgabe und wird bei späterem Routingfehler nicht rückgängig gemacht."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.archive.zip-files/Source/USP_CreateZipFileFromEntries.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql", "Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql", "Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql", "Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_CreateZipFileFromEntries
--
-- ## Zweck und Einsatzfälle
--
-- Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.
--
-- ## Voraussetzungen
--
-- Windows-only mit lokalem ZIPfiles1.0.0-Profil, ZIPmemory1.4.0, Windowsfilesystem1.0.0 und ResultTable derselben Datenbank. Vorhandener aktiver Root mit AllowWrite, bestehendes Zielverzeichnis und NTFS-Rechte. Caller-Modus verlangt Windowsauthentifizierung. ServiceAccount nur bei expliziter Wahl mit toolbelt_filesystem_service_account und Root-AllowServiceAccount. Keine zentrale Cross-DB- oder Linuxroute.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|
-- | `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. Im Dateifassadenpfad zusätzlich kein #tbx_-Präfix oder eigener #ZipFiles_*Stage-Name. |
-- | `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; explizite Zieldatei, deren Verzeichnis bereits bestehen muss. ZIP-Namen werden nicht zu Zielpfaden. |
-- | `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
-- | `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
-- | `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. Dateifassade verlangt Namen 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Dateipublikation erfolgt vor SQL-Ausgabe und wird bei späterem Routingfehler nicht rückgängig gemacht. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- TechnischeDefaults ermöglichenHilfe;fachlichePflicht-NULLwertebleibenungültig. Typbindung/KürzungaufSQL-ParameterbreiteliegenvorderFachprüfung. KeineautomatischeRechte-/Root-/Identityeinrichtung.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `BytesWritten` | `bigint` | NOT NULL; BytesderbereitsveröffentlichtenDatei |
-- | `RootAlias` | `nvarchar(128)` | NOT NULL; vomWindowsprovidergebundenerRootalias |
-- | `RelativePath` | `nvarchar(4000)` | NOT NULL; vomWindowsprovidergebundenerrelativerZielpfad |
-- | `State` | `varchar(16)` | NOT NULL; bytegenaucompletednachDateipublikation |
--
-- Genau einevollständigeFachzeilebeiErfolg. ResultTableNULL direkteAusgabe,sonstlokalesCallerzielohnezusätzlichenFachresultset. Hilfe liefert bisherigezwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühesRETURN0 vorFachprüfung. NormalerErfolgsreturn0. Datei-ReceiptattestiertkeinegemeinsameSQL-Atomarität.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
-- CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
-- INSERT #ContosoEntries VALUES(1,N'contoso.txt',0x010203);
-- -- NurmitvorhandenemautorisiertemRoot/Zielverzeichnis;schreibteineDatei.
-- EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#ContosoEntries',@RootAlias=N'ContosoRoot',@RelativePath=N'out\contoso.zip';
-- DROP TABLE #ContosoEntries;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Dateifassade und tatsächlich benötigte Dependency-/Providerrechte. SELECT auf FileSystemRoot im Ausführungskontext, Root-AllowWrite und NTFS-Schreib-/Publikationsrechte. Windows-Calleridentität oder explizit zulässiger ServiceAccount, ohne Fallback. Keine zusätzliche DB-weite Metadatensicht aus diesem Skill ableiten; Signatursicht für benötigte Objekte bleibt erforderlich.
--
-- ## Ressourcenbedarf
--
-- Vollständige Memory-Stage, Windows-Stagingdatei und spätere SQL-Ergebniskopie. Memorylimits bleiben wirksam. Dateipublikation und SQL-Routing haben keine gemeinsame Rollbackgrenze. Cleanupfehler können Stagingreste hinterlassen. Keine harte Gesamtfrist, Peakheap- oder Festplattenkapazitätszusage.
--
-- ## Nebenwirkungen
--
-- Frühe Hilfe vor Fachzugriff. Caller-TX und XACT_STATE müssen0 sein. RootAlias/RelativePath sind erforderlich; vier eigene Stage-/Resulttemps dürfen nicht vorbelegt sein. Das Caller-ResultTable muss eine vorhandene lokale #Temp mit2..116UTF16-Einheiten sein, ohne Punkt, ##, #tbx_ oder eigene Stagenamen. Bei Create darf EntryTable keine eigene Stage und nicht dasselbe Objekt wie Output sein. Tatsächlich aufgerufene Signaturen von Memorywriter, Memoryextract, WriteBinaryFile und PrepareResultTable über sys.parameters prüfen. Das ist keine DB-weite Installations- oder Versionsattestation.
--
-- Create delegiert einmal an den Memorywriter, Extract einmal an den Memoryreader mit festem FailIfEncrypted1. Eigene feste Stage, KeepData0/Debug0. Genau eine vollständige Zeile mit konsistenter Payloadlänge, Method, Encryption und gegebenenfalls Entrybindung prüfen. Erst nach vollständiger Erzeugung beziehungsweise CRC-geprüfter Zielextraktion WriteBinaryFile außerhalb jeder eigenen SQL-TX aufrufen. Ausschließlich RootAlias/RelativePath bestimmen das Dateiziel. Der Windowsprovider erzwingt bestehende Root-, Identity-, NTFS- und Handlegrenzen, schreibt eine eigene .part-Stagingdatei und publiziert atomar. Keine Root- oder Verzeichnisanlage und kein Identityfallback.
--
-- Das Filesystemreceipt muss genau eine Zeile mit passender BytesWritten und bytegenauem State completed liefern. Vier Felder materialisieren. Optionales endgültiges ResultTable-DDL/INSERT erfolgt danach in eigener kurzer SQL-TX. Die Datei ist bereits veröffentlicht und bleibt auch bei späterem SQL-Routingfehler bestehen. Abschluss-PRINT und direkte Ausgabe folgen. CATCH versucht SQL-Rollback; ein sekundärer Rollbackfehler ersetzt den Primärfehler nicht. Kein kompensierendes Dateilöschen, keine SQL-/Dateisystem-Gesamtatomarität und kein automatischer Retry.
--
-- ## Fehlerbehandlung
--
-- 54620:ungültige Fassadenargumente;54621:Caller-TX;54622:fehlende/abweichende Signatur;54623:inkohärente Stage/Receipt;54624:private Temp-Kollision. Kanonische ZIP-, Filesystem-, Helper- und Enginefehler bleiben erhalten. Datei kann bereits veröffentlicht sein; kein Kompensationslöschen oder Retry.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SELECT @Hilfe=ISNULL(@Hilfe,0),@Debug=ISNULL(@Debug,0),@KeepData=ISNULL(@KeepData,0);
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_archive' AS sysname) AS SchemaName,
            CAST(N'USP_CreateZipFileFromEntries' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'BytesWritten', N'bigint', NULL, 0, NULL, CAST(N'Tatsächlich veröffentlichte Payloadbytes.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'Root-Alias aus dem Filesystemresultat.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'Relativer Zielpfad aus dem Filesystemresultat.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'Unveränderter Filesystemstatus completed.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf mit zuvor eingerichtetem Root-Alias.' AS nvarchar(max)), CAST(N'CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max)); INSERT #Entries VALUES(1,N''hello.txt'',0x4869); EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N''#Entries'',@RootAlias=N''ContosoOutput'',@RelativePath=N''hello.zip'';' AS nvarchar(max))),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Nach Publish kann SQL-Ausgabe scheitern; Datei bleibt bestehen. Vor Retry eigenen Zielzustand klären. Keine SQL-/Dateisystematomarität.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 2, NULL, NULL, NULL, NULL, NULL, CAST(N'Ein erfolgreicher unverschlüsselter leerer Entry wird als 0-Byte-Datei geschrieben; NULL oder Encryption wird niemals zu 0x umgedeutet.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Bestehende EXECUTE-/Ownershipchain-, Alias- und NTFS-Rechte; keine Rechtevergabe oder Identitätsfallback.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'54620-54624 TBX_ZIP_FILE_*; vorhandene ZIP-/Filesystem-/Helper- und Enginefehler unverändert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@EntryTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. Im Dateifassadenpfad zusätzlich kein #tbx_-Präfix oder eigener #ZipFiles_*Stage-Name.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; explizite Zieldatei, deren Verzeichnis bereits bestehen muss. ZIP-Namen werden nicht zu Zielpfaden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@CompressionMethod', N'varchar(max)', 0, 0, N'''Stored''', CAST(N'Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxEntries', N'int', 0, 0, N'256', CAST(N'Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxEntryNameCodeUnits', N'int', 0, 0, N'1024', CAST(N'Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxEntryBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxTotalPayloadBytes', N'bigint', 0, 0, N'67108864', CAST(N'Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@MaxArchiveBytes', N'bigint', 0, 0, N'71303168', CAST(N'Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@MaxEnvelopeBytes', N'bigint', 0, 0, N'71303168', CAST(N'Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@WriterBudgetMilliseconds', N'int', 0, 0, N'30000', CAST(N'Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Overwrite', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 14, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. Dateifassade verlangt Namen 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Dateipublikation erfolgt vor SQL-Ausgabe und wird bei späterem Routingfehler nicht rückgängig gemacht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 15, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 16, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 17, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_archive' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_CreateZipFileFromEntries' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-archive-usp-createzipfilefromentries"
description: "Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-files"
schema_name: "toolbelt_archive"
object_name: "USP_CreateZipFileFromEntries"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EntryTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. Im Dateifassadenpfad zusätzlich kein #tbx_-Präfix oder eigener #ZipFiles_*Stage-Name."}, {"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccoun' AS nvarchar(max)) + N't=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; explizite Zieldatei, deren Verzeichnis bereits bestehen muss. ZIP-Namen werden nicht zu Zielpfaden."}, {"name": "@CompressionMethod", "sql_type": "varchar(max)", "sql_default": "''Stored''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryNameCodeUnits", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses' + N' Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxTotalPayloadBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEnvelopeBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@WriterBudgetMilliseconds", "sql_type": "int", "sql_default": "30000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..60000, Default 30000: Millisekunden kooperat' + N'ives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt."}, {"name": "@ExecutionIdentity", "sql_type": "varchar(16)", "sql_default": "''Caller''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. Dateifassade ver' + N'langt Namen 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Dateipublikation erfolgt vor SQL-Ausgabe und wird bei späterem Routingfehler nicht rückgängig gemacht."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.archive.zip-files/Source/USP_CreateZipFileFromEntries.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql", "Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql", "Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql", "Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_vers' + N'ion: "1.0.0"
---

# USP_CreateZipFileFromEntries

## Zweck und Einsatzfälle

Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.

## Voraussetzungen

Windows-only mit lokalem ZIPfiles1.0.0-Profil, ZIPmemory1.4.0, Windowsfilesystem1.0.0 und ResultTable derselben Datenbank. Vorhandener aktiver Root mit AllowWrite, bestehendes Zielverzeichnis und NTFS-Rechte. Caller-Modus verlangt Windowsauthentifizierung. ServiceAccount nur bei expliziter Wahl mit toolbelt_filesystem_service_account und Root-AllowServiceAccount. Keine zentrale Cross-DB- oder Linuxroute.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. Im Dateifassadenpfad zusätzlich kein #tbx_-Präfix oder eigener #ZipFiles_*Stage-Name. |
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und' + N' bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; explizite Zieldatei, deren Verzeichnis bereits bestehen muss. ZIP-Namen werden nicht zu Zielpfaden. |
| `@CompressionMethod` | `varchar(max)` | `''Stored''` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
| `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entr' + N'ies. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `''Caller''` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Son' + N'st ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. Dateifassade verlangt Namen 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Dateipublikation erfolgt vor SQL-Ausgabe und wird bei späterem Routingfehler nicht rückgängig gemacht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

TechnischeDefaults ermöglichenHilfe;fachlichePflicht-NULLwertebleibenungültig. Typbindung/KürzungaufSQL-ParameterbreiteliegenvorderFachprüfung. KeineautomatischeRechte-/Root-/Identityeinrichtung.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `BytesWritten` | `bigint` | NOT NULL; BytesderbereitsveröffentlichtenDatei |
| `RootAlias` | `nvarchar(128)` | NOT NULL; vomWindowsprovidergebundenerRootalias |
| `RelativePath` | `nvarchar(4000)` | NOT NULL; vomWindowsprovidergebundenerrelativerZielpfad |
| `State` | `varchar(16)` | NOT NULL; bytegenaucompletednachDateipublika' + N'tion |

Genau einevollständigeFachzeilebeiErfolg. ResultTableNULL direkteAusgabe,sonstlokalesCallerzielohnezusätzlichenFachresultset. Hilfe liefert bisherigezwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühesRETURN0 vorFachprüfung. NormalerErfolgsreturn0. Datei-ReceiptattestiertkeinegemeinsameSQL-Atomarität.

## Aufrufbeispiele

```sql
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ContosoEntries VALUES(1,N''contoso.txt'',0x010203);
-- NurmitvorhandenemautorisiertemRoot/Zielverzeichnis;schreibteineDatei.
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N''#ContosoEntries'',@RootAlias=N''ContosoRoot'',@RelativePath=N''out\contoso.zip'';
DROP TABLE #ContosoEntries;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Dateifassade und tatsächlich benötigte Dependency-/Providerrechte. SELECT auf FileSystemRoot im Ausführungskontext, Root-AllowWrite und NTFS-Schreib-/Publikationsrechte. Windows-Calleridentität oder explizit zulässiger ServiceAccount, ohne Fallback. Keine zusätzliche DB-weite Metadatensicht aus diesem Skill ableiten; Signatursicht für benötigte Objekte bleibt erforderlich.

## Ressourcenbedarf

Vollständige Memory-Stage, Windows-Stagingdatei und spätere SQL-Ergebniskopie. Memorylimits bleiben wirksam. Dateipublikation und SQL-Routing haben keine gemeinsame Rollbackgrenze. Cleanupfehler können Stagingreste hinterlassen. Keine harte Gesamtfrist, Peakheap- oder Festplattenkapazitätszusage.

## Nebenwirkungen

Frühe Hilfe vor Fachzugriff. Caller-TX und XACT_STATE müssen0 sein. RootAlias/RelativePath sind erforderlich; vier eigene Stage-/Resulttemps dürfen nicht vorbelegt sein. Das Caller-ResultTable muss eine vorhandene lokale #Temp mit2..116UTF16-Einheiten sein, ohne Punkt, ##, #tbx_ oder eigene Stagenamen. Bei Create darf EntryTable kei' + N'ne eigene Stage und nicht dasselbe Objekt wie Output sein. Tatsächlich aufgerufene Signaturen von Memorywriter, Memoryextract, WriteBinaryFile und PrepareResultTable über sys.parameters prüfen. Das ist keine DB-weite Installations- oder Versionsattestation.

Create delegiert einmal an den Memorywriter, Extract einmal an den Memoryreader mit festem FailIfEncrypted1. Eigene feste Stage, KeepData0/Debug0. Genau eine vollständige Zeile mit konsistenter Payloadlänge, Method, Encryption und gegebenenfalls Entrybindung prüfen. Erst nach vollständiger Erzeugung beziehungsweise CRC-geprüfter Zielextraktion WriteBinaryFile außerhalb jeder eigenen SQL-TX aufrufen. Ausschließlich RootAlias/RelativePath bestimmen das Dateiziel. Der Windowsprovider erzwingt bestehende Root-, Identity-, NTFS- und Handlegrenzen, schreibt eine eigene .part-Stagingdatei und publiziert atomar. Keine Root- oder Verzeichnisanlage und kein Identityfallback.

Das Filesystemreceipt muss genau eine Zeile mit passender BytesWritten und bytegenauem State completed liefern. Vier Felder materialisieren. Optionales endgültiges ResultTable-DDL/INSERT erfolgt danach in eigener kurzer SQL-TX. Die Datei ist bereits veröffentlicht und bleibt auch bei späterem SQL-Routingfehler bestehen. Abschluss-PRINT und direkte Ausgabe folgen. CATCH versucht SQL-Rollback; ein sekundärer Rollbackfehler ersetzt den Primärfehler nicht. Kein kompensierendes Dateilöschen, keine SQL-/Dateisystem-Gesamtatomarität und kein automatischer Retry.

## Fehlerbehandlung

54620:ungültige Fassadenargumente;54621:Caller-TX;54622:fehlende/abweichende Signatur;54623:inkohärente Stage/Receipt;54624:private Temp-Kollision. Kanonische ZIP-, Filesystem-, Helper- und Enginefehler bleiben erhalten. Datei kann bereits veröffentlicht sein; kein Kompensationslöschen oder Retry.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise ' + N'bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    IF @@TRANCOUNT<>0 OR XACT_STATE()<>0
        THROW 54621,N'TBX_ZIP_FILE_CALLER_TRANSACTION_UNSUPPORTED: Dateipublikation benötigt einen transaktionsfreien Aufruf.',1;
    IF @RootAlias IS NULL OR DATALENGTH(@RootAlias)=0 OR @RelativePath IS NULL OR DATALENGTH(@RelativePath)=0
        THROW 54620,N'TBX_ZIP_FILE_INVALID_FACADE_ARGUMENT: RootAlias und RelativePath fehlen.',1;
    -- Enge Namingausnahme nur für diese statischen ResultTable-Brücken.
    IF OBJECT_ID(N'tempdb..#ZipFiles_CreateStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#ZipFiles_ExtractStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#ZipFiles_WriteStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_ZipFiles_Result',N'U') IS NOT NULL
        THROW 54624,N'TBX_ZIP_FILE_PRIVATE_TEMP_COLLISION: Eigener Tempname ist belegt.',1;
    IF @ResultTable IS NOT NULL AND
       (LEFT(@ResultTable,1)<>N'#' OR LEFT(@ResultTable,2)=N'##' OR DATALENGTH(@ResultTable) NOT BETWEEN 4 AND 232
        OR CHARINDEX(N'.',@ResultTable)>0
        OR LOWER(LEFT(@ResultTable,5) COLLATE Latin1_General_100_BIN2)=N'#tbx_'
        OR LOWER(@ResultTable COLLATE Latin1_General_100_BIN2) IN(N'#zipfiles_createstage',N'#zipfiles_extractstage',N'#zipfiles_writestage')
        OR OBJECT_ID(N'tempdb..'+QUOTENAME(@ResultTable),N'U') IS NULL)
        THROW 54620,N'TBX_ZIP_FILE_INVALID_FACADE_ARGUMENT: ResultTable muss eine vorhandene lokale Caller-Temp sein.',1;
    IF @EntryTable IS NULL OR LEFT(@EntryTable,1)<>N'#' OR LEFT(@EntryTable,2)=N'##'
       OR LOWER(LEFT(@EntryTable,5) COLLATE Latin1_General_100_BIN2)=N'#tbx_'
       OR LOWER(@EntryTable COLLATE Latin1_General_100_BIN2) IN(N'#zipfiles_createstage',N'#zipfiles_extractstage',N'#zipfiles_writestage')
       OR (@ResultTable IS NOT NULL AND OBJECT_ID(N'tempdb..'+QUOTENAME(@EntryTable),N'U')=OBJECT_ID(N'tempdb..'+QUOTENAME(@ResultTable),N'U'))
        THROW 54620,N'TBX_ZIP_FILE_INVALID_FACADE_ARGUMENT: Input und Output dürfen keine eigenen Temps oder dasselbe Objekt sein.',1;
    -- Keine zusätzliche DB-weite Metadatensicht für normale Aufrufer.
    -- Lokal gebundene Installation ist ein Paketprofil, kein Laufzeitmarker.
    -- Tatsächlich aufgerufene Schnittstellen prüfen; Engine-Rechte bleiben erhalten.
    DECLARE @Dependencies TABLE(ObjectName nvarchar(257),ParameterCount int,Ordinal int,
      ParameterName sysname,TypeId int,Bytes smallint,Precision tinyint,Scale tinyint);
    INSERT @Dependencies VALUES
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,1,N'@EntryTable',231,256,0,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,2,N'@CompressionMethod',167,-1,0,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,3,N'@MaxEntries',56,4,10,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,4,N'@MaxEntryNameCodeUnits',56,4,10,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,5,N'@MaxEntryBytes',127,8,19,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,6,N'@MaxTotalPayloadBytes',127,8,19,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,7,N'@MaxArchiveBytes',127,8,19,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,8,N'@MaxEnvelopeBytes',127,8,19,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,9,N'@WriterBudgetMilliseconds',56,4,10,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,10,N'@ResultTable',231,256,0,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,11,N'@KeepData',104,1,1,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,12,N'@Debug',48,1,3,0),
      (N'toolbelt_archive.USP_CreateZipFromEntries',13,13,N'@Hilfe',104,1,1,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,1,N'@ZipArchive',165,-1,0,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,2,N'@EntryName',231,2048,0,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,3,N'@MaxEntryBytes',127,8,19,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,4,N'@MaxCompressionRatio',106,5,9,2),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,5,N'@FailIfEncrypted',104,1,1,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,6,N'@ResultTable',231,256,0,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,7,N'@KeepData',104,1,1,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,8,N'@Debug',48,1,3,0),
      (N'toolbelt_archive.USP_ExtractZipEntryFromBinary',9,9,N'@Hilfe',104,1,1,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,1,N'@RootAlias',231,256,0,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,2,N'@RelativePath',231,8000,0,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,3,N'@Content',165,-1,0,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,4,N'@Overwrite',104,1,1,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,5,N'@ExecutionIdentity',167,16,0,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,6,N'@ResultTable',231,256,0,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,7,N'@KeepData',104,1,1,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,8,N'@Debug',48,1,3,0),
      (N'toolbelt_filesystem.USP_WriteBinaryFile',9,9,N'@Hilfe',104,1,1,0),
      (N'toolbelt_core.USP_PrepareResultTable',5,1,N'@ResultTableToAlter',231,256,0,0),
      (N'toolbelt_core.USP_PrepareResultTable',5,2,N'@LikeTable',231,1552,0,0),
      (N'toolbelt_core.USP_PrepareResultTable',5,3,N'@KeepData',104,1,1,0),
      (N'toolbelt_core.USP_PrepareResultTable',5,4,N'@Debug',48,1,3,0),
      (N'toolbelt_core.USP_PrepareResultTable',5,5,N'@Hilfe',104,1,1,0);
    IF EXISTS(SELECT 1 FROM @Dependencies d
        WHERE OBJECT_ID(d.ObjectName,N'P') IS NULL
        OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(d.ObjectName,N'P'))<>d.ParameterCount
        OR NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=OBJECT_ID(d.ObjectName,N'P')
            AND p.parameter_id=d.Ordinal AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),d.ParameterName)
            AND p.system_type_id=d.TypeId AND p.max_length=d.Bytes AND p.precision=d.Precision
            AND p.scale=d.Scale AND p.is_output=0))
      THROW 54622,N'TBX_ZIP_FILE_DEPENDENCY: Dependency-Schnittstellen fehlen oder sind abweichend.',1;
    DECLARE @Payload varbinary(max),@Sql nvarchar(max);
    BEGIN TRY
        CREATE TABLE #ZipFiles_CreateStage(ArchivePayload varbinary(max) NOT NULL,ArchiveBytes bigint NOT NULL,EntryCount int NOT NULL,TotalPayloadBytes bigint NOT NULL,CompressionMethod int NOT NULL);
        EXEC toolbelt_archive.USP_CreateZipFromEntries
            @EntryTable=@EntryTable,@CompressionMethod=@CompressionMethod,@MaxEntries=@MaxEntries,
            @MaxEntryNameCodeUnits=@MaxEntryNameCodeUnits,@MaxEntryBytes=@MaxEntryBytes,
            @MaxTotalPayloadBytes=@MaxTotalPayloadBytes,@MaxArchiveBytes=@MaxArchiveBytes,
            @MaxEnvelopeBytes=@MaxEnvelopeBytes,@WriterBudgetMilliseconds=@WriterBudgetMilliseconds,
            @ResultTable=N'#ZipFiles_CreateStage',@KeepData=0,@Debug=0,@Hilfe=0;
        IF (SELECT COUNT_BIG(*) FROM #ZipFiles_CreateStage)<>1
           OR EXISTS(SELECT 1 FROM #ZipFiles_CreateStage WHERE ArchivePayload IS NULL
                OR ArchiveBytes<>CONVERT(bigint,DATALENGTH(ArchivePayload)) OR ArchiveBytes<22
                OR EntryCount<0 OR TotalPayloadBytes<0 OR CompressionMethod NOT IN(0,8))
            THROW 54623,N'TBX_ZIP_FILE_INTERNAL_RESULT_INVALID: Writerstage ist nicht vollständig.',1;
        SELECT @Payload=ArchivePayload FROM #ZipFiles_CreateStage;
        -- Erst nach vollständiger ZIP-/CRC-Prüfung, außerhalb jeder eigenen SQL-TX.
        CREATE TABLE #ZipFiles_WriteStage(BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL);
        EXEC toolbelt_filesystem.USP_WriteBinaryFile
            @RootAlias=@RootAlias,@RelativePath=@RelativePath,@Content=@Payload,
            @Overwrite=@Overwrite,@ExecutionIdentity=@ExecutionIdentity,
            @ResultTable=N'#ZipFiles_WriteStage',@KeepData=0,@Debug=0,@Hilfe=0;
        IF (SELECT COUNT_BIG(*) FROM #ZipFiles_WriteStage)<>1
           OR EXISTS(SELECT 1 FROM #ZipFiles_WriteStage WHERE BytesWritten<>CONVERT(bigint,DATALENGTH(@Payload))
                OR CONVERT(varbinary(max),State)<>CONVERT(varbinary(max),'completed'))
            THROW 54623,N'TBX_ZIP_FILE_INTERNAL_RESULT_INVALID: Filesystemstatus ist nicht eindeutig.',1;
        CREATE TABLE #tbx_ZipFiles_Result(BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL);
        INSERT #tbx_ZipFiles_Result(BytesWritten,RootAlias,RelativePath,State)
            SELECT BytesWritten,RootAlias,RelativePath,State FROM #ZipFiles_WriteStage;
        IF @ResultTable IS NOT NULL
        BEGIN
            -- Nur SQL-Zieldaten sind gemeinsam rückrollbar; Datei bleibt veröffentlicht.
            BEGIN TRANSACTION;
            EXEC toolbelt_core.USP_PrepareResultTable
                @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ZipFiles_Result',
                @KeepData=@KeepData,@Debug=@Debug,@Hilfe=0;
            SET @Sql=N'INSERT '+QUOTENAME(@ResultTable)+N'(BytesWritten,RootAlias,RelativePath,State) SELECT BytesWritten,RootAlias,RelativePath,State FROM #tbx_ZipFiles_Result;';
            EXEC sys.sp_executesql @Sql;
            COMMIT TRANSACTION;
        END;
        IF @Debug>0 PRINT N'ZIP-Datei: Dateipublikation und SQL-Ausgabe abgeschlossen.';
        IF @ResultTable IS NULL SELECT BytesWritten,RootAlias,RelativePath,State FROM #tbx_ZipFiles_Result;
        -- Alle eigenen statisch angelegten Temps enden automatisch mit dem Scope.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Kein Caller-TX wurde angenommen. Ein Cleanupfehler ersetzt niemals den Primärfehler.
        BEGIN TRY
            IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        END TRY
        BEGIN CATCH
            PRINT N'TBX_ZIP_FILE_SECONDARY_SQL_ROLLBACK_FAILED';
        END CATCH;
        -- Kein Filesystem-Rollback oder kompensierendes Löschen.
        THROW;
    END CATCH;
END;
GO
