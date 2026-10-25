# toolbelt.validation.semantic-version

Aktuelle [Utility-Callerrechte](../../Releases/1.0.0/UTILITY-CALLER-QUALIFICATION.md): einzelne SELECT-/EXECUTE-Grants für16 öffentliche Funktionen lokal/direkt zentral auf zwölf Ziel-/CL-Kombinationen; andere APIs, direkte Dependencies und Helper bleiben unzugänglich. Frühere Voll-, Last-, Client- und Lifecycle-Nachweise behalten ihren Scope; keine Statusaufwertung.

Für Scalarwrapper ist das nativ geprüfte direkte Einzelrecht EXECUTE. Die ältere generische SELECT-/REFERENCES-Formulierung im Manifest beziehungsweise Scalarheader ist veraltet und bleibt bis zum getrennten gebundenen Metadaten-/Paketrefresh ausdrücklich als Erratum geführt.

Nachqualifikation 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../Tests/V0C_RELEASE_GATE_STATUS.md).

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
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019/2022/2025 unter Windows mit freigegebenen CU-Äquivalenten zu base und Linux latest; vollständiger Adapter einschließlich der am 2026-10-09 verschärften NULL- und Kardinalitätsorakel, Upgrade, Central, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
