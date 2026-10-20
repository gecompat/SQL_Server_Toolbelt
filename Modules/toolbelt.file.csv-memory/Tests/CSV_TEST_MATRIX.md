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
Die anschließende getrennte CL-Welle nach PR339 bestand auf Windows und Linux
jeweils SQL2022/CL150 sowie SQL2025/CL150 und CL160, mit derselben Lab-Patchauswahl
und aktuellem Quellen-/Abhängigkeitsstand. Sechs erste native Versuche, je
local/central, vollständiger oben genannter Adapterumfang, Exit0, vollständige
Kanäle/leeres Stderr und frischer unabhängiger Audit drei eigene DBs/ein eigener
Trusthash abwesend. Zwei autorisierte temporäre SQL2022-CLR-Konfigurationen
vollständig restauriert; keine Rechte-/Owner-/Infrastrukturänderung.
Build-/Framework- und Standard-CL-Nachweise nach erneuter Inputprüfung
wiederverwendet, nicht erneut ausgeführt. Damit sind alle zwölf zulässigen
Plattform-/Engine-/CL-Kombinationen im begrenzten Gesamtadapter bestanden.
Minimalrechte, Vollmatrixdrift, weitere Collations, Heap, authentifiziertes TLS
und Release bleiben offen.

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
| Erweiterte Marker-Guards | zehn Markeränderungen, je Deploy/Uninstall, erfasster Metadatenzustand und exakte eigene Restaurierung | Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 local/central PASS, je 40 Abweisungen und frischer Cleanup-Audit zwei eigene DBs/ein eigener Trusthash abwesend; zwei vorherige Linux-Guardfehlläufe bleiben FAILED, dritter Linuxlauf ausdrücklich freigegeben. Separate Zählung, keine API-/Client-/Driftvollmatrixabnahme |
| Fehlende Ownershipmarker | 27 einzelne Markerentfernungen je Modus, je Deploy-/Uninstallabweisung und exakte Restaurierung | Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 local/central jeweils erster Versuch PASS, 108 Abweisungen je Ziel SQL55324/state1/2/3/4/5; frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend. Kein zusätzlicher API-/Default-/Binding-/Minimalrechte-/Heap-/TLS-Nachweis |
| Fremdslots/Markerdrift | weitergehende Lifecycle-Kollisions-/Driftmatrix | not executed; der separate Zweifall-Nachweis ersetzt die Vollmatrix nicht |
| Fremdslot-/Verbraucher-Teilnachweis | fünf tabellenbelegte Zielslots, SQL- und CLR-Verbraucher, je Deploy/Uninstall; Wert-/Index-Witnesskontrollen | Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 local/central PASS: je 28 Abweisungen und vier inverse Kontrollen, frischer Cleanup-Audit zwei eigene DBs/ein eigener Trusthash abwesend. Erster Linuxversuch FAILED am Leerkatalogsnapshot, bereinigt; gemeinsamer Snapshotfix und zweiter Versuch PASS. Separater Linux-Defaultregressionslauf mit 29 Lifecyclefällen und drei eigenen DBs bereinigt PASS. Keine vollständige Fremdobjekt-/Driftmatrix oder neue Zwölfzielabnahme |
| Fremde Views/Prozeduren | fünf reservierte Namen je als View und SQL-Prozedur; Deploy/Uninstall, Definition-/Signatur-/Wertorakel | Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 local/central jeweils erster Versuch PASS, je 40 Abweisungen SQL55324/state3, erfasster Zustand und synthetische Ergebnisse unverändert; geschützte Fixtureentfernung, frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend. Keine Synonym-/übrige Fremdart-/Verbraucher-/Driftvollmatrix, kein neuer Default-/API-/Clientnachweis |
| Fremde Synonyme/SQL-Funktionen | fünf reservierte Namen je als Synonym und SQL-Skalarfunktion, gleiche Lifecycle-Abweisung plus bytegenaues lokales Synonymziel | Linux2019/latest CL150 zweiter und Windows2025/base mit erlaubtem CU-Äquivalent CL170 erster Aliasversuch local/central PASS, je 40 Abweisungen; erster Linuxfehllauf erhalten und bereinigt. Separater Linux-View-/Prozedur-Regressionslauf ebenfalls 40 PASS. Je erfolgreichem Lauf frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend; kein neuer Default-/API-/Client-/Binding-/Minimalrechte-/Heap-/TLS-/Release- oder Driftvollmatrixnachweis |
| Interne CLR-Bindingdrift | acht einzelne NULL-Options-/Längen-/Namensänderungen an den drei internen Funktionen, je Deploy/Uninstall und exakte Restaurierung | Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 local/central jeweils erster Versuch PASS: je 32 Abweisungen SQL55324/state5/7, konkreter Katalogwitness, unveränderter erfasster Mutationszustand und Objektidentität, anschließend exakte Baseline. Je frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend. Keine vollständige Binding-/Driftmatrix oder neue Default-/API-/Client-/Minimalrechte-/Heap-/TLS-/Releaseabnahme |
| CLR-Parameterdefaults | fünf einzelne Text-/bit-/NULL-/bigint-Defaults, je Deploy/Uninstall und exakte Restaurierung | Finaler fünfter Lauf Windows2025/base mit erlaubtem CU-Äquivalent CL170 zweiter Defaultsversuch local/central20 Abweisungen SQL55324/state7 PASS, Basistyp/Wertbytes einschließlich NULL vor/nach Abweisung und vor Restore exakt. Linuxzweiter/Windowserster mit konvertierenden numerischen Probes und erster Linuxlauf ohne wiederholten Wertwitness bleiben enger. Separate Linux-Bindingregression32 PASS vor letzter defaultspezifischer Probeänderung; alle fünf Läufe frisch bereinigt, je zwei eigene DBs/ein eigener Trusthash abwesend. Keine Vollmatrix-/Defaultadapter-/API-/Client-/Minimalrechte-/Heap-/TLS-/Releaseabnahme |
| Client | echte SqlDataReader-Spalten/Nullability/Resultsetanzahl, keine Help-Seiteneffekte | passed in zwölf nativen Läufen vom 2026-10-20 (sechs Standard-CL, sechs zusätzliche CL); historischer fünfter Metadata-Fehllauf bleibt FAILED |
| Modi | local, central, CrossDB mit caller-lokalen Temps und abweichender Collation | passed local/central und frischer SC-/UTF8-Consumer; keine Collationvollmatrix |
| Plattform | SQL2019/2022/2025 Windows/Linux und relevante CL getrennt | 2026-10-20: Windows/base mit erlaubten CU-Äquivalenten und Linux/latest jeweils SQL2019 CL150, SQL2022 CL150/160, SQL2025 CL150/160/170 bestanden; zwölf zulässige Kombinationen im begrenzten Adapter, weitere Pflichtscopes offen |
| Gesamtadapter/Cleanup | Prozessausgang, vollständige Kanäle, frischer unabhängiger OwnDB-/Trustaudit | zwölf native Läufe vom 2026-10-20 PASS mit Exit0/vollständigen Kanälen/leeren Stderr; je drei OwnDB/ein OwnTrust abwesend. Standard-CL-Wellen: drei temporäre CLR-Konfigurationen restauriert; zusätzliche CL-Welle: zwei restauriert. Keine Rechte-/Infrastrukturänderungen |
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
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope binding-defaults; separater binding-drift-Regressionslauf`
- Scope: Finaler fünfter nativer Lauf: Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 im zweiten Defaultsversuch local/central PASS, 20 Deploy-/Uninstallabweisungen SQL55324/state7 mit exakter Basistyp-/Wertbytesprüfung einschließlich NULL vor/nach Abweisung und vor Restaurierung; exakte Baseline. Dieser repräsentative Lauf qualifiziert das nach unabhängigem Review verschärfte Orakel. Linux2019/latest CL150 zweiter und Windows erster Defaultsversuch bestanden zuvor20 Abweisungen mit engeren konvertierenden numerischen Probes; keine nachträgliche Aufwertung auf den finalen Byteswitness. Erster Linuxlauf bleibt noch engerer Teilnachweis ohne wiederholten Defaultwertwitness. Separater Linux-Binding-Regressionslauf local/central32 Abweisungen vor der letzten ausschließlich defaultspezifischen Probeverschärfung PASS. Alle fünf Läufe Exit0/vollständige Kanäle/leeres Stderr, je frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. 255 Offlinekontrollen,52 SQL150-Batches und AST PASS. Produkt-/Deployment-/CLR-Quellen und gemeinsame Snapshot-/Abweisungshelper unverändert; keine neue Defaultadapter-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/authentifizierte TLS-/Releaseabnahme.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
