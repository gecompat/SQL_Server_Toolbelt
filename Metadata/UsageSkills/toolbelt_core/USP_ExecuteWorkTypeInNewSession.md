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
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@SuppressResult", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0 oder NULL: Infrastrukturresultat direkt oder nach ResultTable; 1: diese Ausgabe nach erfolgreichem Dispatcher-Return unterdrücken. Nicht mit ResultTable kombinierbar. Das prüft NICHT automatisch HandlerReturnCode=0; ein nichtzero Handlercode kann dadurch ohne Ausgabe bleiben."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql", "Modules/toolbelt.core.second-session/Source/SecondSessionProvider.sql", "Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql", "Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# USP_ExecuteWorkTypeInNewSession

## Zweck und Einsatzfälle

Führt einen registrierten Work Type synchron per administriertem Loopback-RPC in einer getrennten Session aus und liefert optional eine Infrastrukturzeile. Kein freier SQL-Text, kein paralleler Hintergrundjob oder Clientworker.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Aktiver registrierter lokaler WorkType mit NONE oder JSON_PAYLOAD, sichtbare gültige lokale App-Policy EXECUTE_NEW_SESSION. Aktivierter gespeicherter loopback-Provider mit sichtbarem LinkedServerExists=1,RpcOutEnabled=1,Promotion=0; gültige Remote-Anmeldung und installierter Dispatcher in derselben benannten Toolbelt-DB. Remote ebenfalls aktive Registrierung/Policy/Handler-EXECUTE/korrekte Signatur. Keine automatische Provideranlage oder Umstellung nach Verbindungsfehler.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@SuppressResult` | `bit` | `0` | Input | 0 oder NULL: Infrastrukturresultat direkt oder nach ResultTable; 1: diese Ausgabe nach erfolgreichem Dispatcher-Return unterdrücken. Nicht mit ResultTable kombinierbar. Das prüft NICHT automatisch HandlerReturnCode=0; ein nichtzero Handlercode kann dadurch ohne Ausgabe bleiben. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults. |

## Ergebnisse

Unterstütztes ResultTable-Zielschema:

| Feld | Typ/NULL/Collation |
|---|---|
| `ExecutedAtUtc` | `datetime2(7) NOT NULL` |
| `ProviderName` | `varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `LinkedServerName` | `sysname NOT NULL` |
| `TargetDatabaseName` | `sysname NOT NULL` |
| `WorkTypeName` | `varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `ParameterMode` | `varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `CallerSessionId` | `int NOT NULL` |
| `RemoteSessionId` | `int NOT NULL` |
| `CallerXactState` | `smallint NOT NULL` |
| `CallerTransactionCount` | `int NOT NULL` |
| `ExecutionId` | `uniqueidentifier NOT NULL` |
| `CorrelationId` | `uniqueidentifier NOT NULL` |
| `HandlerReturnCode` | `int NULL` |
| `RemoteStartedAtUtc` | `datetime2(7) NOT NULL` |
| `RemoteCompletedAtUtc` | `datetime2(7) NOT NULL` |
| `DurationMilliseconds` | `decimal(19,3) NOT NULL` |

Direkter SELECT verwendet Ausdrücke und Variablen; physische Nullable-/Collation-Metadaten können vom festen Temp-Zielschema abweichen. Kein ORDER-BY-Vertrag für die Einzelzeile. Bei ResultTable=NULL direktes Ergebnis, sonst vorhandene caller-lokale #Temp über sameDB USP_PrepareResultTable (KeepData=0 ersetzt,1 hängt kompatibel an,NULL=>0). RETURN 0; keine OUTPUT-Parameter. Hilfe liefert zuerst die vorhandene zwölfspaltige Standardhilfe und genau eine zusätzliche vollständige Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); danach RETURN 0 vor fachlichen Prüfungen, Katalog-/Kontextlesen, RPC oder Mutation. SQL-Typbindung und ausdrücklich genannte lokale Initialisierung bleiben erhalten. SuppressResult=1 unterdrückt nur die Infrastrukturzeile, nicht den Handleraufruf. HandlerReturnCode wird ausgegeben, aber NICHT automatisch auf 0 geprüft; die Fassade prüft den Dispatcher-/ProviderReturnCode auf 0. Somit kann Return0 der Fassade mit Handlercode ungleich0 auftreten, bei unterdrücktem Resultset ohne diese sichtbare Zahl. DurationMilliseconds ist DATEDIFF_BIG(MICROSECOND,RemoteStart,RemoteEnd)/1000 als decimal(19,3), nicht komplette End-to-End-RPCdauer. ExecutedAtUtc entsteht erst für die Ausgabe; TargetDatabaseName ist DB_NAME des Toolbeltkatalogs. Keine automatische Commit-/Exactly-once-Interpretation für beliebige transaktionswidrige Handler.

