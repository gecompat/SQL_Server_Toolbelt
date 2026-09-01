# URI Component Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| RFC | unreserved, reserved, Leerzeichen und `%HH` in Großbuchstaben | Kernfälle erfolgreich; vollständige Zeichentabelle `not executed` |
| Unicode | BMP, Supplementary Plane und UTF-8-Mehrbytefolgen | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Decode-Fehler | `%`, `%G0`, unvollständige Sequenz, Overlong und NUL | `%G0`, Overlong und NUL erfolgreich; übrige Fälle `not executed` |
| Sicherheit | `%252F` wird nur einmal decodiert | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Lifecycle | Dependency, Erst-, Wiederholungs-, zentrale Nutzung und Uninstall | SQL Server 2025 Linux: erfolgreich; Kollision `not executed` |

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger W1-Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
