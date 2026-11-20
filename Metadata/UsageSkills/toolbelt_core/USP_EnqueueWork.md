---
name: "toolbelt-toolbelt-toolbelt-core-usp-enqueuework"
description: "Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_EnqueueWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser ältere Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{\"value\":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql"]
review_status: "draft"
source_module_version: "2.1.0"
---

# USP_EnqueueWork

## Zweck und Einsatzfälle

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser ältere Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Eindeutige Queue-ID.

Kanonischer Work-Type-Name.

Nach Enqueue stets QUEUED.

UTC-Zeitpunkt der Einreihung.

Original-Login der Einreihung.

UTC-Zeitpunkt des Claims; nach Enqueue NULL.

Original-Login des Claimers; nach Enqueue NULL.

UTC-Abschlusszeit; nach Enqueue NULL.

Original-Login des Abschlusses; nach Enqueue NULL.

UTC-Fehlerzeit; nach Enqueue NULL.

Original-Login des Fail-Aufrufs; nach Enqueue NULL.

Stabiler Fehlercode; nach Enqueue NULL.

Optionale bereinigte Fehlermeldung; nach Enqueue NULL.

Aktueller Concurrency-Marker.

Nach Enqueue 0; wird bei jedem Claim erhöht.

Nach Enqueue NULL.

Nach Enqueue NULL.

Nach Enqueue NULL.

Nach Enqueue 0.

Nach Enqueue 0.

Nach Enqueue NULL.

Nach Enqueue NULL.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='demo.json', @PayloadJson=N'{"value":1}';
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Work-Type-, Payload-, Transaktions- oder ResultTable-Fehler. 51998: explizites ENQUEUE fehlt oder DENY gewinnt; Prüfung vor Insert und Idempotencyauskunft.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueWork.md`

Keine Installations-, Definitions- oder Rechteattestation.
