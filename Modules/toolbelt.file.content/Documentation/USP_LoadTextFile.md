# toolbelt_file.USP_LoadTextFile

## Zweck

Liest eine Textdatei als `nvarchar(max)` über `OPENROWSET(BULK...)`.
Erkennt Byte Order Marks (BOM) und decodiert entsprechend. Dateien ohne BOM
werden mit `@FallbackEncoding` gelesen.

## Signatur

```sql
CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadTextFile]
(
      @FilePath          nvarchar(4000)
    , @FallbackEncoding  nvarchar(128) = N'Windows-1252'
    , @MaxBytes          bigint        = NULL
    , @Debug             tinyint       = 0
    , @Hilfe             bit           = 0
)
```

## Parameter

| Parameter | Typ | Pflicht | Standard | Beschreibung |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | ja | - | Absoluter Pfad; UNC erlaubt. |
| `@FallbackEncoding` | `nvarchar(128)` | nein | `Windows-1252` | Codepage für BOM-lose Dateien. |
| `@MaxBytes` | `bigint` | nein | `NULL` | Optionales Größenlimit. |
| `@Debug` | `tinyint` | nein | `0` | Reserviert. |
| `@Hilfe` | `bit` | nein | `0` | `1` gibt Help-Resultset aus. |

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
| `EF BB BF` | UTF-8 | `OPENROWSET(BULK..., SINGLE_CLOB)` + `CAST` |
| `FF FE` | UTF-16-LE | `OPENROWSET(BULK..., SINGLE_NCLOB)` |
| `FE FF` | UTF-16-BE | nicht unterstützt |
| `00 00 FE FF` | UTF-32-LE | nicht unterstützt |
| `FF FE 00 00` | UTF-32-BE | nicht unterstützt |
| kein BOM | `@FallbackEncoding` | `OPENROWSET(BULK..., SINGLE_CLOB)` + `CAST` |

## Fehlercodes

| Code | Bedeutung |
|---|---|
| `51320` | Ungültiger oder leerer Dateipfad. |
| `51321` | Pfad liegt außerhalb der Root-Allowlist. |
| `51322` | Pfad enthält verbotene relative Segmente oder Traversal. |
| `51323` | Datei überschreitet `@MaxBytes`. |
| `51324` | Fallback-Encoding wird nicht unterstützt. |
| `51325` | Encoding wird nicht unterstützt (UTF-16-BE, UTF-32). |

## Beispiel

```sql
EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = N'/var/opt/mssql/data/allowed/sample.txt';
```

## Berechtigungen

- `EXECUTE` auf `toolbelt_file.USP_LoadTextFile`
- Lesezugriff auf den Dateipfad
- `ADMINISTER BULK OPERATIONS` oder `ad hoc distributed queries`
