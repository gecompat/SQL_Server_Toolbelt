# Contract-Testmatrix: Console Message

| Bereich | Pflichtfall | Status |
|---|---|---|
| API | Objektart, Parameter, Reihenfolge und Typen | `not executed` |
| Help | vollständige Sections; keine Payload- oder Debug-Ausgabe | `not executed` |
| Resultset | normale Ausführung ohne fachliches Resultset | `not executed` |
| NULL/Leertext | keine Ausgabe, `RETURN 0` | `not executed` |
| PRINT | mehr als 8.000 Unicode-Zeichen vollständig gechunked | `not executed` |
| NOWAIT | mehr als 4.000 Unicode-Zeichen, `%` als Payload | `not executed` |
| Unicode | Supplementary Character an Chunkgrenze | `not executed` |
| Zeilen | CRLF-Reihenfolge im Payload | `not executed` |
| Lifecycle | Erstinstallation, Wiederholung, Central, Uninstall | `not executed` |
| Matrix | SQL Server 2025 Linux, Compatibility 150/160/170 | `not executed` |
| Release | physische SQL Server 2019/2022 und Windows | `not executed` |

Client-Pufferung und optische Frame-Darstellung werden nicht allein durch
einen erfolgreichen Engine-Test als plattformübergreifend bewiesen.
