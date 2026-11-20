# Gemeinsame Installation als normale SQL-Datei

Der Funktionsinstaller dieses Quellstands erstellt Toolbelt ohne SQLCMD,
Installationsmarker oder Deploymenttabellen. Eine Datei enthält die Binaries,
Schemas, fachlichen Tabellen und SQL-Objekte des gewählten Profils. Beim
Installieren wird ausschließlich die erste `USE`-Zeile angepasst.

Die veröffentlichten Vorabreleases bis rc.4 bleiben unverändert. Dieser neue
Weg ist ein Quellbuild und kein veröffentlichtes oder vollständig nativ
qualifiziertes Gesamtpaket. Die bisherigen markerbasierten Deploy-/Uninstall-
Skripte verwalten einen anderen Installationsweg und dürfen nicht zum Upgrade
oder Entfernen dieser markerfreien Installation verwendet werden.

Der begrenzte native Gesamtfall vom 2026-11-20 ist für Windows SQL2025/CU8,
CL170, das lokale Windows-Profil und den Hashweg bestanden: Installation und
Wiederholung, XML-Aufruf, zentraler Aufruf mit Startwerten und tatsächliche
DebugScript-Ausführung. 13 Prüfungen und der separate frische Windows-Audit
mit zwei Prüfungen sind PASS. Zwei vorherige, bereinigte Fehlläufe deckten
ausgelassene kanonische Objektdateien auf; ihre Fehlernachweise bleiben erhalten.
Das ist keine vollständige native Abnahme aller Profile oder Trustwege.
Die [Prüfübersicht](Tests/QUALIFICATION.md) grenzt Teilnachweise und Restpunkt ab.

## Datei bauen

Auf einem Windows-Buildhost werden die .NET-Framework-4.8-Entwicklungswerkzeuge,
MSBuild, PowerShell 7 und Python 3 benötigt. Ausgangspunkt ist das unveränderte
net472-ScriptDom-Binary aus Microsofts NuGet-Paket
`Microsoft.SqlServer.TransactSql.ScriptDom` 180.117.0. Die Buildskripte erstellen
eine reproduzierbare private Toolbelt-Abhängigkeit; sie verändern die
Originalbibliothek nicht.

Vom Repositoryroot aus, mit neuen Ausgabeordnern:

```powershell
& Modules/toolbelt.tsql.script-parser/Scripts/New-ClrReleaseArtifacts.ps1 `
  -ScriptDomDllPath C:/BuildInputs/Microsoft.SqlServer.TransactSql.ScriptDom.dll `
  -OutputDirectory .runtime/simple-common/inputs/parser
python Modules/toolbelt.tsql.ssis-debug/Scripts/New-DependencyPins.py `
  .runtime/simple-common/inputs/parser
& Modules/toolbelt.tsql.ssis-debug/Scripts/New-ClrReleaseArtifacts.ps1 `
  -ScriptDomDllPath C:/BuildInputs/Microsoft.SqlServer.TransactSql.ScriptDom.dll `
  -ParserReleaseDirectory .runtime/simple-common/inputs/parser `
  -OutputDirectory .runtime/simple-common/inputs/ssis
python Scripts/Install/New-SimpleCommonInstall.py `
  --inputs .runtime/simple-common/inputs `
  --work .runtime/simple-common/build-windows-central `
  --output .runtime/simple-common/Install-Toolbelt.sql `
  --platform Windows --mode central --trust-mode auto
```

Unveränderte CLR-Binaries werden nur bei passender Compilerbindung aus den
erhaltenen Lieferungen wiederverwendet. Der Build prüft die Eingaben und parst
die SQL-Quellen offline; er verbindet sich nicht mit SQL Server. Neben der
SQL-Datei entsteht eine JSON-Datei mit Profil, Quell- und Binarybindungen. Sie
ist ein Buildinventar und kein Nachweis einer tatsächlich ausgeführten
Installation. Kein Release oder Tag wird dadurch erstellt.

| Auswahl | Inhalt |
|---|---|
| `--platform Windows --mode local` | Alle 45 Module in der Arbeitsdatenbank |
| `--platform Windows --mode central` | 43 Module in der gemeinsamen Toolbelt-Datenbank; ohne die beiden lokal gebundenen Dateisystem-/ZIP-Dateifassaden |
| `--platform Portable --mode local` | 41 portable Module, auch für Linux; ohne Windows-Dateisystem, ZIP-Dateifassaden, Scriptparser und SSIS-Debug |
| `--platform Portable --mode central` | Dieselben 41 portablen Module in einer zentralen Datenbank |

Die [DTSX-Anleitung](../../Modules/toolbelt.tsql.ssis-debug/Documentation/SimpleInstallation.md)
erklärt den kleineren SSIS-Funktionssatz, wenn die übrigen Module nicht benötigt
werden. Table Clone ist portabel ohne Triggerübernahme verfügbar; die optionale
Triggerübernahme benötigt auf Windows zusätzlich den strikten Parservertrag.

## Installieren

