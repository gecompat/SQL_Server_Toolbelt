# Contract-Testmatrix: Bigint Bit Operations

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Pflichtfälle |
|---|---|
| Shift | links, rechts, negativ, `0`, `63`, `64`, größere Beträge, bigint-Min/Max |
| Logik | Right Shift negativer Werte füllt mit null; Left Shift verwirft Übertrag |
| Bit Count | `0`, `-1`, Min/Max, wechselnde Muster, `NULL` |
| Get Bit | Offset `0`, `63`, negativ, `64`, Vorzeichenbit |
| Set Bit | setzen, löschen, Default `1`, ungültiger Bitwert, Vorzeichenwechsel |
| Validation | Codes `10`, `11`; typisierte NULL-Propagation |
| Parität | alle fünf Operationen mit Vektoren gegen SQL Server 2022/2025 |
| Performance | mengenorientierter `APPLY`-Aufruf und Vergleich mit nativer Funktion |
| Lifecycle | Erstdeployment, Wiederholung, Kollision, Central, Uninstall |

`binary(n)` und `varbinary(n)` sind nicht Teil dieser Matrix.

## Evidenzstatus

Windows/Linux 2019/2022/2025 waren einschließlich nativer Parität, Kollision,
Lifecycle, Central und Uninstall erfolgreich.

[W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter einschließlich nativer Parität, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
