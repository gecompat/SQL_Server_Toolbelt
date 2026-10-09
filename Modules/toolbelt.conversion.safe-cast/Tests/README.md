# Safe Cast – Tests

Die [Testmatrix](SAFE_CAST_TEST_MATRIX.md) beschreibt den synthetischen
182-Fälle-API-Vertrag, tatsächliche Clientmetadaten und die installierte
Lifecyclebaseline der sechs einzeln freigegebenen Inline-TVFs.
Die erfolgreiche native Teilqualifikation und ihre Grenzen stehen unten;
Code und Offlineprüfung ersetzen sie nicht.

`Runtime/Contract.Tests.sql` bindet den expliziten SQLCMD-Wert
`ToolbeltDatabase` (leer=currentDB, Name=central), verwendet feste Zieltypen
und führt CROSS/OUTER APPLY in drei Language/DATEFORMAT-Sitzungsformen mit
vier Inputcollations aus. Private `#tbx_SafeCast_`-Temps werden vor der Anlage
auf Kollision geprüft. Surrogatfixtures entstehen aus festen UTF16-Binarybytes.
Ein unerwarteter Enginefehler ist FAIL, keine erfolgreiche Statusrow.

`Runtime/Metadata.Tests.ps1` erhält eine bereits offene SqlConnection,
optional `ToolbeltDatabase`, `CommandTimeoutProvider` und `ReadBudgetProvider`.
Es prüft echte Clientmetadaten und Katalogbindungen für sechs Funktionen;
18 direkte Reader müssen genau eine Row ohne weiteren Resultset liefern.

Testwartung 2026-10-09 (SOURCE_ONLY): Der Helper besitzt seinen Command bis
zur erfolgreichen Rückgabe und disponiert ihn bei einem Setupfehler davor.
Beide Parameter-Setups liegen nun im bestehenden Command-try des Callers.
Die übergebene Connection bleibt fremdes Eigentum; SQL, Timeouts, ReadBudget,
Reader-/Resultsetorakel und Erfolgsmarker bleiben unverändert. Ein Disposefehler
kann weiterhin den primären Fehler ersetzen. Die geänderten Ausnahmezweige
sind noch nicht nativ ausgeführt; die unten datierten Nachweise behalten
jeweils ihren historischen Umfang. Kein gemessener Leak- oder Ursachenbeleg.

`Runtime/Lifecycle.Tests.sql` qualifiziert nur die installierte Baseline.
Der eigene CI-Adapter besitzt Setup/Repeat, zentrale Consumer, Confirm,
Caller-/AppLock-/Rollback-/Fremdslot-/Markerfälle und Uninstall/own cleanup.
Ein installierter Marker oder vorhandener Testcode beweist diese Fälle nicht.

Statisch: `python Modules/toolbelt.conversion.safe-cast/Tests/Static/validate_contract.py`.
Der pfadbezogene Dokumentationsworkflow führt diesen Source-/Deploymentvertrag
bei Änderungen am Safe-Cast-Modul ebenfalls aus; das ist kein SQL-Runtime-
oder vollständiger exakter Head-CI-Nachweis.
`Tests/CI/Test-LabDriverArgumentCase.ps1` prüft die Parameterbindung des
Labtreibers mit synthetischen Argumenten ohne Verbindung zum Lab.
Der gekoppelte Generator läuft ausschließlich im nicht schreibenden Checkmodus.
Der [Safe-Cast-Runtime-Workflow](../../../.github/workflows/safe-cast-runtime.yml)
prüft in flüchtigen Linux-SQL-Server-Containern 2019/2022/2025 die zulässigen
Compatibility Levels mit local/central/Consumer: feste API-Fixtures,
Clientmetadaten, installierte Baseline, Repeat und Uninstall.
`CI/Test-SafeCastLifecycle.ps1` verwendet die unveränderten kanonischen
Funktionen aus `Tests/CI/SafeCastLifecycle.Helpers.ps1`: je CL 18 local- und
20 central-Fälle. Dazu gehören acht Callerfälle pro Modus mit intakter oder
doomed Transaktion und XACT_ABORT OFF/ON, zwei AppLockfälle, vier
post-DROP/pre-COMMIT-Rollbackfälle, zwei typisierte Markerfälle und zwei
Fremdslotfälle. Central ergänzt zwei Confirm0-Abweisungen. Die Calleroracles
prüfen Transaktionszustand, Sentinel und SET-Optionen auf derselben Connection.
Die bisherigen überlappenden zentralen Teilprüfungen entfallen. Ein
synthetisch auf `9.9.9` gesetzter Release-Marker muss Deploy und Uninstall
mit `55424/state2` abweisen. Marker und sechs TVFs bleiben erhalten; nach
Wiederherstellung des eigenen Markers besteht die Baseline.