Die Zieldatenbank muss existieren. SQL Server 2019 oder neuer und mindestens
Compatibility Level 150 sind erforderlich. CLR muss für die CLR-Module bereits
aktiviert sein. Der Installer verändert weder CLR-Konfiguration, Datenbankowner,
TRUSTWORTHY, Strict Security noch vorhandene Rechte. Er verlangt keine pauschale
sysadmin-Mitgliedschaft: Die Engine prüft die tatsächlich ausgeführten
CREATE-/Schema-/Assemblyoperationen. Exakte Hashregistrierung benötigt die
entsprechenden vorhandenen Serverrechte; Dateifunktionen behalten ihre
Windows-/Dateisystemrechte und ihre eigenen Freigabegrenzen.

1. `USE [ContosoToolbelt];` am Anfang auf die eigene Zieldatenbank ändern.
2. Die gesamte SQL-Datei als gewöhnliche Abfrage ausführen, ohne SQLCMD-Modus.
3. Bei einem Fehler dessen erste Engine-/Toolbelt-Meldung beachten. Nachfolgende
   Installationsschritte werden abgebrochen; bereits angelegte Objekte können
   bestehen bleiben. Es gibt keine behauptete Gesamttransaktion.

| `--trust-mode` | Bedeutung |
|---|---|
| `auto`, Standard | Bereits TRUSTWORTHY ON: vorhandenen Datenbank-Trust nutzen; sonst exakte Hashfreigabe |
| `hash` | Binaryhashes vergleichen und ausschließlich die eingebetteten exakten Hashes registrieren |
| `trustworthy-checked` | Bereits vorhandenes TRUSTWORTHY ON verwenden, erwartete Assemblybytes vergleichen, keine Hashregistrierung |
| `trustworthy` | Bereits vorhandenes TRUSTWORTHY ON ohne Toolbelt-Hashvergleich oder Registryabfrage verwenden |

Die beiden Datenbank-Trustwege setzen einen entsprechend berechtigten Owner
voraus. Sie aktivieren TRUSTWORTHY nicht. Ein Fehler wechselt den gewählten Weg
nicht automatisch. Der ungeprüfte Weg ist keine Aussage zur Binaryintegrität;
auch der Hashweg qualifiziert nicht automatisch sämtliche vorhandenen
SQL-Objektdefinitionen oder die Herkunft namensgleicher Objekte.

## Wiederholung und vorhandene Installationen

Fehlende Prozeduren, Funktionen und Views werden erstellt, vorhandene bleiben
unverändert. Die neuen SQL-Assemblynamen beginnen sämtlich mit `tlblt`; fremde
Assemblies werden weder umbenannt noch aktualisiert. Die private ScriptDom-
Abhängigkeit besitzt zusätzlich eine eigene CLR-Identität, damit eine fremde
Microsoft-Version weiter unabhängig verwendet werden kann.

Fachliche Tabellen werden in zusammengehörigen Gruppen erstellt. Vorhandene
vollständige Gruppen werden übersprungen; teilweise vorhandene Gruppen führen
zum Abbruch. Die älteren Tabellenmigrationen laufen ausschließlich auf gerade
neu erstellten eigenen Gruppen. Bestehende Tabellen werden dadurch nicht
erweitert, umgebaut oder mit neuen Initialwerten überschrieben.

Dies ist ein **create-only-Installer**, kein In-place-Upgrade. Für einen anderen
Build eine neue eigene Datenbank verwenden oder vorhandene eigene Objekte nach
Verbraucherprüfung gezielt verwalten. Er entfernt keine unbekannten Objekte
oder globalen Trusteinträge. Einen vorhandenen produktiven Toolbelt-Stand
ersetzt dieser Build nicht automatisch.

Die fachlichen Event-/Work-Queue-Tabellen bleiben Bestandteil ihrer Module;
sie sind keine Deploymentlogs. Ebenso bleibt das ausdrücklich angeforderte
Kopieren benutzerdefinierter Tabellen-Properties bei Table Clone eine
Fachfunktion. Toolbelt verwendet solche Properties nicht mehr für seine
Installations-, Versions-, Ownership- oder Laufzeitabhängigkeitsprüfung.

## Verwenden und Fehler eingrenzen

Öffentliche Schema-/Objektnamen und deren Berechtigungen stehen in den
[Modulanleitungen](../../Modules/README.md). Für zentralen Aufruf den Namen der
Toolbelt-Datenbank voranstellen; Cross-DB-Zugriff, Identitätsmapping und konkrete
Objektrechte bleiben erforderlich. Der Installer vergibt diese Rechte nicht.

`VW_ModuleCapabilities` zeigt nur sichtbare bekannte Schnittstellenkandidaten.
Ohne Registry lassen sich Version und Installationsmodus daraus nicht beweisen;
beide bleiben NULL und `MetadataStatus` ist `incomplete`. Diese View ist kein
Autorisierungs-, Ownership- oder Upgradegate.

Bei `compiler drift`, `binary` oder `source ... drift` die zum aktuellen
Quellstand passenden Buildartefakte neu erstellen; keine Hashprüfung umgehen.
Bei einer teilweise vorhandenen Tabellengruppe eine neue eigene Datenbank
verwenden. Fehlende Berechtigungen oder nicht eingerichteten Datenbank-Trust
mit dem zuständigen Administrator klären; der Installer lockert diese Grenzen
nicht selbst.
