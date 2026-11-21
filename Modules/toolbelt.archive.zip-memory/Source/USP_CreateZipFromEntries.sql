-- ============================================================================
-- Objekt: toolbelt_archive.USP_CreateZipFromEntries; Typ: Stored Procedure
-- Zweck: Begrenztes In-memory-ZIP aus caller-lokaler Entrytabelle erzeugen.
-- Vertrag: Documentation/USP_CreateZipFromEntries.md; USP_CONTRACT 1.0.
-- Parameter: EntryTable, Stored/Deflate, positive Ressourcenlimits; Standard-
-- Defaults 256 Entries/16 MiB Entry/64 MiB Summe/68 MiB Output und Envelope.
-- Resultset: ArchivePayload, ArchiveBytes, EntryCount, TotalPayloadBytes,
-- CompressionMethod; Dependencies: SAFE-ZIP-CLR, ResultTable >=1.0.0.
-- Rechte: EXECUTE, eigene lokale Temps; keine Rechte-/Trustausweitung.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehler: 51350–51359; keine Teilarchive, callerfreundliche Savepoints.
-- Performance: Snapshot/Envelope/Output materialisiert, LOB-.WRITE statt
-- wachsender Variablenkonkatenation; CLR-Budget kooperativ, kein SQL-Timeout.
-- Einschränkungen: kein Datei-I/O/ZIP64/TVP/Encryption; Readerlimits bleiben.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_archive.USP_CreateZipFromEntries
      @EntryTable sysname = NULL
    , @CompressionMethod varchar(max) = 'Stored'
    , @MaxEntries int = 256
    , @MaxEntryNameCodeUnits int = 1024
    , @MaxEntryBytes bigint = 16777216
    , @MaxTotalPayloadBytes bigint = 67108864
    , @MaxArchiveBytes bigint = 71303168
    , @MaxEnvelopeBytes bigint = 71303168
    , @WriterBudgetMilliseconds int = 30000
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-archive-usp-createzipfromentries"
-- description: "Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.archive.zip-memory"
-- schema_name: "toolbelt_archive"
-- object_name: "USP_CreateZipFromEntries"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@EntryTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation."}, {"name": "@CompressionMethod", "sql_type": "varchar(max)", "sql_default": "'Stored'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryNameCodeUnits", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxTotalPayloadBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEnvelopeBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@WriterBudgetMilliseconds", "sql_type": "int", "sql_default": "30000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.4.0"
-- ---
--
-- # USP_CreateZipFromEntries
--
-- ## Zweck und Einsatzfälle
--
-- Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.
--
-- ## Voraussetzungen
--
-- ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|
-- | `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. |
-- | `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
-- | `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. |
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
-- | `ArchivePayload` | `varbinary(max)` | NOT NULL; vollständigesZIPbinary |
-- | `ArchiveBytes` | `bigint` | NOT NULL; DATALENGTH desfinalisiertenArchivs |
-- | `EntryCount` | `int` | NOT NULL; AnzahlEntries,auch0 |
-- | `TotalPayloadBytes` | `bigint` | NOT NULL; Summe unkomprimierterEntrybytes |
-- | `CompressionMethod` | `int` | NOT NULL; 0Stored,8Deflate;ListekannweitereMethodenbeschreiben |
--
-- Genau einevollständigeFachzeilebeiErfolg. ResultTableNULL direkteAusgabe,sonstlokalesCallerzielohnezusätzlichenFachresultset. Hilfe liefert bisherigezwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühesRETURN0 vorFachprüfung. NormalerErfolgsreturn0. Datei-ReceiptattestiertkeinegemeinsameSQL-Atomarität.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
-- CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
-- INSERT #ContosoEntries VALUES(1,N'contoso.txt',0x010203);
-- EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ContosoEntries';
-- DROP TABLE #ContosoEntries;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Memory-USP und gezielte SELECT-Rechte auf benötigte interne CLR-TVFs gemäß Modulvertrag. Writer braucht die ResultTable-Schnittstelle für beide Ausgaben; Reader Helper-EXECUTE nur bei ResultTable. Leserechte auf Caller-Temps und Metadatensicht für Writer, tempdb.sys.columns und spezifische sys.parameters-Sicht. Interne Kennzeichnung ist kein Verbot notwendiger Providerberechtigungen, aber kein Freibrief für allgemeine Direktnutzung. Keine Filesystemrechte für den Memorypfad.
--
-- ## Ressourcenbedarf
--
-- Writergrenzen:Entries1..1024, Namen1..2048Codeunits, Entry1..33554432, Summe1..134217728, ZIP1..150994944, Envelope1..142606336, Budget1..60000ms. Readergrenzen:268435456Archivbytes,10000Entries,1024Namenseinheiten, komprimiert134217728, extrahiert maximal67108864. Reader hat keinen eigenen Timer. Snapshot-, Envelope-, Seek- und Transportkopien, Deflatepuffer und CRC kosten zusätzlich Speicher/CPU. Kooperatives Writerbudget ist keine harte Wallclock-, Heap- oder SQL-Transportquote.
--
-- ## Nebenwirkungen
--
-- Die öffentliche Fassade normalisiert KeepData/Debug/Hilfe bei NULL zu 0 und liefert frühe Hilfe. Sie prüft Stored/Deflate byte- und längengenau, endliche Ressourcenlimits und die beiden Writer-TVFs. Die fünfparametrige PrepareResultTable-Schnittstelle wird auch ohne Ausgabeziel geprüft. Input und Output müssen verschiedene sichtbare lokale Caller-Temps ohne Punkt oder ## sein; Writer-Helpernamen sind reserviert. Inputspalten: Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed oder verschlüsselt. Geprüft werden system_type_id/max_length, kein zusätzlicher user_type_id-Gleichheitsguard. LEN-Namensgrenzen folgen SQL-Space-Semantik.
--
-- Doomed Caller werden abgewiesen. Eigene Transaktion oder eigener Savepoint; HOLDLOCK stabilisiert Preflight und Snapshot. Keine parallele MARS-/Caller-Mutation derselben Temps. Positive eindeutige Ordinals, nichtNULL-Fachwerte, Count-, Entry- und Summengrenzen vor privater Payloadkopie prüfen. Die Name-TVF codiert wohlgeformtes UTF16 streng nach UTF8. Duplikate nach exakten Namensbytes und Länge abweisen. Envelopegröße:12+Payloadsumme+16*Count+Namensbytes. In Ordinalreihenfolge Little-endian-TBZW-V1-Envelope mittels lokaler LOB-.WRITE-Operationen bilden.
--
-- Die Archive-TVF kopiert den begrenzten Envelope einmal in eigenen seekbaren Speicher. Header, Version, Count, steigende Ordinals, UTF8-Namen, Ressourcen und Restfreiheit prüfen. Stored0 oder Deflate8; CRC32 bei Payloadverarbeitung, UTF8-Flag und feste DOS-Zeit1980-01-01. Lokale Header nachtragen, CentralDirectory und EOCD finalisieren. Keine ZIP64-, Multi-Disk-, Encryption-, Verzeichnisentry- oder Extrafeldunterstützung. Leere Eingabe erzeugt ein22Byte-EOCD-ZIP. Der kooperative CLR-Timer umfasst Kopie, Writer und Finalisierung; SQL-Preflight, Envelopebau und Ergebnistransport liegen außerhalb.
--
-- Eine Writer-Statuszeile: ErrorNumber0 und nichtNULL-Payload bei Erfolg. Die Fassade prüft den Status und materialisiert fünf Ergebnisfelder. Optionales Helper-DDL/INSERT gehört zur Transaktion beziehungsweise zum Savepoint. Eigener Commit vor Abschluss-PRINT und direkter Ausgabe; im CATCH eigener Rollback oder committable eigener Savepointrollback. Kein Dateizugriff. Writer-Namenslimit2048 und Readerlimit1024 sind verschieden. Deflatebytes haben keine pauschale plattformübergreifende Bitgleichheitszusage.
--
-- ## Fehlerbehandlung
--
-- Reader:51320 Argumente,51321 Struktur/Encoding/Stream,51322 Name fehlt,51323 gesuchter Name doppelt,51324 Encryption verboten,51325 Ressourcen,51326 Ratio,51327 Format/Method,51328 Integrität,51329 Wrapper/Dependency. Writer:51350 Argumente,51351 SQL-Inputshape,51352 Name,51353 Namensduplikat,51354 Ressourcen,51355 Format/Overflow,51356 Timeout,51357 Dependency,51358 Transport,51359 Providerstatus. Status-TVFs wandeln nur explizit gefangene Fehler um; unerwartete CLR-/Enginefehler bleiben Originalexceptions. Reader-ErfolgNULL, Writer-Erfolg0. Öffentliche Fassaden werfen statt einer Teilpayload.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData=ISNULL(@KeepData,0), @Debug=ISNULL(@Debug,0), @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_archive' AS sysname) AS SchemaName,
            CAST(N'USP_CreateZipFromEntries' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'ArchivePayload', N'varbinary(max)', NULL, 0, NULL, CAST(N'Vollständig finalisiertes ZIP-Binary.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ArchiveBytes', N'bigint', NULL, 0, NULL, CAST(N'Tatsächliche Archivgröße in Bytes.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'EntryCount', N'int', NULL, 0, NULL, CAST(N'Anzahl vorhandener Dateien, leere Liste erlaubt.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'TotalPayloadBytes', N'bigint', NULL, 0, NULL, CAST(N'Summe unkomprimierter Payloadbytes.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'CompressionMethod', N'int', NULL, 0, NULL, CAST(N'ZIP-Methode 0 Stored oder 8 Deflate.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer In-memory-Aufruf.' AS nvarchar(max)), CAST(N'CREATE TABLE #ZipInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); INSERT #ZipInput VALUES(1,N''hello.txt'',0x4869); EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N''#ZipInput'';' AS nvarchar(max))),
        (N'ERROR', 1, N'51350-51359', NULL, NULL, NULL, NULL, CAST(N'TBX_ZIP_WRITE_*; kein Teiloutput; Original-Enginefehler und Callertransaktionszustand erhalten.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@EntryTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@CompressionMethod', N'varchar(max)', 0, 0, N'''Stored''', CAST(N'Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxEntries', N'int', 0, 0, N'256', CAST(N'Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxEntryNameCodeUnits', N'int', 0, 0, N'1024', CAST(N'Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxEntryBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxTotalPayloadBytes', N'bigint', 0, 0, N'67108864', CAST(N'Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxArchiveBytes', N'bigint', 0, 0, N'71303168', CAST(N'Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxEnvelopeBytes', N'bigint', 0, 0, N'71303168', CAST(N'Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@WriterBudgetMilliseconds', N'int', 0, 0, N'30000', CAST(N'Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_archive' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_CreateZipFromEntries' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-archive-usp-createzipfromentries"
description: "Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "USP_CreateZipFromEntries"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EntryTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation."}, {"name": "@CompressionMethod", "sql_type": "varchar(max)", "sql_default": "''Stored''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable":' AS nvarchar(max)) + N' false, "description": "Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryNameCodeUnits", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxTotalPayloadBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEnvelopeBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "desc' + N'ription": "Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@WriterBudgetMilliseconds", "sql_type": "int", "sql_default": "30000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NUL' + N'L wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.4.0"
---

# USP_CreateZipFromEntries

## Zweck und Einsatzfälle

Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.

## Voraussetzungen

ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-1' + N'6-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. |
| `@CompressionMethod` | `varchar(max)` | `''Stored''` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
| `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEnvelopeBytes` | `bigint` | `713031' + N'68` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

TechnischeDefaults ermöglichenHilfe;fachlichePflicht-NULLwertebleibenungültig. ' + N'Typbindung/KürzungaufSQL-ParameterbreiteliegenvorderFachprüfung. KeineautomatischeRechte-/Root-/Identityeinrichtung.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `ArchivePayload` | `varbinary(max)` | NOT NULL; vollständigesZIPbinary |
| `ArchiveBytes` | `bigint` | NOT NULL; DATALENGTH desfinalisiertenArchivs |
| `EntryCount` | `int` | NOT NULL; AnzahlEntries,auch0 |
| `TotalPayloadBytes` | `bigint` | NOT NULL; Summe unkomprimierterEntrybytes |
| `CompressionMethod` | `int` | NOT NULL; 0Stored,8Deflate;ListekannweitereMethodenbeschreiben |

Genau einevollständigeFachzeilebeiErfolg. ResultTableNULL direkteAusgabe,sonstlokalesCallerzielohnezusätzlichenFachresultset. Hilfe liefert bisherigezwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühesRETURN0 vorFachprüfung. NormalerErfolgsreturn0. Datei-ReceiptattestiertkeinegemeinsameSQL-Atomarität.

## Aufrufbeispiele

```sql
EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;
CREATE TABLE #ContosoEntries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #ContosoEntries VALUES(1,N''contoso.txt'',0x010203);
EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N''#ContosoEntries'';
DROP TABLE #ContosoEntries;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Memory-USP und gezielte SELECT-Rechte auf benötigte interne CLR-TVFs gemäß Modulvertrag. Writer braucht die ResultTable-Schnittstelle für beide Ausgaben; Reader Helper-EXECUTE nur bei ResultTable. Leserechte auf Caller-Temps und Metadatensicht für Writer, tempdb.sys.columns und spezifische sys.parameters-Sicht. Interne Kennzeichnung ist kein Verbot notwendiger Providerberechtigungen, aber kein Freibrief für allgemeine Direktnutzung. Keine Filesystemrechte für den Memorypfad.

