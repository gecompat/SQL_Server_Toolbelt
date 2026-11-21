---
name: "toolbelt-archive-extract-zip-directory"
description: "Extrahiert ein ZIP gestreamt in einen konfigurierten lokalen NTFS-Ordner und meldet jeden Eintrag."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-files"
schema_name: "toolbelt_archive"
object_name: "USP_ExtractZipArchiveToDirectory"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiges ZIP als Bytes. NULL oder 0x ist ungültig."}, {"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandener konfigurierter Alias mit AllowWrite. NULL oder leer ist ungültig."}, {"name": "@RelativeDirectory", "sql_type": "nvarchar(4000)", "sql_default": "N''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig."}, {"name": "@OverwriteExistingFiles", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Archivbytes. 1 bis 268435456, NULL ungültig."}, {"name": "@MaxEntries", "sql_type": "bigint", "sql_default": "1000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig."}, {"name": "@MaxTotalExpandedBytes", "sql_type": "bigint", "sql_default": "268435456", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(9,2)", "sql_default": "200.00", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig."}, {"name": "@MaxPathLength", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL liefert Zeilen. Sonst vorhandene lokale temporäre Tabelle nach ResultTable-Vertrag."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei ResultTable 0 ersetzt und 1 ergänzt bei kompatiblem Schema. NULL entspricht 0."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0 bis 255. NULL entspricht 0. Nur Diagnose des ResultTable-Helpers."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert die Skillzeile vor der Facharbeit. 0 oder NULL führt die Fachfunktion aus."}]
source_paths: ["Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipArchiveToDirectory.sql", "Modules/toolbelt.filesystem.windows/Clr/ArchiveSqlBridge.cs", "Modules/toolbelt.filesystem.windows/Clr/ArchiveDestination.cs", "Modules/toolbelt.filesystem.windows/Clr/ArchiveNativePaths.cs", "Modules/toolbelt.filesystem.windows/Clr/ArchiveDirectoryExtraction.cs", "Modules/toolbelt.archive.zip-memory/Clr/ArchiveExtraction.cs"]
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
| `@RelativeDirectory` | `nvarchar(4000)` | `N''` | Relativer Zielordner. Leer verwendet den Root. NULL, absolute und unsichere Pfade sind ungültig. |
| `@OverwriteExistingFiles` | `bit` | `0` | 0 lehnt bestehende Dateien ab. 1 erfordert unabhängig davon administratives AllowZipOverwrite und exklusive Schreibhoheit. NULL ist ungültig. |
| `@MaxArchiveBytes` | `bigint` | `67108864` | Archivbytes. 1 bis 268435456, NULL ungültig. |
| `@MaxEntries` | `bigint` | `1000` | Dateien und Verzeichnisse. 1 bis 10000, NULL ungültig. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Expandierte Bytes je Datei. 1 bis 67108864, NULL ungültig. |
| `@MaxTotalExpandedBytes` | `bigint` | `268435456` | Summe deklarierter expandierter Bytes. Positiver bigint, NULL ungültig. Entry- und Anzahlgrenzen gelten zusätzlich. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Expansionsfaktor 1,00 bis 9999999,99, NULL ungültig. |
| `@MaxPathLength` | `int` | `1024` | ZIP-Eintragsname in UTF-16-Codeeinheiten. 1 bis 1024, NULL ungültig. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Ordinal exakt Caller oder ServiceAccount. ServiceAccount erfordert die freigegebene Datenbankrolle und Root-AllowServiceAccount. Kein Fallback, NULL ungültig. |
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

EXECUTE auf die öffentliche Fassade, Zugriff des Ausführungskontexts auf die Rootkonfiguration und die tatsächlich benötigten NTFS-Rechte. Überschreiben setzt einen dafür freigegebenen exklusiven Root voraus. Eigentümer und DACL werden an Handles geprüft. Nur die gewählte Identität und vertrauenswürdige lokale Systemadministration dürfen dort schreiben. Unabhängige Schreiber unter derselben Identität, überlappende Roots und bereits gültige fremde Schreibhandles muss der Betreiber ausschließen.

## Ressourcenbedarf

Das Archiv braucht seekbaren Zugriff auf den LOB. Nutzdaten eines Eintrags werden in begrenzten Chunks über Staging kopiert. Es gibt keine feste Gesamtlaufzeit.

## Nebenwirkungen

Dateien werden einzeln veröffentlicht. Bereits veröffentlichte Dateien und angelegte Verzeichnisse bleiben bei einem späteren Fehler erhalten. Ein SQL-Rollback kann sie nicht zurücknehmen.

## Fehlerbehandlung

Zuerst werden Manifest, Pfade und bekannte Zielkonflikte ohne Extraktionsmutationen geprüft. Bei einem Fehler in diesem Preflight wird kein Entry versucht. Beim Payload- oder Dateifehler wird die weitere Verarbeitung abgebrochen. Ein ungültiger Aufruf oder ein Archiv ohne verlässliches Manifest liefert einen SQL-Fehler. Bei unsicherer Identitätswiederherstellung endet der Aufruf ohne weitere Verarbeitung.

## Aussagegrenzen

Ohne ZIP64, Multi-Disk-ZIP, verschlüsselte Einträge, Reparse Points, Hardlinks, Netzwerkziele oder Linux. Der Scope ist einzeldatei-atomar. Quelldaten und Berechtigungen können das Resultat weiterhin beschränken.
