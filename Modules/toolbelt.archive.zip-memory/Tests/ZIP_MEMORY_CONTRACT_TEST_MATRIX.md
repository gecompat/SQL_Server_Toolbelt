# Contract-Testmatrix: ZIP Memory CLR Inspection

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Pflichtfall | Status |
|---|---|---|
| Build | .NET Framework 4.8; reproduzierbare Release-Artefakte | `success` |
| Dependencies | direkte Assemblyreferenzen nur `System` und `System.Data` | `success` |
| Trust | exakter SHA2-512-Hash; getrenntes administratives Opt-in | `success` |
| Security | `SAFE`; kein Dateisystem, Netzwerk, Prozess, `TRUSTWORTHY`, `EXTERNAL_ACCESS` oder `UNSAFE` | `success` |
| API | öffentliche Procedure behält Parameter, Reihenfolge und Resultset | `success` |
| Listing API | Metadaten-Procedure behält Parameter, Reihenfolge und Resultset | `success` |
| Intern | CLR-Tabellefunktion und Assembly bleiben interne Providerartefakte | `success` |
| Help | vollständiger Help-Vertrag bei `@Hilfe = 1` | `success` |
| Stored | gültiger Method-0-Entry wird extrahiert und CRC-geprüft | `success` |
| Deflate | gültiger Method-8-Entry wird dekomprimiert und CRC-geprüft | `success` |
| Data Descriptor | Method 8 mit Flag 3 und nachgelagertem Descriptor | `success` |
| UTF-8 | Flag 11 dekodiert UTF-8-Namen korrekt | `success` |
| CP437 | Name ohne Flag 11 verwendet CP437 | `success` |
| Namensvergleich | ordinal, case-sensitive, unbekannter Name liefert `51322` | `success` |
| Duplicate Name | doppelter exakter Name liefert `51323` | `success` |
| Verschlüsselt | `@FailIfEncrypted = 1` liefert `51324` | `success` |
| Encrypted Status | `@FailIfEncrypted = 0` liefert `IsEncrypted = 1` ohne Payload | `success` |
| Archivlimit | hartes Limit `268435456` Bytes | `not executed` |
| Entry-Count | hartes Limit `10000` Entries | `not executed` |
| Compressed Limit | hartes Limit `134217728` Bytes | `not executed` |
| Output-Limit | `@MaxEntryBytes` vor und während Dekomprimierung | `success` |
| Ratio-Limit | deklarierte und tatsächliche Compression Ratio | `success` |
| Method | unbekannte Method und Deflate64 liefern `51327` | `success` |
| ZIP64 | Sentinel oder ZIP64-Strukturen liefern `51327` | `success` |
| Multi-Disk | Diskfelder außerhalb Single-Disk liefern `51327` | `success` |
| Header | Local-/Central-Name, Method und relevante Flags müssen übereinstimmen | `success` |
| Größenintegrität | tatsächliche Ausgabe entspricht deklarierter Größe | `success` |
| CRC | CRC32 wird über den tatsächlichen Payload neu berechnet | `success` |
| Leeres ZIP | gültiges leeres ZIP liefert leeres Resultset und Returncode 0 | `success` |
| Listing | Central-Directory-Reihenfolge und deklarierte Metadaten | `success` |
| Listing Status | unbekannte Methode und Verschlüsselung werden markiert, nicht abgelehnt | `success` |
| Listing Names | ordinal/case-sensitive DuplicateCount; UTF-8 und CP437 | `success` |
| Listing Paths | Directory, safe, absolute, drive-qualified, traversal und noncanonical | `success` |
| Listing Time | gültige DOS-Zeit; ungültiger Wert wird NULL | `success` |
| Bounded Read | Deflate darf keine Bytes außerhalb des Entry-Payloads konsumieren | `success` |
| ResultTable | Replace und Append über `@ResultTable`/`@KeepData` | `success` |
| Wiederholung | Deployment derselben Assembly ist idempotent | `success` |
| Upgrade | Upgrade von bekanntem Modulstand `1.1.0` auf `1.2.0` | `partially validated` |
| Central | Aufruf aus Consumer-Datenbank gegen zentrale Toolbelt-Datenbank | `success` |
| Uninstall | Procedure, CLR-TVF und Assembly entfernt; Trust bleibt bestehen | `success` |
| SQL 2019 Linux | physische Engine, Compatibility 150 | `success` |
| SQL 2022 Linux | physische Engine, Compatibility 160 | `success` |
| SQL 2025 Linux | Compatibility 150, 160 und 170 | `success` |
| Windows Build | .NET-Framework-Build und Release-Manifest | `success` |
| Windows Runtime | SQL Server unter Windows | `not executed` |

`not executed` wird erst durch reproduzierbare CI- oder gezielte Release-Evidenz
ersetzt. `partially validated` beim Upgrade bezeichnet den erfolgreichen
synthetischen Versionsmarker-Pfad ohne vollständiges vorheriges 1.1.0-Deployment.
Einzelne offene Fälle verhindern keine wahrheitsgemäße
`partially validated`-Einstufung des Moduls, bleiben aber vor Release sichtbar.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453
