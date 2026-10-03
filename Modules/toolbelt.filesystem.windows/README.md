# Windows Filesystem

`toolbelt.filesystem.windows` stellt kontrollierte Dateisystemoperationen für SQL Server unter Windows bereit.

Der Provider ist bewusst Windows-only und benötigt eine per SHA2-512 autorisierte `EXTERNAL_ACCESS`-Assembly. Er akzeptiert nur Root-Aliasse und relative Pfade. Konkrete Pfade werden ausschließlich vom Betreiber in `toolbelt_filesystem.FileSystemRoot` konfiguriert und gehören nicht in Deployment-Skripte, Beispiele oder Test-Evidence.

Die öffentliche API umfasst begrenztes Lesen von Binary/Text, gestreamtes Schreiben, Transcoding, Directory-Listing, Directory-Erzeugung sowie File-/Directory-Delete. Standardmodus ist `Caller`: Der per Windows Authentication angemeldete SQL-Caller wird ausschließlich während des Dateisystemzugriffs impersoniert. `ServiceAccount` ist eine explizite Alternative für kontrollierte Server-Jobs. SQL Authentication mit `Caller` wird abgelehnt.

Die Windows-Validierung ist teilweise ausgeführt. Die Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 war für Build, SHA2-512-Trust, lokales Deployment, alle Help-Verträge und die SQL-Authentication-Ablehnung im `Caller`-Modus erfolgreich. Der Lauf `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 bestätigte das kontrollierte Erstellen eines Verzeichnisses und Schreiben einer Textdatei im `ServiceAccount`-Modus. Windows-Authentication-, NTFS-ACL- und weitere I/O-Tests bleiben offen. Vor produktiver Verwendung sind die [Contract-Testmatrix](./Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md) und der [manuelle Windows-Runtime-Testplan](./Tests/Manual_Windows_Runtime_Testplan.md) verpflichtend.

## Build-Voraussetzung

Für den Build der SQL-CLR-Assembly wird das **.NET Framework 4.8 Developer Pack** einschließlich des **4.8 Targeting Pack** benötigt. Es stellt die Referenzassemblies bereit, gegen die das C#-Projekt kompiliert wird. Das installierte .NET-Framework-Runtime allein genügt nicht. Das Projekt zielt ausdrücklich auf `v4.8`; ein ausschließlich installiertes 4.8.1 Developer Pack ersetzt die `v4.8`-Referenzassemblies für MSBuild nicht.

Microsoft stellt das benötigte Paket auf der offiziellen [Downloadseite für .NET Framework 4.8](https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48) bereit. Die Installation ist nur auf Build- oder Testarbeitsplätzen erforderlich; für ein Deployment aus verifizierten Release-Artefakten wird kein Developer Pack auf dem SQL-Server benötigt.

Der SQL-Server benötigt für die Laufzeit stattdessen die in den Deployment-Dokumenten beschriebenen Voraussetzungen: `clr enabled`, weiterhin aktiviertes `clr strict security` und die explizite Freigabe des SHA2-512-Hashes der Release-Assembly.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `Portierter NoOverwrite-Frameworktest und private Prozesskontrollen`
- Scope: Aktueller sourcegebundener Fixed-only-Harness: neun Fälle/254 Assertions, Staging-/Zielerhalt und eigene Bereinigung erfolgreich; vier private tatsächliche Prozesskontrollen für Nonzero, Timeout, Capturegrenze und Postpin-Drift erfolgreich. Aktueller Projektbuild/Releaseartefakt mit Assemblyversion1.0.0.0 ebenfalls erfolgreich. Offline-Scope ohne SQL, Caller-/NTFS-Nachweis; CI am exakten PR-Head separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## NoOverwrite-Regression

Bei `@Overwrite = 0` veröffentlicht der Provider ausschließlich per nicht überschreibendem `File.Move`. Auch ein erst während des Staging-Schreibens erzeugtes Ziel wird nicht ersetzt; der frühere Existenzcheck allein ist keine Veröffentlichungsbarriere. `@Overwrite = 1` behält den bisherigen Move-/Replace-Pfad. Fehlgeschlagenes Schreiben räumt die eigene Staging-Datei auf; ein vorhandenes Ziel bleibt bei NoOverwrite unverändert. Dies ist keine allgemeine NTFS-, Power-Loss- oder Caller-Impersonation-Garantie.

Der aktuelle Provider hat am 2026-10-03 den .NET-Framework-4.8-Projektbuild und die Releaseartefakt-Erzeugung bestanden. Die historische private Helperqualifikation umfasste neun synthetische Fälle und 254 Assertions; sie ersetzt keinen Nachweis des neuen öffentlichen Test-Runners. Der sourcegebundene [Offline-Regressionstest](./Tests/Framework/README.md) bestand tatsächlich neun Fälle/254 Assertions einschließlich eigener Bereinigung und abschließender Pins. Vier zusätzliche private Prozesskontrollen bestanden Nonzero, Timeout, Capturegrenze und Postpin-Drift. Aktuelle CI wird separat am exakten PR-Head nachgewiesen. Neue SQL-Caller-/NTFS-Tests der korrigierten Binary sind nicht ausgeführt. Modulversion1.0.0, `partially validated` und `unreleased` bleiben erhalten.
