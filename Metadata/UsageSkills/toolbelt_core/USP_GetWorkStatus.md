---
name: "toolbelt-core-usp-getworkstatus"
description: "Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_GetWorkStatus"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Liest Status; Payload und ClaimToken sind absichtlich nicht Teil dieser Oberfläche."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_GetWorkStatus.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_GetWorkStatus

## Zweck und Einsatzfälle

Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt.

## Voraussetzungen

Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächliches existierendes Item; kein aktiver/registrierter Handler für reine Statuslesung erforderlich. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Liest Status; Payload und ClaimToken sind absichtlich nicht Teil dieser Oberfläche. |
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
EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;

-- Synthetische ID durch die eigene tatsächliche Enqueue-/Claim-ID ersetzen.
EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=1;
-- Statuslesung liefert weder Payload noch ClaimToken.
```

## Rechte

Vorhandenes EXECUTE auf den gewählten öffentlichen Einstieg und erforderlicher Datenbankzugriff/Identitätsmapping. Keine neuen Rechte aus diesem Skill ableiten. Statuslesen hat keinen eigenen WorkType-Policy-/Owner-/ClaimTokenfilter; nicht als Mandantentrennung oder Besitznachweis verwenden. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten; ResultTable braucht bereits zulässige lokale #Tabelle und vorhandene Helper-/Temp-DDL-/INSERT-Rechte. Keine Serverrolle pauschal erforderlich.

## Ressourcenbedarf

Aufwand abhängig von Queue-,Policy-,Idempotency- und Barrierblockerumfang sowie Sperrkonkurrenz. Private tempdb-Ergebnisobjekte und optionales Callerziel; DRAIN_BARRIER benötigt Scheduler-/Itemlocks und kann viele Blockergenerationen speichern. Kein eigener CPU-/Heap-/Log-/Gesamtlaufzeit-/Ergebnisbyte-Limiter, keine automatische Wiederholung. Nur Payload ist auf65536Bytes begrenzt; das ist keine gesamte Laufzeit- oder Ausgabegarantie.

## Nebenwirkungen

NOCOUNT ON;KeepData/Debug/HilfeNULL→0, keine eigene XACT_ABORT-Zuweisung. Frühe Hilfe, dann positive ID verlangen. Ein SELECT kopiert die22 angegebenen VW_WorkQueue-Spalten in eine private lokale Ergebnistabelle; fehlt die Zeile51931. Kein WorkType-Aktivitäts-,ENQUEUE-,CLAIM-,Handler-,Callerowner- oder ClaimToken-Guard. Optionales ResultTable anschließend vorbereiten/füllen; keine eigene Transaktion/kein Savepoint/kein CATCH. Caller-TX und XACT_ABORT bestimmen deshalb Fehlerwirkung; keine eigene atomare Rollbackgarantie für Helper-/Zieländerungen. Debug>0 Severity10 NOWAIT, direkte Ausgabe nur ohne Ziel. RETURN0. Kein Leaseheartbeat,Recovery oder Statusübergang.

## Fehlerbehandlung

51930 IDNULL/nichtpositiv;51931 Item über VW_WorkQueue nicht vorhanden;51934 ResultTablehelper fehlt. Keine eigene Fehlerumschreibung/Transaktionsreparatur. Ursprüngliche Engine-,Constraint-,Helper-,Temp-/Lock-/Deadlock-/Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung; eigene bereits committete Arbeit wird durch einen späteren Ergebnistransportfehler nicht zurückgenommen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Idempotency-/Konkurrenzabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Kein Exactly-once, Handler-/Hoststart, automatische Recovery oder fremde Claimübernahme. Standard-Statusfelder enthalten Namen/Zeit-/Fehlerdaten; vertrauliche Eingaben/Runtimebefunde nicht öffentlich loggen. Kein Redaktions-/Secretfilter. Erfolgsreturn/WasCreated/Status allein attestieren keine tatsächliche Handlerwirkung oder Installation/Rechte.
