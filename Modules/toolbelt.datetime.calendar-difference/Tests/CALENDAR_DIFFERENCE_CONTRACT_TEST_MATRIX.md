# Calendar Difference Contract-Testmatrix

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| Grundvertrag | gleiche, vorwärts- und rückwärtsgerichtete Daten | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Anniversary | Monatsende, 28./29. Februar und Schaltjahr | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Grenzen | `0001-01-01`, `9999-12-31`, `NULL` | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Mengenaufruf | `OUTER APPLY` über mehrere Paare | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Lifecycle | Erst-, Wiederholungs-, zentrale Nutzung, Kollision und Uninstall | Windows/Linux 2019/2022/2025: erfolgreich |

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
