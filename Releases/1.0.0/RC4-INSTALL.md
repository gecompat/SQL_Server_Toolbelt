# Toolbelt v1.0.0-rc.4 installieren

Lade die `SQL-Server-Toolbelt-v1.0.0-rc.4-Install.zip` und ihre `.sha256` aus
dem [Vorabrelease](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.4).
Prüfe die ZIP-Prüfsumme mit `Get-FileHash -Algorithm SHA256` und entpacke das
Paket vollständig. Die innere Basis-ZIP nicht zusätzlich entpacken.

Öffne im entpackten Hauptverzeichnis PowerShell 7.4+ und wähle einen Aufruf:

```powershell
# Lokal: eigene Anwendungs-/Testdatenbank
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoAppTest -DeploymentMode local -CreateDatabase -EnableClr

# Zentral: eigene Toolbelt-Datenbank derselben Instanz
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central -CreateDatabase -EnableClr
```

Server und Datenbank ausdrücklich ersetzen. Die Beispiele nutzen die integrierte
Identität des aktuellen Prozesses. SQL-Anmeldung innerhalb einer PowerShell-Sitzung:

```powershell
& .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central -CreateDatabase -EnableClr -Credential (Get-Credential)
```

## Vorher erforderlich

- PowerShell 7.4+, **sqlcmd (ODBC)** samt Microsoft-ODBC-Treiber und erlaubte
  Skriptausführung; kein eigener DLL-Build, Repositorycheckout oder weiterer Download.
- Regulärer SQL Server 2019, 2022 oder 2025 unter Windows oder Linux, erreichbar
  mit verschlüsselter Verbindung und regulärer Zertifikatsprüfung. Nur bei einem
  ausdrücklich erlaubten Ziel den Schalter `TrustServerCertificate` ergänzen.
- Vorhandene SQL-Anmeldung mit `CONTROL SERVER` oder `sysadmin`; bei vorhandenem
  Ziel außerdem `CONTROL` auf der Datenbank. Windows-Administratorrechte allein
  reichen nicht. Es werden keine Rechte oder Logins vergeben.
- `clr strict security` konfiguriert/wirksam 1, `lightweight pooling` 0;
  keine fremden vorgemerkten Konfigurationsänderungen.
- Bereits vorhandenes Ziel: leer, online und beschreibbar, CL mindestens 150,
  `TRUSTWORTHY OFF`. Fehlendes Ziel: reguläre sichere leere model-Vorlage sowie
  ausreichende Serverressourcen für die normale Datenbankanlage.

`CreateDatabase` legt nur ein fehlendes Ziel an. `EnableClr` aktiviert bei Bedarf
`clr enabled` für die ganze Instanz. Lässt du die Schalter weg, müssen Datenbank
und CLR wie bisher bereits vorbereitet sein. Bestehende Datenbanken werden nicht
ersetzt, geleert oder repariert; Sicherheitsoptionen bleiben erhalten.

## Ergebnis und Fehler

Der Aufruf prüft Paket, Client, Ziel und Rechte, speichert vor der Vorbereitung
ein privates Journal und führt danach den exakten Assembly-Trust und das passende
Installationsprofil aus. Erwartet: `Status=INSTALLED`, `Profile`, `Modules`
und bei Vorbereitung `PreparationJournal`. Windows lokal umfasst 45, Windows
zentral 43, Portable lokal/zentral 41 Module. `Release=v1.0.0-rc.2` bezeichnet
weiter die unveränderte innere SQL-Basis; `BUNDLE.json` identifiziert rc.4.

Bei Fehlern bleiben Journal und möglicherweise Teiländerungen bestehen.
Kein Gesamtrollback und kein automatischer Wiederholungs-/Upgradeweg; erst
Zielzustand und Journal klären. Für die neue Vorbereitung erläutert die
[Vorbereitungsanleitung](../../Deployment/PROVISIONING.md) Sicherheitsgrenzen,
rein lesenden Vorcheck, Journal und Fehlerkennungen. Die
[vollständige Referenz](../../Deployment/ONE-CALL-INSTALL.md) enthält alle Parameter.

Dies ist ein Entwicklungsvorabrelease für ausgewählte leere Testdatenbanken.
Die [Releasehinweise](RC4.md) trennen die neue Vorbereitung von wiederverwendeten
Modulnachweisen. rc.1 bis rc.3 und deren Originalnachweise bleiben unverändert.
