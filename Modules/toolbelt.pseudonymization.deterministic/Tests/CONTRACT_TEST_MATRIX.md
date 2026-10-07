# Contract-Testmatrix: deterministische Zuordnung

## Exakter Compatibility-Level-Opt-in der vorhandenen CI

Die sechs vorhandenen Linux-Jobs setzen ihren validierten Compatibility Level
jeweils vor dem ersten SQL-Skript der 13 eigenen Datenbanken, einschliesslich
Central-Consumer und historischer Kollisionsziele. Existenz und exakter Level
werden frisch geprueft; fehlende Sicht, NULL oder Abweichung blockiert. Vor
jedem SQL-Skript wird erneut geprueft, auch im erwarteten Fehlerpfad mit
abgeschaltetem `errexit`. Der Gatewert stammt aus dem validierten Opt-in,
nicht aus einem veraenderlichen Phasenlabel.

Ohne `TBX_SQL_COMPATIBILITY_LEVEL` bleibt der historische Multi-Level-Pfad:
API-Schleifen wechseln die Levels, vorherige Deploys und eigene Negativziele
sind weiterhin kein Nachweis auf allen Levels. Neue exakte Head-/Main-CI bleibt
im zugehoerigen PR separat nachzuweisen. Produkt-SQL, Fixtures, sechs Jobs und
30-Minuten-Frist bleiben unveraendert; keine Lab-/Rechte-/Trustausweitung.

## Eigener Container-Cleanup der bestehenden CI

Der Runnername bindet Run, Attempt, SQL-Version und gewaehlten Level; ohne
exakten Opt-in steht `all` fuer den bisherigen Multi-Level-Pfad. Ein zufaelliges
Ownerlabel und die vollstaendige Container-ID werden gemeinsam frisch gelesen.
Nur ein eigener Owner erlaubt die Entfernung per ID. Frische Abwesenheit am
exakten Namen ist Pflicht; fremder Owner, unlesbare/ungueltige Identitaet,
fehlgeschlagenes rm oder unklarer Abschluss fuehren zu
`DETERMINISTIC_CI_CLEANUP_UNVERIFIED` und Fehlerstatus. Bestaetigter Cleanup
meldet `DETERMINISTIC_CI_CLEANUP_VERIFIED` und erhaelt den urspruenglichen
Payloadstatus. Der Lab-Fruehabbruch bleibt unveraendert; keine
Hard-Interrupt-/Host-Recoverygarantie.

Die bestehende source-extracted Offlineprobe prueft mit
`python Tests/CI/test_owned_container_cleanup.py --module deterministic`
13 ausgewaehlte synthetische Cleanupfaelle ohne Docker/SQL. Echte Head-/Main-CI
und ihre festen Cleanupzeugen bleiben separat im PR nachzuweisen.

## Additiver GeoJitter-Slice 1.2.0

| Scope | Pflichtfälle | Nachweis am 2026-10-02 |
|---|---|---|
| Modell/Framing | bestehender Range-V1-Kern, zwei Kontexte, Kugelkappen-CDF, unabhängige Winkel-/Metrikreferenz, feste Koordinaten | private Vorqualifikation 10.685 Assertions; integrierte unabhängige Referenz 6.367 Assertions PASS; kein SQL-Nachweis |
| Native Operanden | Invalid/Empty/non-Point/SRID/Z/M, sichere Kette, tatsächliche 128-/größere UDTs | Vor-Source-Primitive und finale Safety-API auf beiden ausgewählten Plattformen PASS; exakt 129-Byte-UDT unbeobachtet |
| API/Metadaten | Geo-Vertrag mit ursprünglichen fünf Batches/504 Orakeln, Safety, InstalledMetadata sowie Clientmetadaten | Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral PASS; ausdrücklich drei Runtime-Fixtures |
| Lifecycle | echte 1.0-/1.1-Upgrades, acht Slots, Erst-/Wiederholungsinstallation, Caller-TX/SET, Snapshot-Faults, Zukunftsslots, Uninstall | beide finalen ausgewählten Adapter PASS; eigene Datenbanken bereinigt, keine Konfigurations-/Rechteänderungen |
| Rechte/Matrix/CI | neue Minimalrechte, übrige physische Matrix, aktueller Head | offen; aktuelle CI als separater PR-Mergegate am exakten Head nachzuweisen |

Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.

