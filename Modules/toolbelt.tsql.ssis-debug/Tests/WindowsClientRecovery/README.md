# Vorbereitung, Windows-Client und harte Clientabbrüche

Diese Testkapsel ergänzt die [aktuelle Prüfmatrix](../README.md). Sie verändert
keine Lab-Infrastruktur und erteilt keine neuen Rechte. Native Eingaben,
Wiederherstellungsjournale und Originalausgaben bleiben ausschließlich lokal
unter dem ignorierten `.runtime/`; der öffentliche
[Abnahmenachweis](../Qualification/PreparationRecovery.Windows.20261101.json)
enthält nur aggregierte Orakel und statische Quellbindungen.

## Abgeschlossene Nachweise

| Teilumfang | Tatsächliche Abnahme |
|---|---|
| Öffentliches `PrepareServer.sql` | Windows SQL2019/CU32, 2022/CU26, 2025/CU8; je18 Assertions und frischer unabhängiger Audit |
| Portabler Exporthost | Fünf Ausgabeformen, jeweils echter Prozessabbruch und geschlossene stdout-Pipe; zehn Fälle, 95 Assertions |
| SQL-Client | Aktuelles DebugScript unter beobachtetem eigenen Sch-M-Lock und aktuelle API in offener Callertransaktion; zwei Fälle, 18 Assertions und frischer Audit |
| Öffentlicher Windows-Installer und CLI/API | Windows SQL2025/CU8, CL150; öffentliche Vorbereitung, Erst-/Wiederholungsinstallation, aktuelle38-Parameter-API und vollständiges DebugScript mit zwei Ergebniszeilen; zehn Assertions und frischer Windows-Audit |

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

```powershell
python -m unittest discover -s Tests/Release -p test_ssis_preparation_recovery.py
python Scripts/Release/validate_ssis_preparation_recovery.py
```

Die Gegenproben prüfen Quell-/Methodenbindung, Matrix, echte Abbruchorakel,
Rollback, unveränderliche Grenzen und SQL-freien Preflight. Sie laufen als
kurzer zusätzlicher Schritt im bestehenden SSIS-CI-Job, ohne neue SQL-Matrix,
VMs oder wiederholte native Qualifikation. Linux-SQL-CLR, ununterbrochener
öffentlicher Windows-TLS-Neuaufbau, unbegrenzte Produktionskapazität und
vollständige SSIS-Runtime-Parität bleiben getrennt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-01`
- Nachweis: `local: öffentlicher Windows-Installer und CLI/API auf SQL2025/CU8, CL150; frischer Windows-Audit`
- Scope: NTLM mit vorhandenen sysadmin-Rechten, öffentliche PrepareServer-Vorbereitung und Install-Local-Erst-/Wiederholungsinstallation, unveränderter Trust bei Wiederholung, aktuelle38-Parameter-API und vollständige DebugScript-Ausführung mit zwei Ergebniszeilen. Zehn Assertions für diesen begrenzten Teilumfang und exakte eigene Wiederherstellung; frischer Windows-Abschlussaudit PASS. Der anschließende sichtbare SSMS-Handshake scheiterte vor der ersten GUI-Abfrage; der Gesamtkoordinator bleibt FAILED_CLEANED. Separate Source-/Scope-Gegenproben verhindern eine Aufwertung zum GUI-PASS. Lab-Hostclientquellen entsprechen dem gemergten PR859; ursprüngliches importiertes Labmodul und ausgeführte Bytes bleiben getrennt gebunden. Frühere Fehler/Abbruchzustände und Audits erhalten. Windows-/SSMS-Scripttransport bleibt offen; keine Veröffentlichung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
