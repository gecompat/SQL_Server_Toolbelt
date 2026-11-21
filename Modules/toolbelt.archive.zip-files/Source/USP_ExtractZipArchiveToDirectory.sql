SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_archive.USP_ExtractZipArchiveToDirectory
      @ZipArchive varbinary(max) = NULL
    , @RootAlias sysname = NULL
    , @RelativeDirectory nvarchar(4000) = N''
    , @OverwriteExistingFiles bit = 0
    , @MaxArchiveBytes bigint = 67108864
    , @MaxEntries bigint = 1000
    , @MaxEntryBytes bigint = 16777216
    , @MaxTotalExpandedBytes bigint = 268435456
    , @MaxCompressionRatio decimal(9,2) = 200.00
    , @MaxPathLength int = 1024
    , @ExecutionIdentity nvarchar(16) = N'Caller'
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-archive-extract-zip-directory"
-- description: "Extrahiert ein ZIP gestreamt in einen konfigurierten lokalen NTFS-Ordner und meldet jeden Eintrag."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.archive.zip-files"
-- schema_name: "toolbelt_archive"
-- object_name: "USP_ExtractZipArchiveToDirectory"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig."}, {"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig."}, {"name": "@RelativeDirectory", "sql_type": "nvarchar(4000)", "sql_default": "N''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig."}, {"name": "@OverwriteExistingFiles", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Archivbytes. 1 bis 268435456, NULL ungültig."}, {"name": "@MaxEntries", "sql_type": "bigint", "sql_default": "1000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig."}, {"name": "@MaxTotalExpandedBytes", "sql_type": "bigint", "sql_default": "268435456", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(9,2)", "sql_default": "200.00", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig."}, {"name": "@MaxPathLength", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus."}]
-- source_paths: ["Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipArchiveToDirectory.sql", "Modules/toolbelt.filesystem.windows/Clr/ArchiveSqlBridge.cs", "Modules/toolbelt.filesystem.windows/Clr/ArchiveDestination.cs", "Modules/toolbelt.filesystem.windows/Clr/ArchiveNativePaths.cs", "Modules/toolbelt.archive.zip-memory/Clr/DirectoryExtraction.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_ExtractZipArchiveToDirectory
--
-- ## Zweck und Einsatzfälle
--
-- Extrahiert reguläre ZIP-Dateien und Verzeichnisse in einen autorisierten lokalen Ordner. Sinnvoll für eine vollständige sequenzielle Archivextraktion mit Einzelergebnissen.
--
-- ## Voraussetzungen
--
-- Lokale Installation auf Windows SQL Server, festes NTFS-Laufwerk und vorhandene Root-Konfiguration. Für fehlende Verzeichnisse ist AllowCreateDirectory erforderlich. Die Sitzung darf keine aktive oder implizite SQL-Transaktion haben.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Default | Vertrag |
-- |---|---|---|---|
-- | `@ZipArchive` | `varbinary(max)` | `NULL` | Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig. |
-- | `@RootAlias` | `sysname` | `NULL` | Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig. |
-- | `@RelativeDirectory` | `nvarchar(4000)` | `N''` | Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig. |
-- | `@OverwriteExistingFiles` | `bit` | `0` | 0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig. |
-- | `@MaxArchiveBytes` | `bigint` | `67108864` | Archivbytes. 1 bis 268435456, NULL ungültig. |
-- | `@MaxEntries` | `bigint` | `1000` | Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig. |
-- | `@MaxEntryBytes` | `bigint` | `16777216` | Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig. |
-- | `@MaxTotalExpandedBytes` | `bigint` | `268435456` | Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich. |
-- | `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig. |
-- | `@MaxPathLength` | `int` | `1024` | ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag. |
-- | `@KeepData` | `bit` | `0` | Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0. |
-- | `@Debug` | `tinyint` | `0` | 0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers. |
-- | `@Hilfe` | `bit` | `0` | 1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus. |
--
-- ## Ergebnisse
--
-- In Central-Directory-Reihenfolge je Entry Ordinal bigint (ab 1), EntryName nvarchar(max), EntryKind varchar(9), Status varchar(16), BytesWritten bigint NULL und ErrorCode varchar(64) NULL. Status completed, failed oder not_attempted. Verzeichnisse liefern directory und 0 Bytes bei Erfolg. Ein Fehler nach dem Publish behält completed und meldet den Fehlercode.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @Hilfe = 1;
-- ```
--
-- ## Rechte
--
-- EXECUTE auf die öffentliche Fassade, Zugriff des Ausführungskontexts auf die Rootkonfiguration und die tatsächlich benötigten NTFS-Rechte. Überschreiben setzt einen dafür freigegebenen exklusiven Root voraus. Eigentümer und DACL werden an Handles geprüft. Nur die gewählte Identität und vertrauenswürdige lokale Systemadministration dürfen dort schreiben. Unabhängige Schreiber unter derselben Identität, überlappende Roots und bereits gültige fremde Schreibhandles muss der Betreiber ausschließen.
--
-- ## Ressourcenbedarf
--
-- Das Archiv braucht seekbaren Zugriff auf den LOB. Nutzdaten eines Eintrags werden in begrenzten Chunks über Staging kopiert. Es gibt keine feste Gesamtlaufzeit.
--
-- ## Nebenwirkungen
--
-- Dateien werden einzeln veröffentlicht. Bereits veröffentlichte Dateien und angelegte Verzeichnisse bleiben bei einem späteren Fehler erhalten. Ein SQL-Rollback kann sie nicht zurücknehmen.
--
-- ## Fehlerbehandlung
--
-- Zuerst werden Manifest, Pfade und bekannte Zielkonflikte ohne Extraktionsmutationen geprüft. Bei einem Fehler in diesem Preflight wird kein Entry versucht. Beim Payload- oder Dateifehler wird die weitere Verarbeitung abgebrochen. Ein ungültiger Aufruf oder ein Archiv ohne verlässliches Manifest liefert einen SQL-Fehler. Bei unsicherer Identitätswiederherstellung endet der Aufruf ohne weitere Verarbeitung.
--
-- ## Aussagegrenzen
--
-- Ohne ZIP64, Multi-Disk-ZIP, verschlüsselte Einträge, Reparse Points, Hardlinks, Netzwerkziele oder Linux. Der Scope ist einzeldatei-atomar. Quelldaten und Berechtigungen können das Resultat weiterhin beschränken.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_archive' AS sysname) AS SchemaName,
            CAST(N'USP_ExtractZipArchiveToDirectory' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Extrahiert ein ZIP gestreamt in einen konfigurierten lokalen NTFS-Ordner und meldet jeden Eintrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'Ordinal', N'bigint', NULL, 0, NULL, CAST(N'Einsbasierter Ordinal aus dem Central Directory.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'EntryName', N'nvarchar(max)', NULL, 0, NULL, CAST(N'Dekodierter ursprünglicher ZIP-Eintragsname.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'EntryKind', N'varchar(9)', NULL, 0, NULL, CAST(N'file oder directory.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'Status', N'varchar(16)', NULL, 0, NULL, CAST(N'completed, failed oder not_attempted.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'BytesWritten', N'bigint', NULL, 1, NULL, CAST(N'Veröffentlichte Bytes; 0 bei abgeschlossenem Verzeichnis.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ErrorCode', N'varchar(64)', NULL, 1, NULL, CAST(N'Kontrollierter Code zum Abbruch oder NULL.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Gültiges leeres ZIP ohne Dateimutationen.' AS nvarchar(max)), CAST(N'DECLARE @Zip varbinary(max) = 0x504B0506000000000000000000000000000000000000;
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @ZipArchive=@Zip, @RootAlias=N''ContosoExports'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@ZipArchive', N'varbinary(max)', 1, 0, N'NULL', CAST(N'Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@RelativeDirectory', N'nvarchar(4000)', 0, 0, N'N''''', CAST(N'Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@OverwriteExistingFiles', N'bit', 0, 0, N'0', CAST(N'0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxArchiveBytes', N'bigint', 0, 0, N'67108864', CAST(N'Archivbytes. 1 bis 268435456, NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxEntries', N'bigint', 0, 0, N'1000', CAST(N'Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxEntryBytes', N'bigint', 0, 0, N'16777216', CAST(N'Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxTotalExpandedBytes', N'bigint', 0, 0, N'268435456', CAST(N'Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@MaxCompressionRatio', N'decimal(9,2)', 0, 0, N'200.00', CAST(N'Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@MaxPathLength', N'int', 0, 0, N'1024', CAST(N'ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@ExecutionIdentity', N'nvarchar(16)', 0, 0, N'N''Caller''', CAST(N'Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 14, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 15, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_archive' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ExtractZipArchiveToDirectory' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-archive-extract-zip-directory"
description: "Extrahiert ein ZIP gestreamt in einen konfigurierten lokalen NTFS-Ordner und meldet jeden Eintrag."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-files"
schema_name: "toolbelt_archive"
object_name: "USP_ExtractZipArchiveToDirectory"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig."}, {"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig."}, {"name": "@RelativeDirectory", "sql_type": "nvarchar(4000)", "sql_default": "N''''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig."}, {"name": "@OverwriteExistingFiles", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Archivbytes. 1 bis 268435456, NULL ungültig."}, {"name": "@MaxEntries", "sql_type": "bigint", "sql_default": "1000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig."}, {"na' AS nvarchar(max)) + N'me": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig."}, {"name": "@MaxTotalExpandedBytes", "sql_type": "bigint", "sql_default": "268435456", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(9,2)", "sql_default": "200.00", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig."}, {"name": "@MaxPathLength", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N''Caller''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0."}, {"name": "@Debug", "sql_type": "tinyint", "sq' + N'l_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus."}]
source_paths: ["Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipArchiveToDirectory.sql", "Modules/toolbelt.filesystem.windows/Clr/ArchiveSqlBridge.cs", "Modules/toolbelt.filesystem.windows/Clr/ArchiveDestination.cs", "Modules/toolbelt.filesystem.windows/Clr/ArchiveNativePaths.cs", "Modules/toolbelt.archive.zip-memory/Clr/DirectoryExtraction.cs"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_ExtractZipArchiveToDirectory

## Zweck und Einsatzfälle

Extrahiert reguläre ZIP-Dateien und Verzeichnisse in einen autorisierten lokalen Ordner. Sinnvoll für eine vollständige sequenzielle Archivextraktion mit Einzelergebnissen.

## Voraussetzungen

Lokale Installation auf Windows SQL Server, festes NTFS-Laufwerk und vorhandene Root-Konfiguration. Für fehlende Verzeichnisse ist AllowCreateDirectory erforderlich. Die Sitzung darf keine aktive oder implizite SQL-Transaktion haben.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Vertrag |
|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig. |
| `@RootAlias` | `sysname` | `NULL` | Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig. |
| `@RelativeDirectory` | `nvarchar(4000)` | `N''''` | Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig. |
| `@OverwriteExistingFiles` | `bit` | `0` | 0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist' + N' ungültig. |
| `@MaxArchiveBytes` | `bigint` | `67108864` | Archivbytes. 1 bis 268435456, NULL ungültig. |
| `@MaxEntries` | `bigint` | `1000` | Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig. |
| `@MaxTotalExpandedBytes` | `bigint` | `268435456` | Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig. |
| `@MaxPathLength` | `int` | `1024` | ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N''Caller''` | Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig. |
| `@ResultTable` | `sysname` | `NULL` | NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag. |
| `@KeepData` | `bit` | `0` | Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0. |
| `@Debug` | `tinyint` | `0` | 0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers. |
| `@Hilfe` | `bit` | `0` | 1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus. |

## Ergebnisse

In Central-Directory-Reihenfolge je Entry Ordinal bigint (ab 1), EntryName nvarchar(max), EntryKind varchar(9), Status varchar(16), BytesWritten bigint NULL und ErrorCode varchar(64) NULL. Status completed, failed oder not_attempted. Verzeichnisse liefern directory und 0 Bytes bei Erfolg. Ein Fehler nach dem Publish behält completed und meldet den Fehlercode.

## Aufrufbeispiele

```sql
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @Hilfe = 1;
```

## Rechte

EXECUTE auf die öffentliche Fassade, Zugriff des Ausführungskontexts auf die Rootkonfiguration und die tatsächlich benötigten NTFS-Rec' + N'hte. Überschreiben setzt einen dafür freigegebenen exklusiven Root voraus. Eigentümer und DACL werden an Handles geprüft. Nur die gewählte Identität und vertrauenswürdige lokale Systemadministration dürfen dort schreiben. Unabhängige Schreiber unter derselben Identität, überlappende Roots und bereits gültige fremde Schreibhandles muss der Betreiber ausschließen.

## Ressourcenbedarf

Das Archiv braucht seekbaren Zugriff auf den LOB. Nutzdaten eines Eintrags werden in begrenzten Chunks über Staging kopiert. Es gibt keine feste Gesamtlaufzeit.

## Nebenwirkungen

Dateien werden einzeln veröffentlicht. Bereits veröffentlichte Dateien und angelegte Verzeichnisse bleiben bei einem späteren Fehler erhalten. Ein SQL-Rollback kann sie nicht zurücknehmen.

## Fehlerbehandlung

Zuerst werden Manifest, Pfade und bekannte Zielkonflikte ohne Extraktionsmutationen geprüft. Bei einem Fehler in diesem Preflight wird kein Entry versucht. Beim Payload- oder Dateifehler wird die weitere Verarbeitung abgebrochen. Ein ungültiger Aufruf oder ein Archiv ohne verlässliches Manifest liefert einen SQL-Fehler. Bei unsicherer Identitätswiederherstellung endet der Aufruf ohne weitere Verarbeitung.

## Aussagegrenzen

Ohne ZIP64, Multi-Disk-ZIP, verschlüsselte Einträge, Reparse Points, Hardlinks, Netzwerkziele oder Linux. Der Scope ist einzeldatei-atomar. Quelldaten und Berechtigungen können das Resultat weiterhin beschränken.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    -- The engine can report XACT_STATE()=1 in an autocommit request
    -- with @@TRANCOUNT=0. Only a user transaction or a doomed state blocks.
    IF @@TRANCOUNT <> 0 OR XACT_STATE() = -1 OR (@@OPTIONS & 2) <> 0
        THROW 54620, N'ZIP-Extraktion erfordert eine Sitzung ohne aktive oder implizite Transaktion.', 1;
    IF @ZipArchive IS NULL OR DATALENGTH(@ZipArchive) = 0 OR @RootAlias IS NULL OR
       @RelativeDirectory IS NULL OR @OverwriteExistingFiles IS NULL OR @MaxArchiveBytes IS NULL OR
       @MaxEntries IS NULL OR @MaxEntryBytes IS NULL OR @MaxTotalExpandedBytes IS NULL OR
       @MaxCompressionRatio IS NULL OR @MaxPathLength IS NULL OR @ExecutionIdentity IS NULL
        THROW 54621, N'Erforderliche Argumente der ZIP-Extraktion fehlen.', 1;

    IF @ResultTable IS NULL
    BEGIN
        EXEC toolbelt_filesystem.CLR_ExtractZipArchiveToDirectory
            @ZipArchive, @RootAlias, @RelativeDirectory, @MaxArchiveBytes, @MaxEntries,
            @MaxEntryBytes, @MaxTotalExpandedBytes, @MaxCompressionRatio, @MaxPathLength,
            @OverwriteExistingFiles, @ExecutionIdentity, 0, 0;
        RETURN 0;
    END;
    IF LEFT(@ResultTable, 1) <> N'#' OR LEFT(@ResultTable, 2) = N'##' OR
       LEN(@ResultTable) NOT BETWEEN 2 AND 116 OR @ResultTable LIKE N'%.%' OR
       LEFT(@ResultTable, 5) = N'#tbx_' OR OBJECT_ID(N'tempdb..' + QUOTENAME(@ResultTable), N'U') IS NULL
        THROW 54624, N'ResultTable muss eine vorhandene lokale temporäre Tabelle sein.', 1;

    CREATE TABLE #tbx_ZipDirectoryResult
    (
        Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
        Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
    );
    EXEC toolbelt_filesystem.CLR_ExtractZipArchiveToDirectory
        @ZipArchive, @RootAlias, @RelativeDirectory, @MaxArchiveBytes, @MaxEntries,
        @MaxEntryBytes, @MaxTotalExpandedBytes, @MaxCompressionRatio, @MaxPathLength,
        @OverwriteExistingFiles, @ExecutionIdentity, 1, 0;
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC toolbelt_core.USP_PrepareResultTable
            @ResultTableToAlter=@ResultTable, @LikeTable=N'#tbx_ZipDirectoryResult',
            @KeepData=@KeepData, @Debug=@Debug;
        DECLARE @Sql nvarchar(max) = N'INSERT ' + QUOTENAME(@ResultTable) +
            N' (Ordinal,EntryName,EntryKind,Status,BytesWritten,ErrorCode)
               SELECT Ordinal,EntryName,EntryKind,Status,BytesWritten,ErrorCode FROM #tbx_ZipDirectoryResult;';
        EXEC sys.sp_executesql @Sql;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    RETURN 0;
END;
GO
