# JSON Pointer1.0.0 – Testmatrix

Der [kanonische Vertrag](../../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
bestimmt feste Erwartungen. Historische Engineproben ersetzen keine API-Prüfung.

54 Contract- und74 Safetyfälle ergeben1024 feste Resultatoracles je Kontext;
local/central/Consumer ergeben3072 je vollständigem Zieladapter. Finale
vollständige Adapter auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170
bestanden je diese Oracles,15 echte Clientreader und42 Lifecyclefälle.
Frische Audits bestätigten eigene Bereinigung, Fixturewiederherstellung und
Inputpins. Frühere Fehlläufe und Lifecycle-only-Scopes bleiben getrennt.
Zusätzliche vollständige Adapter auf demselben Windows2025/exaktCU8-Ziel mit
CL150 und CL160 bestanden am 2026-10-06 jeweils local/central/Consumer,
Contract/Safety, Clientmetadaten und42 Lifecyclefälle. Frische unabhängige
Audits bestätigten eigene Bereinigung, Fixturewiederherstellung und Inputpins;
das erweitert weder die physische Zielmatrix noch den Minimalrechte- oder
Maximalworkload-Nachweis.

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
- Datum: `2026-10-06`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope full`
- Scope: Zusätzliche vollständige Läufe auf demselben schema-validierten, exakt ausgewählten Windows2025/CU8-Ziel mit CL150 und CL160 bestanden jeweils local/central/Consumer, Contract/Safety, direkte Clientmetadaten, Repeat und42 Lifecyclefälle. Je Exit0, vollständige Kanäle und leeresStderr; frische unabhängige Audits bestätigten COMPLETE42, drei eigene DBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit zwei Abweisungen, unveränderte Inputpins und Nullscope Konfiguration/Rechte/Trust. CL150/160 sind getrennte neue Nachweise; CL170 und Linux2019 CL150 bleiben frühere Nachweise. Weitere physische Ziele, Minimalrechte,16MiB-Maximalworkload/Heap und vollständige Runtime-Head-CI offen; teilweise validiert, unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
