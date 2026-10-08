# Repository-weites Deployment

`Deploy-All.ps1` führt alle aktuellen `Modules/*/Deployment/Deploy.sql`-Skripte aus. Die Reihenfolge wird deterministisch aus den `module.yaml`-Dependencies berechnet. Module außerhalb von `Modules/` (zum Beispiel Spikes) sind nicht enthalten.

Mit `-ModuleId` lassen sich ein oder mehrere Module auswählen. Ihre transitiven
Manifest-Abhängigkeiten werden automatisch ergänzt und in derselben
deterministischen Reihenfolge ausgeführt. Ohne `-ModuleId` bleibt der
Gesamtdeployment-Modus unverändert.

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 `
  -DeploymentMode local `
  -ModuleId toolbelt.metadata.table-clone `
  -PlanOnly
```

Der Plan zeigt auch automatisch ergänzte Abhängigkeiten und deren fehlende
SQLCMD-Eingaben. Eine Modulauswahl ersetzt nicht die modulbezogenen
Server-, Plattform-, Versions-, Rechte- oder CLR-Preflights.

Vor einer Verbindung kann der Plan einschließlich der pro Modul erforderlichen SQLCMD-Eingaben angezeigt werden:

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 -DeploymentMode local -PlanOnly
```

Ein Deployment benötigt PowerShell 7, `sqlcmd` im `PATH`, eine Zielinstanz und eine Ziel-Datenbank. `DeploymentMode` muss ausdrücklich `local` oder `central` sein.

Mit `-CreateDatabaseIfMissing` prüft der Runner die Datenbank in `master` und
legt sie nur an, wenn sie fehlt. `-PlanOnly` bleibt rein lesend und führt diese
Prüfung nicht aus.

Windows Authentication verwendet das Konto des aktuellen Benutzers:

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 `
  -ServerInstance . `
  -Database Toolbelt `
  -DeploymentMode local `
  -Authentication Windows
```

SQL Authentication verwendet standardmäßig `sa`. Das Passwort wird einmal verdeckt abgefragt und nur über die `SQLCMDPASSWORD`-Umgebungsvariable des gestarteten `sqlcmd`-Prozesses übergeben; es erscheint weder in der Kommandozeile noch in der Ausgabe:

```powershell
pwsh -File .\Deployment\Deploy-All.ps1 `
  -ServerInstance . `
  -Database Toolbelt `
  -DeploymentMode local `
  -Authentication Sql `
  -SqlUsername sa `
  -CreateDatabaseIfMissing
```

CLR-Module benötigen ihre aktuellen, separat erzeugten Binary-Eingaben. Mit `-PlanOnly` werden die pro Modul benötigten Variablennamen aufgelistet. Übergib sie als Hashtabelle über `-ModuleVariables`; beispielsweise enthält `toolbelt.tsql.script-parser` `AssemblyBits` und `ScriptDomAssemblyBits`. Die Großschreibung der Variablennamen ist bei Prüfung und Ersetzung gleichermaßen unerheblich. Binary-Werte müssen vollständige `0x`-präfixierte Hex-Literale sein; SHA2-512-Erwartungswerte müssen `0x` und genau 128 Hex-Zeichen enthalten. Fehlende oder falsch formatierte Eingaben brechen vor der ersten Serververbindung ab.

Der Runner erzeugt keine CLR-Binaries und ändert keine Serverkonfiguration, Trust-Einträge oder Berechtigungen. Solche Voraussetzungen müssen gemäß den jeweiligen Modulregeln separat vorbereitet sein. Jedes Modul führt weiterhin sein eigenes Deployment-Preflight aus. Ein Fehler stoppt die Sequenz; zuvor erfolgreich installierte Module werden nicht zurückgerollt. Wiederholung und Upgrade bleiben an die vom jeweiligen Modul unterstützten Versionen und Lifecycle-Zustände gebunden.

## Eigenständige SQL-Datei

Der zusätzliche Modus `-OutputSqlFile` erzeugt aus denselben aktuellen
Modulskripten eine einzelne Datei. Er benötigt PowerShell 7, aber weder
`sqlcmd` noch eine SQL-Verbindung. Rekursive `:r`-Includes werden eingebettet,
Modulvariablen geprüft und ersetzt, deklarierte Abhängigkeiten ergänzt.
Ohne `-ModuleId` werden alle Module mit `Deployment/Deploy.sql` exportiert;
Spikes, Uninstall- und Testscripte bleiben außerhalb des Deployments.

