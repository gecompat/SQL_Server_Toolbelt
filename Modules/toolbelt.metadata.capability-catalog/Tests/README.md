# Tests – Module Capability Catalog

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Alle zusätzlichen Extended Properties verwenden synthetische Modul-IDs und
werden im Runtime-Contract wieder entfernt.

`ModuleCapabilities.Contract.sql` prüft gültige, unvollständige, ungültige,
falsch typisierte, falsch geschriebene und nicht datenbankweite Marker.
`Lifecycle.Contract.sql` und `Central.Contract.sql` prüfen Objektart,
Modulmarker und dreiteilige Nutzung.

Aktueller Runtime-Status: `validated`.

[W2c-Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich.

Der vollständige Adapter ist seit 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Windows-Läufe und
eingeschränkte Metadata-Visibility bleiben getrennte Pflichtprüfungen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; lokales und zentrales Deployment, eingeschränkte Metadatensichtbarkeit ohne Rechteausweitung, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
