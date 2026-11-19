# Toolbelt mit einem Aufruf installieren

Der [PowerShell-Einstieg](Install-Toolbelt.ps1) installiert den unveränderten
[rc.2-Installer](https://github.com/gecompat/SQL_Server_Toolbelt/releases/tag/v1.0.0-rc.2).
Er übernimmt Paketprüfung, lesende Zielvorprüfung, Plattformauswahl,
Assembly-Trust und Installation. Der manuelle [SSMS-Weg](../INSTALL.md) bleibt
für Anwender ohne PowerShell-/sqlcmd-Client verfügbar. Bestehende rc.2-Assets
und ihre ursprünglichen Nachweise werden nicht verändert.
Die zusätzliche `.ps1` wird aus diesem Repository heruntergeladen; sie ist
kein Bestandteil des eingefrorenen rc.2-ZIP.

## Einmal vorbereiten und aufrufen

Auf dem Client müssen PowerShell 7.4+ und **sqlcmd (ODBC)** mit dem zugehörigen
Microsoft-ODBC-Treiber installiert sein. sqlcmd (Go) wird ausdrücklich
zurückgewiesen. Lade `Install-Toolbelt.ps1` über dessen GitHub-Dateiseite/Raw
herunter oder verwende den Repositorycheckout. Ein eigener DLL-Build ist nicht
nötig. Skriptausführung muss durch deine lokale Richtlinie erlaubt sein.

Lokal, mit integrierter Anmeldung:

```powershell
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoAppTest -DeploymentMode local
```

Zentral, in einer eigenen Datenbank derselben SQL-Server-Instanz:

```powershell
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central
```

Die Beispiele verwenden den Repositorypfad. Bei einzeln heruntergeladenem
Skript lautet der Pfad beispielsweise `./Install-Toolbelt.ps1`.
Ohne lokalen Paketsatz lädt der Einstieg automatisch die **fest gebundene**
Installer-ZIP aus v1.0.0-rc.2. Es gibt kein automatisches „latest“-Update.
Im Checkout verwendet er die identischen versionierten Lieferbytes.

SQL-Anmeldung innerhalb einer PowerShell-7.4+-Sitzung:

```powershell
& .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central -Credential (Get-Credential)
```

Das Kennwort wird verdeckt abgefragt und ausschließlich im Environment des
jeweiligen sqlcmd-Kindprozesses übergeben. Es erscheint weder in Prozessargumenten
noch SQL-Dateien. Ohne `Credential` gilt ausschließlich die integrierte Anmeldung
des aktuellen Prozesses; eine geerbte `SQLCMDPASSWORD`-Variable wählt keine
andere Identität. Die Elternumgebung bleibt unverändert.

Bei SQL-Anmeldung wird `-X1` bewusst nicht verwendet: Diese sqlcmd-Option
unterdrückt auch die Kennwort-Umgebungsvariable. Stattdessen werden
`SQLCMDINI` und andere geerbte sqlcmd-Einstellungen im Kindprozess entfernt,
SQLCMD-Variablensubstitution wird durch `-x` gesperrt und ausschließlich die
gebundenen Skripte samt korrekt gequoteten Zieleingaben ausgeführt. Bei
integrierter Anmeldung bleibt `-X1` zusätzlich aktiv.

## Was auf dem Server vorhanden sein muss

- Eine reguläre SQL-Server-Instanz 2019, 2022 oder 2025 unter Windows/Linux.
- Eine ausdrücklich ausgewählte, **bereits angelegte leere Datenbank**, online
  und beschreibbar, Compatibility Level mindestens 150, `TRUSTWORTHY OFF`.
  Systemdatenbanken sowie bestehende Toolbelt-/Fachobjekte sind ausgeschlossen.
- Vorhandenes `CONTROL SERVER` oder `sysadmin` für den Trustschritt sowie
  `CONTROL` auf der Zieldatenbank. Windows-Administratorrechte allein reichen
  nicht; der Einstieg benötigt keine automatische Windows-Erhöhung.
- Wirksam `clr enabled=1`, `clr strict security=1`, `lightweight pooling=0`.
  Die Administration bereitet dies vor; der Einstieg führt kein `RECONFIGURE`
  aus und vergibt keine Rechte oder Logins.
- Die Datenbank muss während der Installation exklusiv für diesen Zweck
  verfügbar sein. Die Session-AppLock koordiniert weitere Aufrufe dieses
  Einstiegs, ersetzt aber keine Sperre gegen beliebige Administratoraktionen.

Der SQL Server bestimmt das Profil, nicht das Betriebssystem des Clients:

| Server | lokal | zentral |
|---|---|---|
| Windows | Windows-local, 45 Module | Windows-central, 43 Module |
| Linux | Portable-local, 41 Module | Portable-central, 41 Module |

Die [Profilgrenzen](../INSTALL.md#1-lokal-oder-zentral-und-das-passende-profil-wählen)
gelten unverändert. Die Installation erzeugt keine Cross-DB-Benutzerzuordnung,
Anwendungsrechte, Dateirechte, Roots oder Workerregistrierung.

## Ablauf und Fehlerverhalten

1. Die genaue äußere rc.2-SHA256-Prüfsumme wird geprüft, anschließend sämtliche
   Manifestdateien. Das Paket wird nicht beliebig in das Dateisystem entpackt.
   Es gibt weder Paketwechsel noch Netzwerkfallback nach einem Hashfehler.
2. Ein lesender SQL-Aufruf prüft Ziel, Version, Plattform, vorhandene Rechte,
   Datenbankzustand, CLR und Sicherheitszustand. Er verändert noch keinen Trust.
3. Eine zweite frische sqlcmd-Sitzung nimmt die Session-AppLock, prüft
   Datenbank-GUID/Plattform und alle Voraussetzungen erneut. Erst danach laufen
   das originale plattformpassende `Trust-*.sql` und `Install-*.sql`. Nach dem
   Trustschritt in `master` wird ausdrücklich zur ausgewählten Datenbank gewechselt.
4. Der Abschluss prüft für jedes ausgewählte Modul dessen Versionsmarker und
   soweit im bestehenden Modulvertrag vorhanden den Deployment-Modus.
   `INSTALLED` erscheint nur bei Exitcode 0 und eindeutigem Abschlussnachweis.

Die Verbindung bleibt verschlüsselt. Zertifikatsprüfung wird nur durch den
ausdrücklichen Schalter `TrustServerCertificate` übergangen, niemals nach einem
Fehler automatisch. Das Paket benötigt kein eigenes TLS-Zertifikat.

Der Trustschritt registriert ausschließlich die gebundenen Assemblyhashes,
soweit sie fehlen. Vorhandene Einträge werden nicht überschrieben. Die Module
behalten ihre eigenen Transaktionen: Es gibt **keinen Gesamtrollback**.
Bei späterem Fehler oder Abbruch können frühere Module und Trusteinträge
bestehen bleiben. Der Einstieg entfernt sie nicht pauschal und wiederholt
nichts automatisch. Zielzustand vor einem weiteren bewussten Aufruf prüfen.
Mit dem üblichen PowerShell-Schalter `-Verbose` werden zusätzlich begrenzte
SQL-Clientfehlerdetails angezeigt. Ein ausdrücklich übergebenes SQL-Kennwort
wird zuvor aus Fehlerausgaben entfernt. Solche lokalen Diagnosen können
Zielnamen enthalten und gehören nicht unverändert in öffentliche Fehlerberichte.

| Kennung | Bedeutung und nächster Schritt |
|---|---|
| `PACKAGE`, `DOWNLOAD` | Originale rc.2-ZIP bereitstellen; Paketquelle und Prüfsumme prüfen. |
| `CLIENT`, `CLIENT_START` | PowerShell 7.4+, sqlcmd (ODBC), Treiber, Toolpfad und Client-Ausführungsrechte prüfen. |
| `TARGET`, `TBX_TARGET` | Ausdrückliche eigene Zieldatenbank wählen. |
| `TBX_SERVER_RIGHTS`, `TBX_DATABASE_RIGHTS` | Bereits berechtigte Installationsanmeldung verwenden. |
| `TBX_VERSION`, `TBX_PLATFORM` | Unterstützte Engine/Plattform auswählen. |
| `TBX_DATABASE_STATE`, `TBX_NOT_EMPTY` | Leeres, geeignetes Fresh-Install-Ziel bereitstellen; kein pauschaler Upgradeweg. |
| `TBX_CLR`, `TBX_SECURITY` | Administration bereitet CLR/Sicherheitszustand vor. |
| `TBX_LOCK`, `TBX_TARGET_CHANGED`, `PROBE` | Parallelität oder Zieländerung klären; keine automatische Wiederholung. |
| `TBX_RECEIPT`, `RECEIPT` | Installation nicht als vollständig behandeln; Marker/Clientabschluss prüfen. |
| `SQL_FAILED`, `TIMEOUT` | Angegebene Phase, Anmeldung, Netzwerk, Zertifikatsprüfung bzw. SQL-Fehler im Ziel prüfen. Vor Wiederholung möglichen Teilzustand klären. |

## Alle Eingaben

| Parameter | Vertrag |
|---|---|
| `DeploymentMode` | Pflicht; genau die kleingeschriebenen Werte `local` oder `central`. Kein Standardmodus. |
| `ServerInstance` | Pflicht außer bei `ValidateOnly`; Ziel im sqlcmd-Serverformat, z. B. `localhost`. Keine Steuerzeichen. |
| `Database` | Pflicht außer bei `ValidateOnly`; 1–128 Zeichen, nicht leer, keine Steuerzeichen. Genaue Schreibweise des vorhandenen Datenbanknamens verwenden; die Zielbindung vergleicht binär. Bezeichner und SQL-Literal werden getrennt gequotet. |
| `Credential` | Optionales `PSCredential` für SQL-Anmeldung; ohne Wert integrierte Anmeldung. Kein Klartextkennwortparameter. |
| `PackageZip` | Optionaler Pfad zur unveränderten rc.2-Installer-ZIP. Expliziter ungültiger Pfad/Hash stoppt; kein Downloadersatz. Ohne Wert Checkout-ZIP oder fester Release-Download mit 120-s-Grenze. |
| `SqlcmdPath` | Standard `sqlcmd`; expliziter Anwendungspfad möglich. Genau ein Tool wird gewählt; kein Providerfallback. |
| `TrustServerCertificate` | Standard aus; ausdrücklicher Zertifikatsprüfungs-Override für entsprechend erlaubte Ziele. |
| `ValidateOnly` | Nur Paket prüfen, keine sqlcmd-/SQL-Ausführung. Modus muss trotzdem angegeben werden. |
| `PreflightOnly` | Paket und SQL-Ziel lesend prüfen, ohne Trust/Installation. Nicht mit `ValidateOnly` kombinierbar. |
| `LoginTimeoutSeconds` | Standard 60; ganze Zahl 1–120. |
| `CommandTimeoutSeconds` | Standard 600; ganze Zahl 1–1800. Begrenzung pro sqlcmd-Abfrage, zusätzlich harte Kindprozessgrenze aus Login- plus Commandtimeout plus 10 Sekunden. |

Ein reiner Vorcheck lautet beispielsweise:

```powershell
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central -PreflightOnly
```

## Nachweis und Pflege

Die [SQL-freien Gegenproben](Tests/Test-OneCallInstall.ps1) testen den gesamten
Clientablauf mit synthetischen Antworten sowie echte Kindprozess-Startfehler,
Timeout und Exitcodes. Der bestehende Deployment-CI-Impact führt sie über
`Test-SqlExport.ps1` aus; eine zweite vollständige Release-Suite ist dafür
nicht nötig. Diese Prüfungen sind kein nativer SQL-Installationsnachweis.
Der originale [Installationsnachweis](../Releases/1.0.0/CURRENT-INSTALL-QUALIFICATION.md)
behält ausschließlich seinen gebundenen Scope. Neue native Ergebnisse des
Komforteinstiegs sind im [separaten Bericht](Tests/Qualification/OneCallInstaller.20261119.json)
an die aktuellen Client-/Harnessquellen und die unveränderte rc.2-ZIP gebunden:
zwölf Profile auf den sechs schema-validierten Labzielen für Windows/Linux,
SQL2019/CL150, SQL2022/CL160 und SQL2025/CL170; sechs frische unabhängige
Cleanup-Audits PASS. Der [native Adapter](Tests/Invoke-OneCallInstallLab.ps1)
verwendet die bestehenden Identitäts-, Verbraucher- und Wiederherstellungsprüfungen.

Die native Matrix verwendete ausdrücklich SQL-Anmeldung mit `Credential` von
einem Windows-Client. Integrierte Anmeldung ist durch die SQL-freien
Argument-/Environment-Gegenproben abgedeckt, nicht durch einen neuen nativen
Windows-Anmeldenachweis. Für eindeutige Cleanup-Ownership bereitete das
Testsetup seine exakten Trusteinträge mit eigenen Markern vor; der Produktlauf
führte das unveränderte Trustskript gegen diese vorhandenen Einträge aus.
Dessen Neueintragungssemantik wird aus den ursprünglichen Trust-/Installations-
nachweisen wiederverwendet. Keine neue TLS-, GUI- oder Modulgesamtqualifikation.

Zwei frühere Fehler bleiben erhalten: ein Adapterdatumfehler vor SQL sowie
ein SQL-Anmeldefehler durch `-X1`, anschließend FAILED_CLEANED und frischer
Audit PASS. Der gemeinsame Rahmen endete mit 16/20 Dispatches und 16/20
DB-Reservierungen; tatsächlich wurden einschließlich Fehllauf 13 eigene
Datenbanken angelegt und frisch auditiert entfernt. Die ursprüngliche Frist
wurde nicht erneuert. Restplätze eröffnen keine weitere Testwelle.

Der Auftrag vom 19. November 2026 umfasst diesen Clientadapter einschließlich
Vorprüfung und Trust-Vorbereitung, keine neuen fachlichen SQL-Objekte.
Die Alternative, den manuellen Ablauf nur zu dokumentieren, würde weiterhin
mehrere Ausführungsschritte verlangen. Der vorhandene CLR-Maintenance-Runner
verwendet einen anderen Paket-/Lifecyclevertrag und wird nicht auf rc.2 umgedeutet.
Die veröffentlichten ZIPs und ihre historischen Nachweise bleiben unverändert.

Technische Referenzen: [Microsoft sqlcmd](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility)
und [Assembly-Trust/Rechte](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-add-trusted-assembly-transact-sql).
