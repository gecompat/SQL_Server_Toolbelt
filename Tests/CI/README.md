# CI-Testadapter

Dieses Verzeichnis enthält schlanke Adapter für GitHub-hosted Testläufe. Die fachlichen SQL-Tests verbleiben in den jeweiligen Modulverzeichnissen.

`run-result-table-linux.sh` startet für den ResultTable-Vertrag einen offiziellen SQL-Server-Linux-Container, erzeugt ausschließlich synthetische Testdatenbanken und ruft die kanonischen Deploy-, Runtime- und Uninstall-Artefakte auf.

Bash wird hier nur als Linux-CI-Orchestrierung verwendet. Es enthält keine zweite Implementierung der T-SQL-Fachlogik.

Das Testkennwort:

- wird je Lauf zufällig erzeugt;
- wird in GitHub Actions maskiert;
- wird nicht in Dateien oder Artefakten gespeichert;
- ist kein Repository-Secret.

Ein vorhandener Adapter oder Workflow ist kein Runtime-Nachweis. Nur eine tatsächlich erfolgreich abgeschlossene Action erzeugt Evidenz.

## Evidenz

Der [erweiterte GitHub Actions Run 30456207934](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30456207934) war am 2026-07-29 für den statischen Vertrag sowie die vollständige vorhandene Suite auf SQL Server 2019, 2022 und 2025 unter GitHub-hosted Linux erfolgreich. Der genaue Scope, der frühere Basislauf und die verbleibenden Grenzen stehen in der ResultTable-Testmatrix.

## Quellen

- Microsoft (2026): [Offizielle SQL-Server-Linux-Container und Tags](https://mcr.microsoft.com/product/mssql/server/about).
- GitHub (2026): [GitHub-hosted runners](https://docs.github.com/actions/using-github-hosted-runners/about-github-hosted-runners).
- Microsoft (2026): [SQLCMD-Scripting-Variablen und Priorität](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-use-scripting-variables?view=sql-server-ver17).
