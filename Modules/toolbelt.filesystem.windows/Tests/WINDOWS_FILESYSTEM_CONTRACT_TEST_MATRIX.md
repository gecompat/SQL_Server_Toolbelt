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

Der manuelle Test verwendet ausschließlich eine dedizierte, synthetische Teststruktur unter einem administrativ freigegebenen Root-Alias. Kein realer Pfad, Benutzername oder Testergebnis wird in das Repository geschrieben.

Der detaillierte Ablauf und die datenschutzsichere Rückmeldung stehen im [manuellen Windows-Runtime-Testplan](./Manual_Windows_Runtime_Testplan.md).

Aktuelle Evidenz: Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 auf SQL Server 2025 unter Windows; Build, Trust, Deployment, Help und SQL-Authentication-Ablehnung erfolgreich. Der Lauf `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 bestätigte kontrolliertes ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem `WorkPath`. Windows-Authentication-, NTFS-ACL- und weitere I/O-Tests bleiben offen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `Portierter NoOverwrite-Frameworktest und private Prozesskontrollen`
- Scope: Aktueller sourcegebundener Fixed-only-Harness: neun Fälle/254 Assertions, Staging-/Zielerhalt und eigene Bereinigung erfolgreich; vier private tatsächliche Prozesskontrollen für Nonzero, Timeout, Capturegrenze und Postpin-Drift erfolgreich. Aktueller Projektbuild/Releaseartefakt mit Assemblyversion1.0.0.0 ebenfalls erfolgreich. Offline-Scope ohne SQL, Caller-/NTFS-Nachweis; CI am exakten PR-Head separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## NoOverwrite-Korrektur 2026-10-03

| Kategorie | Nachweis | Status |
|---|---|---|
| Aktueller Projektbuild/Releaseartefakt | .NET Framework 4.8; unveränderte Assemblyversion1.0.0.0; exakte Binary-/Hexbindung privat geprüft | erfolgreich, Offline-Scope |
| Historischer Helper | neun synthetische Fälle, 254 Assertions; Zielerzeugung während Staging, false/true und eigene Fehlerbereinigung | erfolgreich, historischer privater Offline-Scope |
| Portierter Fixed-only-Harness | aktueller Provider; neun Fälle/254 Assertions; vollständiger Witness, tatsächlicher Exit0, eigene Bereinigung und abschließende Pins | erfolgreich, Offline-Scope 2026-10-03 |
| Private Prozesskontrollen | Nonzero, Timeout, Capturegrenze und Postpin-Drift; eigene Children beendet/disposed, feste Fehlercodes | erfolgreich, vier tatsächliche Kontrollen 2026-10-03 |
| Witness-Prädikate | elf synthetische Kontrollen; keine Prozessausführung | erfolgreich, getrennte Parserkontrolle |
| Aktuelle Windows-CI | Projektbuild, Static, Witness-Kontrollen und Fixed-only-Harness | separater Mergegate am exakten PR-Head; Nachweis im PR |
| Korrigierte Binary im SQL-Caller-/NTFS-Kontext | Windows Authentication, NTFS-ACLs und reale Veröffentlichungssemantik | not executed |

Keine allgemeine Statusaufwertung; `partially validated`, `unreleased`. Die historische Helper-Assertionzahl ist kein behauptetes Ergebnis des portierten Harness.
