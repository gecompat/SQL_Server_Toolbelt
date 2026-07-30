# URI Component Contract-Testmatrix

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| RFC | unreserved, reserved, Leerzeichen und `%HH` in Großbuchstaben | Kernfälle erfolgreich; vollständige Zeichentabelle `not executed` |
| Unicode | BMP, Supplementary Plane und UTF-8-Mehrbytefolgen | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Decode-Fehler | `%`, `%G0`, unvollständige Sequenz, Overlong und NUL | `%G0`, Overlong und NUL erfolgreich; übrige Fälle `not executed` |
| Sicherheit | `%252F` wird nur einmal decodiert | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Lifecycle | Dependency, Erst-, Wiederholungs-, zentrale Nutzung und Uninstall | SQL Server 2025 Linux: erfolgreich; Kollision `not executed` |

Aktuelle Evidenz: [Run 30552721606](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30552721606).
