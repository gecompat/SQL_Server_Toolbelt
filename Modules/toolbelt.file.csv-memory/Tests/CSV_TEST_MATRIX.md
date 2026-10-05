# CSV-Testmatrix

Stand 2026-10-05: `partially validated`, `unreleased`. Vorhandene Assertions sind
kein Ausführungsnachweis. Der achte öffentliche Gesamtadapter bestand auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 local/central mit
identischem finalem Produkt-/Binarypaar; frische unabhängige Linux-/Windowsaudits
PASS. [Evidenz](README.md) beschreibt
historische Fehlläufe und Einschränkungen. Grenzen werden mit kleinen exakten/+1-
Fixtures geprüft; daraus folgt keine Heap- oder vollständige Ceilingqualifikation.

| Scope | Pflichtfälle | Status |
|---|---|---|
| Statisch | Source-/Lifecycle-/Trust-/Generator-Verträge | passed; kein Runtime-Nachweis |
| Parser/NULL/Text/Writer | Tatsächliche synthetische Assertions in Contract.Tests.sql und Safety.Tests.sql | passed local/central Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 |
| SQL-Budgets | Tatsächliche exakte/+1- und Expansionsassertions in Safety.Tests.sql | passed local/central; kein Heapnachweis |
| USP/ResultTable/Transaktionen | Tatsächliche Contract-/Safety-/Lifecycle-SQLassertions | passed local/central; keine weitergehende Vollmatrix |
| CLR | Exakt gepacktes .NET48-Binary, unabhängige Orakel/Roundtrip, IL/NoIO/Attribute, keine Drittanbieter | passed; drei Kulturen en-US/de-DE/tr-TR, harte Grenzphase en-US; kein SQLnachweis |
| Installation | Clean/Repeat, fünf Slots/drei native CLR-Bindings | passed local/central Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 |
| SQL-Lifecyclefixture | Lifecycle.Tests.sql | passed local/central |
| Gezielter Lifecycle | Caller/SET, AppLock, injected Rollback, Confirm0, Uninstall/Repeat | passed; 29 konkrete Caller-/Lock-/Rollback-/Confirm0-Prüfungen, kein Fremdslot-/Driftvollmatrix-Nachweis |
| Fremdslots/Markerdrift | weitergehende Lifecycle-Kollisions-/Driftmatrix | not executed |
| Client | echte SqlDataReader-Spalten/Nullability/Resultsetanzahl, keine Help-Seiteneffekte | passed im achten Lauf; historischer fünfter Metadata-Fehllauf bleibt FAILED |
| Modi | local, central, CrossDB mit caller-lokalen Temps und abweichender Collation | passed local/central und frischer SC-/UTF8-Consumer; keine Collationvollmatrix |
| Plattform | SQL2019/2022/2025 Windows/Linux und relevante CL getrennt | Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 bestanden; übrige Matrix not executed |
| Gesamtadapter/Cleanup | Prozessausgang, vollständige Kanäle, frischer unabhängiger OwnDB-/Trustaudit | achter Lauf PASS, Exit0, vollständige Kanäle/leeres Stderr, Cleanup im Lauf PASS; frische unabhängige Audits je drei OwnDB/ein OwnTrust abwesend; keine Konfigurations-/Rechteänderungen |
| Head-CI | separater Nachweis am exakten PR-Head | not executed |
| Rechte | vorhandene Minimalrechte, eingeschränkte Metadata-Visibility | not executed |
| Kapazität | vollständige Ceiling-/Heap-/Performancequalifikation | not executed |

Version1.0.0 besitzt keinen historischen Vorgänger; ein Upgrade früherer Releases
ist `not applicable`. Das begründet keine pauschale Lifecycle-Aufwertung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1`
- Scope: Finales gleiches Produkt-/Binarypaar: öffentliche Gesamtadapter auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 jeweils local/central mit allen drei SQLfixtures, Clientmetadaten, Clean/Repeat, fünf Slots/drei Bindings, je 29 gezielten Caller-/SET-/Lock-/Rollback-/Confirm0-Prüfungen, frischem SC-/UTF8-Consumer und Uninstall/Repeat PASS. Je Exit0, vollständige Kanäle, leeres Stderr und Cleanup im Lauf bestanden. Linux: frischer unabhängiger Audit bestätigt drei eigene DBs/einen eigenen Trusthash abwesend, keine Konfigurations-/Rechteänderungen; Windows: frischer unabhängiger Audit bestätigt ebenfalls drei eigene DBs/einen eigenen Trusthash abwesend, keine Konfigurations-/Rechteänderungen. Keine Minimalrechte-/Fremdslot-/Driftvollmatrix-/Heap-/übrige Zielmatrix- oder Head-CI-Qualifikation. Frühere FAILED-Läufe bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
