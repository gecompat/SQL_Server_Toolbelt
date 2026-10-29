# SSIS-Debug ohne eigenen Build installieren

## Separater Komponenten-V2-Kandidat

Die [V2-Installationsanleitung](../Documentation/ComponentsV2Installation.md)
führt zur getrennten ZIP-Lieferung und zum reinen T-SQL-Installer.

Die zusätzliche Lieferung `SSIS-Debug-ComponentsV2-1.0.0-Install-Windows.zip`
enthält den ausdrücklich gewählten Komponentenmodus V2. Er ergänzt fehlende
Versionsattribute mit nachvollziehbarem Schema-Default, Row Count sowie
Flatfile-Metadaten und explizit bereitgestellte SQL-Zeilenbestände. Die
[V2-Vertragsbeschreibung](../../../Documentation/Architecture/SSIS_COMPONENTS_V2_CONTRACT.md)
erklärt auch die parametrierbaren Ressourcenbudgets einschließlich `unlimited`.
V1- und V2-Lieferungen vollständig getrennt entpacken; die unveränderte
Modulversionsnummer ersetzt keine Prüfung des jeweiligen Artefakthashes.

Die neue Lieferung und ihr reiner T-SQL-Installer werden erst nach ihren
eigenen nativen Paketprüfungen als verwendbarer Kandidat ausgewiesen.
Die nachfolgende Anleitung und die historischen Nachweise beschreiben die
bestehende V1-Lieferung. Beide bleiben unveröffentlicht.

Das [ZIP-Installationspaket](https://github.com/gecompat/SQL_Server_Toolbelt/blob/main/Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip) enthält
SSIS-Debug **1.0.0**, Script Parser **2.0.1**, die exakt passende Microsoft
ScriptDom-Assembly aus NuGet **180.117.0** und ResultTable **1.0.0**.
Es ist ein Entwicklungs-/Testpaket; der Status bleibt `unreleased`.

Dieses Archiv enthält den auf Windows SQL2019/2022/2025 lokal und zentral
qualifizierten SSIS-Build mit Pipeline-Identitäten und qualifizierten Lookup-Ausgangsrollen. Es enthält
keinen externen Exporthost. Die [Prüfmatrix](../Tests/README.md) trennt die
zwölf expliziten Engine-/CL-/Modusnachweise von den Prüfungen des entpackten Installationspakets.
Die enthaltene [Buildprojektion](../Tests/Qualification/LookupRoles.Windows.CL.20261025.json)
bindet den Binary an diese Matrix. Die getrennte Paketprojektion im
[Qualifikationsverzeichnis des Repositorys](https://github.com/gecompat/SQL_Server_Toolbelt/tree/main/Modules/toolbelt.tsql.ssis-debug/Tests/Qualification)
nennt je geprüfter Lieferung den exakten ZIP-Hash sowie Umfang und Ergebnis
der Installation und des Upgrades. Den Hash der heruntergeladenen Lieferung
mit dem passenden Nachweis vergleichen. Der öffentliche PowerShell-Aufruf
mit Windows-Anmeldung ist zusätzlich mit 55 Prozess-Orakeln offline geprüft;
eine echte Windows-Testidentität bleibt eine getrennte Clientvoraussetzung.
Der PowerShell-Installer verwendet den lokalen Deploymentmodus; die kanonischen
SQL-Skripte unterstützen zusätzlich den zentralen Modus ohne Synonyme.

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

## Bestehende Testinstallation aktualisieren

1. Das neue ZIP in ein neues Verzeichnis entpacken und `START-HERE.txt` lesen.
   Die neue und alte Lieferung nicht dateiweise vermischen.
2. `Install-Local.ps1 -ValidateOnly` mit denselben Zielangaben wie bei der
   Erstinstallation ausführen, danach denselben Aufruf ohne `-ValidateOnly`.
   Die bestehende Testdatenbank wird weiterverwendet. ResultTable und Parser
   werden wiederholt installiert; die SSIS-Assembly wird ausgetauscht.
3. `VerifyInstallation.sql` und das SSMS-Beispiel erneut ausführen. Die
   Versionsnummer bleibt 1.0.0; entscheidend ist der neue exakte Binaryhash.

Die neue Build-Upgradeprüfung beginnt mit dem zuvor ausgelieferten
Pipeline-Identitätsbuild aus PR #446. Beide Builds haben die Modulversion 1.0.0;
ihre exakten Assemblyhashes unterscheiden sie.
Frühere Upgradepfade behalten ihre eigenen datierten Nachweise. Bereits vorhandene gemeinsame
Dependencies und alte Assembly-Trusteinträge werden nicht pauschal entfernt.
Beim ersten Fehler bricht der Installer ab; erfolgreiche vorherige Schritte
bleiben bestehen. Die [Installationsanleitung](../Examples/Installation/README.md)
beschreibt Rechte, Transportwahl und die fünf Installationsschritte.

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

Für die optionale Quellprüfung nennt `buildSourceRoots` im Paketmanifest die
jeweiligen exakten Buildinputs. Die ursprünglichen Parserquellen liegen
zusätzlich unter `BuildSources/ScriptParser-2.0.1/`; damit bleiben ihre
manifestgebundenen Zeilenenden neben dem separat gebundenen SSIS-Guard erhalten.
DLLs, Trustmanifeste und Dependencypins werden nicht umgeschrieben.

[`Scripts/New-InstallPackage.py`](../Scripts/New-InstallPackage.py) erstellt den Satz aus einem versionierten
Quellcommit und ausdrücklich angegebenen qualifizierten Releaseverzeichnissen.
Es kompiliert nichts. Der zweifache Paketbau verwendet feste ZIP-Metadaten und
wird auf Bytegleichheit geprüft. Für die Installation ist dieses Werkzeug
nicht erforderlich.

Die Gesamtpakete unter `Releases/1.0.0/` behalten ihre eigene frühere Lieferung
und Qualifikation. Dieses aktualisierte SSIS-ZIP ersetzt deren eingebettete
Artefakte nicht automatisch und veröffentlicht kein Release.

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