```powershell
.\Deployment\Deploy-All.ps1 `
  -DeploymentMode local `
  -ModuleId toolbelt.datetime.date-spine `
  -OutputSqlFile .\Toolbelt-Deploy.sql
```

Für einen vollständigen Export müssen die im `-PlanOnly`-Plan ausgewiesenen
Binary- und Hash-Eingaben ausdrücklich über `-ModuleVariables` vorliegen.
Die Datei enthält diese Werte; sie autorisiert keine Assemblies. Insbesondere
bleiben separate exakte CSV-/ZIP-Trustfreigaben erforderlich. Der Generator
führt keine Modulskripte aus, lädt keine Pakete nach und baut keine Binaries.

`-OutputSqlFile` ist mit `-PlanOnly`, Verbindungs-/Authentifizierungsparametern
und `-CreateDatabaseIfMissing` nicht kombinierbar. Das Zielverzeichnis muss
existieren, die Datei muss `.sql` heißen und darf noch nicht vorhanden sein.
Nach vollständiger Prüfung wird die UTF-8-Datei ohne BOM veröffentlicht;
vorhandene Dateien werden auch bei konkurrierender Erzeugung nicht ersetzt.
Zum Aktualisieren einen neuen Dateinamen verwenden und die ältere Datei nach
eigener Prüfung ablösen. Der Export ist ein Snapshot des aktuellen Checkouts;
nach Moduländerungen muss er neu erzeugt werden.

Die manuelle Ausführung benötigt **SQLCMD-Modus mit Fehlerabbruch** und eine
**frische exklusive Sitzung** in der ausdrücklich gewählten Zieldatenbank.
In SSMS SQLCMD-Modus einschalten und eine neue Verbindung verwenden; alternativ:

```powershell
sqlcmd -S localhost -d Toolbelt -E -b -f 65001 -i .\Toolbelt-Deploy.sql
```

Die Datei enthält `:ON ERROR EXIT`, `GO`-Modulgrenzen und prüft vor, zwischen
und nach Modulen auf laufende oder implizite Transaktionen. Diese Zustände
werden abgewiesen; es gibt kein automatisches Caller-Rollback.
`GO` trennt Batches, erzeugt aber keine neue Sitzung. Einige Installer lassen
eigene modulpräfixierte Temp-Tabellen bestehen; deshalb die Verbindung nach
Abschluss schließen und für eine Wiederholung neu öffnen. Andere
SQLCMD-Direktiven, etwa Verbindungswechsel oder Hostbefehle, werden beim
Export abgewiesen. Der Export bindet keine Zielinstanz oder Ziel-Datenbank.
Die Microsoft-Dokumentation beschreibt
[:ON ERROR EXIT](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-commands)
und die [sqlcmd-Optionen](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility).

## Datenerhaltung und derzeitige Grenzen

Der Export übernimmt die kanonischen Installations- und Migrationspfade
unverändert. Er besitzt keinen generischen Schemavergleich und keine
automatische Tabellenkopie. Bekannte Queue-Upgrades ergänzen und migrieren
vorhandene Daten; unbekannte Versionszustände brechen ab. Ein installierter
Worker-Control erlaubt ausschließlich den bekannten vollständigen, ruhenden
Queue2.1-/Control1.0-Repeat gemäß
[Controlvertrag](../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md).
Andere Consumerstände und aktive Zustände bleiben abgewiesen. Ein jederzeit
erfolgreiches Gesamt-Refresh ist damit noch nicht belegt. Weder Export noch
Runner umgehen diese Grenzen oder entfernen Consumer automatisch.

Ein später Modulfehler lässt bereits erfolgreich installierte Module bestehen.
Auch GRANT-/Objektmetadaten-Erhaltung ist modulabhängig; etwa XLSX erneuert
seine Functions über DROP/CREATE. Für das Ziel „alle Objekte jederzeit ohne
Datenverlust aktualisieren“ bleiben daher versionierte Lifecycle-Migrationen
und Tests mit gefüllten Tabellen erforderlich. Die statische Exportprüfung
beweist weder gemeinsame SQL-Laufzeitkompatibilität noch eine vollständige
Upgrade-/Plattformmatrix. Details stehen im
[Deployment-Modell](../Documentation/Architecture/DEPLOYMENT_MODEL.md).

Die Offline-Vertragsprüfung läuft mit:

```powershell
pwsh -File .\Deployment\Tests\Test-SqlExport.ps1
```

Sie erzeugt ausschließlich synthetische Dateien und führt kein SQL aus.

Der fokussierte [befüllte Exportrepeat](Tests/README.md) konsumiert die echte
erzeugte Datei für neun CLR-freie Module im bestehenden externen Linux2019-
CI-Ziel. Er prüft lokal/zentral 14 Tabellen über zwei Wiederholungen in frischen
Sitzungen. Sein begrenzter Batchconsumer qualifiziert weder SSMS noch
`sqlcmd.exe`, Windows oder den vollständigen 44-Modul-Export. Der begrenzte
native Test besteht am Head `a836b87778fbe4c498b4b1ce05f06c58373ea03c` auf
Linux2019/CL150 lokal/zentral einschließlich eigener Bereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37701845352)).

Ein getrennter [Export-Migrationsfall](Tests/README.md) ist mit sieben aktuellen
Bootstrapmodulen, gepinnten Originalquellen der Queue2.0 und der vollständigen
aktuellen Neun-Modul-Datei für local/central vorbereitet. Acht alte Tabellen
mit 109 Feldern einschließlich aller 43 WorkItem-Felder werden vor weiterer
DML privat verglichen; drei neutrale Managedfelder und die erstmaligen
Gate-/Controltabellen werden rein lesend geprüft. Danach folgt eigene
Bereinigung, keine Post-Migration-Completion, Admission oder zusätzliche
Repeatfolge. Die neue native Migration ist `NOT_EXECUTED`. Parent PR290
bestand den begrenzten nativen Exportrepeat am Qualifikationshead
`a836b87778fbe4c498b4b1ce05f06c58373ea03c`; finale Parent-Head-CI am Stand
`bdc2ba9f001190d9d63cc97e040f1e693fb4dafd` bestand. PR290 ist nach `origin/main`
integriert, Mainstand `acba925419973d9dfb2b7b8e481d67f0a75789e3` mit identischem
Parentbaum. Main-Dokumentations- und Main-Worker-CI einschließlich eigener
Bereinigung bestanden.
Dieser Fall ändert keine Source-/Deploy-/API-Semantik und erweitert keine
Rechte oder Ziele.

Statusfortschreibung 2026-10-08: Der erste native Migrationslauf in
[PR291](https://github.com/gecompat/SQL_Server_Toolbelt/pull/291) am Head
`1d4f9cbdde094c2c59c22eb01b5c5ee261df73b0` ist **FAILED**
([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37705019236));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37705019277)
bestand. Die Setupfixture verwendete `#tbx_ExportUpgradeStatus` und
`#tbx_ExportUpgradeClaim` als öffentliche ResultTable-Ziele. Der bestehende
Vertrag von `USP_PrepareResultTable` reserviert `#tbx_` und weist diese Namen
mit Fehler `51020`/State `1` ab. Die vorbereitete Korrektur benennt nur diese
beiden eigenen Fixtureziele in `#ExportUpgradeStatus` und
`#ExportUpgradeClaim` um; Source, Deployment, Guards und Datenorakel bleiben
unverändert. Die korrigierte native Migration ist **NOT_EXECUTED**.
Der erfolgreiche Wholejob-Cleanup wurde getrennt verifiziert. Auf dem
Fehlerpfad erschien kein Erfolgsmarker der eigenen Migration-DB-/Datei-
Bereinigung; daraus wird kein eigener Cleanup-PASS abgeleitet.

