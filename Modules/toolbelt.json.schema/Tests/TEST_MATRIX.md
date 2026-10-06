# JSON Schema – Abnahmematrix

## Schema-CI auf den ausgewählten Compatibility Levels

Der gekoppelte Linuxadapter prüft Schema1.0.1 jetzt in denselben bereits
gewählten CLs wie Constructors: SQL2019/CL150, SQL2022/CL160 und
SQL2025/CL150/160/170. Vor jedem Schema-Scope werden beide Providerdatenbanken
und der separate Consumer auf das jeweilige CL gesetzt und lesend geprüft.
Je CL laufen der genuine1.0.0-Upgradescope, Contract/Safety local/central,
CrossDB, Dependency-/Confirm0-Abweisungen und eigener Uninstall. Nach
verifizierter Modulabwesenheit wird die eigene Upgrade-Capture-Tabelle
entfernt; Core bleibt bis zum Abschluss aller Stufen erhalten.

Die vorhandenen Constructor-Lastfixtures werden innerhalb des neuen
Schema-Loops nicht nochmals ausgeführt. Binaries, Trusthashes, Produktcode,
Runtimefixtures, physische Ziele und Rechte bleiben unverändert. Der
vorhandene flüchtige CI-Container und Jobtimeout gelten weiter. Testcode
allein belegt keine native Ausführung; exakte Head-/Main-Ergebnisse werden
im zugehörigen PR dokumentiert. Der frühere83164b5-Nachweis bleibt auf
seinen damaligen CL-Scope begrenzt. Weitere physische Ziele, Minimalrechte,
volle Lifecycle-/Ressourcenmatrix und Release bleiben offen.

## Aktuelle Schema1.0.1-Wartung

| Bereich | Nachweis | Zustand |
|---|---|---|
| Profil, Priorität, Referenzen, Budget |169 Fälle/1275 Assertions je en-US/de-DE/tr-TR; codierte Schemaform-/Graphorte, escaped Keys, mehrstellige Indizes und unveränderte Instanzreihenfolge | bestanden offline am2026-10-06 |
| Exakte Zahlen |854 Fälle/6830 Assertions je drei Cultures | bestanden offline |
| Managed Bridge |120 Assertions je drei Cultures, Identität1.0.1.0 | bestanden offline |
| Schema-Binary |15 begrenzte Qualifikationsphasen, eigene IL, bytegleicher kanonischer Schema-Projektbuild und Input-/Produktpins | bestanden offline; kein erneuter Core-/Constructor-Gesamtlauf |
| Patchpaketierung |Final `package4`: acht positive/negative Orakel; fester Snapshotpin, Abweisung gültig neu gerahmter Constructorframes im Generator und Driver vor Ausgabe, historische Frames und erlaubte Schemafelder | bestanden offline; frühere sechs Fälle aus `package3` bleiben eigene Historie |
| Aktive Releasepaketierung |Drei Modulpositivfälle und sieben positive/negative Orakel des bisherigen Packagervertrags; stabile Pins | bestanden offline; keine erneute Core-/Constructor-Gesamtqualifikation |
| Historisches1.0.0-Paket |50 bytegenaue Originalblobs aus festem Commit,53 erfolgreiche Prozessphasen, exakte historische Binaryhashes; falsche Coreassembly und belegtes Ziel abgewiesen | bestanden offline; kein nativer Upgrade |
| Aktuelle T-SQL-Syntax |14 Batches/42 Assertions: Source, expandierte Lifecycle-Skripte und SQL-Fixtures in ScriptDom150/160/170 | bestanden offline |
| Treibersteuerung |PowerShell-/Bashsyntax,18 synthetische CI-Cleanupfälle und33 Selector-/Bindungsfälle | bestanden offline; kein Lab-/SQL-/Containerlauf |
| Direkter SQL-Aufruf |40 Contractfälle je local/central auf Linux SQL2019/CL150,2022/CL160,2025/CL170; Safety/CrossDB | PASS CI am83164b5 |
| Neuer Lifecycle |Genuine1.0.0→1.0.1, Mode-Abweisung, post-ALTER55699-Rollback, aktueller Uninstall alt/Reinstall/Upgrade/Repeat und Cleanup local/central | PASS im genannten CI-Scope; übrige Lifecyclematrix offen |
| Head-CI und weitere Matrix |Runtime37532174433 und Docs37532174428 am83164b5 PASS; weitere physische Ziele, Minimalrechte und Ressourcenqualifikation | Jeder spätere Head benötigt vor Integration eigene erfolgreiche Checks; übrige Matrix offen |

Die aktuelle Wartung erfüllt den bestehenden Pointer-Reihenfolgevertrag;
sie führt keine öffentliche API ein. Die folgenden1.0.0-Nachweise bleiben
historisch und qualifizieren die geänderte1.0.1-Assembly nicht.

`qual4` bestätigt die15 Phasen und die angegebenen Harnesszahlen nach der
Common-Härtung. `qual3`/`package3` waren erfolgreich, belegen jedoch den
früheren Scriptstand. Common bindet genau einen strict-UTF8-Byteinput an den
festen historischen Snapshot-SHA256; der finale Kandidat entspricht
semantisch exakt der aktiven Registry und ihren Binaryhashes.

Der erste [native CI-Versuch](NATIVE_EVIDENCE.md) am2026-10-06,
Head `58993f7012a0b458db377d7d4374b7bf162f0432`, scheiterte auf SQL2019/2022
mit Msg515 in UpgradeCapture Permissions. Die leere FOR-XML-Abfrage ergab
NULL. Capture und Verify normalisieren den leeren Katalog nun symmetrisch
auf `0x`; unabhängiger Review und ScriptDom14/42 bestanden. SQL2025
lief bei Erfassung noch; kein Gesamt-PASS. Der korrigierte
Head und die ergänzte Windows-CI-Qualifikation bleiben PENDING.

