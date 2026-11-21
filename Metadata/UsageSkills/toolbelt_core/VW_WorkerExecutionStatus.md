---
name: "toolbelt-core-vw-workerexecutionstatus"
description: "Öffentliche tokenfreie Reservationshistorie mit exakt passender aktueller Hold-Disposition."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "VW_WorkerExecutionStatus"
object_type: "VIEW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.core.worker-control/Source/VW_WorkerExecutionStatus.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# VW_WorkerExecutionStatus

## Zweck und Einsatzfälle

Öffentliche tokenfreie Reservationshistorie mit exakt passender aktueller Hold-Disposition. Vorgesehener Leseweg ohne Tokens/Payloads; Statusdaten sind keine Ausführungsautorität.

## Voraussetzungen

Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.

## Parameter und Zugriff

Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. SELECT mit eigenen Filtern/ORDER BY, zentral bei vorhandenem DBmapping auch dreiteilig über die Toolbelt-Datenbank. Es werden die gespeicherten Objekte der Viewdatenbank gelesen, nicht automatisch die aufrufende Datenbank. Reihenfolge nur mit eigenem ORDER BY. SQL-Typen unten sind quellgeprüft; eine neue native Client-Nullabilityabnahme wird nicht behauptet.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `SlotReservationId` | `uniqueidentifier` | Identität der Reservation |
| `WorkItemId` | `bigint` | Zugehöriger Queueauftrag |
| `ClaimGeneration` | `bigint` | Gespeicherte Claimgeneration |
| `ExecutionId` | `uniqueidentifier` | Gespeicherte Executionidentität |
| `WorkerId` | `uniqueidentifier` | Zugehöriger Worker |
| `WorkerGeneration` | `bigint` | Zugehörige Worker-generation |
| `State` | `varchar(24)` | BIN2; Zustand dieser Reservation |
| `IsHeld` | `bit` | Exakt passende Disposition, sonst0 |
| `HoldVersion` | `binary(8)` | Exakt passende Disposition, sonst NULL |
| `StopStatus` | `varchar(24)` | Passende Disposition; sonst ALREADY_COMMITTED bei Reservationsstatus COMMITTED, andernfalls NONE |

LEFT JOIN aller Reservations auf Disposition nach WorkItemId UND SlotReservationId. Kein State-/Owner-/Principalfilter. Historische Reservations bleiben sichtbar; eine Disposition für eine andere Reservation desselben Items wird nicht übernommen. Ohne passenden Join: IsHeld0,HoldVersion NULL,StopStatus ALREADY_COMMITTED bei r.State COMMITTED, sonst NONE. Diese Fallbacks beweisen weder nie vorhandenen Hold/Stop noch eine autorisierte Freigabe. Mit passendem Join stammen alle drei Dispositionsfelder aus der Tabelle; ein dortiges NONE bleibt auch bei COMMITTED NONE. IsOccupied, Worker-/Claimtoken, AttemptNonce, BoundPrincipalId, Witness und Payload fehlen. Keine eigene Verifikation des Witness, tatsächlichen SQL-Commits oder fachlichen Erfolgs durch den SELECT.

## Aufrufbeispiele

```sql
SELECT SlotReservationId,WorkItemId,ClaimGeneration,State,IsHeld,HoldVersion,StopStatus
FROM toolbelt_core.VW_WorkerExecutionStatus ORDER BY WorkItemId,ClaimGeneration;
```

## Rechte

SELECT auf diese View; bei zentralem Aufruf zusätzlich bestehender Datenbankzugriff/Identitätsmapping. Keine Rechtevergabe oder automatische Sichtbarkeits-/Ownerfilterung. Lesen ist nicht mit getrennten Steuer-, Dispatch- oder internen Tabellenrechten gleichzusetzen.

## Ressourcenbedarf

Persistente Tabellen-/Historiengröße, Indizes, Join-/Zählplan und konkurrierende Sperren bestimmen Aufwand/Logwachstum. Keine implementierte Zeilen-/Byte-/CPU-/Heap-/Zeitquote dieser Relation. PK/Unique/FK unterstützen Zuordnung, garantieren keine bestimmte Laufzeit. Kein automatischer Retentions-/Purgeprozess durch Tabelle oder View; Sperr-, Log-, Speicher- und Timeoutfehler bleiben möglich.

## Nebenwirkungen

Reines SELECT ohne Mutation, Statuswechsel, Heartbeat, Stop, Holdfreigabe, Recovery, eigene Transaktionen oder Sessionkonfiguration. Ein vorgesehener Leseweg ist keine zusätzliche SQL-DML-Sicherheitsschranke: vorhandene UPDATE-Rechte und die SQL-Viewregeln bestimmen mögliche andere Operationen; keine solchen Rechte aus dem Skill ableiten.

## Fehlerbehandlung

Keine eigenen THROW-/Validierungscodes oder Sentinelzeilen. Keine passenden Datensätze ergibt leere Ausgabe. Fehlende Rechte/Abhängigkeiten und technische Abfragefehler bleiben SQL-Enginefehler; Statusfallbacks sind normale Daten, keine Fehlerbehebung.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recovery-/Clientmetadatenabnahme. Historische Fachnachweise behalten ihre eigene Artefakt- und Zielbindung. Status, Generation und Heartbeat allein beweisen weder erfolgreichen Handlercommit noch Rollback; UNKNOWN bleibt ungeklärt. Keine Exactly-once-, Kill-/Hostverlust- oder Vollqualifikationsbehauptung. Keine Installations-/Rechteattestation. IDs, Tokens, Principals und betriebliche Statusdaten privat behandeln.
