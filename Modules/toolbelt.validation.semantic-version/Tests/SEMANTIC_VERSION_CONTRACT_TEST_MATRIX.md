# Semantic-Version Contract-Testmatrix

| Bereich | Fälle | Stand |
|---|---|---|
| Parser | Core, Pre-release, Build, Canonical | vorhanden |
| Ungültig | `NULL`, leer, Präfix, Leading Zero, leere Identifier | vorhanden |
| Präzedenz | offizielle SemVer-Folge, ASCII, Build ignoriert | vorhanden |
| Größe | 2.000-stellige Core-Komponente ohne Overflow | vorhanden |
| Sort Key | gleiche Reihenfolge wie Comparator | vorhanden |
| Lifecycle | lokal, zentral, Drift, Kollision, Uninstall | vorhanden |
| SQL Server 2025 Linux 150/160/170 | vollständige Suite | `not executed` |
| SQL Server 2019/2022 und Windows | Release-Matrix | `not executed` |

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/semantic-version-runtime.yml