## Aufrufbeispiele

```sql
-- Registrierter, erlaubter synthetischer NONE-Handler vorausgesetzt.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='contoso.noop';
-- Infrastrukturzeile einschließlich HandlerReturnCode bewusst auswerten.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Fassade und funktionierende bestehende Objekt-/Katalogrechte. Passende App-Policy EXECUTE_NEW_SESSION sowohl lokal als auch im tatsächlichen Remoteprincipal; Remote zusätzlich Dispatcher-/Handler-EXECUTE und gültiges Linked-Server-Mapping. Sichtbarkeit der WorkType-/Provider-/master.sys.servers-Daten nötig. ResultTable benötigt vorhandene Helper-/Caller-Temp-Rechte. Kein automatischer Grant/Serverrollenwechsel; Dreiteilname und Actor/Tenant verleihen keine Rechte.

## Ressourcenbedarf

Ein synchroner RPC-Aufruf, vollständige Payload bis1048576 UTF-16-Bytes und Kontextmetadaten; eigenes dynamisches Statement mit QUOTENAME-Identifiern und parametergebundenen Werten. Kein eigener Handler-/RPC-/Wallclock-/Locktimeout; DefaultTimeoutSeconds/IsIdempotent werden hier nicht durchgesetzt. Callerlocks auf benötigten Remoteobjekten können den eigenen synchronen Call blockieren. Routing verursacht zusätzliche Helper-/Temp-Arbeit nach Remoteabschluss, keine Streaming-/Heap-/Durchsatzgarantie.

## Nebenwirkungen

SET NOCOUNT ON,KeepData/SuppressResult/Debug/Hilfe NULL=>0. Liest lokalen Katalog/Policy/Provider und aktuellen ExecutionContext: IDs explizit > Kontext > NEWID bzw. gewählte ExecutionId; Actor explizit > Kontext > ORIGINAL_LOGIN, Tenant explizit > Kontext > NULL. Kontext wird als gebundene Werte übertragen, nicht als Berechtigungsnachweis. Caller-SPID/XACT_STATE/TranCount nur Ergebnisdaten. Dispatcher führt Handler im vorgesehenen eigenen Remote-Transaktionsscope aus. Callertransaktion wird nicht committed/rollbackt; uncommittable Caller ist nur ohne ResultTable erlaubt. Remote-Commit liegt vor Unterdrückung/SELECT/ResultTable-Routing: Output-/Cleanup-/Transportfehler können committed Wirkung hinterlassen. Keine automatische Wiederholung/Idempotenz; wiederholte IDs deduplizieren nicht. Debugmessages nur abstrakt, direkter SELECT kehrt vor der letzten Routing-Debugmessage zurück. Routing besitzt keinen atomaren Remote-Rollback.

## Fehlerbehandlung

51610 Name fehlt;51611 uncommittable Caller mit ResultTable;51620 SuppressResult=1 mit ResultTable;51615 lokale Registrierung fehlt;51616 deaktiviert;51629 lokale Policy fehlt;51628 Payload>1MiB;51617 Payload bei NONE;51618 ungültiges JSONobjekt;51612 Provider nicht konfiguriert;51613 deaktiviert;51614 sichtbare Serverflags ungeeignet. Remote-/Kontext-/Handler-/Policyfehler bleiben original. 51619 Dispatcher-/ProviderReturnCode NULL/nicht0 (State1) oder fehlender Routinghelper (State2, nach Remoteabschluss). HandlerReturnCode allein wird nicht so bewertet. Verlorene Antwort ist kein sicherer Nichtausführungsbeleg; keine automatische Kompensation.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Skill-/Caller-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. IDs/Actor/Tenant und Quellnamen sind Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Ein Katalogeintrag/Probe/Returncode ist kein universeller Exactly-once-/Serveridentitäts-/Gesundheitsnachweis; reale Metadaten privat behandeln.