Nachtrag2026-10-06: Der erfolgreiche Nachweis am exakten
Head `83164b539e637deeb1ad21b74a15cad99e0184c1` bestätigt je SQL-Version
acht Upgrade-Witnesses, zweimal40 Contractfälle und zwei Safety-Witnesses,
ohne UnexpectedSQL/CleanupUnverified. Die breiteren SQL2025-Constructor-
CL150/160/170-Prüfungen erweitern die Schemaqualifikation nicht über CL170.
Die vorstehende erste Erfassung bleibt historische Evidenz.

## Historische Schema1.0.0-Qualifikation

| Bereich | Nachweis | Zustand |
|---|---|---|
| Profil, Priorität, Referenzen, Budget |159 Fälle/1174 Assertions je drei Cultures | bestanden offline |
| Exakte Zahlen |854 Fälle/6830 Assertions je drei Cultures, unabhängige rationale Vergleichsorakel | bestanden offline |
| Managed Bridge |120 Assertions je drei Cultures | bestanden offline |
| Closure | Eigene IL, kanonische bytegleiche Builds, bekannte Source-/Binarypins | bestanden offline |
| T-SQL | Source und expandierte Lifecycle-Skripte in ScriptDom150/160/170 | bestanden offline |
| Direkter SQL-Aufruf |30 native Contractfälle auf Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 jeweils local/central; Pointer über4000 UTF16-Einheiten mit Escape und NUL bytegenau | bestanden im begrenzten Scope |
| ResultTable | Zehn Typen/Ordinals, KeepData, echte Constraintfehler mit Ownrollback/Caller-Savepoint/doomed-Erhalt | beide Ziele local/central bestanden; Minimalrechte offen |
| Help und API-Metadaten | Help zuerst, echte Clientreader mit zehn Typen/Ordinals, parameterisierte dynamische Bridge | bestanden auf beiden Zielen local/central |
| Grenzen | Tiefe129, Budget1, MaxErrors0/1, Diagnosetrunkierung und abgesenkte Bytegrenzen/Fehlerpriorität in30 Contractfällen | bestanden auf beiden Zielen local/central; maximale Bytegrenzen separat offen |
| Lifecycle | local/central, Repeat, zwei Consumer-Abweisungen, Uninstall/Repeat und Coreidentität | bestanden auf beiden Zielen; Fremdslot-/Marker-/Owner-/Lockvollmatrix offen |
| Constructorsmigration | Genuine bekannte1.2→1.3, fünf Procedure-ObjectIds/Rechte und effektive Owner erhalten; drei CLR-Slots/Assembly atomar neu, post-DROP-Rollback | beide Ziele local/central bestanden |
| Plattformmatrix | SQL2019/2022/2025; CL150/160/170 soweit unterstützt; Windows/Linux | Lab: Linux2019 CL150 und Windows2025 CU8 CL150/160/170; separate PR176-CI Linux2019/2022/2025 bestanden |

Der gekoppelte Linux-CI-Adapter definiert zusätzlich einen zentralen
Schema-Installations- und Repeat-Pfad mit `Contract.Tests.sql` und
`Safety.Tests.sql`, einen dreiteiligen Aufruf aus einer separaten synthetischen
Consumer-Datenbank sowie Core-/Schema-Uninstall-Abweisungen vor dem regulären
Abbau. Dies ist ein begrenzter CI-Scope; erst ein erfolgreicher Lauf am exakten
Änderungs-Head belegt seine Ausführung. Die vollständige physische Lifecycle-
und Ressourcenmatrix wird dadurch nicht ersetzt.

Die Offline-Driver besitzen endliche Prozessbudgets, prüfen tatsächliche
Exitcodes und Capture und schreiben private Evidenz ausschließlich in neue,
ignorierte `.runtime`-Verzeichnisse. SQL-Testziele werden erst aus dem
schema-validierten Labvertrag ausdrücklich ausgewählt. Neue Trusthashes
werden exakt identifiziert; die aktuelle Schema-Testwelle besitzt die
[fortgeltende Benutzerfreigabe](../Documentation/TRUST_UNICODE_BINDING_OPT_IN.md).
Kein Infrastruktur- oder Produktionsbetrieb. Frühere6552-/Fixture-/Cleanup-
und6282-Migrationsfehlläufe bleiben getrennte Fehlerhistorie.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37532174433`
- Scope: Schema1.0.1 am exakten Head83164b539e637deeb1ad21b74a15cad99e0184c1: Windows und Linux-SQL2019/CL150,2022/CL160,2025/CL170 PASS. Schema je SQL-Version local/central: genuine1.0.0-DLL, Mode-Abweisung, erwarteter post-ALTER55699-Rollback, aktueller Uninstall alt/Reinstall/Upgrade/Repeat, zweimal40 Contractfälle, Safety, CrossDB und Cleanup; je acht Upgrade- und zwei Safety-Witnesses, kein UnexpectedSQL/CleanupUnverified-Witness. SQLCMD-Dateifaulttransport im tatsächlichen Testpfad bestanden. Breitere Constructor-CL-Matrix ist kein Schema-Nachweis. Docs37532174428 am selben Head PASS; frühere failed/PENDING-Records bleiben Historie, Actual168-Rootcause nicht bewiesen. Neuer Dokumentationshead benötigt eigene exakte CI; übrige physische-/Minimalrechte-/Lifecycle-/Kapazitätsmatrix und Release offen. Partially validated, unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
