---
name: "toolbelt-core-workercontrolconfiguration"
description: "Interne Einzeilenkonfiguration der Managed-Worker-Admission."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "WorkerControlConfiguration"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_SetWorkerConcurrency", "toolbelt_core.USP_SetWorkerIntervals", "toolbelt_core.VW_WorkerStatus"]
---

# WorkerControlConfiguration

## Zweck und Einsatzfälle

Interne Einzeilenkonfiguration der Managed-Worker-Admission. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.

## Voraussetzungen

Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.

## Parameter und Zugriff

Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `ConfigurationId` | `tinyint` | NOT NULL; Primärschlüssel und CHECK=1 |
| `MaxConcurrentExecutions` | `int` | NOT NULL; >=0 |
| `HeartbeatSeconds` | `int` | NOT NULL;1..3600 |
| `UnreachableSeconds` | `int` | NOT NULL;3..86400 und>=3*HeartbeatSeconds |
| `ConfigVersion` | `rowversion` | NOT NULL; enginegeneriert |

Neuanlage initialisiert ConfigurationId1,MaxConcurrentExecutions1,HeartbeatSeconds15,UnreachableSeconds60. Das sind einmalige Seedwerte, keine Spaltendefaults; nur ConfigVersion wird automatisch von der Engine erzeugt. PK/CHECK erlauben höchstens eine Zeile, erzwingen ihre Existenz nicht. 0 ist für MaxConcurrentExecutions zulässig; kein kleineres positives Maximum ist in der Tabelle festgelegt. Bestehende leere Tabelle wird durch den CREATE-Guard nicht erneut initialisiert.

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
