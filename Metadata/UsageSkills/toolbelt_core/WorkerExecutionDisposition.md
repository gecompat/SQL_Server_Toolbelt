---
name: "toolbelt-core-workerexecutiondisposition"
description: "Interne aktuelle Hold-/Stop-Disposition je Queueauftrag."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "WorkerExecutionDisposition"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_StopWorkerExecution", "toolbelt_core.USP_ReleaseHeldWork", "toolbelt_core.USP_ReconcileWorkerExecution", "toolbelt_core.VW_WorkerExecutionStatus"]
---

# WorkerExecutionDisposition

## Zweck und Einsatzfälle

Interne aktuelle Hold-/Stop-Disposition je Queueauftrag. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.

## Voraussetzungen

Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.

## Parameter und Zugriff

Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL; Primärschlüssel und FK auf WorkItem |
| `SlotReservationId` | `uniqueidentifier` | NOT NULL; FK auf WorkerSlotReservation |
| `IsHeld` | `bit` | NOT NULL |
| `StopStatus` | `varchar(24)` | NOT NULL; BIN2, NONE/REQUESTED/STOPPING/ROLLED_BACK_HELD/ALREADY_COMMITTED/UNKNOWN |
| `HoldVersion` | `rowversion` | NOT NULL; enginegeneriertes Concurrencytoken |

Primärschlüssel WorkItemId erlaubt höchstens eine aktuelle Disposition pro Item. Separate FKs auf WorkItem und Reservation garantieren deren Existenz, nicht die Übereinstimmung des WorkItemId der Reservation; keine zusammengesetzte Kohärenzconstraint. Keine Spaltendefaults außer automatisch erzeugter rowversion. StopStatus-Wertemenge ist begrenzt, aber ihre Konsistenz mit IsHeld/Reservationszustand ist keine Tabellen-CHECK-Regel. HoldVersion ist ein Concurrencywert, keine Zeitangabe oder Freigabeautorität.

## Aufrufbeispiele

```sql
SELECT SlotReservationId,WorkItemId,ClaimGeneration,State,IsHeld,HoldVersion,StopStatus
FROM toolbelt_core.VW_WorkerExecutionStatus ORDER BY WorkItemId,ClaimGeneration;
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
