# Split-Characters Contract-Testmatrix

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Verpflichtende Fälle | Aktueller Stand |
|---|---|---|
| Signatur | `nvarchar(max)`, `nvarchar(4000)`, `bit = 1`; `Value`, `Ordinal` | Test vorhanden |
| Grundsemantik | mehrere einzelne Separatoren; literal statt Regex | Test vorhanden |
| Leere Tokens | führend, nachfolgend, aufeinanderfolgend; Keep/Drop | Test vorhanden |
| Leere Werte | leere Eingabe; leere Separatorliste | Test vorhanden |
| `NULL` / NUL | `NULL`-Parameter; NUL in Separatorliste | Test vorhanden |
| Collation | Case und Akzent binär verschieden | Test vorhanden |
| Inhaltstreue | kein Trim; nachfolgende Leerzeichen bleiben erhalten | Test vorhanden |
| Separatorliste | Duplikate ohne Wirkung | Test vorhanden |
| Reihenfolge | Ordinal ab 1 und lückenlos; `ORDER BY` erforderlich | Test vorhanden |
| Mengenverwendung | `CROSS APPLY` | Test vorhanden |
| Größe | `nvarchar(max)` mit 10.001 Tokens | Test vorhanden |
| Native Abgrenzung | enges Regex-Oracle nur unter Compatibility 170 | Test vorhanden |
| Dependency | Marker und Objekt erforderlich; fehlende Dependency blockiert | Test vorhanden |
| Deployment | lokal, zentral, Wiederholung, Drift, Kollision | Test vorhanden |
| Uninstall | Objektmarker, Source-Hash, externe Dependency, Schemaeigentum | Test vorhanden |
| Plattform | SQL Server 2025 Linux, Compatibility 150/160/170 | erfolgreich |
| Release-Matrix | physische SQL Server 2019/2022/2025 unter Windows base und Linux latest | erfolgreich |

Der
[Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708)
war für SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die Release-Matrix bleibt offen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
