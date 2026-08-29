# Directional TRIM Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| Position | `LEADING`, `TRAILING`, `BOTH`, leerer Zeichensatz | Richtungen erfolgreich; leerer Zeichensatz `not executed` |
| Literalität | `%`, `_`, `[`, `]` und doppelte Zeichen | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Datentypen | `varchar`, `nvarchar`, `NULL`, `NCHAR(0)` | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Collation | CI, CS, BIN2 und UTF-8-varchar | CS erfolgreich; weitere Collations `not executed` |
| Parität | SQL Server 2022/2025 bei Compatibility 160/170 | SQL Server 2025 Linux, Compatibility 160/170: erfolgreich |
| Lifecycle | Erst-, Wiederholungs-, zentrale Nutzung und Uninstall | SQL Server 2025 Linux: erfolgreich; Kollision `not executed` |

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399).
