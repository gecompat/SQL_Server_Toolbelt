# CI-Testadapter

V0-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt die
vollständige automatisierte Adaptermatrix auf physischen SQL-Server-2019-,
2022- und 2025-Zielen unter Windows base und Linux latest. Manuelle und
extern bereitzustellende Spezialfälle bleiben in den jeweiligen
Modultestmatrizen getrennt ausgewiesen.

Dieses Verzeichnis enthält schlanke Adapter für GitHub-hosted Testläufe. Die fachlichen SQL-Tests verbleiben in den jeweiligen Modulverzeichnissen.

## Eigener W4a-Runnercontainer

`run-w4a-execution-foundations-linux.sh` bindet seinen flüchtigen Runnernamen
an SQL-Version, Run und Attempt und setzt vor dem Start ein Ownerlabel.
Cleanup liest volle ID und Owner gemeinsam, entfernt ausschließlich die
eigene ID und verlangt frische exakte Namensabwesenheit. Fremder Bestand,
unbekannte Sicht oder Removefehler liefern `W4A_CI_CLEANUP_UNVERIFIED` und
Exit1. Bestätigter Cleanup meldet `W4A_CI_CLEANUP_VERIFIED` und erhält den
ursprünglichen Exitstatus. Der Labzweig bleibt sein separater No-op ohne
Ownerproben oder Container-VERIFIED-Zusage.

Der bestehende source-extrahierte Offlineharness
`python -B Tests/CI/test_owned_container_cleanup.py --module w4a` prüft dies
mit synthetischen Dockerantworten einschließlich ersetzter Namen, ungültiger
ID/Ownerdaten, unbekannter Sicht und separatem Lab-Exit0/Exit7. Er greift
weder auf Docker noch SQL oder Lab zu. Der bestehende Dokumentationsworkflow
erfasst Adapteränderungen selektiv. Fachliche SQL-Fixtures und die bisherigen
2019/2022/2025-Linux-Jobs bleiben unverändert; exakte Head-/Main-Ergebnisse
stehen getrennt im PR. Hard-Interrupt-Recovery und Releasequalifikation
werden dadurch nicht belegt.

## Adapter und Zielversionen

Der Identifier-Adapter bindet seinen Runner vor dem Start an SQL-Version,
Run, Attempt und Ownerlabel. Cleanup liest volle ID und Owner gemeinsam,
entfernt ausschließlich diese eigene ID und verlangt frische exakte
Namensabwesenheit. Unbestätigter Cleanup liefert `IDENTIFIER_CI_CLEANUP_UNVERIFIED`
und Exit1; `IDENTIFIER_CI_CLEANUP_VERIFIED` erhält den ursprünglichen Teststatus.
Der Labzweig bleibt Container-No-op ohne Runnerowner oder private Ablage.

Das vorhandene Kollisionsorakel verlangt einen fehlgeschlagenen Deploy und
die vollständige Fehlerkategorie `51064`. Erfolgreicher Exit mit diesem Text,
andere oder fehlende Kategorien und längere Nummern zählen nicht als Nachweis.
Beide Rohkanäle bleiben im Speicher; `IDENTIFIER_COLLISION_VERIFIED` bestätigt
das Orakel. Derselbe Harness prüft dies in Runner- und Labmodus ohne neue SQL-Fixture.

`python -B Tests/CI/test_owned_container_cleanup.py --module identifier`
prüft die tatsächliche Cleanupfunktion synthetisch, einschließlich Fremdbestand,
Namensaustausch, ungültiger Identität, unbekannter Sicht und Lab-Exit0/Exit7.
Parser-/Quote- und Lifecycle-/Kollisionsfixtures, Bereitschaftsfrist, Images,
Versions-/CL-Matrix und Runtimeworkflow bleiben unverändert. Exakte Head-/Main-
Ergebnisse stehen im PR; Hard-Interrupt-Recovery und Release bleiben getrennt.

Der Integer-Base-Adapter prüft seine Runneridentität aus Version, Run und
Attempt sowie den Owner vor dem Start. Cleanup entfernt ausschließlich die
gemeinsam mit dem Label gelesene volle ID und bestätigt frische exakte
Namensabwesenheit. `INTEGER_BASE_CI_CLEANUP_UNVERIFIED` endet mit Exit1;
`INTEGER_BASE_CI_CLEANUP_VERIFIED` erhält den ursprünglichen Teststatus.
Der Labzweig bleibt Container-No-op ohne Runnerowner oder private Ablage.

