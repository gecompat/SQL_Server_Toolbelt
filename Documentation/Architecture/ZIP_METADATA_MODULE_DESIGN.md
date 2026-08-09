# ZIP-Metadaten-Listing (TC-2026-033)

## Status und Freigabe

Der nachfolgende V1-Vertrag wurde am 2026-08-09 mit dem Benutzer fachlich
besprochen und ausdrücklich zur Implementierung freigegeben. Die Freigabe gilt
nur für das Listing eines bereits im Speicher vorliegenden ZIP-Containers. Sie
umfasst keine Extraktion, Dekomprimierung, Archiv-Erzeugung oder Datei-I/O.

## Zweck und Modulgrenze

`toolbelt_archive.USP_ListZipEntriesFromBinary` inventarisiert das Central
Directory eines ZIP-Containers aus `varbinary(max)`. Die Capability wird als
Version `1.2.0` in das bestehende Modul `toolbelt.archive.zip-memory` und dessen
`SAFE`-Assembly aufgenommen. Der vorhandene Parserkern wird gemeinsam genutzt;
eine zweite ZIP-Parserimplementierung oder Assembly ist ausgeschlossen.

## Öffentliche Signatur

```sql
CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ListZipEntriesFromBinary]
(
      @ZipArchive  varbinary(max) = NULL
    , @MaxEntries  int            = 10000
    , @ResultTable sysname        = NULL
    , @KeepData    bit            = 0
    , @Debug       tinyint        = 0
    , @Hilfe       bit            = 0
);
```

`@MaxEntries` darf zwischen `1` und dem harten Providerlimit `10000` liegen.
Das harte Archivlimit bleibt `268435456` Bytes. Dekodierte Entry-Namen sind auf
`1024` Zeichen begrenzt.

## Ergebnisvertrag

Das Resultset enthält pro Central-Directory-Entry genau eine Zeile und behält
dessen Reihenfolge bei.

| Spalte | Typ | Vertrag |
|---|---|---|
| `EntryOrdinal` | `int` | Einsbasierte Position im Central Directory. |
| `EntryName` | `nvarchar(1024)` | Exakt dekodierter, nicht normalisierter Name. |
| `IsDirectory` | `bit` | Aus einem abschließenden `/` abgeleitete Directory-Markierung. |
| `CompressedBytes` | `bigint` | Im Central Directory deklarierte komprimierte Größe. |
| `UncompressedBytes` | `bigint` | Im Central Directory deklarierte unkomprimierte Größe. |
| `CompressionMethod` | `int` | Numerischer ZIP-Methodenwert. |
| `Crc32` | `int` | Deklarierte, beim Listing nicht neu berechnete CRC32. |
| `IsEncrypted` | `bit` | Aus den General-Purpose-Flags abgeleiteter Status. |
| `IsExtractionSupported` | `bit` | Method 0 oder 8 und nicht verschlüsselt. |
| `DuplicateCount` | `int` | Anzahl ordinal und case-sensitive gleichnamiger Entries. |
| `IsPathSafe` | `bit` | Eignung als relativer Pfad für eine mögliche spätere Extraktion. |
| `PathStatus` | `varchar(32)` | `safe`, `absolute`, `drive-qualified`, `parent-traversal` oder `noncanonical`. |
| `LastModifiedAt` | `datetime2(0) NULL` | DOS-Zeit ohne Zeitzonenbehauptung; bei ungültigem Wert `NULL`. |

Ein leeres gültiges ZIP liefert ein leeres Resultset und Returncode `0`. Für
`@ResultTable` und `@KeepData` gilt der vollständige USP-Vertrag.

## Struktur-, Encoding- und Sicherheitsvertrag

- V1 unterstützt klassische Single-Disk-ZIPs und lehnt ZIP64 sowie Multi-Disk
  als nicht unterstützte Features ab.
- Flag 11 dekodiert Namen strikt als UTF-8; andernfalls wird CP437 verwendet.
- Central Directory, Offsets und Local Header werden strukturell geprüft.
  Namen, Methoden und relevante Flags müssen konsistent sein.
- Verschlüsselte Entries, unbekannte Methoden und Duplicate Names werden
  gelistet und markiert; sie sind kein Listingfehler.
- Absolute, laufwerksqualifizierte, traversierende und nicht kanonische Namen
  werden unverändert geliefert und als unsicher markiert. Listing erteilt
  niemals eine Extraktionsfreigabe.
- Payloads werden weder gelesen noch dekomprimiert. Größen und CRC32 sind daher
  deklarierte Metadaten und keine Integritätsbestätigung des Payloads.
- Ein strukturell ungültiges Archiv führt zu einem vollständigen Fehler; V1
  liefert kein partielles oder lenientes Ergebnis.

## Fehlervertrag

Der vorhandene Modulbereich `51320–51329` wird wiederverwendet:

- `51320`: ungültige Parameter;
- `51321`: ungültige oder inkonsistente ZIP-Struktur beziehungsweise Kodierung;
- `51325`: Archiv-, Entry-Anzahl- oder Namenslimit überschritten;
- `51327`: ZIP64, Multi-Disk oder anderes strukturell nicht unterstütztes Feature;
- `51329`: interner Provider oder ResultTable-Dependency fehlt beziehungsweise
  ist inkonsistent.

Unbekannte Kompressionsmethoden, Verschlüsselung, unsichere Pfade und doppelte
Namen sind beim Listing Ergebniszustände und keine Fehler.

## Alternativen und Entscheidung

Ein getrenntes Modul `toolbelt.archive.zip-metadata`, eine reine T-SQL-Lösung
und ein externer Worker wurden betrachtet. Das bestehende SAFE-CLR-Modul wird
erweitert, weil es bereits den begrenzten ZIP-Strukturparser, Trust-, Lifecycle-
und Plattformvertrag besitzt. Ein externer Worker ist für den reinen
In-memory-Vertrag unverhältnismäßig; eine zweite Parserlogik würde die
Architekturregel zur einmaligen Fachlogik verletzen.

## Tests und Risiken

Pflichtfälle sind leeres Archiv, Stored/Deflate, unbekannte Methoden,
Verschlüsselung, UTF-8/CP437, Duplicate Names, Directory-Einträge, unsichere
Pfade, ungültige Zeitstempel, Data Descriptor, beschädigte Header und Offsets,
ZIP64, Multi-Disk, Limits, direkte Ausgabe, ResultTable, lokales/zentrales
Deployment, Upgrade von `1.1.0`, Wiederholungsdeployment und Uninstall.

Die verbleibenden Risiken sind untrusted Metadaten, große Central Directories,
Encoding-Abweichungen realer ZIP-Erzeuger und die Aussagegrenze zwischen
deklarierten Metadaten und tatsächlich verifiziertem Payload. Release-Evidenz
mit zusätzlichen realen Archiven bleibt daher erforderlich.
