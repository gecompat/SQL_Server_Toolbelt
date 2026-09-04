# Test Evidence

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Die Contract- und Lifecycle-Tests verwenden ausschließlich synthetischen URI-Text.

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-07-30 | [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) | SQL Server 2025 Linux; Compatibility 150/160/170; RFC 3986, Unicode, striktes UTF-8, Fehler, Einmal-Decoding, SVF-/TVF-Parität, Wiederholungsdeployment, zentrale Nutzung und Uninstall | `success` | LOB-/Performancegrenzen sowie physische 2019-/2022- und Windows-Läufe bleiben `not executed` |
| 2026-08-29 | lokales SQL_Server_Lab | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | LOB-/Performancegrenzen und Windows-Läufe bleiben `not executed` |

Der Modulstatus ist `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; RFC-3986-ASCII-Raum, Unicode/UTF-8, ungültige Prozentsequenzen, synthetischer Large-Input-Roundtrip, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