Der Driver bindet jede Testconnection an den vor Installation erfassten
synthetischen Owner, Database-ID, CreateDate, Modus und CL. Er pinnt die
geladenen Helperbytes und Deploymentquellen. Das private Restorejournal muss
nach Prozessende COMPLETE, exakt 18/20 bestandene Fälle und beide erfolgreich
restaurierten Fixtures mit je zwei Abweisungen belegen. Der Driver besitzt
den bestätigten Uninstall und dessen Repeat; eine frische Prüfung verlangt
die Abwesenheit der eigenen Releaseobjekte. Seine Arbeitsfrist beträgt
120 Sekunden mit 30 Sekunden Restore-Reserve; der äußere Prozess endet
spätestens nach 160 Sekunden zuzüglich fünf Sekunden Kill-Frist. Ein Timeout
ist kein PASS und beweist keine Wiederherstellung nach hartem Prozessabbruch.
Der reguläre
flüchtige CI-Container trägt eine zufällige Owner-Kennung. Beim normalen
Prozessende werden volle Container-ID und Kennung gemeinsam gelesen. Nur bei
gültiger ID und exakt passender Kennung wird diese ID entfernt; eine frische
Docker-Abfrage muss die Namensabwesenheit bestätigen, sonst schlägt der CI-Job
fehl. Run-/Attempt-/SQL-Identität vor Setup geprüft; das private Verzeichnis
entsteht erst nach fallibler Owner-/Kennwortvorbereitung. Bestätigter Cleanup
meldet `SAFE_CAST_CI_CLEANUP_VERIFIED` und erhält den ursprünglichen Fehlerstatus;
ein fremder Namensersatz wird nicht entfernt. Kein Recoverybeweis nach hartem
Runner-/Hostausfall.

`python Tests/CI/test_owned_container_cleanup.py --module safe_cast` prüft die
echte Safe-Cast-Cleanupfunktion in13 synthetischen Fällen: eigener/fremder Owner,
Daemon-/Inspect-/Entfernungs-/Nachlistenfehler, bereits fehlender oder verbleibender
Container, ursprünglicher Fehler7, Namensaustausch und ungültige ID-/Ownerformen
oder Extrafelder. Die bestehende Dokumentations-CI startet den gemeinsamen
Test bei Änderungen am registrierten Adapter oder der Probe. Kein Docker/SQL
und kein Hard-Interrupt-Nachweis; echte Head-/Main-Zeugen separat im PR.

Ein synthetischer View im zentralen Provider belegt zusätzlich eine tatsächliche
`sys.sql_expression_dependencies`-Referenz. Deploy und Uninstall müssen ihn
mit `55425/state3` abweisen; die installierte Baseline und der View bleiben
bis zur kontrollierten Entfernung des Testverbrauchers erhalten.
Die 38 Lifecyclefälle sind jetzt Teil des CI-Adapters; ihre tatsächliche
Ausführung muss am exakten PR-Head nachgewiesen werden. Minimalrechte,
Hard-Interrupt-Recovery und gemessene Ressourcen bleiben separate Grenzen.
Lokale statische Prüfung und Client-AST bestanden am 2026-10-05;
Beide SQLfixtures bestanden anschließend die unabhängige ScriptDom150-
Offlineprüfung (je 0 Syntaxfehler, leerer ToolbeltDatabase). Native Ausführung
war in diesem Vorbereitungsstand offen; die späteren Läufe stehen unten.

