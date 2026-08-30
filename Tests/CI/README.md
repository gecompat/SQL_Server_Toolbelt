# CI-Testadapter

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Dieses Verzeichnis enthält schlanke Adapter für GitHub-hosted Testläufe. Die fachlichen SQL-Tests verbleiben in den jeweiligen Modulverzeichnissen.

`run-result-table-linux.sh` startet für den ResultTable-Vertrag einen offiziellen SQL-Server-Linux-Container, erzeugt ausschließlich synthetische Testdatenbanken und ruft die kanonischen Deploy-, Runtime- und Uninstall-Artefakte auf.

`run-base64-linux.sh` verwendet einen SQL-Server-2025-Linux-Container und
prüft den Base64-Vertrag seriell mit Compatibility Levels 150, 160 und 170
sowie lokale, zentrale und Lifecycle-Pfade.

`run-generate-series-linux.sh` verwendet einen SQL-Server-2025-Linux-
Container und prüft den portablen Ganzzahlreihenvertrag seriell mit
Compatibility Levels 150, 160 und 170 sowie lokale, zentrale und
Lifecycle-Pfade.

`run-date-spine-linux.sh` installiert Generate Series und Datetime Truncate
als explizite Dependencies und prüft danach Tages-, ISO-Wochen- und
Monatsspine einschließlich halboffener Grenzen, `DATEFIRST`-Unabhängigkeit,
Skalierung, fehlender Dependencies, Kollisionen, Wiederholungsdeployment,
Central-Aufruf und vollständigem Cleanup.

`run-work-queue-linux.sh` installiert ResultTable und Work Type als explizite
Dependencies und prüft den freigegebenen E1a-/E1b-Vertrag: Enqueue, atomaren Lease-Claim,
Heartbeat, explizite Recovery, Upgrade,
tokengebundenes Complete/Fail, Transaktionen, vier echte Claim-Sessions,
Statusschutz, Redeployment, Central, Datenverlustgate und vollständiges
Cleanup. Der Adapter startet, stoppt oder repariert keine Lab-Ressource.

Der Research-Adapter
`../Research/Regex/run-sqlserver-2025.sh` prüft ausschließlich auf SQL Server
2025 die native Regex-Semantik unter Compatibility 150, 160 und 170. Er wird
nicht in der Standardmodulmatrix ausgeführt, installiert kein Modul und
entfernt seine synthetische Datenbank vollständig.

`run-regex-linux.sh` prüft das daraus getrennt freigegebene R1b-Modul mit
dem exakten, reproduzierbar gebauten SAFE-CLR-Releaseartefakt. Der Adapter
deckt Dialekt, UTF-16-Positionen, Grenzen, festen Timeout, stabile
Fehlerpräfixe, Kollisionsschutz, Redeployment, Central und Uninstall ab.

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

Der Adapter `run-lab-target.sh` wird ausschließlich vom lokalen
SQL_Server_Lab-Orchestrator aktiviert. GitHub Actions und andere disposable
Runner führen ohne `TBX_SQL_TARGET=lab` weiterhin den unveränderten
Containerpfad aus. Der lokale Orchestrator führt keinen automatischen
Runner-Fallback durch.

Bash wird hier nur als Linux-CI-Orchestrierung verwendet. Es enthält keine zweite Implementierung der T-SQL-Fachlogik.

`run-q1-migration-idempotency.sh` führt den ersten eng begrenzten
Migration-Idempotency-Vertrag aus. Er deployt das dependency-freie T-SQL-Modul
`toolbelt.core.generate-series` in einer isolierten synthetischen Datenbank,
vergleicht den effektiven Katalog vor und nach dem Wiederholungsdeployment und
prüft ein zweimaliges Uninstall. Die Datenbank wird anschließend gezielt
entfernt; ein Lab-Ziel wird weder gestartet noch beendet.

Die Q1-Lab-Matrix war am 2026-08-29 auf SQL Server 2019, 2022 und 2025 jeweils
unter Linux und Windows erfolgreich. Der abstrahierte Nachweis umfasst
Wiederholungsdeployment, Kataloggleichheit, zwei unabhängige Uninstalls,
Restzustandsprüfung und Cleanup der synthetischen Testdatenbank.

## Lokaler Lab-Lauf aus PowerShell

Für die lokale Entwicklung kann die geeignete CI-Testmatrix gegen die vom
SQL_Server_Lab exportierten READY-Ziele gefahren werden. Voraussetzung sind
Git Bash, `sqlcmd` und ein erreichbares Lab-Netz.

Discovery-Reihenfolge:

1. Prozessvariable `SQL_SERVER_LAB_TEST_ENV_FILE`;
2. gleichnamige Benutzervariable;
3. `SQL_SERVER_LAB_DATA_ROOT` aus Prozess- oder Benutzervariable plus
   `Exports/TestUmgebung.json`.

`SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE` kann das standardmäßig danebenliegende
`TestUmgebung.schema.json` überschreiben. Der Vertrag wird vor jeder Verwendung
gegen dieses Schema validiert. Bei `groupStatus = READY` werden nur Einträge
mit `status = READY` verwendet. Der projektspezifische Override vom 2026-08-29
erlaubt bei `groupStatus = INCOMPLETE` außerdem explizit ausgewählte Einträge
mit `runtimeStatus = READY` und `status = READY` beziehungsweise
`GROUP_INCOMPLETE`. `groupStatus = EMPTY` sowie nicht einzeln bereite Ziele
bleiben ausgeschlossen. Diese engere Einzelzielfreigabe hat für dieses
Repository Vorrang vor einer widersprechenden gruppenweiten READY-Klausel in
einem über `SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE` bereitgestellten
Zusatzvertrag; dessen übrige Regeln sind weiterhin zu beachten. Laufwerks-,
Home- oder Repositorysuche sowie feste Lab-Pfade sind ausgeschlossen.

Beispielaufrufe:

```powershell
pwsh Tests/CI/run-lab-local.ps1
pwsh Tests/CI/run-lab-local.ps1 -Platforms linux -Versions 2019,2022,2025 -LinuxPatches latest -TestSuite full
pwsh Tests/CI/run-lab-local.ps1 -Platforms linux,windows -Versions 2019,2022,2025 -LinuxPatches latest -WindowsPatches base -TestSuite full
pwsh Tests/CI/run-lab-local.ps1 -RunScripts run-zip-memory-linux.sh
pwsh Tests/CI/run-lab-local.ps1 -RunScripts run-regex-linux.sh -RegexAssemblyRoot .runtime/regex-release
```

Die Matrix selektiert explizit nach `platform`, `sqlVersion` und `patch` und
verwendet alle nach dem obigen Gruppen- und Einzelzielvertrag zulässigen
Einträge. Fehlt ein Ziel oder ist sein eigener Runtime-Status nicht `READY`,
wird dieser Scope als nicht ausgeführt behandelt; ein Wechsel auf eine andere
Zielkombination findet nicht statt. Der Adapter startet oder repariert keine
Lab-Ressource.

Wichtige Anpassungen:

- Vor dem Test werden `SELECT @@VERSION` und der Zustand von
  `sys.databases` über eine echte SQL-Anmeldung geprüft.
- Für ZIP-Memory und Regex werden `TBX_ASSEMBLY_ROOT` und der jeweilige exakte
  Assembly-Hash aus den lokal gebauten Release-Artefakten gesetzt.
- Verbindungen verwenden ausschließlich Werte des ausgewählten Eintrags mit
  `Encrypt=True` und `TrustServerCertificate=True`; `Encrypt=Strict` wird nicht
  verwendet.
- Verändernde Tests erhalten eindeutige Datenbanknamen mit zufälliger
  Testlauf-ID. Der Adapter entfernt nur Datenbanken dieser ID. CLR-Adapter
  stellen zusätzlich nur die von ihrem Lauf geänderte CLR-/Trust-Konfiguration
  wieder auf den vorherigen Zustand zurück.
- Der Dateicontent-Lauf gehört nicht zur Standardmatrix, weil seine
  serverseitigen Dateien zuerst explizit in jedem Ziel bereitgestellt werden
  müssen.

Das Testkennwort:

- wird je Lauf zufällig erzeugt;
- wird in GitHub Actions maskiert;
- wird nicht in Dateien oder Artefakten gespeichert;
- ist kein Repository-Secret.

Ein vorhandener Adapter oder Workflow ist kein Runtime-Nachweis. Nur eine tatsächlich erfolgreich abgeschlossene Action erzeugt Evidenz.

## Evidenz

Der [aktuelle GitHub Actions Run 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) war am 2026-07-29 für den statischen Vertrag sowie die vollständige Suite auf SQL Server 2019, 2022 und 2025 unter GitHub-hosted Linux erfolgreich. Der Scope umfasst vier parallele echte Sitzungen mit identischen logischen lokalen Temp-Tabellennamen. Die früheren Läufe und verbleibenden Grenzen stehen in der ResultTable-Testmatrix.

Der [GitHub Actions Run 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) war am 2026-08-01 für SQL Server 2019, 2022 und 2025 unter Linux erfolgreich und ergänzt den natürlichen Enginefehler 2705 nach begonnener Mutation einschließlich vollständigem Savepoint-Rollback von Schema und Daten.

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
