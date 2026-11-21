---
name: "toolbelt-core-usp-enqueuework"
description: "Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_EnqueueWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser einfache Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{\"value\":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_EnqueueWork

## Zweck und Einsatzfälle

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

## Voraussetzungen

Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser einfache Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL |
| `WorkTypeName` | `varchar(128)` | NOT NULL |
| `Status` | `varchar(16)` | NOT NULL |
| `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL |
| `EnqueuedBy` | `sysname` | NOT NULL |
| `ClaimedAtUtc` | `datetime2(7)` | NULL |
| `ClaimedBy` | `sysname` | NULL |
| `CompletedAtUtc` | `datetime2(7)` | NULL |
| `CompletedBy` | `sysname` | NULL |
| `FailedAtUtc` | `datetime2(7)` | NULL |
| `FailedBy` | `sysname` | NULL |
| `FailureCode` | `varchar(64)` | NULL |
| `FailureMessage` | `nvarchar(1000)` | NULL |
| `RowVersion` | `binary(8)` | NOT NULL |
| `ClaimGeneration` | `bigint` | NOT NULL |
| `LeaseDurationSeconds` | `int` | NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
| `IsLeaseExpired` | `bit` | NOT NULL |
| `RecoveryCount` | `bigint` | NOT NULL |
| `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
| `LastRecoveredBy` | `sysname` | NULL |

22 feste Statusspalten, nicht alle41 VW_WorkQueue-Felder. Genau eine Zeile bei erfolgreichem Aufruf, vor Ausgabe in eigener #Temp materialisiert. Payload,ClaimToken,IdempotencyKey und private Managedtokens fehlen absichtlich. ResultTableNULL:direkter Fachresultset; sonst kompatibles lokales #Ziel über PrepareResultTable und kein zusätzlicher direkter Fachresultset. Hilfe: bisherige zwölfspaltige Standardhilfe plus genau eine vier-spaltige Skillzeile (SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)); RETURN0 vor Fachzugriff. Normaler Erfolgsreturn0.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;

-- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='contoso.noop';
-- Erneuter Aufruf erzeugt ein weiteres Item, keine Idempotency-Replaygarantie.
```

## Rechte

Vorhandenes EXECUTE auf den gewählten öffentlichen Einstieg und erforderlicher Datenbankzugriff/Identitätsmapping. Keine neuen Rechte aus diesem Skill ableiten. TVF_WorkTypeAuthorization prüft ENQUEUE im tatsächlichen Aufruferkontext. Einfaches Enqueue benötigt Handler-Metadatensicht; Policy/Barrier prüfen sie nicht. Handler-EXECUTE ist hier nicht Voraussetzung, bleibt aber im Claim-/Ausführungspfad separat nötig. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten; ResultTable braucht bereits zulässige lokale #Tabelle und vorhandene Helper-/Temp-DDL-/INSERT-Rechte. Keine Serverrolle pauschal erforderlich.

## Ressourcenbedarf

Aufwand abhängig von Queue-,Policy-,Idempotency- und Barrierblockerumfang sowie Sperrkonkurrenz. Private tempdb-Ergebnisobjekte und optionales Callerziel; DRAIN_BARRIER benötigt Scheduler-/Itemlocks und kann viele Blockergenerationen speichern. Kein eigener CPU-/Heap-/Log-/Gesamtlaufzeit-/Ergebnisbyte-Limiter, keine automatische Wiederholung. Nur Payload ist auf65536Bytes begrenzt; das ist keine gesamte Laufzeit- oder Ausgabegarantie.

## Nebenwirkungen

NOCOUNT ON,XACT_ABORT OFF;KeepData/Debug/HilfeNULL→0. Frühe Hilfe vor Fachargumenten. Pflichtname,65536Byte-Payloadgrenze und doomed Caller werden geprüft. Eigener TX oder gesunder Savepoint TBX_WorkQueue_Enqueue. WorkType UPDLOCK/HOLDLOCK: registriert,aktiv,Handler als P/PC durch OBJECT_ID sichtbar und ENQUEUE-Policy erlaubt; kein Handler-EXECUTE-Test oder Aufruf. NONE verlangtNULL, JSON_PAYLOAD ein JSON-Objekt. Optionales ResultTable wird vor INSERT vorbereitet. INSERT nur WorkTypeId/PayloadJson; übrige Werte kommen aus kanonischen WorkItem-Defaults: QUEUED,Gruppe default,Priority0,SHARED,MaxAttempts3,Base60,Cap3600,Cycle1,Attempt0,Epoch0,IdempotencyKeyNULL. Jeder erfolgreiche Aufruf legt neu an.22-Spalten-Ergebnis vor Commit kopieren/optional routen. Nur eigener TX commit; CATCH eigener Rollback oder committable Savepointrollback. Debug>0 Severity10 NOWAIT nach Commit, danach direkterSELECT nur ohne Ziel. Ein späterer Transport-/Messagefehler nimmt eigenen Commit nicht zurück. RETURN0.

## Fehlerbehandlung

51900 Name fehlt oder WorkType nicht registriert;51901 deaktiviert;51902 Handler P/PC nicht sichtbar/verfügbar;51998 ENQUEUE verboten;51903 Payload beiNONE;51904 ungültiger JSON_PAYLOAD;51905 Payload>65536Bytes;51906 doomedCaller;51908 ResultTablehelper fehlt. Ursprüngliche Engine-,Constraint-,Helper-,Temp-/Lock-/Deadlock-/Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung; eigene bereits committete Arbeit wird durch einen späteren Ergebnistransportfehler nicht zurückgenommen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Idempotency-/Konkurrenzabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Kein Exactly-once, Handler-/Hoststart, automatische Recovery oder fremde Claimübernahme. Standard-Statusfelder enthalten Namen/Zeit-/Fehlerdaten; vertrauliche Eingaben/Runtimebefunde nicht öffentlich loggen. Kein Redaktions-/Secretfilter. Erfolgsreturn/WasCreated/Status allein attestieren keine tatsächliche Handlerwirkung oder Installation/Rechte.
