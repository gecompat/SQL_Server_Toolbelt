# Contract-Testmatrix: Date/Time Bucket

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Bereich | Pflichtfälle |
|---|---|
| Typen | `date`, `datetime2(7)`, `datetimeoffset(7)` |
| Dateparts | `year` bis `millisecond`, dokumentierte Aliasse |
| Width | `1`, mehrere Einheiten, `0`, negative Werte, `int`-Grenzen |
| Origin | Default, explizit, Zeitanteil, Monatsende, unterschiedliche Offsets |
| Richtung | Value vor und nach Origin; mathematisches Floor für negative Abstände |
| Grenzen | minimale und maximale Date/Time-Werte, Engine-Overflow unverändert |
| Validation | Codes `10`, `11`, `12`; NULL-Propagation |
| Parität | ausgewählte Vektoren gegen natives `DATE_BUCKET` auf 2022/2025 |
| Optimizer | öffentliche Inline-TVFs vor internem einzeiligem Core; 100.000-Zeilen-Workload; kein Fehler `8632` |
| Lifecycle | Erstdeployment, Wiederholung, Kollision, Central, Uninstall |

## Evidenzstatus

Windows/Linux 2019/2022/2025 waren einschließlich nativer Parität,
100.000-Zeilen-Workload, Kollision, Lifecycle, Central und Uninstall erfolgreich.

[W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; lokales und zentrales Deployment, native Parität, 100.000-Zeilen-Optimizer-Workload, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
