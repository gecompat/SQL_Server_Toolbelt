# toolbelt_archive.USP_ExtractZipEntryFromBinary

**Typ:** Stored Procedure mit fachlichem Einzelresultset  
**Version:** `1.1.0`  
**Status:** `implemented`; Runtime `not executed`

## Zweck

Extrahiert einen einzelnen, eindeutig benannten ZIP-Entry aus einem In-memory-
ZIP-Container (`varbinary(max)`) ohne Dateisystemzugriff. Der interne
`SAFE`-SQL-CLR-Provider unterstützt Compression Methods `0` (`Stored`) und `8`
(`Deflate`) und prüft die CRC32 des tatsächlich ausgegebenen Payloads.

## Signatur

Die öffentliche Signatur bleibt gegenüber Version `1.0.0` unverändert:

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

## Parameter

| Parameter | Vertrag |
|---|---|
| `@ZipArchive` | Nicht leer; hartes Providerlimit `268435456` Bytes. |
| `@EntryName` | Exakter ordinaler, case-sensitiver Vergleich; maximal 1024 Zeichen. UTF-8 gemäß Flag 11, sonst CP437. |
| `@MaxEntryBytes` | Limit für deklarierte und tatsächlich ausgegebene Payload-Größe; `1` bis `2147483647`. Default `104857600`. |
| `@MaxCompressionRatio` | Limit für deklarierte und tatsächliche Ratio `UncompressedBytes / CompressedBytes`; mindestens `1`. Default `200.00`. |
| `@FailIfEncrypted` | `1`: Fehler `51324`; `0`: Metadaten und `IsEncrypted=1`, aber `EntryPayload=NULL`. |
| `@ResultTable` | Optionale bestehende lokale Temp-Tabelle gemäß zentralem USP-Vertrag. |
| `@KeepData` | `0`: ResultTable ersetzen; `1`: Resultzeile anhängen. |
| `@Debug` | Standardisierter Debugparameter. |
| `@Hilfe` | `1`: ausschließlich maschinenlesbarer Help-Vertrag; keine Validierung oder Extraktion. |

## Ergebnisvertrag

Bei `@Hilfe = 0` liefert die Procedure genau eine Zeile bei Erfolg:

| Spalte | Typ | Beschreibung |
|---|---|---|
| `EntryName` | `nvarchar(1024)` | Exakter Entry-Name aus dem Central Directory. |
| `CompressedBytes` | `bigint` | Komprimierte Größe aus dem Central Directory. |
| `UncompressedBytes` | `bigint` | Deklarierte Größe, nach erfolgreicher Extraktion gegen die tatsächliche Ausgabe geprüft. |
| `CompressionMethod` | `int` | `0` (`Stored`) oder `8` (`Deflate`). |
| `Crc32` | `int NULL` | CRC32-Bitmuster des tatsächlichen Payloads. Nur beim verschlüsselten Statuspfad ohne Payload stammt der Wert ausschließlich aus den Metadaten. |
| `IsEncrypted` | `bit` | `1`, wenn der Entry als verschlüsselt markiert ist. |
| `EntryPayload` | `varbinary(max)` | Extrahierter Payload; bei erlaubtem verschlüsseltem Status `NULL`. |

Bei gesetztem `@ResultTable` wird kein fachliches `SELECT` ausgegeben; die
Resultzeile wird in die vorbereitete Ziel-Temp-Tabelle geschrieben.

## ZIP-Parsing und Integrität

Der Provider:

1. sucht und validiert den klassischen EOCD-Record;
2. prüft Central-Directory-Grenzen und maximal `10000` Entries;
3. löst den Namen ordinal eindeutig auf;
4. gleicht Local Header und Central Directory für Name, Method und relevante
   Flags ab;
5. begrenzt den komprimierten Lesestream exakt auf die deklarierte Größe;
6. dekomprimiert Method `8` mit `DeflateStream` aus `System.dll`;
7. erzwingt Output-Größe und Compression Ratio während des Lesens erneut;
8. vergleicht tatsächliche Bytezahl und neu berechnete CRC32 mit dem Central
   Directory.

## Fehlervertrag

Die Procedure verwendet den stabilen Bereich `51320–51329`:

| Nummer | Bedeutung |
|---:|---|
| `51320` | Pflichtparameter oder Grenzparameter sind ungültig. |
| `51321` | ZIP-Struktur, Headerbeziehung, Kodierung oder Stream ist ungültig beziehungsweise inkonsistent. |
| `51322` | Der angeforderte Entry wurde nicht gefunden. |
| `51323` | Der Entry-Name ist im Archiv nicht eindeutig. |
| `51324` | Entry ist verschlüsselt und laut Parameter abzulehnen. |
| `51325` | Archiv, Entry oder tatsächlicher Output überschreitet ein Größenlimit. |
| `51326` | Deklarierte oder tatsächliche Compression Ratio überschreitet das Limit. |
| `51327` | Feature nicht unterstützt, beispielsweise ZIP64, Multi-Disk oder Method außerhalb `0`/`8`. |
| `51328` | Tatsächliche Größe oder CRC32 stimmt nicht mit dem Central Directory überein. |
| `51329` | CLR-Provider oder ResultTable-Integration fehlt beziehungsweise liefert keinen gültigen Status. |

Providerfehler werden intern als Statuszeile übertragen und vom T-SQL-Wrapper
als Toolbelt-Fehler geworfen. Damit wird kein generischer CLR-Fehler `6522` als
öffentlicher Fachvertrag verwendet.

## Nicht unterstützt

- ZIP64 und Multi-Disk;
- Verschlüsselungsentschlüsselung;
- Deflate64 oder andere Methods als `0` und `8`;
- zusätzliche Central-Directory-Datensätze;
- Archiv-Erzeugung, Multi-Entry- oder Verzeichnisextraktion;
- Dateisystem-, Netzwerk- oder Prozesszugriff.

## Deployment und Berechtigungen

Die Procedure wird zusammen mit der internen CLR-Tabellefunktion und der
Assembly `Toolbelt_Archive_ZipMemory` installiert. Die Assembly ist `SAFE` und
muss vor dem Datenbankdeployment über den exakten SHA2-512-Hash serverweit
vertraut werden. Der Modulinstaller verändert weder `clr enabled` noch
`clr strict security` oder die Trust-Liste.

Für reguläre Aufrufe ist `EXECUTE` auf der Procedure erforderlich. Bei
`@ResultTable` wird zusätzlich `EXECUTE` auf
`toolbelt_core.USP_PrepareResultTable` benötigt.

## Beispiel

Siehe `../Examples/ExtractZipEntryFromBinary.sql`.
