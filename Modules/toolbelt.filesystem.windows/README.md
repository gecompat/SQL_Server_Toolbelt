# Windows Filesystem

`toolbelt.filesystem.windows` stellt kontrollierte Dateisystemoperationen für SQL Server unter Windows bereit.

Der Provider ist bewusst Windows-only und benötigt eine per SHA2-512 autorisierte `EXTERNAL_ACCESS`-Assembly. Er akzeptiert nur Root-Aliasse und relative Pfade. Konkrete Pfade werden ausschließlich vom Betreiber in `toolbelt_filesystem.FileSystemRoot` konfiguriert und gehören nicht in Deployment-Skripte, Beispiele oder Test-Evidence.

Die öffentliche API umfasst begrenztes Lesen von Binary/Text, gestreamtes Schreiben, Transcoding, Directory-Listing, Directory-Erzeugung sowie File-/Directory-Delete. Standardmodus ist `Caller`: Der per Windows Authentication angemeldete SQL-Caller wird ausschließlich während des Dateisystemzugriffs impersoniert. `ServiceAccount` ist eine explizite Alternative für kontrollierte Server-Jobs. SQL Authentication mit `Caller` wird abgelehnt.

Die Windows-Validierung ist teilweise ausgeführt. Die Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 war für Build, SHA2-512-Trust, lokales Deployment, alle Help-Verträge und die SQL-Authentication-Ablehnung im `Caller`-Modus erfolgreich. Der Lauf `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 bestätigte das kontrollierte Erstellen eines Verzeichnisses und Schreiben einer Textdatei im `ServiceAccount`-Modus. Für diesen historischen Stand blieben Windows-Authentication-, NTFS-ACL- und weitere I/O-Tests offen; den aktuellen begrenzten Nachweis beschreibt der folgende Evidenzabschnitt. Vor produktiver Verwendung sind die [Contract-Testmatrix](./Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md) und der [manuelle Windows-Runtime-Testplan](./Tests/Manual_Windows_Runtime_Testplan.md) verpflichtend.

## Build-Voraussetzung

Die Wartung vom 2026-10-07 korrigiert die vorhandene Delete-Tiefengrenze:
ein vollständiger begrenzter Prüfplan vor jeder Mutation, danach nur geprüfte
Einträge und nichtrekursive Directory-Deletes. Startdirectory-Tiefe0 erlaubt
direkte Dateien bei `@MaxDepth = 0`, aber kein Childdirectory. Details und
Fehlergrenzen stehen bei [USP_RemoveDirectory](Documentation/USP_RemoveDirectory.md).
Historische SQL-/Caller-Nachweise gelten für den damaligen Providerstand;
die korrigierte Source bleibt `partially validated` und `unreleased`.

Für den Build der SQL-CLR-Assembly wird das **.NET Framework 4.8 Developer Pack** einschließlich des **4.8 Targeting Pack** benötigt. Es stellt die Referenzassemblies bereit, gegen die das C#-Projekt kompiliert wird. Das installierte .NET-Framework-Runtime allein genügt nicht. Das Projekt zielt ausdrücklich auf `v4.8`; ein ausschließlich installiertes 4.8.1 Developer Pack ersetzt die `v4.8`-Referenzassemblies für MSBuild nicht.

Microsoft stellt das benötigte Paket auf der offiziellen [Downloadseite für .NET Framework 4.8](https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48) bereit. Die Installation ist nur auf Build- oder Testarbeitsplätzen erforderlich; für ein Deployment aus verifizierten Release-Artefakten wird kein Developer Pack auf dem SQL-Server benötigt.

Der SQL-Server benötigt für die Laufzeit stattdessen die in den Deployment-Dokumenten beschriebenen Voraussetzungen: `clr enabled`, weiterhin aktiviertes `clr strict security` und die explizite Freigabe des SHA2-512-Hashes der Release-Assembly.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater ausgewählter Windows-Caller-/NTFS-Lauf`
- Scope: SQL Server 2025/CU8 Windows; 16 Pflichtfälle erfolgreich: neun öffentliche Prozeduren, Windows-/SQL-Authentifizierung, Caller-/ServiceAccount-NTFS-Verweigerungen, Binary-/UTF-8-/UTF-16-LE-I/O, NoOverwrite/Overwrite und Bereinigung nach Schreib-/Encodingfehlern. Zusätzlicher Race-Fall NOT_OBSERVED. Drei eigene Fixture-ACLs und ein Readonly-Attribut zurückgesetzt; eigene DB/Root/Trustbereinigung und separate frische Prüfung bestanden. Keine Konfigurations-, SQL-Rechte- oder Owneränderungen. Keine direkte CLR-/vollständige Matrix-/ZIP-Dateizugriffsqualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## NoOverwrite-Regression

