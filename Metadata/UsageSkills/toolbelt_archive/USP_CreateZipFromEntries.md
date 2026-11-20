---
name: "toolbelt-toolbelt-toolbelt-archive-usp-createzipfromentries"
description: "Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-memory"
schema_name: "toolbelt_archive"
object_name: "USP_CreateZipFromEntries"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EntryTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation."}, {"name": "@CompressionMethod", "sql_type": "varchar(max)", "sql_default": "'Stored'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryNameCodeUnits", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxTotalPayloadBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@MaxEnvelopeBytes", "sql_type": "bigint", "sql_default": "71303168", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@WriterBudgetMilliseconds", "sql_type": "int", "sql_default": "30000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.archive.zip-memory/Source/USP_CreateZipFromEntries.sql"]
review_status: "draft"
source_module_version: "1.4.0"
---

# USP_CreateZipFromEntries

## Zweck und Einsatzfälle

Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntryTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation. |
| `@CompressionMethod` | `varchar(max)` | `'Stored'` | Input | Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer. |
| `@MaxEntries` | `int` | `256` | Input | Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryNameCodeUnits` | `int` | `1024` | Input | Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxTotalPayloadBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxArchiveBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@MaxEnvelopeBytes` | `bigint` | `71303168` | Input | Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@WriterBudgetMilliseconds` | `int` | `30000` | Input | Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Vollständig finalisiertes ZIP-Binary.

Tatsächliche Archivgröße in Bytes.

Anzahl vorhandener Dateien, leere Liste erlaubt.

Summe unkomprimierter Payloadbytes.

ZIP-Methode 0 Stored oder 8 Deflate.

## Aufrufbeispiele

```sql
CREATE TABLE #ZipInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); INSERT #ZipInput VALUES(1,N'hello.txt',0x4869); EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput';
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

TBX_ZIP_WRITE_*; kein Teiloutput; Original-Enginefehler und Callertransaktionszustand erhalten.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.archive.zip-memory/Documentation/USP_CreateZipFromEntries.md`

Keine Installations-, Definitions- oder Rechteattestation.
