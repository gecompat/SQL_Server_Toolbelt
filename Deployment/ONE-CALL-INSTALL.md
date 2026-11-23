# Toolbelt mit einem Aufruf installieren

Der aktuelle Client verwendet den gemeinsamen markerfreien Installationskern.
Er installiert lokal oder zentral, wählt ausdrücklich den gewünschten Trustweg
und kann auf Wunsch eine fehlende Datenbank anlegen sowie CLR aktivieren.
Die erzeugten SQL-Dateien können alternativ unmittelbar in SSMS ausgeführt
werden: ohne SQLCMD-Modus, nur die erste USE-Zeile ändern.

Die veröffentlichten Vorabreleases bis rc.4 enthalten ihre eigenen historischen
Clients und Nachweise. Sie werden nicht durch den aktuellen Client aktualisiert
oder stillschweigend als aktueller Satz verwendet.

## Fertigen Installationssatz verwenden

Den neu gebauten Installationssatz vollständig entpacken. PowerShell 7.4 oder
neuer und sqlcmd **ODBC** sind für diesen Clientweg erforderlich. Im entpackten
Verzeichnis genügt beispielsweise:

```powershell
pwsh -File .\Deployment\Install-Toolbelt.ps1 `
  -ServerInstance localhost -Database ContosoApp -DeploymentMode local

pwsh -File .\Deployment\Install-Toolbelt.ps1 `
  -ServerInstance localhost -Database ContosoToolbelt -DeploymentMode central `
  -CreateDatabase -EnableClr -TrustMethod hash
```

Ohne Credential wird die aktuelle Windows-Anmeldung verwendet. SQL-Anmeldung:

```powershell
& .\Deployment\Install-Toolbelt.ps1 `
  -ServerInstance localhost -Database ContosoToolbelt -DeploymentMode central `
  -Credential (Get-Credential) -TrustMethod trustworthy
```

Der Client liest die enthaltene Datei `Package/Toolbelt-Install-Payload.zip`.
`-PackageZip` bezeichnet ausdrücklich eine solche **Payload-ZIP**, nicht die
äußere ZIP mit Client und Dokumentation. Es gibt keinen automatischen Download
oder Rückfall auf einen älteren Release. `-ExpectedSha256` kann den Payload
zusätzlich an einen unabhängig bezogenen erwarteten Hash binden. Die internen
Dateihashes belegen Konsistenz, keine Herausgebersignatur.

## Plattform, Rechte und Trust

Der Client ermittelt das Betriebssystem der verbundenen SQL-Server-Instanz.
`-Platform Auto` wählt aus dem vollständigen Satz Windows für ein Windows-Ziel
und Portable für ein Linux-Ziel. `-Platform Portable` ist auch für ein
Windows-Ziel möglich. Lokal und zentral bezeichnen den Datenbankmodus.

| TrustMethod | Verhalten |
|---|---|
| `auto`, Standard | Bei bereits aktivem TRUSTWORTHY den Weg `trustworthy` nutzen, bei OFF den Weg `hash`. |
| `hash` | Eingebettete Assemblyhashes vergleichen und exakt diese Hashes registrieren |
| `trustworthy-checked` | Bereits TRUSTWORTHY ON und passende Ownerautorisierung voraussetzen; Hashvergleich ohne Registrierung |
| `trustworthy` | Vorhandenen Datenbank-Trust ohne Toolbelt-Hashvergleich verwenden |

Bei bereits deaktivierter CLR Strict Security ist eine vorhandene Zieldatenbank
mit `TRUSTWORTHY ON` und ein fest gewählter DB-Trustweg nötig. Verwende
`-TrustMethod trustworthy-checked` für den Hashvergleich oder
`-TrustMethod trustworthy` ohne Hashvergleich. Bei `-InstallSql` kann auch
das Manifest einen dieser Wege festlegen. `auto`, `hash`, `-CreateDatabase`
und `-EnableClr` erfordern weiterhin aktivierte Strict Security. Lightweight
Pooling muss für CLR-Installationen deaktiviert sein.

Kein Fehler schaltet auf einen anderen Weg um. Der Client aktiviert TRUSTWORTHY
nicht, ändert keinen Owner, vergibt keine Rechte und deaktiviert Strict Security
nicht. Die Engine prüft CREATE-, Schema-, Assembly- und Hashfreigaberechte.
Eine pauschale sysadmin-Mitgliedschaft ist für reine Objekterstellung kein Gate.
Die Clientvorprüfung benötigt zusätzlich sichtbare Plattform-/Datenbankidentität
über die Systemmetadaten; der direkte SQL-Weg benötigt diese Clientprüfung nicht.

`-CreateDatabase` und `-EnableClr` sind separate administrative Opt-ins mit
[Vorzustandsvergleich, Pending-Prüfung und privatem Journal](PROVISIONING.md).
Ihre bestehenden stärkeren Rechte- und Sicherheitsgrenzen bleiben erhalten.
Ohne diese Schalter müssen Datenbank und benötigte CLR-Konfiguration vorhanden
sein. SQL-only-Teilsätze benötigen keine CLR-Aktivierung.

## Aktuelle Quellen und einzelne Module

Auf einem Buildhost aus den gebundenen Binaryinputs eine normale SQL-Datei bauen:

```powershell
& .\Deployment\Build-Install.ps1 `
  -Inputs .runtime\build-inputs -OutputSqlFile .runtime\Install-Regex.sql `
  -Platform Portable -DeploymentMode central -ModuleId toolbelt.string.regex

