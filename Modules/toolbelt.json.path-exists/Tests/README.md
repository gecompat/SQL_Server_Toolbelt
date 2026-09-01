# Tests JSON Path Exists

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

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
Uninstall erfolgreich. Der vollständige Adapter ist seit 2026-08-29
zusätzlich auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen
erfolgreich. Windows-Läufe bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
