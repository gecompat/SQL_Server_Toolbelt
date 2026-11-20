---
name: "toolbelt-toolbelt-toolbelt-core-usp-executeworktypeinnewsession"
description: "Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_ExecuteWorkTypeInNewSession"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@SuppressResult", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 liefert die Infrastruktur-Ergebniszeile oder routet sie nach ResultTable (Default/NULL); 1 unterdrückt nur diese Ausgabe nach erfolgreichem Remote-Handlerlauf und Returncodeprüfung. Mit nicht-NULL ResultTable unvereinbar."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# USP_ExecuteWorkTypeInNewSession

## Zweck und Einsatzfälle

Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@SuppressResult` | `bit` | `0` | Input | Taxativ für bit: 0 liefert die Infrastruktur-Ergebniszeile oder routet sie nach ResultTable (Default/NULL); 1 unterdrückt nur diese Ausgabe nach erfolgreichem Remote-Handlerlauf und Returncodeprüfung. Mit nicht-NULL ResultTable unvereinbar. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

ExecutedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

ProviderName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

LinkedServerName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

TargetDatabaseName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

WorkTypeName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

ParameterMode: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

CallerSessionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

RemoteSessionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

CallerXactState: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

CallerTransactionCount: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

ExecutionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

CorrelationId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

HandlerReturnCode: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

RemoteStartedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

RemoteCompletedAtUtc: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

DurationMilliseconds: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='demo.noop';
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Provider-, Work-Type-, Payload- und ResultTable-Fehler; 51628: Payloadlimit, 51629: fehlende lokale EXECUTE_NEW_SESSION-Policy. Remote ist zusätzlich Handler-EXECUTE erforderlich.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.second-session/Documentation/USP_ExecuteWorkTypeInNewSession.md`

Keine Installations-, Definitions- oder Rechteattestation.
