---
name: "toolbelt-core-workqueuescheduler"
description: "Interne Einzeilen-Koordinationsrelation für Queue-Scheduling."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "WorkQueueScheduler"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "2.1.0"
public_entrypoints: ["toolbelt_core.USP_EnqueueWorkWithPolicy", "toolbelt_core.USP_ClaimWork", "toolbelt_core.USP_RequeueDeadLetter"]
---

# WorkQueueScheduler

## Zweck und Einsatzfälle

Interne Einzeilen-Koordinationsrelation für Queue-Scheduling. Internes Objekt; passende öffentliche Einstiege siehe Frontmatter, kein direkter fachlicher DML-Vertrag.

## Voraussetzungen

SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.

## Parameter und Zugriff

Keine Aufrufparameter. Eine frisch erzeugte Tabelle wird mit SchedulerId=1 initialisiert. CHECK und Schlüssel erlauben höchstens diese eine Zeile, erzwingen aber nicht deren Existenz. Keine eigene Fachlese-/Schreib-API; öffentliche Queueabläufe verwenden den Koordinationsdatensatz.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `SchedulerId` | `tinyint` | NOT NULL; Primärschlüssel und CHECK SchedulerId=1; kein Spaltendefault |

Keine Auftragsdaten und kein eigener Schedulerprozess. Der Datensatz ist ein Koordinationsanker, keine Zeit-/Claim-/Heartbeatinformation. Nicht löschen, sperren oder eigenständig neu anlegen. Eine vorhandene leere Tabelle wird durch den CREATE-Guard nicht erneut initialisiert.

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
