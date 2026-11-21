-- ============================================================================
-- Objekt:          toolbelt_file.USP_LoadTextFile
-- Typ:             Stored Procedure
-- Zweck:           Liest eine Datei als nvarchar(max) mit Encoding-Erkennung.
-- Vertrag:         Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md
-- Parameter:       @FilePath nvarchar(4000) = NULL (nur Help-Aufruf)
--                  @FallbackEncoding nvarchar(128) = 'Windows-1252'
--                  @MaxBytes bigint = NULL
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
--                  @ResultTable sysname = NULL
--                  @KeepData bit = 0
-- Resultset:       Genau eine Zeile mit Content, BytesRead, EncodingDetected,
--                  BomPresent, IsValid, ValidationCode, ValidationMessage.
-- Dependencies:    toolbelt_file.FileContentRootAllowlist
-- Rechte:          EXECUTE auf der Procedure;
--                  ADMINISTER BULK OPERATIONS oder ad hoc distributed queries;
--                  Lesezugriff auf den Dateipfad.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux.
-- Fehlerverhalten: Fachliche Fehler werden als Resultset-Zeile mit
--                  IsValid = 0 zurückgegeben. Unbehandelte Engine-Fehler
--                  propagieren als THROW.
-- Performance:     Ein SINGLE_BLOB-Snapshot für Größe, BOM und Text.
-- Einschränkungen:  Dateigröße ist durch nvarchar(max) auf ca. 2 GB begrenzt.
--                  Encoding-Erkennung erfolgt über BOM; Inhalt ohne BOM wird
--                  mit @FallbackEncoding als 8-Bit-Codepage gelesen.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadTextFile]
(
      @FilePath          nvarchar(4000) = NULL
    , @FallbackEncoding  nvarchar(128) = N'Windows-1252'
    , @MaxBytes          bigint        = NULL
    , @ResultTable       sysname       = NULL
    , @KeepData          bit           = 0
    , @Debug             tinyint       = 0
    , @Hilfe             bit           = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-file-usp-loadtextfile"
-- description: "Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.file.content"
-- schema_name: "toolbelt_file"
-- object_name: "USP_LoadTextFile"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@FilePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox."}, {"name": "@FallbackEncoding", "sql_type": "nvarchar(128)", "sql_default": "N'Windows-1252'", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector."}, {"name": "@MaxBytes", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql", "Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql", "Modules/toolbelt.file.content/Source/FileContentRootAllowlist.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_LoadTextFile
--
-- ## Zweck und Einsatzfälle
--
-- Liest eine erlaubte Datei über genau einen serverseitigen OPENROWSET(BULK,SINGLE_BLOB)-Zugriff und decodiert denselben vollständigen Byte-Snapshot nach BOM/CP1252. Kein Dateischreiben oder Clientdatei-Upload.
--
-- ## Voraussetzungen
--
-- SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klammern sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@FilePath` | `nvarchar(4000)` | `NULL` | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
-- | `@FallbackEncoding` | `nvarchar(128)` | `N'Windows-1252'` | Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector. |
-- | `@MaxBytes` | `bigint` | `NULL` | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- Content nvarchar(max) NULL, BytesRead bigint NOT NULL, EncodingDetected nvarchar(128) NULL, BomPresent bit NOT NULL, IsValid bit NOT NULL, ValidationCode int NULL, ValidationMessage nvarchar(4000) NULL. Genau eine fachliche Zeile bei normalem Abschluss. Erfolg IsValid=1 und NULL-Fehlerfelder; fachliche Ablehnung IsValid=0, Content=NULL und Code/Text. BytesRead zählt gelesene Rohbytes einschließlich BOM, bei Pfad-/Rootprüfung vor dem Lesen 0. RETURN 0 bedeutet auch bei IsValid=0 nur normalen Prozedurabschluss; Status unbedingt auswerten. Kein fachlicher OUTPUT-Parameter. ResultTable=NULL SELECT, sonst Ziel-INSERT mit demselben Schema. Hilfe liefert zuerst Standardhilfe und zusätzlich genau eine Zeile SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),vor Fachausführung. EncodingDetected: UTF-8/UTF-16-LE bei unterstützter BOM, Windows-1252 ohne BOM; bei abgewiesener UTF-16-BE/UTF-32-BOM entsprechender Name mit BomPresent=1 und Code51325. Bei früher Ablehnung Encoding=NULL/BomPresent=0. Content-UTF16-Länge ist nicht gleich Rohbytezahl.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_file.USP_LoadTextFile @FilePath=N'C:\Contoso\Input\example.txt',@MaxBytes=1048576;
-- -- Synthetischer serverseitiger Pfad; aktiver Root und vorhandene Rechte nötig.
-- -- IsValid/ValidationCode prüfen; MaxBytes ist kein Vorallokationslimit.
-- EXEC toolbelt_file.USP_LoadTextFile @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf der öffentlichen USP und gültige Abhängigkeitsrechte auf die Allowlist. Zusätzlich für die konkrete SQL-Server-Version/Plattform ausreichende Bulkberechtigung (ADMINISTER BULK OPERATIONS bzw. ADMINISTER DATABASE BULK OPERATIONS, soweit unterstützt) und Lesezugriff des tatsächlich wirksamen Dateisystem-Sicherheitskontexts. Bei SQL-Authentifizierung ist regelmäßig der SQL-Server-Prozesskontext relevant, bei Windows-Anmeldung der passende delegierte Kontext. Linux-/Patchbesonderheiten separat beachten; kein versionsunabhängiger Minimalrechte-PASS behauptet. Eine Ad-hoc-Konfigurationsoption ersetzt keine Rechte. Die Procedure erteilt nichts und aktiviert keine Serveroption. [Microsoft-Bulkvertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/openrowset-bulk-transact-sql?view=sql-server-ver17), [Dateizugriffskontext](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/prepare-data-for-bulk-export-or-import-sql-server). Routing zusätzlich vorhandene Helper-/Temp-Rechte; keine neue Privilegienvergabe im Aufruf.
--
-- ## Ressourcenbedarf
--
-- Pfadargument nvarchar(4000), aber aktuelles BULK-Literal nutzt QUOTENAME mit sysname-Grenze128; längere Pfade sind nicht als funktionierend belegt und können durch NULL-SQL in technischen Fehler münden. Ein vollständiger SINGLE_BLOB-Snapshot vor eigener MaxBytes-Prüfung. MaxBytes=NULL/0 deaktiviert Prüfung; positiv begrenzt erst das bereits gelesene Ergebnis; negativ ist nicht vorab Argumentfehler, sondern führt für gelesene nichtnegative Bytegröße zu Status51323. Kein I/O-,Heap-,CPU-/Wallclock-Vorabcap und kein Streaming. Snapshot, BOM-Payloadkopie, decodierter nvarchar(max)-Text und bei UTF8 zusätzliche Roundtripbytes/Tabellenvariable können gleichzeitig bestehen. SQL-LOB-/Providergrenzen bleiben wirksam; kein erfolgreicher gekürzter Inhalt als Größenersatz.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON, Hilfe NULL=>0 vor frühem Hilfezweig. Im Fachpfad private Ergebnistemp, KeepData/Debug NULL=>0. Nur bei ResultTable SET XACT_ABORT OFF und kontrollierter eigener Transaktionsscope oder zufälliger Caller-Savepoint; uncommittable bestehender Caller wird vorher abgewiesen. Wichtig: ResultTable-Helper bereitet/ersetzt das Ziel VOR Pfad-/Encoding-/Rootprüfung und Datei-I/O. Eine normale IsValid=0-Statuszeile wird regulär eingefügt/committed und kann vorherige Zieldaten bei KeepData=0 ersetzen. Das ist kein nebenwirkungsfreier Argumentfehler. Technischer Fehler rollt eigene Transaktion oder committable Caller-Savepoint zurück; fremde Transaktion nie vollständig committen/rollbacken. Rollbackfehler nicht separat geschützt. Ohne ResultTable kein eigener BEGIN/COMMIT. Kein Dateischreiben, jedoch tatsächliches Datei-/gegebenenfalls UNC-Netzwerklesen im wirksamen Serverkontext. Debug nur an den ResultTable-Helper weitergereicht, keine eigene Inhaltsdiagnose.
--
-- ## Fehlerbehandlung
--
-- Fachliche Statuscodes, kein THROW:51320 Pfad leer/NULL/nicht absolut;51322 erkannte Parent-Traversalsegmente;51321 kein aktiver passender Root;51323 Bytezahl nach Lesen über MaxBytes. 51324 ungültiger Fallback vor Pfadtraversal/Root/I/O, auch bei Datei mit BOM;51325 erkannte UTF-16-BE-/UTF32-BOM unsupported. Technischer THROW51326 für Provider-/Decoderfehler mit übernommenem gekürztem Engine-ERROR_MESSAGE (bis1700 Zeichen, Prozentzeichen escaped). Fehlermeldung kann reale Pfade/Umgebungsdetails enthalten, privat behandeln. 51908 fehlender ResultTable-Helper und51028 ungeeigneter Callerzustand bleiben technische Fehler; sonstige Engine-/Binding-/Helperfehler ebenfalls sichtbar. Für Statusfehler nicht allein auf RETURN0 vertrauen. UTF-32-BOMs vor UTF16-Präfixen prüfen; unterstützte UTF8-/UTF16LE-BOM entfernen. UTF16LE verlangt gerade Payloadbytelänge, keine vollständige Surrogatvalidierung. UTF8 wird über explizite UTF8-Collation und exakten Byte-Roundtrip validiert; Fehlsequenz THROW51326. Ohne BOM immer explizite CP1252-Collation, keine heuristische BOM-lose UTF8-Erkennung. Fallback nach LTRIM/RTRIM/SQL-Collation ausschließlich Windows-1252 oder Alias SQL_Latin1_General_CP1_CI_AS; NULL/leer=>Windows-1252, beide akzeptierten Werte werden zu Windows-1252 normalisiert.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Datei-I/O-/Minimalrechte-/Skill-/Installerabnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Dateiinhalt, Pfade und Providerfehlermeldungen können vertrauliche Umgebungsdaten enthalten; nicht veröffentlichen. Keine Installation-/Rechteattestation, keine unbegrenzte Kapazität oder Garantie eines stabilen Dateisystems.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;

    SET @Hilfe            = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_file' AS sysname) AS SchemaName,
            CAST(N'USP_LoadTextFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'Content', N'nvarchar(max)', 0, 1, NULL, CAST(N'Der Text-Inhalt. Bei Validierungsfehlern NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'BytesRead', N'bigint', 0, 0, NULL, CAST(N'Anzahl gelesener Bytes. Bei Validierungsfehlern vor dem Lesen 0.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'EncodingDetected', N'nvarchar(128)', 0, 1, NULL, CAST(N'Erkanntes Encoding: UTF-8, UTF-16-LE oder der Wert von @FallbackEncoding. UTF-16-BE und UTF-32 werden nicht unterstützt.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'BomPresent', N'bit', 0, 0, NULL, CAST(N'1, wenn ein Byte Order Mark vorhanden war; 0 sonst.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'IsValid', N'bit', 0, 0, NULL, CAST(N'1, wenn der Inhalt erfolgreich gelesen wurde; 0 bei fachlichem Fehler.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ValidationCode', N'int', 0, 1, NULL, CAST(N'Fachlicher Fehlercode oder NULL bei Erfolg.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'ValidationMessage', N'nvarchar(4000)', 0, 1, NULL, CAST(N'Fachliche Fehlermeldung oder NULL bei Erfolg.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51320', NULL, NULL, NULL, NULL, CAST(N'Ungültiger oder leerer Dateipfad.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'51321', NULL, NULL, NULL, NULL, CAST(N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.' AS nvarchar(max)), NULL),
        (N'ERROR', 3, N'51322', NULL, NULL, NULL, NULL, CAST(N'Pfad enthält verbotene relative Segmente oder Traversal.' AS nvarchar(max)), NULL),
        (N'ERROR', 4, N'51323', NULL, NULL, NULL, NULL, CAST(N'Datei überschreitet @MaxBytes.' AS nvarchar(max)), NULL),
        (N'ERROR', 5, N'51324', NULL, NULL, NULL, NULL, CAST(N'Fallback-Encoding wird nicht unterstützt.' AS nvarchar(max)), NULL),
        (N'ERROR', 6, N'51325', NULL, NULL, NULL, NULL, CAST(N'Encoding wird nicht unterstützt (UTF-16-BE, UTF-32).' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erforderlich ist EXECUTE auf toolbelt_file.USP_LoadTextFile, Lesezugriff auf den Dateipfad sowie ADMINISTER BULK OPERATIONS oder ad hoc distributed queries für OPENROWSET(BULK...). Für @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ein SINGLE_BLOB-Snapshot bindet Größe, BOM und Text. UTF-8 und Windows-1252 werden mit expliziten Collations, UTF-16-LE aus geraden Bytefolgen dekodiert. UTF-16-BE und UTF-32 bleiben ausgeschlossen. Die erste BLOB-Allokation ist kein Vorallokationsbudget. ResultTable-Änderung und Datei-I/O liegen in derselben Transaktion.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest eine Textdatei aus einem erlaubten Root.' AS nvarchar(max)), CAST(N'EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = N''/var/opt/mssql/data/allowed/sample.txt'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@FilePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@FallbackEncoding', N'nvarchar(128)', 0, 1, N'N''Windows-1252''', CAST(N'Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxBytes', N'bigint', 0, 1, N'NULL', CAST(N'Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_file' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_LoadTextFile' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-file-usp-loadtextfile"
description: "Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen."
skill_format_version: "1.0"
module_id: "toolbelt.file.content"
schema_name: "toolbelt_file"
object_name: "USP_LoadTextFile"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@FilePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox."}, {"name": "@FallbackEncoding", "sql_type": "nvarchar(128)", "sql_default": "N''Windows-1252''", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector."}, {"name": "@MaxByte' AS nvarchar(max)) + N's", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-P' + N'fad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql", "Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql", "Modules/toolbelt.file.content/Source/FileContentRootAllowlist.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_LoadTextFile

## Zweck und Einsatzfälle

Liest eine erlaubte Datei über genau einen serverseitigen OPENROWSET(BULK,SINGLE_BLOB)-Zugriff und decodiert denselben vollständigen Byte-Snapshot nach BOM/CP1252. Kein Dateischreiben oder Clientdatei-Upload.

## Voraussetzungen

SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. Datenbanktabelle mit administrativ gepflegtem aktivem Root. Provider-/Plattform-/OS-Leserechte unabhängig von Rootfreigabe erfüllen. Für ResultTable sameDB core.result-table>=1.0.0. Aktueller gemeinsamer Offlinebuilder expandiert FileContentRootPredicate.sql in normale SQL-DDL; rohe Source-Prozedurdatei enthält noch :r-Quellinclude und ist kein direkt unverändert auszuführender SQLCMD-freier Installer. Eingabepfad LTRIM/RTRIM normaler Spaces und NULLIF leer; dann zwei REPLACE-Schritte für doppelte/einfache Backslashes nach Slash nur für den Allowlistvergleich. Absolutheit nach Laufwerkbuchstabe:/ oder führendem /; geprüftes ../-Traversal wird abgewiesen, keine vollständige OS-Kanonisierung aller Punkt-/Device-/Aliasformen. Aktive Roots werden ebenfalls slashnormalisiert, nicht generell getrimmt. Vergleich literal BIN2 an exakter Rootlänge oder Verzeichnisgrenze mit angehängtem /; Prozent/Unterstrich/Klamme' + N'rn sind dort keine Wildcards. Ein exakter Rootpfad selbst kann zugelassen sein, nicht nur dessen Kinder. Keine Symlink-/Junction-/Hardlink-/Handleprüfung; tatsächlicher BULK-Aufruf liest den getrimmten Originalpfad. Keine handlegebundene Sandbox oder TOCTOU-/Dateisystemidentitätsgarantie.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@FallbackEncoding` | `nvarchar(128)` | `N''Windows-1252''` | Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector. |
| `@MaxBytes` | `bigint` | `NULL` | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern füh' + N'ren bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Pfad-/Transaktions-/Temp-/Root-/Dateiarbeit. 0/NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

## Ergebnisse

Content nvarchar(max) NULL, BytesRead bigint NOT NULL, EncodingDetected nvarchar(128) NULL, BomPresent bit NOT NULL, IsValid bit NOT NULL, ValidationCode int NULL, ValidationMessage nvarchar(4000) NULL. Genau eine fachliche Zeile bei normalem Abschluss. Erfolg IsValid=1 und NULL-Fehlerfelder; fachliche Ablehnung IsValid=0, Content=NULL und Code/Text. BytesRead zählt gelesene Rohbytes einschließlich BOM, bei Pfad-/Rootprüfung vor dem Lesen 0. RETURN 0 bedeutet auch bei IsValid=0 nur normalen Prozedurabschluss; Status unbedingt auswerten. Kein fachlicher OUTPUT-Parameter. Result' + N'Table=NULL SELECT, sonst Ziel-INSERT mit demselben Schema. Hilfe liefert zuerst Standardhilfe und zusätzlich genau eine Zeile SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),vor Fachausführung. EncodingDetected: UTF-8/UTF-16-LE bei unterstützter BOM, Windows-1252 ohne BOM; bei abgewiesener UTF-16-BE/UTF-32-BOM entsprechender Name mit BomPresent=1 und Code51325. Bei früher Ablehnung Encoding=NULL/BomPresent=0. Content-UTF16-Länge ist nicht gleich Rohbytezahl.

