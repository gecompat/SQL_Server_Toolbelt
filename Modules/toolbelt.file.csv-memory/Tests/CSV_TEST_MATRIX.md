# CSV-Testmatrix

Stand 2026-10-21: `partially validated`, `unreleased`. Vorhandene Assertions sind
kein Ausführungsnachweis. Der achte öffentliche Gesamtadapter bestand auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 local/central mit
identischem finalem Produkt-/Binarypaar; frische unabhängige Linux-/Windowsaudits
PASS. [Evidenz](README.md) beschreibt
historische Fehlläufe und Einschränkungen. Kleine exakte/+1-Fixtures bleiben
getrennt von den neuen tatsächlichen Zeilen-/Spaltendecken auf Windows;
deren abschließender Linuxnachweis ist offen. Keine Heap- oder vollständige
Ceilingqualifikation daraus ableiten.

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
| Tatsächliche Zeilen-/Spaltendecken | ShapeCeilings.Tests.sql: acht Parser-/Writer-Grenz-/+1-Fälle pro Modus und gezählter Abschluss | offen/FAILED: vier native Versuche vom2026-10-21 frisch bereinigt. Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent: lokale Parserphase100000 bestanden, Writerphase100000 Timeout120 beziehungsweise Windows auch300 Sekunden; übrige Phasen/central nicht erreicht. Linux erster zusammengefasster60-Sekunden-Fehllauf bleibt getrennt. Separate finale Linux-Defaultregression local/central einschließlich29 Lifecyclefällen bestanden und frisch bereinigt; keine tatsächliche Ceilingabnahme. |
| Korrigierter Writer an Formgrenzen | Maß-/Fragmentabgleich mit Schlüsseln, echte100000 Zeilen/1024 Spalten und +1; kombinierter Defaultumfang | Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent korrigierter Kandidat local/central PASS:16 Formfälle einschließlich acht SQL55303/state1, drei Defaultfixtures/Client/Consumer/29 Lifecyclefälle, Clean/Repeat und Uninstall/Repeat. Frischer Audit drei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Rechte/Inputs unverändert. Abschließender Linuxkandidat offen; vier frühere Grenz-FAILs und drei separate bereinigte Diagnoseaufrufe bleiben datiert. Keine Zell-/Textvollgrenze oder Heap-/Gesamtmatrix-/Releaseabnahme. |
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
| Fremde SQL-TVFs | fünf reservierte Namen je als Inline-/Multi-Statement-TVF, je Deploy/Uninstall und geschützte Entfernung | 2026-10-21 Linux2019/latest CL150 und Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 jeweils erster Versuch local/central PASS: je 40 Abweisungen SQL55324/state3, Definitionen/Signaturen und synthetische Ergebnisse einschließlich Padding unverändert, exakte Baseline. Ergebniswitness unmittelbar vor/nach jeder Operation und vor Drop. Separate Linuxregressionen beider bisherigen Familien je 40 PASS. Alle vier Läufe frisch bereinigt, je zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Keine neue API-/Client-/Vollmatrix-/Releaseabnahme |
| Interne CLR-Bindingdrift | acht einzelne NULL-Options-/Längen-/Namensänderungen an den drei internen Funktionen, je Deploy/Uninstall und exakte Restaurierung | Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 local/central jeweils erster Versuch PASS: je 32 Abweisungen SQL55324/state5/7, konkreter Katalogwitness, unveränderter erfasster Mutationszustand und Objektidentität, anschließend exakte Baseline. Je frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend. Keine vollständige Binding-/Driftmatrix oder neue Default-/API-/Client-/Minimalrechte-/Heap-/TLS-/Releaseabnahme |
| CLR-Parameterdefaults | fünf Defaults, je Deploy/Uninstall und Restaurierung | Finaler Windows2025/base-Nachweis CL170 mit erlaubtem bereitem CU-Äquivalent vom 2026-10-20 erhalten. Ergänzend Linux2019/latest CL150 am 2026-10-21 im ersten Versuch local/central mit aktuellem Assertionstand nach PR350 PASS: zehn Abweisungen pro Modus, 20 je Ziel SQL55324/state7; Basistyp/Wertbytes/Textbytelänge und separater NULL-Witness unmittelbar vor/nach Abweisung sowie vor Restore exakt, Baseline restauriert. Je frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Frühere sechs Defaults-Läufe und engere Orakel bleiben datiert erhalten; keine neue Gesamt-/Release-/Vollmatrixabnahme |
| Explizite SameDB-Verbraucher | fünf benannte Referenzen, je Deploy/Uninstall und geschützte Fixtureentfernung | Finaler Windows2025/base-Nachweis CL170 mit erlaubtem CU-Äquivalent vom 2026-10-20 erhalten. Ergänzend Linux2019/latest CL150 am 2026-10-21 im ersten Versuch local/central mit finalem Assertionstand PASS: zehn Abweisungen pro Modus, 20 je Ziel SQL55325/state3. Dependencyfingerprint unmittelbar vor/nach jeder Operation und vor Drop, exakte Zielnamen, zulässige lokale ID-/Namensbindung und geschützte Identitäten; Baseline exakt restauriert. Je frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Frühere engere Linux-/Windowsläufe und erster Linux-FAIL bleiben datiert erhalten; kein isolierter NULL-ID-Preflightzweig, keine Consumerausführung oder neue API-/Client-/Vollmatrixabnahme |
| Falsche Markerwerte |25 einzelne Wertänderungen, je Deploy/Uninstall und exakte Restaurierung | Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 jeweils erster Versuch local/central100 Abweisungen SQL55324/state2/4/5 PASS. Typisierte Erwartungs-/Wertbytes mit Länge, erfasster Zustand erhalten und Baseline exakt restauriert. Separate Linux-Markertypregression40 PASS. Je Lauf frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend; kein neuer Gesamt-/Vollmatrix-/Release-Nachweis |
| Falsche Schemamarkerwerte | Managed-int 1→0 und drei falsche Kategorien einschließlich Case/Padding, je Deploy/Uninstall und Restaurierung | 2026-10-21 Linux2019/latest CL150 und Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 jeweils erster Versuch local/central PASS: je 16 Abweisungen SQL55324/state1. Typisierte MaxLength-/DATALENGTH-/Wertbytesbindung, erfasster Zustand und neutrale Sitzung erhalten, Baseline exakt restauriert. Separate Linux-Markerwerteregression100 PASS. Alle drei Läufe frisch bereinigt, je zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Keine Rechte-/Owneränderung oder neue Gesamt-/Vollmatrix-/Releaseabnahme |
| CLR-Ausführungskontext | drei interne Funktionen einzeln mit OWNER-Metadatum, je Deploy/Uninstall und exakte Caller-Restaurierung |2026-10-20/21 Linux2019/latest CL150 und Windows2025/base mit erlaubtem CU-Äquivalent CL170 erster Versuch local/central je zwölf Abweisungen SQL55324/state5 PASS. Witness unmittelbar vor/nach Operation und vor Restore; Metadaten-/Defaultregressionen32/20 bestanden. Alle vier Läufe frisch bereinigt, je zwei eigene DBs/ein eigener Trusthash abwesend. Keine Funktionsausführung unter OWNER oder neue API-/Client-/Vollmatrix-/Releaseabnahme |
| Interne CLR-Rückgabelängen | skalare QuoteCell-Rückgabe und Parser-RowKind-Länge, je Deploy/Uninstall und exakte Restaurierung | 2026-10-21 Linux2019/latest CL150 und Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 jeweils erster Versuch local/central PASS: je acht Abweisungen SQL55324/state7. Konkreter parameter_id0-/column_id1-Längenwitness unmittelbar vor/nach Operation und vor Restore, Identität/CLR-Bindung/Ownership und erfasster Zustand erhalten, exakte Baseline. Separate Linux-Bindingregression32 PASS. Alle drei Läufe frisch bereinigt, je zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Keine Funktionsausführung unter abweichender Länge oder neue API-/Client-/Vollmatrix-/Releaseabnahme |
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
- Datum: `2026-10-21`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope shape-ceilings`
- Scope: Native tatsächliche Zeilen-/Spaltengrenzabnahme offen: vier Versuche FAILED_CLEANED. Linux2019/latest CL150 erster zusammengefasster Batch Timeout60; danach Linux und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent lokale Parserphase100000 bestanden, anschließende Writerphase100000 Timeout120, Windows zweiter Versuch auch bei300. Übrige Phasen/central nicht erreicht. Je frischer Audit eine eigene DB/ein eigener Trusthash abwesend, Konfiguration/Rechte/Inputs unverändert. Separate finale Linux-Defaultregression local/central mit drei SQLfixtures/Client/Consumer/29 Lifecyclefällen PASS, frischer Audit drei eigene DBs/ein eigener Trusthash abwesend. 509 Offlinekontrollen, acht SQL150-Phasen, AST/Static PASS. Unabhängiger Erstquellreview ohne semantische Findings; keine Engpassursache oder Laufzeitvertragsverletzung belegt. Produkt-/Deployment-/CLR-/Snapshotquellen und Workflow unverändert; Paket an Quellen/Binarybytes gebunden, kein neuer lokaler Build-/Frameworklauf. Keine vollständige tatsächliche Ceiling-/Heap-/Minimalrechte-/TLS-/Releaseabnahme.
- Ergebnis: `failed`
<!-- END GENERATED:MODULE_EVIDENCE -->