Der erste begrenzte lokale Lauf am 2026-10-05 auf SQL Server 2019 Linux/latest
CL150 scheiterte beim lokalen Deploy mit SQL1054/state6: Projektionswildcards
in den CTEs sind bei SCHEMABINDING unzulässig. Kein API- oder Lifecyclefall
wurde dadurch qualifiziert. Der Lauf endete `FAILED_CLEANED`; eine unabhängige
neue Verbindung bestätigte die Abwesenheit der einzigen eigenen Testdatenbank
und die unveränderten eingefrorenen Inputs. Keine Konfigurations-, Rechte-
oder Truständerungen. Vollständige Kanäle und eigene Journale bleiben privat.
Die Korrektur ersetzt die Wildcards durch explizite Spaltenlisten und ergänzt
den statischen Vertrag um deren Verbot; erfolgreiche Wiederholung ist separat
nachzuweisen.

Der korrigierte zweite Lauf bestand Deploy und Repeat, scheiterte aber im
API-Fixture mit SQL102/state1 an einem geklammerten COLLATE-Namen im dynamischen
Test-SQL. Eine separate reine SELECT-Probe reproduzierte diesen Syntaxfehler.
Die feste interne Vierer-Allowlist wird deshalb ohne Identifierklammern
eingesetzt; der öffentliche Funktionsvertrag bleibt unverändert. Auch dieser
Lauf endete `FAILED_CLEANED`, mit unabhängig frisch bestätigter Abwesenheit
seiner einzigen eigenen Datenbank und vollständig geprüften Inputpins.
Kein vollständiger API-, Client- oder Lifecycle-PASS aus diesem Lauf.

Der dritte Lauf bestand lokal die 4368 festen API-Oracles, installierte
Lifecyclebaseline, Clientmetadaten und 16 gezielte Caller-/Lock-/Rollback-/
Markerfälle einschließlich exakter Markerwiederherstellung. Nach dem echten
Uninstall scheiterte die Vorbereitung des Fremdslotfalls an
`SAFE_CAST_COMPLETE_SNAPSHOT_INVALID`. Er endete `FAILED_CLEANED` mit
Bereinigung im Lauf; der unabhängige neue Audit bestätigte die Abwesenheit
der einzigen eigenen Datenbank, alle Inputpins und unveränderte Nullscopes
für Konfiguration, Rechte und Trust. Eine reine synthetische SELECT-Probe
zeigte: scalar FOR JSON bei leerer Liste und dessen Hash sind NULL; explizites
`N'[]'` erhält einen vollständigen Hash. Der Adapter normalisiert seine drei
obersten Metadatenlisten entsprechend, ohne Vergleichsfelder zu entfernen.
Kein Gesamt-PASS, kein zentraler oder Windows-Nachweis aus diesem Teillauf.

Der vierte Gesamtadapter bestand am 2026-10-05 auf SQL Server 2019 Linux/latest
CL150, jeweils local und central sowie mit separatem zentralem SC-/UTF8-Consumer.
Drei Ausführungen des API-Fixtures ergeben13104 feste APPLY-Oracles;
Clientmetadaten umfassen54 direkte Reader. Clean/Repeat, installierte Baseline,
Uninstall/Repeat und 38 konkrete Lifecyclefälle bestanden: Callerzustände,
AppLock, vier Rollbackinjektionen je Modus, typisierte Marker, Fremdslots
und zentrale Confirm0-Abweisung. Jede Marker-/Fremdslotfixture wurde exakt
wiederhergestellt. Tatsächlicher Exit0, vollständige Kanäle und leeres Stderr.
Der unabhängige neue Audit bestätigte COMPLETE, alle eingefrorenen Inputs,
zwei Marker- und zwei Fremdslotfixtures mit je zwei Abweisungen und erfolgter
Wiederherstellung sowie die Abwesenheit aller drei eigenen Datenbanken.
Keine Konfigurations-, Rechte- oder Truständerungen. Weitere physische Ziele,
Minimalrechte und Heap-/Produktionskapazität bleiben `not executed`;
Windows und exakte Head-CI sind getrennte Nachweise. Die drei früheren
Gesamtfehlläufe bleiben fehlgeschlagen.

Der anschließende Windows-Gesamtadapter bestand mit demselben finalen Produkt-,
Fixture- und Adapterstand auf SQL Server 2025/exaktCU8 CL170. Derselbe local/
central/Consumer-Scope mit 13104 festen API-Oracles,54 direkten Clientreadern
und 38 Lifecyclefällen; Exit0, vollständige Kanäle und leeres Stderr.
Der unabhängige neue Audit bestätigte COMPLETE38, drei eigene Datenbanken
abwesend, alle Inputpins und je zwei exakt wiederhergestellte Marker- und
Fremdslotfixtures mit je zwei Abweisungen. Keine Konfigurations-, Rechte-
oder Truständerungen. Beide begrenzten Zielnachweise ergeben `partially validated`,
`unreleased`; übrige physische Ziel-/CL-Matrix, tatsächliche Minimalrechte,
Heap und exakte Head-CI bleiben separate Nachweise.

