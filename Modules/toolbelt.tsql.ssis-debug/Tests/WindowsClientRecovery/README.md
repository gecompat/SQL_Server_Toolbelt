# Vorbereitung, Windows-Client und harte Clientabbrüche

Diese Testkapsel ergänzt die [aktuelle Prüfmatrix](../README.md). Sie verändert
keine Lab-Infrastruktur und erteilt keine neuen Rechte. Native Eingaben,
Wiederherstellungsjournale und Originalausgaben bleiben ausschließlich lokal
unter dem ignorierten `.runtime/`; der öffentliche
[Abnahmenachweis](../Qualification/PreparationRecovery.Windows.20261101.json)
enthält nur aggregierte Orakel und statische Quellbindungen.

## Aktueller Build und ursprüngliche Teilnachweise

Für den korrigierten 40-Parameter-Build verwende
[`Invoke-CurrentBuildSsms.ps1`](Invoke-CurrentBuildSsms.ps1). Die
[frische Ausgabeabnahme](../README.md#frische-buildgebundene-ausgabeabnahme)
belegt dessen sichtbaren Gesamtlauf einschließlich nativer SQLCMD-Stopprobe,
Phase-2-Receipt und frischem Windows-Audit. Die folgenden datierten
Teilnachweise beschreiben ihre ursprünglichen Artefakte und bleiben unverändert.

| Teilumfang | Tatsächliche Abnahme |
|---|---|
| Öffentliches `PrepareServer.sql` | Windows SQL2019/CU32, 2022/CU26, 2025/CU8; je18 Assertions und frischer unabhängiger Audit |
| Portabler Exporthost | Fünf Ausgabeformen, jeweils echter Prozessabbruch und geschlossene stdout-Pipe; zehn Fälle, 95 Assertions |
| SQL-Client | Aktuelles DebugScript unter beobachtetem eigenen Sch-M-Lock und aktuelle API in offener Callertransaktion; zwei Fälle, 18 Assertions und frischer Audit |
| Öffentlicher Windows-Installer und CLI/API | Windows SQL2025/CU8, CL150; öffentliche Vorbereitung, Erst-/Wiederholungsinstallation, damalige 38-Parameter-API und vollständiges DebugScript mit zwei Ergebniszeilen; zehn Assertions und frischer Windows-Audit |
| Sichtbarer Windows-/SSMS-Gesamtfall | Windows SQL2025/CU8, CL150; [native Stopprobe und Phase2-Receipt](../Qualification/SsmsClient.Complete.Windows.20261103.json), 17 Prüfungen und frischer Windows-Audit |

Der separate [Windows-Installer-/Clientrecord](../Qualification/InstallerClient.Windows.20261101.json)
qualifiziert genau diesen Teilumfang. Sein Gesamtkoordinator bleibt
`FAILED_CLEANED`: Die sichtbare SSMS-Instanz scheiterte vor der ersten
GUI-Abfrage am Pre-Login-Handshake und wurde nach ihrem endlichen Testfenster
geschlossen. Der [Microsoft-Timeoutvertrag](https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/connect/timeout-expired-error)
trennt diesen Verbindungsfehler von einer SQL-Abfrage. Keine erfolgreiche
Windows-SSMS-Anmeldung oder vollständiger Copy/Paste-Transport wird behauptet.
Der frische Windows-Audit bestätigt die gesamte eigene Wiederherstellung.

Der ursprüngliche PrepareServer-Fehler wurde vor der Korrektur ohne Mutation
reproduziert. SQL Server dokumentiert implizite Laufzeitdefaults für min/max
server memory, die von konfiguriertem0 abweichen können. Nur diese dokumentierten
Kombinationen werden vom Pending-Guard ausgenommen; echte vorgemerkte Änderungen
bleiben gesperrt. Der sysadmin-Guard verweigert auch SQL-NULL.
[Microsoft: sys.configurations](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-configurations-transact-sql)

Der Host ist exakt derselbe portable Binary wie bei der
[Windows-/Linux-Exportabnahme](../Qualification/ExportHost.Linux.20261101.json).
Eine geschlossene Pipe kann den Exitcode0 liefern. Deshalb gilt ausschließlich
eine vollständige, validierbare Ausgabe als Resultat; partielle JSON-Bytes werden
verworfen. Jeder neue vollständige Export war byteidentisch zum ungestörten
Orakel. Eingaben blieben unverändert.

Die SQL-Fälle beenden ausschließlich eigene beobachtete sqlcmd-Prozesse. Der
überlebende Koordinator prüft das Verschwinden der Sitzung, Rollback beider
Calleränderungen und identische neue DebugScript-Resultate. Datenbank,
Trusteinträge und CLR-Konfiguration wurden anschließend exakt wiederhergestellt.
Alle früheren fehlgeschlagenen Fixtureversuche und ihre Audits bleiben lokale
Historie. Kein OS-/VM-Ausfall oder Verlust des Koordinators wird behauptet.

## Native Ausführung und Wiederherstellung

Voraussetzungen sind PowerShell7.5, schema-validierter Labvertrag mit exakt
ausgewählten bereiten Windows-Zielen, bestehende ausreichende Rechte und ein
vorab geprüfter, freigegebener Artefaktsatz. Die Funktionen bleiben
`TestPurpose=Functional`: Verschlüsselung mit explizitem Lab-Trustwert belegt
keine authentifizierte TLS-Serveridentität.

`Invoke-Preparation.ps1` und `Invoke-TransportRecovery.ps1` besitzen jeweils
`Prepare`, `Run`, `Audit` und `ValidateOnly`. `Prepare` versiegelt die aktuellen
Eingaben in einem neuen privaten Plan. `Run -ValidateOnly` prüft diesen Plan
ohne Labzugriff, SQL oder Mutation. Ein Operator stellt dafür explizit
`PlanPath`, `ExpectedPlanSha256`, `JournalPath` und `BudgetPath` bereit; beim
Transport zusätzlich die geprüften `SsisReleaseDirectory`,
`ParserReleaseDirectory` und `SqlcmdPath`. Vor jedem nativen Aufruf wird der
gemeinsame endliche Wellenverbrauch reserviert. Alte Verbräuche werden erhalten.

`Audit` benötigt zusätzlich `ExpectedJournalSha256` und eine neue Sitzung.
Er bestätigt Datenbankabwesenheit sowie identische Konfiguration, Trustkatalog
und fremde Assemblyverbraucher. Nur `PASS_CLEANED` mit frischem Audit qualifiziert
den jeweiligen Gesamtfall. Bei `RECOVERY_REQUIRED` stoppt die Kapsel: Ownership,
Drift und verbleibende Verbraucher zuerst klären; keine fremden Zustände
überschreiben und keine grüne Wiederholung als Recovery ausgeben.

Die native Vorbereitung und SQL-Abnahme verwendeten den SQL-Zweig des gemeinsamen
Helpers. Die spätere Unterdrückung zweier ungenutzter boolescher Windows-Remove-
Rückgabewerte ist als exakt reversible Quellintegration dokumentiert. Der
Validator akzeptiert ausschließlich diese zwei Änderungen gegenüber den
tatsächlich ausgeführten ursprünglichen Bytes.

## Separates Windows-/SSMS-Profil

`Invoke-WindowsClient.ps1` adaptiert den exakt gepinnten Transportkoordinator.
`Prepare` bindet zusätzlich den ausdrücklich gewählten SSMS-Binary. `Launch`
verlangt den expliziten Hash des nativen SQL_Server_Lab-Testhelpers
`Tests/Integration/Start-WindowsSqlHostClient.ps1` sowie dessen sauberes gebundenes
Labmodul. Die vorhandene geschützte Windows-Anmeldung bleibt intern im Lab.
Ein gestarteter Prozess ist noch kein Anmeldenachweis. Es gibt keinen
automatischen Kennwortdialog, Retry oder Providerwechsel.

Das Profil verlangt eine echte Windows-Clientanmeldung, öffentliche erste und
wiederholte `Install-Local.ps1`-Ausführung sowie eine eigene sichtbare SSMS-Instanz.
Der Operator führt dort das erzeugte01-Script aus, kopiert genau eine vollständige
DebugScript-Zelle in eine neue Abfrage und speichert sie am bereitgestellten
02-Pfad. UTF16/LF-Hash und Unicode müssen mit dem Serverartefakt übereinstimmen.
Nach tatsächlicher Ausführung mit zwei erwarteten Ergebniszeilen und fehlerfreien
Messages wird der getrennte visuelle Nachweis geschrieben, das03-Receipt
ausgeführt und ausschließlich die eigene SSMS-Instanz geschlossen. Danach sind
Cleanup und ein frischer separater Windows-Audit erforderlich. Bestehende
SSMS-Tabs bleiben erhalten. Anmelde-/Sicherheitsdialoge bedient der Benutzer.

### Kopierprüfung vor der Ausführung

Die Ergebnisoptionen bereits vor dem01-Script in dessen eigener Abfrage setzen:
`Query Options > Results > Grid`, `Non XML data = 2000000` und
`Retain CR/LF on copy or save` aktiv. Diese in SSMS22 beobachteten Optionen
gelten für die Testabfrage. Bestehende Benutzerabfragen bleiben unverändert.
Nach einer Änderung01 erneut ausführen und genau dessen neue Zelle kopieren.
Der erwartete Hash muss aus der aktuellen Server-Receiptzeile stammen:
erneutes `explain` kann einen neuen Snapshot und einen anderen Hash erzeugen.
Eine früher geschriebene `gui-produced.json` kann dann veraltet sein.

Vor der Ausführung die02-Kopie über SSMS speichern und separat prüfen:

```powershell
./Test-SsmsScriptCopy.ps1 -CopiedScriptPath $copiedPath -ExpectedUtf16LfSha256 $currentExpectedHash
```

Die Testhilfe liest ausschließlich die Datei. Sie normalisiert nur CRLF zu LF
und vergleicht SHA256 über UTF16LE mit dem aktuellen Serverhash. Sie entfernt
weder Whitespace noch einen zusätzlichen abschließenden Zeilenumbruch und
schreibt den Scriptinhalt nicht in die Ausgabe. Ein Fehler stoppt die Ausführung.
Ihr PASS bestätigt allein die gespeicherte Kopie; sichtbare SQL-Ausführung,
Ergebnisorakel,03-Receipt, eigene Bereinigung und frischer Windows-Audit bleiben
separate Gates. Die Offline-Gegenproben verwenden eine synthetische lange
Unicode-Zelle und weisen Kürzung bei65535, entfernte Zeilenumbrüche,
Unicodeänderung und eine zusätzliche Schlusszeile zurück.

Die frühere Trust-Zuordnung scheiterte am engeren SQL-datetime-Format. Eine
weitere eigene Probe wurde nach dem Computer-Use-Abbruch sicher storniert.
Danach fehlte im Adapter die beim Ersetzen des manuellen Deployments ebenfalls
entfernte Datenbankverbindung. Alle drei Fehler-/Abbruchzustände und ihre
erfolgreichen Abschlussaudits bleiben erhalten. Das aktuelle Profil verwendet
typisierte datetime2(7)-Parameter und öffnet nach den öffentlichen Phasen genau
einen eigenen Windows-Datenbankverbraucher. Offline-Gegenproben sichern sieben
Nachkommastellen, beide Kulturen und die wirkliche Verbindungseröffnung im
isolierten Installerdoppel. Die letzte native Probe bestand den oben genannten
Installer-/CLI-Teilumfang; ihr späterer SSMS-Handshakefehler bleibt ausdrücklich
unqualifiziert. Kein grüner GUI-Gesamtkoordinator wird daraus abgeleitet.

## Offlineprüfungen

Der ergänzende `Invoke-SsmsQualification.ps1` verwendet den exakt gepinnten
bestehenden Koordinator und `SsmsGuiHook.ps1`. Vor der Testdatenbank startet
er eine eigene SSMS-Instanz in `master` mit dem eindeutigen Verbindungsnamen
`SSIS-LAB-QUALIFICATION`. Eine rein lesende SQL-Abfrage vergleicht den privaten
Instanz-/Prozess-/Startzeitstempel des ausgewählten Labziels und verlangt
Windows-Authentifizierung, Verschlüsselung und SSMS als Anwendung. Erst nach
dem getrennten sichtbaren PASS-Nachweis darf die Datenbankanlage beginnen.
Die gleiche eigene SSMS-Instanz wird für den anschließenden Scripttransport
wiederverwendet. Bestehende Benutzerfenster und andere Serververbindungen sind
kein Ersatz für diesen Zielnachweis.

`DescribeOnly` erzeugt den tatsächlich adaptierten Ablauf und die Vorcheckabfrage
ohne Labzugriff, Credentials, Prozessstart oder SQL-Verbindung. Die Gegenproben
führen diesen Compiler wirklich aus, prüfen den Vorcheck vor der Datenbankanlage,
die Wiederverwendung der eigenen Instanz sowie die restliche endliche Laufzeit.
Veränderte historische Treiber werden vor jedem Labzugriff zurückgewiesen.
Historische Methoden und ihre vorhandenen Nachweise bleiben bytegenau erhalten.

Der Vorcheck besitzt ein endliches Zeitfenster; der spätere GUI-Teil verwendet
die verbleibende gemeinsame Labfrist mit reservierter Zeit für Cleanup und Audit.
Ein unbestätigter Vorcheck erzeugt keine Testdatenbank. Nach Abschluss werden
ausschließlich eigene Prozesshandles und eindeutig eigene SQL-Ressourcen bereinigt.
Eine reservierte Auditfrist ist kein ausgeführter Audit. Scheitert der GUI-Teil,
muss der separate Audit vor der gemeinsamen Grenze stattfinden; nach deren
Ablauf wird kein neuer Qualifikationsaufruf zugelassen.

Die erste zusätzliche zielgebundene native Probe bestand den sichtbaren Vorcheck
mit Windows-Anmeldung und Verschlüsselung am ausgewählten SQL2025/CU8-Labziel
sowie den API-Erzeuger in derselben SSMS-Instanz. Der erste Kopierversuch
offenbarte die65535-Zeichen-Grenze und fehlende Zeilenumbrüche. Nach Änderung
der eigenen Abfrageoptionen entstand eine lange mehrzeilige Dateikopie;
deren vollständiger Hashabgleich und Ausführung wurden vor Ablauf der
gemeinsamen Grenze nicht mehr abgeschlossen. Der Koordinator bleibt
`FAILED_CLEANED`, ein GUI-Gesamt-PASS wird nicht behauptet. Seine eigenen
Cleanupprüfungen und eine zusätzliche frische lesende Zustandskontrolle
bestanden. Letztere ist ausdrücklich kein separater Windows-Qualifikationsaudit;
dieser wurde in dieser Probe nicht ausgeführt. Die frühere qualifizierte
Installer-/CLI-Evidenz bleibt unverändert.

Die ausdrücklich separat freigegebene Restprobe bestand danach den sichtbaren
Windows-Vorcheck und die API-Erzeugung am selben ausgewählten Labziel. Vor der
Erzeugung setzte der Benutzer die eigenen Gridoptionen. Die über SSMS kopierte
Zelle bestand vor ihrer Ausführung die strikte Dateihashprüfung. Nach Fehlern
der UI-Automation führte der Benutzer den unveränderten vollständigen Inhalt
genau einmal aus; zwei erwartete Zeilen und der fehlerfreie Messages-Abschluss
wurden anschließend visuell geprüft. Der
[getrennte Clientnachweis](../Qualification/SsmsClient.Windows.20261101.json)
bindet diese tatsächlichen Beobachtungen und den frischen Windows-Audit.

Der Koordinator blieb dennoch `FAILED_CLEANED`, weil das03-Receipt vor der
GUI-Frist nicht mehr ausgeführt wurde. Die zusätzliche private Aufrufhülle
erhielt diesen Fehler und rief danach genau den einen reservierten öffentlichen
Windows-Audit auf; dessen PASS bindet das finale unveränderte Journal. Dieser
Audit ersetzt weder das fehlende Receipt noch den grünen Gesamtlauf. Elf native
Checks und der separate visuelle Umfang bleiben unterscheidbar. Für einen
vollständigen Koordinator-PASS sind weiterhin03, eigenes reguläres Ende und
der frische Audit im selben endlichen Lauf nötig; vorhandene Teilbelege
werden dafür nicht umgeschrieben. Native Fehler- und Ressourcenbudgets bleiben
geschlossen und werden durch diesen Nachweis nicht erneuert.

```powershell
python -m unittest discover -s Tests/Release -p test_ssis_preparation_recovery.py
python Scripts/Release/validate_ssis_preparation_recovery.py
python -m unittest discover -s Tests/Release -p test_ssis_ssms_gui.py
python Scripts/Release/validate_ssis_ssms_gui.py
```

Die Gegenproben prüfen Quell-/Methodenbindung, Matrix, echte Abbruchorakel,
Rollback, unveränderliche Grenzen und SQL-freien Preflight. Sie laufen als
kurzer zusätzlicher Schritt im bestehenden SSIS-CI-Job, ohne neue SQL-Matrix,
VMs oder wiederholte native Qualifikation. Linux-SQL-CLR, ununterbrochener
öffentlicher Windows-TLS-Neuaufbau, unbegrenzte Produktionskapazität und
vollständige SSIS-Runtime-Parität bleiben getrennt.

## Autonomer Receipt-Ablauf und aktuelle Grenze

`Invoke-AutonomousSsms.ps1` und `AutonomousSsmsHook.ps1` sind ein separates
Testprofil für den noch offenen Gesamtabschluss. Sie behalten Zielvorcheck,
Windows-/SSMS-/Verschlüsselungswachen, vollständige Kopierprüfung,
Prozessownership und Wiederherstellung bei. Historische Methoden und Records
bleiben unverändert. Der Start öffnet keine SQL-Datei automatisch; das ist
keine Zusage einer dialogfreien Anmeldung.

Die autonome Probe vom2026-11-02 zeigte auch bei diesem Start einen
SSMS-Verbindungs-Bestätigungsdialog. Sie wurde ohne GUI-Eingabe oder
GUI-Abfrage vor der Datenbankanlage beendet. Der Koordinator blieb
`FAILED_CLEANED`, mit fünf Cleanupchecks und keinem bestandenen Gesamtfall.
Der dafür reservierte frische unabhängige Windows-Audit bestand und bestätigte
Datenbankabwesenheit, wiederhergestellte Konfiguration und Trust sowie
unveränderte andere Verbraucher. Dieser Audit qualifiziert keine Anmeldung,
keinen Receipt-Abschluss und keine autonome SSMS-Ausführung. Der bisherige
getrennte visuelle Teilnachweis bleibt gültig innerhalb seines ursprünglichen
Umfangs; der Gesamtkoordinator bleibt offen.

Eine Ausführung ohne anwesenden Benutzer benötigt einen zulässigen
Verbindungsweg ohne interaktiven Anmelde-/Sicherheitsdialog. Ein solcher Dialog
beendet den autonomen Versuch; er wird weder automatisiert bestätigt noch durch
geänderte Sicherheitsoptionen unterdrückt. Ein gestartetes oder maximiertes
Fenster gilt weiterhin nicht als Nachweis. Nicht verwendete Ressourcenplätze
verlängern die ausdrücklich begrenzte Welle nicht.

Für den nach erfolgreichem Vorcheck vorgesehenen Receipt-Abschluss erzeugt
`New-SsmsExecutionEnvelope.ps1` eine SQL-freie Testhülle. Sie prüft zunächst den
aktuellen UTF16/LF-Hash der gespeicherten02-Zellenkopie und den exakten Hash des
nativen03-Receipts. Die Hülle besteht aus `USE [eigene Testdatenbank]`, dem
unveränderten kopierten Body und dem Receipt. Ausschließlich CRLF wird zu LF
normalisiert. Die02-Datei bleibt erhalten. Kontext und Receipt sind explizite
Testinstrumentierung außerhalb des kopierten Produktartefakts.

Nach echtem Kopieren und Speichern der02-Datei kann die Hülle so vorbereitet
werden; der erwartete Bodyhash stammt aus dem aktuellen nativen Erzeuger,
der Receipthash aus der unveränderten nativen03-Datei:

```powershell
./New-SsmsExecutionEnvelope.ps1 -CopiedScriptPath $copiedPath -ExpectedUtf16LfSha256 $currentExpectedHash -ReceiptPath $receiptPath -ExpectedReceiptSha256 $receiptHash -Database $ownDatabase -OutputPath $envelopePath
```

Die vollständige Hülle wird in einer eigenen verbundenen SSMS-Abfrage
unverändert eingefügt, als05-Ausführungsdatei gespeichert und mit denselben
Parametern sowie `-VerifyExisting` gegen diese Datei geprüft. Erst dann darf
sie genau einmal ausgeführt werden. Erwartet sind die zwei fachlichen
Ergebniszeilen, anschließend `SSIS_WINDOWS_CLIENT_GUI_PASS` mit Unicodezeugen
und fehlerfreie Messages. Der Body enthält seine ursprünglichen Fehlerwachen;
ein Fehler darf nicht durch getrennte Ausführung des Receipts übergangen werden.
Die Testhilfe verweigert deshalb auch `GO`-Batchtrenner vor jeder Dateianlage.
Nach sichtbarer Prüfung und Schließen ausschließlich der eigenen SSMS-Instanz
vergleicht der Koordinator05 erneut mit02 und dem bei der Erstellung gebundenen
03-Receipt. Ein grüner Gesamtfall benötigt außerdem echtes Phase2 und den
frischen separaten Windows-Audit. Diese Ausführungsstrecke wurde in der
autonomen Probe wegen des vorgelagerten Dialogs **nicht ausgeführt**.

Acht SQL-freie Gegenproben prüfen die tatsächlich kompilierten Adapter,
erhaltene Wachen, den vollständigen langen Unicodebody und die Trennung vom
Receipt. Kürzung, geändertes Receipt, falsche Datenbank, veränderte gespeicherte
Ausführung, Batchtrenner sowie stilles Überschreiben vorhandener Nachweise werden verweigert:

```powershell
python -m unittest discover -s Tests/Release -p test_ssis_autonomous_ssms.py
```

Die Gegenproben laufen im vorhandenen SSIS-CI-Job. Sie ersetzen weder den
ausstehenden GUI-Gesamtlauf noch eine neue ausdrückliche Testfreigabe.

## Sichtbarer Start vor der Anmeldung

`Invoke-VisibleSsms.ps1` mit `VisibleSsmsHook.ps1` ergänzt einen Start für
beaufsichtigte Proben. Der eigene SSMS-Prozess wird innerhalb der geschützten
Windows-Netzwerkanmeldesitzung des Labhelpers zunächst ausschließlich mit
`-nosplash` gestartet. Ohne automatische Serververbindung kann sein Hauptfenster
vor dem Anmeldedialog sichtbar ausgewählt und maximiert werden. Ob SSMS selbst
aus seinem Benutzerprofil weitere Dialoge öffnet, muss dabei beobachtet werden;
ein gestarteter Prozess behauptet weiterhin keine Anmeldung oder Sichtbarkeit.

Der private `preflight-ready.json` nennt PID, Prozessstartzeit, vorgesehenes
Labziel und `master` sowie Encrypt=`Mandatory` und den exakt übernommenen
booleschen Trustwert. Diese Werte enthalten keine Zugangsdaten. Die zugehörige
eigene Fensterinstanz muss anhand PID/Startzeit und aktuellem Fensterinventar
zugeordnet werden. Eine bestehende SSMS-Instanz erhält durch die Auswahl von
Windows Authentication nicht die Netzwerkanmeldung des separat gestarteten
Labclients. Ebenso beweist der lokale angezeigte Windows-Benutzer bei einem
Netzwerkanmeldestart noch nicht die tatsächlich verwendete SQL-Identität.
[Microsoft: CreateProcessWithLogonW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createprocesswithlogonw)

Erst im sichtbar geprüften eigenen Fenster öffnet der Operator eine Verbindung
zum ausgewählten Labziel mit Windows Authentication, den privaten TLS-Werten
und `master`. Anmelde- und Sicherheitsdialoge bedient ausschließlich der
Operator. Anschließend folgt die vorhandene lesende00-Abfrage mit Zielzeugen,
Windows-Authscheme, Verschlüsselungs- und SSMS-Wache. Erst ihr tatsächlich
beobachteter PASS erlaubt die eigene Datenbankanlage. Fensterstart,
Verbindungsversuch oder eine Benutzerbestätigung ohne verbundenen Vorcheck
genügen dafür nicht. Der zehnminütige Vorcheck und die gemeinsame endliche
Lauf-/Auditgrenze bleiben erhalten; danach ist die eigene Testinstanz geschlossen
und darf nicht durch eine andere Verbindung ersetzt werden.

Das Profil verwendet danach denselben geprüften Receipt-Ablauf mit unverändertem
kopiertem DebugScript, echter Phase2, eigener Prozessownership und frischem
Windows-Audit. Die vier SQL-freien Gegenproben prüfen den tatsächlich kompilierten
Start ohne Verbindungsargumente, den expliziten manuellen Zielvertrag, erhaltene
SQL-/Receipt-/Ownershipwachen und die Ablehnung geänderter historischer Hooks:

```powershell
python -m unittest discover -s Tests/Release -p test_ssis_visible_ssms.py
```

Der ergänzte sichtbare Start bestand anschließend nativ den Windows-NTLM-/Ziel-/
Verschlüsselungsvorcheck auf SQL2025/CU8. Öffentliche Erst- und Wiederholungs-
installation sowie die aktuelle API in derselben SSMS-Instanz bestanden.
Die echte kopierte Unicode-Zelle wurde mit184441 UTF16-Zeichen vor der Ausführung
hashgleich zum aktuellen Serverartefakt geprüft. Der Koordinator blieb dennoch
`FAILED_CLEANED` mit elf Checks und keinem bestandenen Gesamtfall: Die erste
Testhülle lehnte19 reguläre `GO`-Trenner des tatsächlichen DebugScripts ab.
Es erfolgte keine GUI-Ausführung dieses kopierten DebugScripts und kein Phase2.
Die eigenen Ressourcen wurden bereinigt; der frische Windows-Audit bestand.
Die vorausgegangene beaufsichtigte Probe war bereits vor einem bestandenen
Anmeldevorcheck ohne Datenbankanlage beendet worden; auch deren Audit bestand.
Ein später gezeigter SSPI-Fehler aus einer anderen bestehenden SSMS-Instanz
qualifiziert den gebundenen Testclient nicht und beweist allein keine Ursache
für dessen früheren Verbindungsversuch. Alle bisherigen Fehler und Grenzen
bleiben erhalten. Für einen weiteren nativen Lauf ist eine neue konkrete
endliche Testfreigabe nötig.

### Mehrere Batches und überprüfter Fehlerabbruch

Die tatsächliche DebugScript-Ausgabe verwendet reguläre `GO`-Batchtrenner.
Die frühere Single-Batch-Testhülle passt deshalb nicht zu dieser Ausgabe.
`Invoke-SsmsSqlcmd.ps1`, `SsmsSqlcmdHook.ps1` und
`New-SsmsSqlcmdEnvelope.ps1` bilden dafür einen gesonderten Testpfad. Er behält
den sichtbaren Start und den manuellen Anmeldevorcheck bei und verwendet in der
eigenen Ausführungsabfrage **SQLCMD Mode**, über das Menü `Query` aktiviert.
Bestehende Benutzerabfragen und globale SSMS-Defaults werden nicht geändert.
[Microsoft: SQLCMD-Skripte im Query Editor](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/edit-sqlcmd-scripts-query-editor)

In der ersten Probe dieses Pfads endete der interne zehnminütige Vorcheck
vor der späteren Verbindungsbestätigung. Ohne Datenbankanlage oder GUI-Abfrage
blieb der Koordinator `FAILED_CLEANED` mit fünf Cleanupchecks; der reservierte
frische Windows-Audit bestand. Der korrigierte SQLCMD-Pfad lässt für den
beaufsichtigten Vorcheck bis zu20 Minuten zu, weiterhin innerhalb der
ausdrücklich freigegebenen gemeinsamen Gesamtgrenze. Die vorhandene Klemme
auf Gesamtende minus zehn Minuten bleibt erhalten; eine spätere Anmeldung
verkürzt somit das verbleibende GUI-/Auditfenster. Fristen werden während
eines laufenden Versuchs nicht verlängert. Ein erneuter Ablauf wird künftig
ausdrücklich als `SSIS_SSMS_TARGET_PREFLIGHT_TIMEOUT` klassifiziert.

Auch die anschließend ausdrücklich freigegebene Probe mit20 Minuten Vorcheck
endete am2026-11-02 mit diesem Timeout. Die Verbindung war vom Operator
hergestellt worden; die Teststeuerung brachte den sichtbaren Zielvorcheck
jedoch nicht innerhalb der Frist zur Ausführung. Es gab keine neue
Datenbankanlage und keine GUI-Abfrage. Der Koordinator bleibt
`FAILED_CLEANED` mit fünf Cleanupchecks und keinem bestandenen Gesamtfall.
Der reservierte frische Windows-Audit bestand und bindet das exakte finale
Journal. Dies belegt sichere Bereinigung, keinen Fehler der SSIS-Fachfunktion
und keinen erfolgreichen SSMS-Gesamtabschluss. Die native Freigabe ist
verbraucht; ungenutzte Datenbank- oder GUI-Plätze erneuern sie nicht.

#### Sichtbaren Vorcheck direkt übergeben

Der aktuelle SQLCMD-Pfad veröffentlicht die private `preflight-ready.json`
erst mit dem konkreten Fristende `deadlineUtc` und einer neuen
`ObservationId`. Der Operator kann den Vorcheck nach dem Verbinden direkt
abschließen. Die Anmeldung, die Auswahl der eigenen Instanz und die sichtbare
Ausführung bleiben Schritte in SSMS.

1. Im eigenen SSMS-Fenster die in `sqlPath` angegebene 00-Abfrage auf der
   verbundenen `master`-Sitzung ausführen. Das Ergebnis muss genau eine
   erfolgreiche Zeile mit den vier Spalten `Result`, `AuthScheme`,
   `Patch` und `ObservationId` zeigen.
2. Die vier Zellen dieser Zeile ohne Spaltenüberschriften kopieren. Aus dem
   Repository-Stamm in PowerShell 7.5 den tatsächlichen Ready-Pfad einsetzen
   und die kopierte Zeile übernehmen.

   ```powershell
   & ./Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Write-SsmsPreflightObservation.ps1 `
     -ReadyPath '.runtime/<Journalpräfix>.preflight-ready.json' `
     -ObservedRow (Get-Clipboard -Raw)
   ```

3. `SSMS_PREFLIGHT_OBSERVATION_RECORDED` bestätigt die lokale Übernahme.
   Anschließend auf die private `gui-ready.json` des Koordinators warten.
   Sie erscheint nach der Prüfung und der Testvorbereitung.

Das Hilfsskript prüft Ergebnis, Windows-Authentifizierung, CU8, Laufkennung,
Abfragehash, Prozessstartzeit und Frist. Es legt die Beobachtungsdatei in
einem Schritt an und verweigert das Überschreiben. Der Koordinator prüft
zusätzlich den Hash der von ihm veröffentlichten Ready-Datei. Eine kopierte
Zeile aus einem früheren Lauf, eine veränderte Abfrage oder eine abgelaufene
Frist führen zur Ablehnung. Die Ergebniszeile bleibt eine sichtbare
Bedienerbeobachtung. Ihre lokale Übernahme führt selbst weder die Abfrage aus
noch bestätigt sie den Gesamtfall. Die aktualisierte Übergabe bestand
offline und im nativen Gesamtfall vom 2026-11-03. Für eine neu freigegebene native Probe muss der
Ausführungsplan mit den aktuellen Methoden erstellt werden.

Der neue SQL-freie Konstruktor hat dieselben Eingabeparameter wie die bisherige
Hülle. Er erlaubt die unveränderten `GO`-Trenner des hashgeprüften Bodys und
setzt außerhalb dieses Bodys `:ON ERROR EXIT`, den eigenen Datenbankkontext und
die nötigen Batchgrenzen vor das native Receipt. SQLCMD muss beim ersten
SQL-Fehler die Verarbeitung beenden, bevor spätere Batches und das Receipt
erreicht werden. Eingebettete Clientdirektiven, Shellkommandos und
SQLCMD-Variablensubstitution in Body oder Receipt werden vor jeder Dateianlage
verweigert. Damit verändert die Vorverarbeitung keine synthetischen Literale
und führt keine fremden Clientoperationen aus.
[Microsoft: On Error und GO](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-commands)

Nach API-Erzeugung, echter Zellenkopie und strikter02-Dateiprüfung ist zuerst
die **native Fehlergegenprobe** erforderlich:

1. In der eigenen zweiten Abfrage SQLCMD Mode aktivieren. Die native
   `sqlcmd-ready.json` nennt das07-Script und dessen gebundenen Hash.
2. Dieses Script vollständig unverändert einsetzen und als08-Ausführungsdatei
   speichern. Es wirft absichtlich Fehler51001 mit
   `SSIS_SQLCMD_EXPECTED_STOP`; ein späterer Batch würde die eigene Receiptphase
   auf99 setzen und eine unerwartete Fortsetzungsmarkierung ausgeben.
3. Genau den vollständigen Inhalt einmal ausführen. Der erwartete Fehler muss
   sichtbar sein; zusätzliche Fehler oder die Fortsetzungsmarkierung verhindern
   ein PASS. Den privaten visuellen Gegenprobennachweis schreiben.
4. **Vor dem eigentlichen DebugScript** auf die native
   `sqlcmd-negative.pass.json` warten. Der Koordinator vergleicht die
   gespeicherte08-Datei mit seinem unveränderten07-Script und verlangt, dass die
   echte Receiptphase weiterhin1 ist. Eine bloß sichtbare Fehlermeldung genügt
   nicht als Stopnachweis.
5. Mit `New-SsmsSqlcmdEnvelope.ps1` die04-Hülle aus der weiterhin unveränderten
  02-Datei und dem nativen03-Receipt erzeugen. In derselben eigenen Abfrage
   vollständig einsetzen, als05-Datei speichern und `-VerifyExisting` ausführen.
   Erst danach genau den vollständigen Inhalt einmal ausführen.
6. Die zwei fachlichen Ergebniszeilen, anschließend die Receiptmarkierung mit
   Unicodezeuge und den fehlerfreien Messages-Abschluss beobachten. Der
   absichtliche Fehler aus Schritt3 bleibt ein eigener negativer Fall.
   Der visuelle Hauptnachweis muss auch den beobachteten SQLCMD-Modus enthalten.
7. Ausschließlich die eigene SSMS-Instanz schließen. Der Koordinator verlangt
   weiterhin echtes Phase2, alle Kopier-/Envelope-/Windowswachen, eigene
   Bereinigung und den frischen separaten Windows-Audit.

Ein privates `operator-abort.json` unter dem eigenen Journalpräfix kann die
neue Probe während Vorcheck oder GUI-Phase fehlgeschlagen beenden. Es kann
keinen PASS erzeugen oder einen Lauf fortsetzen. Die eigene Prozessownership,
Bereinigung, reservierte Auditfrist und vorherige Fehler bleiben erhalten.

Die Offlinegegenproben prüfen den tatsächlich kompilierten Ablauf, die
frist- und laufgebundene Übernahme der Ergebniszeile, eine
mehrbatchige Unicode-Eingabe, unveränderten Body und Receipt sowie Abbruch-
direktive, Dateibindung, verbotene eingebettete Clientkommandos und den
fail-closed Operatorabbruch. Die Dateikonstruktion besteht zusätzlich mit der
tatsächlichen privaten Kopie aus der beendeten Probe; diese nachträgliche
Konstruktion wurde **nicht ausgeführt** und qualifiziert keinen Gesamtlauf.
Der getrennte [native Lauf vom 2026-11-03](../Qualification/SsmsClient.Complete.Windows.20261103.json)
bestand beide Proben. Im Ergebnis der Stopprobe blieb die Receiptphase auf 1.
Der Gesamtfall lieferte beide erwarteten Zeilen und das Unicode-Receipt.
Er endete mit bestätigter Phase 2, `PASS_CLEANED` und einem frischen
Windows-Audit gegen das finale Journal.

```powershell
python -m unittest discover -s Tests/Release -p test_ssis_sqlcmd_envelope.py
python Scripts/Release/validate_ssis_ssms_gui.py
```

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-05`
- Nachweis: `local: frische ZIP12-, sichtbare Windows-/SSMS- und strikte TLS-Gesamtfälle mit unabhängigen Abschlussaudits`
- Scope: Derselbe korrigierte 40-Parameter-DLL und unverändertes qualifiziertes ZIP: zwölf neu ausgeführte Windows-/CL-/Moduskontexte mit 15204 Assertions und zwölf frischen Audits. Sichtbarer Windows-NTLM-/SSMS-Gesamtfall auf SQL2025/CU8 CL150 lokal mit Erst-/Wiederholungsinstallation, echter vollständiger Unicode-Kopie, gespeichertem Hash, nativer SQLCMD-Fehlerprobe, zwei Ergebniszeilen und Phase-2-Receipt; PASS_CLEANED mit17 Prüfungen und frischem Windows-Audit. Benutzer übernahm Anmeldung und Gridoptionen. Getrennter ununterbrochener öffentlicher Windows-SQL2025-RTM-TLS-Neuaufbau, CL170 lokal/zentral, SQL-Anmeldung, 416 aktuelle SSIS-Assertions und frische SQL-/VM-/Fremdzustandsaudits PASS. Eigene Ressourcen entfernt, Konfiguration/Trust/andere Verbraucher unverändert. Frühere Fehler unverändert erhalten; Fresh.Build.20261104.json ergänzt die ursprüngliche Gesamtabnahme. Vereinbarter Debugvertrag, keine volle SSIS-Runtime-Parität oder OS-/VM-Verlustqualifikation; unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
