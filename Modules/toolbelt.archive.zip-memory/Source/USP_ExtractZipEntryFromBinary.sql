SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ExtractZipEntryFromBinary]
(
      @ZipArchive          varbinary(max) = NULL
    , @EntryName           nvarchar(1024) = NULL
    , @MaxEntryBytes       bigint         = 16777216
    , @MaxCompressionRatio decimal(9,2)   = 200.00
    , @FailIfEncrypted     bit            = 1
    , @ResultTable         sysname        = NULL
    , @KeepData            bit            = 0
    , @Debug               tinyint        = 0
    , @Hilfe               bit            = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-archive-usp-extractzipentryfrombinary"
-- description: "Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.archive.zip-memory"
-- schema_name: "toolbelt_archive"
-- object_name: "USP_ExtractZipEntryFromBinary"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge."}, {"name": "@EntryName", "sql_type": "nvarchar(1024)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(9,2)", "sql_default": "200.00", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/<1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad."}, {"name": "@FailIfEncrypted", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.4.0"
-- ---
--
-- # USP_ExtractZipEntryFromBinary
--
-- ## Zweck und Einsatzfälle
--
-- Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.
--
-- ## Voraussetzungen
--
-- ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|
-- | `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
-- | `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath. |
-- | `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze. |
-- | `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/<1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad. |
-- | `@FailIfEncrypted` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- TechnischeDefaults ermöglichenHilfe;fachlichePflicht-NULLwertebleibenungültig. Typbindung/KürzungaufSQL-ParameterbreiteliegenvorderFachprüfung. KeineautomatischeRechte-/Root-/Identityeinrichtung.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `EntryName` | `nvarchar(1024)` | NOT NULL; unveränderterdecodierterZIPname |
-- | `CompressedBytes` | `bigint` | NOT NULL; deklariertekomprimierteBytes |
-- | `UncompressedBytes` | `bigint` | NOT NULL; deklarierteentpackteBytes |
-- | `CompressionMethod` | `int` | NOT NULL; 0Stored,8Deflate;ListekannweitereMethodenbeschreiben |
-- | `Crc32` | `int` | NULL; CRC32-Bitmuster als signedint,negativeWerte sindgültig |
-- | `IsEncrypted` | `bit` | NOT NULL; Verschlüsselungsflag,keineEntschlüsselungszusage |
-- | `EntryPayload` | `varbinary(max)` | NULL; extrahierteBytes;0xechteleerePayload,NULLbeierlaubterEncryption |
--
-- Genau einevollständigeFachzeilebeiErfolg. ResultTableNULL direkteAusgabe,sonstlokalesCallerzielohnezusätzlichenFachresultset. Hilfe liefert bisherigezwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühesRETURN0 vorFachprüfung. NormalerErfolgsreturn0. Datei-ReceiptattestiertkeinegemeinsameSQL-Atomarität.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;
-- -- VollständigeZIPbytesvomClientanstelleNULLbinden.
-- DECLARE @Archive varbinary(max)=NULL;
-- EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N'contoso.txt';
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
-- Die öffentliche Fassade normalisiert KeepData/Debug/Hilfe bei NULL zu0, bei Extraktion FailIfEncrypted bei NULL zu1, und liefert frühe Hilfe. Nichtleeres Archiv und Argumente prüfen. Der interne Reader akzeptiert höchstens268435456Archivbytes,10000Entries und1024Namenseinheiten. Nichtseekender Input wird begrenzt in eigenen seekbaren Speicher kopiert, ohne Dateifallback. EOCD am Archivende mit Kommentargröße prüfen; kein ZIP64 oder Multi-Disk. CentralDirectory muss exakt bis EOCD reichen. Alle Datensätze und LocalHeader werden auf Flags, Method, rohe Namensbytes und Größen-/Payloadbereiche geprüft. UTF8 bei Flag11, sonst CP437, jeweils streng. Auch ein unbeteiligter defekter Header kann Einzelextraktion verhindern.
--
-- Liste: CentralDirectory-Reihenfolge ab Ordinal1, ordinale Duplikatanzahl, unveränderte lexikalische Pfadklasse und DOS-Zeit ohne Zeitzone; ungültige Zeit wird NULL. Keine Dekompression oder Prüfung aller Payload-CRCs. IsExtractionSupported bedeutet nur Method0/8 und nicht verschlüsselt; CRC, Quoten, Duplikate und PathSafe werden damit nicht attestiert. Ein Leerarchiv liefert null Zeilen. Ein erwarteter Fehler liefert eine einzelne Statuszeile statt einer gemischten Teilmenge.
--
-- Extraktion: genau ein ordinal gleicher Name, sonst51322/51323. Encrypted mit Fail1 ergibt51324. Fail0 liefert nur Metadaten mit IsEncrypted1 und PayloadNULL, vor Method-, Payloadgrößen-, Ratio- und CRC-Extraktionsprüfung. Die LocalHeader sind zu diesem Zeitpunkt bereits indexseitig geprüft. Sonst nur Method0/8, komprimiert höchstens134217728 und entpackt bis MaxEntryBytes≤67108864; Ratio vor und während der Dekompression. Exakter deklarierter Zielbuffer, bounded Kompressionsstream, Endlänge und CRC32 prüfen. Echte leere Payload bleibt0x durch SqlBinary. Binaryextraktion nutzt den Entrynamen nicht als Dateisystemziel und lehnt ihn nicht allein wegen PathStatus ab.
--
-- Reader-Erfolg verwendet ErrorNumberNULL, nicht die Writer-Konvention0. Erwartete Struktur-, Stream- und Decoderfehler werden Statuszeilen; unerwartete CLR-/Enginefehler bleiben Exceptions. Die Fassade prüft Status/Shape und entfernt Fehlerfelder aus der Fachausgabe. Kein eigener TX, Savepoint oder XACT_ABORT im Readerwrapper. ResultTablehelper erst nach vollständiger Prüfung und nur bei Ausgabeziel; dessen Vertrag und Caller-TX bestimmen die Rollbackwirkung. Debug wird nur an den Helper weitergegeben.
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

    SET @FailIfEncrypted = ISNULL(@FailIfEncrypted, 1);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_archive' AS sysname) AS SchemaName,
            CAST(N'USP_ExtractZipEntryFromBinary' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'EntryName', N'nvarchar(1024)', 1, 0, NULL, CAST(N'Exakter Entry-Name aus dem Central Directory.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'CompressedBytes', N'bigint', 1, 0, NULL, CAST(N'Komprimierte Entry-Größe laut Central Directory.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'UncompressedBytes', N'bigint', 1, 0, NULL, CAST(N'Unkomprimierte Entry-Größe, nach erfolgreicher Extraktion gegen die tatsächliche Ausgabe geprüft.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'CompressionMethod', N'int', 1, 0, NULL, CAST(N'ZIP Compression Method. Unterstützt werden 0 (Stored) und 8 (Deflate).' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'Crc32', N'int', 0, 1, NULL, CAST(N'CRC32 des tatsächlichen Payloads als SQL-int-Bitmuster. Bei verschlüsseltem Status stammt der Wert aus dem Central Directory.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'IsEncrypted', N'bit', 1, 0, NULL, CAST(N'1 kennzeichnet einen als verschlüsselt markierten Entry.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'EntryPayload', N'varbinary(max)', 0, 1, NULL, CAST(N'Dekomprimierter Payload. Bei @FailIfEncrypted=0 und verschlüsseltem Entry ist der Wert NULL.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51320-51329', NULL, NULL, NULL, NULL, CAST(N'Parameter-, ZIP-Struktur-, Limit-, Feature-, Integritäts- und Providerfehlerbereich.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erforderlich sind EXECUTE auf diesem Objekt und bei @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Nicht unterstützt: ZIP64, Multi-Disk, Verschlüsselungsentschlüsselung, Deflate64, unbekannte Methods und zusätzliche Central-Directory-Datensätze.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 2, NULL, NULL, NULL, NULL, NULL, CAST(N'Harte Providerlimits: 268435456 Archivbytes, 134217728 komprimierte Entry-Bytes und 10000 Entries.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Extrahiert deflated.txt aus einem synthetischen ZIP-BLOB.' AS nvarchar(max)), CAST(N'DECLARE @ZipArchive varbinary(max) = 0x...;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipArchive
    , @EntryName = N''deflated.txt'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@ZipArchive', N'varbinary(max)', 1, 0, N'NULL', CAST(N'Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@EntryName', N'nvarchar(1024)', 1, 0, N'NULL', CAST(N'Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxEntryBytes', N'bigint', 0, 1, N'16777216', CAST(N'Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxCompressionRatio', N'decimal(9,2)', 0, 1, N'200.00', CAST(N'decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/<1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@FailIfEncrypted', N'bit', 0, 1, N'1', CAST(N'Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_archive' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ExtractZipEntryFromBinary' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-archive-usp-extractzipentryfrombinary"
description: "Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "USP_ExtractZipEntryFromBinary"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge."}, {"name": "@EntryName", "sql_type": "nvarchar(1024)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung' AS nvarchar(max)) + N' der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(9,2)", "sql_default": "200.00", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/<1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad."}, {"name": "@FailIfEncrypted", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false,' + N' "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql", "Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs", "Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.4.0"
---

# USP_ExtractZipEntryFromBinary

## Zweck und Einsatzfälle

Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.

## Voraussetzungen

ZIPmemory1.4.0 mit passender SAFE-Assembly tlblt_Archive_ZipMemory und ResultTable derselben Datenbank. Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen; keine Datei- oder Netzwerkquelle.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|-' + N'--|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/<1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad. |
| `@FailIfEncrypted` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Meta' + N'datenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

TechnischeDefaults ermöglichenHilfe;fachlichePflicht-NULLwertebleibenungültig. Typbindung/KürzungaufSQL-ParameterbreiteliegenvorderFachprüfung. KeineautomatischeRechte-/Root-/Identityeinrichtung.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `EntryName` | `nvarchar(1024)` | NOT NULL; unveränderterdecodierterZIPname |
| `CompressedBytes` | `bigint` | NOT NULL; deklariertekomprimierteBytes |
| `UncompressedBytes` | `bigint` | NOT NULL; deklarierteentpackteBytes |
| `CompressionMethod` | `int` | NOT NULL; 0Stored,8Deflate;ListekannweitereMethodenbeschreiben |
| `Crc32` | `int` | NULL; CRC32-Bitmuster als signedint,negativeWerte sindgültig |
| ' + N'`IsEncrypted` | `bit` | NOT NULL; Verschlüsselungsflag,keineEntschlüsselungszusage |
| `EntryPayload` | `varbinary(max)` | NULL; extrahierteBytes;0xechteleerePayload,NULLbeierlaubterEncryption |

Genau einevollständigeFachzeilebeiErfolg. ResultTableNULL direkteAusgabe,sonstlokalesCallerzielohnezusätzlichenFachresultset. Hilfe liefert bisherigezwölfspaltigeStandardhilfe plusgenaueineSkillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühesRETURN0 vorFachprüfung. NormalerErfolgsreturn0. Datei-ReceiptattestiertkeinegemeinsameSQL-Atomarität.

## Aufrufbeispiele

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;
-- VollständigeZIPbytesvomClientanstelleNULLbinden.
DECLARE @Archive varbinary(max)=NULL;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Archive,@EntryName=N''contoso.txt'';
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Memory-USP und gezielte SELECT-Rechte auf benötigte interne CLR-TVFs gemäß Modulvertrag. Writer braucht die ResultTable-Schnittstelle für beide Ausgaben; Reader Helper-EXECUTE nur bei ResultTable. Leserechte auf Caller-Temps und Metadatensicht für Writer, tempdb.sys.columns und spezifische sys.parameters-Sicht. Interne Kennzeichnung ist kein Verbot notwendiger Providerberechtigungen, aber kein Freibrief für allgemeine Direktnutzung. Keine Filesystemrechte für den Memorypfad.

## Ressourcenbedarf

Writergrenzen:Entries1..1024, Namen1..2048Codeunits, Entry1..33554432, Summe1..134217728, ZIP1..150994944, Envelope1..142606336, Budget1..60000ms. Readergrenzen:268435456Archivbytes,10000Entries,1024Namenseinheiten, komprimiert134217728, extrahiert maximal67108864. Reader hat keinen eigenen Timer. Snapshot-, Envelope-, Seek- und Transportkopien, Deflatepuffer und CRC kosten zusätzlich Speicher/CPU. Kooperatives Writerbudget ist keine harte Wallclock-, Heap- oder SQL-Transportquote.

## Nebenwirkungen

Die öffentliche Fassade normalisiert KeepData/Debug/H' + N'ilfe bei NULL zu0, bei Extraktion FailIfEncrypted bei NULL zu1, und liefert frühe Hilfe. Nichtleeres Archiv und Argumente prüfen. Der interne Reader akzeptiert höchstens268435456Archivbytes,10000Entries und1024Namenseinheiten. Nichtseekender Input wird begrenzt in eigenen seekbaren Speicher kopiert, ohne Dateifallback. EOCD am Archivende mit Kommentargröße prüfen; kein ZIP64 oder Multi-Disk. CentralDirectory muss exakt bis EOCD reichen. Alle Datensätze und LocalHeader werden auf Flags, Method, rohe Namensbytes und Größen-/Payloadbereiche geprüft. UTF8 bei Flag11, sonst CP437, jeweils streng. Auch ein unbeteiligter defekter Header kann Einzelextraktion verhindern.

Liste: CentralDirectory-Reihenfolge ab Ordinal1, ordinale Duplikatanzahl, unveränderte lexikalische Pfadklasse und DOS-Zeit ohne Zeitzone; ungültige Zeit wird NULL. Keine Dekompression oder Prüfung aller Payload-CRCs. IsExtractionSupported bedeutet nur Method0/8 und nicht verschlüsselt; CRC, Quoten, Duplikate und PathSafe werden damit nicht attestiert. Ein Leerarchiv liefert null Zeilen. Ein erwarteter Fehler liefert eine einzelne Statuszeile statt einer gemischten Teilmenge.

Extraktion: genau ein ordinal gleicher Name, sonst51322/51323. Encrypted mit Fail1 ergibt51324. Fail0 liefert nur Metadaten mit IsEncrypted1 und PayloadNULL, vor Method-, Payloadgrößen-, Ratio- und CRC-Extraktionsprüfung. Die LocalHeader sind zu diesem Zeitpunkt bereits indexseitig geprüft. Sonst nur Method0/8, komprimiert höchstens134217728 und entpackt bis MaxEntryBytes≤67108864; Ratio vor und während der Dekompression. Exakter deklarierter Zielbuffer, bounded Kompressionsstream, Endlänge und CRC32 prüfen. Echte leere Payload bleibt0x durch SqlBinary. Binaryextraktion nutzt den Entrynamen nicht als Dateisystemziel und lehnt ihn nicht allein wegen PathStatus ab.

Reader-Erfolg verwendet ErrorNumberNULL, nicht die Writer-Konvention0. Erwartete Struktur-, Stream- und Decoderfehler werden Statuszeilen; unerwartete CLR-/Enginefehler ble' + N'iben Exceptions. Die Fassade prüft Status/Shape und entfernt Fehlerfelder aus der Fachausgabe. Kein eigener TX, Savepoint oder XACT_ABORT im Readerwrapper. ResultTablehelper erst nach vollständiger Prüfung und nur bei Ausgabeziel; dessen Vertrag und Caller-TX bestimmen die Rollbackwirkung. Debug wird nur an den Helper weitergegeben.

## Fehlerbehandlung

Reader:51320 Argumente,51321 Struktur/Encoding/Stream,51322 Name fehlt,51323 gesuchter Name doppelt,51324 Encryption verboten,51325 Ressourcen,51326 Ratio,51327 Format/Method,51328 Integrität,51329 Wrapper/Dependency. Writer:51350 Argumente,51351 SQL-Inputshape,51352 Name,51353 Namensduplikat,51354 Ressourcen,51355 Format/Overflow,51356 Timeout,51357 Dependency,51358 Transport,51359 Providerstatus. Status-TVFs wandeln nur explizit gefangene Fehler um; unerwartete CLR-/Enginefehler bleiben Originalexceptions. Reader-ErfolgNULL, Writer-Erfolg0. Öffentliche Fassaden werfen statt einer Teilpayload.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/ZIP-/Dateipublikationsabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. CRC32, Status und PathSafe sind keine Signatur, Malwareprüfung oder Herkunftsauthentifizierung. Kein allgemeiner ZIP64-, Encryption-, Streaming- oder Mehrdatei-Unpacker. Keine Installations- oder Rechteattestation. ZIPnamen, Payloads, Dateipfade und Runtimebefunde privat halten.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @ZipArchive IS NULL OR DATALENGTH(@ZipArchive) = 0
        THROW 51320, N'@ZipArchive muss einen nicht leeren ZIP-Container enthalten.', 1;
    IF @EntryName IS NULL OR LEN(@EntryName) = 0
        THROW 51320, N'@EntryName muss gesetzt sein.', 1;
    IF @MaxEntryBytes IS NULL
       OR @MaxEntryBytes <= 0
       OR @MaxEntryBytes > 67108864
        THROW 51320, N'@MaxEntryBytes muss zwischen 1 und 67108864 liegen.', 1;
    IF @MaxCompressionRatio IS NULL OR @MaxCompressionRatio < 1
        THROW 51320, N'@MaxCompressionRatio muss größer oder gleich 1 sein.', 1;

    IF OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr', N'FT') IS NULL
        THROW 51329, N'Der interne CLR-ZIP-Provider ist nicht installiert.', 1;

    DECLARE @ProviderResult TABLE
    (
          ErrorNumber       int            NULL
        , ErrorMessage      nvarchar(4000) NULL
        , EntryName         nvarchar(1024) NULL
        , CompressedBytes   bigint         NULL
        , UncompressedBytes bigint         NULL
        , CompressionMethod int            NULL
        , Crc32             int            NULL
        , IsEncrypted       bit            NULL
        , EntryPayload      varbinary(max) NULL
    );

    INSERT INTO @ProviderResult
    (
          ErrorNumber
        , ErrorMessage
        , EntryName
        , CompressedBytes
        , UncompressedBytes
        , CompressionMethod
        , Crc32
        , IsEncrypted
        , EntryPayload
    )
    SELECT
          ErrorNumber
        , ErrorMessage
        , EntryName
        , CompressedBytes
        , UncompressedBytes
        , CompressionMethod
        , Crc32
        , IsEncrypted
        , EntryPayload
    FROM toolbelt_archive.TVF_InternalExtractZipEntryClr
    (
          @ZipArchive
        , @EntryName
        , @MaxEntryBytes
        , @MaxCompressionRatio
        , @FailIfEncrypted
    );

    IF (SELECT COUNT_BIG(*) FROM @ProviderResult) <> 1
        THROW 51329, N'Der interne CLR-ZIP-Provider lieferte keinen eindeutigen Status.', 1;

    DECLARE
          @ProviderErrorNumber int
        , @ProviderErrorMessage nvarchar(2048);

    SELECT
          @ProviderErrorNumber = ErrorNumber
        , @ProviderErrorMessage =
              CONVERT(nvarchar(2048), LEFT(ErrorMessage, 2048))
    FROM @ProviderResult;

    IF @ProviderErrorNumber IS NOT NULL
    BEGIN
        IF @ProviderErrorNumber NOT BETWEEN 51320 AND 51329
            THROW 51329, N'Der interne CLR-ZIP-Provider lieferte einen ungültigen Fehlercode.', 1;

        SET @ProviderErrorMessage =
            COALESCE(NULLIF(@ProviderErrorMessage, N''), N'Der CLR-ZIP-Provider hat den Vorgang abgebrochen.');

        THROW @ProviderErrorNumber, @ProviderErrorMessage, 1;
    END;

    CREATE TABLE #tbx_ZipMemory_ResultSource
    (
          EntryName         nvarchar(1024) NOT NULL
        , CompressedBytes   bigint         NOT NULL
        , UncompressedBytes bigint         NOT NULL
        , CompressionMethod int            NOT NULL
        , Crc32             int            NULL
        , IsEncrypted       bit            NOT NULL
        , EntryPayload      varbinary(max) NULL
    );

    INSERT INTO #tbx_ZipMemory_ResultSource
    (
          EntryName
        , CompressedBytes
        , UncompressedBytes
        , CompressionMethod
        , Crc32
        , IsEncrypted
        , EntryPayload
    )
    SELECT
          EntryName
        , CompressedBytes
        , UncompressedBytes
        , CompressionMethod
        , Crc32
        , IsEncrypted
        , EntryPayload
    FROM @ProviderResult;

    IF @ResultTable IS NULL
    BEGIN
        SELECT
              EntryName
            , CompressedBytes
            , UncompressedBytes
            , CompressionMethod
            , Crc32
            , IsEncrypted
            , EntryPayload
        FROM #tbx_ZipMemory_ResultSource;

        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51329, N'Die ResultTable-Dependency toolbelt_core.USP_PrepareResultTable ist nicht installiert.', 1;

    CREATE TABLE #tbx_ZipMemory_ResultShape
    (
          EntryName         nvarchar(1024) NOT NULL
        , CompressedBytes   bigint         NOT NULL
        , UncompressedBytes bigint         NOT NULL
        , CompressionMethod int            NOT NULL
        , Crc32             int            NULL
        , IsEncrypted       bit            NOT NULL
        , EntryPayload      varbinary(max) NULL
    );

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable          = N'#tbx_ZipMemory_ResultShape'
        , @KeepData           = @KeepData
        , @Debug              = @Debug;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable) + N'
        (
              EntryName
            , CompressedBytes
            , UncompressedBytes
            , CompressionMethod
            , Crc32
            , IsEncrypted
            , EntryPayload
        )
        SELECT
              EntryName
            , CompressedBytes
            , UncompressedBytes
            , CompressionMethod
            , Crc32
            , IsEncrypted
            , EntryPayload
        FROM #tbx_ZipMemory_ResultSource;';

    EXEC sys.sp_executesql @InsertSql;

    RETURN 0;
END;
GO