## Ressourcenbedarf

Writergrenzen:Entries1..1024, Namen1..2048Codeunits, Entry1..33554432, Summe1..134217728, ZIP1..150994944, Envelope1..142606336, Bud' + N'get1..60000ms. Readergrenzen:268435456Archivbytes,10000Entries,1024Namenseinheiten, komprimiert134217728, extrahiert maximal67108864. Reader hat keinen eigenen Timer. Snapshot-, Envelope-, Seek- und Transportkopien, Deflatepuffer und CRC kosten zusätzlich Speicher/CPU. Kooperatives Writerbudget ist keine harte Wallclock-, Heap- oder SQL-Transportquote.

## Nebenwirkungen

Die öffentliche Fassade normalisiert KeepData/Debug/Hilfe bei NULL zu 0 und liefert frühe Hilfe. Sie prüft Stored/Deflate byte- und längengenau, endliche Ressourcenlimits und die beiden Writer-TVFs. Die fünfparametrige PrepareResultTable-Schnittstelle wird auch ohne Ausgabeziel geprüft. Input und Output müssen verschiedene sichtbare lokale Caller-Temps ohne Punkt oder ## sein; Writer-Helpernamen sind reserviert. Inputspalten: Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed oder verschlüsselt. Geprüft werden system_type_id/max_length, kein zusätzlicher user_type_id-Gleichheitsguard. LEN-Namensgrenzen folgen SQL-Space-Semantik.

