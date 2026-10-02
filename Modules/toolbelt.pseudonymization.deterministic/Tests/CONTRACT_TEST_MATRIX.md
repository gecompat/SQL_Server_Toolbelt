# Contract-Testmatrix: deterministische Zuordnung

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
- Nachweis: `local: Tests/CI/run-deterministic-translate-lab.ps1`
- Scope: Version 1.1.0: vollständiger Linux2019/latest CL150 local/central; bestehende APIregressionen, Translate/21Safetybatches/vier Caller-Collations/echte2MiB+16MiB/Metadaten, genuine1.0Upgrade/FirstInstall/Repeat/CallerTX/Snapshot-Faults/fremdeFutureSlots/historischerUninstall/CrossDB/ownCleanup; Windows2025/CU8 vollständiger central-Adapter CL150/160/170 PASS; lokale APIs/Safety im früheren insgesamt fehlgeschlagenen Lauf bestanden, separater korrigierter lokaler Metadaten-/Lifecycleadapter PASS; keine neuen Lab-Grants/Serverkonfiguration, weitere Targets/Minimalrechte/CI offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
