# Date-Spine-Contract-Testmatrix

| Bereich | Pflichtfälle |
|---|---|
| API | Drei öffentliche und eine interne Inline TVF; Parameter-, Spalten-, Typ- und Nullabilityvertrag. |
| Grenzen | Halboffener Bereich, partielle Randperioden, leer, umgekehrt und `NULL`. |
| Tag | Monats-/Jahreswechsel, Schaltjahr, minimale und maximale darstellbare Grenzen. |
| ISO-Woche | Montag, ISO-Jahreswechsel und Unabhängigkeit von `DATEFIRST`. |
| Monat | Kurze/lange Monate, Schaltjahr und partielle Monate. |
| Größe | Mindestens 100.000 Tagesperioden; nullbasierte lückenlose Ordinals. |
| Dependencies | Fehlende oder falsche Generate-Series-/Truncate-Version vor erster Mutation ablehnen. |
| Lifecycle | Erstinstallation, Wiederholungsdeployment, Kollision, Marker, Uninstall und Dependency-Schutz. |
| Deployment | Lokal, zentral und dreiteiliger Cross-database-Aufruf. |
| Collation | Case-insensitive, case-sensitive und BIN2 über lokale und zentrale Testdatenbanken. |
| Plattform | SQL Server 2019/2022/2025 jeweils Windows und Linux. |

Nur tatsächlich ausgeführte Kombinationen bilden Runtime-Evidenz.

Evidenz 2026-08-30: `local: Tests/CI/run-lab-local.ps1` war für den vollständigen
Linux-Scope auf SQL Server 2019, 2022 und 2025 erfolgreich. Windows blieb nach
fehlgeschlagenem SQL-Anmeldungs-Preflight `not executed`.
