---
name: "toolbelt-core-usp-enqueueworkwithpolicy"
description: "Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_EnqueueWorkWithPolicy"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{\"value\":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder."}, {"name": "@IdempotencyKey", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. SQL-BIN2 ohne zusätzlichen Längenvergleich ist keine Byteidentitätsgarantie; SQL-Spacepadding beachten."}, {"name": "@Priority", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints."}, {"name": "@ExecutionGroup", "sql_type": "varchar(128)", "sql_default": "'default'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default."}, {"name": "@MaxAttempts", "sql_type": "tinyint", "sql_default": "3", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints."}, {"name": "@RetryBaseDelaySeconds", "sql_type": "int", "sql_default": "60", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss <= RetryMaxDelaySeconds sein. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints."}, {"name": "@RetryMaxDelaySeconds", "sql_type": "int", "sql_default": "3600", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints."}, {"name": "@ExecutionMode", "sql_type": "varchar(16)", "sql_default": "'SHARED'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_EnqueueWorkWithPolicy

## Zweck und Einsatzfälle

Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.

## Voraussetzungen

Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. DRAIN_BARRIER verlangt@@TRANCOUNT0; SHARED unterstützt gesunden Caller-TX/Savepoint. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. SQL-BIN2 ohne zusätzlichen Längenvergleich ist keine Byteidentitätsgarantie; SQL-Spacepadding beachten. |
| `@Priority` | `tinyint` | `0` | Input | Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@ExecutionGroup` | `varchar(128)` | `'default'` | Input | Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss <= RetryMaxDelaySeconds sein. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@ExecutionMode` | `varchar(16)` | `'SHARED'` | Input | Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig. NichtNULL ist der zulässige fachliche Vertrag; der Code hat nicht für jeden dieser Werte einen vollständigen NULL-Frühguard. Bei vorhandenem IdempotencyKey kann UNKNOWN den Differenzvergleich umgehen; bei neuem Item wirken Tabellenconstraints. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WasCreated` | `bit` | 1 neu angelegt,0 bestehendes Idempotency-Item wiederverwendet |
| `WorkItemId` | `bigint` | NOT NULL; IDENTITY(1,1), geclusterter Primärschlüssel |
| `WorkTypeName` | `varchar(128)` | WorkType-Katalogname, BIN2 |
| `Status` | `varchar(16)` | NOT NULL; BIN2, Default QUEUED |
| `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL; Default SYSUTCDATETIME() |
| `EnqueuedBy` | `sysname` | NOT NULL; Default ORIGINAL_LOGIN() |
| `ClaimedAtUtc` | `datetime2(7)` | NULL |
| `ClaimedBy` | `sysname` | NULL |
| `CompletedAtUtc` | `datetime2(7)` | NULL |
| `CompletedBy` | `sysname` | NULL |
| `FailedAtUtc` | `datetime2(7)` | NULL |
| `FailedBy` | `sysname` | NULL |
| `FailureCode` | `varchar(64)` | NULL; BIN2 |
| `FailureMessage` | `nvarchar(1000)` | NULL |
| `RowVersion` | `binary(8)` | Konvertierter WorkItem-Rowversionwert, keine Zeitangabe |
| `ClaimGeneration` | `bigint` | NOT NULL; Default0 |
| `LeaseDurationSeconds` | `int` | NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
| `IsLeaseExpired` | `bit` | 1 genau bei Status CLAIMED und LeaseUntilUtc<=SYSUTCDATETIME(), sonst0 |
| `RecoveryCount` | `bigint` | NOT NULL; Default0 |
| `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
| `LastRecoveredBy` | `sysname` | NULL |
| `ExecutionGroup` | `varchar(128)` | NOT NULL; BIN2, Default default |
| `Priority` | `tinyint` | NOT NULL; Default0 |
| `ExecutionMode` | `varchar(16)` | NOT NULL; BIN2, Default SHARED |
| `MaxAttempts` | `tinyint` | NOT NULL; Default3 |
| `RetryBaseDelaySeconds` | `int` | NOT NULL; Default60 |
| `RetryMaxDelaySeconds` | `int` | NOT NULL; Default3600 |
| `RetryCycleNumber` | `bigint` | NOT NULL; Default1 |
| `CycleAttemptCount` | `bigint` | NOT NULL; Default0 |
| `NextAttemptAtUtc` | `datetime2(7)` | NULL |
| `LastErrorCode` | `varchar(64)` | NULL; BIN2 |
| `LastErrorMessage` | `nvarchar(1000)` | NULL |
| `LastRetryScheduledAtUtc` | `datetime2(7)` | NULL |
| `LastRetryScheduledBy` | `sysname` | NULL |
| `DeadLetteredAtUtc` | `datetime2(7)` | NULL |
| `DeadLetteredBy` | `sysname` | NULL |
| `LastRequeuedAtUtc` | `datetime2(7)` | NULL |
| `LastRequeuedBy` | `sysname` | NULL |
| `LastRequeueReason` | `nvarchar(1000)` | NULL |
| `BarrierEpoch` | `bigint` | NOT NULL; Default0 |

42 Spalten: WasCreated und die41 VW_WorkQueue-Spalten. Direkte Ausgabe nach eigenem Commit ist live und kein materialisierter Entscheidungsreceipt; ResultTable materialisiert innerhalb der Transaktion. Payload,ClaimToken,IdempotencyKey und private Managedtokens fehlen absichtlich. ResultTableNULL:direkter Fachresultset; sonst kompatibles lokales #Ziel über PrepareResultTable und kein zusätzlicher direkter Fachresultset. Hilfe: bisherige zwölfspaltige Standardhilfe plus genau eine vier-spaltige Skillzeile (SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)); RETURN0 vor Fachzugriff. Normaler Ablauf endet ohne eigenes explizites RETURN (implizite0).

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;

-- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='contoso.noop',@IdempotencyKey='contoso.request.1',
 @ExecutionGroup='contoso.group',@Priority=10,@ExecutionMode='SHARED',
 @MaxAttempts=3,@RetryBaseDelaySeconds=60,@RetryMaxDelaySeconds=3600;
-- Gleicher Key wird nur mit tatsächlich gleicher Policy wiederverwendet.
```

## Rechte

Vorhandenes EXECUTE auf den gewählten öffentlichen Einstieg und erforderlicher Datenbankzugriff/Identitätsmapping. Keine neuen Rechte aus diesem Skill ableiten. TVF_WorkTypeAuthorization prüft ENQUEUE im tatsächlichen Aufruferkontext. Einfaches Enqueue benötigt Handler-Metadatensicht; Policy/Barrier prüfen sie nicht. Handler-EXECUTE ist hier nicht Voraussetzung, bleibt aber im Claim-/Ausführungspfad separat nötig. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten; ResultTable braucht bereits zulässige lokale #Tabelle und vorhandene Helper-/Temp-DDL-/INSERT-Rechte. Keine Serverrolle pauschal erforderlich.

## Ressourcenbedarf

Aufwand abhängig von Queue-,Policy-,Idempotency- und Barrierblockerumfang sowie Sperrkonkurrenz. Private tempdb-Ergebnisobjekte und optionales Callerziel; DRAIN_BARRIER benötigt Scheduler-/Itemlocks und kann viele Blockergenerationen speichern. Kein eigener CPU-/Heap-/Log-/Gesamtlaufzeit-/Ergebnisbyte-Limiter, keine automatische Wiederholung. Nur Payload ist auf65536Bytes begrenzt; das ist keine gesamte Laufzeit- oder Ausgabegarantie.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF vor früher Hilfe. Die Policyvariante prüft WorkType/Gruppe, Wertebereiche, Barrier-Caller-TX-Verbot und Payloadbreite. Eigener TX bei@@TRANCOUNT0, sonst Savepoint TBX_WorkQueue_EnqueuePolicy. ResultTable wird bereits vor WorkTypeprüfung vorbereitet. WorkType UPDLOCK/HOLDLOCK, aktiv und ENQUEUE erlaubt; ParameterMode NONE verlangtNULL, JSON_PAYLOAD verlangt JSON-Objekt. Anders als einfaches Enqueue keine OBJECT_ID-/Handler-EXECUTE-Prüfung. Bei DRAIN_BARRIER SchedulerId1 mit UPDLOCK/HOLDLOCK lesen; kein eigener Existenzguard dieser Seedzeile.

NichtNULL IdempotencyKey wird unter UPDLOCK/HOLDLOCK je WorkType gesucht. Bestehendes Item: Payload und alle übergebenen Policyfelder nach den tatsächlichen SQL-Vergleichen vergleichen; Abweichung51972, sonst WasCreated0 und bestehendes Item unverändert zurückgeben, auch im Terminalstatus. Vergleich ist kein Byteidentitätsnachweis: BIN2-Vergleiche ohne DATALENGTH können SQL-Spacepadding enthalten, NULL-Payload wird für diesen Vergleich zu leerem Text. Explizite NULL-Policywerte werden nicht durch vollständige ISNULL-Guards abgefangen; beim Neuanlegen wirken NOT-NULL-/CHECK-Constraints, bei vorhandenem Item können UNKNOWN-Vergleiche einzelne Abweichungen nicht erkennen. Deshalb kanonische vollständige nichtNULL-Policywerte verwenden. Kein fachlicher Exactly-once-Beweis.

Fehlt das Item: INSERT mit fester Itempolicy, RetryCycle1,Attempt0,BarrierEpoch0/1 und StatusQUEUED beziehungsweiseBARRIER_WAIT. Barrier erfasst bereitsCLAIMED Items derselben Gruppe mit ihrer ClaimGeneration, außer DRAIN_BARRIER mit gleicher Priority. Nur historische Blockergenerationen, kein Handleraufruf und kein Abbruch laufender Arbeit. ResultTable-Zeile wird vor eigenem Commit materialisiert/geroutet. Eigener TX wird committed, Caller-TX bleibt offen; CATCH eigener Rollback beziehungsweise gesunder Savepointrollback. Direkter SELECT WasCreated,*VW_WorkQueue erst nach eigenem Commit: live Sicht, kein materialisierter Entscheidungsreceipt. Konkurrenz kann Status inzwischen ändern. Kein eigener normaler expliziter RETURN; implizite0 allein beweist keine Handlerwirkung.

## Fehlerbehandlung

51965 Name/GruppeNULL/leer;51966 Wertebereich/Modus ungültig nach SQL-Vergleichen;51997 Barrier mitCallerTX;51967 Payload>65536Bytes;51969 WorkType fehlt/deaktiviert;51998 ENQUEUE verboten;51970 Payload beiNONE;51971 ungültiger JSON_PAYLOAD;51972 abweichende Arbeit beiIdempotencyKey;51908 ResultTablehelper fehlt. Explizite NULL-Policy kann wegen UNKNOWN erst an Tabellenconstraints scheitern oder bei Wiederverwendung unerkannt bleiben; keine vollständige NULL-Frühvalidierung behaupten. Ursprüngliche Engine-,Constraint-,Helper-,Temp-/Lock-/Deadlock-/Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung; eigene bereits committete Arbeit wird durch einen späteren Ergebnistransportfehler nicht zurückgenommen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Idempotency-/Konkurrenzabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Kein Exactly-once, Handler-/Hoststart, automatische Recovery oder fremde Claimübernahme. Standard-Statusfelder enthalten Namen/Zeit-/Fehlerdaten; vertrauliche Eingaben/Runtimebefunde nicht öffentlich loggen. Kein Redaktions-/Secretfilter. Erfolgsreturn/WasCreated/Status allein attestieren keine tatsächliche Handlerwirkung oder Installation/Rechte.
