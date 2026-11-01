# Lokale Installation für das SSMS-Beispiel

Diese Anleitung installiert den aktuellen Entwicklungsstand in einer eigenen
Demodatenbank. Sie verwendet die kanonischen Lifecycle-/Trustskripte und
ändert weder öffentliche SQL-Verträge noch Versions-/Dependencypins. Die
Module bleiben unveröffentlicht; den jeweiligen Abnahmeumfang beschreibt die
[aktuelle Installationsübersicht](../../Documentation/CurrentInstallation.md#qualifizierter-installationsumfang).

| Bestandteil | Version | Installation / Trust |
|---|---|---|
| ResultTable | 1.0.0 | T-SQL in der Zieldatenbank; keine CLR-Assembly |
| Script Parser | exakt 2.0.1 | Parser und exakt gepinntes Microsoft ScriptDom in derselben Datenbank |
| SSIS-Debug | 1.0.0 | SSIS-Debug-Assembly in derselben Datenbank |

Alle drei Assemblies verwenden UNSAFE. Ihre SHA2-512-Trusteinträge gelten
instanzweit. `clr strict security` bleibt aktiviert; `TRUSTWORTHY ON` wird nicht
benötigt. Auf dem SQL Server sind kein SSIS-SDK und kein Visual Studio für den
Aufruf erforderlich. Windows SQL Server 2019/2022/2025 mit CL150/160/170 und ein
vorhandener `sysadmin`-Zugang per Windows-Anmeldung sind Voraussetzungen dieses
administrativen Beispiels. PowerShell 7 und ODBC-sqlcmd laufen auf dem
Installationsrechner.

Der getrennte [öffentliche SSIS-Trustschritt](../../Tests/InstallerTrust/README.md)
ist mit dem aktuellen freigegebenen Binary auf allen drei Windows-SQL-Versionen
nativ geprüft. Sein Guard weist leere, NULL- und überlange Hashliterale vor
Mutation zurück. Dies belegt den einzelnen SQL-Schritt; der vollständige
Windows-Anmeldeweg dieses PowerShell-Beispiels ist inzwischen
[auf SQL2025/CU8, CL150 nativ geprüft](../../Tests/Qualification/InstallerClient.Windows.20261101.json):
öffentliche Vorbereitung, Erst-/Wiederholungsinstallation, aktuelle CLI/API und
vollständige DebugScript-Ausführung unter NTLM mit eigenem frischem Windows-Audit.
Der spätere SSMS-Handshake scheiterte, sodass der vollständige GUI-Transport
weiterhin offen bleibt. `PrepareServer.sql` ist [separat auf allen drei Windows-Versionen
qualifiziert](../../Tests/WindowsClientRecovery/README.md). Sein Pending-Guard
nimmt ausschließlich die dokumentierten impliziten min/max-memory-Defaults
aus und aktiviert keine fremden vorgemerkten Änderungen. Das PowerShell-Beispiel
übergibt Release-SQL ausdrücklich mit UTF8-Codepage65001 an sqlcmd.
Der neue Nachweis bindet die aktuellen Repository-Beispiele mit dem unveränderten
freigegebenen Binary. Bestehende ZIPs enthalten weiterhin ihre ursprünglichen
Beispielbytes; die Korrekturen werden damit nicht rückwirkend ausgeliefert.
Historische ZIP-Nachweise behalten ihre
ursprünglichen Artefakte; die Korrektur steht im aktuellen Repository-Trustskript.

## 1. Passenden Artefaktsatz bereitstellen

Für einen Test ohne eigenen Build das
[vorbereitete ZIP-Installationspaket](../../InstallPackages/README.md)
vollständig entpacken und mit dessen `START-HERE.txt` beginnen. Die folgenden
Schritte und relativen Pfade gelten auch im entpackten Paketroot. Das ZIP
enthält bereits alle benötigten DLLs, Deployments und Trustmanifeste.

Ein frischer Git-Klon enthält die Quellen, aber keine Buildartefakte in
`Artifacts/`. Vor der Installation einen vom Betreiber geprüften,
zusammengehörigen Buildsatz bereitstellen:

| Verzeichnis relativ zum Repository | Benötigte Dateien |
|---|---|
| `Modules/toolbelt.tsql.script-parser/Artifacts/` | `Toolbelt.Tsql.ScriptParser.dll`, `Microsoft.SqlServer.TransactSql.ScriptDom.dll`, `Toolbelt.Tsql.ScriptParser.trust-manifest.json`, `Deploy.WithAssembly.sql` |
| `Modules/toolbelt.tsql.ssis-debug/Artifacts/` | `Toolbelt.Tsql.SsisDebug.dll`, `Toolbelt.Tsql.SsisDebug.trust-manifest.json`, `Deploy.WithAssembly.sql` |

Der Parser muss exakt zu `Contracts/DependencyPins.json` passen. Ein anderer
Build mit derselben Versionsnummer 2.0.1 ist kein austauschbarer Ersatz.
Ein Hashvergleich bindet Dateien an das Manifest und die Repositorypins;
Herkunft und Freigabe des Buildsatzes prüft der Betreiber gesondert.

Für einen ausdrücklich vorbereiteten eigenen Build stehen der
[Parser-Releasebuilder](../../../toolbelt.tsql.script-parser/Scripts/New-ClrReleaseArtifacts.ps1)
und der [SSIS-Releasebuilder](../../Scripts/New-ClrReleaseArtifacts.ps1) bereit:

```powershell
# Aus dem Repositoryroot; vorhandenes MSBuild und .NET-Framework-4.8-Targeting-Pack.
$dom = 'C:\Contoso\BuildInputs\Microsoft.SqlServer.TransactSql.ScriptDom.dll'
./Modules/toolbelt.tsql.script-parser/Scripts/New-ClrReleaseArtifacts.ps1 `
    -ScriptDomDllPath $dom
./Modules/toolbelt.tsql.ssis-debug/Scripts/New-ClrReleaseArtifacts.ps1 `
    -ScriptDomDllPath $dom `
    -ParserReleaseDirectory (Join-Path (Get-Location).Path 'Modules/toolbelt.tsql.script-parser/Artifacts')
```

Der erste Builder benötigt den festgelegten ScriptDom-Input aus
[`Microsoft.SqlServer.TransactSql.ScriptDom` 180.117.0](https://www.nuget.org/packages/Microsoft.SqlServer.TransactSql.ScriptDom/180.117.0);
Identität, Dateiversion
und SHA2-512 werden geprüft. Der zweite verlangt den exakt gepinnten Parser.
Compiler, Pfade und Quellbytes können einen abweichenden Parserhash ergeben.
Bei `SSIS_BUILD_DEPENDENCY_PIN_MISMATCH` oder
`SSIS_INSTALL_DEPENDENCY_PIN_MISMATCH` stoppen und einen passenden freigegebenen
Artefaktsatz verwenden. Eine neue Dependencybindung ist eine gesonderte
Build-/Qualifikationsaufgabe; die Installationsbeispiele schreiben keine Pins
um und erteilen unbekannten Binaries keinen Trust. Ein neuer Eigenbuild
übernimmt keine früheren nativen Nachweise automatisch.

Alternativ lassen sich externe Releaseverzeichnisse über
`-ParserReleaseDirectory` und `-SsisReleaseDirectory` angeben. Die Quellen
einschließlich ResultTable und der beiden Trustskripte werden weiterhin aus
dem ausdrücklich gewählten Repository verwendet.

## 2. Artefakte ohne SQL-Zugriff vorprüfen

Aus dem Repositoryroot, mit bewusst gewähltem späterem Ziel:

```powershell
./Modules/toolbelt.tsql.ssis-debug/Examples/Installation/Install-Local.ps1 `
    -Server localhost -Database ContosoSsisDebug -ValidateOnly
```

[`Install-Local.ps1`](Install-Local.ps1) bestimmt seinen Repositoryroot aus
dem eigenen Speicherort; ein privater Rechner- oder Worktreepfad ist nicht
eingebaut. `-RepositoryRoot` kann ausdrücklich einen anderen Root wählen.
Vor dem ersten sqlcmd-Aufruf prüft das Script vorhandene Inputs, Modul- und
Dependencyversionen, drei DLL-Hashes und beide Deploymentartefakthashes.
`-ValidateOnly` startet kein sqlcmd und öffnet keine SQL-Verbindung. Dieser
Prüfmodus bestätigt Dateien, nicht die Rechte oder Konfiguration eines Servers.

## 3. Server und Demodatenbank vorbereiten

[`PrepareServer.sql`](PrepareServer.sql) in SSMS auf dem vorgesehenen SQL
Server mit einem vorhandenen `sysadmin`-Zugang vollständig ausführen.
`@DemoDatabase` bei Bedarf anpassen. Der Block verlangt eine transaktionsfreie
Sitzung, die unterstützte Windows-/SQL-Version, deaktiviertes Lightweight
Pooling und aktivierte CLR Strict Security. Ausstehende Konfigurationsänderungen
stoppen vor RECONFIGURE; sie müssen zuerst gesondert geprüft werden.

Der Block aktiviert `clr enabled`, wenn erforderlich, und prüft den wirksamen
Wert. Vorzustand und gewähltes Ziel lokal festhalten. Eine fehlende Demodatenbank
wird angelegt und erhält CL150; eine vorhandene Datenbank muss ONLINE mit
CL150/160/170 sein und erhält keine geänderten Optionen. Servervorbereitung
und Datenbankanlage sind keine gemeinsame atomare Transaktion.

## 4. Module und Assembly-Trust installieren

Nach erfolgreicher Vorbereitung mit demselben Ziel ausführen:

```powershell
./Modules/toolbelt.tsql.ssis-debug/Examples/Installation/Install-Local.ps1 `
    -Server localhost -Database ContosoSsisDebug
```

Das Script verwendet vorhandene Windows-Administratorrechte und ODBC-sqlcmd.
Reihenfolge der fünf Aufrufe:

1. ResultTable mit `DeploymentMode=local`; die relativen Source-Includes werden
   aus seinem Deploymentverzeichnis aufgelöst, danach wird das vorherige
   PowerShell-Arbeitsverzeichnis wiederhergestellt.
2. Administrativer Trust für die exakten Parser-/ScriptDom-Hashes über das
   vorhandene Parser-Trustskript in `master`.
3. Parser und ScriptDom über das generierte `Deploy.WithAssembly.sql`.
4. Administrativer Trust für den exakten SSIS-Debug-Hash über dessen vorhandenes
   Trustskript in `master`.
5. SSIS-Debug über sein generiertes `Deploy.WithAssembly.sql`.

Jeder Aufruf verwendet Windows-Anmeldung (`-E`), Verschlüsselung (`-N`) und
Fehlerabbruch (`-b`). Standardmäßig wird der explizite Trustwert true als `-C`
übergeben. Für Zertifikatsvalidierung:

```powershell
./Modules/toolbelt.tsql.ssis-debug/Examples/Installation/Install-Local.ps1 `
    -Server localhost -Database ContosoSsisDebug -TrustServerCertificate:$false
```

Dann wird `-C` weggelassen. Es gibt keinen Fehlerfallback und keinen Retry mit
verändertem Trustwert. Diese Transportwahl ändert nicht den Assembly-Hash-Trust.
`-SqlcmdPath` wählt bei Bedarf den vollständigen Pfad zur ODBC-sqlcmd-Datei.

Beim ersten sqlcmd-Fehler bricht die Folge ab. Bereits erfolgreich installierte
Module und Trusteinträge bleiben bestehen; es gibt keinen Gesamtrollback.
Die jeweiligen Modulskripte behalten ihre eigenen Preflights und Transaktionen.
Die generierten SQL-Dateien enthalten die Assemblybytes; die DLLs benötigen
keine Dateifreigabe auf dem SQL Server. Vorbereitung, Installation, Prüfung
und Walkthrough vergeben keine Benutzerrechte automatisch.

## 5. Installation kontrollieren und Datenfluss debuggen

[`VerifyInstallation.sql`](VerifyInstallation.sql) in SSMS ausführen; dessen
`USE`-Zeile bei abweichendem Datenbanknamen anpassen. Erwartet werden drei
Modulmarker mit 1.0.0/2.0.1/1.0.0 und drei UNSAFE-Assemblies mit aktuellem
Hash-Trust. Die Parserprobe lädt den CLR-Parser tatsächlich; die beiden
Help-Aufrufe zeigen die öffentlichen Schnittstellen. Das ist eine begrenzte
Installationskontrolle und kein vollständiger Runtime- oder Releasenachweis.

Anschließend die [synthetische DTSX-Fixture](../../Tests/Fixtures/synthetic-8.dtsx)
unverändert auf den SQL-Server-Rechner nach `C:\Contoso\synthetic-8.dtsx`
kopieren. Für das serverseitige `OPENROWSET` müssen Datei-/BULK-Leserechte
vorhanden sein. Der [SSMS-Walkthrough](../SsmsDebugWalkthrough.sql) mit seiner
[Anleitung](../README.md) erzeugt die JSON-Vorlage, fordert CTE-Stufen an und
zeigt direkte DECLARE-Änderungen. Sein Vorlagenaufruf prüft den tatsächlichen
SSIS-Debug-CLR-Einstieg; die T-SQL-Hilfe allein lädt diesen nicht.

Für spätere Benutzer werden vorhandene EXECUTE-Rechte auf der öffentlichen
Prozedur, vollständige erforderliche Katalogsicht und SELECT auf den manuell
gelesenen Quellen benötigt. Das Demobeispiel legt außerdem eigene Tabellen an.

## Quellen und Gültigkeit

- [Öffentlicher Objektvertrag](../../Documentation/USP_ExplainSsisDataFlow.md)
- [Aktueller API-Vertrag](../../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md)
- [Microsoft: CLR aktivieren und Voraussetzungen](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/clr-enabled-server-configuration-option?view=sql-server-ver17)
- [Microsoft: sys.sp_add_trusted_assembly](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-add-trusted-assembly-transact-sql?view=sql-server-ver17)
- [Microsoft: sqlcmd-Optionen](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility?view=sql-server-ver17)

Die [Testbeschreibung](../../Tests/README.md) grenzt Offlineprüfungen von
tatsächlich ausgeführten Installations-/SSMS-Läufen und vorhandener nativer
V1-Evidenz ab. Die Beispiele führen selbst keine Labverwaltung aus.
