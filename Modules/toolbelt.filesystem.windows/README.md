# Windows Filesystem

`toolbelt.filesystem.windows` stellt kontrollierte Dateisystemoperationen für SQL Server unter Windows bereit.

Der Provider ist bewusst Windows-only und benötigt eine per SHA2-512 autorisierte `EXTERNAL_ACCESS`-Assembly. Er akzeptiert nur Root-Aliasse und relative Pfade. Konkrete Pfade werden ausschließlich vom Betreiber in `toolbelt_filesystem.FileSystemRoot` konfiguriert und gehören nicht in Deployment-Skripte, Beispiele oder Test-Evidence.

Die öffentliche API umfasst begrenztes Lesen von Binary/Text, gestreamtes Schreiben, Transcoding, Directory-Listing, Directory-Erzeugung sowie File-/Directory-Delete. Standardmodus ist `Caller`: Der per Windows Authentication angemeldete SQL-Caller wird ausschließlich während des Dateisystemzugriffs impersoniert. `ServiceAccount` ist eine explizite Alternative für kontrollierte Server-Jobs. SQL Authentication mit `Caller` wird abgelehnt.

Die Laufzeitvalidierung ist noch nicht ausgeführt. Vor produktiver Verwendung sind die [Contract-Testmatrix](./Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md) und der [manuelle Windows-Runtime-Testplan](./Tests/Manual_Windows_Runtime_Testplan.md) verpflichtend.
