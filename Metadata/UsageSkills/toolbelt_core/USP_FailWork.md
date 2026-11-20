---
name: "toolbelt-toolbelt-toolbelt-core-usp-failwork"
description: "Schließt genau ein CLAIMED Work Item mit passendem ClaimToken als FAILED ab. Gespeichert werden nur ein stabiler Code und eine optionale bereinigte Kurzmeldung."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_FailWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@FailureMessage", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_FailWork.sql"]
review_status: "draft"
source_module_version: "2.1.0"
---

# USP_FailWork

## Zweck und Einsatzfälle

Schließt genau ein CLAIMED Work Item mit passendem ClaimToken als FAILED ab. Gespeichert werden nur ein stabiler Code und eine optionale bereinigte Kurzmeldung.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(max)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Eindeutige Queue-ID.

Kanonischer Work-Type-Name.

Nach Erfolg stets FAILED.

UTC-Zeitpunkt der Einreihung.

Original-Login der Einreihung.

UTC-Zeitpunkt des Claims.

Original-Login des Claimers.

Bei FAILED NULL.

Bei FAILED NULL.

UTC-Zeitpunkt des Fehlabschlusses.

Original-Login des Fail-Aufrufs.

Stabiler case-sensitiver Fehlercode.

Optionale bereinigte Fehlermeldung.

Aktueller Concurrency-Marker.

Ownership-Generation des fehlgeschlagenen Claims.

Lease-Dauer des fehlgeschlagenen Claims.

Lease-Grenze des fehlgeschlagenen Claims.

Letzter Heartbeat des fehlgeschlagenen Claims.

Bei FAILED stets 0.

Kumulierte Recoveries vor diesem Abschluss.

Zeitpunkt der letzten Recovery.

Original-Login der letzten Recovery.

## Aufrufbeispiele

```sql
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_FailWork @WorkItemId=1,@ClaimToken='00000000-0000-0000-0000-000000000001',@FailureCode='DEMO.ERROR';
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Parameter-, Zustands-, Token-, Transaktions- oder ResultTable-Fehler.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-queue/Documentation/USP_FailWork.md`

Keine Installations-, Definitions- oder Rechteattestation.