Das bestehende Kollisionsorakel verlangt einen fehlgeschlagenen Deploy und
die vollständige Fehlerkategorie `51094`. Ein erfolgreicher Exit mit diesem
Text, eine andere oder fehlende Kategorie und längere Nummern zählen nicht
als Ablehnungsnachweis. Beide Kanäle werden ausschließlich im Speicher geprüft;
nur `INTEGER_BASE_COLLISION_VERIFIED` bestätigt das Orakel. Derselbe synthetische
Harness prüft diese Fälle in Runner- und Labmodus ohne zusätzlichen SQL-Negativtest.

`python -B Tests/CI/test_owned_container_cleanup.py --module integer_base`
prüft die tatsächliche Cleanupfunktion mit synthetischen Stubs, einschließlich
Fremdbestand, Namensaustausch, ungültiger ID/Owner, unbekannter Sicht und
Lab-Exit0/Exit7. Encode/Decode, Upgrade-/Lifecycle-/Kollisionsfixtures,
Images, Bereitschaftsfrist, Versions-/CL-Matrix und vorhandener Runtimeworkflow
bleiben erhalten. Exakte Head-/Main-Ergebnisse stehen im PR; harte
Unterbrechungen und eine Releasequalifikation bleiben getrennt.

Der W1-Adapter bindet seinen Runner vor dem Start an SQL-Version, Run,
Attempt und Owner. Cleanup entfernt ausschließlich die gemeinsam mit dem
Label gelesene volle ID und verlangt frische exakte Namensabwesenheit.
Unbestätigter Cleanup meldet `W1_CI_CLEANUP_UNVERIFIED` und Exit1;
`W1_CI_CLEANUP_VERIFIED` erhält den ursprünglichen Teststatus. Der Labzweig
bleibt Container-No-op; Datenbankbereinigung beim Labtreiber.

`python -B Tests/CI/test_owned_container_cleanup.py --module w1` prüft
die tatsächliche Cleanupfunktion synthetisch ohne Docker, SQL oder Lab,
einschließlich Fremdbestand, Namensaustausch, ungültiger Identität, unbekannter
Sicht und Lab-Exit0/Exit7. Fachliche SQL-Fixtures, drei Kollisionsorakel,
CS-/CI-/UTF8-Fälle, Images, Bereitschaftsfrist, Versions-/CL-Matrix und
bestehender PR-/Push-/Manual-Workflow bleiben erhalten. Exakte Head-/Main-
Ergebnisse stehen im PR; Hard-Interrupt-Recovery, Lab-, Minimalrechte- und
Releasequalifikation bleiben getrennt.

Der W2a-Adapter bindet seinen Runner vor dem Start an SQL-Version, Run,
Attempt und Owner. Cleanup entfernt ausschließlich die gemeinsam mit dem
Label gelesene volle ID und verlangt frische exakte Namensabwesenheit.
Unbestätigter Cleanup meldet `W2A_CI_CLEANUP_UNVERIFIED` und Exit1;
`W2A_CI_CLEANUP_VERIFIED` erhält den ursprünglichen Teststatus. Der Labzweig
bleibt Container-No-op; Datenbankbereinigung beim Labtreiber.

`python -B Tests/CI/test_owned_container_cleanup.py --module w2a` prüft
die tatsächliche Cleanupfunktion synthetisch ohne Docker, SQL oder Lab,
einschließlich Fremdbestand, Namensaustausch, ungültiger Identität, unbekannter
Sicht und Lab-Exit0/Exit7. Fachliche SQL-Fixtures, drei Kollisionsorakel,
Bucket-Workload, Images, Bereitschaftsfrist, Versions-/CL-Matrix und
bestehender PR-/Push-/Manual-Workflow bleiben erhalten. Exakte Head-/Main-
Ergebnisse stehen im PR; Hard-Interrupt-Recovery, Lab-, Minimalrechte- und
Releasequalifikation bleiben getrennt.

