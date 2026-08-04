# Windows Filesystem: Contract-Testmatrix

| Kategorie | Nachweis | Status |
|---|---|---|
| Build | .NET Framework 4.8, Release-Binary und SHA2-512 | erfolgreich: Manuelle Windows-CLR-Preflight-Validierung |
| Deployment | `clr enabled`, `clr strict security`, Trust, `EXTERNAL_ACCESS` | erfolgreich: Manuelle Windows-CLR-Preflight-Validierung |
| Caller | Windows Authentication, erlaubte und verweigerte NTFS-Rechte | not executed |
| ServiceAccount | Expliziter Modus mit kontrolliertem Testroot | not executed |
| SQL Authentication | `Caller` wird abgelehnt | erfolgreich: Manuelle Windows-CLR-Preflight-Validierung |
| Binary/Text | Chunk-Grenze, UTF-8, UTF-16 LE/BE, Windows-1252 und ungültige Bytefolge | not executed |
| Transcoding | Roundtrip und nicht repräsentierbares Zeichen | not executed |
| Filesystem | List/Create/Remove, Limits, Reparse Point, Root-Delete-Sperre | not executed |
| Atomic write | Staging-Abbruch, bestehendes Target, WorkPath | not executed |
| Recursive delete | MaxDepth/MaxEntries, Junction/Symlink und TOCTOU-Beobachtung | not executed |

Der manuelle Test verwendet ausschließlich eine dedizierte, synthetische Teststruktur unter einem administrativ freigegebenen Root-Alias. Kein realer Pfad, Benutzername oder Testergebnis wird in das Repository geschrieben.

Der detaillierte Ablauf und die datenschutzsichere Rückmeldung stehen im [manuellen Windows-Runtime-Testplan](./Manual_Windows_Runtime_Testplan.md).

Aktuelle Evidenz: Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 auf SQL Server 2025 unter Windows; Build, Trust, Deployment, Help und SQL-Authentication-Ablehnung erfolgreich. Windows-Authentication-, NTFS-ACL- und I/O-Tests bleiben offen.
