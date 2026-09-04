# Semantic-Version Contract-Testmatrix

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Fälle | Stand |
|---|---|---|
| Parser | Core, Pre-release, Build, Canonical | vorhanden |
| Ungültig | `NULL`, leer, Präfix, Leading Zero, leere Identifier | vorhanden |
| Präzedenz | offizielle SemVer-Folge, ASCII, Build ignoriert | vorhanden |
| Größe | 2.000-stellige Core-Komponente ohne Overflow | vorhanden |
| Sort Key | gleiche Reihenfolge wie Comparator | vorhanden |
| API-Parität | SVF und inline TVF, exakt eine Zeile, `OUTER APPLY` | vorhanden |
| Upgrade | `1.0.0` auf `1.1.0`, Wiederholung, Kollision | vorhanden |
| Lifecycle | lokal, zentral, Drift, Kollision, Uninstall | vorhanden |
| SQL Server 2025 Linux 150/160/170 | Version `1.1.0` | `success` |
| SQL Server 2019/2022/2025 unter Windows base und Linux latest | Release-Matrix | erfolgreich |

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
