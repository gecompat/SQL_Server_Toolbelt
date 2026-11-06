# Worker Control – Testnachweise

## Weitere Windows-Providerkontexte vom 2026-11-06

Zwei weitere aktuelle `ManagedOnly`-Gesamtfälle bestanden mit tatsächlichem
Windows-Workerhost und unveränderten elf Providerorakeln. Der bereits grüne
2025/CL170-Kontext wurde wiederverwendet, nicht wiederholt.

| Windows-SQL-Ziel | CL | Umfang | Gesamtkoordinator und separater Audit |
|---|---|---|---|
| 2019/CU32 | 150 | local, elf Providerfälle | bestanden |
| 2022/CU26 | 150 | local, elf Providerfälle | bestanden |
| 2025/CU8 | 170 | unten gebundener vorhandener Gesamtfall | bestanden, wiederverwendet |
| 2022/CU26 | 160 | elf Providerfälle bestanden | Gesamtlauf fehlgeschlagen, separat bereinigt und frisch auditiert |
| 2025/CU8 | 150/160 | weitere Provider-Gesamtfälle | nicht ausgeführt |

Die neuen Produkt-/Provider-/Fixturequellen sind an
[00ae181b](https://github.com/gecompat/SQL_Server_Toolbelt/tree/00ae181bc6b160ec2d6d16ddf776e8c0dba1285c)
gebunden und unverändert. Die beiden grünen Fälle haben jeweils ein finales,
hashgebundenes Providerergebnis mit elf PASS-Fällen ohne Nebenfehler und einen
separaten frischen Audit. `FullProduct=false` bleibt erhalten.

Der 2022/CL160-Aufrufer scheiterte nach erfolgreichem Providerpfad am
unveränderten kombinierten Katalog-/Verbraucherguard mit SQL50000/State1.
Welches Prädikat zum damaligen Zeitpunkt abwies, wurde nicht gemessen.
Die spätere lesende Inspektion bestätigte dieselbe eigene Datenbankidentität,
Erzeugungsbytes, Eigentümer und Runmarker, keine anderen Sessions/Requests
und keine belegten Slots. Erst danach entfernte der unveränderte ursprüngliche
Dropguard die eigene DB. Ein zunächst wegen des leeren Fixtureunterverzeichnisses
blockierter eigener Dateischritt wurde separat eng begrenzt abgeschlossen;
alle Originale und Fehler bleiben erhalten. Der reservierte frische lesende
Audit bestätigte finale DB-/Dateiabwesenheit und unveränderte erfasste fremde
Zustände. Das macht den ursprünglichen Gesamtkoordinator nicht zum PASS.

Die restlichen Providerfälle wurden gestoppt. Elf der höchstens 13 reservierten
Ziel-/Auditdispatches dieses Rahmens sind verbraucht und geschlossen, drei
eigene Datenbanken entfernt. Zusammen mit dem vorherigen Einzelkontext sind
14 von maximal 16 Providerdispatches und vier eigene Datenbanken verbraucht;
freie Plätze eröffnen keinen erneuten Gesamtlauf. Keine Rechte-, Server-,
Trust-, CLR- oder Infrastrukturänderung. Quellenpins bestanden vor den
Dokumentationsnachträgen. Die vollständige Windows-Providermatrix bleibt
offen; teilweise validiert und unveröffentlicht.

## Aktueller Windows-Workerprovider vom 2026-11-06

Ein separater frischer `ManagedOnly`-Gesamtfall mit tatsächlichem
Windows-Workerhost gegen WindowsSQL2025/CU8/CL170, local, bestand alle elf
festen Fälle des aktuellen
[`Invoke-ManagedContract.ps1`](../../../Workers/ExternalQueue/Tests/Runtime/Invoke-ManagedContract.ps1).
Produkt-, Provider- und Fixturequellen sind an
[d271b846](https://github.com/gecompat/SQL_Server_Toolbelt/tree/d271b846b3df91ba31004808d634d72e81f39e3d)
gebunden und bleiben unverändert.

Die bestehenden Orakel beobachteten leere BOUNDED-/CONTINUOUS-Betriebsarten
mit zwei Supervisoren, Nullbudget und reduzierte Livekapazität ohne Abbruch
laufender Arbeit, tatsächlichen Cancel/Rollback mit Hold, explizite Freigabe
und den anderen registrierten Worker, Legacyclaim-Abweisung, bekannten Commit
gegen späten Stop sowie den echten Completion-/Stop-Rendezvous.
Der gezielte Controltimeout blieb UNKNOWN, belegte seinen Slot und verhinderte
Replay. Unberechtigte UNKNOWN-Freigabe wurde abgewiesen; explizite
Reconciliation bestätigte das gesonderte Ressourcenende.

Der private quellgebundene Aufrufer bindet wie im SQL-Gateumfang eigene
GUID/Runmarker/CL/Pfade, endliche Timeouts und das Originaljournal. Zusätzlich
bewahrt er das tatsächliche Providerergebnis mit genau den elf quellfesten
PASS-Fällen, ohne Nebenfehler und mit unverändertem `FullProduct=false`.
Ein frischer separater lesender Audit bindet Plan, finales Originaljournal,
Adapter und Providerergebnis und bestätigt eigene DB-Abwesenheit sowie
unveränderte erfasste Server-, Konfigurations-, Trust-, Principal-/Rechte-
und CLR-Zustände. Eigene Fixtureverzeichnisse sind entfernt; alle drei
reservierten Ziel-/Auditdispatches sind abgeschlossen. Keine Rechte-,
Konfigurations-, Trust- oder Infrastrukturänderung. Postpins bestanden vor
den abgeleiteten Dokumentationsnachträgen; Originale bleiben privat.

Das ist der tatsächliche fokussierte Windows-Providerpfad dieses Kontexts.
Weitere SQL-Versionen/CLs des Providers, zentrale/CrossDB-Identitäten,
Minimalrechte, echter Host-/Committransportverlust und volle Modulqualifikation
bleiben gesondert. Der folgende sechsfach ausgeführte SQL-Gateumfang ist ein
anderer Testpfad und wird nicht als zusätzliche Provider-Matrix ausgegeben.
Teilweise validiert und unveröffentlicht.

## Aktuelle Windows-SQL-Gates vom 2026-11-06

Die aktuellen Produkt- und Fixturequellen aus
[633eb6a2](https://github.com/gecompat/SQL_Server_Toolbelt/tree/633eb6a26f2e4b11f5c01051ff0e68dff189e415)
bestanden den vorhandenen `ManagedSqlOnly`-Umfang auf sechs ausdrücklich
ausgewählten Windows-SQL-/CL-Kontexten im schema-validierten Labvertrag:

| SQL-Ziel | CL | Deployment | SQL-Fixture und sechs Lifecycle-Abweisungen | Frischer separater Audit |
|---|---|---|---|---|
| Windows 2019/CU32 | 150 | local | bestanden | bestanden |
| Windows 2022/CU26 | 150 | local | bestanden | bestanden |
| Windows 2022/CU26 | 160 | local | bestanden | bestanden |
| Windows 2025/CU8 | 150 | local | bestanden | bestanden |
| Windows 2025/CU8 | 160 | local | bestanden | bestanden |
| Windows 2025/CU8 | 170 | local | bestanden | bestanden |

`WorkerControl.Contract.sql` prüft die bestehenden SQL-Gates für Admission,
Generationen, Holds und private Autorität. Pro Kontext wurden anschließend
Occupied, Held und Dependency jeweils gegen den tatsächlichen Deploy- und
Uninstallaufruf geprüft: sechs exakte Number-/State-Abweisungen mit vorherigem
Snapshot und nachfolgendem vollständigem Datenvergleich, insgesamt 36.

Der quellgebundene private Adapter leitet denselben vorhandenen Weg aus
`Workers/ExternalQueue/Tests/Runtime/Invoke-Contract.ps1 -ManagedSqlOnly` ab.
Er bindet eigene GUID-Datenbank, Runmarker und Dateipfade, setzt und prüft den
CL ausschließlich in dieser Datenbank, begrenzt Command-Timeouts und bewahrt
das finale Originaljournal vor dessen regulärer Dateibereinigung. Produkt-
und Fixtureorakel sind unverändert; zusätzliche öffentliche Parameter wurden
nicht eingeführt. Vor SQL-Zugriff bestanden die exakten Adapteranker und
Grammatikprüfung sowie synthetische Snapshot-Stabilitäts-/Driftgegenproben.

Alle sechs eigenen Datenbanken und temporären Fixtureverzeichnisse sind
entfernt. Sechs frische lesende Audits binden jeweils finales Plan- und
Originaljournal und bestätigen unveränderte Serveridentität, Konfiguration,
Trust sowie erfasste fremde Datenbank-, Principal-, Rechte- und CLR-Zustände.
Keine Serverkonfigurations-, Trust-, SQL-GRANT-, Login- oder Rollenänderung.
Alle 15 reservierten Ziel-/Auditdispatches sind abgeschlossen. Quellenpins
bestanden vor den abgeleiteten Dokumentationsnachträgen; Originale bleiben
privat. Die Produkt- und Fixturebytes bleiben auch nach diesen Nachträgen
unverändert.

Windows bezeichnet hier die SQL-Zielplattform. Die Funktionsverbindungen
verwenden die erforderliche Verschlüsselung und den expliziten Trustwert des
Labvertrags. Authentifiziertes TLS, Windows-/SSMS-Anmeldung, Workerprovider,
zentrale/CrossDB-Verwendung, Minimalrechte, Transport-/Hostverlust und volle
Modulqualifikation sind gesonderte Nachweise. Das Modul bleibt teilweise
validiert und unveröffentlicht. Frühere datierte Ergebnisse unten behalten
ihren ursprünglichen Quellen- und Umfangsbezug.

Der zusätzliche ruhende Verbundrepeat wird im vorhandenen `QueueUpgradeOnly`-
Adapter nach dem genuine Queueupgrade und dessen bisherigen Repeats geprüft.
Legacyclaims werden vor Controlinstallation ausdrücklich abgeschlossen.
Eine eigene synthetische Fixture enthält terminale Controlhistorie und alle
zehn persistenten Queue-/Control-/WorkType-Tabellen. Zwei vollständige Repeats
vergleichen binäre Zeilen einschließlich Tokens/Rowversions, Tabellen- und
APIidentität, Identitymetadaten und semantische Katalogdefinitionen.
Bestehende Berechtigungen werden gelesen; eine zusätzliche Rechtevergabe
erfolgt nicht. Ein nichtleerer Benutzergrant ist daher nicht qualifiziert.
Konkurrenz- und Faultfälle prüfen unveränderte Daten und neutrale eigene
Sitzungen; die Callertransaktion wird nicht vom Installer zurückgerollt.
Gezielte Schemaabweisungen prüfen gepolsterte Versionsmarker, umbenannte
Checks und einen deaktivierten Idempotenzindex. Gate- und Reservationsperren
werden gegen beide Installer geprüft. Der separate Source-Fault wird nur
durch den Adapter auf dessen eigener identitätsgeprüfter Session zurückgerollt.
Dieser Scope bestand am 2026-10-07 auf SQL Server 2019 Linux am Commit
`91507c65ac24051890a1775cc4264c8c119f549f` im bestehenden
`External Queue Worker`-Workflow, Schritt `Execute genuine Queue 2.0 to 2.1 upgrade`
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37672934548)).
Ausgeführt wurden zwei vollständige Queue-/Control-Repeats, sechs
Caller-/Implicit-/Timeoutfälle, acht Zustands-/Metadatenabweisungen, vier
Writerkonflikte und der eigene PostSource-Rollback. Zeilen, Identitäten und
semantischer Katalog blieben unverändert; eigenes Zielcleanup bestand.
Die separate Queue-Runtime-Matrix auf 2019/2022/2025 Linux qualifiziert keine
zusätzliche Plattform für diesen neuen Verbundscope. Weitere Verbundziele
und nichtleere Benutzergrants bleiben `not executed`; frühere fehlgeschlagene
Läufe behalten ihren Status. Offlineparser sind nur Syntaxnachweise.

Der Stand ist **partially validated**. Am 2026-10-04 bestand `Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedSqlOnly` auf einem schema-validierten, ausdrücklich ausgewählten SQL-Server-2019-Linux-Ziel. Statische Kopplung und Offlineparser sind keine zusätzliche SQL-Laufzeitqualifikation. Die gezielten parallelen Providerläufe sind unten getrennt belegt; zu diesem Zeitpunkt blieb die exakte Head-CI ein separates Mergegate.

`Static/validate_contract.py` prüft die Source-/Manifest-/Lifecyclekopplung, getrennten Completiontest vor Witnesszugriff, nonblocking GroupStop und Sessionfence bis Reconcile-Commit. `Runtime/WorkerControl.Contract.sql` prüft synthetisch Admission, Livebudget und pausenerhaltende Generationen auf einer isolierten Modulinstallation. Die parallelen Guardian-/Transaction-/Stop-/Commitnachweise liegen in `Workers/ExternalQueue/Tests/Runtime/Invoke-ManagedContract.ps1` und werden getrennt bewertet.

Vor Abnahme erforderlich: tatsächlich ausgeführte gezielte SQL- und Providerfälle, unabhängiges Review und grüne erforderliche CI. Fehlende Laufzeitfälle bleiben NOT EXECUTED. Keine Zielinventare, Connectionstrings oder realen Runtimeausgaben in Repositoryartefakten.


## Fokussierte Negativwelle – bestanden auf SQL Server 2019 Linux

Basic prüft vor Opt-in, falsche private Admission-/Bind-/Witnessautorität, die14 öffentlichen Helpobjekte und gehaltene SHARED-/Barrierarbeit (Recovery, Retry, Requeue, Complete, Fail, UNKNOWN-Release). Synthetische Leasealterung spart Wartezeit und ist kein tatsächlicher Handlerrollbacknachweis. Aktuelle Sourceorakel ändern keine öffentlichen APIs.

Lifecycle auf derselben isolierten, gejournalten DB nach erfolgreicher Basicfixture, ohne Actors oder konkurrierende Verbraucher:

| Vorbereitung | Snapshot | Tatsächliches Deploy | Tatsächliches Uninstall mit ConfirmNoExternalConsumers=1/AllowDataLoss=1 |
|---|---|---|---|
| Runtime/LifecycleOccupied.Setup.sql | Runtime/Lifecycle.Snapshot.sql | Fehler54242, State1 | Fehler54246, State2 |
| Runtime/LifecycleHeld.Setup.sql | Snapshot erneut | Fehler54242, State1 | Fehler54246, State2 |
| Runtime/LifecycleDependency.Setup.sql | Snapshot erneut | Fehler54243, State1 | Fehler54243, State1 |

Jeder tatsächliche Lifecycleaufruf verwendet eine eigene kurzlebige Connection derselben eindeutig eigenen DB. Die Snapshotconnection bleibt offen. SQLCMD-Includes und Variablen werden durch den vorhandenen privaten Adapter aufgelöst; es wird kein Produktcheck nachgebaut. Nach jedem beobachteten erwarteten Fehler führt die Snapshotconnection Runtime/Lifecycle.Verify.sql aus: alle sieben persistierenden Tabellen und Modulversionen müssen unverändert sein. Dieses Verify allein beweist ausschließlich Datenintegrität, keine Ausführung oder Ablehnung des Lifecycle.

Occupied wird durch explizite Holdfreigabe, Reactivation und echten Claim vorbereitet. Held entsteht durch echten Stop vor Dispatch und Reconcile mit LateDispatchfence, ohne fingierte Handlerrollbackbestätigung. Für die Fremdabhängigkeit werden vorhandene Holds ausdrücklich freigegeben und Managedmodus kontrolliert deaktiviert; die sichtbare synthetische View referenziert die öffentliche Statussicht. Root koordiniert alle Consumer und Cleanup. Keine weiteren Versionen-/Plattformläufe durch diese Fixtures.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedOnly`
- Scope: Derselbe fokussierte Managedvertrag mit Windows-Workerhost gegen SQL Server 2019 Linux; zwei Supervisoren, Betriebsmodi, Stop/Rollback/Hold/anderer Worker, Dispositionrennen und Controltimeout/UNKNOWN/keine Übernahme.
- Ergebnis: `success including own cleanup; Linux-Workerhost durch aktuelle CI gesondert zu prüfen; Committransportverlust, minimale Rechte und weitere Ziele nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->

Am selben Datum bestand der gleiche gezielte SQL-Vertrag mit `-Platform windows -Version 2025 -Patch CU8 -ManagedSqlOnly`. Diese Evidenz umfasst die SQL-Gates und Lifecycle-Abweisungen; sie ersetzt den vollständigen Providerlauf nicht.

## Fokussierter Windows-Providerlauf

Am 2026-10-05 bestand `Tests/CI/run-external-queue-worker-lab.ps1 -Platform windows -Version 2025 -Patch CU8 -ManagedOnly`, einschließlich eigenem Datenbank- und Datei-Cleanup. Zwei tatsächliche Supervisoren mit kleinen Budgets, leere BOUNDED-/CONTINUOUS-Modi, tatsächlicher Handlerstart und Abbruch/Rollback, persistenter Hold, Handlerkorrektur und Übernahme nach expliziter Freigabe durch den anderen Worker sowie der beobachtete Completion-/Stop-Wettlauf sind geprüft.

Ein gezielter eigener Zeilenlock erzeugte einen tatsächlichen Controltimeout: Guardianfehler, physischer Rollback und beendete Ressourcen wurden beobachtet; der ursprüngliche Ausgang blieb UNKNOWN und belegte den Slot. Ein anderer geeigneter Worker übernahm vorhandene QUEUED-Arbeit nicht. Erst ausdrückliche Admin-Reconciliation klassifizierte den Hold; die Wiederfreigabe blieb bis zum getrennten Endnachweis abgewiesen. Das beweist keinen Hostverlust oder Committransportverlust. Reale Minimalrechte und die vollständige Zielmatrix sind nicht ausgeführt; zum Zeitpunkt dieses Labnachweises blieb die exakte Head-CI ein separates Mergegate. Frühere fehlgeschlagene Läufe werden durch diesen Nachweis nicht rückwirkend aufgewertet.

Am selben Datum bestand der unveränderte fokussierte Managedadapter mit `-Platform linux -Version 2019 -Patch latest -ManagedOnly`, einschließlich eigenem Cleanup. Der Workerhost war Windows; ein Linux-SQL-Ziel qualifiziert allein keinen Linux-Workerhost.

Ergänzung 2026-10-06: Der [PR197-Worker-CI-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37423892477)
bestand am exakten Head mit einem tatsächlichen Linux-Workerhost gegen eine
flüchtige synthetische SQL-2019-Instanz: Managed-Vertrag, SQL-Admission und
Generation, echter Queue2.0→2.1-Upgrade sowie getrennte Windows-/Linux-
Faultverträge. Der erste [main-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37425398209)
scheiterte im zeitabhängigen Managed-Controltimeout-Orakel bei erfolgreichem
Cleanup; ein einziger Retry desselben Commits bestand alle Jobs. Der erste
Fehler bleibt fehlgeschlagen und seine Ursache unbekannt. Die CI ergänzt die
obigen physischen Windows-Workerhost-Nachweise, ersetzt aber weder echten
Committransportverlust noch Minimalrechte oder weitere Zielkombinationen.
