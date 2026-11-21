---
name: "toolbelt-core-workqueuebarrierblocker"
description: "Interner Snapshot der zu einer Barrier-Epoch erfassten Blocker-Claimgenerationen."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "WorkQueueBarrierBlocker"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "2.1.0"
public_entrypoints: ["toolbelt_core.VW_WorkQueueBarrierBlockers", "toolbelt_core.USP_EnqueueBarrierWork", "toolbelt_core.USP_RequeueDeadLetter"]
---

# WorkQueueBarrierBlocker

## Zweck und Einsatzfälle

Interner Snapshot der zu einer Barrier-Epoch erfassten Blocker-Claimgenerationen. Internes Objekt; passende öffentliche Einstiege siehe Frontmatter, kein direkter fachlicher DML-Vertrag.

## Voraussetzungen

SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.

## Parameter und Zugriff

Keine Aufrufparameter. Lesen über VW_WorkQueueBarrierBlockers; Snapshotmutation über öffentliche Barrier-/Queueabläufe. Zusammengesetzter Primärschlüssel über BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration. Zwei FKs auf WorkItem ohne ON DELETE CASCADE.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `BarrierWorkItemId` | `bigint` | NOT NULL; FK WorkItem, Barrierauftrag |
| `BarrierEpoch` | `bigint` | NOT NULL; Snapshotepoch |
| `BlockingWorkItemId` | `bigint` | NOT NULL; FK WorkItem, Blockerauftrag |
| `BlockingClaimGeneration` | `bigint` | NOT NULL; erfasste Claimgeneration |
| `CapturedAtUtc` | `datetime2(7)` | NOT NULL; Default SYSUTCDATETIME() |

Ein Eintrag hält eine erfasste Claimgeneration fest, keinen geheimen ClaimToken und keine Payload. Fremdschlüssel sichern Existenz, nicht Status, Modus, Gruppenbeziehung oder positive Epoch-/Generationswerte. Kein automatisches Löschen durch die Tabelle oder allein durch Ablauf einer Lease; öffentliche Abläufe bestimmen die Lebensdauer.

## Aufrufbeispiele

```sql
SELECT BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration,IsResolved
FROM toolbelt_core.VW_WorkQueueBarrierBlockers
ORDER BY BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId;
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
