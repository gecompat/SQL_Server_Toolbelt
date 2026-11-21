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

Ohne `-Platform` wird das Windows-Profil auf Windows beziehungsweise das
Portable-Profil auf Linux ausgewählt. `-Platform Portable` ist auch auf Windows
möglich. Windows-Funktionen werden auf Linux nicht installiert. Lokal und zentral
bezeichnen den Installationsort in der Datenbank, nicht den Rechner des Clients.

| TrustMethod | Verhalten |
|---|---|
| `auto`, Standard | Bereits TRUSTWORTHY ON: vorhandenen Datenbank-Trust nutzen; andernfalls exakte Hashfreigabe |
| `hash` | Eingebettete Assemblyhashes vergleichen und exakt diese Hashes registrieren |
| `trustworthy-checked` | Bereits TRUSTWORTHY ON und passende Ownerautorisierung voraussetzen; Hashvergleich ohne Registrierung |
| `trustworthy` | Vorhandenen Datenbank-Trust ohne Toolbelt-Hashvergleich verwenden |

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
Hash und deklarierte Schnittstellen. Bei einem festen Trustweg im Buildmanifest
wird dieser verwendet, sofern der Aufruf ihn nicht ausdrücklich überschreibt.
Details zu Inputs und vier Profilen: [gemeinsamer SQL-Build](../Scripts/Install/README.md).
`Deploy-All.ps1` führt Planung, Quellbuild und Installation über denselben Kern.

## Prüfen, Fehler und Abschluss

- `-ValidateOnly`: Paket-/Dateikontrolle ohne Verbindung und ohne SQL-Ausführung.
- `-PreflightOnly`: lesende Zielprüfung; mit Vorbereitungsflags ausschließlich
  deren lesende Planung, keine Datenbankanlage oder Konfigurationsänderung.
- `-TrustServerCertificate`: nur ausdrücklich auf Wunsch; die Prüfung von
  Zertifikatskette und Servername entfällt. Kein automatischer TLS-Fallback.
- `-LoginTimeoutSeconds` und `-CommandTimeoutSeconds`: endliche Clientgrenzen;
  nach Fehler oder Timeout kein automatischer Wiederanlauf.

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
