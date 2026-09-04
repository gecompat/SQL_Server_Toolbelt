# toolbelt.validation.semantic-version

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Strikte Semantic-Version-2.0.0-Validierung und Präzedenz für ASCII-Strings bis
`varchar(8000)`.

Status: `implemented`, `validated`, `unreleased`.

Öffentliche Objekte:

- `TVF_ParseSemanticVersion` – genau eine Validierungs-/Komponentenzeile;
- `TVF_CompareSemanticVersion` – relationaler Vergleichskern;
- `TVF_SemanticVersionSortKey` – relationaler Sort-Key-Kern;
- `SVF_CompareSemanticVersion` – `-1`, `0`, `1` oder `NULL`;
- `SVF_SemanticVersionSortKey` – binärer, collation-unabhängiger Präzedenzkey.

Core-Zahlen bleiben Dezimalstrings und können daher nicht numerisch
überlaufen. Build Metadata wird erhalten, aber bei Präzedenz und Sort Key
ignoriert. Es gibt kein Trimmen, `v`-Präfix oder stilles Korrigieren.

Modulversion `1.1.0` ergänzt die beiden inline-TVF-APIs. Die SVFs delegieren
an diese Kerne. Für mengenorientierte Aufrufe sind die TVFs mit `APPLY` zu
bevorzugen.

Aktuelle Evidenz:
[Semantic-Version Runtime Run 30535377984](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Der vollständige Adapter ist am 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Windows-Läufe
bleiben offen.

Siehe [Design](../../Documentation/Architecture/SEMANTIC_VERSION_MODULE_DESIGN.md)
und [Testmatrix](./Tests/SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
