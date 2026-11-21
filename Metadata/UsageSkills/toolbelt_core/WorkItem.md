---
name: "toolbelt-core-workitem"
description: "Interner persistenter Queueauftrag mit Claim-, Retry-, Barrier- und Managedmetadaten."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "WorkItem"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql"]
review_status: "verified"
source_module_version: "2.1.0"
public_entrypoints: ["toolbelt_core.VW_WorkQueue", "toolbelt_core.USP_EnqueueWorkWithPolicy", "toolbelt_core.USP_ClaimWork", "toolbelt_core.USP_GetWorkStatus"]
---

# WorkItem

## Zweck und Einsatzfälle

Interner persistenter Queueauftrag mit Claim-, Retry-, Barrier- und Managedmetadaten. Internes Objekt; passende öffentliche Einstiege siehe Frontmatter, kein direkter fachlicher DML-Vertrag.

## Voraussetzungen

SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.

## Parameter und Zugriff

Keine Aufrufparameter. Die46 Spalten sind der Endzustand nach Scheduling-/Managed-Ergänzungen; Defaultwerte sind Spaltenregeln, keine Prozedurargumente. Lesen über VW_WorkQueue/USP_GetWorkStatus; Änderungen ausschließlich über autorisierte öffentliche Queue-/Workerabläufe, keine direkte DML als fachliche API.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL; IDENTITY(1,1), geclusterter Primärschlüssel |
| `WorkTypeId` | `bigint` | NOT NULL; FK WorkType.WorkTypeId |
| `PayloadJson` | `nvarchar(max)` | NULL; JSON-Objekt, höchstens65536 Bytes |
| `Status` | `varchar(16)` | NOT NULL; BIN2, Default QUEUED |
| `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL; Default SYSUTCDATETIME() |
| `EnqueuedBy` | `sysname` | NOT NULL; Default ORIGINAL_LOGIN() |
| `ClaimedAtUtc` | `datetime2(7)` | NULL |
| `ClaimedBy` | `sysname` | NULL |
| `ClaimToken` | `uniqueidentifier` | NULL; vertrauliches Claimtoken |
| `ClaimGeneration` | `bigint` | NOT NULL; Default0 |
| `LeaseDurationSeconds` | `int` | NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
| `RecoveryCount` | `bigint` | NOT NULL; Default0 |
| `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
| `LastRecoveredBy` | `sysname` | NULL |
| `CompletedAtUtc` | `datetime2(7)` | NULL |
| `CompletedBy` | `sysname` | NULL |
| `FailedAtUtc` | `datetime2(7)` | NULL |
| `FailedBy` | `sysname` | NULL |
| `FailureCode` | `varchar(64)` | NULL; BIN2 |
| `FailureMessage` | `nvarchar(1000)` | NULL |
| `RowVersion` | `rowversion` | NOT NULL; Engine-Concurrencywert |
| `ExecutionGroup` | `varchar(128)` | NOT NULL; BIN2, Default default |
| `Priority` | `tinyint` | NOT NULL; Default0 |
| `ExecutionMode` | `varchar(16)` | NOT NULL; BIN2, Default SHARED |
| `IdempotencyKey` | `varchar(128)` | NULL; BIN2 |
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
| `ManagedReservationId` | `uniqueidentifier` | NULL |
| `ManagedHold` | `bit` | NOT NULL; Default0 |
| `ManagedCompletionNonce` | `uniqueidentifier` | NULL |

Zulässige Statuswerte QUEUED,BARRIER_WAIT,CLAIMED,RETRY_WAIT,COMPLETED,FAILED,DEAD_LETTER. Der endgültige CK_WorkItem_StateMetadata prüft ebenfalls nur diese Statusmenge; die frühere Vierzustandsprüfung der Claim-/Abschlussmetadaten wird entfernt. Daher beweisen Tabellenconstraints keine vollständige Status-/Lease-/Tokenkonsistenz. Payload NULL oder ISJSON=1, führende Objektklammer nach LTRIM und DATALENGTH<=65536. FailureCode NULL oder1..64, beginnt mit ASCII-Buchstabe und enthält nur A-Z/a-z/0-9/._-. RecoveryCount0 verlangt leere Recoverymetadaten; positiver Wert verlangt Zeitpunkt/Principal, negative Werte unzulässig. Policyconstraint: ExecutionGroup<>leer nach SQL-Vergleich, Modus SHARED/DRAIN_BARRIER, Attempts1..10, RetryBase1..86400, RetryMax>=Base und<=86400, RetryCycle>=1,CycleAttempt>=0,BarrierEpoch>=0. Keine zusätzliche Tabellenprüfung der API-spezifischen ASCII-/Gruppennamensyntax, Claimgeneration oder aller Fehlerfelder. IdempotencyKey ist je WorkType bei Nicht-NULL per gefiltertem Uniqueindex eindeutig, auch für terminale erhaltene Zeilen; SQL-BIN2-Vergleiche sind keine allgemeine längensensitive Byteidentität. Drei Status-/Leaseindizes und Schedulingindex unterstützen öffentliche Abläufe. Kein Tabellen-Retentionjob oder automatischer Leaseablauf.

## Aufrufbeispiele

```sql
SELECT WorkItemId,WorkTypeName,Status,IsLeaseExpired
FROM toolbelt_core.VW_WorkQueue ORDER BY WorkItemId;
```

## Rechte

Keine direkten Tabellenrechte für reguläre Caller voraussetzen oder erteilen; bestehende EXECUTE-Rechte auf die benötigten öffentlichen Prozeduren und gegebenenfalls SELECT auf ihre öffentlichen Views nutzen. Direkter SELECT/DML auf der Tabelle benötigt eigene vorhandene Rechte und wird durch diesen Skill nicht autorisiert.

## Ressourcenbedarf

Persistente Queuegröße, Indizes, Join-/Filterplan und konkurrierende Sperren bestimmen den Aufwand. Keine implementierte Maximalzeilen-, Byte-, CPU-, Speicher- oder Laufzeitquote dieser Relation. Begrenzte Feldtypen schützen keine unbegrenzte Auftragsanzahl; kein automatischer Retentions-/Purgeauftrag. Sperren, Log-/tempdb-/Speicherdruck und Timeouts bleiben möglich.

## Nebenwirkungen

Speicherung, Defaults, Constraints und Indizes wirken bei tatsächlicher autorisierter Mutation; ein SELECT verändert die Tabelle nicht. Keine selbstlaufende Wiederherstellung, kein Handleraufruf, keine externe Transaktion und keine eigene Ausführungsidentität. Die Tabellen-DDL hat Initialisierungs-/historische Migrationszweige, ist kein frei aufzurufender Fach-API-Einstieg.

## Fehlerbehandlung

Keine fachlichen Rückgabe-/Fehlercodes oder Sentinelzeilen dieser Tabelle. Engine meldet verletzte Schlüssel/FKs/CHECKs/NOT-NULL und fehlende Rechte; diese Fehler ersetzen nicht die Validierung und Recovery der öffentlichen Prozeduren.

## Aussagegrenzen

Quellgeprüfter Objektvertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recoveryabnahme. Historische unveränderte Fachbelege behalten ausschließlich ihre ursprüngliche Bindung. Kein Exactly-once-, Atomizitäts- oder vollständiger Worker-Recoverynachweis allein durch gespeicherte Statuswerte. Personen-/Payload-/Fehlerdaten privat behandeln; keine Installation, Rechte oder gesunde Gesamtkonfiguration attestieren.
