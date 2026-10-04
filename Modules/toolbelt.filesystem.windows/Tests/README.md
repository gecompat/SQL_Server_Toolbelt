# Test-Evidence

Die Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 war auf SQL Server 2025 unter Windows erfolgreich. Sie umfasste .NET-Framework-4.8-CLR-Build, SHA2-512-Trust, lokales Deployment, alle Help-Verträge und die kontrollierte SQL-Authentication-Ablehnung im `Caller`-Modus ohne I/O-Spuren. Der Lauf `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 bestätigte kontrolliertes ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem `WorkPath`.

Die vollständige Windows-Authentication-/NTFS-ACL-/I/O-Matrix bleibt offen; die historische Zwei-Fall-Auth-Probe und der aktuelle ausgewählte Caller-/NTFS-Lauf sind unten getrennt belegt. Reale Pfade, Benutzer, NTFS-ACLs, Runtime-Ausgaben und Inhalte bleiben außerhalb des Repositorys.

Ein begrenzter nativer Windows-/SQL-Server-2025-Test vom 2026-10-03 bestätigte Installation und Wiederholung, scheiterte aber am Help-Metadatenvertrag: `IsRequired` war `int` statt `bit`. Der SQL-Fix typisiert die fünf Parameterzeilen ausdrücklich als `bit`, damit auch `IsNullable` seinen vertraglichen Typ behält. Der korrigierte Stand bestand anschließend die Prüfung der zwölf CLR-Spaltentypen, sieben Help-Zeilen und zulässigen NULL-Werte für `USP_WriteBinaryFile @Hilfe=1`. Dies ist ein begrenzter Help-Nachweis, kein vollständiger Modulnachweis.

Der nachfolgende Caller-Dateischreibaufruf scheiterte mit `51540/1`; seine konkrete Providerursache wurde für diesen damaligen Stand getrennt untersucht. Alle eigenen Testressourcen wurden bereinigt; jeweils eine separate frische Prüfung bestätigte dies. Für diesen damaligen Stand waren Caller-/NTFS-/I/O-Nachweise noch offen. Die fehlgeschlagenen Gesamtläufe werden nicht als Erfolg gewertet.

Der .NET-Framework-4.8-Build und der statische Vertrag waren im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 erfolgreich. Dies ist kein Windows-SQL-Server-/NTFS-Runtime-Nachweis.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater ausgewählter Windows-Caller-/NTFS-Lauf`
- Scope: SQL Server 2025/CU8 Windows; 16 Pflichtfälle erfolgreich: neun öffentliche Prozeduren, Windows-/SQL-Authentifizierung, Caller-/ServiceAccount-NTFS-Verweigerungen, Binary-/UTF-8-/UTF-16-LE-I/O, NoOverwrite/Overwrite und Bereinigung nach Schreib-/Encodingfehlern. Zusätzlicher Race-Fall NOT_OBSERVED. Drei eigene Fixture-ACLs und ein Readonly-Attribut zurückgesetzt; eigene DB/Root/Trustbereinigung und separate frische Prüfung bestanden. Keine Konfigurations-, SQL-Rechte- oder Owneränderungen. Keine direkte CLR-/vollständige Matrix-/ZIP-Dateizugriffsqualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## NoOverwrite: begrenzter Offline-Nachweis 2026-10-03

Der NoOverwrite-Providerstand vor der Streaming-Identitätskorrektur bestand den .NET-Framework-4.8-Projektbuild und die kanonische Releaseartefakt-Erzeugung. Die historische private Helperqualifikation besteht neun synthetische Fälle mit 254 Assertions: vorhandenes und während des Schreibens erzeugtes Ziel bei NoOverwrite, leere Ausgabe, Overwrite=true und eigene Staging-Bereinigung bei Writefehler. Dies belegt weder SQL-Caller-Impersonation noch NTFS-ACLs oder Power-Loss-Verhalten.

