# toolbelt_file.USP_LoadTextFile

## Zweck

Liest eine Textdatei als `nvarchar(max)` über `OPENROWSET(BULK...)`.
Erkennt Byte Order Marks (BOM) und decodiert entsprechend. Dateien ohne BOM
werden mit `@FallbackEncoding` gelesen.
Der Pfad muss unter einem aktiven Root der `FileContentRootAllowlist` liegen.
Der Root gilt literal und case-sensitiv an einer Verzeichnisgrenze;
ein abschließender Slash ist optional. Geschwisterpräfixe und durch
`%`, `_` oder Klammern erweiterte Suchmuster werden nicht freigegeben.

## Signatur

```sql
CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadTextFile]
(
      @FilePath          nvarchar(4000) = NULL
    , @FallbackEncoding  nvarchar(128) = N'Windows-1252'
    , @MaxBytes          bigint        = NULL
    , @ResultTable       sysname       = NULL
    , @KeepData          bit           = 0
    , @Debug             tinyint       = 0
    , @Hilfe             bit           = 0
)
```

## Parameter

Der technische `NULL`-Default für `@FilePath` ermöglicht `@Hilfe = 1`; im
normalen Aufruf bleibt der Pfad fachlich erforderlich. Hilfe wird vor
Pfadnormalisierung und Dateizugriff zurückgegeben.

Die Standardparameter stehen jetzt in der vereinbarten Reihenfolge
`@ResultTable, @KeepData, @Debug, @Hilfe`. Bisherige positionsgebundene
Aufrufe mit Debug-/Hilfe-Werten müssen auf benannte Parameter umgestellt
werden; benannte Aufrufe behalten ihre Bedeutung.

| Parameter | Typ | Pflicht | Standard | Beschreibung |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | ja | `NULL` (technischer Help-Default) | Bei normalem Aufruf absoluter Pfad; UNC erlaubt. |
| `@FallbackEncoding` | `nvarchar(128)` | nein | `Windows-1252` | Codepage für BOM-lose Dateien. |
| `@MaxBytes` | `bigint` | nein | `NULL` | Optionales Größenlimit. |
| `@Debug` | `tinyint` | nein | `0` | Diagnosemeldungen des ResultTable-Helpers beim Routing; keine zusätzlichen fachlichen Resultsets. |
| `@Hilfe` | `bit` | nein | `0` | `1` gibt Help-Resultset aus. |
| `@ResultTable` | `sysname` | nein | `NULL` | Optionaler Name einer lokalen Temp-Tabelle für die Ergebniszeile. |
| `@KeepData` | `bit` | nein | `0` | Mit ResultTable: 1 erhält bestehende Zeilen; 0 ersetzt Inhalt und Shape gemäß ResultTable-Vertrag. |

`toolbelt.core.result-table` Version `1.0.0` wird nur für `@ResultTable`
benötigt. Das Ziel wird innerhalb derselben Transaktion vor dem Datei-I/O
präpariert. Ein Datei-/Provider- oder Decoderfehler rollt die ResultTable-
Änderung zurück; eine vorhandene Callertransaktion wird über einen Savepoint
behandelt.

## Resultset

| Spalte | Typ | Beschreibung |
|---|---|---|
| `Content` | `nvarchar(max)` | Textinhalt oder `NULL` bei Fehler. |
| `BytesRead` | `bigint` | Gelesene Bytes (geschätzt aus `DATALENGTH`). |
| `EncodingDetected` | `nvarchar(128)` | Erkanntes Encoding. |
| `BomPresent` | `bit` | `1`, wenn BOM vorhanden. |
| `IsValid` | `bit` | `1` bei Erfolg, `0` bei fachlichem Fehler. |
| `ValidationCode` | `int` | Fachlicher Fehlercode oder `NULL`. |
| `ValidationMessage` | `nvarchar(4000)` | Fehlermeldung oder `NULL`. |

## Unterstützte Encodings

| BOM | Encoding | Lesemodus |
|---|---|---|
| `EF BB BF` | UTF-8 | UTF-8-Decoder des einmaligen `SINGLE_BLOB`-Snapshots |
| `FF FE` | UTF-16-LE | UTF-16-LE-Decoder desselben Snapshots |
| `FE FF` | UTF-16-BE | nicht unterstützt |
| `00 00 FE FF` | UTF-32-BE | nicht unterstützt |
| `FF FE 00 00` | UTF-32-LE | nicht unterstützt |
| kein BOM | `@FallbackEncoding` | Explizite Windows-1252-Dekodierung desselben Snapshots |

## Fehlercodes

| Code | Bedeutung |
|---|---|
| `51320` | Ungültiger oder leerer Dateipfad. |
| `51321` | Pfad liegt außerhalb der Root-Allowlist. |
| `51322` | Pfad enthält verbotene relative Segmente oder Traversal. |
| `51323` | Datei überschreitet `@MaxBytes`. |
| `51324` | Fallback-Encoding wird nicht unterstützt. |
| `51325` | Encoding wird nicht unterstützt (UTF-16-BE, UTF-32). |
| `51326` | `OPENROWSET`-/Decoderfehler, einschließlich ungültiger UTF-8-Bytes oder ungerader UTF-16-LE-Bytelänge. |

## Beispiel

```sql
EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = N'/var/opt/mssql/data/allowed/sample.txt';

CREATE TABLE #TextResult (Content nvarchar(max) NULL, BytesRead bigint NOT NULL,
    EncodingDetected nvarchar(128) NULL, BomPresent bit NOT NULL, IsValid bit NOT NULL,
    ValidationCode int NULL, ValidationMessage nvarchar(4000) NULL);
EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = N'/var/opt/mssql/data/allowed/sample.txt'
    , @ResultTable = N'#TextResult';
```

## Berechtigungen

- `EXECUTE` auf `toolbelt_file.USP_LoadTextFile`
- Bei `@ResultTable`: zusätzlich `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable`
- Lesezugriff auf den Dateipfad
- `ADMINISTER BULK OPERATIONS` oder `ad hoc distributed queries`

## Byte-Snapshot ab 2026-10-15

SC-040: USP_LoadTextFile verwendet genau einen SINGLE_BLOB-Snapshot. Bytezahl, BOM und Inhalt stammen aus derselben Aufnahme. UTF-8/UTF-16-LE-BOM wird vor Dekodierung entfernt; UTF-8 wird mit expliziter UTF8-Collation und binärem Roundtrip geprüft, UTF-16-LE verlangt gerade Bytezahl. Windows-1252 wird mit expliziter 1252-Collation auch auf Linux dekodiert. UTF-16-BE/UTF-32 bleiben ausgeschlossen. MaxBytes schützt nach der ersten Aufnahme; keine vorgezogene Heapgarantie.
