# Calendar Difference Contract-Testmatrix

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| Grundvertrag | gleiche, vorwärts- und rückwärtsgerichtete Daten | vorgesehen |
| Anniversary | Monatsende, 28./29. Februar und Schaltjahr | vorgesehen |
| Grenzen | `0001-01-01`, `9999-12-31`, `NULL` | vorgesehen |
| Mengenaufruf | `CROSS APPLY` über mehrere Paare | vorgesehen |
| Lifecycle | Erst-, Wiederholungs-, Kollisions- und Uninstall-Pfad | vorgesehen |

Aktuelle Evidenz: [W1 Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml) – `not executed`.
