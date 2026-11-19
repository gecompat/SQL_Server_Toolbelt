# Toolbelt v1.0.0-rc.3 installieren

Lade `SQL-Server-Toolbelt-v1.0.0-rc.3-Install.zip` und seine `.sha256` aus
dem [GitHub-Vorabrelease](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.3).
Vergleiche die ZIP-Prüfsumme mit der SHA256-Datei, beispielsweise:

```powershell
Get-FileHash 'C:\Temp\SQL-Server-Toolbelt-v1.0.0-rc.3-Install.zip' -Algorithm SHA256
```

Entpacke die ZIP vollständig. Öffne im entpackten Verzeichnis PowerShell 7.4+
und führe **genau einen** der folgenden Aufrufe aus:

```powershell
# Lokal: in der vorbereiteten Anwendungs-/Testdatenbank
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoAppTest -DeploymentMode local

# Zentral: in einer eigenen Datenbank derselben SQL-Server-Instanz
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central
```

`localhost` und die Datenbanknamen durch dein ausdrücklich ausgewähltes Ziel
ersetzen. Für SQL-Anmeldung den Aufruf innerhalb einer PowerShell-7.4+-Sitzung
mit einem verdeckt abgefragten Credential ausführen:

```powershell
& .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central -Credential (Get-Credential)
```

Das Paket enthält den geprüften Einstieg und seine vollständige unveränderte
SQL-Basis bereits im richtigen Verzeichnis. Für die Installation sind kein
weiterer Paketdownload, Entpacken der inneren ZIP oder eigener DLL-Build nötig.

## Voraussetzungen und Ergebnis

- Auf dem Client: PowerShell 7.4+ und **sqlcmd (ODBC)** samt Microsoft-ODBC-Treiber.
- Auf dem Server: SQL Server 2019, 2022 oder 2025 unter Windows oder Linux;
  eine bereits angelegte, leere, beschreibbare eigene Testdatenbank mit
  Compatibility Level mindestens 150 und `TRUSTWORTHY OFF`.
- Vorhandene Installationsanmeldung mit `CONTROL SERVER` oder `sysadmin`
  sowie `CONTROL` auf der Zieldatenbank.
- Wirksam `clr enabled=1`, `clr strict security=1`, `lightweight pooling=0`.
  Der Installer legt weder die Datenbank noch Rechte an und ändert keine
  Serverkonfiguration. Die Administration bereitet diese Voraussetzungen vor.

Der Aufruf prüft Paket und Ziel, wählt Windows/Portable anhand des SQL Servers,
bereitet den exakten Assembly-Trust vor und installiert das gewählte lokale
oder zentrale Profil. Verschlüsselung bleibt erforderlich; ein etwaiger
`TrustServerCertificate`-Override muss ausdrücklich erlaubt und angegeben sein.

Erwartet wird `Status=INSTALLED` mit Profil und Modulanzahl: Windows lokal 45,
Windows zentral 43, Portable lokal/zentral 41. Das Feld `Release=v1.0.0-rc.2`
bezeichnet weiterhin die unveränderte SQL-Basis; `BUNDLE.json` identifiziert
die neue **rc.3-Lieferung** samt integriertem Einstieg.

Die [vollständige Anleitung](../../Deployment/ONE-CALL-INSTALL.md) erklärt alle
Parameter, Profile und Fehlerkennungen. Bei einem Fehler nach Installationsbeginn
können bereits installierte Module und Trusteinträge bestehen bleiben. Es gibt
keinen Gesamtrollback oder automatischen Wiederholungs-/Upgradeweg.
Vor einem neuen bewussten Aufruf den Zielzustand klären.

## Inhalt und Nachweisgrenze

`SHA256SUMS` prüft die entpackten Lieferdateien; die äußere ZIP-Prüfsumme muss
zuvor stimmen. `BUNDLE.json` bindet Quellcommit, Einstieg, innere Basis-ZIP und
Originalnachweis. Der Einstieg und die Basis-ZIP sind bytegleich zu den
[zwölf nativen Installationsprofilen](../../Deployment/Tests/Qualification/OneCallInstaller.20261119.json)
mit sechs frischen Abschlussaudits. Die neue Paketierung ergänzt ausschließlich
Offline-Prüfungen, keine neuen SQL-/TLS-/GUI-Läufe und keine Modul-Supportfreigabe.

Dies ist ein Entwicklungsvorabrelease für leere ausgewählte Testdatenbanken.
Die [Releasehinweise](RC3.md) grenzen Originalnachweise und neue Paketlieferung ab.
Lizenz und Drittanbieterhinweise sind mitgeliefert; die Originalpakete bleiben erhalten.
