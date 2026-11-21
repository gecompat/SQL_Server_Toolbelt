---
name: "toolbelt-core-workerregistration"
description: "Interne Workeridentität mit Generation, Principalbindung und gepinnten Intervallen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "WorkerRegistration"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_RegisterWorker", "toolbelt_core.USP_HeartbeatWorker", "toolbelt_core.USP_SetWorkerState", "toolbelt_core.VW_WorkerStatus"]
---

# WorkerRegistration

## Zweck und Einsatzfälle

Interne Workeridentität mit Generation, Principalbindung und gepinnten Intervallen. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.

## Voraussetzungen

Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.

## Parameter und Zugriff

Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `WorkerId` | `uniqueidentifier` | NOT NULL |
| `WorkerGeneration` | `bigint` | NOT NULL;>0 |
| `WorkerToken` | `uniqueidentifier` | NOT NULL; vertrauliches internes Token |
| `OwnerPrincipalId` | `int` | NOT NULL; gespeicherte Principal-ID, kein FK |
| `ProviderKind` | `varchar(16)` | NOT NULL; BIN2, keine CHECK-Wertemenge in der Tabelle |
| `State` | `varchar(16)` | NOT NULL; BIN2, ACTIVE/PAUSED/DRAINING/UNREACHABLE/CLOSED |
| `AdmissionPaused` | `bit` | NOT NULL |
| `Capacity` | `int` | NOT NULL;>0 |
| `RunMode` | `varchar(16)` | NOT NULL; BIN2, BOUNDED/CONTINUOUS |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NOT NULL |
| `HeartbeatSeconds` | `int` | NOT NULL; keine eigene Bereichsconstraint dieser Tabelle |
| `UnreachableSeconds` | `int` | NOT NULL; keine eigene Bereichsconstraint dieser Tabelle |

Zusammengesetzter Primärschlüssel WorkerId/WorkerGeneration. Keine weiteren Uniqueness-/FK-/Spaltendefaultregeln, insbesondere kein FK auf SQL-Principals und keine Eindeutigkeit des WorkerToken. Die Tabellenconstraints prüfen nur positive Generation/Kapazität und die genannten State-/RunMode-Mengen. ProviderKind, Heartbeatintervalle, LastHeartbeat, AdmissionPaused und Zustandszusammenhänge werden nicht durch zusätzliche CHECKs abgesichert. Ein gespeicherter OwnerPrincipalId ist allein keine dauerhafte Principalidentitätsattestation.

## Aufrufbeispiele

```sql
SELECT WorkerId,WorkerGeneration,State,Capacity,OccupiedSlots,ConfigVersion
FROM toolbelt_core.VW_WorkerStatus ORDER BY WorkerId,WorkerGeneration;
```

## Rechte

Keine direkten Tabellenrechte für normale Caller voraussetzen oder erteilen. Vorhandene EXECUTE-Rechte auf die benötigten öffentlichen Steuer-/Dispatchprozeduren und SELECT auf ihre Statusviews nutzen. Direkter Tabellenzugriff erfordert eigene vorhandene Rechte und wird durch diesen Skill nicht autorisiert.

## Ressourcenbedarf

Persistente Tabellen-/Historiengröße, Indizes, Join-/Zählplan und konkurrierende Sperren bestimmen Aufwand/Logwachstum. Keine implementierte Zeilen-/Byte-/CPU-/Heap-/Zeitquote dieser Relation. PK/Unique/FK unterstützen Zuordnung, garantieren keine bestimmte Laufzeit. Kein automatischer Retentions-/Purgeprozess durch Tabelle oder View; Sperr-, Log-, Speicher- und Timeoutfehler bleiben möglich.

## Nebenwirkungen

Engine wendet Schlüssel/FKs/CHECKs und rowversion bei tatsächlicher autorisierter Mutation an. Tabelle startet keine Handler, Heartbeats, Abbrüche, Reconciliation, Cleanup oder eigene Transaktionen. Initialisierung nur im jeweils bewachten CREATE-Pfad. Keine Statuszeile setzt selbständig einen SQL-Prozess fort.

## Fehlerbehandlung

Keine eigenen fachlichen Fehlercodes/Returnwerte der Tabelle. Ungültige Schlüssel/FKs/CHECKs/NOT-NULL oder fehlende Rechte ergeben Enginefehler. Constraints ersetzen keine Provider-/Transaktions-/Principal-/Proofprüfung.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recovery-/Clientmetadatenabnahme. Historische Fachnachweise behalten ihre eigene Artefakt- und Zielbindung. Status, Generation und Heartbeat allein beweisen weder erfolgreichen Handlercommit noch Rollback; UNKNOWN bleibt ungeklärt. Keine Exactly-once-, Kill-/Hostverlust- oder Vollqualifikationsbehauptung. Keine Installations-/Rechteattestation. IDs, Tokens, Principals und betriebliche Statusdaten privat behandeln.