Doomed Caller werden abgewiesen. Eigene Transaktion oder eigener Savepoint; HOLDLOCK stabilisiert Preflight und Snapshot. Keine parallele MARS-/Caller-Mutation derselben Temps. Positive eindeutige Ordinals, nichtNULL-Fachwerte, Count-, Entry- und Summengrenzen vor privater Payloadkopie prüfen. Die Name-TVF codiert wohlgeformtes UTF16 streng nach UTF8. Duplikate nach exakten Namensbytes und Länge abweisen. Envelopegröße:12+Payloadsumme+16*Count+Namensbytes. In Ordinalreihenfolge Little-endian-TBZW-V1-Envelope mittels lokaler LOB-.WRITE-Operationen bilden.

Die Archive-TVF kopiert den begrenzten Envelope einmal in eigenen seekbaren Speicher. Header, Version, Count, steigende Ordinals, UTF8-Namen, Ressourcen und Restfreiheit prüfen. Stored0 oder Deflate8; CRC32 bei Payloadverarbeitung, UTF8-Flag und feste DOS-Zeit1980-01-01. Lokale Header nachtragen, CentralDirectory und EOCD finalisieren. Keine ZIP64-, Multi-Disk-, Encryption-, Verzeichnisentry- ode' + N'r Extrafeldunterstützung. Leere Eingabe erzeugt ein22Byte-EOCD-ZIP. Der kooperative CLR-Timer umfasst Kopie, Writer und Finalisierung; SQL-Preflight, Envelopebau und Ergebnistransport liegen außerhalb.

