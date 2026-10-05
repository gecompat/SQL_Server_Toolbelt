# toolbelt_file.USP_WriteCsv

Schreibt einen read-only Snapshot einer vorhandenen caller-lokalen Temp-Tabelle
mit genau `RowKind varchar(6)`, `RowOrdinal bigint`, `ColumnOrdinal int`,
`Value nvarchar(max)`. Nur eingebaute Typen; keine Alias-, computed oder zusätzlichen
Spalten. Tatsächliche RowKind-/Ordinal-NULLs sind unzulässig. Quelle und Ziel
dürfen nicht dieselbe tatsächliche Temp-Objekt-ID haben.

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
Zeilenverkettung. Kein Heap- oder Performanceversprechen.

ResultTable-Routing und Transaktionen folgen dem
[USP-Vertrag](../../../Documentation/Standards/USP_CONTRACT.md); unerwartete
technische Fehler bleiben Originalfehler und ein doomed Callerzustand sichtbar.
Vorhandenes EXECUTE und Quellzugriff sind erforderlich, keine Rechtevergabe.
SQL2019+ Windows/Linux sind Zielmatrix; tatsächliche Nachweise stehen in
[Tests](../Tests/README.md).
