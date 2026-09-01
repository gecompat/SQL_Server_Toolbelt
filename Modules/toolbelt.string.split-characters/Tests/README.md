# Tests für `toolbelt.string.split-characters`

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Status

Runtime: `partially validated`.

Der
[Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich.

## Artefakte

- `Static/validate_contract.py` prüft Source-, Manifest-, Deployment-,
  Workflow- und Dokumentkopplung.
- `Runtime/SplitCharacters.Contract.sql` prüft Signatur, Semantik, Collation,
  LOB, `CROSS APPLY` und das enge SQL-Server-2025-Oracle.
- `Runtime/Lifecycle.Contract.sql` prüft Marker, Source-Hash und Dependency.
- `Runtime/Central.Contract.sql` prüft den dreiteiligen zentralen Aufruf.
- `../../../Tests/CI/run-split-characters-linux.sh` orchestriert synthetische
  Datenbanken, Compatibility Levels 150/160/170, Wiederholungsdeployment,
  fehlende Dependency, Kollision und Uninstall.

Der vollständige Adapter ist seit 2026-08-29 auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Windows-Läufe
bleiben Releaseaufgaben.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
