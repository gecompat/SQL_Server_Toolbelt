---
name: "toolbelt-toolbelt-toolbelt-core-usp-setexecutioncontext"
description: "Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-context"
schema_name: "toolbelt_core"
object_name: "USP_SetExecutionContext"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExpectedExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL (Default) erhält die bisherige CorrelationId; eine explizite ID ersetzt sie. Es gibt hier kein Correlation-Clear-Flag."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearActor=1 verwenden; Actor muss dann NULL sein."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearTenant=1 verwenden; Tenant muss dann NULL sein."}, {"name": "@ClearActor", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 erhält den Actor bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Actor aus dem Sessionkontext. Bei 1 darf Actor auch nicht als Leertext übergeben werden, sondern muss NULL sein."}, {"name": "@ClearTenant", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 erhält den Tenant bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Tenant. Bei 1 muss Tenant NULL sein, auch Leertext ist ein Konflikt."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_SetExecutionContext.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_SetExecutionContext

## Zweck und Einsatzfälle

Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL (Default) erhält die bisherige CorrelationId; eine explizite ID ersetzt sie. Es gibt hier kein Correlation-Clear-Flag. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearActor=1 verwenden; Actor muss dann NULL sein. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearTenant=1 verwenden; Tenant muss dann NULL sein. |
| `@ClearActor` | `bit` | `0` | Input | Taxativ für bit: 0 erhält den Actor bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Actor aus dem Sessionkontext. Bei 1 darf Actor auch nicht als Leertext übergeben werden, sondern muss NULL sein. |
| `@ClearTenant` | `bit` | `0` | Input | Taxativ für bit: 0 erhält den Tenant bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Tenant. Bei 1 muss Tenant NULL sein, auch Leertext ist ein Konflikt. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.

## Aufrufbeispiele

```sql
-- Voraussetzung: in derselben Session zuvor USP_BeginExecution aufrufen.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id, @Actor=N'Contoso example', @Tenant=N'Fabrikam';
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
- `Modules/toolbelt.core.execution-context/Documentation/USP_SetExecutionContext.md`

Keine Installations-, Definitions- oder Rechteattestation.
