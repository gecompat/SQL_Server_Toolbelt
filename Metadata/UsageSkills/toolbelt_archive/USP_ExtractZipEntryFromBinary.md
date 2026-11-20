---
name: "toolbelt-toolbelt-toolbelt-archive-usp-extractzipentryfrombinary"
description: "Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "USP_ExtractZipEntryFromBinary"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge."}, {"name": "@EntryName", "sql_type": "nvarchar(1024)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(9,2)", "sql_default": "200.00", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/<1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad."}, {"name": "@FailIfEncrypted", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql"]
review_status: "draft"
source_module_version: "1.4.0"
---

# USP_ExtractZipEntryFromBinary

## Zweck und Einsatzfälle

Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/&lt;1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad. |
| `@FailIfEncrypted` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 lehnt einen verschlüsselten ausgewählten Entry mit 51324 ab (Default); 0 liefert ausschließlich dessen Metadaten mit IsEncrypted=1 und EntryPayload=NULL, keine Entschlüsselung/Passwortübergabe. NULL wird wie 1 normalisiert. Der erlaubte Metadatenpfad passiert vor Method-/Payloadgrößen-/Ratio-/CRC-Extraktionsprüfungen; er qualifiziert keine lesbare Payload. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Exakter Entry-Name aus dem Central Directory.

Komprimierte Entry-Größe laut Central Directory.

Unkomprimierte Entry-Größe, nach erfolgreicher Extraktion gegen die tatsächliche Ausgabe geprüft.

ZIP Compression Method. Unterstützt werden 0 (Stored) und 8 (Deflate).

CRC32 des tatsächlichen Payloads als SQL-int-Bitmuster. Bei verschlüsseltem Status stammt der Wert aus dem Central Directory.

1 kennzeichnet einen als verschlüsselt markierten Entry.

Dekomprimierter Payload. Bei @FailIfEncrypted=0 und verschlüsseltem Entry ist der Wert NULL.

## Aufrufbeispiele

```sql
-- Vollständiges synthetisches ZIP mit hello.txt und dem Text Hi.
DECLARE @ZipArchive varbinary(max)=0x504B0304140000000000000021580E0E174D02000000020000000900000068656C6C6F2E7478744869504B01021400140000000000000021580E0E174D020000000200000009000000000000000000000080010000000068656C6C6F2E747874504B0506000000000100010037000000290000000000;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@ZipArchive, @EntryName=N'hello.txt';
```

## Rechte

Erforderlich sind EXECUTE auf diesem Objekt und bei @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Parameter-, ZIP-Struktur-, Limit-, Feature-, Integritäts- und Providerfehlerbereich.

## Aussagegrenzen

Nicht unterstützt: ZIP64, Multi-Disk, Verschlüsselungsentschlüsselung, Deflate64, unbekannte Methods und zusätzliche Central-Directory-Datensätze.

Harte Providerlimits: 268435456 Archivbytes, 134217728 komprimierte Entry-Bytes und 10000 Entries.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.archive.zip-memory/Documentation/USP_ExtractZipEntryFromBinary.md`

Keine Installations-, Definitions- oder Rechteattestation.
