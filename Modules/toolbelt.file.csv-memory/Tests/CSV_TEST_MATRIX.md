# CSV-Testmatrix

Stand 2026-10-20: `partially validated`, `unreleased`. Vorhandene Assertions sind
kein Ausführungsnachweis. Der achte öffentliche Gesamtadapter bestand auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 local/central mit
identischem finalem Produkt-/Binarypaar; frische unabhängige Linux-/Windowsaudits
PASS. [Evidenz](README.md) beschreibt
historische Fehlläufe und Einschränkungen. Grenzen werden mit kleinen exakten/+1-
Fixtures geprüft; daraus folgt keine Heap- oder vollständige Ceilingqualifikation.

Die ergänzende Welle vom 2026-10-20 bestand auf Windows2019/base CL150,
Windows2022/base CL160 (je bereites erlaubtes CU-Äquivalent), Linux2022/latest
CL160 und Linux2025/latest CL170 jeweils local/central. Je erster nativer
Versuch, drei SQLfixtures, Client, Clean/Repeat, fünf Slots/drei Bindings,
29 gezielte Lifecyclefälle, frischer SC-/UTF8-Consumer, Uninstall/Repeat,
Exit0/vollständige Kanäle/leeres Stderr und frischer unabhängiger Audit mit drei
eigenen DBs/einem eigenen Trusthash abwesend. Drei autorisierte temporäre
CLR-Konfigurationen vollständig restauriert, keine Rechte-/Infrastrukturänderung.
Ein neues gemeinsames reproduzierbar gebautes Releasepaket bestand vorher
Framework/IL/NoIO in drei Kulturen; keine hostübergreifende Buildzusage.
In dieser Vierzielwelle wurden die älteren beiden Ziele nicht erneut ausgeführt.
Die nachfolgende getrennte Standard-CL-Ergänzung vom 2026-10-20 bestand auf
Linux2019/latest CL150 und Windows2025/base CL170 (erlaubtes bereites
CU-Äquivalent) jeweils local/central im ersten nativen Versuch mit aktuellen
ResultTable-Abhängigkeiten und demselben unveränderten Paket. Je identischer
SQL-/Client-/29-Lifecycle-/Consumer-/Uninstall-Scope, Exit0, vollständige Kanäle,
leeres Stderr und frischer unabhängiger Audit drei eigene DBs/ein eigener
Trusthash abwesend. Keine Konfigurations-/Rechte-/Infrastrukturänderungen.
Vorherige Build-/Frameworknachweise wurden nach Inputbindung wiederverwendet,
nicht erneut ausgeführt. Damit ist der begrenzte Standard-CL-Adapter auf allen
sechs physischen Kombinationen am aktuellen Quellen-/Abhängigkeitsstand bestanden.
Zusätzliche CLs,
Minimalrechte, Vollmatrixdrift, Heap, authentifiziertes TLS und Release bleiben offen.

