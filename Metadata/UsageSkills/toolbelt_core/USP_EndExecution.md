---
name: "toolbelt-toolbelt-toolbelt-core-usp-endexecution"
description: "Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-context"
schema_name: "toolbelt_core"
object_name: "USP_EndExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExpectedExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_EndExecution.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_EndExecution

## Zweck und Einsatzfälle

Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.

## Aufrufbeispiele

```sql
-- Voraussetzung: aktiver Context in derselben Session.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.execution-context/Documentation/USP_EndExecution.md`

Keine Installations-, Definitions- oder Rechteattestation.
