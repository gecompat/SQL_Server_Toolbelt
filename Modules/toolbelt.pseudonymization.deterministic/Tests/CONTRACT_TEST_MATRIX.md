# Contract-Testmatrix: deterministische Zuordnung 1.0.0

Diese Matrix beschreibt Pflichtfälle, nicht deren automatische Erfüllung.
Ausgeführte Teilprüfungen und Befehle: [Tests/README](README.md).

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
| Plattformen | risikobasiert2019 Linux CL150 und2025 Windows CU8 CL150/160/170 | final2019 Linux PASS; finaler Safetyfix-Windowsbaum noch nicht ausgeführt |
| Weitere Scopegrenzen | SQL2022 und weitere physische Plattformen; CrossDB-Minimalrechte; Produktionskapazität und100000-Zeilen-Durchsatz | not executed; keine Ableitung aus Small- oder Referenztests |

Row-/LOB-Grenzen begrenzen fachliche Arbeit, nicht den gesamten SQL-Memory-
Grant, TempDB-Verbrauch oder die Wallclock. Keine Performancevergleiche aus
überlappenden beziehungsweise nicht qualifizierten Lab-Läufen ableiten.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Finaler Safetyfix-Adapter SQL Server 2019 Linux/latest CL150; API/Fehler/Grenzen/Transaktionen, vier Caller-Temp-Eclipsing/Help-Fixtures, Installer-Callertransaction ON/OFF und SQLCMD-nonzero, Local-CS/Central-BIN2, administrative CrossDB-CI, direkte Minimalrechte und Clientmetadaten lokal/zentral, Wiederholung/Drift/Kollision/Dependency/Uninstall; finaler Windowsbaum und weitere physische Targets offen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
