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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@FallbackEncoding` | `nvarchar(128)` | `N'Windows-1252'` | Input | Taxativ nach LTRIM/RTRIM und Vergleich unter wirksamer SQL-Collation: Windows-1252 (Default) = explizite CP1252-Dekodierung bei fehlender BOM; SQL_Latin1_General_CP1_CI_AS = akzeptierter Alias für dieselbe CP1252-Dekodierung, keine beliebige Collationwahl. NULL/leer/nur Randspaces werden Windows-1252. Andere Werte ergeben 51324, auch wenn später eine BOM vorhanden wäre. UTF-8-/UTF-16-LE-BOM überschreibt die zulässige Fallbackwahl; UTF-16-BE/UTF-32 bleiben unsupported. Kein freier .NET-Codepageselector. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

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

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#dateiinhalte).
