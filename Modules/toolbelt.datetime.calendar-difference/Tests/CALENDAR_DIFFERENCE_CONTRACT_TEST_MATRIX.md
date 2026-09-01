# Calendar Difference Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| Grundvertrag | gleiche, vorwärts- und rückwärtsgerichtete Daten | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Anniversary | Monatsende, 28./29. Februar und Schaltjahr | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Grenzen | `0001-01-01`, `9999-12-31`, `NULL` | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Mengenaufruf | `OUTER APPLY` über mehrere Paare | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Lifecycle | Erst-, Wiederholungs-, zentrale Nutzung und Uninstall | SQL Server 2025 Linux: erfolgreich; Kollision `not executed` |

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger W1-Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
