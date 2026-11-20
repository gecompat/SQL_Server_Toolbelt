# Toolbelt installieren und verwenden

Der aktuelle Quellstand verwendet normale SQL-Dateien ohne SQLCMD-Modus,
Toolbelt-Deploymenttabellen oder Extended Properties. Für den PowerShell-Weg
übernimmt der gemeinsame Client Paketprüfung, Zielvorprüfung und den gewählten
Trustweg. Die veröffentlichten Vorabreleases bis rc.4 bleiben eigenständige
historische Lieferungen und enthalten ihre ursprünglichen Installer.

## Lokal oder zentral wählen

Lokal liegen die Objekte in der Anwendungsdatenbank. Zentral liegen sie in einer
eigenen Datenbank derselben Instanz; der Aufruf erfolgt mit dreiteiligen Namen.
Zentraler Aufruf erteilt keine Rechte und überwindet keine Datenbankgrenzen.

| SQL-Server-Plattform | Lokal | Zentral |
|---|---|---|
| Windows | 45 Module | 43 Module |
| Portable, auch Linux | 41 Module | 41 Module |

Portable enthält keine Windows-Dateisystem-/ZIP-Dateifassaden, keinen
Scriptparser und kein SSIS-Debug. Zentral auf Windows entfallen die beiden
lokal gebundenen Dateifassaden. Einzelmodule und ihre Pflichtabhängigkeiten
können über denselben [Buildkern](Scripts/Install/README.md) gewählt werden.

## Mit einem Aufruf installieren

Den aktuellen gebauten Installationssatz vollständig entpacken. Im Paketroot:

```powershell
# Lokal
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoApp -DeploymentMode local

# Zentral, fehlende Datenbank und CLR ausdrücklich vorbereiten
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoToolbelt -DeploymentMode central -CreateDatabase -EnableClr
```

PowerShell 7.4+ und ODBC-sqlcmd sind erforderlich. Ohne Credential gilt die
integrierte Prozessidentität; SQL-Anmeldung erfolgt mit `-Credential
(Get-Credential)`. Der Client lädt keinen älteren Satz automatisch nach.
Im Quellcheckout alternativ eine aktuelle SQL-Datei mit ihrer Manifestdatei
über `-InstallSql` angeben. Vollständige Parameter und Fehlerbehandlung:
[Ein-Aufruf-Installer](Deployment/ONE-CALL-INSTALL.md).

## Direkt in SSMS installieren

Eine [aktuelle SQL-Datei bauen](Scripts/Install/README.md), vollständig öffnen,
ausschließlich die erste `USE [ContosoToolbelt];`-Zeile anpassen und als normale
Abfrage ausführen. Kein SQLCMD-Modus, keine separaten Variablen oder DLL-Pfade.
Für DTSX allein gibt es den [kleineren Funktionssatz](Modules/toolbelt.tsql.ssis-debug/Documentation/SimpleInstallation.md).

## Voraussetzungen und Trust

SQL Server 2019 oder neuer, Compatibility Level mindestens 150, eine online
schreibbare Zieldatenbank und die für die ausgeführten Objekte erforderlichen
vorhandenen Rechte. CLR-Module benötigen aktiviertes CLR und unveränderte
Strict Security. Windows-Funktionen behalten ihre Plattform-/Dateirechte.

| Trustweg | Verhalten |
|---|---|
| auto | Vorhandenes TRUSTWORTHY ON nutzen; sonst exakte Hashfreigabe |
| hash | Erwartete Assemblybytes vergleichen und deren Hashes registrieren |
| trustworthy-checked | Vorhandenen DB-Trust nutzen, Assemblybytes vergleichen, keine Hashregistrierung |
| trustworthy | Vorhandenen DB-Trust ohne Toolbelt-Hashvergleich nutzen |

Der Installer aktiviert TRUSTWORTHY nicht, ändert keinen Owner und vergibt keine
Rechte. Die Engine verlangt die notwendigen CREATE-/Assemblyrechte; Hashfreigabe
benötigt entsprechende Serverrechte. Die DB-Trustwege benötigen einen passend
autorisierten Owner. Eine pauschale sysadmin-Bedingung gilt nicht für reine
Objekterstellung. Die administrativen Opt-ins CreateDatabase/EnableClr behalten
ihre [strengeren Vorbereitungsgrenzen](Deployment/PROVISIONING.md).
Zertifikatsprüfung bleibt Standard; ein ausdrückliches TrustServerCertificate
ist keine authentifizierte TLS-Abnahme. Fehler lösen keinen Trust-Fallback aus.

## Nach Installation

Die Installation ist create-only: vorhandene Objekte werden nicht aktualisiert
oder gelöscht. Der Abschluss bestätigt erwartete Namen/Typen, keine Version
oder Definition bereits bestehender Objekte. Nach Fehlern können Teilobjekte
bestehen bleiben; Ziel prüfen, bevor bewusst erneut ausgeführt wird.

Objektaufrufe und Rechte stehen im [Funktionskatalog](Documentation/README.md)
und in den jeweiligen Modulanleitungen. Der [Deploymentvertrag](Documentation/Architecture/DEPLOYMENT_MODEL.md)
erklärt Cross-Database-Grenzen. Historische Release-/Installationsanleitungen
bleiben im [Vorgängerstand](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2fbe8e3e86f370b22ad2ce9f9716d971072a052b/INSTALL.md) erhalten und qualifizieren den
aktuellen Satz nicht automatisch. Ein gebauter Satz ist noch keine Veröffentlichung.
