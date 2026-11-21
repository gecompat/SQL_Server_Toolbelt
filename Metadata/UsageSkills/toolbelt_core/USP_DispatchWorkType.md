---
name: "toolbelt-second-session-dispatch"
description: "Interner Remote-Dispatcher für registrierte Work Types, Kontextbindung und transaktionalen Handleraufruf."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_DispatchWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Registrierter Remote-WorkType in derselben Datenbank; NULL/nicht gefunden ergibt 51631, kein freier SQL-Text."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NONE akzeptiert ausschließlich NULL; JSON_PAYLOAD erfordert nicht-NULL Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces. Höchstens 1048576 UTF-16-Bytes; konkrete Felder nach Handlervertrag, keine allgemeine JSON-Schema-Auswertung."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Gebundene nicht-NULL Ausführungs-ID vom autorisierten Transport; keine eigene Fallback-ID. Erforderlich außerhalb Hilfe."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Gebundene nicht-NULL Korrelations-ID vom Transport; kein eigener Kontextfallback. Erforderlich außerhalb Hilfe."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Autorisierung."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Tenant-Rechteerteilung."}, {"name": "@RemoteSessionId", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird im Fachpfad vor Validierung auf @@SPID gesetzt. Bei Hilfe bleibt bereits übergebener Wert unverändert."}, {"name": "@HandlerReturnCode", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird vor Fachvalidierung NULL, danach tatsächlicher Handler-Returncode. Nichtzero wird hier nicht automatisch als Fehler behandelt oder rollbackt. Hilfe lässt den Eingangswert unverändert."}, {"name": "@StartedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird vor Fachvalidierung SYSUTCDATETIME; damit Start der Dispatchbearbeitung, nicht ausschließlich Handlerzeit. Hilfe lässt Eingangswert unverändert."}, {"name": "@CompletedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT im Fachpfad zuerst NULL, nach Handler und COMMIT SYSUTCDATETIME, aber vor abschließendem Kontextcleanup. Bei späterem Fehler kann bereits ein Zeitpunkt gesetzt sein. Hilfe lässt Eingangswert unverändert."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Hilfe plus vollständige Skillzeile ohne Änderung irgendeines OUTPUT-Werts; 0/NULL: Fachpfad."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "1.1.0"
public_entrypoints: ["toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
---

# USP_DispatchWorkType

## Zweck und Einsatzfälle

Interner Handlerdispatch im bestehenden Remoteprozess; regulärer Einstieg ausschließlich USP_ExecuteWorkTypeInNewSession. Führt nur registrierte P-/PC-Prozeduren aus, keinen frei übergebenen SQL-Text.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Remote-WorkType muss registriert/aktiv sein, Kontextmodule vorhanden, Handler sichtbar mit EXECUTE für den tatsächlichen Remoteprincipal und gültige App-Policy EXECUTE_NEW_SESSION. Vorgesehener Pfad ist eine frische separate Session ohne aktive Callertransaktion. NONE verlangt exakt null SQL-Parameter am Handler. JSON_PAYLOAD verlangt exakt einen nicht-OUTPUT @PayloadJson nvarchar(max), außer kanonischer Event-Handler toolbelt.event-log.write -> toolbelt_core.USP_WriteEventInternal mit exakt zweitem @Hilfe bit; nur dort wird explizit Hilfe=0 gebunden. Keine allgemeine Freigabe zusätzlicher optionaler Parameter. Keine automatische Handler-/WorkType-/Policyanlage.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Registrierter Remote-WorkType in derselben Datenbank; NULL/nicht gefunden ergibt 51631, kein freier SQL-Text. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | NONE akzeptiert ausschließlich NULL; JSON_PAYLOAD erfordert nicht-NULL Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces. Höchstens 1048576 UTF-16-Bytes; konkrete Felder nach Handlervertrag, keine allgemeine JSON-Schema-Auswertung. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Gebundene nicht-NULL Ausführungs-ID vom autorisierten Transport; keine eigene Fallback-ID. Erforderlich außerhalb Hilfe. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Gebundene nicht-NULL Korrelations-ID vom Transport; kein eigener Kontextfallback. Erforderlich außerhalb Hilfe. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Autorisierung. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Tenant-Rechteerteilung. |
| `@RemoteSessionId` | `int` | `NULL` | INPUT/OUTPUT | OUTPUT wird im Fachpfad vor Validierung auf @@SPID gesetzt. Bei Hilfe bleibt bereits übergebener Wert unverändert. |
| `@HandlerReturnCode` | `int` | `NULL` | INPUT/OUTPUT | OUTPUT wird vor Fachvalidierung NULL, danach tatsächlicher Handler-Returncode. Nichtzero wird hier nicht automatisch als Fehler behandelt oder rollbackt. Hilfe lässt den Eingangswert unverändert. |
| `@StartedAtUtc` | `datetime2(7)` | `NULL` | INPUT/OUTPUT | OUTPUT wird vor Fachvalidierung SYSUTCDATETIME; damit Start der Dispatchbearbeitung, nicht ausschließlich Handlerzeit. Hilfe lässt Eingangswert unverändert. |
| `@CompletedAtUtc` | `datetime2(7)` | `NULL` | INPUT/OUTPUT | OUTPUT im Fachpfad zuerst NULL, nach Handler und COMMIT SYSUTCDATETIME, aber vor abschließendem Kontextcleanup. Bei späterem Fehler kann bereits ein Zeitpunkt gesetzt sein. Hilfe lässt Eingangswert unverändert. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Hilfe plus vollständige Skillzeile ohne Änderung irgendeines OUTPUT-Werts; 0/NULL: Fachpfad. |

## Ergebnisse

Kein fachliches SELECT-Resultset. Normale Kommunikation ausschließlich über vier optionale OUTPUT-Parameter und RETURN 0 nach erfolgreichem Dispatchabschluss. RemoteSessionId/HandlerReturnCode/StartedAtUtc/CompletedAtUtc siehe Parameter. Handler-Returncode ungleich 0 führt NICHT automatisch zu THROW oder ROLLBACK; fehlendes THROW des Handlers erlaubt den COMMITpfad. Diese Semantik nicht mit Dispatcher-Returncode verwechseln. Hilfe liefert zuerst die vorhandene zwölfspaltige Standardhilfe und genau eine zusätzliche vollständige Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); danach RETURN 0 vor fachlichen Prüfungen, Katalog-/Kontextlesen, RPC oder Mutation. SQL-Typbindung und ausdrücklich genannte lokale Initialisierung bleiben erhalten. Der Hilfezweig steht vor sämtlicher OUTPUT-Initialisierung, bestehende Werte bleiben unverändert.

## Aufrufbeispiele

```sql
-- Fachlichen Dispatch nur über die öffentliche Fassade aufrufen.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='contoso.noop';
-- Registrierter erlaubter NONE-Handler und konfigurierter Loopback nötig.
DECLARE @Spid int=123,@Code int=456,@Start datetime2(7)='2000-01-01',@End datetime2(7)='2000-01-02';
EXEC toolbelt_core.USP_DispatchWorkType @RemoteSessionId=@Spid OUTPUT,@HandlerReturnCode=@Code OUTPUT,@StartedAtUtc=@Start OUTPUT,@CompletedAtUtc=@End OUTPUT,@Hilfe=1;
-- Alle vier synthetischen Eingangswerte bleiben im Hilfemodus unverändert.
```

## Rechte

Bestehende Remote-EXECUTE-Rechte auf Dispatcher und Handler sowie lokale Katalog-/Kontext-/Ownershiprechte des Remoteprincipals. App-Policy EXECUTE_NEW_SESSION wird im tatsächlichen Remote-DBtoken mit DENY-Vorrang geprüft. Handler-EXECUTE wird durch HAS_PERMS_BY_NAME ausdrücklich geprüft. Benötigte sys.parameters/TYPE_NAME/Objektmetadaten müssen sichtbar sein. Keine Empfehlung direkter Consumergrants auf diesen internen Einstieg; Actor/Tenant ersetzen keine Rechte.

## Ressourcenbedarf

Payload maximal 1048576 UTF-16-Bytes, vollständige JSONobjektprüfung bei JSON_PAYLOAD; Felder nach Handlervertrag. Registrierung/PayloadContractJson wird hier nicht als JSON-Schema ausgeführt. Synchroner Handler und eigene Handlertransaktion, keine eigene CPU-/Heap-/Lock-/Wallclockgrenze und keine Durchsetzung von DefaultTimeoutSeconds/IsIdempotent. Handlerkosten können darüber hinausgehen; keine automatische Wiederholung oder Deduplikation.

## Nebenwirkungen

SET NOCOUNT ON,XACT_ABORT ON. Hilfe vor OUTPUT-Zuweisungen. Im Fachpfad RemoteSPID/Startzeit setzen, Handlercode/Endzeit NULL; danach Vorprüfungen. BeginExecution mit gebundenen IDs/Actor/Tenant und AllowNested=0, dann BEGIN TRANSACTION, gebundener Handleraufruf WITH RESULT SETS NONE, COMMIT ohne Prüfung auf Handlercode0, Endzeit und EndExecution. Kein fachlicher Handlerresultset zugelassen. Kontextcleanup kann nach Commit fehlschlagen; Fehler bedeutet dann nicht zwingend zurückgerollte Handlerwirkung. CATCH rollt bei XACT_STATE ungleich0 vollständig zurück, danach best-effort Kontextcleanup mit unterdrücktem sekundärem Cleanupfehler; Rollback selbst hat keinen zusätzlichen Schutz. Direktaufruf in einer fremden Callertransaktion ist kein sicherer Consumerpfad: BEGIN/COMMIT kann verschachtelt sein, CATCH kann den gesamten vorhandenen Scope rollbacken. Erfolgs-/Commitinterpretation setzt den vorgesehenen frischen Remote-/Handlervertrag voraus.

## Fehlerbehandlung

51630 fehlende ExecutionId/CorrelationId;51631 WorkType fehlt;51632 deaktiviert;51628 Payload>1MiB;51633 Payload bei NONE;51634 ungültiges JSONobjekt;51629 Remote-Policy fehlt;51635 Handler fehlt/unsichtbar;51636 Handler-EXECUTE fehlt;51637 NONE-Signatur nicht parameterlos;51638 JSON-Signatur falsch, in dieser tatsächlichen Priorität. Kontext-/Handler-/Enginefehler bleiben erhalten. Nichtzero HandlerReturnCode allein ist kein implementierter Fehler und kein Rollbackkriterium.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Skill-/Caller-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. IDs/Actor/Tenant und Quellnamen sind Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Ein Katalogeintrag/Probe/Returncode ist kein universeller Exactly-once-/Serveridentitäts-/Gesundheitsnachweis; reale Metadaten privat behandeln.
