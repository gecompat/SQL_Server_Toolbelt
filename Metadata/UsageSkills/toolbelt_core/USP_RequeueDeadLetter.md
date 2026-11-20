---
name: "toolbelt-toolbelt-toolbelt-core-usp-requeuedeadletter"
description: "Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_RequeueDeadLetter"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung."}, {"name": "@RequeueReason", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql"]
review_status: "draft"
source_module_version: "2.1.0"
---

# USP_RequeueDeadLetter

## Zweck und Einsatzfälle

Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Eindeutige Queue-ID.

Kanonischer Work-Type-Name.

QUEUED, CLAIMED, COMPLETED oder FAILED.

UTC-Zeitpunkt der Einreihung.

Original-Login der Einreihung.

UTC-Zeitpunkt des Claims.

Original-Login des Claimers.

UTC-Zeitpunkt eines erfolgreichen Abschlusses.

Original-Login des erfolgreichen Abschlusses.

UTC-Zeitpunkt eines Fehlabschlusses.

Original-Login des Fehlabschlusses.

Optionaler stabiler Fehlercode.

Optionale bereinigte Fehlermeldung.

Aktueller Concurrency-Marker.

Monotoner Ownership-Zähler.

Dauer der aktuellen oder letzten Lease.

Exklusive UTC-Grenze der aktuellen oder letzten Lease.

Zeitpunkt des letzten Heartbeats.

1 nur bei aktuell CLAIMED und abgelaufener Lease.

Kumulierte kontrollierte Recoveries.

Zeitpunkt der letzten Recovery.

Original-Login der letzten Recovery.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.

## Aufrufbeispiele

```sql
-- Eine tatsächliche eigene DEAD_LETTER-ID einsetzen.
DECLARE @WorkItemId bigint=NULL;
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@WorkItemId, @RequeueReason=N'Synthetischer Wiederholungsversuch';
```

## Rechte

EXECUTE und die vorgesehenen Queue-Autorisierungen; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Fehlende ResultTable-Dependency, ungültige ID, nicht requeuebarer Zustand oder Callertransaktion.

## Aussagegrenzen

Bei Fehlern entsteht keine fachliche Statuszeile. Managed-Holds benötigen den geschützten Freigabepfad.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-queue/Documentation/USP_RequeueDeadLetter.md`

Keine Installations-, Definitions- oder Rechteattestation.
