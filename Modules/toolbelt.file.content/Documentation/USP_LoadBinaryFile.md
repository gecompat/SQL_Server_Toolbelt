# toolbelt_file.USP_LoadBinaryFile

## Zweck

Liest eine Datei als `varbinary(max)` über `OPENROWSET(BULK...)`.
Der Pfad muss absolut sein und unter einem Eintrag der Root-Allowlist
`toolbelt_file.FileContentRootAllowlist` liegen.

## Signatur

```sql
CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadBinaryFile]
(
      @FilePath  nvarchar(4000)
    , @MaxBytes  bigint       = NULL
    , @Debug     tinyint      = 0
    , @Hilfe     bit          = 0
)
```

## Parameter

| Parameter | Typ | Pflicht | Standard | Beschreibung |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | ja | - | Absoluter Pfad; UNC erlaubt. |
| `@MaxBytes` | `bigint` | nein | `NULL` | Optionales Größenlimit. |
| `@Debug` | `tinyint` | nein | `0` | Reserviert. |
| `@Hilfe` | `bit` | nein | `0` | `1` gibt Help-Resultset aus. |

## Resultset

| Spalte | Typ | Beschreibung |
|---|---|---|
| `Content` | `varbinary(max)` | Dateiinhalt oder `NULL` bei Fehler. |
| `BytesRead` | `bigint` | Gelesene Bytes. |
| `IsValid` | `bit` | `1` bei Erfolg, `0` bei fachlichem Fehler. |
| `ValidationCode` | `int` | Fachlicher Fehlercode oder `NULL`. |
| `ValidationMessage` | `nvarchar(4000)` | Fehlermeldung oder `NULL`. |

## Fehlercodes

| Code | Bedeutung |
|---|---|
| `51320` | Ungültiger oder leerer Dateipfad. |
| `51321` | Pfad liegt außerhalb der Root-Allowlist. |
| `51322` | Pfad enthält verbotene relative Segmente oder Traversal. |
| `51323` | Datei überschreitet `@MaxBytes`. |

## Beispiel

```sql
EXEC toolbelt_file.USP_LoadBinaryFile
      @FilePath = N'/var/opt/mssql/data/allowed/sample.bin';
```

## Berechtigungen

- `EXECUTE` auf `toolbelt_file.USP_LoadBinaryFile`
- Lesezugriff auf den Dateipfad
- `ADMINISTER BULK OPERATIONS` oder `ad hoc distributed queries`