Der W2b-JSON-Path-Adapter bindet seinen Runner vor dem Start an SQL-Version,
Run, Attempt und Owner. Cleanup entfernt ausschließlich die gemeinsam mit
dem Label gelesene volle ID und verlangt frische exakte Namensabwesenheit.
Unbestätigter Cleanup meldet `W2B_JSON_CI_CLEANUP_UNVERIFIED` und Exit1;
`W2B_JSON_CI_CLEANUP_VERIFIED` erhält den ursprünglichen Teststatus. Der
Labzweig bleibt Container-No-op; Datenbankbereinigung beim Labtreiber.

`python -B Tests/CI/test_owned_container_cleanup.py --module w2b` prüft
die tatsächliche Cleanupfunktion synthetisch ohne Docker, SQL oder Lab,
einschließlich Fremdbestand, Namensaustausch, ungültiger Identität, unbekannter
Sicht und Lab-Exit0/Exit7. Fachliche SQL-Fixtures, Kollisionsorakel, Images,
Bereitschaftsfrist, Versions-/CL-Matrix und bestehender PR-/Push-/Manual-
Workflow bleiben erhalten. Exakte Head-/Main-Ergebnisse stehen im PR;
Hard-Interrupt-Recovery, Lab-, Minimalrechte- und Releasequalifikation bleiben
getrennt.

Der W2c-Adapter bindet seinen Runner vor dem Start an SQL-Version, Run,
Attempt und Owner. Cleanup entfernt nur die gemeinsam mit dem Label gelesene
volle ID und verlangt frische exakte Namensabwesenheit. Unbestätigter Cleanup
meldet `W2C_CI_CLEANUP_UNVERIFIED` und Exit1; `W2C_CI_CLEANUP_VERIFIED`
erhält den ursprünglichen Teststatus. Der Labzweig bleibt Container-No-op;
seine Datenbankbereinigung bleibt beim vorhandenen Labtreiber.

`python -B Tests/CI/test_owned_container_cleanup.py --module w2c` prüft
die tatsächliche Bereinigungsfunktion mit synthetischen Dockerantworten,
einschließlich Fremdbestand, Namensaustausch, ungültiger Identität, unbekannter
Sicht und Lab-Exit0/Exit7. SQL-Fixtures, Console-Ausgabemarker, Images,
Versions-/CL-Matrix und bestehender PR-/Push-/Manual-Workflow bleiben erhalten.
Exakte Head-/Main-Ergebnisse stehen im PR; Hard-Interrupt-Recovery, zusätzliche
Client-/Treiberkontexte, Lab- und Releasequalifikation bleiben getrennt.

Der W6d-Cancellation-Adapter bindet seinen Runner vor dem Start an Version,
Run, Attempt und Owner. Cleanup entfernt ausschließlich die gemeinsam mit
dem Label gelesene volle ID und verlangt frische Namensabwesenheit sowie
private Dateibereinigung. `W6D_CI_CLEANUP_UNVERIFIED` endet Exit1;
`W6D_CI_CLEANUP_VERIFIED` erhält den ursprünglichen Teststatus. Im Lab bleibt
Container-rm No-op, während private Dateicleanupfehler
`W6D_LAB_CLEANUP_UNVERIFIED` und Exit1 melden. Die Datenbankbereinigung bleibt
beim vorhandenen Labtreiber.

Dependency- und Uninstall-Ausgaben liegen in beiden Modi laufisoliert. Die
bestehenden Guards verlangen weiterhin Fehlerexit und Kategorie 52641 oder
52646. `python -B Tests/CI/test_owned_container_cleanup.py --module w6d`
prüft tatsächliche Cleanupblöcke mit synthetischen Antworten ohne Docker,
SQL oder Lab. Cancellation-Semantik, fachliche Fixtures, vier parallele
Worker, Images und Versions-/CL-Matrix bleiben erhalten. Der unveränderte
Runtimeworkflow läuft bei passenden PRs, Main-Pushes und manuell; Ergebnisse
werden für den jeweiligen exakten Commit separat ausgewiesen. Hard-Interrupt-,
Lab-, Minimalrechte- und Releasequalifikation werden damit nicht belegt.

Der W5b-Event-Log-Adapter bindet seinen Runner an Version, Run, Attempt und
Owner vor dem Start. Cleanup entfernt nur die gemeinsam mit dem Label gelesene
volle ID und prüft frische Namensabwesenheit. `W5B_CI_CLEANUP_UNVERIFIED` endet
Exit1; `W5B_CI_CLEANUP_VERIFIED` erhält den ursprünglichen Teststatus. Im Lab
bleiben Container-rm No-op und Datenbank-/Linked-Server-Bereinigung beim
vorhandenen Labtreiber. Private Dateicleanupfehler melden
`W5B_LAB_CLEANUP_UNVERIFIED` und Exit1.

