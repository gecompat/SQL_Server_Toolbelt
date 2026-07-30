# Tests JSON Path Exists

`JsonPathExists.Contract.sql` prüft Pfad-, JSON-, NULL-, Wildcard-,
Collation- und native Paritätsfälle. `Lifecycle.Contract.sql` prüft
Objektart und Modulmarker; `Central.Contract.sql` prüft den dreiteiligen
Aufruf.

Geplanter CI-Scope:

- SQL Server 2025 Linux;
- Compatibility Levels 150, 160 und 170;
- wiederholtes Deployment;
- lokaler und zentraler Aufruf;
- Uninstall.

Aktuelle Evidenz:
[Run 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943)
– SQL Server 2025 Linux mit Compatibility Levels 150/160/170 einschließlich
Runtime, nativer Parität, Wiederholungsdeployment, Lifecycle, Central und
Uninstall erfolgreich. Physische 2019-/2022- und Windows-Läufe bleiben
`not executed`.
