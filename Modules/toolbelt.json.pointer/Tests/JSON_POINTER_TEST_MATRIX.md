# JSON Pointer1.0.0 – Testmatrix

Der [kanonische Vertrag](../../../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
bestimmt feste Erwartungen. Historische Engineproben ersetzen keine API-Prüfung.

54 Contract- und74 Safetyfälle ergeben1024 feste Resultatoracles je Kontext;
local/central/Consumer ergeben3072 je vollständigem Zieladapter. Finale
vollständige Adapter auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170
bestanden je diese Oracles,15 echte Clientreader und42 Lifecyclefälle.
Frische Audits bestätigten eigene Bereinigung, Fixturewiederherstellung und
Inputpins. Frühere Fehlläufe und Lifecycle-only-Scopes bleiben getrennt.
Zusätzliche vollständige Adapter auf demselben Windows2025/exaktCU8-Ziel mit
CL150 und CL160 bestanden am 2026-10-06 jeweils local/central/Consumer,
Contract/Safety, Clientmetadaten und42 Lifecyclefälle. Frische unabhängige
Audits bestätigten eigene Bereinigung, Fixturewiederherstellung und Inputpins;
das erweitert weder die physische Zielmatrix noch den Minimalrechte- oder
Maximalworkload-Nachweis.

| Artefakt | Prüfscope |
|---|---|
| Runtime/Contract.Tests.sql | RFC-Beispiele, Roottypen, einmalige Escapes, exakte Keys/NUL/trailing spaces, passende Duplikate, Arraylexik, große Indices, alle Statuswerte; CROSS/OUTER APPLY und vier Inputcollations |
| Runtime/Safety.Tests.sql | SQLNULL-/Budget-/Syntax-/Unicode-/Tiefenpriorität, Grenzen und vollständige unselektierte Prüfung, Chunkübergänge und gemischte Surrogatpaare |
| Runtime/Metadata.Tests.ps1 | Tatsächliche TF, vier Parameter/vier Spalten, Defaults, Collation/Nullability und fünf direkte Statusreader ohne weiteren Resultset |
| Runtime/Lifecycle.Tests.sql | Installierter eigener TF-/Marker-/Parameter-/Spaltenbestand |
| Tests/CI/run-json-pointer-lab.ps1 | Local/central/Consumer mit gewähltem CL, install/repeat/uninstall/repeat, 42 gezielte Caller-/Lock-/Rollback-/Marker-/Fremdslot-/Dependency-/Confirmfälle bei beiden Modi, own cleanup und Inputpins |
| Tests/CI/run-json-pointer-linux.sh | Flüchtige Linux-Matrix einschließlich harter Inputlimit-Abweisung bei 16 MiB plus einer UTF-16-Codeeinheit; keine 16-MiB-Verarbeitungs- oder Heapqualifikation |
| Tests/CI/run_max_workload.py | Nur manuell auslösbarer Einzelversuch je Größe/Form/SQL-Version auf eigenem flüchtigem Linux-Container; 240-s-Arbeitsbudget, höchstens60-s-Bereinigung und exaktes serverseitiges Orakel. Ein vorhandener Adapter ist noch kein erfolgreicher Maximalworkload-Nachweis. |
| Tests/CI/test_hard_interrupt_recovery.py | Separat manuell gestartete lokale Kindprozess-Abbruchprobe mit eigenem flüchtigem Docker-Container, vor/nach CID, falscher Owner-ID und frischem Abwesenheitsaudit; keine SQL-Ausführung oder Runnerausfallprobe. |
| Static/validate_contract.py | Source-/Manifest-/Deployment-/Test-/Dokumentationskopplung und nicht schreibender Generatorcheck; keine SQL-Ausführung |

Inputcollations: Latin1_General_100_BIN2, Latin1_General_100_CI_AS,
Latin1_General_100_CS_AS, Latin1_General_100_CI_AS_SC_UTF8.
Zielmatrix SQL2019/2022/2025 Windows/Linux mit gültigem CL150/160/170.
Weitere physische Kombinationen, Minimalrechte, über die zwei synthetischen
Formen hinausgehende Maximalworkloads, Heap und Parallelität bleiben offen.
Keine Release- oder Produktionszusage.

## Offene Minimalrechte-Qualifikation

Die TVF selbst verlangt für den Aufruf vorhandenes `SELECT`. Der Lifecycle-
Preflight prüft datenbankweites `VIEW DEFINITION`, `SELECT` auf
`sys.sql_expression_dependencies`, `CREATE FUNCTION` sowie `ALTER` auf dem
vorhandenen Schema oder `CREATE SCHEMA` für ein neues Schema. Diese Prüfungen
decken noch nicht jede später ausgeführte Operation ab: `MarkRelease.sql`
schreibt zusätzlich zwei Extended Properties **auf Datenbankebene**;
`Uninstall.sql` entfernt sie. Laut Microsoft benötigen solche Marker eigene
wirksame Rechte; insbesondere darf `db_ddladmin` allein keine
datenbankweiten Properties hinzufügen. Siehe die Primärdokumentation zu
[`sp_addextendedproperty`](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addextendedproperty-transact-sql),
[`sp_updateextendedproperty`](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-updateextendedproperty-transact-sql)
und [`sys.sql_expression_dependencies`](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql).
Dass Schema-DDL-Rechte allein für den gesamten Lifecycle nicht genügen,
ist eine Schlussfolgerung aus diesen Quellen und dem vorliegenden Skript;
die exakte kleinste erfolgreiche Rechtemenge wurde **nicht** nativ belegt.

Ein späterer Minimalrechteversuch verwendet nur einen bereits vorhandenen,
ausdrücklich ausgewählten Testprincipal auf einem erlaubten Testziel. Vor
Deploy werden effektive Rechte und Ausgangszustand privat erhoben; ohne
passenden Principal bleibt der Versuch **NOT_EXECUTED**. Getrennt zu prüfen
sind Aufruf, Erstinstallation mit vorhandenem/neuem Schema, Repeat sowie
zentraler und lokaler Uninstall einschließlich Markerbereinigung. Ein
fehlgeschlagener Versuch benötigt Rollback-/Own-State-Audit. Der bisherige
physische Labadapter setzt für die eigene DB-Bereinigung `sysadmin` voraus;
seine Erfolge sind deshalb kein Minimalrechtebeweis. Diese Analyse vergibt
keine Rechte, erstellt keinen Principal und ändert kein SQL-Produktverhalten.

## Begrenzte 16-MiB-Verarbeitung und offene Lastfälle

Die reguläre CI prüft nur die sofortige Abweisung bei
16777218 Inputbytes. Für genau16777216 Bytes durchläuft die Funktion dagegen
den rohen Struktur- und den Unicode-Policyscan vollständig. Bei einem
nichtleeren Pointer kommt `OPENJSON` auf dem gewählten Fragment hinzu;
verschachtelte Pfade können erneut große Fragmente parsen und kopieren.
Deshalb ersetzt ein einzelner Grenzfall weder Heap- noch Worst-Case-Nachweis.

Ein separater, gezielt gestarteter Qualifikationslauf soll zuerst
eine eigene flüchtige SQL-Instanz mit synthetischen Daten verwenden. Jede
Größenstufe läuft in einem eigenen Prozess mit SQL-Commandtimeout höchstens
180 Sekunden, Arbeitswatchdog höchstens240 Sekunden und äußerem
Gesamtwatchdog höchstens300 Sekunden einschließlich60 Sekunden reserviertem
Cleanupfenster. Nach Timeout, unklarem Prozessende oder
unbestätigter Bereinigung endet die Stufenfolge ohne weitere Last. Der
reguläre PR-Runtime-Workflow erhält daraus keinen automatischen Maximaltest.
Der Workflow `JSON Pointer Runtime` bietet hierfür ausschließlich per
`workflow_dispatch` die Eingaben `workload_bytes`, `workload_shape` und
`workload_sql_version`; `workload_bytes=none` belässt die reguläre Matrix.
Jeder Lastaufruf führt genau einen Fall aus. Die Stufen sind manuell in der
Reihenfolge 64KiB,1MiB,4MiB,16MiB und zuerst `root`, danach `object`
zu starten. Der 7-Minuten-Jobtimeout ist nur eine letzte äußere Schranke;
ein dadurch hart beendeter Job ohne bestätigtes Cleanup ist INCONCLUSIVE.

1. Ein vollständiger JSON-String als Root mit leerem Pointer wird gestuft bei
   64 KiB,1 MiB,4 MiB und exakt16 MiB Original-`DATALENGTH` geprüft. Nur nach
   bestandenem kleineren Fall folgt die nächste Größe. Der Grenzfall enthält
   zwei Quotes und8388606 synthetische `a`-Codeeinheiten.
2. Erst nach bestandenem Rootfall folgt separat ein Objekt mit einem Key und
   `/k`, ebenfalls bis exakt16 MiB. So wird zusätzlich die native
   `OPENJSON`-Auflösung eines großen Werts geprüft. Tiefe128 mit großen
   Fragmenten ist ein weiterer, unabhängiger Lastfall.
3. Pro Versuch müssen genau eine FOUND/STRING-Zeile, NULL-ErrorCode, exakte
   `DATALENGTH(Value)` und der SHA2-256-Vergleich gegen den separat erzeugten
   synthetischen Erwartungswert bestehen. Der große Wert verlässt den Server
   nicht als Clientresultat; veröffentlicht werden nur Scope und Urteil.

Ein Timeout ist **INCONCLUSIVE** für die fachliche Semantik, kein PASS und
keine stillschweigende Absenkung des öffentlichen 16-MiB-Budgets. Erst nach
erfolgreichem flüchtigem Lauf darf derselbe begrenzte Versuch auf einem erneut
schema-validierten, ausdrücklich ausgewählten bereiten Labziel geplant werden;
eigene Ressourcen und Vorzustände benötigen private Journale und unabhängigen
Bereinigungsaudit. Gemessene Zeiten, Heap-/Hostwerte, reale Logs und
Zielinventar bleiben außerhalb des Repositories. Selbst zwei erfolgreiche
Grenzfälle belegen weder Tiefe128 bei Maximalgröße noch Parallelität oder
Produktionskapazität.

Am 2026-10-06 bestand ein gezielter lokaler Lauf des neuen Adapters mit
flüchtigem Linux-SQL-Server2019-Container und CL150. Für `root` und danach
`object` bestanden getrennte Prozesse bei 65536,1048576,4194304 und16777216
Originalbytes jeweils das Einzeilen-, Status-/Typ-, Längen- und SHA2-256-Orakel;
der jeweilige eigene Container war nach jedem Prozess entfernt. Ausführung:
`python Modules/toolbelt.json.pointer/Tests/CI/run_max_workload.py`
mit den Optionen `--sql-version 2019 --stage-bytes <Stufe> --shape <Form>`.
Dies ist ein einzelner synthetischer Host-/SQL-Versuch, kein Head-CI-Lauf,
kein gemessenes Heap-/Parallelitäts- oder produktives Leistungsversprechen.

Nach Merge von [PR201](https://github.com/gecompat/SQL_Server_Toolbelt/pull/201)
bestanden am 2026-10-06 auf `main`-Commit `d4c003d4234f97a26b097b5f06810fc93d003c1a`
zusätzlich alle acht *manuell* ausgelösten Einzeljobs auf flüchtigem Linux-
SQL2019-Container mit CL150. Jeder Job führte genau den genannten Fall aus;
die reguläre SQL-Matrix war bei diesen Dispatches erwartungsgemäß SKIPPED.

| Form | 64 KiB | 1 MiB | 4 MiB | exakt 16 MiB |
|---|---|---|---|---|
| Root, leerer Pointer | [37435680944](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37435680944) | [37435820068](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37435820068) | [37435903114](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37435903114) | [37435993020](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37435993020) |
| Objekt, `/k` | [37436158005](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37436158005) | [37436244282](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37436244282) | [37436327215](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37436327215) | [37436407146](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37436407146) |

Alle acht Lastjobs meldeten SUCCESS einschließlich eigenem Cleanup-Audit und
serverseitigem Einzeilen-/Längen-/Hashorakel. Der [reguläre Main-Push-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37435479777)
bestand getrennt auf Linux SQL2019/2022/2025; sein manueller Job war SKIPPED.
Lastläufe auf SQL2022/2025, anderen Plattformen, mit großen verschachtelten
Fragmenten oder Parallelität sowie Heap-/Produktionskapazität bleiben
**NOT_EXECUTED** beziehungsweise unqualifiziert.

### Verschachtelte Fragmentlast

Der zusätzliche manuelle Modus `workload_shape=nested` erzeugt `D` geschachtelte
Objekte mit demselben Key `k` und einen Pointer mit `D` Segmenten `/k`.
Bei Eingabelänge `B` Bytes enthält der terminale String exakt
`B/2 - 6D - 2` synthetische `a`-Codeeinheiten; die gesamte JSON-Eingabe
einschließlich Prefix, Quotes und Suffix muss exakt `B` Bytes lang sein.
Zulässige Tiefen sind 1,2,4,8,16,32,64,128, maximaler Pointer256
UTF-16-Einheiten. Die schon vorhandenen Einzeilen-/Wertlängen-/SHA2-256-
Oracles gelten unverändert. Nur für diesen Modus begrenzt Docker den eigenen
Container auf 3GiB Arbeitsspeicher ohne Swap. Dies ist eine Testobergrenze,
kein gemessener Heap- oder Runnerkapazitätswert.

Die sichere Stufenfolge beginnt mit 64KiB und verdoppelt die Tiefe bis128;
anschließend kann Tiefe128 getrennt mit1MiB,4MiB und16MiB geprüft werden.
Jede Stufe besitzt einen eigenen Container/Prozess und dieselben 180-/240-/
300-Sekunden-Grenzen. Nach Timeout, technischen Ressourcenfehlern oder
unklarem Cleanup werden keine größeren Stufen gestartet. Der reguläre PR-/
Push-Workflow führt keinen dieser Fälle automatisch aus.

Am 2026-10-06 bestanden lokale flüchtige Linux-SQL2019-CL150-Proben bei
64KiB/Tiefe2,4,8,16,32,64,128 und anschließend bei Tiefe128 mit1MiB,4MiB
und exakt16MiB. Die unveränderten Root- und einfachen Objektpfade bestanden
danach erneut bei64KiB. Jeder Prozess bestätigte seinen eigenen Container-
Cleanup; es wurde kein Host-Port veröffentlicht. Das ist begrenzte lokale
synthetische Evidenz. Der manuelle GitHub-Dispatch des neuen Tiefenmodus,
andere SQL-Versionen/Plattformen, allgemeine JSON-Strukturen, parallele Last
und produktive Kapazität waren bei diesem lokalen Lauf **NOT_EXECUTED**.

Nach Merge von [PR203](https://github.com/gecompat/SQL_Server_Toolbelt/pull/203)
bestanden am 2026-10-06 auf `main`-Commit `bb301fc73f13b3af1de377973f38678cf157e32e`
auch zehn getrennte *manuelle* Tiefenjobs auf flüchtigem Linux-SQL2019-
Container mit CL150. Bei 64KiB wurden die Tiefen der Reihe nach erhöht:
[2](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37438559822),
[4](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37438651184),
[8](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37438740501),
[16](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37438830781),
[32](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37438918840),
[64](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37439009964)
und [128](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37439102708).
Bei Tiefe128 folgten getrennt
[1MiB](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37439244664),
[4MiB](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37439329406)
und [exakt16MiB](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37439471664).
Alle zehn Lastjobs meldeten SUCCESS einschließlich serverseitigem Oracle und
eigenem Cleanup-Audit; die reguläre Matrix war bei den manuellen Dispatches
SKIPPED. Der getrennte [Main-Push-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37438354749)
bestand regulär auf Linux SQL2019/2022/2025 mit SKIPPED-Lastjob.
Maximalgrößen auf SQL2022/2025, anderen Plattformen, in anderen JSON-
Strukturen oder unter Parallelität sowie tatsächlicher Heapverbrauch,
Hard-Interrupt-Recovery und Produktionskapazität bleiben offen.

## Ausstehender Nachweis nach hartem Prozessabbruch

Der manuelle Lastadapter entfernt seinen eigenen Container in einem Python-
`finally`; der reguläre Linux-Adapter verwendet einen Shell-`EXIT`-Trap.
Beides wirkt nur, solange der jeweilige Prozess seine Aufräumroutine noch
ausführen kann. Ein `SIGKILL`, ein abrupt beendeter Runner oder ein nicht
erreichbarer Docker-Daemon ist damit **nicht** als bereinigt nachgewiesen.
Die Workflow-Einstellung `cancel-in-progress: false` verhindert lediglich
die automatische Ablösung eines laufenden Jobs; sie ist kein Recoverytest.

Ein eigenständiger Hard-Interrupt-Nachweis benötigt einen *außerhalb* des
Testprozesses laufenden Supervisor und ausschließlich einen eigens erzeugten,
flüchtigen Docker-Container. Vor dessen Start hält der Supervisor eine zufällige
Owner-ID und den daraus deterministisch gebildeten Containernamen in einem
privaten, nicht versionierten Journal fest. Der Testcontainer trägt dieselbe
Owner-ID als Docker-Label. Weder fremde Container noch gemeinsam genutzte
Labziele dürfen für diesen Nachweis beendet werden.

1. Einen kleinen synthetischen Test starten und nach bestätigtem Containerstart
   den *Kindprozess* hart beenden. Der Supervisor selbst muss weiterlaufen.
   Die Unterbrechung vor und nach dem Schreiben der Container-ID sind getrennte
   Fälle; ein bloßes `EXIT`-Trap- oder `finally`-Ergebnis zählt nicht.
2. In einer frischen Supervisoraktion Name **und** Owner-Label exakt vergleichen.
   Nur bei Übereinstimmung den eigenen Container gezielt entfernen und durch
   eine erfolgreiche Docker-Abfrage seine Abwesenheit prüfen. Ein fehlendes
   Label, ein fremdes Label oder ein unerreichbarer Daemon verbietet blindes
   Entfernen und ergibt `INCONCLUSIVE` bis zur manuellen Zuordnung.
3. Als Negativkontrolle einen absichtlich falschen Owner gegen den noch
   vorhandenen eigenen Container prüfen: Der Versuch muss die Entfernung
   verweigern. Anschließend erfolgt die Entfernung ausschließlich mit der
   richtigen Owner-ID. Ein neuer, unabhängiger Audit bestätigt die Abwesenheit
   und das unveränderte fremde Umfeld. Bei unbekanntem Cleanup keine weitere
   Laststufe starten.

Am 2026-10-06 bestand die separat manuell gestartete lokale Probe
`python Modules/toolbelt.json.pointer/Tests/CI/test_hard_interrupt_recovery.py`
für beide kontrollierten Fälle vor/nach CID-Schreiben. Sie nutzte ein bereits
lokal vorhandenes SQL2019-Linux-Image nur als flüchtigen `sleep`-Container,
ohne SQL-Start, Portfreigabe, Netz oder Labziel. Der unabhängige Elternprozess
beendete jeweils das Kind hart, verweigerte die Entfernung mit falscher
Owner-ID, entfernte nur den exakt gelabelten eigenen Container und bestätigte
dessen Abwesenheit. Eine zusätzliche frische Docker-Abfrage bestätigte, dass
kein Container mit dem Test-Owner-Label verblieb. Das ist **PASSED** allein für
diese lokale Kindprozess-/Docker-Recoverymechanik.

Runnerverlust, Hostausfall, Docker-Daemon-Ausfall, SQL-Transaktionszustand,
geteilter Labzustand, ein fremder Container als eigene Testfixture und
allgemeine CI-Abbruchfreigabe wurden **NOT_EXECUTED**. Ein `finally` oder
Workflow-Timeout gilt weiterhin nicht als Recoverybeweis; die allgemeine
Hard-Interrupt-Recovery bleibt offen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope full`
- Scope: Zusätzliche vollständige Läufe auf demselben schema-validierten, exakt ausgewählten Windows2025/CU8-Ziel mit CL150 und CL160 bestanden jeweils local/central/Consumer, Contract/Safety, direkte Clientmetadaten, Repeat und42 Lifecyclefälle. Je Exit0, vollständige Kanäle und leeresStderr; frische unabhängige Audits bestätigten COMPLETE42, drei eigene DBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit zwei Abweisungen, unveränderte Inputpins und Nullscope Konfiguration/Rechte/Trust. CL150/160 sind getrennte neue Nachweise; CL170 und Linux2019 CL150 bleiben frühere Nachweise. Weitere physische Ziele, Minimalrechte,16MiB-Maximalworkload/Heap und vollständige Runtime-Head-CI offen; teilweise validiert, unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
