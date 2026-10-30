# toolbelt_file.USP_WriteCsv

Schreibt einen read-only Snapshot einer vorhandenen caller-lokalen Temp-Tabelle
mit genau `RowKind varchar(6)`, `RowOrdinal bigint`, `ColumnOrdinal int`,
`Value nvarchar(max)`. Nur eingebaute Typen; keine Alias-, computed oder zusätzlichen
Spalten. Tatsächliche RowKind-/Ordinal-NULLs sind unzulässig. Quelle und Ziel
dürfen nicht dieselbe tatsächliche Temp-Objekt-ID haben.

Vorhandene Callerrechte: EXECUTE auf diese USP sowie auf `toolbelt_file.SVF_InternalMeasureCsvCell` und `toolbelt_file.SVF_InternalQuoteCsvCell`. Bei ResultTable zusätzlich EXECUTE auf `toolbelt_core.USP_PrepareResultTable`. Die [gebundene CSV-Rechteprüfung](../../../Releases/1.0.0/CSV-CALLER-PROFILE.md) belegt diese Kombinationen; Das [korrigierte Manifest mit Paketbindung](../../../Releases/1.0.0/CSV-METADATA-UPDATE.md) übernimmt diese vorhandenen Rechte. Keine automatische Rechtevergabe.

Parameter in Reihenfolge: `@CellsTable sysname=NULL`,
`@Separator nvarchar(2)=N','`, `@HasHeader bit=0`,
`@NullToken nvarchar(128)=NULL`, `@LineEnding varchar(4)='CRLF'`,
`@MaxRows bigint=100000`, `@MaxColumns int=1024`,
`@MaxCells bigint=1000000`, `@MaxValueBytes bigint=16777216`,
`@MaxOutputBytes bigint=16777216`, anschließend
`@ResultTable sysname=NULL`, `@KeepData bit=0`, `@Debug tinyint=0`, `@Hilfe bit=0`.
Quelle ist außerhalb Hilfe erforderlich; Budgets sind positive absenkbare Limits.

DATA-Zeilen1..n und Spalten1..Breite müssen lückenlos und eindeutig sein.
`@HasHeader=1` verlangt genau den vollständigen HEADER-Record mit RowOrdinal0.
Leere Quelle ohne Header ergibt eine Zeile mit leerem CsvText, DataRows0 und
ColumnCount0; leere Quelle mit Header ist Fehler. Header-only ist zulässig.
SQL-NULL in DATA benötigt aktives NullToken, im HEADER ist es immer Fehler.

Ausgabe ist genau eine Zeile: `CsvText nvarchar(max) NOT NULL`,
`DataRows bigint NOT NULL`, `ColumnCount int NOT NULL`.
Literal-Token sowie Werte mit Separator, Quote, CR oder LF werden quoted.
Jeder nichtleere Ausgaberecord erhält exakt CRLF oder LF einschließlich des
letzten Records. NUL, ungepaarte Surrogate und trailing spaces bleiben Wertinhalt.

```sql
CREATE TABLE #CsvCells(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,Value nvarchar(max));
INSERT #CsvCells VALUES('DATA',1,1,N'Contoso'),('DATA',1,2,N'a,b');
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCells',@LineEnding='LF';
DROP TABLE #CsvCells;
```

Der [CSV-Vertrag](../../../Documentation/Architecture/CSV_MEMORY_CONTRACT.md)
definiert alle Grenzen und Fehler55300..55309. Valuebytes sind die Summe der
UTF16-Snapshotwerte, NULL zählt0; Outputbytes schließen Quotes, Token,
Separatoren und sämtliche Recordabschlüsse ein. Exakte globale Messung erfolgt
vor Fragmentallokation; geordnete nvarchar(max)-Aggregation statt wachsender
Zeilenverkettung. Die internen Maß- und Fragmenttabellen besitzen unbenannte
Clustered-Primärschlüssel auf den bereits als eindeutig geprüften Zellordinals
für den vollständigen Fragment-/Maßabgleich. Kein Heap- oder Performanceversprechen.

ResultTable-Routing und Transaktionen folgen dem
[USP-Vertrag](../../../Documentation/Standards/USP_CONTRACT.md); unerwartete
technische Fehler bleiben Originalfehler und ein doomed Callerzustand sichtbar.
Vorhandenes EXECUTE und Quellzugriff sind erforderlich, keine Rechtevergabe.
SQL2019+ Windows/Linux sind Zielmatrix; tatsächliche Nachweise stehen in
[Tests](../Tests/README.md).

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@CellsTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name/#tbx_-Präfix. Genau vier sichtbare nicht-computed Basisspalten ohne Alias-/Zusatzspalten: RowKind varchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max). RowKind bytegenau DATA = Datenrecord oder HEADER = Headerrecord; RowKind/Ordinals nicht NULL. HEADER nur bei HasHeader=1 mit RowOrdinal=0; DATA-Ordinals lückenlos 1..n, Spalten lückenlos 1..Breite und jede Zellposition eindeutig. DATA-Value darf nur bei aktivem NullToken NULL sein, HEADER niemals. Leere Quelle nur ohne Header zulässig; keine Mutation/Quell-Ziel-Identität. |
| `@Separator` | `nvarchar(2)` | `N','` | Input | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. |
| `@HasHeader` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 kein Header (Default); 1 erster Record als HEADER/RowOrdinal 0, DATA beginnt bei 1. NULL ist ungültig und kein Default. Header zählt zu MaxCells, nicht zu MaxRows. Writer verlangt bei 1 einen vollständigen nicht-NULL-Header. |
| `@NullToken` | `nvarchar(128)` | `NULL` | Input | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. |
| `@LineEnding` | `varchar(4)` | `'CRLF'` | Input | Taxativ, bytegenau ohne Trim: CRLF (Default) = U+000D gefolgt von U+000A; LF = nur U+000A. Jeder ausgegebene Record einschließlich des letzten erhält diesen Abschluss. NULL/leer/andere Schreibweisen ungültig. |
| `@MaxRows` | `bigint` | `100000` | Input | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. |
| `@MaxColumns` | `int` | `1024` | Input | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. |
| `@MaxCells` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. |
| `@MaxValueBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Snapshotbytes als Summe DATALENGTH(Value), Default 16777216. NULL-Zellen zählen 0; NULL/außerhalb beim Budget ist ungültig. Keine zusätzliche einzelne Zellgrenze außerhalb dieses Gesamtbudgets. |
| `@MaxOutputBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes des gesamten CsvText, Default 16777216. Einschließlich Quoteverdopplung, Hüllen, NullTokens, Separatoren und sämtlicher Recordabschlüsse. NULL/außerhalb ungültig; vor Allokation/Veröffentlichung exakt gemessen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#csv).
