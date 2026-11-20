---
name: "toolbelt-toolbelt-toolbelt-archive-usp-listzipentriesfrombinary"
description: "Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "USP_ListZipEntriesFromBinary"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..10000 Central-Directory-Entries, Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_ListZipEntriesFromBinary.sql"]
review_status: "draft"
source_module_version: "1.4.0"
---

# USP_ListZipEntriesFromBinary

## Zweck und Einsatzfälle

Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..10000 Central-Directory-Entries, Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Einsbasierte Position im Central Directory.

Exakt dekodierter, nicht normalisierter Entry-Name.

Aus einem abschließenden Schrägstrich abgeleitete Directory-Markierung.

Deklarierte komprimierte Größe.

Deklarierte unkomprimierte Größe.

Numerischer ZIP-Methodenwert.

Deklarierte und beim Listing nicht neu berechnete CRC32.

Verschlüsselungsstatus aus den General-Purpose-Flags.

1 nur für unverschlüsselte Methods 0 und 8.

Ordinal und case-sensitive gezählte Namensduplikate.

1 nur für einen kanonischen relativen Pfad.

safe, absolute, drive-qualified, parent-traversal oder noncanonical.

DOS-Zeit ohne Zeitzonenbehauptung; bei ungültigem Wert NULL.

## Aufrufbeispiele

```sql
-- Vollständiges synthetisches ZIP mit hello.txt und dem Text Hi.
DECLARE @ZipArchive varbinary(max)=0x504B0304140000000000000021580E0E174D02000000020000000900000068656C6C6F2E7478744869504B01021400140000000000000021580E0E174D020000000200000009000000000000000000000080010000000068656C6C6F2E747874504B0506000000000100010037000000290000000000;
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@ZipArchive;
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Parameter-, Struktur-, Limit-, Feature- und Providerfehlerbereich.

## Aussagegrenzen

ZIP64 und Multi-Disk werden abgelehnt. Metadaten sind keine Integritätsbestätigung des Payloads.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.archive.zip-memory/Documentation/USP_ListZipEntriesFromBinary.md`

Keine Installations-, Definitions- oder Rechteattestation.