| Scope | Pflichtfälle | Status |
|---|---|---|
| Statisch | Source-/Lifecycle-/Trust-/Generator-Verträge | passed; kein Runtime-Nachweis |
| Parser/NULL/Text/Writer | Tatsächliche synthetische Assertions in Contract.Tests.sql und Safety.Tests.sql | passed local/central im jeweils datierten Zielscope vom 2026-10-05 und 2026-10-20 |
| SQL-Budgets | Tatsächliche exakte/+1- und Expansionsassertions in Safety.Tests.sql | passed local/central; kein Heapnachweis |
| USP/ResultTable/Transaktionen | Tatsächliche Contract-/Safety-/Lifecycle-SQLassertions | passed local/central; keine weitergehende Vollmatrix |
| CLR | Exakt gepacktes .NET48-Binary, unabhängige Orakel/Roundtrip, IL/NoIO/Attribute, keine Drittanbieter | passed; drei Kulturen en-US/de-DE/tr-TR, harte Grenzphase en-US; kein SQLnachweis |
| Installation | Clean/Repeat, fünf Slots/drei native CLR-Bindings | passed local/central im jeweils datierten Zielscope vom 2026-10-05 und 2026-10-20 |
| SQL-Lifecyclefixture | Lifecycle.Tests.sql | passed local/central |
| Gezielter Lifecycle | Caller/SET, AppLock, injected Rollback, Confirm0, Uninstall/Repeat | passed; 29 konkrete Caller-/Lock-/Rollback-/Confirm0-Prüfungen, kein Fremdslot-/Driftvollmatrix-Nachweis |
| Typed-Marker-Teilnachweis | synthetisches int statt bit auf USP_ParseCsv, Deploy/Uninstall SQL55324/state5, unveränderte Metadaten und exakte Restaurierung | passed; zwei separate Fälle Linux2019/latest CL150 lokal, frischer unabhängiger Audit eine eigene DB/ein eigener Trusthash abwesend; kein Gesamtadapter-/Windows-/Central-Nachweis |
| Fremdslots/Markerdrift | weitergehende Lifecycle-Kollisions-/Driftmatrix | not executed; der separate Zweifall-Nachweis ersetzt die Vollmatrix nicht |
| Client | echte SqlDataReader-Spalten/Nullability/Resultsetanzahl, keine Help-Seiteneffekte | passed im achten historischen Lauf und in sechs ergänzenden Standard-CL-Läufen vom 2026-10-20; historischer fünfter Metadata-Fehllauf bleibt FAILED |
| Modi | local, central, CrossDB mit caller-lokalen Temps und abweichender Collation | passed local/central und frischer SC-/UTF8-Consumer; keine Collationvollmatrix |
| Plattform | SQL2019/2022/2025 Windows/Linux und relevante CL getrennt | 2026-10-20: Windows/base mit erlaubten CU-Äquivalenten und Linux/latest jeweils SQL2019 CL150, SQL2022 CL160, SQL2025 CL170 bestanden. Zusätzliche CLs not executed; keine vollständige Supportqualifikation |
| Gesamtadapter/Cleanup | Prozessausgang, vollständige Kanäle, frischer unabhängiger OwnDB-/Trustaudit | sechs ergänzende Standard-CL-Läufe vom 2026-10-20 PASS mit Exit0/vollständigen Kanälen/leeren Stderr; je drei OwnDB/ein OwnTrust abwesend. Vierzielwelle: drei temporäre CLR-Konfigurationen restauriert; folgende zwei Läufe: keine Konfigurationsänderung. Keine Rechte-/Infrastrukturänderungen |
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
- Datum: `2026-10-20`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1`
- Scope: Vier zusätzliche physische Labzielkombinationen bestanden jeweils im ersten nativen Versuch mit demselben reproduzierbar gebauten Releasepaket: Windows2019/base CL150 und Windows2022/base CL160 mit erlaubten bereiten CU-Äquivalenten sowie Linux2022/latest CL160 und Linux2025/latest CL170. Je local/central, drei SQLfixtures, Clientmetadaten, Clean/Repeat, fünf Slots/drei Bindings, 29 gezielte Caller-/SET-/Lock-/Rollback-/Confirm0-Fälle, frischer SC-/UTF8-Consumer und Uninstall/Repeat; Exit0, vollständige Kanäle, leeres Stderr. Je frischer unabhängiger Audit drei eigene DBs/einen eigenen Trusthash abwesend und Inputpins unverändert. Autorisierte temporäre CLR-Testkonfiguration auf drei Zielen einschließlich zuvor vorgemerktem Scope privat erfasst und vollständig in den Ausgangszustand restauriert; keine Rechte-/Infrastrukturänderungen. Historische Nachweise bleiben datiert; zusätzliche CLs, Minimalrechte, Fremdslot-/Driftvollmatrix, Heap, authentifiziertes TLS und Release bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
