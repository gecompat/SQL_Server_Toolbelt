# JSON Pointer – Tests

Die [Testmatrix](JSON_POINTER_TEST_MATRIX.md) trennt feste synthetische Oracles,
Metadaten, Lifecycle und tatsächliche Ausführung. Code allein ist kein Nachweis.
Der [kanonische Vertrag](../../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
definiert Fehlerpriorität und die zugelassene MSTVF-Ausnahme.

Contract/Safety verwenden feste Status-/Wertoracles unter vier Inputcollations
mit CROSS/OUTER APPLY. Unicode entsteht aus synthetischen UTF16-Binarybytes.
SQLCMD `ToolbeltDatabase` ist leer für currentDB oder bindet den expliziten
zentralen Provider. Technische Enginefehler gelten als FAIL.

Metadata erhält eine offene SqlConnection und optionale Timeout-/Readbudget-
Callbacks. Lifecycle.Tests.sql prüft ausschließlich die installierte Baseline.
Der eigene Labadapter besitzt Erst-/Repeat-/Uninstall, Callerzustände,
AppLock, Rollbackinjektionen, Marker-/Fremdslotwiederherstellung, Confirm0,
zentralen Consumer sowie streng journalgebundene eigene Bereinigung.
Produkt-DDL wird direkt ausgeführt; künstliche Faultseams sind Testvorbereitung.

`run-json-pointer-lab.ps1 -QualificationScope lifecycle` qualifiziert
unabhängig die installierte Baseline, echte Clientmetadaten und42 gezielte
Lifecyclefälle bei beiden Modi. Contract/Safety bleiben in diesem Scope
ausdrücklich NOT_EXECUTED; eine erfolgreiche Lifecycle-Prüfung löst die
notwendige vollständige Contract-/Safetyqualifikation nicht. Default `full` enthält weiterhin alle
drei SQLfixtures. Das private Journal hält Scope und tatsächliche Fixtures fest.

Statisch: `python Modules/toolbelt.json.pointer/Tests/Static/validate_contract.py`.
Der pfadbezogene Dokumentationsworkflow führt diesen Source-/Deploymentvertrag
bei Änderungen am JSON-Pointer-Modul ebenfalls aus; das ist kein SQL-Runtime-
oder vollständiger exakter Head-CI-Nachweis.
`Tests/CI/Test-LabDriverArgumentCase.ps1` prüft die Parameterbindung des
Labtreibers mit synthetischen Argumenten ohne Verbindung zum Lab.
Der kanonische Deploymentgenerator wird dabei nicht schreibend geprüft.
Der [Pointer-Runtime-Workflow](../../../.github/workflows/json-pointer-runtime.yml)
prüft in flüchtigen Linux-SQL-Server-Containern 2019/2022/2025 die zulässigen
Compatibility Levels mit local/central/Consumer: feste Contract-/Safety-
Fixtures, Clientmetadaten, installierte Baseline, Repeat und Uninstall.
Ein eigener Grenzfall erzeugt 16 MiB plus eine UTF-16-Codeeinheit und verlangt
vor Syntaxprüfung genau `INVALID/INPUT_LIMIT` ohne Rückgabe des Inputs. Dies
qualifiziert die Abweisung oberhalb der Grenze, nicht die Verarbeitung eines
vollen 16-MiB-Dokuments oder dessen Heap-/Laufzeitkosten.
Der separat per `workflow_dispatch` wählbare Lastfall nutzt
`Tests/CI/run_max_workload.py` und genau einen eigenen flüchtigen Container.
Die Größen-/Formstufen und Abbruchregeln stehen in der
[Testmatrix](JSON_POINTER_TEST_MATRIX.md). Ein nicht ausgeführter oder
abgebrochener Lastfall bleibt ausdrücklich ohne Maximalworkload-Nachweis.
Der ebenfalls manuelle `nested`-Modus prüft feste Tiefenstufen bis128 mit
eigener Container-Speichergrenze. Die Testmatrix trennt lokale Proben von
den später erfolgreich manuell ausgelösten GitHub-Dispatches und weiteren
offenen Lastformen.
Der manuelle `array`-Modus adressiert einen langen String unter `/0`. Lokal
ist nur die 64-KiB-Stufe einschließlich eigenem Cleanup und separatem
Regressionstest der bisherigen Formen belegt; ein 16-MiB-Arraylauf wurde
noch nicht ausgeführt.
Eine getrennte lokale Abbruchprobe in `Tests/CI/test_hard_interrupt_recovery.py`
prüft nur die Owner-Label-Bereinigung durch einen weiterlaufenden Elternprozess
nach hartem Kindprozessabbruch; Umfang und offene Fälle stehen in der
[Testmatrix](JSON_POINTER_TEST_MATRIX.md). Sie läuft nicht im regulären CI-
oder Lastworkflow und belegt keine Recovery nach Runner- oder Hostausfall.
Der CI-Adapter weist außerdem den zentralen Uninstall ohne explizite
Consumerbestätigung mit `55526/state1` ab und prüft danach die installierte
Baseline erneut, bevor der bestätigte Uninstall ausgeführt wird.
Ein synthetisch auf `9.9.9` gesetzter Release-Marker muss sowohl Deploy als
auch Uninstall mit `55524/state2` abweisen. Der Marker und die TVF bleiben
erhalten; nach Wiederherstellung des eigenen Markers besteht die Baseline.
Deploy und Uninstall werden zudem im zentralen CI-Provider mit bereits offener
Aufrufertransaktion gestartet. Beide müssen am frühen Gate mit
`50000/state1` und dem Pointer-Caller-Präfix abbrechen; nach jedem Abbruch
bleibt die installierte Baseline erhalten. Der SQLCMD-Verbindungsabbruch
belegt keine Erhaltung der Aufrufertransaktion oder ihrer SET-Optionen;
diese Zustandsoracles liegen im separaten physischen Labadapter.
Der reguläre flüchtige CI-Container trägt eine zufällige Owner-Kennung. Beim
normalen Prozessende wird er nur bei exakt passender Kennung entfernt; eine
frische Docker-Abfrage muss seine Abwesenheit bestätigen, sonst schlägt der
CI-Job fehl. Das ist kein Recoverybeweis nach hartem Runner-/Hostausfall.

`python Tests/CI/test_owned_container_cleanup.py` prüft zusätzlich beide
Modul-Cleanupfunktionen mit synthetischen Dockerantworten: eigener oder
fremder Owner, Daemon-/Entfernungsfehler, bereits fehlender Container und
Erhalt eines ursprünglichen Testfehlers. Die Dokumentations-CI startet diesen
isolierten Test bei Änderungen an einem der beiden CI-Adapter oder dem Test.

Ein synthetischer View im zentralen Provider belegt zudem eine tatsächliche
`sys.sql_expression_dependencies`-Referenz. Deploy und Uninstall müssen ihn
mit `55525/state3` abweisen; die installierte Baseline und der View bleiben
bis zur kontrollierten Entfernung des Testverbrauchers erhalten.
Die vollständigen 42 gezielten Caller-/Lock-/Rollback-/Marker-/Fremdslot-/
Dependencyfälle des separaten Labadapters, Minimalrechte, Maximalworkload und
Hard-Interrupt-Recovery gehören nicht zu diesem CI-Scope.
Weitere physische Ziele, Minimalrechte und Heap-/Maximalworkloadqualifikation
bleiben offen; die tatsächlich ausgeführte begrenzte API-/Safetyqualifikation
steht getrennt unten.

Zwei begrenzte Linux2019/latest-CL150-Läufe bestanden Install/Repeat und
432 Contract-APPLY-Oracles, scheiterten danach in Safety. Der erste technische
Fehler13606/state1 wurde im zweiten Lauf als synthetischer Fall41 (Tiefe129)
isoliert. ISJSON selbst wirft bei129 offenen Containern auch für ungültiges
JSON diesen Fehler. Beide Läufe sind FAILED_CLEANED; unabhängige neue
Verbindungen bestätigten eigene DB-Abwesenheit und unveränderte Inputpins.
Keine Konfigurations-, Rechte- oder Truständerungen. Kein vollständiger
Safety-/Client-/Lifecycle-/central-/Windowsnachweis. Der
[Änderungsvorschlag](../../../Documentation/Architecture/JSON_POINTER_NATIVE_DEPTH_BOUNDARY.md)
benötigte in diesem historischen Stand ausdrückliche Zustimmung zur Priorität
oberhalb128. Die anschließende konkrete Antwort „Diese Prioritätsänderung
freigegeben“ autorisiert genau den hier dokumentierten Guard und Wrapperpfad.

Die anschließenden getrennten Lifecycle-Scope-Adapter bestanden mit zwischen
diesen beiden erfolgreichen Läufen identischem eingefrorenen Source-/Deployment-/
Fixture-/Adapterstand auf Linux2019/latest CL150 und
Windows2025/exaktCU8 CL170. Je local/central/Consumer,15 echte direkte
Statusclientreader, installierte Baseline, Erst-/Repeat-/Uninstall-/Repeat
und42 gezielte Lifecyclefälle. Je Exit0, vollständige Kanäle und leeresStderr.
Frische unabhängige Audits bestätigen COMPLETE42, drei eigeneDBs abwesend,
je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert und jeweils
zweifach abgewiesen sowie sämtlicheInputpins unverändert. Kein Konfigurations-,
Rechte- oder Trustscope. Contract/Safety-Fixtures sind in diesen zwei separaten
Scopes NOT_EXECUTED. Die frühere Contract-Teilevidenz und beide fehlgeschlagenen
Gesamtadapter bleiben getrennt; keine Behebung der nativen Tiefenpriorität
und keine vollständige API-/Safetymatrixqualifikation daraus abgeleitet.

Nach der ausdrücklichen Prioritätsfreigabe wurde der feste nonnegative128er-
Guard vor ISJSON umgesetzt und der Scalarwrapper geschützt. Finale vollständige
Adapter bestanden mit identischem eingefrorenen Repository-Inputstand auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170. Je local/central/Consumer,
3072 feste Contract-/Safety-APPLY-Oracles (54+74 Fälle, vier Inputcollations,
zwei APPLY-Formen in drei Kontexten),15 direkte Statusclientreader,42
Lifecyclefälle und Erst-/Repeat-/Uninstall-/Repeat bestanden. Je Exit0,
vollständige Kanäle und leeresStderr. Frische unabhängige Audits bestätigen
COMPLETE42, drei eigeneDBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures
exakt restauriert mit je zwei Abweisungen und sämtlicheInputpins unverändert.
Keine Konfigurations-, Rechte- oder Truständerungen. Vorherige Fehlläufe und
Lifecycle-only-Scopes bleiben getrennte historische Nachweise. Weitere
physische Ziele, Minimalrechte,16MiB-Maximalworkload/Heap und exakteHead-CI
bleiben separat offen; teilweise validiert und unveröffentlicht.

Am 2026-10-06 bestanden zwei weitere vollständige Adapter auf demselben
schema-validierten, exakt ausgewählten Windows2025/CU8-Ziel mit CL150 und CL160.
Je local/central/Consumer, Contract/Safety, direkte Clientmetadaten,42
Lifecyclefälle sowie Repeat/Uninstall/Repeat; tatsächlicherExit0, vollständige
Kanäle und leeresStderr. Getrennte frische unabhängige Audits bestätigten je
COMPLETE42, drei eigene DBs abwesend, je zwei Marker-/Fremdslot-/
Dependencyfixtures exakt restauriert mit zwei Abweisungen, sämtliche Inputpins
unverändert und Nullscope Konfiguration/Rechte/Trust. Die früheren CL170-/
Linuxnachweise bleiben eigenständig. Weitere physische Ziele, Minimalrechte,
16MiB-Maximalworkload/Heap und vollständige Runtime-Head-CI bleiben offen.

Der begrenzte Modulworkflow bestand am 2026-10-06 am exakten
[PR187-Head](https://github.com/gecompat/SQL_Server_Toolbelt/pull/187):
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403031663)
und [Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403031731)
waren erfolgreich, einschließlich aller drei Linux-Jobs 2019/2022/2025.
Nach Merge bestanden auf `main` erneut
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403199690)
und [Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403199703).
Die 42 gezielten Lifecyclefälle des Labadapters sind nicht Teil dieser CI.
Weitere physische Ziele, tatsächliche Minimalrechte, Hard-Interrupt-Recovery,
16-MiB-Maximalworkload/Heap und Releasequalifikation bleiben offen;
`partially validated`, `unreleased`.

