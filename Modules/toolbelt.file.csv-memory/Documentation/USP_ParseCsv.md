# toolbelt_file.USP_ParseCsv

Parst caller-gelieferten `nvarchar(max)`-Text vollständig und liefert genau vier
Spalten: `RowKind varchar(6) NOT NULL`, `RowOrdinal bigint NOT NULL`,
`ColumnOrdinal int NOT NULL`, `Value nvarchar(max) NULL`. HEADER ist RowOrdinal0;
DATA beginnt bei1. Die normale Ausgabe ist nach beiden Ordinals geordnet.

Vorhandene Callerrechte: EXECUTE auf diese USP und SELECT auf `toolbelt_file.TVF_InternalParseCsv`. Bei ResultTable zusätzlich EXECUTE auf `toolbelt_core.USP_PrepareResultTable`. Die [gebundene CSV-Rechteprüfung](../../../Releases/1.0.0/CSV-CALLER-PROFILE.md) belegt diese Kombinationen; Das [korrigierte Manifest mit Paketbindung](../../../Releases/1.0.0/CSV-METADATA-UPDATE.md) übernimmt diese vorhandenen Rechte. Keine automatische Rechtevergabe.

Parameter in Reihenfolge: `@Text nvarchar(max)=NULL`,
`@Separator nvarchar(2)=N','`, `@HasHeader bit=0`,
`@NullToken nvarchar(128)=NULL`, `@MaxRows bigint=100000`,
`@MaxColumns int=1024`, `@MaxCells bigint=1000000`,
`@MaxInputBytes bigint=16777216`, anschließend
`@ResultTable sysname=NULL`, `@KeepData bit=0`, `@Debug tinyint=0`, `@Hilfe bit=0`.
Text ist außerhalb Hilfe erforderlich; Budgets sind positive absenkbare Limits.

Leerer Text ergibt null Zellen, SQL-NULL ist Argumentfehler. Quote ist U+0022;
doppelte Quotes escapen den Wert. Unquoted Recordgrenzen sind LF oder CRLF.
Die erste Recordbreite gilt für alle Records; ein Header zählt zum Zellenlimit,
aber nicht zum DATA-Zeilenlimit. Ein finaler Recordabschluss erzeugt keinen
zusätzlichen Record. Unquoted exakt gleiches DATA-NullToken ergibt SQL-NULL;
quoted Token und alle Headerwerte bleiben Text. Kein Trim und keine Normalisierung.

Der [CSV-Vertrag](../../../Documentation/Architecture/CSV_MEMORY_CONTRACT.md)
enthält alle Zeichen-, Budget- und Fehlergrenzen55300..55309. Interner
Status bleibt privat. Unerwartete Engine-/CLR-Fehler werden unverändert
weitergegeben; keine Eingabewerte in eigenen Fehlertexten.

```sql
EXEC toolbelt_file.USP_ParseCsv @Text=N'name,value'+NCHAR(10)+N'Contoso,7', @HasHeader=1;
EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
```

`@ResultTable` verwendet den [USP-Vertrag](../../../Documentation/Standards/USP_CONTRACT.md)
und kanonischen sameDB-ResultTable-Helper. Syntax, Form, Budgets und privater
Snapshot sind vor Zieländerungen abgeschlossen. Vorhandenes EXECUTE ist
erforderlich; keine Rechtevergabe. Kosten: zwei lineare Scannerdurchläufe und
begrenzte private Zellmaterialisierung. SQL2019+ Windows/Linux sind Zielmatrix;
ausgeführte Teilnachweise stehen in [Tests](../Tests/README.md).

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `NULL` | Input | Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord. |
| `@Separator` | `nvarchar(2)` | `N','` | Input | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. |
| `@HasHeader` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 kein Header (Default); 1 erster Record als HEADER/RowOrdinal 0, DATA beginnt bei 1. NULL ist ungültig und kein Default. Header zählt zu MaxCells, nicht zu MaxRows. Writer verlangt bei 1 einen vollständigen nicht-NULL-Header. |
| `@NullToken` | `nvarchar(128)` | `NULL` | Input | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. |
| `@MaxRows` | `bigint` | `100000` | Input | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. |
| `@MaxColumns` | `int` | `1024` | Input | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. |
| `@MaxCells` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. |
| `@MaxInputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#csv).
