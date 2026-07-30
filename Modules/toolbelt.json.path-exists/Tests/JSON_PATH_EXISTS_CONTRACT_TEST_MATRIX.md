# Contract-Testmatrix JSON Path Exists

| Dimension | Pflichtfälle | Erwartung |
|---|---|---|
| Rückgabe | vorhanden, nicht vorhanden, JSON `null` | `1`, `0`, `1` |
| SQL NULL | JSON oder Pfad SQL `NULL` | SQL `NULL` |
| JSON | Objekt, Array, skalare Roots, ungültiger Text | fehlerfreie definierte Rückgabe |
| Properties | unquotiert, quotiert, escaped, Unicode | case-sensitive BIN2-Semantik |
| Arrays | Index `0`, fehlender Index, `[*]` | nullbasierte Navigation und Any-Match |
| Modi | Default, `lax`, `strict` | identischer fehlerfreier Existenzvertrag |
| Ungültige Pfade | fehlendes `$`, unclosed quote, ungültiger Escape, Range, Liste, `last` | `0`, kein Fehler |
| Länge | leerer und mehr als 4.000 Codeunits langer Pfad | `0` |
| Native Parität | SQL Server 2022+ für den gemeinsamen Scope | gleiche `1`/`0`/`NULL`-Ergebnisse |
| Objektart | `TVF_JsonPathExists` | Multi-statement TVF (`TF`) |
| Lifecycle | Erstinstallation, Wiederholung, Central, Uninstall | vollständig und ohne Restobjekt |
| Plattform | SQL Server 2025 Linux, Compatibility 150/160/170 | zuerst CI; 2019/2022/Windows später |

Die SQL-Server-2025-Preview-Pfade mit Array-Range, Indexliste und `last`
werden ausschließlich als abgelehnte Eingaben getestet. Sie sind kein
V1-Kompatibilitätsversprechen.

Aktuelle Evidenz:
[Run 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943)
– SQL Server 2025 Linux mit Compatibility Levels 150/160/170 erfolgreich.
