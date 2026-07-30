# URI Component Contract-Testmatrix

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| RFC | unreserved, reserved, Leerzeichen und `%HH` in Großbuchstaben | vorgesehen |
| Unicode | BMP, Supplementary Plane und UTF-8-Mehrbytefolgen | vorgesehen |
| Decode-Fehler | `%`, `%G0`, unvollständige Sequenz, Überlong und NUL | vorgesehen |
| Sicherheit | `%252F` wird nur einmal decodiert | vorgesehen |
| Lifecycle | Dependency, Erst-, Wiederholungs-, Kollisions- und Uninstall-Pfad | vorgesehen |

Aktuelle Evidenz: [W1 Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml) – `not executed`.