Die bestehende Uninstall-Negativphase verlangt Fehlerexit und Kategorie 51749.
Ihre Datei liegt in beiden Modi laufisoliert; das vorhandene `cat` bleibt
Diagnosekanal. `python -B Tests/CI/test_owned_container_cleanup.py --module w5b`
prüft tatsächliche Cleanup-/Guardblöcke mit synthetischen Antworten ohne
Docker, SQL oder Lab. Event-Log-Semantik, Loopback-Konfiguration, vier Caller-
Sessions und Versions-/CL-Matrix bleiben erhalten. Der unveränderte Workflow
läuft bei passenden PRs oder manuell, ohne Pushtrigger. Head-Runtime,
Main-Documentation und Treevergleich werden separat ausgewiesen; Hard-Interrupt-,
Lab-, Minimalrechte- und Releasequalifikation werden damit nicht belegt.

Der W5a-Second-Session-Adapter bindet seinen Runner vor dem Start an Version,
Run, Attempt und Owner. Cleanup verwendet ausschließlich die gemeinsam mit
dem Label gelesene vollständige ID und prüft frische Namensabwesenheit.
`W5A_CI_CLEANUP_UNVERIFIED` endet Exit1; `W5A_CI_CLEANUP_VERIFIED` erhält den
ursprünglichen Teststatus. Im Lab bleiben Container-rm No-op und die bestehende
Datenbank-/Linked-Server-Bereinigung beim Labtreiber. Nur seine private
Ausgabeablage wird zusätzlich entfernt; Fehler melden
`W5A_LAB_CLEANUP_UNVERIFIED` und Exit1.

Die tatsächliche Uninstall-Negativphase verlangt Fehlerexit und Kategorie51649.
Ihre Datei liegt in beiden Modi laufisoliert; das bestehende `cat` bleibt als
Diagnosekanal erhalten. `python -B Tests/CI/test_owned_container_cleanup.py
--module w5a` prüft tatsächliche Cleanup-/Guardblöcke mit synthetischen Antworten
ohne Docker, SQL oder Lab. Loopback-Konfiguration, fachliche Fixtures, vier
Caller-Sessions und Versions-/CL-Matrix bleiben erhalten. Der unveränderte
Workflow läuft bei passenden PRs oder manuell, ohne Pushtrigger. Head-Runtime,
Main-Documentation und Treevergleich werden separat ausgewiesen; daraus folgt
keine Hard-Interrupt-, Minimalrechte-, Lab- oder Releasequalifikation.

Der W4b-Work-Type-Adapter bindet seinen Runner an Version, Run, Attempt und
Owner. Cleanup entfernt nur die gemeinsam mit dem Label gelesene vollständige
ID und verlangt frische Namensabwesenheit; unbestätigter Cleanup endet mit
`W4B_CI_CLEANUP_UNVERIFIED` und Exit1. `W4B_CI_CLEANUP_VERIFIED` erhält den
ursprünglichen Status. Seine Uninstall-Negativausgabe liegt in beiden Modi
privat; der erwartete Fehler verlangt jetzt einen Fehlerexit und Kategorie51549.
Im Lab bleibt Container-rm No-op, ohne Runnerproben oder Container-VERIFIED;
private Dateicleanupfehler melden `W4B_LAB_CLEANUP_UNVERIFIED` und Exit1.

`python -B Tests/CI/test_owned_container_cleanup.py --module w4b` prüft die
echten Cleanup- und Uninstall-Orakel mit synthetischen Antworten ohne Docker,
SQL oder Lab. Fachliche SQL-Fixtures, vier Sessions und Versions-/CL-Matrix
bleiben erhalten. Der vorhandene W4b-Workflow läuft bei passenden PRs oder
manuell; er besitzt keinen Pushtrigger. Head-Runtime, Main-Documentation und
Treevergleich werden im PR getrennt ausgewiesen. Hard-Interrupt-Recovery
und tatsächliche Labqualifikation bleiben offen.

