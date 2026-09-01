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
- Datum: `2026-08-05`
- Nachweis: `Ergänzender Windows-CLR-Preflight-Lauf`
- Scope: SQL Server 2025 Windows; kontrolliertes ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem WorkPath
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
