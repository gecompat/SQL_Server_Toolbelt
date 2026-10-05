# toolbelt_file.USP_ParseCsv

Parst caller-gelieferten `nvarchar(max)`-Text vollständig und liefert genau vier
Spalten: `RowKind varchar(6) NOT NULL`, `RowOrdinal bigint NOT NULL`,
`ColumnOrdinal int NOT NULL`, `Value nvarchar(max) NULL`. HEADER ist RowOrdinal0;
DATA beginnt bei1. Die normale Ausgabe ist nach beiden Ordinals geordnet.

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