Eine Writer-Statuszeile: ErrorNumber0 und nichtNULL-Payload bei Erfolg. Die Fassade prüft den Status und materialisiert fünf Ergebnisfelder. Optionales Helper-DDL/INSERT gehört zur Transaktion beziehungsweise zum Savepoint. Eigener Commit vor Abschluss-PRINT und direkter Ausgabe; im CATCH eigener Rollback oder committable eigener Savepointrollback. Kein Dateizugriff. Writer-Namenslimit2048 und Readerlimit1024 sind verschieden. Deflatebytes haben keine pauschale plattformübergreifende Bitgleichheitszusage.

## Fehlerbehandlung

Reader:51320 Argumente,51321 Struktur/Encoding/Stream,51322 Name fehlt,51323 gesuchter Name doppelt,51324 Encryption verboten,51325 Ressourcen,51326 Ratio,51327 Format/Method,51328 Integrität,51329 Wrapper/Dependency. Writer:51350 Argumente,51351 SQL-Inputshape,51352 Name,51353 Namensduplikat,51354 Ressourcen,51355 Format/Overflow,51356 Timeout,51357 Dependency,51358 Transport,51359 Providerstatus. Status-TVFs wandeln nur explizit gefangene Fehler um; unerwartete CLR-/Enginefehler bleiben Originalexceptions. Reader-ErfolgNULL, Writer-Erfolg0. Öffentliche Fassaden werfen statt einer Teilpayload.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @CompressionMethod IS NULL OR
       NOT ((@CompressionMethod COLLATE Latin1_General_100_BIN2 = 'Stored' AND DATALENGTH(@CompressionMethod)=6)
         OR (@CompressionMethod COLLATE Latin1_General_100_BIN2 = 'Deflate' AND DATALENGTH(@CompressionMethod)=7))
       OR @MaxEntries IS NULL OR @MaxEntries NOT BETWEEN 1 AND 1024
       OR @MaxEntryNameCodeUnits IS NULL OR @MaxEntryNameCodeUnits NOT BETWEEN 1 AND 2048
       OR @MaxEntryBytes IS NULL OR @MaxEntryBytes NOT BETWEEN 1 AND 33554432
       OR @MaxTotalPayloadBytes IS NULL OR @MaxTotalPayloadBytes NOT BETWEEN 1 AND 134217728
       OR @MaxArchiveBytes IS NULL OR @MaxArchiveBytes NOT BETWEEN 1 AND 150994944
       OR @MaxEnvelopeBytes IS NULL OR @MaxEnvelopeBytes NOT BETWEEN 1 AND 142606336
       OR @WriterBudgetMilliseconds IS NULL OR @WriterBudgetMilliseconds NOT BETWEEN 1 AND 60000
        THROW 51350,N'TBX_ZIP_WRITE_INVALID_ARGUMENT: Parameter oder Ressourcenlimit ungültig.',1;
    IF OBJECT_ID(N'toolbelt_archive.TVF_InternalZipWriterName',N'FT') IS NULL
       OR OBJECT_ID(N'toolbelt_archive.TVF_InternalZipWriterArchive',N'FT') IS NULL
        THROW 51357,N'TBX_ZIP_WRITE_DEPENDENCY: ZIP-Writer-Schnittstelle fehlt.',1;
