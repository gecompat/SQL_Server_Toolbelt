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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

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
