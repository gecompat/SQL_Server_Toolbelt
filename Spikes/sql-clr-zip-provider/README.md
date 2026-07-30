# SQL CLR ZIP Provider – Build-/Deployment-Spike

## Status

**Implementiert, Runtime nicht ausgeführt.** Dieser Spike ist kein Toolbelt-Modul,
kein Release-Artefakt und stellt keine produktive ZIP-API bereit. Er prüft allein,
ob eine minimale C#-Assembly mit `System.IO.Compression` reproduzierbar gebaut,
mit `PERMISSION_SET = SAFE` registriert und in einer ausdrücklich angelegten
Testdatenbank wieder entfernt werden kann.

Die produktive Deflate-/CRC-Implementierung bleibt bis zu einer eigenen
funktionsbezogenen Freigabe gesperrt. Ihr Vertrag steht in
[`ZIP_CLR_PROVIDER_DESIGN.md`](../../Documentation/Architecture/ZIP_CLR_PROVIDER_DESIGN.md).

## Enthaltene Nachweise

| Artefakt | Zweck |
|---|---|
| `Source/` | Minimaler .NET-Framework-4.8-Build mit einem echten Verweis auf `System.IO.Compression` und einem deterministischen In-memory-Probe. |
| `Scripts/New-TrustManifest.ps1` | Erzeugt aus dem gebauten Binary ein SHA2-512-Manifest. Das Binary und das abgeleitete Manifest bleiben lokal. |
| `Deployment/Add-TrustedAssembly.sql` | Getrenntes, ausschließlich administratives Opt-in für `sys.sp_add_trusted_assembly`; es ändert keine Instanzoption. |
| `Deployment/Deploy-TestDatabase.sql` | Registriert Assembly und Probe-Procedure nur in der expliziten Testdatenbank. |
| `Deployment/Verify-TestDatabase.sql` | Prüft `SAFE`, den erwarteten Provider-Verweis und die Ausführung der Probe. |
| `Deployment/Uninstall-TestDatabase.sql` | Entfernt Procedure, Assembly und das leere Test-Schema; ein Trust-Eintrag bleibt bewusst unangetastet. |

## Sicherheitsgrenzen

- Kein `TRUSTWORTHY ON`, kein Abschalten von `clr strict security`, kein
  `EXTERNAL_ACCESS` und kein `UNSAFE`.
- Keine Dateien, Pfade, Netzwerke, Prozesse oder Secrets in der CLR-Routine.
- Das Deployment akzeptiert einen serverlokal erreichbaren Pfad nur zum Laden
  der bereits gebauten Assembly. Dieser Pfad ist keine Runtime-API und wird
  weder persistiert noch protokolliert.
- Trust wird ausschließlich über den SHA2-512-Hash des konkreten Binaries und
  nur durch einen Administrator eingerichtet. Der reguläre Produktinstaller
  darf diesen Schritt später nicht stillschweigend ausführen.

## Voraussetzungen und Ausführung

Auszuführen ist der Spike ausschließlich auf einer disposable SQL-Server-
Testinstanz. Er benötigt Windows mit .NET Framework 4.8 Targeting Pack,
Visual-Studio-Build-Tools (MSBuild), PowerShell und `sqlcmd`. SQL Server muss
CLR bereits aktiviert haben; `clr strict security` bleibt aktiviert. Die
angegebene Testdatenbank muss vor dem Aufruf bewusst angelegt worden sein; der
Spike erstellt oder löscht keine Datenbank.

```powershell
Set-Location Spikes/sql-clr-zip-provider
./Scripts/Invoke-DeploymentSpike.ps1 `
  -SqlInstance '<test-instance>' `
  -TestDatabase 'Toolbelt_ClrZipSpike'
```

`Invoke-DeploymentSpike.ps1` baut, erstellt lokal das Trust-Manifest, führt
das getrennte Trust-Opt-in aus, deployt, verifiziert und deinstalliert die
Testobjekte. Es entfernt den Trust-Eintrag nicht automatisch. Dies verhindert,
dass der Vorgang eine möglicherweise gemeinsam verwendete Vertrauensfreigabe
unbeabsichtigt entfernt.

Für jeden Zieltest (SQL Server 2019, 2022 und 2025; Windows und Linux) sind
Version, Plattform, Ausführungsdatum, der verwendete Befehl und das Ergebnis
außerhalb des Repositorys zu erfassen. Ohne reale Ausführung bleibt der Status
korrekt `not executed`.

## Nicht enthalten

Deflate-Extraktion, CRC32, ZIP64, öffentliche SQL-Objekte, Modulmanifest,
Produktinstallation, Paketierung und ein automatischer Server-Trust sind nicht
Teil dieses Spikes.
