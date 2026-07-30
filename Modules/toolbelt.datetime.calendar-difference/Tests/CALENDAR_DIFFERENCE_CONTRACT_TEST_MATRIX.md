# Calendar Difference Contract-Testmatrix

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| Grundvertrag | gleiche, vorwärts- und rückwärtsgerichtete Daten | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Anniversary | Monatsende, 28./29. Februar und Schaltjahr | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Grenzen | `0001-01-01`, `9999-12-31`, `NULL` | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Mengenaufruf | `OUTER APPLY` über mehrere Paare | SQL Server 2025 Linux, Compatibility 150/160/170: erfolgreich |
| Lifecycle | Erst-, Wiederholungs-, zentrale Nutzung und Uninstall | SQL Server 2025 Linux: erfolgreich; Kollision `not executed` |

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399).
