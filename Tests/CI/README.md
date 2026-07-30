# CI-Testadapter

Dieses Verzeichnis enthält schlanke Adapter für GitHub-hosted Testläufe. Die fachlichen SQL-Tests verbleiben in den jeweiligen Modulverzeichnissen.

`run-result-table-linux.sh` startet für den ResultTable-Vertrag einen offiziellen SQL-Server-Linux-Container, erzeugt ausschließlich synthetische Testdatenbanken und ruft die kanonischen Deploy-, Runtime- und Uninstall-Artefakte auf.

`run-base64-linux.sh` verwendet einen SQL-Server-2025-Linux-Container und
prüft den Base64-Vertrag seriell mit Compatibility Levels 150, 160 und 170
sowie lokale, zentrale und Lifecycle-Pfade.

`run-generate-series-linux.sh` verwendet einen SQL-Server-2025-Linux-
Container und prüft den portablen Ganzzahlreihenvertrag seriell mit
Compatibility Levels 150, 160 und 170 sowie lokale, zentrale und
Lifecycle-Pfade.

`run-identifier-linux.sh` prüft den Identifier-Vertrag mit denselben
Compatibility Levels sowie lokale, zentrale, Kollisions- und Lifecycle-Pfade.

`run-split-characters-linux.sh` installiert zuerst den Generate-Series-Kern
und prüft danach den literalen Multi-Separator-Vertrag mit denselben
Compatibility Levels, fehlender Dependency, lokaler und zentraler Nutzung,
Kollision, Wiederholungsdeployment und Uninstall.

`run-semantic-version-linux.sh` prüft Parser, Comparator, Sort Key sowie
lokale, zentrale, Kollisions- und Lifecycle-Pfade bei Compatibility Levels
150, 160 und 170.

`run-integer-base-linux.sh` prüft Alphabete von Basis 2 bis 93,
Kanonizität, den vollständigen `bigint`-Bereich, Overflow sowie lokale,
zentrale, Kollisions- und Lifecycle-Pfade bei denselben Compatibility Levels.

`run-zip-memory-linux.sh` installiert zuerst `toolbelt.core.result-table` als
Dependency und prueft danach den In-memory-ZIP-Vertrag fuer
`toolbelt.archive.zip-memory` mit Compatibility Levels 150, 160 und 170 sowie
lokale, zentrale, Lifecycle- und Uninstall-Pfade.

Bash wird hier nur als Linux-CI-Orchestrierung verwendet. Es enthält keine zweite Implementierung der T-SQL-Fachlogik.

Das Testkennwort:

- wird je Lauf zufällig erzeugt;
- wird in GitHub Actions maskiert;
- wird nicht in Dateien oder Artefakten gespeichert;
- ist kein Repository-Secret.

Ein vorhandener Adapter oder Workflow ist kein Runtime-Nachweis. Nur eine tatsächlich erfolgreich abgeschlossene Action erzeugt Evidenz.

## Evidenz

Der [aktuelle GitHub Actions Run 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) war am 2026-07-29 für den statischen Vertrag sowie die vollständige Suite auf SQL Server 2019, 2022 und 2025 unter GitHub-hosted Linux erfolgreich. Der Scope umfasst vier parallele echte Sitzungen mit identischen logischen lokalen Temp-Tabellennamen. Die früheren Läufe und verbleibenden Grenzen stehen in der ResultTable-Testmatrix.

Der
[Base64-Runtime-Lauf 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`.

Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`.

Der
[Identifier-Runtime-Lauf 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`.

Der
[Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`.

Der
[Semantic-Version Runtime Run 30517137373](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`.

Der
[Integer-Base Runtime Run 30518087070](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30518087070)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`.

## Quellen

- Microsoft (2026): [Offizielle SQL-Server-Linux-Container und Tags](https://mcr.microsoft.com/product/mssql/server/about).
- GitHub (2026): [GitHub-hosted runners](https://docs.github.com/actions/using-github-hosted-runners/about-github-hosted-runners).
- Microsoft (2026): [SQLCMD-Scripting-Variablen und Priorität](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-use-scripting-variables?view=sql-server-ver17).
