# Integer-Base Contract-Testmatrix

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Fälle | Stand |
|---|---|---|
| Signatur | `bigint`, `varchar(93)`, `varchar(65)` | vorhanden |
| Alphabet | Länge 2/93, druckbares ASCII, binär eindeutig, kein `-` | vorhanden |
| Darstellung | Null, Vorzeichen, keine führenden Nullen, kein `+`/`-0` | vorhanden |
| Basen | 2, 8, 10, 16, 36, 62 und 93 | vorhanden |
| Grenzen | vollständiger `bigint`-Bereich und Decode-Overflow | vorhanden |
| Roundtrip | positive, negative und Grenzwerte | vorhanden |
| API-Parität | SVF und inline TVF, exakt eine Zeile, `OUTER APPLY` | vorhanden |
| Upgrade | `1.0.0` auf `1.1.0`, Wiederholung, Kollision | vorhanden |
| Lifecycle | lokal, zentral, Drift, Kollision, Uninstall | vorhanden |
| SQL Server 2025 Linux 150/160/170 | Version `1.1.0` | `success` |
| SQL Server 2019/2022/2025 unter Windows base und Linux latest | Release-Matrix | erfolgreich |

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
