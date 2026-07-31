# Contract-Testmatrix: ZIP Memory CLR Extraction

| Bereich | Pflichtfall | Status |
|---|---|---|
| Build | .NET Framework 4.8; reproduzierbare Release-Artefakte | `not executed` |
| Dependencies | direkte Assemblyreferenzen nur `System` und `System.Data` | `not executed` |
| Trust | exakter SHA2-512-Hash; getrenntes administratives Opt-in | `not executed` |
| Security | `SAFE`; kein Dateisystem, Netzwerk, Prozess, `TRUSTWORTHY`, `EXTERNAL_ACCESS` oder `UNSAFE` | `not executed` |
| API | öffentliche Procedure behält Parameter, Reihenfolge und Resultset | `not executed` |
| Intern | CLR-Tabellefunktion und Assembly bleiben interne Providerartefakte | `not executed` |
| Help | vollständiger Help-Vertrag bei `@Hilfe = 1` | `not executed` |
| Stored | gültiger Method-0-Entry wird extrahiert und CRC-geprüft | `not executed` |
| Deflate | gültiger Method-8-Entry wird dekomprimiert und CRC-geprüft | `not executed` |
| Data Descriptor | Method 8 mit Flag 3 und nachgelagertem Descriptor | `not executed` |
| UTF-8 | Flag 11 dekodiert UTF-8-Namen korrekt | `not executed` |
| CP437 | Name ohne Flag 11 verwendet CP437 | `not executed` |
| Namensvergleich | ordinal, case-sensitive, unbekannter Name liefert `51322` | `not executed` |
| Duplicate Name | doppelter exakter Name liefert `51323` | `not executed` |
| Verschlüsselt | `@FailIfEncrypted = 1` liefert `51324` | `not executed` |
| Encrypted Status | `@FailIfEncrypted = 0` liefert `IsEncrypted = 1` ohne Payload | `not executed` |
| Archivlimit | hartes Limit `268435456` Bytes | `not executed` |
| Entry-Count | hartes Limit `10000` Entries | `not executed` |
| Compressed Limit | hartes Limit `134217728` Bytes | `not executed` |
| Output-Limit | `@MaxEntryBytes` vor und während Dekomprimierung | `not executed` |
| Ratio-Limit | deklarierte und tatsächliche Compression Ratio | `not executed` |
| Method | unbekannte Method und Deflate64 liefern `51327` | `not executed` |
| ZIP64 | Sentinel oder ZIP64-Strukturen liefern `51327` | `not executed` |
| Multi-Disk | Diskfelder außerhalb Single-Disk liefern `51327` | `not executed` |
| Header | Local-/Central-Name, Method und relevante Flags müssen übereinstimmen | `not executed` |
| Größenintegrität | tatsächliche Ausgabe entspricht deklarierter Größe | `not executed` |
| CRC | CRC32 wird über den tatsächlichen Payload neu berechnet | `not executed` |
| Bounded Read | Deflate darf keine Bytes außerhalb des Entry-Payloads konsumieren | `not executed` |
| ResultTable | Replace und Append über `@ResultTable`/`@KeepData` | `not executed` |
| Wiederholung | Deployment derselben Assembly ist idempotent | `not executed` |
| Upgrade | Upgrade von bekanntem Modulstand `1.0.0` auf `1.1.0` | `not executed` |
| Central | Aufruf aus Consumer-Datenbank gegen zentrale Toolbelt-Datenbank | `not executed` |
| Uninstall | Procedure, CLR-TVF und Assembly entfernt; Trust bleibt bestehen | `not executed` |
| SQL 2019 Linux | physische Engine, Compatibility 150 | `not executed` |
| SQL 2022 Linux | physische Engine, Compatibility 160 | `not executed` |
| SQL 2025 Linux | Compatibility 150, 160 und 170 | `not executed` |
| Windows Build | .NET-Framework-Build und Release-Manifest | `not executed` |
| Windows Runtime | SQL Server unter Windows | `not executed` |

`not executed` wird erst durch reproduzierbare CI- oder gezielte Release-Evidenz
ersetzt. Einzelne offene Fälle verhindern keine wahrheitsgemäße
`partially validated`-Einstufung, bleiben aber vor Release sichtbar.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206