Der Work-Queue-Adapter verwendet eine eigene private Ausgabeablage für seine
vier Negativphasen, auch im Labmodus. Im Runner bindet er den Container an
SQL-Version, Run, Attempt und Owner; Cleanup entfernt ausschließlich die
gemeinsam mit dem Label gelesene vollständige ID und prüft danach frische
Namensabwesenheit. Es sendet dabei keine SQL-Drops über einen Containernamen.
Unbestätigte Bereinigung endet mit `WORK_QUEUE_CI_CLEANUP_UNVERIFIED` und Exit1;
bestätigte Bereinigung meldet `WORK_QUEUE_CI_CLEANUP_VERIFIED` und erhält den
ursprünglichen Exitstatus.

Der Labzweig behält seine sieben suffixierten Datenbank-Drops und den
Container-No-op des vorhandenen Shims. Er bereinigt die private Ablage ohne
Runner-Inspection oder Container-VERIFIED-Zusage; ein Dateicleanupfehler wird
mit `WORK_QUEUE_LAB_CLEANUP_UNVERIFIED` und Exit1 sichtbar. Der bestehende
source-extrahierte Harness
`python -B Tests/CI/test_owned_container_cleanup.py --module work_queue`
prüft Runneridentität und Cleanup sowie die separaten Labpfade ausschließlich
mit synthetischen Antworten. Hard-Interrupt-Recovery und tatsächliche
Labqualifikation bleiben davon getrennt.

Die Modul-Adapter sind versionsparametrisch. `TBX_SQL_VERSION` wählt das
Zielrelease und daraus die tatsächlich geprüften Compatibility Levels: `2019`
prüft 150, `2022` prüft 160 und `2025` prüft 150, 160 und 170.
`TBX_SQL_IMAGE` benennt den zugehörigen offiziellen Container. Ohne gesetzte
Versionsvariable bleibt `2025` der Vorgabewert. Angaben zu Compatibility
Levels in den folgenden Adapterbeschreibungen beziehen sich auf die jeweils
ausgewählte Zielversion.

`run-result-table-linux.sh` startet für den ResultTable-Vertrag einen offiziellen SQL-Server-Linux-Container, erzeugt ausschließlich synthetische Testdatenbanken und ruft die kanonischen Deploy-, Runtime- und Uninstall-Artefakte auf.

`run-base64-linux.sh` verwendet einen offiziellen SQL-Server-Linux-Container
der ausgewählten Zielversion und prüft den Base64-Vertrag seriell über deren
Compatibility Levels sowie lokale, zentrale und Lifecycle-Pfade.

`run-generate-series-linux.sh` verwendet einen offiziellen
SQL-Server-Linux-Container der ausgewählten Zielversion und prüft den
portablen Ganzzahlreihenvertrag seriell über deren Compatibility Levels sowie
lokale, zentrale und Lifecycle-Pfade.

Die drei Performance-Workloads für Result Table, Base64 und Generate Series
laufen nur mit `TBX_RUN_PERFORMANCE_WORKLOAD=1` und verwenden ausschließlich
die flüchtigen Umgebungsvariablen
`TBX_PERFORMANCE_BASELINE_MEDIAN_MILLISECONDS` und
`TBX_PERFORMANCE_MAX_MEDIAN_REGRESSION_PERCENT`. Ohne Basiswert ist der
Vergleich deaktiviert; die Default-Grenze beträgt 20 %. Die Adapter geben
keine Messwerte aus und speichern sie nicht als Evidenz.

Für Generate Series ergänzt
`TBX_PERFORMANCE_MAX_BATCH_MEDIAN_VARIANCE_PERCENT` ein Stabilitäts-Gate mit
Default `20`. Drei unabhängige Batch-Mediane müssen innerhalb dieser Grenze
liegen, bevor ein vorhandener Baseline-Vergleich stattfindet. Instabilität
endet im lokalen Lab-Adapter als `NOT_EXECUTED` mit
`PERFORMANCE_STABILITY_UNAVAILABLE`; sie ist kein erfolgreicher Nachweis und
keine Statusaufwertung. Auch dafür werden keine Messwerte ausgegeben oder
gespeichert.

`run-date-spine-linux.sh` installiert Generate Series und Datetime Truncate
als explizite Dependencies und prüft danach Tages-, ISO-Wochen- und
Monatsspine einschließlich halboffener Grenzen, `DATEFIRST`-Unabhängigkeit,
Skalierung, fehlender Dependencies, Kollisionen, Wiederholungsdeployment,
Central-Aufruf und vollständigem Cleanup.

