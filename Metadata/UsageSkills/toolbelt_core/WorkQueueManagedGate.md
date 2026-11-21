---
name: "toolbelt-core-workqueuemanagedgate"
description: "Interne neutrale Queue-Koordination für Managed-Admission und Reservierung."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "WorkQueueManagedGate"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql"]
review_status: "verified"
source_module_version: "2.1.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWork", "toolbelt_core.USP_EnableManagedWorkers", "toolbelt_core.USP_DisableManagedWorkers"]
---

# WorkQueueManagedGate

## Zweck und Einsatzfälle

Interne neutrale Queue-Koordination für Managed-Admission und Reservierung. Internes Objekt; passende öffentliche Einstiege siehe Frontmatter, kein direkter fachlicher DML-Vertrag.

## Voraussetzungen

SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.

## Parameter und Zugriff

Keine Aufrufparameter. Neu angelegte Tabelle wird einmal mit GateId1,ManagedEnabled0,AdmissionToken NEWID(),PendingReservationId NULL initialisiert. Dies sind Seedwerte, keine Spaltendefaults. CHECK/PK erlauben höchstens eine Gatezeile und erzwingen ihre Existenz nicht. Kein direkter Tabellenzugriff als fachliche API.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `GateId` | `tinyint` | NOT NULL; Primärschlüssel und CHECK GateId=1 |
| `ManagedEnabled` | `bit` | NOT NULL; kein Spaltendefault |
| `AdmissionToken` | `uniqueidentifier` | NOT NULL; kein Spaltendefault, technisches internes Token |
| `PendingReservationId` | `uniqueidentifier` | NULL; kein Spaltendefault |

Keine FK- oder weitergehende Reservierungs-/Tokenkonsistenzconstraint in dieser Relation. Ein Gate ist weder eigener Worker noch Sicherheitsprincipal. Öffentliche Managed-Steuerung benötigt zusätzlich den installierten Worker-Control-Provider und dessen Rechte; dessen Verfügbarkeit wird durch diese Tabelle nicht behauptet. Dieselbe Source ergänzt WorkItem um drei Managedfelder, aber das ist kein Schreibweg für Caller.

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
