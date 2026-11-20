---
name: "toolbelt-toolbelt-toolbelt-core-usp-requestexecutioncancellation"
description: "Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-cancel"
schema_name: "toolbelt_core"
object_name: "USP_RequestExecutionCancellation"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Explizite Ziel-ID darf nicht die Null-GUID sein. NULL/Default verwendet den aktiven Execution Context; fehlt dann eine ID, entsteht ein Fehler. Keine aktive Callertransaktion zulässig."}, {"name": "@CancellationReason", "sql_type": "nvarchar(512)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Grund nvarchar(512), keine Ausführung und keine automatische Redigierung; keine Secrets übergeben. NULL/leer bzw. LEN=0 (reine Spaces) wird NULL. Bei wiederholter Anforderung derselben ID bleiben erster Grund und Zeitpunkt erhalten."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_RequestExecutionCancellation

## Zweck und Einsatzfälle

Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Explizite Ziel-ID darf nicht die Null-GUID sein. NULL/Default verwendet den aktiven Execution Context; fehlt dann eine ID, entsteht ein Fehler. Keine aktive Callertransaktion zulässig. |
| `@CancellationReason` | `nvarchar(512)` | `NULL` | Input | Optionaler Unicode-Grund nvarchar(512), keine Ausführung und keine automatische Redigierung; keine Secrets übergeben. NULL/leer bzw. LEN=0 (reine Spaces) wird NULL. Bei wiederholter Anforderung derselben ID bleiben erster Grund und Zeitpunkt erhalten. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Kein fachliches Resultset; den Status liefert TVF_ExecutionCancellationStatus.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N'planned maintenance';
```

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation
    @CancellationReason = N'planned maintenance';

SELECT *
FROM toolbelt_core.TVF_ExecutionCancellationStatus
    (toolbelt_core.SVF_CurrentExecutionId());
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Parameter-, Context-, Transaktions- oder Quotenfehler: 52605 bei 100000 DBrequests, 52606 bei 10000 je Principal; bestehende IDs bleiben idempotent.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.execution-cancel/Documentation/USP_RequestExecutionCancellation.md`

Keine Installations-, Definitions- oder Rechteattestation.
