---
name: "toolbelt-toolbelt-toolbelt-core-usp-resolveworktype"
description: "Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_ResolveWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@RequireEnabled", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren."}, {"name": "@RequireExecutableByCaller", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung."}, {"name": "@RequiredPermission", "sql_type": "varchar(32)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY."}, {"name": "@SuppressResult", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597)."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_ResolveWorkType.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# USP_ResolveWorkType

## Zweck und Einsatzfälle

Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@RequireEnabled` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren. |
| `@RequireExecutableByCaller` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung. |
| `@RequiredPermission` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY. |
| `@SuppressResult` | `bit` | `0` | Input | Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597). |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

WorkTypeId.

WorkTypeName.

HandlerSchema.

HandlerProcedure.

HandlerQualifiedName.

ParameterMode.

PayloadContractJson.

DefaultTimeoutSeconds.

IsIdempotent.

IsEnabled.

Description.

CreatedAtUtc.

CreatedBy.

ModifiedAtUtc.

ModifiedBy.

DisabledAtUtc.

DisabledBy.

DisabledReason.

RowVersion.

HandlerExists.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='demo.noop';
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
- `Modules/toolbelt.core.work-type/Documentation/USP_ResolveWorkType.md`

Keine Installations-, Definitions- oder Rechteattestation.
