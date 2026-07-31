# toolbelt_archive.USP_ExtractZipEntryFromBinary

**Typ:** Stored Procedure mit fachlichem Einzelresultset  
**Version:** `1.1.0`  
**Status:** `implemented`; `partially validated`

## Zweck

Extrahiert einen einzelnen, eindeutig benannten ZIP-Entry aus einem In-memory-
ZIP-Container (`varbinary(max)`). Der interne `SAFE`-SQL-CLR-Provider
unterstützt Methods `0` (`Stored`) und `8` (`Deflate`) und prüft die CRC32 des
tatsächlich ausgegebenen Payloads.

## Signatur

```sql
CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ExtractZipEntryFromBinary]
(
      @ZipArchive          varbinary(max) = NULL
    , @EntryName           nvarchar(1024) = NULL
    , @MaxEntryBytes       bigint         = 104857600
    , @MaxCompressionRatio decimal(9,2)   = 200.00
    , @FailIfEncrypted     bit            = 1
    , @ResultTable         sysname        = NULL
    , @KeepData            bit            = 0
    , @Debug               tinyint        = 0
    , @Hilfe               bit            = 0
)
```

Die öffentliche Signatur ist gegenüber Version `1.0.0` unverändert.

## Ergebnis

| Spalte | Typ | Bedeutung |
|---|---|---|
| `EntryName` | `nvarchar(1024)` | Exakter Name aus dem Central Directory. |
| `CompressedBytes` | `bigint` | Komprimierte Größe. |
| `UncompressedBytes` | `bigint` | Deklarierte und bei Extraktion bestätigte Payload-Größe. |
| `CompressionMethod` | `int` | `0` oder `8`. |
| `Crc32` | `int NULL` | CRC32-Bitmuster des tatsächlichen Payloads. |
| `IsEncrypted` | `bit` | Verschlüsselungsflag. |
| `EntryPayload` | `varbinary(max)` | Extrahierter Payload oder `NULL` beim erlaubten verschlüsselten Status. |

Bei `@ResultTable` wird die Zeile in die vorbereitete lokale Temp-Tabelle
geschrieben und kein fachliches `SELECT` ausgegeben.

## Semantik

- Entry-Namen werden ordinal und case-sensitive verglichen.
- Flag 11 verwendet UTF-8, sonst CP437.
- Duplicate Names liefern Fehler `51323`.
- `@FailIfEncrypted = 1` liefert Fehler `51324`.
- `@FailIfEncrypted = 0` liefert Metadaten und `IsEncrypted = 1`, aber keinen
  Payload.
- Größe und Compression Ratio werden vor und während des Lesens begrenzt.
- Reale Bytezahl und neu berechnete CRC32 müssen den Metadaten entsprechen.

## Fehlervertrag

| Nummer | Bedeutung |
|---:|---|
| `51320` | Ungültige Parameter. |
| `51321` | Ungültige oder inkonsistente ZIP-Struktur/Kodierung. |
| `51322` | Entry nicht gefunden. |
| `51323` | Duplicate Name. |
| `51324` | Verschlüsselter Entry abgelehnt. |
| `51325` | Größenlimit überschritten. |
| `51326` | Compression-Ratio-Limit überschritten. |
| `51327` | Nicht unterstütztes Feature, etwa ZIP64, Multi-Disk oder Method. |
| `51328` | Tatsächliche Größe oder CRC32 stimmt nicht. |
| `51329` | Interner Provider oder ResultTable-Dependency fehlt/ist inkonsistent. |

Erwartete Providerfehler werden intern als Status übertragen und vom T-SQL-
Wrapper als Toolbelt-Fehler geworfen. CLR-Fehler `6522` ist kein öffentlicher
Fachvertrag.

## Nicht unterstützt

ZIP64, Multi-Disk, Verschlüsselungsentschlüsselung, Deflate64, weitere Methods,
zusätzliche Central-Directory-Datensätze, Archiv-Erzeugung, Multi-Entry- oder
Verzeichnisextraktion sowie Dateisystem-, Netzwerk- oder Prozesszugriff.

## Deployment

Die Procedure wird gemeinsam mit
`toolbelt_archive.TVF_InternalExtractZipEntryClr` und der `SAFE`-Assembly
`Toolbelt_Archive_ZipMemory` installiert. Vor dem Datenbankdeployment muss der
exakte SHA2-512-Hash serverweit freigegeben sein. Der Installer verändert keine
Instanzoption und keine Trust-Liste.

## Evidenz

GitHub-Actions-Lauf `30615544206` war erfolgreich auf SQL Server 2019, 2022 und
2025 unter Linux sowie für den Windows-.NET-Framework-4.8-Build. Windows-SQL-
Server-Runtime und Release-Extremgrößenläufe bleiben offen.

## Beispiel

Siehe `../Examples/ExtractZipEntryFromBinary.sql`.