`run-work-queue-linux.sh` installiert ResultTable und Work Type als explizite
Dependencies und prüft den freigegebenen E1a-/E1b-Vertrag: Enqueue, atomaren Lease-Claim,
Heartbeat, explizite Recovery, Upgrade,
tokengebundenes Complete/Fail, Transaktionen, vier echte Claim-Sessions,
Statusschutz, Redeployment, Central, Datenverlustgate und vollständiges
Cleanup. Der Adapter startet, stoppt oder repariert keine Lab-Ressource.

Der Research-Adapter
`../Research/Regex/run-sqlserver-2025.sh` prüft ausschließlich auf SQL Server
2025 die native Regex-Semantik unter Compatibility 150, 160 und 170. Er wird
nicht in der Standardmodulmatrix ausgeführt, installiert kein Modul und
entfernt seine synthetische Datenbank vollständig.

`run-regex-linux.sh` prüft das daraus getrennt freigegebene R1b-Modul mit
dem exakten, reproduzierbar gebauten SAFE-CLR-Releaseartefakt. Der Adapter
deckt Dialekt, UTF-16-Positionen, Grenzen, festen Timeout, stabile
Fehlerpräfixe, Kollisionsschutz, Redeployment, Central und Uninstall ab.

`run-identifier-linux.sh` prüft den Identifier-Vertrag über dieselben
Compatibility Levels sowie lokale, zentrale, Kollisions- und Lifecycle-Pfade.

`run-split-characters-linux.sh` installiert zuerst den Generate-Series-Kern
und prüft danach den literalen Multi-Separator-Vertrag über dieselben
Compatibility Levels, fehlender Dependency, lokaler und zentraler Nutzung,
Kollision, Wiederholungsdeployment und Uninstall.

`run-semantic-version-linux.sh` prüft Parser, Comparator, Sort Key sowie
lokale, zentrale, Kollisions- und Lifecycle-Pfade über dieselben
Compatibility Levels.

`run-integer-base-linux.sh` prüft Alphabete von Basis 2 bis 93,
Kanonizität, den vollständigen `bigint`-Bereich, Overflow sowie lokale,
zentrale, Kollisions- und Lifecycle-Pfade über dieselben Compatibility Levels.

`run-zip-memory-linux.sh` installiert zuerst `toolbelt.core.result-table` als
Dependency und prueft danach den In-memory-ZIP-Vertrag fuer
`toolbelt.archive.zip-memory` mit Compatibility Levels 150, 160 und 170 sowie
lokale, zentrale, Lifecycle- und Uninstall-Pfade.

Der Adapter `run-lab-target.sh` wird ausschließlich vom lokalen
SQL_Server_Lab-Orchestrator aktiviert. GitHub Actions und andere disposable
Runner führen ohne `TBX_SQL_TARGET=lab` weiterhin den unveränderten
Containerpfad aus. Der lokale Orchestrator führt keinen automatischen
Runner-Fallback durch.

Bash wird hier nur als Linux-CI-Orchestrierung verwendet. Es enthält keine zweite Implementierung der T-SQL-Fachlogik.

`run-q1-migration-idempotency.sh` führt den ersten eng begrenzten
Migration-Idempotency-Vertrag aus. Er deployt das dependency-freie T-SQL-Modul
`toolbelt.core.generate-series` in einer isolierten synthetischen Datenbank,
vergleicht den effektiven Katalog vor und nach dem Wiederholungsdeployment und
prüft ein zweimaliges Uninstall. Die Datenbank wird anschließend gezielt
entfernt; ein Lab-Ziel wird weder gestartet noch beendet.

Die Q1-Lab-Matrix war am 2026-08-29 auf SQL Server 2019, 2022 und 2025 jeweils
unter Linux und Windows erfolgreich. Der abstrahierte Nachweis umfasst
Wiederholungsdeployment, Kataloggleichheit, zwei unabhängige Uninstalls,
Restzustandsprüfung und Cleanup der synthetischen Testdatenbank.

## Lokaler Lab-Lauf aus PowerShell

Für die lokale Entwicklung kann die geeignete CI-Testmatrix gegen die vom
SQL_Server_Lab exportierten READY-Ziele gefahren werden. Voraussetzung sind
Git Bash, `sqlcmd` und ein erreichbares Lab-Netz.

