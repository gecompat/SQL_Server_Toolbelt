# Contract-Testmatrix: Module Capability Catalog

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Pflichtfall | Status |
|---|---|---|
| API | View-Typ und vier Spalten | `success` – Run 30573135975 |
| gültig | kanonische Modulmarker | `success` – Run 30573135975 |
| unvollständig | fehlender Version- oder Mode-Marker sichtbar | `success` – Run 30573135975 |
| ungültig | Version, Modus, Datentyp und Schreibweise | `success` – Run 30573135975 |
| Scope | Object-level Extended Property wird ignoriert | `success` – Run 30573135975 |
| Collation | CS-, CI- und BIN2-Datenbankpfade | `success` – Run 30573135975 |
| Read-only | keine Registry und keine Mutation durch die View | `success` – Run 30573135975 |
| Metadata Visibility | eingeschränkter Principal ohne `VIEW DEFINITION`; keine Rechteausweitung | `success` – lokaler Lauf 2026-09-01 |
| Lifecycle | Erstinstallation, Wiederholung, Central, Uninstall | `success` – Run 30573135975 |
| Matrix | SQL Server 2025 Linux, Compatibility 150/160/170 | `success` – [Run 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975) |
| Release | physische SQL Server 2019/2022/2025 unter Windows base und Linux latest | `success` – lokaler Lauf 2026-09-01 |

Physische SQL-Server-2019-/2022- und Windows-Läufe sowie eingeschränkte
Metadata-Visibility bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; lokales und zentrales Deployment, eingeschränkte Metadatensichtbarkeit ohne Rechteausweitung, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
