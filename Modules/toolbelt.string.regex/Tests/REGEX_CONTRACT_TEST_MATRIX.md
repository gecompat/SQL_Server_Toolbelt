# Regex-Contract-Testmatrix

## Capture-/Replace-Zusatzscope 1.3.0

| Bereich | Pflichtnachweis |
|---|---|
| Captures | Linksöffnende gemischte Gruppenordinals, Namen, alle Wiederholungen, Backtracking entfernt verworfene Captures, Sentinel/Empty, UTF16, Start und terminale Treffer |
| Replace | Strikte `$1`/`${Name}`/`$$`, ganze Ordinalziffernfolge, letzter Capture, unmatched leer, unbekannte Referenzen vor Suche, NULL/Fehlerpriorität, altes literales Replace unverändert |
| History | Konservative L-basierte saturierte Pfadformel vor Enginekonstruktion, finite-nullable/Zeroquantifier/Alternation/Nesting, unbounded-nullable-Capture abweisen; keine Heap-/Backtrackingzusage |
| Grenzen | Framework tatsächlich 100000 Captures, verschachtelte 99099 Captures, Standard/Large Name-plus-Value-Charge, atomare Rückgabe, gemeinsame Budgetprüfung |
| SQLClient | Acht nullable Spalten, Typen/Größen/Parameterreihenfolge, Defaults, kein Zusatzresult/Message, Fehler ohne erste verwertbare Zeile |
| Lifecycle | Frische Ownership-Prüfung unter gemeinsamem AppLock, Caller-TX/Optionserhalt, Failure-Rollback, versionsgebundene 3/7/11/15 Slots, genuine 1.2 Upgrade, fremde künftige Slots und Schema, Marker/Dependency/Uninstall/Cleanup |

Integrierte Framework-Suite und finaler Gesamtadapter am 2026-10-02 erfolgreich:
Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral,
einschließlich echtem 1.2-Upgrade, Reinstall, erwarteter Binaryhashbindung,
Caller-TX/Optionserhalt, AppLock, post-DROP-Rollback, Kollisionen, Dependencies,
Uninstall und eigenem DB-/Trustcleanup. Neue Capture-Minimalrechte, weitere
Ziele und die tatsächliche große SQL-Capture-Ausgabegrenze bleiben offen;
CI steht aus. Historische Matrixnachweise
qualifizieren keine neu hinzugefügte Capture-API.

## R2b-Zusatzscope 1.2.0

Framework-Build und relationaler Frameworkvertrag am 2026-10-01 PASS;
keine SQL-SAFE-Evidence allein daraus. Der vollständige Adapter lief am
2026-10-01 auf SQL Server 2025 Windows/CU8 bei CL150/160/170 und SQL Server
2019 Linux/latest CL150 erfolgreich. Weitere R2b-Ziele und Lowpriv-CrossDB
bleiben offen; SQL-100k-Durchsatz bleibt `not executed`.

| Bereich | Pflichtnachweis |
|---|---|
| Gesamttreffer | Schema, Ordinals, Start/UTF16/kein Treffer/NULL/terminaler Leerwert |
| Split | ganze Quelle, Originalbytes, leere Rand-/Zwischentokens, unabhängiger Suchcursor, Empty-Input, Anker, gemischte leere/konsumierte Separatoren |
| Grenzen | Framework: echte 100000 Zeilen; SQL: gezielte High-Volume-Probe entweder vollständig oder exakt atomarer TBX_REGEX_TIMEOUT, keine 100k-Durchsatzgarantie; 16 MiB Quelle/Output; kleine MaxRows-Grenzfälle strikt; NULL/Flags/Patternpriorität |
| SQLClient | tatsächliche vier Typen/max-Längen/nullable-Metadaten, nicht-NULL-Erfolgswerte, kein Zusatzresult/Message, Fehler vor erster verwertbarer Zeile |
| Lifecycle | genuine 1.0 und 1.1, vier neue Namenskollisionen inklusive imitiertem Marker, Erhalt bei historischem Uninstall, 1.2-Reinstall, interne Marker und Dependency-Uninstall |
| Rechte | lokale/direkt zentrale SELECT-Minimalrechte; kein pauschaler Lowpriv-CrossDB-Nachweis |

