# Zieldatenbank und CLR mit dem Installer vorbereiten

Der neue Ein-Aufruf-Installer kann mit zwei ausdrücklich gewählten Schaltern
auch die Voraussetzungen einer leeren Neuinstallation vorbereiten:

```powershell
pwsh -File .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central -CreateDatabase -EnableClr
```

Für lokale Installation `-DeploymentMode local` und die vorgesehene eigene
Anwendungs-/Testdatenbank angeben. Der vollständige Installationssatz muss
entpackt vorliegen; PowerShell 7.4+, sqlcmd **ODBC**, Treiber, Erreichbarkeit
und eine vorhandene SQL-Installationsanmeldung bleiben erforderlich.
Ohne `Credential` gilt die integrierte Identität des aktuellen Prozesses.
Für SQL-Anmeldung innerhalb von PowerShell stattdessen aufrufen:

```powershell
& .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database Toolbelt -DeploymentMode central -CreateDatabase -EnableClr -Credential (Get-Credential)
```

## Wirkung und Voraussetzungen

| Eingabe | Wirkung |
|---|---|
| `CreateDatabase` | Standard aus. Legt ausschließlich eine fehlende ausdrücklich benannte Benutzerdatenbank mit den regulären Server-/model-Defaults an. Keine Dateipfade, Größen- oder Collationvorgaben. Eine vorhandene geeignete leere Datenbank wird verwendet; bestehende Datenbanken werden niemals ersetzt oder geleert. |
| `EnableClr` | Standard aus. Aktiviert ausschließlich `clr enabled`, falls noch deaktiviert. Die Änderung gilt für die ganze Instanz und bleibt nach erfolgreicher Installation wirksam. Bereits aktives CLR führt zu keiner Konfigurationsänderung. |
| `PreflightOnly` | Mit diesen Schaltern nur lesende Vorbereitungsprüfung. Auch bei fehlender Datenbank wird nichts angelegt oder aktiviert. Ergebnis `PREPARATION_PREFLIGHT_OK` bestätigt den Vorbereitungsplan, keine ausgeführte Installation. |
| `ValidateOnly` | Weiterhin ausschließlich Offline-Paketprüfung, auch mit den beiden Schaltern. |

Erforderlich bleiben `CONTROL SERVER` oder `sysadmin`, auf einem vorhandenen
Ziel außerdem `CONTROL`. Es werden keine Rechte oder Logins vergeben.
`clr strict security` muss konfiguriert und wirksam 1, `lightweight pooling`
konfiguriert und wirksam 0 sein. Andernfalls wird abgebrochen. Systemdatenbanken,
nicht leere oder ungeeignete Ziele sowie kontaminierte/ungeeignete model-Vorlagen
werden zurückgewiesen. Die neu entstandene Datenbank muss CL mindestens 150,
`TRUSTWORTHY OFF`, Online- und Schreibzustand aufweisen. Es gibt keine automatische
Reparatur fremder Datenbanken, Neustarts oder `RECONFIGURE WITH OVERRIDE`.

## Ablauf, Journal und Fehler

1. Paket und Client prüfen, anschließend Rechte, Sicherheitszustand, Ziel und
   sämtliche konfigurierten/wirksamen Serveroptionen lesend aus `master` erfassen.
   Vorgemerkte Änderungen blockieren die Vorbereitung. Die dokumentierten
   Normalisierungen der beiden Speicheroptionen gelten nicht als Pending-Änderung.
2. Vor Mutationen einen privaten lokalen Snapshot unter dem Benutzerprofil in
   `SQL_Server_Toolbelt/InstallJournals/<Lauf-ID>/preparation.json` speichern.
   Unter Windows besitzt das neue Laufverzeichnis eine explizite Benutzer-ACL,
   unter Unix Modus 0700. Dateisystemumleitungen werden zurückgewiesen.
   Zielnamen und Konfigurationswerte bleiben lokal; keine Credentials oder
   Connection Strings. Der Pfad wird beim Start ausgegeben.
3. In einer frischen Sitzung aus `master` eine kooperative instanzweite
   Vorbereitungssperre nehmen und den exakten Snapshot erneut vergleichen.
   Danach gegebenenfalls die fehlende Datenbank anlegen und CLR aktivieren.
   Unmittelbar vor `RECONFIGURE` dürfen nur die eigenen CLR-Werte vorgemerkt sein.
   `show advanced options` bleibt unverändert.
4. Zielidentität und übrige Konfigurationswerte prüfen; anschließend durchlaufen
   die gebundenen SQL-Paketbytes den gewählten Trust-/Installationsweg mit
   erneuter Zielidentitätsprüfung und markerfreier Schnittstellenprüfung.

Beliebige gleichzeitige Administratoraktionen werden durch die kooperative
Sperre nicht ausgeschlossen. Das Ziel und die Instanz müssen während des
Aufrufs administrativ stabil bleiben. Ein erkannter Wechsel bricht ab.
Verschlüsselung und der ausdrückliche Zertifikatsprüfungs-Override behalten
ihren bisherigen Vertrag. Der Assembly-Trust bleibt an exakte Paket-Hashes gebunden.

`Status=INSTALLED_OR_PRESENT` bestätigt, dass die erwarteten Schnittstellen
und Assemblies vorhanden sind. Die Bestätigung bezieht sich auf den Bestand
nach einem Create-only-Lauf. `PreparationJournal` nennt das
aufbewahrte Journal. Dieses dokumentiert den Vorzustand und den bestätigten
Vorbereitungsabschluss. Bei Prozessverlust bleibt der Ausgang ausdrücklich
unbekannt. Es gibt **keinen Gesamtrollback**: Eine angelegte Datenbank, aktiviertes
CLR sowie bereits installierte Module/Trust können nach Fehlern bestehen bleiben.
Weder Datenbanken noch Serverkonfiguration werden dann ungeprüft zurückgesetzt.
Vor einem weiteren bewussten Aufruf Journal und tatsächlichen Zielzustand klären.
Journale nicht unverändert in öffentliche Fehlerberichte übernehmen.

| Fehler | Nächster Schritt |
|---|---|
| `TBX_DATABASE_MISSING` | Ziel anlegen oder `CreateDatabase` ausdrücklich wählen. |
| `TBX_CLR` | CLR administrativ vorbereiten oder `EnableClr` ausdrücklich wählen. |
| `TBX_PENDING_CONFIGURATION` | Vorgemerkte Änderungen administrativ klären; nichts automatisch aktivieren. |
| `TBX_PREPARATION_DRIFT`, `TBX_TARGET_CHANGED` | Parallelität/Zielwechsel klären, Journal und Teilzustand prüfen. |
| `TBX_MODEL` | model-Vorlage administrativ prüfen; keine fremden Inhalte automatisch entfernen. |
| `TBX_SECURITY`, `TBX_DATABASE_STATE`, `TBX_NOT_EMPTY` | Sichere Instanz und geeignetes leeres Ziel bereitstellen. |
| `JOURNAL`, `RECEIPT`, `TIMEOUT`, `SQL_FAILED` | Lokalen Journalzugriff beziehungsweise tatsächlichen Teilzustand prüfen; keine automatische Wiederholung. |

Die [vollständige Installationsreferenz](ONE-CALL-INSTALL.md) beschreibt die
übrigen Parameter und Profilgrenzen. Technische Grundlagen:
[Microsoft CLR-Aktivierung](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/clr-enabled-server-configuration-option)
und [CREATE DATABASE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-database-transact-sql).
