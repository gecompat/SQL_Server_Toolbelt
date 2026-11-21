---
name: "toolbelt-core-vw-workerstatus"
description: "Öffentliche tokenfreie Statusprojektion aller registrierten Worker-generationen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "VW_WorkerStatus"
object_type: "VIEW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.core.worker-control/Source/VW_WorkerStatus.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# VW_WorkerStatus

## Zweck und Einsatzfälle

Öffentliche tokenfreie Statusprojektion aller registrierten Worker-generationen. Vorgesehener Leseweg ohne Tokens/Payloads; Statusdaten sind keine Ausführungsautorität.

## Voraussetzungen

Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.

## Parameter und Zugriff

Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. SELECT mit eigenen Filtern/ORDER BY, zentral bei vorhandenem DBmapping auch dreiteilig über die Toolbelt-Datenbank. Es werden die gespeicherten Objekte der Viewdatenbank gelesen, nicht automatisch die aufrufende Datenbank. Reihenfolge nur mit eigenem ORDER BY. SQL-Typen unten sind quellgeprüft; eine neue native Client-Nullabilityabnahme wird nicht behauptet.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `WorkerId` | `uniqueidentifier` | WorkerRegistration.WorkerId |
| `WorkerGeneration` | `bigint` | WorkerRegistration.WorkerGeneration |
| `ProviderKind` | `varchar(16)` | BIN2; gespeicherter Providerkind |
| `State` | `varchar(16)` | BIN2; gespeicherter Workerzustand, keine dynamische Unerreichbarkeitsberechnung |
| `Capacity` | `int` | Gespeicherte lokale Kapazität |
| `RunMode` | `varchar(16)` | BIN2; gespeicherter Runmode |
| `LastHeartbeatAtUtc` | `datetime2(7)` | Gespeicherte Heartbeatzeit |
| `OccupiedSlots` | `bigint` | COUNT_BIG der Reservations mit gleicher WorkerId/Generation und IsOccupied=1, ISNULL-Fallback0 |
| `ConfigVersion` | `binary(8)` | Aktuelle globale Konfigurations-rowversion, ISNULL-Fallback acht Nullbytes |
| `HeartbeatSeconds` | `int` | In WorkerRegistration gespeicherter Intervallwert |
| `UnreachableSeconds` | `int` | In WorkerRegistration gespeicherter Intervallwert |

CROSS JOIN WorkerRegistration mit WorkerControlConfiguration und Filter ConfigurationId=1. Eine fehlende Konfigurationszeile blendet alle Worker aus; der ConfigVersion-ISNULL-Fallback erzeugt keine fehlende Zeile. Kein Filter auf ACTIVE, Principal/Owner, ProviderKind oder RunMode. OccupiedSlots zählt ausschließlich IsOccupied=1 für dieselbe WorkerId/Generation, unabhängig von State; ungeklärte Reservations können damit weiter zählen. Keine Begrenzung des ausgegebenen Zählers auf Capacity oder globale Konfiguration. ConfigVersion stammt aus aktueller globaler Konfiguration; die ausgegebenen Intervalle stammen dagegen aus der Workerregistration. State wird nicht durch NOW/fehlenden Heartbeat automatisch umgerechnet. WorkerToken, OwnerPrincipalId, AdmissionPaused, ClaimToken und AttemptNonce fehlen.

## Aufrufbeispiele

```sql
SELECT WorkerId,WorkerGeneration,State,Capacity,OccupiedSlots,ConfigVersion
FROM toolbelt_core.VW_WorkerStatus ORDER BY WorkerId,WorkerGeneration;
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