Der neue [Fixed-only-Test](./Framework/README.md) kompiliert ausschließlich den aktuellen Provider und Harness aus gebundenen Sourcebytes. Seine Ausführung vor der Streaming-Identitätskorrektur bestand am 2026-10-03 neun Fälle/254 Assertions; der vollständige Witness, tatsächlicher Exit0, eigene Bereinigung und abschließende Pins wurden geprüft. Vier tatsächliche private Prozesskontrollen bestanden Nonzero, Timeout, Capturegrenze und Postpin-Drift einschließlich beendeter/disposierter eigener Children und fester Fehlercodes. Die elf synthetischen Witness-Kontrollen bleiben ein getrenntes Parser-Prädikat, keine Prozessausführung. Aktuelle CI wird separat am exakten PR-Head nachgewiesen. Neue Binary-/Caller-/NTFS-Runtimequalifikation bleibt offen. Historische Evidenz oben bleibt erhalten.

## Streaming-Identitätskorrektur — begrenzte Offline-Qualifikation

Der neue Sourcestand liest gestreamte SQL-Inhalte außerhalb der Caller-Impersonation und verwendet dieselbe erfasste Identität für sämtliche Dateioperationen einschließlich eigener Bereinigung. Der [Framework-Harness](./Framework/README.md) enthält zusätzlich sieben begrenzte Sequenz-/Fehlerfälle. Ein privater, begrenzter C#-Sourcebuild und der sourcegebundene Frameworklauf dieses Stands bestanden am 2026-10-03. Der Frameworklauf bestätigte neun NoOverwrite-Fälle und sieben zusätzliche Copy-/Staging-Sequenzfälle mit synthetischem Executor. Er führt keine tatsächliche Windows-Identität aus und qualifiziert daher weder Enter/Undo/Poison noch SQL-gestreamte Inhalte oder NTFS. Ein aktueller vollständiger Projektbuild samt kanonischem Releaseartefakt und native Windows-Caller-/NTFS-Regression bleiben offen. Die vorherigen erfolgreichen Offline- und Help-Nachweise sowie fehlgeschlagenen Gesamtläufe bleiben getrennte historische Evidenz.
## Requestbezogene Caller-Authentifizierung — Sourcekorrektur

Alle neun CLR-Einstiegspunkte verwenden im Caller-Pfad dieselbe Authentifizierungspruefung. Eine Contextconnection liest vor Impersonation `CONNECTIONPROPERTY('auth_scheme')`; Connection und Command sind vor der Identity-Erfassung vollstaendig disposed. Nur die exakt ordinalen Windows-Modi `NTLM`, `KERBEROS`, `DIGEST`, `BASIC` und `NEGOTIATE` zusammen mit einer nichtleeren Windows-Identity werden akzeptiert. SQL-Authentifizierung, NULL und unbekannte Werte werden mit dem bestehenden `CallerWindowsAuthenticationRequired` abgewiesen. `ServiceAccount` bleibt ausdruecklicher Opt-in; es gibt keinen Fallback, keine DMV-/Sichtrechte-Abhaengigkeit und keine neue API.

[Microsofts CONNECTIONPROPERTY-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/connectionproperty-transact-sql?view=sql-server-ver17) beschreibt diese requestbezogenen Modi. Der vorbereitete Frameworktest ruft nur das echte reine Auth-Praedikat mit fuenf erlaubten und zehn abgewiesenen synthetischen Werten auf. Die neun NoOverwrite- und sieben Streaming-Faelle bleiben erhalten. Die vorherige Sourcevorbereitung und ihre damaligen Nachweisgrenzen bleiben historisch. Der aktuelle Guard bestand anschließend eine private native Zwei-Fall-Authentifizierungsprüfung auf SQL Server 2025/CU8 unter Windows: Windows-Authentifizierung (NTLM) schrieb über `USP_WriteBinaryFile` im Caller-Modus genau drei synthetische Bytes; SQL-Authentifizierung wurde mit `51540/1` und `CallerWindowsAuthenticationRequired` vor Datei- oder Staging-I/O abgewiesen. Eigene DB-, Root- und Trustbereinigung sowie eine separate frische Prüfung bestanden; Konfiguration, Rechte und Owner blieben unverändert. Dies ist ausschließlich der begrenzte Auth-Probe-Nachweis. Vollständige direkte CLR-/RunAs- und alle neun EntryPoint-Nachweise, NTFS-ACL-Matrix, ServiceAccount-Regression, Races und weitere Zielsysteme bleiben offen; der Modulstatus und die unveröffentlichte Version ändern sich nicht.

