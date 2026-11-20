---
name: "toolbelt-toolbelt-toolbelt-core-usp-scheduleworkretry"
description: "Plant einen tokengebundenen Retry oder verschiebt nach Dead Letter."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_ScheduleWorkRetry"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@FailureMessage", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetry.sql"]
review_status: "draft"
source_module_version: "2.1.0"
---

# USP_ScheduleWorkRetry

## Zweck und Einsatzfälle

Plant einen tokengebundenen Retry oder verschiebt nach Dead Letter.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden. |
| `@ResultTable` | `sysname` | `NULL` | Input | Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben. |
| `@KeepData` | `bit` | `0` | Input | bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages. |
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
-- ID und Token stammen aus dem eigenen aktuellen Claim.
DECLARE @WorkItemId bigint=NULL, @ClaimToken uniqueidentifier=NULL; -- tatsächliche Claimwerte einsetzen
EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@WorkItemId, @ClaimToken=@ClaimToken,
 @FailureCode='EXAMPLE_RETRY', @FailureMessage=N'Synthetischer Testfehler';
```

## Rechte

EXECUTE sowie die Queue-Claim-Autorisierung des aufrufenden Pfades.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Fehlende Argumente, ungültige Fehlerdaten, inaktiver Claim oder nicht unterstütztes ResultTable.

## Aussagegrenzen

Diese Version unterstützt kein ResultTable-Routing; der Aufruf gibt eine Statuszeile aus toolbelt_core.VW_WorkQueue zurück.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-queue/Documentation/USP_ScheduleWorkRetry.md`

Keine Installations-, Definitions- oder Rechteattestation.