Bei `@Overwrite = 0` veröffentlicht der Provider ausschließlich per nicht überschreibendem `File.Move`. Auch ein erst während des Staging-Schreibens erzeugtes Ziel wird nicht ersetzt; der frühere Existenzcheck allein ist keine Veröffentlichungsbarriere. `@Overwrite = 1` behält den bisherigen Move-/Replace-Pfad. Bei Fehlern versucht der Provider, seine eigene Staging-Datei unter derselben gewählten Identität zu bereinigen; der erste Fehler bleibt erhalten. Scheitern Identitätswiederherstellung oder Bereinigung, können Reste bleiben. Ein vorhandenes Ziel bleibt bei NoOverwrite unverändert. Dies ist keine allgemeine NTFS-, Power-Loss- oder Caller-Impersonation-Garantie.

Der Providerstand vor der Streaming-Identitätskorrektur hat am 2026-10-03 den .NET-Framework-4.8-Projektbuild und die Releaseartefakt-Erzeugung bestanden. Die historische private Helperqualifikation umfasste neun synthetische Fälle und 254 Assertions; sie ersetzt keinen Nachweis des neuen öffentlichen Test-Runners. Der sourcegebundene [Offline-Regressionstest](./Tests/Framework/README.md) bestand tatsächlich neun Fälle/254 Assertions einschließlich eigener Bereinigung und abschließender Pins. Vier zusätzliche private Prozesskontrollen bestanden Nonzero, Timeout, Capturegrenze und Postpin-Drift. Aktuelle CI wird separat am exakten PR-Head nachgewiesen. Für den damaligen Stand war ausschließlich der getrennt beschriebene Zwei-Fall-Auth-Probe-Scope belegt. Der aktuelle ausgewählte Caller-/NTFS-Lauf ist im Evidenzblock und in der Testdokumentation beschrieben; die vollständige Matrix bleibt offen. Modulversion1.0.0, `partially validated` und `unreleased` bleiben erhalten.

## Streaming und Identität

SQL-LOB-Zugriffe (`SqlBytes`/`SqlChars` Length/Read) erfolgen im ursprünglichen SQL-Kontext zwischen den Dateisystem-Sitzungen. Binary verwendet weiterhin einen 1-MiB-Puffer, Text 32768 Zeichen plus den begrenzten Encoding-Puffer; der vollständige Inhalt wird nicht materialisiert. Für Caller wird dieselbe einmal erfasste Windows-Identität bei jedem Datei-Open, Write, Flush, Dispose, Publish und Cleanup verwendet. Nach ungewissem Impersonation-Enter oder Undo wird nicht unter ServiceAccount weitergearbeitet. `ServiceAccount` bleibt eine ausdrücklich gewählte Alternative.

[Microsoft dokumentiert](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/impersonation-and-credentials-for-connections?view=sql-server-ver17), dass lokale Datenzugriffe während Caller-Impersonation bis Undo nicht verfügbar sind. Die Korrektur trennt diese Zugriffe, verändert jedoch weder den öffentlichen Vertrag noch die Encoding-Semantik. Den aktuellen begrenzten Framework-/Auth-Probe-Nachweis beschreibt der folgende Evidenzabschnitt; vollständige NTFS-Qualifikation bleibt offen. Historische Nachweise gelten für ihre damaligen Sources.
## Aktueller begrenzter Nachweis 2026-10-04

Der Providerstand vom 2026-10-04 bestand einen privaten begrenzten produktiven C#-Sourcebuild und den sourcegebundenen Frameworklauf: neun NoOverwrite-Fälle/270 Assertions sowie sieben Streaming-Fälle/188 Assertions; darin enthalten ist die reine Caller-Policyprüfung mit fünf erlaubten und zehn abgewiesenen Werten. Vollständige Captures, Exit0, eigene Bereinigung und abschließende Sourcepins wurden geprüft. Die synthetischen Sequenzfälle beweisen keine echte Impersonation.

Die private native Zwei-Fall-Authentifizierungsprüfung auf SQL Server 2025/CU8 unter Windows bestand: Windows-Caller (NTLM) schrieb drei synthetische Bytes über `USP_WriteBinaryFile`; SQL-Authentifizierung wurde mit `51540/1` und `CallerWindowsAuthenticationRequired` vor Datei-/Staging-I/O abgewiesen. Eigene DB-, Root- und Trustbereinigung und eine separate frische Prüfung bestanden, ohne Konfigurations-, Rechte- oder Owneränderungen. Dieser begrenzte Probe-Scope ist kein vollständiger Produkttest.

Aktueller kanonischer Projektbuild/Releaseartefakt, direkte CLR-/RunAs-Qualifikation aller neun Einstiegspunkte, vollständige NTFS-/Caller-/ServiceAccount-Matrix, Races, weitere Ziele und aktuelle Head-CI bleiben separate offene Gates. Status `partially validated`, Version1.0.0 und `unreleased` bleiben erhalten; frühere Nachweise sind historisch.