## Aktueller begrenzter Nachweis 2026-10-04

Der aktuelle Provider bestand einen privaten begrenzten produktiven C#-Sourcebuild und den sourcegebundenen Frameworklauf: neun NoOverwrite-Fälle/270 Assertions sowie sieben Streaming-Fälle/188 Assertions; darin enthalten ist die reine Caller-Policyprüfung mit fünf erlaubten und zehn abgewiesenen Werten. Vollständige Captures, Exit0, eigene Bereinigung und abschließende Sourcepins wurden geprüft. Die synthetischen Sequenzfälle beweisen keine echte Impersonation.

Die private native Zwei-Fall-Authentifizierungsprüfung auf SQL Server 2025/CU8 unter Windows bestand: Windows-Caller (NTLM) schrieb drei synthetische Bytes über `USP_WriteBinaryFile`; SQL-Authentifizierung wurde mit `51540/1` und `CallerWindowsAuthenticationRequired` vor Datei-/Staging-I/O abgewiesen. Eigene DB-, Root- und Trustbereinigung und eine separate frische Prüfung bestanden, ohne Konfigurations-, Rechte- oder Owneränderungen. Dieser begrenzte Probe-Scope ist kein vollständiger Produkttest.

Aktueller kanonischer Projektbuild/Releaseartefakt, direkte CLR-/RunAs-Qualifikation aller neun Einstiegspunkte, vollständige NTFS-/Caller-/ServiceAccount-Matrix, Races, weitere Ziele und aktuelle Head-CI bleiben separate offene Gates. Status `partially validated`, Version1.0.0 und `unreleased` bleiben erhalten; frühere Nachweise sind historisch.

## Ausgewählter Caller-/NTFS-Lauf 2026-10-04

Der aktuelle Provider bestand auf SQL Server 2025/CU8 unter Windows 16 Pflichtfälle. Der Lauf verwendete alle neun öffentlichen Prozeduren und bestätigte Binary-Chunks, UTF-8 mit BOM, Transcoding nach UTF-16 LE, List/Create/Remove, die Ablehnung von SQL-Authentifizierung im Caller-Modus, Caller- und ServiceAccount-NTFS-Verweigerungen, NoOverwrite/Overwrite sowie Zielerhalt und Staging-Bereinigung nach Schreib- und Encodingfehlern. Die Caller-Identität wurde mit der authentifizierten SQL-Sitzung abgeglichen; die Caller-Verweigerungen wurden mit demselben Windows-Token gegengeprüft. Für ServiceAccount sind Produktaufrufe und Rückkehr zum unveränderten Zugriffszustand belegt, kein separater Service-Token-Test.

Der zusätzliche Race-Fall blieb `NOT_OBSERVED` und liefert keinen Race-Nachweis. Eigene Testdatenbank, Root und Trust wurden bereinigt; drei ausschließlich eigene Fixture-ACLs und ein Readonly-Attribut wurden zurückgesetzt. Eine separate frische Prüfung bestätigte die Ressourcenabsenz und Trust-Wiederherstellung. Die unabhängige Prüfung bestätigte vollständige Prozesskanäle, Exit0, beendete/disposierte Children, unveränderte Sourcepins und das exakt gebundene Journal. Es wurden keine Konfiguration, SQL-Rechte oder Owner geändert. Private Journale, Identitäten, Pfade und Runtimeausgaben bleiben außerhalb des Repositorys.

Dies qualifiziert ausschließlich den ausgewählten Lauf. Direkte CLR-/RunAs-Aufrufe, weitere Codepages und Limits, Reparse-/rekursive Delete-Fälle, Race-Beobachtung, weitere Ziele und die separate ZIP-Dateizugriffswelle bleiben offen. `partially validated` und `unreleased` bleiben erhalten.