& .\Deployment\Install-Toolbelt.ps1 `
  -InstallSql .runtime\Install-Regex.sql -ServerInstance localhost `
  -Database ContosoToolbelt -DeploymentMode central
```

Die danebenliegende `.manifest.json` gehört zur SQL-Datei. Der Client überprüft
Hash und deklarierte Schnittstellen. Bei `-InstallSql` übernimmt `-Platform Auto`
das Plattformprofil aus dem Buildmanifest. Der Zielserver muss dieses Profil
unterstützen. Bei einem festen Trustweg im Buildmanifest
wird dieser verwendet, sofern der Aufruf ihn nicht ausdrücklich überschreibt.
Details zu Inputs und vier Profilen: [gemeinsamer SQL-Build](../Scripts/Install/README.md).
`Deploy-All.ps1` führt Planung, Quellbuild und Installation über denselben Kern.

## Parameterübersicht

| Parameter | Bedeutung |
|---|---|
| `-DeploymentMode` | Pflicht. `local` für die Anwendungsdatenbank, `central` für die gemeinsame Toolbelt-Datenbank. |
| `-ServerInstance`, `-Database` | Zielinstanz und Zielkatalog. Für Installation und Zielvorprüfung erforderlich. `-ValidateOnly` benötigt kein Ziel. |
| `-Credential` | Optionales `PSCredential` für SQL-Anmeldung. Ohne Credential verwendet `sqlcmd` integrierte Anmeldung im aktuellen Prozesskontext. |
| `-PackageZip`, `-InstallSql` | Alternative Eingaben. Inneres Payload-ZIP oder SQL-Datei mit danebenliegendem Manifest. Im vollständigen Satz findet der Client den mitgelieferten Payload. |
| `-ExpectedSha256` | Erwarteter SHA-256-Wert des inneren Payload-ZIP oder der einzelnen SQL-Datei, 64 Hexzeichen. Das äußere ZIP separat prüfen. |
| `-Platform` | `Auto` (Standard), `Windows` oder `Portable`. Eine einzelne SQL-Datei bringt ihr Profil im Manifest mit. |
| `-TrustMethod` | `auto`, `hash`, `trustworthy-checked` oder `trustworthy`. Bei `-InstallSql` gilt ohne explizite Auswahl der Wert aus dem Manifest. |
| `-SqlcmdPath` | Name oder Pfad des ODBC-Clients. Standard `sqlcmd`. |
| `-TrustServerCertificate` | Ausdrücklicher TLS-Override für die Verbindung. |
| `-ValidateOnly`, `-PreflightOnly` | Alternative Prüfmodi. Offline-Paketprüfung oder lesende Zielprüfung ohne Installation. |
| `-CreateDatabase`, `-EnableClr` | Getrennte [administrative Optionen](PROVISIONING.md). |
| `-LoginTimeoutSeconds` | 1 bis 120 Sekunden, Standard 60. |
| `-CommandTimeoutSeconds` | 1 bis 1800 Sekunden, Standard 600. |

## Prüfen, Fehler und Abschluss

- `-ValidateOnly`: Paket-/Dateikontrolle ohne Verbindung und ohne SQL-Ausführung.
- `-PreflightOnly`: lesende Zielprüfung; mit Vorbereitungsflags ausschließlich
  deren lesende Planung, keine Datenbankanlage oder Konfigurationsänderung.
  Der Client prüft die Plattform-/Moduskombination vor der schreibenden
  Vorbereitung.
- `-TrustServerCertificate`: nur ausdrücklich auf Wunsch; die Prüfung von
  Zertifikatskette und Servername entfällt. Kein automatischer TLS-Fallback.
- `-LoginTimeoutSeconds` und `-CommandTimeoutSeconds`: endliche Clientgrenzen;
  standardmäßig 60 beziehungsweise 600 Sekunden. Nach einem Fehler oder
  Timeout läuft die Installation nicht automatisch erneut an.

Der Installationsdispatch bindet die zuvor gelesene Datenbank-GUID erneut und
verwendet eine sitzungsgebundene Anwendungssperre. Der Abschluss prüft erwartete
Objektnamen/-typen und Assemblynamen, keine Extended Properties. Das Ergebnis
`INSTALLED_OR_PRESENT` behauptet keine installierte Versionsnummer oder geprüfte
Definition bereits vorhandener Objekte. Hashgeprüfte Wege weisen abweichende
vorhandene Assemblybytes ab. Der ungeprüfte Weg ist keine Integritätsabnahme.

Nach der Installation führt die [Anleitung zur Skill-View](../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md)
von der Suche nach einer Funktion zu ihrem vollständigen Markdown-Vertrag.
Für zentrale Installation kann der Datenbankname der View vorangestellt werden.

Der Lebenszyklus ist **create-only**: fehlende Objekte ergänzen, vorhandene nicht
ersetzen. Dies ist kein In-place-Upgrade oder automatisches Uninstall.
Historische Lifecycle-Skripte sind dafür ungeeignet. Bei Fehlern können bereits
angelegte Objekte, eigene Hashfreigaben und ausdrücklich vorbereitete Zustände
bestehen bleiben. Das private Vorbereitungsjournal erhalten und den Zielzustand
vor einem bewussten weiteren Aufruf prüfen. Keine pauschale Rücknahme fremder
Zustände oder automatische Löschung von Datenbanken.
