# Toolbelt bauen und installieren

Alle aktuellen Einstiege verwenden denselben markerfreien Installationskern.
Die SQL-Datei läuft als gewöhnliche Abfrage ohne SQLCMD-Modus; nur die erste
`USE`-Zeile muss angepasst werden. Die Installation ergänzt fehlende Objekte,
ersetzt oder entfernt aber keine vorhandenen Objekte.

## Den passenden Einstieg wählen

| Aufgabe | Einstieg |
|---|---|
| Fertigen Satz mit einem Aufruf installieren | [Ein-Aufruf-Installer](ONE-CALL-INSTALL.md) |
| Normale SQL-Datei aus Quellen bauen | [Build und Binaryeingaben](../Scripts/Install/README.md) |
| Optional Datenbank anlegen oder CLR aktivieren | [Vorbereitung und Sicherheitsgrenzen](PROVISIONING.md) |
| Nur DTSX-Debug installieren | [SSIS-Funktionssatz](../Modules/toolbelt.tsql.ssis-debug/Documentation/SimpleInstallation.md) |
| Lokal oder zentral verstehen | [Deployment-Modell](../Documentation/Architecture/DEPLOYMENT_MODEL.md) |

## Auswahl ohne Verbindung prüfen

```powershell
& .\Deployment\Build-Install.ps1 -PlanOnly -Platform Windows `
  -DeploymentMode central -ModuleId toolbelt.tsql.ssis-debug
```

Der Plan zeigt die ausgewählten Module einschließlich ihrer transitiven
Pflichtabhängigkeiten. Nicht unterstützte Plattform-/Moduskombinationen werden
abgewiesen. Ohne ModuleId wird das vollständige Profil gewählt. Planen lädt
keine Binaries und verbindet sich nicht mit SQL Server.

## SQL-Datei bauen

Mit den gemäß Buildanleitung bereitgestellten, gebundenen Eingaben:

```powershell
& .\Deployment\Build-Install.ps1 -Inputs .runtime\build-inputs `
  -OutputSqlFile .runtime\Install-Toolbelt.sql `
  -Platform Windows -DeploymentMode central -TrustMethod auto
```

PowerShell 7.4+, Python und die beschriebenen lokalen Buildwerkzeuge sind
hierfür erforderlich. Die SQL-Datei und ihre `.manifest.json` gehören zusammen.
Vorhandene Ausgabedateien werden nicht überschrieben. Einzelmodule werden mit
`-ModuleId` gewählt und erhalten dieselbe Installationslogik wie der Gesamtsatz.

## Installieren

```powershell
& .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost `
  -Database ContosoToolbelt -DeploymentMode central `
  -InstallSql .runtime\Install-Toolbelt.sql
```

Der Client benötigt ODBC-sqlcmd; die direkte Ausführung der SQL-Datei in SSMS
benötigt ihn nicht. Ohne Credential gilt die integrierte Prozessidentität.
`-ValidateOnly` prüft ausschließlich lokale Dateien. `-PreflightOnly` prüft das
Ziel lesend. Für Trustwege, SQL-Anmeldung, Zertifikatsprüfung, Zeitgrenzen und
Fehlermeldungen gilt die [Clientanleitung](ONE-CALL-INSTALL.md).

`Deploy-All.ps1` bleibt ein kurzer gemeinsamer Einstieg: PlanOnly ruft denselben
Plan auf, Inputs mit OutputSqlFile denselben Build und Inputs mit Zielparametern
denselben Installer. Ohne Inputs verwendet die Installation den aktuellen
fertigen Payload, keinen automatischen Download eines historischen Releases.
Die früheren ModuleVariables und CreateDatabaseIfMissing gehören zum alten
Weg; aktuelle Parameter heißen Inputs beziehungsweise CreateDatabase.

## Lebenszyklus und Nachweise

Es gibt keine installierte Toolbelt-Versions-/Modusregistry und keine
Deployment-Extended-Properties. Der Abschluss prüft deklarierte Objektnamen und
Typen, nicht die Definition bestehender Objekte. Ein Teilfehler kann bereits
angelegte Objekte hinterlassen; es gibt keinen automatischen Rollback über alle
Module. Eine erneute Ausführung ist kein Upgrade und keine Integritätsabnahme
bereits vorhandener SQL-Definitionen. Historische Uninstall-Skripte dürfen diese
Installation nicht verwalten.

Frühere Releases und Qualifikationsnachweise bleiben an ihre ursprünglichen
Bytes gebunden. Ihre ursprüngliche Deploymentanleitung ist im
[unveränderlichen Vorgängerstand](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2fbe8e3e86f370b22ad2ce9f9716d971072a052b/Deployment/README.md) nachlesbar.
Ein neuer Offlinebuild behauptet keine neue native Gesamtqualifikation.