Die bisherigen SQL150-Offlinenachweise mit 865 Export-Inputs und 28
Fixture-/Wrapper-Inputs sowie die unabhängigen Reviews bleiben an ihren
ursprünglichen Quellenständen gültig. Sie belegen Syntax beziehungsweise
Reviewumfang und erkennen diese Laufzeitverletzung des ResultTable-
Namensvertrags nicht. Die oben genannten NOT_EXECUTED-Angaben dokumentieren
den Vorbereitungsstand; dieser fehlgeschlagene Lauf qualifiziert weder die
Migration noch deren eigenen nativen Cleanup. Parentnachweise bleiben
unverändert erhalten. Keine API-, Rechte-, Ziel- oder Vertragsausweitung.

Statusfortschreibung 2026-10-08: Der zweite Lauf am korrigierten Head
`2735ad3167174d8986857e2f16ec92c3c6942beb` ist bereits in den unveränderten
Managed-Worker-SQL-Contracts **FAILED**
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37706094651));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37706094720)
bestand. Das feste Oracle `MANAGED.UNEXPECTED_UNKNOWN` meldet ein unbekanntes
Workerende im Fall `budget-two`, nach `LIVE_BUDGET_TWO_REDUCED_WITHOUT_CANCEL`.
Beide Export-Schritte wurden **SKIPPED**; die korrigierte native Migration
bleibt **NOT_EXECUTED**. Always-Containercleanup bestand. Die zugrunde liegende
Actor-/Guardianursache ist nicht gemessen; SQL0 der generischen Waitexception
belegt keinen Actor-SQL-Code. Eine begrenzte Diagnoseergänzung an der Testfixture
soll bereits vorhandene Actor-/Guardianfelder ausschließlich als feste
Sourcecodes, typisierte numerische SQL-Codes und Statusflags sichtbar machen.
Workerprodukt, SQL, Orakel, Timing, Ressourcen und Cleanup bleiben unverändert;
kein unveränderter Retry oder gelockerter UNKNOWN-Guard qualifiziert den Test.

