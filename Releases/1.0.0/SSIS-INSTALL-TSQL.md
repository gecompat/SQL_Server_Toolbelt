# Eigenständiger T-SQL-Installer für SSIS-Debug

`SSIS-INSTALL-TSQL.sql` installiert die bestehenden SQL-CLR-Objekte für
`toolbelt.core.result-table` 1.0.0, `toolbelt.tsql.script-parser` 2.0.1 und
`toolbelt.tsql.ssis-debug` 1.0.0. Die drei qualifizierten Assemblies sind
jeweils einmal im Batch eingebettet. Die Herkunft und die Prüfsummen stehen in
[ssis-standalone-installer.json](ssis-standalone-installer.json); die
vollständigen Lizenz- und Herkunftshinweise liegen in
[SSIS-INSTALL-TSQL-LICENSE.md](SSIS-INSTALL-TSQL-LICENSE.md) und
[ThirdParty/ScriptDom-180.117.0](ThirdParty/ScriptDom-180.117.0/).

## Voraussetzungen und Grenzen

- Windows SQL Server 2019, 2022 oder 2025 mit Kompatibilitätslevel 150, 160
  oder 170.
- Die CLR muss bereits aktiviert sein und `clr strict security` eingeschaltet
  bleiben. Das Script ändert keine Serverkonfiguration und startet den Server
  nicht neu.
- Die aktuelle Datenbank muss eine bereits angelegte Benutzerdatenbank sein.
  Das Script erstellt keine Datenbank und installiert keine Objekte in
  `master`, `model`, `msdb` oder `tempdb`.
- Das Script erwartet eine frische Sitzung ohne Caller-Transaktion und ohne
  aktivierte implizite Transaktionen.
- Standardmäßig muss SQL Server die drei exakt eingebetteten Assemblies
  bereits kennen. Nur wer bewusst die Option
  `@RegisterAssemblyTrust = 1` ändert und bereits die erforderlichen
  `sysadmin`-Rechte hat, lässt das Script die drei exakten Paket-Hashes
  registrieren. Unbekannte Trust-Einträge werden weder entfernt noch ersetzt.
- Externe neutrale Modell- und Identitätsexporte sind keine SQL-Objekte dieses
  Installers. SSISDB, der SSIS-Katalog, DTSX-Pakete und ein DTSX-Paketbericht
  sind nicht Teil dieses Installers; Paketberichte werden separat behandelt.

## Ausführen

Prüfe die Paket- und DLL-Herkunft anhand der verknüpften Provenienz und lies
die Lizenzhinweise. Führe anschließend den gesamten Inhalt von
`SSIS-INSTALL-TSQL.sql` in einer frischen Verbindung aus, zum Beispiel als
einzelne Abfrage in SQL Server Management Studio. Der Inhalt ist ein einzelner
T-SQL-Batch: Er benötigt zur Laufzeit weder SQLCMD-Direktiven noch `GO`,
PowerShell, `sqlcmd` oder Dateien auf dem Datenbankserver.

Die Deklaration `@DeploymentMode` am Anfang steht standardmäßig auf `local`.
Sie kann auf `central` gesetzt werden, wenn die Umgebung den vorhandenen
zentralen Deploymentmodus verwendet. Andere Werte werden vor der ersten
Installationsstufe abgewiesen.

Das Script prüft Datenbank, Plattform, Kompatibilitätslevel, CLR-Sicherheit,
exakte DLL-Hashes und Assembly-Trust, bevor es mit den Modulstufen beginnt.
Bei einem Fehler meldet es die Stufe und den SQL-Fehler und wirft den Fehler
erneut aus. Bereits erfolgreich abgeschlossene Modulstufen können bei einem
späteren Fehler bestehen bleiben; der Installationsablauf ist nicht global
atomar. Eine erfolgreiche Ausgabe bestätigt nur den Abschluss dieser drei
Modulinstallationen auf der gewählten Datenbank.

## Nachweisumfang

Die bestehenden Paket- und Modulnachweise bleiben unverändert und werden durch
diese Lieferform nicht erweitert. Die Prüfung der T-SQL-Ausführung belegt nur
die ausgewählten Installations-, Wiederholungs-, Hilfe- und Sanity-Fälle auf
den ausdrücklich getesteten Windows-Zielen. Sie ist keine vollständige
Versionsmatrix, Lifecycle-, SSISDB-, DTSX-, Client- oder
Veröffentlichungsfreigabe. Die Veröffentlichung bleibt nicht freigegeben.

Die begrenzten Laufzeitfälle und ihre Quellpins stehen in der
[separaten Laufzeitevidenz](ssis-standalone-installer-runtime-qualification.json).
Zwei ausgewählte Windows-Ziele (SQL Server 2019/CL150 und 2025/CL170) bestanden
lokale und zentrale Installation, Wiederholung sowie die vorhandenen API-,
Hilfe-, Sanity- und Sitzungsprüfungen. Beide unabhängigen Bereinigungsprüfungen
bestanden. Der Harness stellte die exakt gebundenen Assembly-Trust-Einträge
vorab bereit; der optionale Registrierungszweig des Installers wurde nicht
ausgeführt. Diese Fälle belegen weder die vollständige Plattformmatrix noch
SSISDB-/DTSX-Ausführung oder eine Veröffentlichung.