## Aufrufbeispiele

```sql
EXEC toolbelt_file.USP_LoadTextFile @FilePath=N''C:\Contoso\Input\example.txt'',@MaxBytes=1048576;
-- Synthetischer serverseitiger Pfad; aktiver Root und vorhandene Rechte nötig.
-- IsValid/ValidationCode prüfen; MaxBytes ist kein Vorallokationslimit.
EXEC toolbelt_file.USP_LoadTextFile @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf der öffentlichen USP und gültige Abhängigkeitsrechte auf die Allowlist. Zusätzlich für die konkrete SQL-Server-Version/Plattform ausreichende Bulkberechtigung (ADMINISTER BULK OPERATIONS bzw. ADMINISTER DATABASE BULK OPERATIONS, soweit unterstützt) und Lesezugriff des tatsächlich wirksamen Dateisystem-Sicherheitskontexts. Bei SQL-Authentifizierung ist regelmäßig der SQL-Server-Prozesskontext relevant, bei Windows-Anmeldung der passende delegierte Kontext. Linux-/Patchbesonderheiten separat beachten; kein versionsunabhängiger Minimalrechte-PASS behauptet. Eine Ad-hoc-Konfigurationsoption ersetzt keine Rechte. Die Procedure erteilt nichts und aktiviert keine Serveroption. [Microsoft-Bulkvertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/openrowset-bulk-transact-sql?view=sql-server-ver17), [Dateizugriffskontext](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/prepare-data-for-bulk-export-or-import-sql-server). Routing zusätzlich vorhandene Helper-/Temp-Rechte; keine neue Privilegienvergabe im Aufruf.

## Ressourcenbedarf

Pfadargument nvarchar(4000), aber aktuelles BULK-Lit' + N'eral nutzt QUOTENAME mit sysname-Grenze128; längere Pfade sind nicht als funktionierend belegt und können durch NULL-SQL in technischen Fehler münden. Ein vollständiger SINGLE_BLOB-Snapshot vor eigener MaxBytes-Prüfung. MaxBytes=NULL/0 deaktiviert Prüfung; positiv begrenzt erst das bereits gelesene Ergebnis; negativ ist nicht vorab Argumentfehler, sondern führt für gelesene nichtnegative Bytegröße zu Status51323. Kein I/O-,Heap-,CPU-/Wallclock-Vorabcap und kein Streaming. Snapshot, BOM-Payloadkopie, decodierter nvarchar(max)-Text und bei UTF8 zusätzliche Roundtripbytes/Tabellenvariable können gleichzeitig bestehen. SQL-LOB-/Providergrenzen bleiben wirksam; kein erfolgreicher gekürzter Inhalt als Größenersatz.

## Nebenwirkungen

SET NOCOUNT ON, Hilfe NULL=>0 vor frühem Hilfezweig. Im Fachpfad private Ergebnistemp, KeepData/Debug NULL=>0. Nur bei ResultTable SET XACT_ABORT OFF und kontrollierter eigener Transaktionsscope oder zufälliger Caller-Savepoint; uncommittable bestehender Caller wird vorher abgewiesen. Wichtig: ResultTable-Helper bereitet/ersetzt das Ziel VOR Pfad-/Encoding-/Rootprüfung und Datei-I/O. Eine normale IsValid=0-Statuszeile wird regulär eingefügt/committed und kann vorherige Zieldaten bei KeepData=0 ersetzen. Das ist kein nebenwirkungsfreier Argumentfehler. Technischer Fehler rollt eigene Transaktion oder committable Caller-Savepoint zurück; fremde Transaktion nie vollständig committen/rollbacken. Rollbackfehler nicht separat geschützt. Ohne ResultTable kein eigener BEGIN/COMMIT. Kein Dateischreiben, jedoch tatsächliches Datei-/gegebenenfalls UNC-Netzwerklesen im wirksamen Serverkontext. Debug nur an den ResultTable-Helper weitergereicht, keine eigene Inhaltsdiagnose.

## Fehlerbehandlung

Fachliche Statuscodes, kein THROW:51320 Pfad leer/NULL/nicht absolut;51322 erkannte Parent-Traversalsegmente;51321 kein aktiver passender Root;51323 Bytezahl nach Lesen über MaxBytes. 51324 ungültiger Fallback vor Pfadtraversal/Root/I/O, auch bei Datei mit BOM;5' + N'1325 erkannte UTF-16-BE-/UTF32-BOM unsupported. Technischer THROW51326 für Provider-/Decoderfehler mit übernommenem gekürztem Engine-ERROR_MESSAGE (bis1700 Zeichen, Prozentzeichen escaped). Fehlermeldung kann reale Pfade/Umgebungsdetails enthalten, privat behandeln. 51908 fehlender ResultTable-Helper und51028 ungeeigneter Callerzustand bleiben technische Fehler; sonstige Engine-/Binding-/Helperfehler ebenfalls sichtbar. Für Statusfehler nicht allein auf RETURN0 vertrauen. UTF-32-BOMs vor UTF16-Präfixen prüfen; unterstützte UTF8-/UTF16LE-BOM entfernen. UTF16LE verlangt gerade Payloadbytelänge, keine vollständige Surrogatvalidierung. UTF8 wird über explizite UTF8-Collation und exakten Byte-Roundtrip validiert; Fehlsequenz THROW51326. Ohne BOM immer explizite CP1252-Collation, keine heuristische BOM-lose UTF8-Erkennung. Fallback nach LTRIM/RTRIM/SQL-Collation ausschließlich Windows-1252 oder Alias SQL_Latin1_General_CP1_CI_AS; NULL/leer=>Windows-1252, beide akzeptierten Werte werden zu Windows-1252 normalisiert.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Datei-I/O-/Minimalrechte-/Skill-/Installerabnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Dateiinhalt, Pfade und Providerfehlermeldungen können vertrauliche Umgebungsdaten enthalten; nicht veröffentlichen. Keine Installation-/Rechteattestation, keine unbegrenzte Kapazität oder Garantie eines stabilen Dateisystems.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    DECLARE @InitialTransactionCount int = @@TRANCOUNT
          , @StartedTransaction bit = 0
          , @SavepointCreated bit = 0
          , @SavepointName varchar(32) = CONVERT(varchar(32), 'tbx_file_' + LEFT(REPLACE(CONVERT(varchar(36), NEWID()), '-', ''), 23))
          , @InsertResultSql nvarchar(max);
    IF @ResultTable IS NOT NULL SET XACT_ABORT OFF;
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    IF @ResultTable IS NOT NULL AND @InitialTransactionCount > 0 AND XACT_STATE() <> 1
        THROW 51028, N'Der Callertransaktionszustand erlaubt keinen kontrollierten ResultTable-Savepoint.', 1;
    CREATE TABLE #tbx_LoadTextFileResult
    (
          Content nvarchar(max) NULL
        , BytesRead bigint NOT NULL
        , EncodingDetected nvarchar(128) NULL
        , BomPresent bit NOT NULL
        , IsValid bit NOT NULL
        , ValidationCode int NULL
        , ValidationMessage nvarchar(4000) NULL
    );
    BEGIN TRY
    IF @ResultTable IS NOT NULL
    BEGIN
        IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
            THROW 51908, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;
        IF @InitialTransactionCount = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @StartedTransaction = 1;
        END
        ELSE
        BEGIN
            IF XACT_STATE() <> 1 THROW 51028, N'Der Callertransaktionszustand erlaubt keinen kontrollierten ResultTable-Savepoint.', 1;
            SAVE TRANSACTION @SavepointName;
            SET @SavepointCreated = 1;
        END;
        EXEC toolbelt_core.USP_PrepareResultTable
              @ResultTableToAlter = @ResultTable
            , @LikeTable = N'#tbx_LoadTextFileResult'
            , @KeepData = @KeepData
            , @Debug = @Debug;
    END;

    SET @FilePath         = NULLIF(LTRIM(RTRIM(@FilePath)), N'');
    SET @FallbackEncoding = ISNULL(NULLIF(LTRIM(RTRIM(@FallbackEncoding)), N''), N'Windows-1252');
    SET @MaxBytes         = NULLIF(@MaxBytes, 0);
    SET @Debug            = ISNULL(@Debug, 0);
    IF @FilePath IS NULL
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51320, N'Ungültiger oder leerer Dateipfad.');
        GOTO EmitResult;
    END;

    IF @FallbackEncoding NOT IN (N'Windows-1252', N'SQL_Latin1_General_CP1_CI_AS')
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51324, N'Fallback-Encoding wird nicht unterstützt.');
        GOTO EmitResult;
    END;

    -- UTF-8 als Fallback-Encoding ist nicht sinnvoll, weil BOM-lose UTF-8-Dateien
    -- nicht von Windows-1252 unterschieden werden können. Wir erlauben daher nur
    -- Windows-1252 als expliziten Fallback.
    SET @FallbackEncoding = N'Windows-1252';

    DECLARE @NormalizedPath nvarchar(4000) = @FilePath;

    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\\', N'/');
    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\', N'/');

    IF @NormalizedPath LIKE N'%/../%' OR @NormalizedPath LIKE N'%/..'
       OR @NormalizedPath LIKE N'../%'
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51322, N'Pfad enthält verbotene relative Segmente oder Traversal.');
        GOTO EmitResult;
    END;

    IF @NormalizedPath NOT LIKE N'[A-Za-z]:/%'
       AND @NormalizedPath NOT LIKE N'//%'
       AND @NormalizedPath NOT LIKE N'/%'
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51320, N'Ungültiger oder leerer Dateipfad.');
        GOTO EmitResult;
    END;

    IF NOT EXISTS
       (
:r ../Source/FileContentRootPredicate.sql
       )
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51321, N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.');
        GOTO EmitResult;
    END;

    DECLARE @Sql nvarchar(max)
          , @Snapshot varbinary(max)
          , @Header varbinary(4)
          , @EncodingDetected nvarchar(128)
          , @BomPresent bit = 0
          , @Content nvarchar(max)
          , @BytesRead bigint;

    -- BOM-Heuristik und exakte Dateigröße über denselben SINGLE_BLOB-Lesezugriff.
    SET @Sql = N'SELECT TOP (1)'
               + N' @Snapshot = BulkColumn, @Header = SUBSTRING(BulkColumn, 1, 4),'
               + N' @BytesRead = DATALENGTH(BulkColumn)'
               + N' FROM OPENROWSET(BULK '
               + QUOTENAME(@FilePath, N'''')
               + N', SINGLE_BLOB) AS x;';

    BEGIN TRY
        EXEC sys.sp_executesql
              @stmt = @Sql
            , @params = N'@Snapshot varbinary(max) OUTPUT, @Header varbinary(4) OUTPUT, @BytesRead bigint OUTPUT'
            , @Snapshot = @Snapshot OUTPUT
            , @Header = @Header OUTPUT
            , @BytesRead = @BytesRead OUTPUT;
    END TRY
    BEGIN CATCH
      DECLARE @HeaderProviderError nvarchar(2048) = N'Datei konnte nicht ueber OPENROWSET gelesen werden. Engine-Meldung: '
        + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
      THROW 51326, @HeaderProviderError, 1;
    END CATCH;

    IF @MaxBytes IS NOT NULL AND @BytesRead > @MaxBytes
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, @BytesRead, NULL, 0, 0, 51323, N'Datei überschreitet @MaxBytes.');
        GOTO EmitResult;
    END;

    -- Vierbyteige BOMs müssen vor den zweibyteigen Präfixen geprüft werden.
    IF @Header = 0xFFFE0000 OR @Header = 0x0000FEFF
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, @BytesRead, CASE @Header WHEN 0xFFFE0000 THEN N'UTF-32-LE' ELSE N'UTF-32-BE' END, 1, 0, 51325, N'UTF-32 wird nicht unterstützt.');
        GOTO EmitResult;
    END
    ELSE IF SUBSTRING(@Header, 1, 3) = 0xEFBBBF
    BEGIN
        SET @EncodingDetected = N'UTF-8';
        SET @BomPresent = 1;
    END
    ELSE IF SUBSTRING(@Header, 1, 2) = 0xFFFE
    BEGIN
        SET @EncodingDetected = N'UTF-16-LE';
        SET @BomPresent = 1;
    END
    ELSE IF SUBSTRING(@Header, 1, 2) = 0xFEFF
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, @BytesRead, N'UTF-16-BE', 1, 0, 51325, N'UTF-16-BE wird nicht unterstützt.');
        GOTO EmitResult;
    END
    ELSE
    BEGIN
        SET @EncodingDetected = @FallbackEncoding;
        SET @BomPresent = 0;
    END;

    -- Genau ein Byte-Snapshot für Größe, BOM und Decoder. Keine zweite
    -- Pfadauflösung; OPENROWSET selbst besitzt keine Vorallokationsgarantie.
    DECLARE @Payload varbinary(max) = SUBSTRING(@Snapshot,
        CASE WHEN @BomPresent = 0 THEN 1 WHEN @EncodingDetected = N'UTF-8' THEN 4 ELSE 3 END,
        2147483647);
    BEGIN TRY
        IF @EncodingDetected = N'UTF-16-LE'
        BEGIN
            IF DATALENGTH(@Payload) % 2 <> 0
                THROW 51326, N'Ungültige UTF-16-LE-Bytelänge.', 1;
            SET @Content = CONVERT(nvarchar(max), @Payload);
        END
        ELSE IF @EncodingDetected = N'UTF-8'
        BEGIN
            DECLARE @Utf8Bytes TABLE(Value varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
            INSERT @Utf8Bytes(Value) VALUES(@Payload);
            SELECT @Content = CONVERT(nvarchar(max), Value) FROM @Utf8Bytes;
            DECLARE @Utf8Roundtrip varbinary(max) = CONVERT(varbinary(max),
                CONVERT(varchar(max), @Content COLLATE Latin1_General_100_BIN2_UTF8));
            IF DATALENGTH(@Utf8Roundtrip) <> DATALENGTH(@Payload) OR @Utf8Roundtrip <> @Payload
                THROW 51326, N'Ungültige UTF-8-Bytesequenz.', 1;
        END
        ELSE
        BEGIN
            DECLARE @Cp1252Bytes TABLE(Value varchar(max) COLLATE Latin1_General_100_BIN2);
            INSERT @Cp1252Bytes(Value) VALUES(@Payload);
            SELECT @Content = CONVERT(nvarchar(max), Value) FROM @Cp1252Bytes;
        END;

        INSERT #tbx_LoadTextFileResult VALUES(@Content, @BytesRead, @EncodingDetected, @BomPresent, 1, NULL, NULL);
        GOTO EmitResult;
    END TRY
    BEGIN CATCH
      DECLARE @ContentProviderError nvarchar(2048) = N'Datei konnte nicht ueber OPENROWSET gelesen werden. Engine-Meldung: '
        + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
      THROW 51326, @ContentProviderError, 1;
    END CATCH;
    END TRY
    BEGIN CATCH
        IF @StartedTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointCreated = 1 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @SavepointName;
        THROW;
    END CATCH;

EmitResult:
    IF @ResultTable IS NULL
    BEGIN
        SELECT Content,BytesRead,EncodingDetected,BomPresent,IsValid,ValidationCode,ValidationMessage
        FROM #tbx_LoadTextFileResult;
        RETURN 0;
    END;
    BEGIN TRY
        SET @InsertResultSql = N'INSERT INTO ' + QUOTENAME(@ResultTable)
            + N' (Content,BytesRead,EncodingDetected,BomPresent,IsValid,ValidationCode,ValidationMessage)'
            + N' SELECT Content,BytesRead,EncodingDetected,BomPresent,IsValid,ValidationCode,ValidationMessage FROM #tbx_LoadTextFileResult;';
        EXEC sys.sp_executesql @InsertResultSql;
        IF @StartedTransaction = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @StartedTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointCreated = 1 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @SavepointName;
        THROW;
    END CATCH;
    RETURN 0;
END;
GO