Statusfortschreibung 2026-10-08: Der begrenzte native Export-Migrationsfall
in [PR291](https://github.com/gecompat/SQL_Server_Toolbelt/pull/291) besteht
am Qualifikationshead `155f74c9d11548cf600e7770f0d0d12e0720a7f4` (**PASS**;
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37707910466),
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37707910490)).
Auf SQL Server 2019 Linux/CL150 bestand lokal und zentral die tatsächliche
Exportfolge: sieben aktuelle Bootstrapmodule (124 Batches), die gepinnte
Original-Queue2.0 (46 Batches) und der vollständige aktuelle Neun-Modul-Export
(261 Batches), jeweils in frischen ungepoolten Sitzungen. Acht Legacytabellen
mit allen 109 Feldern einschließlich der 43 WorkItem-Felder und des aktiven
Legacyclaims bleiben vor weiterer persistenter DML bytegenau erhalten;
Rowversions, Tokens, NULLs, Audit-/Textbytes, verbrauchte Identitywerte und
ausgewählte Katalogmetadaten sind eingeschlossen. Nur die dokumentierten
Queue-Versions-/Check-ID-Normalisierungen sind ausgenommen. Die drei neutralen
Managedfelder und die bekannten Spaltenformen/neutralen Zustände der sechs
neuen Gate-/Controltabellen bestehen die lesenden Assertions. Eigene
Migration-DB-/Dateibereinigung und separate Containerbereinigung bestanden.
Auch der vorhandene gemeinsame befüllte Exportrepeat bestand separat; die
Migration erhält keine Post-Migration-Completion, Admission, neue Callback-/
SQL-API oder zusätzliche Repeatfolge. Keine Rechte-, Provider-, Trust-,
Konfigurations- oder Zielausweitung; weitere Plattformen/CLs, Minimalrechte,
nichtleere Grants und allgemeiner 44-Modul-Lifecycle bleiben offen.

Frühere Vorbereitungs-/NOT_EXECUTED-Angaben und beide FAILED-Läufe einschließlich
der SKIPPED-Exportschritte bleiben historische Evidenz ihrer Quellenstände.
Der Erfolg schreibt keine früheren Fehler oder fehlenden Cleanupnachweise um.
Die Actor-/Guardianursache des früheren Managed-UNKNOWN bleibt **UNMEASURED**;
im erfolgreichen Lauf erschien kein UNKNOWN-Diagnosedescriptor. Die begrenzte
Beobachterabbildung ist offline validiert; ihre UNKNOWN-Ausgabestrecke wurde
hier nicht ausgelöst. Der UNKNOWN-Guard bleibt unverändert; daraus wird kein
Workerprodukt- oder Ursachenfix abgeleitet. Parentnachweise bleiben erhalten.
Finale Head-CI nach dieser Evidenzfortschreibung, PR291-Merge und anschließende
Main-CI einschließlich Maincleanup sind noch offen.

