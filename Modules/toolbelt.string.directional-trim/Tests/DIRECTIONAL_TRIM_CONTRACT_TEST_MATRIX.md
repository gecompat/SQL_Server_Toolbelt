# Directional TRIM Contract-Testmatrix

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| Position | `LEADING`, `TRAILING`, `BOTH`, leerer Zeichensatz | erfolgreich |
| Literalität | `%`, `_`, `[`, `]` und doppelte Zeichen | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Datentypen | `varchar`, `nvarchar`, `NULL`, `NCHAR(0)` | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Collation | CI, CS, BIN2 und UTF-8-varchar | erfolgreich |
| Parität | SQL Server 2022/2025 bei Compatibility 160/170 | SQL Server 2025 Linux, Compatibility 160/170: erfolgreich |
| Lifecycle | Erst-, Wiederholungs-, zentrale Nutzung, Kollision und Uninstall | Windows/Linux 2019/2022/2025: erfolgreich |

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; lokales und zentrales Deployment, CI-/CS-/UTF-8-Collations, leere Trim-Menge, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