Discovery-Reihenfolge:

1. Prozessvariable `SQL_SERVER_LAB_TEST_ENV_FILE`;
2. gleichnamige Benutzervariable;
3. `SQL_SERVER_LAB_DATA_ROOT` aus Prozess- oder Benutzervariable plus
   `Exports/TestUmgebung.json`.

`SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE` kann das standardmäßig danebenliegende
`TestUmgebung.schema.json` überschreiben. Der Vertrag wird vor jeder Verwendung
gegen dieses Schema validiert. Bei `groupStatus = READY` werden nur Einträge
mit `status = READY` verwendet. Der projektspezifische Override vom 2026-08-29
erlaubt bei `groupStatus = INCOMPLETE` außerdem explizit ausgewählte Einträge
mit `runtimeStatus = READY` und `status = READY` beziehungsweise
`GROUP_INCOMPLETE`. `groupStatus = EMPTY` sowie nicht einzeln bereite Ziele
bleiben ausgeschlossen. Diese engere Einzelzielfreigabe hat für dieses
Repository Vorrang vor einer widersprechenden gruppenweiten READY-Klausel in
einem über `SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE` bereitgestellten
Zusatzvertrag; dessen übrige Regeln sind weiterhin zu beachten. Laufwerks-,
Home- oder Repositorysuche sowie feste Lab-Pfade sind ausgeschlossen.

Beispielaufrufe:

```powershell
pwsh Tests/CI/run-lab-local.ps1
pwsh Tests/CI/run-lab-local.ps1 -Platforms linux -Versions 2019,2022,2025 -LinuxPatches latest -TestSuite full
pwsh Tests/CI/run-lab-local.ps1 -Platforms linux,windows -Versions 2019,2022,2025 -LinuxPatches latest -WindowsPatches base -TestSuite full
pwsh Tests/CI/run-lab-local.ps1 -RunScripts run-zip-memory-linux.sh
pwsh Tests/CI/run-lab-local.ps1 -RunScripts run-regex-linux.sh -RegexAssemblyRoot .runtime/regex-release
```

`run-file-content-linux.sh` ist bewusst kein SQL_Server_Lab-Adapter: Er
erzeugt seine synthetischen Fixtures im Dateisystem eines eigenen Docker-SQL-
Servers. Die lokale Lab-Matrix weist diesen Aufruf daher explizit zurück,
statt fälschlich Lab-Evidenz zu behaupten. Eine spätere Lab-Validierung des
File-Content-Moduls benötigt separat vorbereitete, serverseitige synthetische
Fixtures und eine dafür freigegebene Identity-/Pfadkonfiguration.

Die Matrix selektiert explizit nach `platform`, `sqlVersion` und `patch` und
verwendet alle nach dem obigen Gruppen- und Einzelzielvertrag zulässigen
Einträge. Für einen allgemeinen Windows-`base`-Lauf gilt die ausdrücklich
freigegebene Patchäquivalenz: Bereite `base`- und `CU<n>`-Ziele derselben
Windows-/SQL-Version werden gemeinsam und deterministisch ausgeführt. Ein
explizit angefordertes `CU<n>` bleibt hinsichtlich der CU-Nummer exakt;
`CU32`, `Cu32` und `cu32` bezeichnen denselben Patchstand. Die Schreibweise
anderer Patchbezeichnungen bleibt unverändert. Überlappende Anforderungen
(beispielsweise `base` und `CU32`) führen ein Ziel anhand seines
Vertragsschlüssels nur einmal aus. Fehlt ein zulässiges Ziel oder ist
sein eigener Runtime-Status nicht
`READY`, wird dieser Scope als nicht ausgeführt behandelt; ein Wechsel auf eine
andere Plattform oder SQL-Version findet nicht statt. Der Adapter startet oder
repariert keine Lab-Ressource.

`python Tests/CI/validate_lab_selector.py` führt mit PowerShell 7 synthetische
Verhaltenstests der echten Selektionsfunktionen aus. Die Funktionen werden
über den PowerShell-AST geladen, ohne den Runner zu initialisieren oder ein
Labziel zu kontaktieren. Geprüft werden CU-Schreibweisen, exakte Grenzen,
numerische/stabile base-Auswahl, Bereitschaft und Deduplizierung. Der
Documentation-Consistency-Workflow führt sie bei Änderungen an der Auswahl
oder ihren Tests sowie bei einem manuellen vollständigen Audit aus.

