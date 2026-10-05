# JSON Pointer1.0.0 – Testmatrix

Der [kanonische Vertrag](../../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
bestimmt feste Erwartungen. Historische Engineproben ersetzen keine API-Prüfung.

| Artefakt | Prüfscope |
|---|---|
| Runtime/Contract.Tests.sql | RFC-Beispiele, Roottypen, einmalige Escapes, exakte Keys/NUL/trailing spaces, passende Duplikate, Arraylexik, große Indices, alle Statuswerte; CROSS/OUTER APPLY und vier Inputcollations |
| Runtime/Safety.Tests.sql | SQLNULL-/Budget-/Syntax-/Unicode-/Tiefenpriorität, Grenzen und vollständige unselektierte Prüfung, Chunkübergänge und gemischte Surrogatpaare |
| Runtime/Metadata.Tests.ps1 | Tatsächliche TF, vier Parameter/vier Spalten, Defaults, Collation/Nullability und fünf direkte Statusreader ohne weiteren Resultset |
| Runtime/Lifecycle.Tests.sql | Installierter eigener TF-/Marker-/Parameter-/Spaltenbestand |
| Tests/CI/run-json-pointer-lab.ps1 | Local/central/Consumer mit gewähltem CL, install/repeat/uninstall/repeat, 42 gezielte Caller-/Lock-/Rollback-/Marker-/Fremdslot-/Dependency-/Confirmfälle bei beiden Modi, own cleanup und Inputpins |
| Static/validate_contract.py | Source-/Manifest-/Deployment-/Test-/Dokumentationskopplung und nicht schreibender Generatorcheck; keine SQL-Ausführung |

Inputcollations: Latin1_General_100_BIN2, Latin1_General_100_CI_AS,
Latin1_General_100_CS_AS, Latin1_General_100_CI_AS_SC_UTF8.
Zielmatrix SQL2019/2022/2025 Windows/Linux mit gültigem CL150/160/170.
Weitere physische Kombinationen, Minimalrechte, 16MiB-Maximalworkload,
Heap und Parallelität bleiben bis zur dokumentierten Ausführung not executed.
Keine Release- oder Produktionszusage.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope lifecycle`
- Scope: Separater gleicher Source-/Deployment-/Fixture-/Adapterstand auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 bestanden: jeweils local/central/Consumer, installierte Baseline,15 echte Statusclientreader, Clean/Repeat/Uninstall/Repeat und42 gezielte Caller-/Lock-/Rollback-/TypedMarker-/Fremdslot-/Dependency-/Confirm0-Fälle. Je tatsächlicherExit0, vollständige Kanäle und leeresStderr. Neue unabhängige Verbindungen bestätigen COMPLETE42, drei eigeneDBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit je zwei Abweisungen und sämtlicheInputpins unverändert; Nullscope Konfiguration/Rechte/Trust. Contract/Safety-Fixtures in diesem Scope ausdrücklich NOT_EXECUTED. Frühere Gesamtfehlläufe bleiben fehlgeschlagen; ursprüngliche Priorität oberhalb128 weiterhin blockiert und Änderungszustimmung offen. Weitere physische Ziele, Minimalrechte, Maximalworkload/Heap und exakteHead-CI separat offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
