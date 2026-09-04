# Test Evidence

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Die Contract- und Lifecycle-Tests verwenden ausschließlich synthetische `date`-Werte.

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-07-30 | [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) | SQL Server 2025 Linux; Compatibility 150/160/170; Anniversary, Grenzwerte, NULL, APPLY, Wiederholungsdeployment, zentrale Nutzung und Uninstall | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |
| 2026-08-29 | lokales SQL_Server_Lab | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe bleiben `not executed` |

Der Modulstatus ist `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