| Bereich | Pflichtnachweis |
|---|---|
| CLR | .NET Framework 4.8, nur System/System.Data, SAFE, identischer Provider auf Windows/Linux |
| Dialekt | Literale, Escapes, Punkt, Klassen/Bereiche/Negation, Gruppen, Alternation, Anker, Quantifier bis 1.000 |
| Klassen | ASCII-`\d`/`\s`/`\w`, Unicode-`\p{L}` |
| Flags | `c`, `i`, `m`, `s`, keine Duplikate, kulturinvariantes IgnoreCase |
| IsMatch | Treffer, Nichttreffer und NULL-Propagation |
| Instr | Start, Occurrence, Start-/Ende-exklusiv, 0 ohne Treffer, UTF-16-Positionen |
| Count | nicht überlappend, Startposition und Empty-Match-Fortschritt |
| Abweisung | Backreferences, Lookaround, benannte/atomare/bedingte/Balancing Groups und beliebige .NET-Syntax |
| Grenzen | Input 2 MiB, Pattern 8.000 Bytes, Quantifier 1.000, fester Timeout 250 ms |
| Fehler | SQL 6522 mit stabilem `TBX_REGEX_*`-Präfix |
| Lifecycle | exakter SHA2-512-Trust, Erst-/Wiederholungsdeployment, Kollision, Central, Uninstall, Cleanup |
| Matrix | SQL Server 2019/2022/2025 auf Windows base und Linux latest |
| R2a | Literal Replace, n-ter Gesamttreffer, DEFAULT/EXEC, NULL-Prio, Start/Occurrence, terminale und leere Treffer |
| R2a-Grenzen | Quelle/Ersatz/Output 2/16 MiB, Pattern 8.000/8.001 Codeeinheiten, Gruppen 64/65, Alternation 1.024/1.025 |
| Gesamtbudget | Framework-Whitebox qualifiziert Restbudget und viele Empty-Matches; SQL-ReDoS prüft Engine-Timeout |
| Codepages | Klassisches/UTF-8-varchar vor Centralcall nach Unicode dekodiert; n-Collationvergleich ausdrücklich festgelegt |
| Upgrade | Echtes gepinntes 1.0.0-Binary nach 1.1.0; neue Slotkollision ohne Mutation; Dependency-Schutz und interne Marker |
| LOB-Concurrency | Vier echte Sitzungen mit synthetischen Large-LOBs; keine gemessene Performancezusage |

RE2-Parität, lineare Laufzeit, SARGability, Parallelplanfähigkeit, Replace,
Substring, Capture-Ausgabe, Split und Match-Resultsets sind keine R1b-Tests.

Die vollständige Pflichtmatrix wurde am 2026-08-30 über
`local: Tests/CI/run-lab-local.ps1` erfolgreich ausgeführt. Alle Testdaten
waren synthetisch; erzeugte Objekte und neue Trust-Einträge wurden entfernt,
die Lab-Umgebungen nicht beendet.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-regex-captures-lab.ps1; Windows PowerShell: Tests/Framework/run-framework-captures.ps1`
- Scope: Finaler Capture/Replace-Gesamtadapter lokal/zentral auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170: sieben alte und zwei neue APIs, unabhängige Orakel, SQLClient acht nullable Spalten/Defaults/Atomicity, Standard-Namenscharge, echter 1.2-zu-1.3-Upgrade, Reinstall, explizite erwartete SHA2_512-Binaryhashbindung, Caller-TX/SET-Erhalt, AppLock, post-DROP-Rollback, Versions-/Marker-/Future-Slot-/Schema-Kollisionen, Dependencies, Uninstall und verifiziertes eigenes DB-/Trustcleanup. Framework tatsächlich 100000 Captures und Standard/Large. Frühere API-only- und fehlgeschlagene Adapterstände bleiben historische Evidenz. Neue Capture-Minimalrechte, weitere Ziele, ältere 1.0/1.1-Capture-Upgrades, tatsächliche große SQL-Capture-Ausgabe und SQL-100k-Durchsatz nicht ausgeführt; CI ausstehend, teilweise validiert/unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
