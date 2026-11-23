# Toolbelt installieren und verwenden

## Paket oder Quellbuild wählen

| Ausgangspunkt | Vorgehen |
|---|---|
| Entpackter aktueller Installationssatz | Den mitgelieferten PowerShell-Client oder eine der vier vollständigen SQL-Dateien verwenden. Lizenz, Manifest und Prüfsumme beim Paket behalten. |
| Aktueller Repository-Checkout | Den [Installationssatz aus einem festgeschriebenen Commit bauen](Scripts/Install/README.md#installationssatz-aus-festgeschriebenen-quellen-bauen). Für einen Teilinstaller die Module vor dem Build auswählen. |
| Öffentliches Vorabpaket | Client und Anleitung aus genau diesem Paket verwenden. Das zuletzt veröffentlichte Vorabpaket ist [v1.0.0-rc.4](Releases/1.0.0/RC4-INSTALL.md). |

Der aktuelle gemeinsame Installer wird aus dem aktuellen Quellstand gebaut.
Seine SQL-Dateien laufen als normale Abfragen ohne SQLCMD-Modus. Der optionale
PowerShell-Client übernimmt Paketprüfung, Zielvorprüfung und Assembly-Trust.

Die Prüfsumme des äußeren ZIP lässt sich mit
`Get-FileHash -Algorithm SHA256 -LiteralPath .\Toolbelt-Install.zip` berechnen.
Vergleiche sie mit dem erwarteten Wert aus einer vertrauenswürdigen Quelle.

## Lokal oder zentral wählen

Lokal liegen die Objekte in der Anwendungsdatenbank. Zentral liegen sie in
einer eigenen Datenbank derselben SQL-Server-Instanz. Der Aufruf erfolgt dann
mit dreiteiligen Namen, soweit der Objektvertrag dies für den konkreten Einsatz
vorsieht.

| Profil | Lokal | Zentral |
|---|---:|---:|
| Windows | 45 Module | 43 Module |
| Portable, auch für Linux | 41 Module | 41 Module |

Das Portable-Profil enthält weder Windows-Dateisystem noch ZIP-Dateifassaden,
T-SQL-Scriptparser oder SSIS-Debug. Im zentralen Windows-Profil entfallen die
beiden lokal gebundenen Module Windows-Filesystem und ZIP-Dateifassaden.
Table Clone ist im Portable-Profil verfügbar. Für die Triggerübernahme wird
zusätzlich der Scriptparser auf Windows benötigt.

Der Client wählt das Profil anhand des SQL-Ziels. `-Platform Portable` kann auch
für eine Windows-Instanz gewählt werden. Ein Teilinstaller enthält die
ausgewählten Module und deren Pflichtabhängigkeiten.

## Voraussetzungen und Trust

- SQL Server 2019, 2022 oder 2025 und Compatibility Level ab 150. Die
  Objektseite nennt zusätzliche Voraussetzungen für die jeweilige Funktion.
- Eine erreichbare Instanz und online schreibbare Zieldatenbank. Die Anmeldung
  muss die notwendigen Schema-, CREATE- und gegebenenfalls Assembly- und
  Serverrechte besitzen. Die Installation vergibt keine Rechte.
- Für CLR-Module aktiviertes CLR und deaktiviertes Lightweight Pooling.
  Ein reiner T-SQL-Teilinstaller benötigt kein CLR. Windows-Dateizugriffe
  brauchen zusätzlich die Rechte für die gewählte Identität und den Root.

Die TLS-Zertifikatsprüfung der **Verbindung** und der **Assembly-Trust** in
SQL Server sind getrennte Einstellungen. Der PowerShell-Client verlangt
verschlüsselten Transport und prüft Servername und Zertifikatskette.
`-TrustServerCertificate` überspringt diese Identitätsprüfung. Die Verbindung
bleibt verschlüsselt. Es gibt keinen automatischen Trust-Fallback.

| Assembly-Trustweg | Wann und wie er wirkt |
|---|---|
| `auto` | Standard. Bei vorhandenem `TRUSTWORTHY ON` wählt er `trustworthy`. Andernfalls wählt er `hash`. |
| `hash` | Prüft die eingebetteten Assemblybytes und registriert genau deren Hashes. Die Anmeldung braucht dafür passende Serverrechte. |
| `trustworthy-checked` | Nutzt vorhandenes `TRUSTWORTHY ON` und vergleicht die Assemblybytes. Es werden keine Hashes registriert. |
| `trustworthy` | Nutzt vorhandenes `TRUSTWORTHY ON` ohne Toolbelt-Hashvergleich und ohne Hashregistrierung. |

DB-Trustwege setzen die erforderliche Ownerautorisierung voraus. Der Installer
aktiviert `TRUSTWORTHY` nicht und ändert keinen Datenbankowner. Eine pauschale
`sysadmin`-Voraussetzung gilt für die reine Objekterstellung nicht. Bei bereits
deaktivierter CLR Strict Security verlangt der PowerShell-Client eine vorhandene
Datenbank mit `TRUSTWORTHY ON` und einen fest gewählten DB-Trustweg.
`auto`, `hash` und die optionale administrative Vorbereitung erfordern aktive
Strict Security. Die vollständigen Regeln stehen im
[Clientvertrag](Deployment/ONE-CALL-INSTALL.md#plattform-rechte-und-trust).

## Mit einem Aufruf installieren

Im vollständig entpackten Paketroot mit PowerShell 7.4 oder neuer und
ODBC-`sqlcmd` arbeiten. Die Beispiele verwenden die integrierte
Prozessidentität. Für SQL-Anmeldung `-Credential (Get-Credential)` ergänzen.

```powershell
# Lokal in einer vorhandenen Anwendungsdatenbank
& .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoApp -DeploymentMode local

# Zentral mit ausdrücklicher Vorbereitung und Hash-Trust
& .\Deployment\Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoToolbelt -DeploymentMode central -CreateDatabase -EnableClr -TrustMethod hash
```

`-CreateDatabase` legt nur ein fehlendes benanntes Ziel an. `-EnableClr`
aktiviert CLR instanzweit. Für beide Optionen gelten stärkere Rechte und
Zielvoraussetzungen. Bei vorhandener Datenbank und aktivem CLR die Schalter
weglassen. [Administrative Vorbereitung](Deployment/PROVISIONING.md)

Mit `-ValidateOnly` das Paket offline prüfen. `-PreflightOnly` prüft das Ziel
lesend und führt die Vorbereitung nicht aus. Für ein aus Quellen gebautes
Einzelprofil `-InstallSql` und die passende `.manifest.json` verwenden.
Für ein ausgewähltes inneres Payload-ZIP gibt es `-PackageZip`.
[Vollständige Clientparameter](Deployment/ONE-CALL-INSTALL.md)

## Direkt in SSMS installieren

1. Die passende `Install-<Profil>-<Modus>.sql` aus dem entpackten Satz wählen
   oder [mit dem gewünschten Trustweg bauen](Scripts/Install/README.md#datei-bauen).
2. Die Zieldatenbank und gegebenenfalls CLR vorab bereitstellen. Die SQL-Datei
   übernimmt die optionalen administrativen PowerShell-Schritte nicht.
3. In SSMS mit der vorgesehenen Instanz verbinden. Die gesamte Datei öffnen,
   nur die erste `USE`-Zeile auf den Datenbanknamen ändern und als normale
   Abfrage ausführen. Die `GO`-Batchgrenzen bleiben erhalten. Die Datei enthält
   die Assemblies. Ein separater DLL-Pfad ist nicht erforderlich.

Für DTSX allein gibt es den
[kleineren Funktionssatz](Modules/toolbelt.tsql.ssis-debug/Documentation/SimpleInstallation.md).

## Nach Installation

Der Client meldet `INSTALLED_OR_PRESENT`, wenn erwartete Objekte und Assemblies
vorhanden sind. Vorhandene SQL-Definitionen bleiben erhalten. Die Meldung
bestätigt daher keine Versionsnummer bereits vorhandener Objekte. Notiere den
verwendeten Satz und prüfe das benötigte Objekt mit der vorgesehenen Anmeldung.

Beispiel für Generate Series in der lokalen Installationsdatenbank:

```sql
SELECT Value
FROM toolbelt_core.TVF_GenerateSeriesBigInt(1, 3, 1)
ORDER BY Value;
```

Das Ergebnis sind drei Zeilen mit den Werten 1, 2 und 3. Details stehen im
[Objektvertrag](Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigInt.md).

## Zentrale Objekte aufrufen

In einer anderen Datenbank derselben Instanz den Namen der zentralen Datenbank
voranstellen. Beispiel für `ContosoToolbelt`:

```sql
SELECT Value
FROM [ContosoToolbelt].toolbelt_core.TVF_GenerateSeriesBigInt(1, 3, 1)
ORDER BY Value;

SELECT SchemaName, ObjectName, Description
FROM [ContosoToolbelt].toolbelt_metadata.VW_ObjectUsageSkills
WHERE IsInternal = 0
ORDER BY SchemaName, ObjectName;
```

Die Anmeldung benötigt Zugriff auf die zentrale Datenbank und einen dort
berechtigten Benutzer. Für die gezeigten Objekte ist objektbezogenes `SELECT`
erforderlich, für Prozeduren normalerweise `EXECUTE`. Rechte auf Anwendungsdaten,
Zieltabellen oder Dateiroots ergeben sich aus dem jeweiligen Objektvertrag.
Der [Deploymentvertrag](Documentation/Architecture/DEPLOYMENT_MODEL.md)
erklärt die Datenbankgrenzen. Die
[Skill-View](Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md)
enthält auch Beschreibungen zu nicht ausgewählten Modulen.

## Auf einen neuen Stand wechseln

Für eine zentrale Installation eine neue Datenbank bereitstellen. Direkte
SQL-Referenzen, Benutzer, Rechte und gespeicherte Anwendungsdaten ermitteln.
Benötigte Daten und Einstellungen bewusst übernehmen. Aufrufe mit den
Anwendungsanmeldungen prüfen, dann die Referenzen umstellen. Die bisherige
Datenbank kann während des Wechsels als Rückfalloption dienen.

Bei einer lokalen Installation die Ablösung oder Datenbankmigration gemeinsam
mit der Anwendung planen. Der aktuelle Installer ergänzt fehlende Objekte.
Er ersetzt keine Definitionen und führt keine Deinstallation aus. Ältere
markerbasierte Upgrade- und Uninstall-Skripte gelten für ihre eigenen Sätze.

## Fehler beheben

| Beobachtung | Nächster Schritt |
|---|---|
| Paket oder `sqlcmd` fehlt | Den vollständigen Satz entpacken, den Pfad prüfen und ODBC-`sqlcmd` bereitstellen. Alternativ ein SQL-Profil direkt ausführen. |
| Login oder Zertifikatsprüfung scheitert | Instanz, Port, Anmeldeart, Zertifikatskette und Namensübereinstimmung prüfen. |
| Plattform oder Modul fehlt | Zielprofil und bei Teilinstallern die Modulauswahl prüfen. |
| CLR, Rechte oder vorbereitete Änderung blockieren | [Trust und Clientprüfungen](Deployment/ONE-CALL-INSTALL.md#plattform-rechte-und-trust) und [Voraussetzungen zur Vorbereitung](Deployment/PROVISIONING.md#wirkung-und-voraussetzungen) prüfen. |
| `INSTALLED_OR_PRESENT`, aber der Aufruf passt nicht | Zieldatenbank, vorhandene Objektdefinition und Rechte der Anwendungsanmeldung prüfen. |
| Installation wurde unterbrochen | Vor einem weiteren Aufruf tatsächlichen Zielzustand und gegebenenfalls das private Vorbereitungsjournal prüfen. Objekte, Trust oder Konfiguration können teilweise bestehen. |

[Funktionen nach Aufgabe wählen](Documentation/ChooseFunctions.md) ·
[Objekthilfe nachschlagen](Documentation/Reference/README.md)
