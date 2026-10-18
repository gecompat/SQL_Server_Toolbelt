# Tests für `toolbelt.string.split-characters`

Nachqualifikation 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Runtime: `validated`; Release: `unreleased`. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Status

Runtime: `validated`.

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
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019/2022/2025 unter Windows mit freigegebenen CU-Äquivalenten zu base und Linux latest; vollständiger lokaler/zentraler Moduladapter, versionsabhängige CL150/160/170, Lifecycle und Uninstall; Security-Grenzen, atomare Limitfälle, Minimalrechte und zentrale Status-API
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
