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
