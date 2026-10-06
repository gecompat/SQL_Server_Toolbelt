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
| Typed-Marker-Teilnachweis | synthetisches int statt bit auf USP_ParseCsv, Deploy/Uninstall SQL55324/state5, unveränderte Metadaten und exakte Restaurierung | passed; zwei separate Fälle Linux2019/latest CL150 lokal, frischer unabhängiger Audit eine eigene DB/ein eigener Trusthash abwesend; kein Gesamtadapter-/Windows-/Central-Nachweis |
| Fremdslots/Markerdrift | weitergehende Lifecycle-Kollisions-/Driftmatrix | not executed; der separate Zweifall-Nachweis ersetzt die Vollmatrix nicht |
| Client | echte SqlDataReader-Spalten/Nullability/Resultsetanzahl, keine Help-Seiteneffekte | passed im achten Lauf; historischer fünfter Metadata-Fehllauf bleibt FAILED |
| Modi | local, central, CrossDB mit caller-lokalen Temps und abweichender Collation | passed local/central und frischer SC-/UTF8-Consumer; keine Collationvollmatrix |
| Plattform | SQL2019/2022/2025 Windows/Linux und relevante CL getrennt | Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 bestanden; übrige Matrix not executed |
| Gesamtadapter/Cleanup | Prozessausgang, vollständige Kanäle, frischer unabhängiger OwnDB-/Trustaudit | achter Lauf PASS, Exit0, vollständige Kanäle/leeres Stderr, Cleanup im Lauf PASS; frische unabhängige Audits je drei OwnDB/ein OwnTrust abwesend; keine Konfigurations-/Rechteänderungen |
| Head-CI | separater Nachweis am exakten PR-Head | passed historisch für [PR169](https://github.com/gecompat/SQL_Server_Toolbelt/pull/169), Head89f36f848ab68a1a72898ddd5f081fc47740f119, fünf erfolgreiche Checks; kein CSV-SQL2022-Runtime-Nachweis; neue Heads separat prüfen |
| Rechte | vorhandene Minimalrechte, eingeschränkte Metadata-Visibility | not executed |
| Kapazität | vollständige Ceiling-/Heap-/Performancequalifikation | not executed |

Version1.0.0 besitzt keinen historischen Vorgänger; ein Upgrade früherer Releases
ist `not applicable`. Das begründet keine pauschale Lifecycle-Aufwertung.

`MarkRelease.sql` schreibt und `Preflight.sql` entfernt datenbankweite
Release-Marker per Extended Property ohne Objektlevel. Schema-/Assembly-DDL-Rechte
belegen diese Operationen nicht allein; Microsoft dokumentiert für
[`sp_addextendedproperty`](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addextendedproperty-transact-sql)
die Datenbank-Ausnahme für `db_ddladmin`. Eine tatsächliche Minimalrechteprobe
für den vollständigen Lifecycle wurde nicht ausgeführt und es wurden keine
Rechte vergeben.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: hashgebundener Typed-Marker-Teiladapter aus Tests/CI/run-csv-memory-lab.ps1`
- Scope: Zwei separate synthetische Markerfälle auf Linux2019/latest CL150 lokal: Deploy/Uninstall weisen Toolbelt.Managed als int statt bit auf USP_ParseCsv mit SQL55324/state5 ab; vollständige Metadaten unverändert, neutraler Transaktionszustand und exakte eigene Restaurierung bestanden. Exit0, vollständige Kanäle, leeres Stderr; frischer unabhängiger Audit bestätigt eine eigene DB/einen eigenen Trusthash abwesend, keine Konfigurations-/Rechteänderungen. Kein neuer Gesamtadapter-, API-, Client-, Central-, Windows-, Minimalrechte-, Heap- oder vollständiger Fremdslot-/Driftmatrix-Nachweis; nicht zum bisherigen 29-Fall-Zähler addiert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
