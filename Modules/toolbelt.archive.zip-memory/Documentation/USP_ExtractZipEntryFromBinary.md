# toolbelt_archive.USP_ExtractZipEntryFromBinary

**Typ:** Stored Procedure mit fachlichem Einzelresultset
**Version:** `1.0.0`
**Status:** `implemented`; Runtime `not executed`

## Zweck

Extrahiert einen einzelnen benannten ZIP-Eintrag aus einem in-memory
ZIP-Container (`varbinary(max)`) ohne Dateisystemzugriff.

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

## Ergebnisvertrag

Bei `@Hilfe = 0` liefert die Procedure genau eine Zeile bei Erfolg:

| Spalte | Typ | Beschreibung |
|---|---|---|
| `EntryName` | `nvarchar(1024)` | Exakter Entry-Name aus dem Central Directory. |
| `CompressedBytes` | `bigint` | Komprimierte Groesse laut ZIP-Metadaten. |
| `UncompressedBytes` | `bigint` | Unkomprimierte Groesse laut ZIP-Metadaten. |
| `CompressionMethod` | `int` | ZIP Compression Method. Version 1.0.0 akzeptiert nur `0` fuer Payload-Extraktion. |
| `Crc32` | `int NULL` | CRC32-Wert aus ZIP-Metadaten. |
| `IsEncrypted` | `bit` | `1` falls Entry als verschluesselt markiert ist. |
| `EntryPayload` | `varbinary(max)` | Extrahierter Payload. Bei `@FailIfEncrypted = 0` und verschluesseltem Entry `NULL`. |

Bei gesetztem `@ResultTable` wird kein fachliches `SELECT` ausgegeben; die
Resultzeile wird in die vorbereitete Ziel-Temp-Tabelle geschrieben.

## Help- und Parametervertrag

`@Hilfe`, `@Debug`, `@ResultTable` und `@KeepData` folgen dem USP-Vertrag aus
`Documentation/Standards/USP_CONTRACT.md`.

## Fehlervertrag

Die Procedure verwendet den Bereich `51320-51329`:

| Nummer | Bedeutung |
|---:|---|
| `51320` | Pflichtparameter oder Grenzparameter sind ungueltig. |
| `51321` | ZIP-Struktur ist ungueltig oder inkonsistent. |
| `51322` | Der angeforderte Entry wurde nicht gefunden. |
| `51323` | Der Entry-Name ist im Archiv nicht eindeutig. |
| `51324` | Entry ist verschluesselt und laut Parameter abzulehnen. |
| `51325` | Entry ueberschreitet `@MaxEntryBytes`. |
| `51326` | Entry ueberschreitet `@MaxCompressionRatio`. |
| `51327` | Compression Method ist fuer Payload-Extraktion nicht unterstuetzt. |
| `51328` | Header- oder CRC-Konsistenz verletzt den Vertragsrahmen. |
| `51329` | ResultTable-Integration ist nicht verfuegbar oder nicht ausfuehrbar. |

## Sicherheit

- Keine Dateisystem-I/O, keine Pfadauflosung, keine rekursive Entpackung.
- Harte Limits gegen uebergrosse Entries und unplausible Kompressionsverhaeltnisse.
- Encrypted Entries werden kontrolliert behandelt.

## Beispiel

Siehe `../Examples/ExtractZipEntryFromBinary.sql`.