Wichtige Anpassungen:

- Vor dem Test werden `SELECT @@VERSION` und der Zustand von
  `sys.databases` über eine echte SQL-Anmeldung geprüft.
- Für ZIP-Memory und Regex werden `TBX_ASSEMBLY_ROOT` und der jeweilige exakte
  Assembly-Hash aus den lokal gebauten Release-Artefakten gesetzt.
- Verbindungen verwenden ausschließlich Werte des ausgewählten Eintrags mit
  `Encrypt=True` und `TrustServerCertificate=True`; `Encrypt=Strict` wird nicht
  verwendet.
- Verändernde Tests erhalten eindeutige Datenbanknamen mit zufälliger
  Testlauf-ID. Der Adapter entfernt nur Datenbanken dieser ID. CLR-Adapter
  stellen zusätzlich nur die von ihrem Lauf geänderte CLR-/Trust-Konfiguration
  wieder auf den vorherigen Zustand zurück.
- Der Dateicontent-Lauf gehört nicht zur Standardmatrix, weil seine
  serverseitigen Dateien zuerst explizit in jedem Ziel bereitgestellt werden
  müssen.

Das Testkennwort:

- wird je Lauf zufällig erzeugt;
- wird in GitHub Actions maskiert;
- wird nicht in Dateien oder Artefakten gespeichert;
- ist kein Repository-Secret.

Ein vorhandener Adapter oder Workflow ist kein Runtime-Nachweis. Nur eine tatsächlich erfolgreich abgeschlossene Action erzeugt Evidenz.

## Evidenz

Der [aktuelle GitHub Actions Run 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) war am 2026-07-29 für den statischen Vertrag sowie die vollständige Suite auf SQL Server 2019, 2022 und 2025 unter GitHub-hosted Linux erfolgreich. Der Scope umfasst vier parallele echte Sitzungen mit identischen logischen lokalen Temp-Tabellennamen. Die früheren Läufe und verbleibenden Grenzen stehen in der ResultTable-Testmatrix.

Der [GitHub Actions Run 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) war am 2026-08-01 für SQL Server 2019, 2022 und 2025 unter Linux erfolgreich und ergänzt den natürlichen Enginefehler 2705 nach begonnener Mutation einschließlich vollständigem Savepoint-Rollback von Schema und Daten.

Der
[Base64-Runtime-Lauf 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die ergänzende lokale Windows-/Linux-Matrix 2019/2022/2025 war
am 2026-09-01 erfolgreich; die breitere Large-LOB-Performance-Evidenz bleibt offen.

Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die ergänzende lokale Windows-/Linux-Matrix 2019/2022/2025 war
am 2026-09-01 erfolgreich; die breitere Very-large-series-Performance-Evidenz bleibt offen.

Der
[Identifier-Runtime-Lauf 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die ergänzende lokale Windows-/Linux-Matrix 2019/2022/2025 war
am 2026-09-01 erfolgreich; das Modul ist `validated`.

Der
[Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die ergänzende lokale Windows-/Linux-Matrix 2019/2022/2025 war
am 2026-09-01 erfolgreich; das Modul ist `validated`.

Der
[Semantic-Version Runtime Run 30517137373](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die ergänzende lokale Windows-/Linux-Matrix 2019/2022/2025 war
am 2026-09-01 erfolgreich; das Modul ist `validated`.

Der
[Integer-Base Runtime Run 30518087070](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30518087070)
war auf SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die ergänzende lokale Windows-/Linux-Matrix 2019/2022/2025 war
am 2026-09-01 erfolgreich; das Modul ist `validated`.

## Quellen

- Microsoft (2026): [Offizielle SQL-Server-Linux-Container und Tags](https://mcr.microsoft.com/product/mssql/server/about).
- GitHub (2026): [GitHub-hosted runners](https://docs.github.com/actions/using-github-hosted-runners/about-github-hosted-runners).
- Microsoft (2026): [SQLCMD-Scripting-Variablen und Priorität](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-use-scripting-variables?view=sql-server-ver17).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-11`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2025-Ziele unter Windows und Linux; vollständiger Moduladapter einschließlich explizit aktivierter synthetischer Performance-Workload ohne persistierte Basis
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
