# toolbelt_file.USP_LoadBinaryFile

## Zweck

Liest eine Datei als `varbinary(max)` über `OPENROWSET(BULK...)`.
Der Pfad muss absolut sein und unter einem Eintrag der Root-Allowlist
`toolbelt_file.FileContentRootAllowlist` liegen.
Der Root gilt literal und case-sensitiv an einer Verzeichnisgrenze;
ein abschließender Slash ist optional. Geschwisterpräfixe und durch
`%`, `_` oder Klammern erweiterte Suchmuster werden nicht freigegeben.

## Signatur

```sql
CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadBinaryFile]
(
      @FilePath  nvarchar(4000) = NULL
    , @MaxBytes  bigint       = NULL
    , @ResultTable sysname    = NULL
    , @KeepData bit           = 0
    , @Debug     tinyint      = 0
    , @Hilfe     bit          = 0
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
| `@MaxBytes` | `bigint` | nein | `NULL` | Optionales Größenlimit. |
| `@Debug` | `tinyint` | nein | `0` | Diagnosemeldungen des ResultTable-Helpers beim Routing; keine zusätzlichen fachlichen Resultsets. |
| `@Hilfe` | `bit` | nein | `0` | `1` gibt Help-Resultset aus. |
| `@ResultTable` | `sysname` | nein | `NULL` | Optionaler Name einer lokalen Temp-Tabelle für die Ergebniszeile. |
| `@KeepData` | `bit` | nein | `0` | Mit ResultTable: 1 erhält bestehende Zeilen; 0 ersetzt Inhalt und Shape gemäß ResultTable-Vertrag. |

`toolbelt.core.result-table` Version `1.0.0` wird nur für `@ResultTable`
benötigt. Das Ziel wird innerhalb derselben Transaktion vor dem Datei-I/O
präpariert. Ein Datei-/Providerfehler rollt die ResultTable-Änderung zurück;
eine vorhandene Callertransaktion wird über einen Savepoint behandelt.

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
| `51326` | `OPENROWSET` konnte die Datei nicht lesen; die Engine-Meldung folgt mit Kontext. |

## Beispiel

```sql
EXEC toolbelt_file.USP_LoadBinaryFile
      @FilePath = N'/var/opt/mssql/data/allowed/sample.bin';

CREATE TABLE #BinaryResult (Content varbinary(max) NULL, BytesRead bigint NOT NULL,
    IsValid bit NOT NULL, ValidationCode int NULL, ValidationMessage nvarchar(4000) NULL);
EXEC toolbelt_file.USP_LoadBinaryFile
      @FilePath = N'/var/opt/mssql/data/allowed/sample.bin'
    , @ResultTable = N'#BinaryResult';
```

## Berechtigungen

- `EXECUTE` auf `toolbelt_file.USP_LoadBinaryFile`
- Bei `@ResultTable`: zusätzlich `EXECUTE` auf `toolbelt_core.USP_PrepareResultTable`
- Lesezugriff auf den Dateipfad
- `ADMINISTER BULK OPERATIONS` oder `ad hoc distributed queries`

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#dateiinhalte).
