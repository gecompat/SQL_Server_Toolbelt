# `toolbelt_archive.USP_ListZipEntriesFromBinary`

## Zweck

Listet alle Central-Directory-Entries eines klassischen Single-Disk-ZIP aus
`varbinary(max)`. Das Objekt liest und dekomprimiert keine Payloads. Größen und
CRC32 sind deklarierte Metadaten und keine Integritätsbestätigung.

## Signatur

```sql
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary
      @ZipArchive  = @ZipArchive
    , @MaxEntries  = 10000
    , @ResultTable = NULL
    , @KeepData    = 0
    , @Debug       = 0
    , @Hilfe       = 0;
```

`@ZipArchive` ist erforderlich. `@MaxEntries` muss zwischen `1` und `10000`
liegen. Das Archivlimit beträgt `268435456` Bytes. `@ResultTable` bezeichnet
optional eine bestehende lokale Temp-Tabelle; `@KeepData = 0` ersetzt ihre
Form und Daten, `@KeepData = 1` hängt an eine kompatible Form an.

## Resultset

| Spalte | Typ | Bedeutung |
|---|---|---|
| `EntryOrdinal` | `int` | Einsbasierte Central-Directory-Position. |
| `EntryName` | `nvarchar(1024)` | Exakt dekodierter, nicht normalisierter Name. |
| `IsDirectory` | `bit` | Name endet mit `/`. |
| `CompressedBytes` | `bigint` | Deklarierte komprimierte Größe. |
| `UncompressedBytes` | `bigint` | Deklarierte unkomprimierte Größe. |
| `CompressionMethod` | `int` | Numerischer ZIP-Methodenwert. |
| `Crc32` | `int` | Deklarierte CRC32 als SQL-`int`-Bitmuster. |
| `IsEncrypted` | `bit` | Verschlüsselungsflag ist gesetzt. |
| `IsExtractionSupported` | `bit` | Unverschlüsselte Method `0` oder `8`. |
| `DuplicateCount` | `int` | Ordinal und case-sensitive gleicher Name. |
| `IsPathSafe` | `bit` | Kanonischer relativer Pfad. |
| `PathStatus` | `varchar(32)` | `safe`, `absolute`, `drive-qualified`, `parent-traversal` oder `noncanonical`. |
| `LastModifiedAt` | `datetime2(0) NULL` | DOS-Zeit ohne Zeitzonenbehauptung; ungültig ergibt `NULL`. |

Ein leeres gültiges ZIP liefert ein leeres Resultset und Returncode `0`.

## Fehler und Grenzen

- `51320`: ungültige Parameter;
- `51321`: ungültige Struktur oder Kodierung;
- `51325`: Archiv-, Entry-Anzahl- oder Namenslimit;
- `51327`: ZIP64, Multi-Disk oder nicht unterstützte Struktur;
- `51329`: Provider- oder ResultTable-Vertragsfehler.

Unbekannte Methoden, Verschlüsselung, Namensduplikate und unsichere Pfade sind
Ergebniszustände. Sie machen das Listing nicht erfolgreich extrahierbar und
erteilen insbesondere keine Freigabe für Datei-I/O.

## Berechtigung

Erforderlich ist `EXECUTE` auf der Procedure. Für `@ResultTable` wird außerdem
`EXECUTE` auf `toolbelt_core.USP_PrepareResultTable` benötigt.