Am 2026-10-06 bestanden auf demselben zuvor ausgewählten, schema-validierten
Windows2025/exaktCU8-Ziel auch CL150 und CL160 mit dem vollständigen local/
central/Consumer-Scope. Je 13104 feste API-Oracles, 54 direkte Clientreader,
38 Lifecyclefälle und Uninstall/Repeat; tatsächlicher Exit0, vollständige
Kanäle und leeres Stderr. Zwei frische unabhängige Audits bestätigten je
COMPLETE38, drei eigene Datenbanken abwesend, je zwei Marker- und
Fremdslotfixtures exakt wiederhergestellt mit je zwei Abweisungen sowie
unveränderte Input- und sechs Sourcepins. Keine Konfigurations-, Rechte- oder
Truständerungen. Die frühere CL170- und Linux-Evidenz bleiben eigenständige
Nachweise; weitere physische Ziele, Minimalrechte, Heap und vollständige
Runtime-Head-CI sind weiterhin offen.

Der begrenzte Modulworkflow bestand am 2026-10-06 am exakten
[PR186-Head](https://github.com/gecompat/SQL_Server_Toolbelt/pull/186):
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402202963)
und [Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402203046)
waren erfolgreich, einschließlich aller drei Linux-Jobs 2019/2022/2025.
Nach Merge bestanden auf `main` erneut
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837670)
und [Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837558).
Die 38 gezielten Lifecyclefälle des Labadapters sind nicht Teil dieser CI.
Der zentrale Runtime-CI-Adapter prüft zusätzlich vier im Speicher injizierte
Rollbackfälle für Deploy/Uninstall nach `DROP` beziehungsweise vor `COMMIT`.
Dabei müssen der vollständige Modul-Katalogsnapshot und der neutrale Zustand
derselben SQL-Verbindung erhalten bleiben. Die vollständige physische
Lifecycle-Suite bleibt ein separater Nachweis.
Die flüchtige Runtime-CI führt zusätzlich am höchsten unterstützten
Compatibility Level je SQL-Version 1910 deterministische, rein synthetische
Differentialfälle aus. Python `Decimal` liefert Status und exakten Wert für
411 Dezimalfälle; der Python-Kalender liefert Status und NULL-Erwartung für
622 `date`-/`datetime2(7)`-Fälle. Python `int` und `uuid` sowie die strikten
ASCII-Lexiken liefern Status, Fehlercode und Wert für 411 `bigint`-, 210 `bit`-
und 256 `uniqueidentifier`-Fälle. Dies ersetzt weder die festen API-Oracles
noch die übrigen Ziel-, Ressourcen- und Lifecycleprüfungen.
Die Generatoren sichern vor der SQL-Ausgabe die festen Fallzahlen und die
erforderlichen Statuskategorien ab; feste Lexik- und Grenzfälle erhalten ein
gültiges Bytebudget, damit sie nicht zufällig am Parameter-Gate enden.
Weitere physische Ziele, tatsächliche Minimalrechte, Hard-Interrupt-Recovery,
Heap und Releasequalifikation bleiben offen; `partially validated`,
`unreleased`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `local: Tests/CI/run-safe-cast-lab.ps1`
- Scope: Auf demselben bereits ausgewählten schema-validierten Windows2025/exaktCU8-Ziel bestanden zusätzlich CL150 und CL160 mit jeweils vollständigem local/central/Consumer-Adapter: je 13104 feste API-Oracles, 54 direkte Clientreader und 38 Lifecyclefälle. Je Exit0, vollständige Kanäle und leeres Stderr. Frische unabhängige Audits bestätigten COMPLETE38, drei eigene DBs abwesend, je zwei Marker-/Fremdslotfixtures exakt restauriert mit zwei Abweisungen sowie unveränderte Input- und sechs Sourcepins. Keine Konfigurations-/Rechte-/Truständerungen. Weitere physische Ziele, Minimalrechte, Heap und vollständige Runtime-Head-CI bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
