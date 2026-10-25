# SSIS-Debug ohne eigenen Build installieren

Das [ZIP-Installationspaket](SSIS-Debug-1.0.0-Install-Windows.zip) enthält
SSIS-Debug **1.0.0**, Script Parser **2.0.1**, die exakt passende Microsoft
ScriptDom-Assembly aus NuGet **180.117.0** und ResultTable **1.0.0**.
Es ist ein Entwicklungs-/Testpaket; der Status bleibt `unreleased`.

Der neue gemeinsame Modellkern ist separat auf Windows qualifiziert.
Dieses Archiv enthält weiterhin den zuvor qualifizierten SSIS-Binary und
keinen externen Exporthost. Die [aktuellen Buildnachweise](../Tests/README.md)
ändern den Inhalt dieses ZIPs nicht; ein aktualisierter Lieferstand bleibt
separat vorzubereiten.

## Download und Installation

1. Die ZIP-Datei über GitHubs Download-Schaltfläche herunterladen und vollständig
   entpacken. Die Verzeichnisstruktur beibehalten.
2. `START-HERE.txt` im Paketroot lesen. Sie führt über die Offlineprüfung,
   SQL-Server-Vorbereitung und PowerShell-Installation zur Installationskontrolle.
3. Die enthaltene synthetische DTSX-Datei auf den SQL-Server-Rechner kopieren und
   das SSMS-Beispiel abschnittsweise im selben Abfragefenster ausführen.

Windows SQL Server 2019, 2022 oder 2025, SSMS sowie auf dem Installationsrechner
PowerShell 7 und ODBC-sqlcmd werden vorausgesetzt. Für dieses administrative
Installationsbeispiel ist ein bestehender `sysadmin`-Zugang per Windows-Anmeldung
erforderlich. Visual Studio, MSBuild und ein SSIS-SDK werden nicht benötigt.

Enthalten sind alle drei DLLs, fertige SQL-Deployments mit eingebetteten
Assemblybytes, SHA2-512-Trustmanifeste, ResultTable-Sources, SQL-/PowerShell-
Installationsskripte, API-/Vertragsdokumentation, SSMS-Walkthrough und
synthetische DTSX-Fixtures. Die Installation öffnet vorhandene kanonische
Trust-/Lifecycle-Skripte. Strict Security bleibt aktiv; der Assembly-Trust
erfolgt für die exakten Hashes. Teilweise erfolgreiche Installationsschritte
werden bei einem späteren Fehler nicht automatisch zurückgerollt.

Für den ersten Test eine eigene Demodatenbank verwenden. Bereits vorhandene
SSIS-Debug- oder Table-Clone-Entwicklungsinstallationen mit einem früheren
Parserhash benötigen den gemeinsam aktualisierten Stand ihrer Consumer;
gleiche Versionsnummern ersetzen die exakte Binarybindung nicht. Das ZIP
installiert die drei aufgeführten Module. Table Clone wird separat aus dem
zugehörigen Repositorystand aktualisiert, falls es in derselben Datenbank
vorhanden ist.

## Integrität und Herkunft

Die [SHA-256-Prüfsumme](SSIS-Debug-1.0.0-Install-Windows.zip.sha256) bezieht sich
auf die gesamte ZIP-Datei. Im Archiv dokumentiert `PACKAGE-MANIFEST.json` den
exakten Quellcommit, die Modulversionen und Dateihashes; `SHA256SUMS.txt` enthält
die zusätzliche Dateiliste. Die vorhandenen Trustmanifeste binden die drei
DLLs und beide fertigen Deployments an den ausdrücklich ausgewählten Build.
Diese Hashvergleiche ersetzen keine digitale Herausgebersignatur.

Der Parser wird ohne PDB-Debugverzeichnis und mit synthetischem `PathMap`
gebaut. Die Toolbelt-Assemblies werden unverändert aus dem neu qualifizierten
Buildsatz übernommen. Der offizielle ScriptDom-Binarypin bleibt unverändert.
Seine MIT-Lizenz, Microsoft-/ANTLR-Hinweise, NuGet-Metadaten und Herkunft sind
unter `ThirdParty/ScriptDom-180.117.0/` im ZIP enthalten. Die unveränderte
Toolbelt-Lizenz liegt im Paketroot als `LICENSE.md`.

## Wartung und Prüfung

`Tests/Static/validate_install_package.py` prüft das tatsächlich versionierte
ZIP: Pfad-/Dateisicherheit, sämtliche Paket- und Deploymenthashes, exakte
Parser-/ScriptDom-Bindung sowie das Fehlen von CodeView-/PDB-Einträgen in den
beiden Toolbelt-DLLs. Der Check läuft im bestehenden SSIS-Offlinejob; es entsteht
weder ein neuer CI-Job noch ein zusätzlicher Build oder SQL-/Labzugriff.

Ein aktualisiertes ZIP erfordert einen zusammengehörigen, geprüften Artefaktsatz
mit aktuellen Pins. `Artifacts/` und sonstige Buildausgaben bleiben ignoriert;
die `.gitignore`-Ausnahme erlaubt in diesem Ordner nur README, die benannte ZIP
und ihre Prüfsumme. Bei einem Paketupdate werden ZIP und Prüfsumme gemeinsam
ersetzt und der entpackte Installer mit `-ValidateOnly` geprüft. Native
Qualifikation ist an den jeweiligen Binary-/Quellstand gebunden.

Die vorhandenen Modulnachweise gelten ausschließlich in ihrem dokumentierten
Scope. Dieses Paket ist keine vollständige Release- oder Produktionsqualifikation;
die getrennte authentifizierte TLS-Abnahme bleibt separat `not executed`.

Weitere Details: [Installation](../Examples/Installation/README.md),
[SSMS-Beispiel](../Examples/README.md), [API](../Documentation/USP_ExplainSsisDataFlow.md)
und [Prüfmatrix](../Tests/README.md).
