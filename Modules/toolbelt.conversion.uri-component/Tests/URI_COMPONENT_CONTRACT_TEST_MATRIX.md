# URI Component Contract-Testmatrix

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| RFC | vollständiger druckbarer ASCII-Raum, unreserved, reserved, Leerzeichen und `%HH` in Großbuchstaben | erfolgreich |
| Unicode | BMP, Supplementary Plane und UTF-8-Mehrbytefolgen | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Decode-Fehler | `%`, `%A`, `%G0`, unvollständige Sequenz, Overlong und NUL | erfolgreich |
| Sicherheit | `%252F` wird nur einmal decodiert | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Skalierung | synthetischer Large-Input-Roundtrip | erfolgreich |
| Lifecycle | Dependency, Erst-, Wiederholungs-, zentrale Nutzung, Kollision und Uninstall | Windows/Linux 2019/2022/2025: erfolgreich |

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; RFC-3986-ASCII-Raum, Unicode/UTF-8, ungültige Prozentsequenzen, synthetischer Large-Input-Roundtrip, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
