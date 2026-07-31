# SQL CLR ZIP Provider – Build-/Deployment-Spike

## Status

**Implementiert; positiver Linux-Runtime-Gate ist Bestandteil der CI.** Dieser
Spike ist kein Toolbelt-Modul, kein Release-Artefakt und stellt keine produktive
ZIP-API bereit. Er prüft den technisch kleinsten Providerpfad für ZIP Method 8:

- .NET Framework 4.8 und `PERMISSION_SET = SAFE`;
- `DeflateStream` aus der von SQL Server unterstützten `System.dll`;
- ein fest eingebetteter Raw-Deflate-Stream ausschließlich im Speicher;
- eine eigene CRC32-Prüfung des dekomprimierten Payloads;
- binäres `CREATE ASSEMBLY`, ohne serverlokalen Dateipfad.

Der vorherige `ZipArchive`-Ansatz war ungeeignet: Er erzeugte eine direkte
Abhängigkeit von der nicht automatisch unterstützten
`System.IO.Compression.dll` und konnte deshalb auf SQL Server Linux nicht
deployt werden. Der Namespace `System.IO.Compression` bleibt im C#-Code korrekt;
entscheidend ist, dass die Assembly nur `System.dll` referenziert.

Die produktive ZIP-Containeranalyse, Ressourcenlimits, Entry-Auswahl und der
öffentliche SQL-Vertrag bleiben bis zu einer eigenen funktionsbezogenen
Freigabe gesperrt. Der Vertrag steht in
[`ZIP_CLR_PROVIDER_DESIGN.md`](../../Documentation/Architecture/ZIP_CLR_PROVIDER_DESIGN.md).

## Enthaltene Nachweise

| Artefakt | Zweck |
|---|---|
| `Source/` | Minimaler .NET-Framework-4.8-Build mit `DeflateStream` aus `System.dll`, Raw-Deflate-Fixture und CRC32-Probe. |
| `Scripts/New-TrustManifest.ps1` | Erzeugt aus dem gebauten Binary ein SHA2-512-Manifest. Binary und Manifest bleiben lokal beziehungsweise CI-Artefakte. |
| `Deployment/Add-TrustedAssembly.sql` | Getrenntes, ausschließlich administratives Opt-in für `sys.sp_add_trusted_assembly`; es ändert keine Instanzoption. |
| `Deployment/Deploy-TestDatabase.sql` | Registriert Assembly und Probe-Procedure aus einem vom Aufrufer eingesetzten Binärliteral in der expliziten Testdatenbank. |
| `Deployment/Verify-TestDatabase.sql` | Prüft `SAFE`, die tatsächliche `System.dll`, Payload-Länge, Payload-Inhalt und CRC32. |
| `Deployment/Uninstall-TestDatabase.sql` | Entfernt Procedure, Assembly und das leere Test-Schema; ein Trust-Eintrag bleibt bewusst unangetastet. |
| `.github/workflows/sql-clr-zip-spike.yml` | Baut auf Windows und führt Deploy, CLR-Aufruf und Uninstall auf SQL Server 2022 Linux aus. |

## Sicherheitsgrenzen

- Kein `TRUSTWORTHY ON`, kein Abschalten von `clr strict security`, kein
  `EXTERNAL_ACCESS` und kein `UNSAFE`.
- Keine Dateien, Pfade, Netzwerke, Prozesse oder Secrets in der CLR-Routine.
- Das Deployment verwendet das bereits gebaute Binary als `0x`-Literal. Der
  SQL-Server-Dienst benötigt keinen Zugriff auf einen Build- oder Freigabepfad.
- Trust wird ausschließlich über den SHA2-512-Hash des konkreten Binaries und
  nur durch einen Administrator eingerichtet. Der reguläre Produktinstaller
  darf diesen Schritt später nicht stillschweigend ausführen.
- Der temporär erzeugte Deployment-SQL-Text wird nicht im Repository oder als
  CI-Artefakt gespeichert.

## Voraussetzungen und Ausführung

Auszuführen ist der Spike ausschließlich auf einer disposable SQL-Server-
Testinstanz. Der lokale Komplettlauf benötigt Windows mit .NET Framework 4.8
Targeting Pack, Visual-Studio-Build-Tools (MSBuild), PowerShell und `sqlcmd`.
SQL Server muss CLR bereits aktiviert haben; `clr strict security` bleibt
aktiviert. Die angegebene Testdatenbank muss vor dem Aufruf bewusst angelegt
worden sein; der Spike erstellt oder löscht keine Datenbank.

```powershell
Set-Location Spikes/sql-clr-zip-provider
./Scripts/Invoke-DeploymentSpike.ps1 `
  -SqlInstance '<test-instance>' `
  -TestDatabase 'Toolbelt_ClrZipSpike'
```

`Invoke-DeploymentSpike.ps1` baut, erstellt lokal das Trust-Manifest, erzeugt
eine temporäre SQL-Kopie mit dem Binärliteral, führt das getrennte Trust-Opt-in
aus, deployt, verifiziert und deinstalliert die Testobjekte. Es entfernt den
Trust-Eintrag nicht automatisch. Dies verhindert, dass der Vorgang eine
möglicherweise gemeinsam verwendete Vertrauensfreigabe unbeabsichtigt entfernt.

## Aussagegrenze und weitere Matrix

Der automatisierte Linux-Gate belegt nach erfolgreichem Lauf ausschließlich:

- Build der .NET-Framework-4.8-Assembly auf Windows;
- Trust und `SAFE`-Deployment auf SQL Server 2022 Linux;
- tatsächliche Raw-Deflate-Dekomprimierung über `System.dll`;
- CRC32-Prüfung und vollständigen Uninstall.

SQL Server 2019, SQL Server 2025 und Windows-Runtime bleiben getrennte
Pflichtläufe vor einer Produktfreigabe. Der Spike belegt noch keinen sicheren
Parser beliebiger ZIP-Container und keine Produktionsreife.

## Nicht enthalten

Produktive ZIP-Header-/Central-Directory-Analyse, ZIP64, öffentliche
SQL-Objekte, Modulmanifest, Produktinstallation, Paketierung, Archiv-Erzeugung
und automatischer Server-Trust sind nicht Teil dieses Spikes.
