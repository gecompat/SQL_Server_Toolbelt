# JSON Pointer – Tests

Die [Testmatrix](JSON_POINTER_TEST_MATRIX.md) trennt feste synthetische Oracles,
Metadaten, Lifecycle und tatsächliche Ausführung. Code allein ist kein Nachweis.
Der [kanonische Vertrag](../../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
definiert Fehlerpriorität und die zugelassene MSTVF-Ausnahme.

Contract/Safety verwenden feste Status-/Wertoracles unter vier Inputcollations
mit CROSS/OUTER APPLY. Unicode entsteht aus synthetischen UTF16-Binarybytes.
SQLCMD `ToolbeltDatabase` ist leer für currentDB oder bindet den expliziten
zentralen Provider. Technische Enginefehler gelten als FAIL.

Metadata erhält eine offene SqlConnection und optionale Timeout-/Readbudget-
Callbacks. Lifecycle.Tests.sql prüft ausschließlich die installierte Baseline.
Der eigene Labadapter besitzt Erst-/Repeat-/Uninstall, Callerzustände,
AppLock, Rollbackinjektionen, Marker-/Fremdslotwiederherstellung, Confirm0,
zentralen Consumer sowie streng journalgebundene eigene Bereinigung.
Produkt-DDL wird direkt ausgeführt; künstliche Faultseams sind Testvorbereitung.

`run-json-pointer-lab.ps1 -QualificationScope lifecycle` qualifiziert
unabhängig die installierte Baseline, echte Clientmetadaten und42 gezielte
Lifecyclefälle bei beiden Modi. Contract/Safety bleiben in diesem Scope
ausdrücklich NOT_EXECUTED; eine erfolgreiche Lifecycle-Prüfung löst die
offene native Tiefenpriorität nicht. Default `full` enthält weiterhin alle
drei SQLfixtures. Das private Journal hält Scope und tatsächliche Fixtures fest.

Statisch: `python Modules/toolbelt.json.pointer/Tests/Static/validate_contract.py`.
Der kanonische Deploymentgenerator wird dabei nicht schreibend geprüft.
Vollständige native API-/Safetyqualifikation, weitere physische Ziele, Minimalrechte und Heap-/
Maximalworkloadqualifikation sind in diesem Vorbereitungsstand offen.

Zwei begrenzte Linux2019/latest-CL150-Läufe bestanden Install/Repeat und
432 Contract-APPLY-Oracles, scheiterten danach in Safety. Der erste technische
Fehler13606/state1 wurde im zweiten Lauf als synthetischer Fall41 (Tiefe129)
isoliert. ISJSON selbst wirft bei129 offenen Containern auch für ungültiges
JSON diesen Fehler. Beide Läufe sind FAILED_CLEANED; unabhängige neue
Verbindungen bestätigten eigene DB-Abwesenheit und unveränderte Inputpins.
Keine Konfigurations-, Rechte- oder Truständerungen. Kein vollständiger
Safety-/Client-/Lifecycle-/central-/Windowsnachweis. Der
[Änderungsvorschlag](../../../Documentation/Architecture/JSON_POINTER_NATIVE_DEPTH_BOUNDARY.md)
benötigt ausdrückliche Zustimmung zur Priorität oberhalb128; Source bleibt
bis dahin beim freigegebenen ursprünglichen Vertrag. Teilweise validiert,
unveröffentlicht, aktuell kein mergefähiger Abschlussstand.

Die anschließenden getrennten Lifecycle-Scope-Adapter bestanden mit zwischen
diesen beiden erfolgreichen Läufen identischem eingefrorenen Source-/Deployment-/
Fixture-/Adapterstand auf Linux2019/latest CL150 und
Windows2025/exaktCU8 CL170. Je local/central/Consumer,15 echte direkte
Statusclientreader, installierte Baseline, Erst-/Repeat-/Uninstall-/Repeat
und42 gezielte Lifecyclefälle. Je Exit0, vollständige Kanäle und leeresStderr.
Frische unabhängige Audits bestätigen COMPLETE42, drei eigeneDBs abwesend,
je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert und jeweils
zweifach abgewiesen sowie sämtlicheInputpins unverändert. Kein Konfigurations-,
Rechte- oder Trustscope. Contract/Safety-Fixtures sind in diesen zwei separaten
Scopes NOT_EXECUTED. Die frühere Contract-Teilevidenz und beide fehlgeschlagenen
Gesamtadapter bleiben getrennt; keine Behebung der nativen Tiefenpriorität
und keine vollständige API-/Safetymatrixqualifikation daraus abgeleitet.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope lifecycle`
- Scope: Separater gleicher Source-/Deployment-/Fixture-/Adapterstand auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 bestanden: jeweils local/central/Consumer, installierte Baseline,15 echte Statusclientreader, Clean/Repeat/Uninstall/Repeat und42 gezielte Caller-/Lock-/Rollback-/TypedMarker-/Fremdslot-/Dependency-/Confirm0-Fälle. Je tatsächlicherExit0, vollständige Kanäle und leeresStderr. Neue unabhängige Verbindungen bestätigen COMPLETE42, drei eigeneDBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit je zwei Abweisungen und sämtlicheInputpins unverändert; Nullscope Konfiguration/Rechte/Trust. Contract/Safety-Fixtures in diesem Scope ausdrücklich NOT_EXECUTED. Frühere Gesamtfehlläufe bleiben fehlgeschlagen; ursprüngliche Priorität oberhalb128 weiterhin blockiert und Änderungszustimmung offen. Weitere physische Ziele, Minimalrechte, Maximalworkload/Heap und exakteHead-CI separat offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