Statusfortschreibung 2026-10-08 nach PR291-Merge: Die vorstehende offene
Abschlussangabe beschreibt den damaligen Stand. Der erfolgreiche
Qualifikationshead `155f74c9d11548cf600e7770f0d0d12e0720a7f4` bleibt erhalten;
auch der finale Head `6a28ba484760d181ce2b37833b339780084a457d` bestand
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709411383)
und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709411388).
PR291 wurde nach `main` `f8b9b407ad30fc560015b8b475005b4505617689` gemergt.
Die [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709938821)
bestand; die [Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709938890)
ist **FAILED** im bestehenden Schritt „Execute genuine Queue 2.0 to 2.1
upgrade“. Die vorherigen realen Linux-Worker-, Managed- und Admissionprüfungen
bestanden. Beide neuen Export-Schritte sind **SKIPPED / NOT_EXECUTED**.
Die separate eigene Containerbereinigung bestand mit genau einem tatsächlichen
festen Cleanupmarker; daraus folgt kein eigener Export- oder Fixturecleanup-PASS.
Die beiden früheren FAILED-Läufe bleiben unverändert historische Evidenz.

Der geschlossene Fehlerbefund nennt die Sourcephase
`control-repeat-post-source-rollback`, SQL1222, die äußere Source-Skriptzeile141
und Orakel `UNSPECIFIED`; der bestehende Sourcefall erwartet SQL54969/State1.
Ein numerischer Enginefehlerdescriptor wurde nicht ausgegeben. Enginezeile,
tatsächlicher State, erster fehlgeschlagener Batch und Blockerursache bleiben
**UNMEASURED**. Weder ein
Timingproblem noch ein Produktfehler ist damit ursächlich belegt; die frühere
Managed-UNKNOWN-Ursache bleibt ebenfalls offen. Kein Main-PASS wird abgeleitet.

Die begrenzte Diagnosewartung liegt als privater, eingefrorener
Testfixturekandidat vor. Ausschließlich `Invoke-ControlRepeatExpectedFailure`
erfasst vor dem unveränderten Weiterwerfen der ersten unerwarteten SQL-Abweisung
den Batch und höchstens vier numerische Enginefehler im vorhandenen
`fixtureSqlFailure`-Pfad; Texte sind auf fünf vorhandene Source-Guardmeldungen
oder leer beschränkt. Die bestehende geschlossene Descriptorabbildung gibt
keine freien Fehlertexte aus. Offlineprüfungen und unabhängiger Client-/Privacy-
Review bestanden: erste begrenzte Erfassung ohne Überschreiben, erwartete
Abweisungen und State-Wildcard unverändert, unbekannte Meldungen ausgeschlossen
und ursprüngliche Exception auch bei fehlgeschlagener Erfassung erhalten.
Syntax sowie vollständige Byteerhaltung außerhalb dieser Diagnosefunktion
wurden offline geprüft. Die native Ausführung des Kandidaten ist
**NOT_EXECUTED**; Ursache und Mainqualifikation bleiben offen. Erwartete
Abweisungen, Orakel, Timing, Transaktions-/Ownership-Guards, Produktquellen,
Ziele und Cleanup bleiben unverändert; kein unveränderter Retry ersetzt diesen
Nachweis. Kanonische Main-Adoption von ParameterMetadata und class3-
Schemaannotation bleibt bis zur Mainqualifikation gesperrt; private Vorbereitung
kann innerhalb der bestehenden Grenzen fortgesetzt werden.

Ein weiterer begrenzter [Parameter-Metadatentest](Tests/README.md) ist für
`USP_PrepareResultTable` und `USP_EnqueueWork` mit elf Parametern vorbereitet.
Der Fall `ParameterMetadata` verwendet die tatsächliche CLR-freie Closure
result-table/work-type/work-queue und konsumiert dieselbe hashgebundene Datei
lokal/zentral zur Erstinstallation und genau einmal zum Repeat, jeweils in
einer frischen ungepoolten Sitzung. Vier eigene class-2-Annotationszeugen,
der Parameterkatalog, ausgewählte Objekt-/Modulmetadaten, Definitionbytes und
beobachtete Permissions werden privat binär verglichen. Produktquellen,
Deployment-DDL, API, Berechtigungen und Ziele bleiben unverändert.
Offlineprüfung der beiden Exporte mit je 90 Batches und unabhängige Reviews
bestanden; native Parameterprüfung und eigene Bereinigung sind
`NOT_EXECUTED`. Dies qualifiziert weder die Prozedurausführung noch
Benutzergrants, Minimalrechte, SSMS/sqlcmd.exe, Windows oder alle 44 Module.