DECLARE @CoreDependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
 IF @CoreDependencyId IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@CoreDependencyId)<>5
 OR EXISTS(SELECT 1 FROM (VALUES (1,N'@ResultTableToAlter',231,256),(2,N'@LikeTable',231,1552),
(3,N'@KeepData',104,1),(4,N'@Debug',48,1),(5,N'@Hilfe',104,1)) expected(id,name,typeid,bytes)
     WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=@CoreDependencyId
       AND p.parameter_id=expected.id AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.name)
       AND p.system_type_id=expected.typeid AND p.max_length=expected.bytes AND p.is_output=0))
 THROW 51357,N'TBX_ZIP_WRITE_DEPENDENCY: ResultTable-Schnittstelle fehlt oder ist abweichend.',1;
    IF @EntryTable IS NULL OR LEFT(@EntryTable,1)<>N'#' OR LEFT(@EntryTable,2)=N'##'
       OR LEN(@EntryTable)>116 OR CHARINDEX(N'.',@EntryTable)>0
       OR (@ResultTable IS NOT NULL AND (LEFT(@ResultTable,1)<>N'#' OR LEFT(@ResultTable,2)=N'##' OR LEN(@ResultTable)>116 OR CHARINDEX(N'.',@ResultTable)>0))
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Nur vorhandene caller-lokale Temps sind zulässig.',1;
    DECLARE @InputId int=OBJECT_ID(N'tempdb..'+QUOTENAME(@EntryTable),N'U'),
            @OutputId int=CASE WHEN @ResultTable IS NOT NULL THEN OBJECT_ID(N'tempdb..'+QUOTENAME(@ResultTable),N'U') END;
    IF @InputId IS NULL OR (@ResultTable IS NOT NULL AND @OutputId IS NULL) OR @InputId=@OutputId
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Temp fehlt oder Input und Output sind identisch.',2;
    IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@InputId AND
          ((name COLLATE Latin1_General_100_BIN2=N'Ordinal' AND system_type_id=56 AND max_length=4)
          OR (name COLLATE Latin1_General_100_BIN2=N'EntryName' AND system_type_id=231 AND max_length=-1)
          OR (name COLLATE Latin1_General_100_BIN2=N'Payload' AND system_type_id=165 AND max_length=-1))
          AND is_computed=0 AND encryption_type IS NULL) <> 3
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Erwartet Ordinal int, EntryName nvarchar(max), Payload varbinary(max).',3;
    IF XACT_STATE()=-1 THROW 51350,N'TBX_ZIP_WRITE_INVALID_ARGUMENT: Callertransaktion nicht committable.',2;
    IF LEFT(@EntryTable,15)=N'#tbx_ZipWriter_' OR LEFT(@ResultTable,15)=N'#tbx_ZipWriter_'
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Interne Helpernamen sind reserviert.',4;

    -- Keine MARS-/Parallelmutation derselben Caller-Temps während des
    -- synchronen Aufrufs. Eine Lese-Transaktion stabilisiert Preflight/Snapshot.
    DECLARE @OwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @SavepointSet bit=0,
            @Savepoint varchar(32)='tbxZW'+REPLACE(CONVERT(varchar(36),NEWID()),'-',''),
            @Sql nvarchar(max), @Count bigint, @Total bigint, @Invalid bigint,
            @TooLarge bigint, @Duplicate bigint, @Envelope varbinary(max),
            @Archive varbinary(max), @Method int=CASE WHEN @CompressionMethod='Stored' THEN 0 ELSE 8 END;
    BEGIN TRY
        IF @OwnTransaction=1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @SavepointSet=1; END;
        SET @Sql=N'SELECT @Count=COUNT_BIG(*), @Total=COALESCE(SUM(CONVERT(bigint,DATALENGTH(Payload))),0),
          @Invalid=COALESCE(SUM(CONVERT(bigint,CASE WHEN Ordinal IS NULL OR Ordinal<1 OR EntryName IS NULL OR Payload IS NULL THEN 1 ELSE 0 END)),0),
          @TooLarge=COALESCE(SUM(CONVERT(bigint,CASE WHEN DATALENGTH(Payload)>@EntryMax OR DATALENGTH(EntryName)>CONVERT(bigint,@NameMax)*2 THEN 1 ELSE 0 END)),0)
          FROM '+QUOTENAME(@EntryTable)+N' WITH(HOLDLOCK);
          SELECT @Duplicate=COUNT_BIG(*) FROM(SELECT Ordinal FROM '+QUOTENAME(@EntryTable)+N' GROUP BY Ordinal HAVING COUNT_BIG(*)>1)d;';
        EXEC sys.sp_executesql @Sql,N'@Count bigint OUTPUT,@Total bigint OUTPUT,@Invalid bigint OUTPUT,@TooLarge bigint OUTPUT,@Duplicate bigint OUTPUT,@EntryMax bigint,@NameMax int',
            @Count OUTPUT,@Total OUTPUT,@Invalid OUTPUT,@TooLarge OUTPUT,@Duplicate OUTPUT,@MaxEntryBytes,@MaxEntryNameCodeUnits;
        IF @Invalid>0 OR @Duplicate>0 THROW 51350,N'TBX_ZIP_WRITE_INVALID_ARGUMENT: NULL, ungültige oder doppelte Ordinals.',3;
        IF @Count>@MaxEntries OR @Total>@MaxTotalPayloadBytes OR @TooLarge>0
            THROW 51354,N'TBX_ZIP_WRITE_RESOURCE_LIMIT: Input überschreitet die Ressourcenlimits.',1;
        CREATE TABLE #tbx_ZipWriter_Snapshot(Ordinal int NOT NULL PRIMARY KEY, EntryName nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL, Payload varbinary(max) NOT NULL, NameBytes varbinary(max) NULL, NameError int NULL);
        SET @Sql=N'INSERT #tbx_ZipWriter_Snapshot(Ordinal,EntryName,Payload) SELECT Ordinal,EntryName,Payload FROM '+QUOTENAME(@EntryTable)+N' WITH(HOLDLOCK);';
        EXEC sys.sp_executesql @Sql;
        -- Encoding wird vor verlustbehafteter UTF8-Konvertierung durch CLR mit
        -- Exceptionfallback validiert; Namensduplikate inklusive Länge/Bytes.
        UPDATE s SET NameBytes=p.Payload,NameError=p.ErrorNumber
        FROM #tbx_ZipWriter_Snapshot s CROSS APPLY toolbelt_archive.TVF_InternalZipWriterName(EntryName COLLATE DATABASE_DEFAULT,@MaxEntryNameCodeUnits) p;
        IF EXISTS(SELECT 1 FROM #tbx_ZipWriter_Snapshot WHERE NameError IS NULL OR NameError<>0 OR NameBytes IS NULL)
            THROW 51352,N'TBX_ZIP_WRITE_INVALID_NAME: Name oder UTF-16 ungültig.',1;
        IF EXISTS(SELECT 1 FROM #tbx_ZipWriter_Snapshot a JOIN #tbx_ZipWriter_Snapshot b ON a.Ordinal<b.Ordinal
            AND DATALENGTH(a.NameBytes)=DATALENGTH(b.NameBytes) AND a.NameBytes=b.NameBytes)
            THROW 51353,N'TBX_ZIP_WRITE_DUPLICATE_NAME: Binär identische Namen.',1;
        DECLARE @EnvelopeSize bigint=12+@Total+@Count*16+(SELECT COALESCE(SUM(CONVERT(bigint,DATALENGTH(NameBytes))),0) FROM #tbx_ZipWriter_Snapshot);
        IF @EnvelopeSize>@MaxEnvelopeBytes THROW 51354,N'TBX_ZIP_WRITE_RESOURCE_LIMIT: Envelope inklusive Namen/Framing zu groß.',2;
        CREATE TABLE #tbx_ZipWriter_Envelope(Value varbinary(max) NOT NULL);
        DECLARE @CountBinary binary(4)=CONVERT(binary(4),CONVERT(int,@Count));
        INSERT #tbx_ZipWriter_Envelope VALUES(0x54425A5701000000+SUBSTRING(@CountBinary,4,1)+SUBSTRING(@CountBinary,3,1)+SUBSTRING(@CountBinary,2,1)+SUBSTRING(@CountBinary,1,1));
        DECLARE @Ordinal int,@Name varbinary(max),@Payload varbinary(max),@Chunk varbinary(max);
        DECLARE EntryCursor CURSOR LOCAL FAST_FORWARD FOR SELECT Ordinal,NameBytes,Payload FROM #tbx_ZipWriter_Snapshot ORDER BY Ordinal;
        OPEN EntryCursor;
        FETCH NEXT FROM EntryCursor INTO @Ordinal,@Name,@Payload;
        WHILE @@FETCH_STATUS=0
        BEGIN
            -- REVERSE(binary) liefert varchar und ist deshalb kein sicherer
            -- Binarytransport. Byteweise SUBSTRING bleibt varbinary.
            DECLARE @OrdinalBinary binary(4)=CONVERT(binary(4),@Ordinal),@NameBinary binary(4)=CONVERT(binary(4),DATALENGTH(@Name)),@PayloadBinary binary(8)=CONVERT(binary(8),CONVERT(bigint,DATALENGTH(@Payload)));
            SET @Chunk=SUBSTRING(@OrdinalBinary,4,1)+SUBSTRING(@OrdinalBinary,3,1)+SUBSTRING(@OrdinalBinary,2,1)+SUBSTRING(@OrdinalBinary,1,1)
              +SUBSTRING(@NameBinary,4,1)+SUBSTRING(@NameBinary,3,1)+SUBSTRING(@NameBinary,2,1)+SUBSTRING(@NameBinary,1,1)
              +SUBSTRING(@PayloadBinary,8,1)+SUBSTRING(@PayloadBinary,7,1)+SUBSTRING(@PayloadBinary,6,1)+SUBSTRING(@PayloadBinary,5,1)
              +SUBSTRING(@PayloadBinary,4,1)+SUBSTRING(@PayloadBinary,3,1)+SUBSTRING(@PayloadBinary,2,1)+SUBSTRING(@PayloadBinary,1,1)+@Name;
            -- .WRITE fügt LOB-Teile an; kein @Envelope=@Envelope+Payload mit
            -- quadratischen Komplettkopien bei vielen Entries.
            UPDATE #tbx_ZipWriter_Envelope SET Value.WRITE(@Chunk,NULL,0);
            UPDATE #tbx_ZipWriter_Envelope SET Value.WRITE(@Payload,NULL,0);
            FETCH NEXT FROM EntryCursor INTO @Ordinal,@Name,@Payload;
        END;
        CLOSE EntryCursor; DEALLOCATE EntryCursor;
        SELECT @Envelope=Value FROM #tbx_ZipWriter_Envelope;
        IF DATALENGTH(@Envelope)<>@EnvelopeSize THROW 51358,N'TBX_ZIP_WRITE_TRANSPORT_INVALID: Envelope-Länge widersprüchlich.',1;
        DECLARE @Provider TABLE(ErrorNumber int,ErrorMessage nvarchar(4000),Payload varbinary(max));
        INSERT @Provider SELECT ErrorNumber,ErrorMessage,Payload
        FROM toolbelt_archive.TVF_InternalZipWriterArchive(@Envelope,@Method,@MaxEntries,@MaxEntryNameCodeUnits,@MaxEntryBytes,@MaxTotalPayloadBytes,@MaxArchiveBytes,@MaxEnvelopeBytes,@WriterBudgetMilliseconds);
        IF (SELECT COUNT(*) FROM @Provider)<>1 THROW 51359,N'TBX_ZIP_WRITE_PROVIDER_FAILURE: Statusrow fehlt oder mehrdeutig.',1;
        DECLARE @ProviderError int,@ProviderMessage nvarchar(4000);
        SELECT @ProviderError=ErrorNumber,@ProviderMessage=ErrorMessage,@Archive=Payload FROM @Provider;
        IF @ProviderError IS NULL OR @ProviderError NOT BETWEEN 0 AND 51359 OR (@ProviderError<>0 AND @ProviderError<51350)
            THROW 51359,N'TBX_ZIP_WRITE_PROVIDER_FAILURE: Fehlerstatus ungültig.',2;
        IF @ProviderError<>0 THROW @ProviderError,@ProviderMessage,1;
        IF @Archive IS NULL THROW 51359,N'TBX_ZIP_WRITE_PROVIDER_FAILURE: Archiv fehlt.',1;
        CREATE TABLE #tbx_ZipWriter_Result(ArchivePayload varbinary(max) NOT NULL,ArchiveBytes bigint NOT NULL,EntryCount int NOT NULL,TotalPayloadBytes bigint NOT NULL,CompressionMethod int NOT NULL);
        INSERT #tbx_ZipWriter_Result VALUES(@Archive,DATALENGTH(@Archive),CONVERT(int,@Count),@Total,@Method);
        IF @ResultTable IS NOT NULL
        BEGIN
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ZipWriter_Result',@KeepData=@KeepData,@Debug=@Debug;
            SET @Sql=N'INSERT '+QUOTENAME(@ResultTable)+N'(ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod) SELECT ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod FROM #tbx_ZipWriter_Result;';
            EXEC sys.sp_executesql @Sql;
        END;
        IF @OwnTransaction=1 COMMIT TRANSACTION;
        IF @Debug>0 PRINT N'ZIP-Writer: vollständiges Archiv erfolgreich erzeugt; Inhalte werden nicht ausgegeben.';
        IF @ResultTable IS NULL SELECT ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod FROM #tbx_ZipWriter_Result;
        DROP TABLE #tbx_ZipWriter_Result,#tbx_ZipWriter_Envelope,#tbx_ZipWriter_Snapshot;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @OwnTransaction=0 AND @SavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
        -- Lokale statische Temps werden bei Scopeende auch dann entfernt,
        -- wenn ein Caller-Doom-Zustand kein weiteres DDL erlaubt.
        THROW;
    END CATCH;
END;
GO