Historische Zwischenstände vom 2026-10-02: Die ursprüngliche Ausdrucksform und kleinere Zwischenkandidaten scheiterten mit SQL-Fehler 701; ein späterer Lauf endete mit Timeout -2. Diese Läufe bleiben fehlgeschlagen, eine allgemeine Compilerursache ist nicht nachgewiesen. Der historische Vector-Facts-Kandidat bestand auf Linux mit einer vorübergehenden Partitionierung: 72 Gruppen mit je sieben Radiuswerten, zusammen dieselben 504 Orakel, eingebettet in 78 Batches einschließlich Metadaten/Goldens/Defaults, Setup, globalem Coverage-Orakel und Wiederholung. Dieser Zwischenbeleg ersetzt den finalen Nachweis der ursprünglichen fünf Batches nicht.

## Translate: nachfolgender CI-Abschluss

[PR #140](https://github.com/gecompat/SQL_Server_Toolbelt/pull/140) belegt
Merge und sieben erfolgreiche Prüfungen am finalen 1.1-Head. Die folgende
Matrix bewahrt den davor dokumentierten Lab-Snapshot. Kein Geo-Nachweis.

## Additiver Translate-Slice 1.1.0

| Scope | Pflichtfälle | Nachweis am 2026-10-02 |
|---|---|---|
| Format/Mapping | feste 22-Byte-Frames, signed Grenzen, 36 logische Mappingeingaben, Digest-/Ordinalranking, Casekopplung und Bijektion | private Vorqualifikation unabhängig wiederholt 5.540 Assertions; integrierte Referenzsuite 1.746 Assertions; feste SQL-Vektoren Linux2019 und Windows2025 lokal PASS |
| API/Metadaten | echter IF-Typ, fünf Parameter/Defaults, genau eine nullable Value-/nicht-nullable ErrorCode-Zeile, nvarchar(max)/BIN2 | SQL- und Clientmetadaten Linux2019 local/central und Windows2025 central CL150/160/170 sowie separat korrigierter local-Adapter PASS |
| Fehler/Optimizer | NULL zuerst, vollständige Fehlerpriorität, bytegenaue Profile/Separatoren, sichere native Operanden, Konstanten/APPLY/äußerer CASE | 21 getrennte unabhängige Safetybatches Linux2019 local/central und Windows2025 local/central CL150/160/170 PASS; local-APIteil im früheren Gesamtfehllauf |
| Collation | Caller BIN2, CS_AS, CI_AS_SC, CI_AS_SC_UTF8; NUL/Surrogates/trailing Spaces | je fünf integrierte Fälle pro Collation in Safetyfixture PASS im obigen Scope |
| Budgets | 33/+1 Separatoren; Standard 2MiB und large 16MiB exakt/+1; letzte unbekannte Codeunit; vollständige Ausgabebytes | tatsächliche SQL-LOBs und Hash-/Längenorakel PASS im obigen Scope; keine Heap-/Zeit-/Produktionskapazitätszusage |
| Lifecycle | genuine unverändertes 1.0 mit sechs Slots →1.1 mit sieben Slots; frische Installation/Wiederholung; CallerTX ON/OFF; Marker-/Dependency-/Confirm-Snapshots; Zukunftsslots selbst mit imitierten Markern ablehnen; historischer Uninstall bewahrt fremden Slot | Linux2019 local/central und Windows2025 central sowie separat korrigierter local-Adapter PASS; genuine Fixture gegen öffentlichen Commit geprüft |
| Central | identischer Source, administrative dreiteilige Aufrufe aus CI_AS_SC_UTF8-Consumer, Original-Clientmetadaten/Help/Tempguard | vollständiger Adapter Linux2019 CL150 und Windows2025 CL150/160/170 PASS |
| Rechte/weitere Targets | neue direkte/CrossDB-Minimalrechte; weitere physische Windows-/Linux-Ziele | im neuen Labscope not executed, keine Grants; historische 1.0-Rechtebelege qualifizieren Translate nicht |
| CI/Release | erforderliche grüne CI auf aktuellem Head; keine Veröffentlichung | CI noch offen, unreleased |

Der unveränderte Source besteht die qualifizierten Teilprüfungen. Frühere
Adapterläufe scheiterten an sessionübergreifenden Testtemps bzw. dem gebündelten
Safetybatch; diese Läufe sind kein Gesamt-PASS. Separate Sessions und Batches
behalten die strengen Orakel und unveränderten Testtimeouts. Eigene Datenbanken
abgeschlossener Läufe wurden entfernt, keine Serverkonfiguration/Rechte geändert.

## Historischer 1.0.0-Scope

Diese Matrix beschreibt Pflichtfälle, nicht deren automatische Erfüllung.
Ausgeführte Teilprüfungen und Befehle: [Tests/README](README.md).
Der identische finale Adapter bestand am 2026-10-02 außerdem unter
SQL Server 2025 Windows/CU8 CL150/160/170. Die folgenden Linux-Fallnachweise
gelten in diesem identischen Adapter auch dort, nicht für weitere Targets.

| Scope | Pflichtfälle | Aktueller Nachweis |
|---|---|---|
| Range | echter IF-Typ; genau eine Value/ErrorCode-Zeile; NULL zuerst; Mapping/Seed/Bounds/Key-Priorität; voller bigint-Bereich; Singleton; 8000/8001 Byte; stabile unabhängige Vektoren einschließlich zwei verworfener Kandidaten | finaler Linux2019 CL150 PASS (2026-10-02) |
| Encoder/Framing | explizites Big-endian-Zweierkomplement; negatives Seed/Bounds; feste Kontext-/Längenfelder; SHA256-Frame über 8000 Byte ohne Kürzung | Referenz und finaler Linux2019 PASS |
| Rejection | höchstens 128 Kandidaten; erster akzeptierter Kandidat; nichtuniforme Modulo-Verzerrung vermeiden; erschöpfte Reihe liefert Code5/NULL | Referenz-Exhaustion PASS; reale SQL-Exhaustion nicht erzwungen |
| DateShift | gleicher Entityoffset/Abstand/Uhrzeit/Scale7; MaxDays0; Defaults; 3652058/3652059; NULL zuerst; Unter-/Obergrenzenoverflow ohne Clamp | Rand-/Default-/Overflowfälle final Linux2019 PASS; gültiges MaxDays-Ceiling zusätzlich offen |
| Lookup | positive eindeutige bigint-Ordinals/Gaps; binäre Keyidentität; unabhängiger Lookupdomain-Vektor; explizite Poolversion; physische Reihenfolge irrelevant; NULL-Key versus NULL-Pooltext; leerer Pool Fehler; leerer Input0 Zeilen | final Linux2019 PASS einschließlich unabhängigen Lookupvektors |
| Fehler/Ressourcen | exakte Nummer und State; Konfiguration vor Names; begrenzter Vorabscan; Row-/Text-/Resultbudgets; 8000/8001-Key; vollständiger Fehler vor Zielmutation | finale Small-/Boundary-/Atomaritäts-Oracles Linux2019 PASS; Maximaldurchsatz offen |
| StandardUSP | Hilfe zuerst, 12 Spalten/13 Parameter/3 Resultspalten, technische Defaults; NULL-Flags; Debug nur Messages; SELECT genau ein Resultset; ResultTable kein SELECT | finale Clientprobe Linux2019 lokal/zentral PASS, einschließlich vier Caller-Temp-Eclipsing-/Help-Fixtures |
| ResultTable | beliebige Dummyspalte; alle KeepData-Konstellationen; Replace auch befüllt/schemafremd; Indizes bleiben; blockierende Dependencies vor Mutation; verschachtelter Aufruf ohne INSERT EXEC | Replace/Append/NULL/Metadaten und tatsächlicher Insertfehler final Linux2019 PASS; zusätzliche Dependencies offen |
| Transaktionen | eigener Commit vor SELECT; Caller-@@TRANCOUNT/XACT_STATE erhalten; eigener Savepoint erst nach Erfolg; fachliche Fehler und tatsächliche Insertfehler atomar; Callerrollback | Caller-Erfolg/-Fehler/-Rollback und eigener Insertfehler final Linux2019 PASS; Installer ON/OFF Count/State/Data/Options plus SQLCMD-nonzero PASS |
| API/Marker/Rechte | tatsächliche Parameter/Typen/Ordinals; alle sechs Objekte und interne Sichtbarkeit; Marker/diagnostische Hashes; SELECT öffentliche IFs und EXEC Lookup/Helper unter synthetischem WITHOUT LOGIN-User | final Linux2019 PASS |
| Local/Central | identischer kanonischer Kern; direkt zentral und dreiteiliger Calleraufruf; abweichende Datenbank-/TempDB-Collations; ResultTable | local CS, central BIN2, administrative CrossDB-CI final Linux2019 PASS; CrossDB-Minimalrechte offen |
| Lifecycle | Erstinstallation; gleiche Version; Source- und IF/TF/FN-Drift; fremde Namenskollision auch CI-Casing; malformed/unknown Marker; fehlende Dependency; own dependency ausgeschlossen; fremde Dependency blockiert; Central-Confirmation; SharedSchema bewahren | Deploy/Repeat/Source-/FN-Drift/Kollision/Dependency/Uninstall/Confirmation final Linux2019 PASS; TF-Drift und weitere Markerfälle offen |
| Historisches Upgrade | jede unterstützte echte Vorgängerversion | not applicable: erstes Release, keine Vorgängerversion |
| Plattformen | risikobasiert2019 Linux CL150 und2025 Windows CU8 CL150/160/170 | identischer finaler Safetyfixbaum beide Targets PASS (2026-10-02) |
| Weitere Scopegrenzen | SQL2022 und weitere physische Plattformen; CrossDB-Minimalrechte; Produktionskapazität und100000-Zeilen-Durchsatz | not executed; keine Ableitung aus Small- oder Referenztests |

Row-/LOB-Grenzen begrenzen fachliche Arbeit, nicht den gesamten SQL-Memory-
Grant, TempDB-Verbrauch oder die Wallclock. Keine Performancevergleiche aus
überlappenden beziehungsweise nicht qualifizierten Lab-Läufen ableiten.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-deterministic-geo-lab.ps1`
- Scope: Version 1.2.0: Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 lokal/zentral PASS; ausdrücklich GeoJitter.Contract.sql (ursprüngliche fünf unpartitionierte Batches/504 Orakel), GeoJitter.Safety.sql, InstalledMetadata.Contract.sql plus Client-/SQLmetadaten, echte1.0/1.1-Upgrades, FirstInstall/Repeat/CallerTX-SET/Snapshot-Faults/FutureSlots/Uninstall/ownCleanup; alte sieben Source-Dateien bytegleich, kein erneuter finaler Vollfamilien-Runtime-Nachweis; keine Konfigurations-/Rechteänderungen, neue Minimalrechte/weitere Targets/exakt129ByteUDT offen; aktueller CI-/PR-Mergegate am exakten Head separat nachzuweisen; unreleased
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