Voraussetzung für die Parameterintegration, Stand 2026-10-08: PR292 wurde
nach `main` `c73f67959185c7a7846455b89c067854dc7d87f6` gemergt.
Die [Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37713277392)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37713277427)
bestanden am exakten Mainstand. Alle drei Workerjobs sowie beide bestehenden
Exportfälle bestanden; die tatsächlichen Festmarker bezeugen beide Export-PASS,
zweimal eigenen Exportcleanup und einmal eigene Containerbereinigung.
Auch die bestehende Control-Repeat- und Ablehnungsabnahme bestand.
Der neue unerwartete SQL-Diagnosezweig wurde dabei **NOT_TRIGGERED**;
seine Offline-Negativprüfung bleibt ein getrennter Nachweis. Der frühere
Mainfehler auf `f8b9b407ad30fc560015b8b475005b4505617689` und seine
weiterhin **UNMEASURED** Ursache bleiben unveränderte Historie; der erfolgreiche
Lauf belegt keine Ursachenbehebung.
Die native Parameterprüfung einschließlich eigener Bereinigung bleibt
**NOT_EXECUTED**. Der Mainnachweis wurde unabhängig geprüft; der Parameter-
branch enthält Adapter, Fixtures und CI-Schritt für die eigene Headprüfung.
Sämtliche bisherigen
Migrations-/Fehler-/Parentnachweise bleiben vollständig erhalten.

Die Schemaannotationsprüfung erweitert ausschließlich den
bestehenden gefüllten DefaultRepeat: fünf eigene class-3-Zeugen auf zwei Schemas
und vollständiger typisierter Snapshot in beiden Vergleichsfenstern. Zusätzliche Exporte,
Szenarien oder Testdatenbanken sind nicht vorgesehen. [Deploymenttests](Tests/README.md)
beschreiben die Zeugen und Grenzen. Der Branch ergänzt drei bestehende
Populated-Fixtures; native class3-Prüfung und eigene Bereinigung sind
**NOT_EXECUTED**. Source, API, Rechte und Ziele bleiben unverändert.

Voraussetzung, Stand 2026-10-08: PR293 ist nach `main`
`2ad2c018da18768c05f05e0fd7cf4c333fd6b090` gemergt.
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148163)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148155)
bestanden am exakten Mainstand; Parameterrepeat, beide bestehenden Exportfälle,
drei eigene Exportbereinigungen und Containercleanup sind separat bezeugt.
Die Parameter-Mainvoraussetzung ist erfüllt. Native class3-Prüfung und
eigener Cleanup sind **NOT_EXECUTED**; die eigene exakte Head-/Main-CI
einschließlich Bereinigung bleibt **PENDING**.

Die Objektannotationsprüfung ergänzt Setup und Assert des DefaultRepeat um
sechs eigene class-1/minor0-Zeugen auf vorhandenen P/FN/V-Objekten. Capture und
Exportfolge bleiben erhalten; [Deploymenttests](Tests/README.md) beschreiben das Orakel.
Native class1-Prüfung und eigener Cleanup: **NOT_EXECUTED**; exakte class1-Head-/Main-CI **PENDING**.

Class3-Voraussetzung erfüllt: PR294, Main `91e13af689334407527fddfdc8d22285933f4225` (2026-10-08).
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103755) und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103790): **PASS**.

Die View-Spaltenprüfung ergänzt zwei eigene class-1-Properties auf
`VW_WorkQueue.RowVersion`, mit tatsächlicher namensgebundener column_id.
Der vorhandene DefaultRepeat und Capture werden verwendet; [Deploymenttests](Tests/README.md)
beschreiben den vollständigen typisierten Vergleich. Native View-Spaltenprüfung
und eigener Cleanup: **NOT_EXECUTED**; eigene exakte Head-CI sowie Merge-/
Mainqualifikation einschließlich Cleanup: **PENDING**.

Class1-Voraussetzung erfüllt: PR295, Main `a585803de0d1d94be595dbf7b3153e582fbff9d2` (2026-10-08).
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226636) und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226645): **PASS**.
Der begrenzte Nachweis gilt für Linux SQL2019/CL150 local/central; sechs Objektzeugen, drei eigene Exportbereinigungen und Containercleanup sind belegt. Er qualifiziert keine neuen View-Spaltenzeugen und erklärt keine historische Fehlerursache.
