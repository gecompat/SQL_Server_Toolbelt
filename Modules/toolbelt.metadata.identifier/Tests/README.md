# Tests für `toolbelt.metadata.identifier`

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

`Identifier.Contract.sql` prüft den öffentlichen Parser- und Quote-Vertrag.
`Lifecycle.Contract.sql` prüft Marker, Objekttypen und interne Dependency.
`Central.Contract.sql` prüft dreiteilige Aufrufe aus einer getrennten
synthetischen Konsumentendatenbank.

Der
[Identifier-Runtime-Lauf 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Der vollständige Adapter ist seit 2026-08-29 zusätzlich auf
physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich.
Windows-Läufe bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