Am 2026-10-06 bestanden nach [PR201](https://github.com/gecompat/SQL_Server_Toolbelt/pull/201)
zusätzlich acht einzeln manuell ausgelöste, begrenzte Linux-SQL2019-CL150-
Lastjobs für Root und `/k` bei 64KiB,1MiB,4MiB und exakt16MiB. Die
[Testmatrix](JSON_POINTER_TEST_MATRIX.md) enthält die acht direkten Runlinks
und trennt sie vom regulären Head-/Main-CI-Scope. Weitere SQL-Versionen,
verschachtelte Maximalfälle, Heap, Parallelität und produktive Kapazität
bleiben offen; Modulstatus und Releaseaussage ändern sich nicht.

Nach [PR203](https://github.com/gecompat/SQL_Server_Toolbelt/pull/203)
bestanden zusätzlich zehn manuelle Tiefenjobs auf flüchtigem Linux-SQL2019-
CL150-Container: 64KiB bei Tiefe2,4,8,16,32,64,128 und danach Tiefe128 bei
1MiB,4MiB und exakt16MiB. Die [Testmatrix](JSON_POINTER_TEST_MATRIX.md)
enthält alle direkten Runlinks und die getrennten Grenzen. Allgemeine
JSON-Strukturen, SQL2022/2025-Maximallast, andere Plattformen, Heap,
Parallelität und Release bleiben offen.

Am 2026-10-06 bestanden zusätzlich16 **lokale**, separat gestartete
flüchtige Linux-SQL2022-CL160-/SQL2025-CL170-Lastfälle: je Root und einfaches
`/k` bei 64KiB,1MiB,4MiB und exakt16MiB mit serverseitigem Längen-/Hashoracle
und bestätigter eigener Bereinigung. Die [Testmatrix](JSON_POINTER_TEST_MATRIX.md)
grenzt diese lokalen Belege gegen frühere manuelle GitHub-Jobs und die offene
Tiefe128 auf diesen Versionen ab. Kein zusätzlicher Runner-/Lab-/Heapbeweis.

Am selben Tag bestanden zusätzlich20 lokale verschachtelte Einzelproben auf
denselben flüchtigen Linux-SQL2022-CL160-/SQL2025-CL170-Images: je Version
64KiB mit Tiefe2,4,8,16,32,64,128 und Tiefe128 mit1MiB,4MiB und exakt16MiB.
Der unveränderte manuelle Adapter prüfte serverseitig Einzeilenstatus, Länge
und SHA2-256, entfernte jeweils seinen Container; frische unabhängige
Owner-Label-Audits fanden danach keinen eigenen Lastcontainer. Details und
Grenzen stehen in der [Testmatrix](JSON_POINTER_TEST_MATRIX.md). Dies sind
lokale synthetische Belege, keine neuen GitHub-Dispatches oder Labtests.
Andere Formen/Plattformen, Heap, Parallelität, Runner-/Host-Recovery und
Releasequalifikation bleiben offen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope full`
- Scope: Zusätzliche vollständige Läufe auf demselben schema-validierten, exakt ausgewählten Windows2025/CU8-Ziel mit CL150 und CL160 bestanden jeweils local/central/Consumer, Contract/Safety, direkte Clientmetadaten, Repeat und42 Lifecyclefälle. Je Exit0, vollständige Kanäle und leeresStderr; frische unabhängige Audits bestätigten COMPLETE42, drei eigene DBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit zwei Abweisungen, unveränderte Inputpins und Nullscope Konfiguration/Rechte/Trust. CL150/160 sind getrennte neue Nachweise; CL170 und Linux2019 CL150 bleiben frühere Nachweise. Weitere physische Ziele, Minimalrechte,16MiB-Maximalworkload/Heap und vollständige Runtime-Head-CI offen; teilweise validiert, unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
