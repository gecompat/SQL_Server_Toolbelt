# Contract-Testmatrix: Date/Time Truncation

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Pflichtfälle |
|---|---|
| Typen | `date`, `datetime2(7)`, `datetimeoffset(7)` mit typgleicher Ausgabe |
| Dateparts | kanonische Werte und Aliasse von `year` bis `microsecond` |
| Woche | mehrere `DATEFIRST`-Werte, `iso_week`, Unterlauf an `0001-01-01` |
| Fractional Scale | `millisecond` und `microsecond` bei Scale 7 |
| Offset | positive und negative nicht volle Stunden; Offset bleibt erhalten |
| Validation | Codes `10`, `11`, `12`; vollständig typisierte NULL-Propagation |
| Parität | ausgewählte Vektoren gegen natives `DATETRUNC` auf 2022/2025 |
| Performance | mengenorientierter `CROSS APPLY`-Aufruf; Planform vor Release prüfen |
| Lifecycle | Erstdeployment, Wiederholung, Kollision, Central, Uninstall |

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
