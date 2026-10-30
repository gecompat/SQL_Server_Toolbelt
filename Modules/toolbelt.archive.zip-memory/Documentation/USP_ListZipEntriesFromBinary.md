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

Die Pfadklassifikation weist auch laufwerksrelative Namen wie `C:file` als
`drive-qualified` und das alleinstehende `..` als `parent-traversal` aus.
`.` sowie führende oder abschließende Dotsegmente (`./file`, `a/.`) sind
`noncanonical`. Diese Fälle liefern `IsPathSafe=0`; gewöhnliche relative
Namen und Verzeichniseinträge mit abschließendem `/` behalten `safe`.

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

Das geprüfte schmale Callerprofil benötigt `EXECUTE` auf dieser Procedure und
`SELECT` auf `toolbelt_archive.TVF_InternalListZipEntriesClr`. Für
`@ResultTable` ist zusätzlich `EXECUTE` auf
`toolbelt_core.USP_PrepareResultTable` erforderlich. Dies ist das im
[ZIP-Callerbericht](../../../Releases/1.0.0/ZIP-CALLER-PROFILE.md) geprüfte
Objektprofil; es behauptet keine mathematische Minimalität oder Ausschließung
anderer möglicher Profile.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..10000 Central-Directory-Entries, Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zip).
