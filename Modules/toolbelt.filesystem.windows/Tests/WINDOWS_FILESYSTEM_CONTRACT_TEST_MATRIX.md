# Windows Filesystem: Contract-Testmatrix

| Kategorie | Nachweis | Status |
|---|---|---|
| Build | .NET Framework 4.8, Release-Binary und SHA2-512 | erfolgreich: Manuelle Windows-CLR-Preflight-Validierung |
| Deployment | `clr enabled`, `clr strict security`, Trust, `EXTERNAL_ACCESS` | erfolgreich: Manuelle Windows-CLR-Preflight-Validierung |
| Caller | Windows Authentication, erlaubte und verweigerte NTFS-Rechte | not executed |
| ServiceAccount | Kontrolliertes Erstellen eines Verzeichnisses und Schreiben einer Textdatei mit konfiguriertem `WorkPath` | erfolgreich: `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 |
| SQL Authentication | `Caller` wird abgelehnt | erfolgreich: Manuelle Windows-CLR-Preflight-Validierung |
| Binary/Text | Chunk-Grenze, UTF-8, UTF-16 LE/BE, Windows-1252 und ungültige Bytefolge | not executed |
| Transcoding | Roundtrip und nicht repräsentierbares Zeichen | not executed |
| Filesystem | List/Create/Remove, Limits, Reparse Point, Root-Delete-Sperre | not executed |
| Atomic write | Staging-Abbruch, bestehendes Target, WorkPath | not executed |
| Recursive delete | MaxDepth/MaxEntries, Junction/Symlink und TOCTOU-Beobachtung | not executed |
| Begrenzter Delete-Frameworktest | Tatsächlicher privater Helper, zwölf kleine synthetische Nonrecursive-/Depth-/Entry-Fälle, Zielerhalt bei Abweisung, eigene nichtrekursive Bereinigung | vorbereitet; native SQL-/Reparse-/Race-/Identitätsqualifikation nicht enthalten |

Der manuelle Test verwendet ausschließlich eine dedizierte, synthetische Teststruktur unter einem administrativ freigegebenen Root-Alias. Kein realer Pfad, Benutzername oder Testergebnis wird in das Repository geschrieben.

Der detaillierte Ablauf und die datenschutzsichere Rückmeldung stehen im [manuellen Windows-Runtime-Testplan](./Manual_Windows_Runtime_Testplan.md).

Aktuelle Evidenz: Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 auf SQL Server 2025 unter Windows; Build, Trust, Deployment, Help und SQL-Authentication-Ablehnung erfolgreich. Der Lauf `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 bestätigte kontrolliertes ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem `WorkPath`. Für diesen historischen Stand blieben Windows-Authentication-, NTFS-ACL- und weitere I/O-Tests offen; den aktuellen begrenzten Nachweis beschreibt der folgende Evidenzabschnitt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater ausgewählter Windows-Caller-/NTFS-Lauf`
- Scope: SQL Server 2025/CU8 Windows; 16 Pflichtfälle erfolgreich: neun öffentliche Prozeduren, Windows-/SQL-Authentifizierung, Caller-/ServiceAccount-NTFS-Verweigerungen, Binary-/UTF-8-/UTF-16-LE-I/O, NoOverwrite/Overwrite und Bereinigung nach Schreib-/Encodingfehlern. Zusätzlicher Race-Fall NOT_OBSERVED. Drei eigene Fixture-ACLs und ein Readonly-Attribut zurückgesetzt; eigene DB/Root/Trustbereinigung und separate frische Prüfung bestanden. Keine Konfigurations-, SQL-Rechte- oder Owneränderungen. Keine direkte CLR-/vollständige Matrix-/ZIP-Dateizugriffsqualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## NoOverwrite-Korrektur 2026-10-03

| Kategorie | Nachweis | Status |
|---|---|---|
| Projektbuild/Releaseartefakt vor der Streaming-Identitätskorrektur | .NET Framework 4.8; unveränderte Assemblyversion1.0.0.0; exakte Binary-/Hexbindung privat geprüft | erfolgreich, Offline-Scope |
| Historischer Helper | neun synthetische Fälle, 254 Assertions; Zielerzeugung während Staging, false/true und eigene Fehlerbereinigung | erfolgreich, historischer privater Offline-Scope |
| Portierter Fixed-only-Harness | Providerstand vor der Streaming-Identitätskorrektur; neun Fälle/254 Assertions; vollständiger Witness, tatsächlicher Exit0, eigene Bereinigung und abschließende Pins | erfolgreich, Offline-Scope 2026-10-03 |
| Private Prozesskontrollen | Nonzero, Timeout, Capturegrenze und Postpin-Drift; eigene Children beendet/disposed, feste Fehlercodes | erfolgreich, vier tatsächliche Kontrollen 2026-10-03 |
| Witness-Prädikate | elf synthetische Kontrollen; keine Prozessausführung | erfolgreich, getrennte Parserkontrolle |
| Aktuelle Windows-CI | Projektbuild, Static, Witness-Kontrollen und Fixed-only-Harness | separater Mergegate am exakten PR-Head; Nachweis im PR |
| Korrigierte Binary im SQL-Caller-/NTFS-Kontext | Windows Authentication, NTFS-ACLs und reale Veröffentlichungssemantik | not executed |

Keine allgemeine Statusaufwertung; `partially validated`, `unreleased`. Die historische Helper-Assertionzahl ist kein behauptetes Ergebnis des portierten Harness.

## Streaming-Identitätskorrektur 2026-10-03

| Kategorie | Nachweis | Status |
|---|---|---|
| Privater C#-Sourcebuild | Gebundene aktuelle Providerquelle und feste Frameworkreferenzen; tatsächlicher Exit0 und leere Compilerkanäle | erfolgreich, begrenzter Offline-Scope |
| Aktueller Framework-Harness | Neun NoOverwrite-Fälle plus sieben Copy-/Staging-Sequenzfälle; synthetischer Executor, keine tatsächliche Windows-Identität | erfolgreich, begrenzter Offline-Scope |
| Projektbuild/kanonisches Releaseartefakt dieses Stands | Vollständige aktuelle Buildkopplung | not executed |
| Enter/Undo/Poison, SQL-gestreamte Inhalte und NTFS | Tatsächliche Caller-Identität und SQL-/Windows-Runtime | not executed |

## Aktueller begrenzter Nachweis 2026-10-04

Der Providerstand vom 2026-10-04 bestand einen privaten begrenzten produktiven C#-Sourcebuild und den sourcegebundenen Frameworklauf: neun NoOverwrite-Fälle/270 Assertions sowie sieben Streaming-Fälle/188 Assertions; darin enthalten ist die reine Caller-Policyprüfung mit fünf erlaubten und zehn abgewiesenen Werten. Vollständige Captures, Exit0, eigene Bereinigung und abschließende Sourcepins wurden geprüft. Die synthetischen Sequenzfälle beweisen keine echte Impersonation.

Die private native Zwei-Fall-Authentifizierungsprüfung auf SQL Server 2025/CU8 unter Windows bestand: Windows-Caller (NTLM) schrieb drei synthetische Bytes über `USP_WriteBinaryFile`; SQL-Authentifizierung wurde mit `51540/1` und `CallerWindowsAuthenticationRequired` vor Datei-/Staging-I/O abgewiesen. Eigene DB-, Root- und Trustbereinigung und eine separate frische Prüfung bestanden, ohne Konfigurations-, Rechte- oder Owneränderungen. Dieser begrenzte Probe-Scope ist kein vollständiger Produkttest.

Aktueller kanonischer Projektbuild/Releaseartefakt, direkte CLR-/RunAs-Qualifikation aller neun Einstiegspunkte, vollständige NTFS-/Caller-/ServiceAccount-Matrix, Races, weitere Ziele und aktuelle Head-CI bleiben separate offene Gates. Status `partially validated`, Version1.0.0 und `unreleased` bleiben erhalten; frühere Nachweise sind historisch.

## Ausgewählter Caller-/NTFS-Lauf 2026-10-04

| Kategorie | Nachweis auf SQL Server 2025/CU8 Windows | Ergebnis |
|---|---|---|
| Öffentliche Prozeduren | Alle neun Prozeduren; Binary-Chunks, UTF-8/BOM, UTF-16-LE-Transcoding und List/Create/Remove | ausgewählter Scope erfolgreich |
| Caller | Windows-Identität gegen SQL-Sitzung abgeglichen; NTFS-Read-/Write-Verweigerungen mit demselben Token gegengeprüft; SQL-Authentifizierung vor I/O abgewiesen | erfolgreich |
| ServiceAccount | Explizite Read-/Write-/List-Aufrufe; eigene WorkPath-Verweigerung und Zugriff nach Wiederherstellung | erfolgreich; kein externer Service-Token-Test |
| Dateibereitstellung | Bestehendes Ziel bei NoOverwrite erhalten; Overwrite bestätigt; Zielerhalt und Staging-Bereinigung bei Schreib-/Encodingfehlern | erfolgreich |
| Cleanup | Eigene DB/Root/Trust bereinigt; drei eigene ACLs und ein Readonly-Attribut zurückgesetzt; separate frische Prüfung und unabhängige Evidenzprüfung | erfolgreich |
| Race | Ein begrenzter Versuch, Ziel während Staging anzulegen | `NOT_OBSERVED`; kein Race-PASS |

16 Pflichtfälle bestanden; ein zusätzlicher Race-Fall wurde nicht beobachtet. Direkte CLR-/RunAs-Aufrufe, weitere Codepages und Limits, Reparse-/rekursive Delete-Fälle, weitere Ziele und ZIP-Dateizugriff sind dadurch nicht qualifiziert. Keine Konfigurations-, SQL-Rechte- oder Owneränderungen; Status `partially validated` und `unreleased` unverändert. Frühere Evidenzabschnitte bleiben historische Nachweise.
