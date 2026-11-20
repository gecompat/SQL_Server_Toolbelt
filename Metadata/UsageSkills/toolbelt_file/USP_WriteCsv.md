---
name: "toolbelt-toolbelt-toolbelt-file-usp-writecsv"
description: "Schreibt einen read-only Snapshot vier typgenauer caller-lokaler Temp-Spalten als vollständig budgetiertes CSV."
skill_format_version: "1.0"
module_id: "toolbelt.file.csv-memory"
schema_name: "toolbelt_file"
object_name: "USP_WriteCsv"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@CellsTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name/#tbx_-Präfix. Genau vier sichtbare nicht-computed Basisspalten ohne Alias-/Zusatzspalten: RowKind varchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max). RowKind bytegenau DATA = Datenrecord oder HEADER = Headerrecord; RowKind/Ordinals nicht NULL. HEADER nur bei HasHeader=1 mit RowOrdinal=0; DATA-Ordinals lückenlos 1..n, Spalten lückenlos 1..Breite und jede Zellposition eindeutig. DATA-Value darf nur bei aktivem NullToken NULL sein, HEADER niemals. Leere Quelle nur ohne Header zulässig; keine Mutation/Quell-Ziel-Identität."}, {"name": "@Separator", "sql_type": "nvarchar(2)", "sql_default": "N','", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim."}, {"name": "@HasHeader", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 kein Header (Default); 1 erster Record als HEADER/RowOrdinal 0, DATA beginnt bei 1. NULL ist ungültig und kein Default. Header zählt zu MaxCells, nicht zu MaxRows. Writer verlangt bei 1 einen vollständigen nicht-NULL-Header."}, {"name": "@NullToken", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung."}, {"name": "@LineEnding", "sql_type": "varchar(4)", "sql_default": "'CRLF'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, bytegenau ohne Trim: CRLF (Default) = U+000D gefolgt von U+000A; LF = nur U+000A. Jeder ausgegebene Record einschließlich des letzten erhält diesen Abschluss. NULL/leer/andere Schreibweisen ungültig."}, {"name": "@MaxRows", "sql_type": "bigint", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf."}, {"name": "@MaxColumns", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig."}, {"name": "@MaxCells", "sql_type": "bigint", "sql_default": "1000000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig."}, {"name": "@MaxValueBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Snapshotbytes als Summe DATALENGTH(Value), Default 16777216. NULL-Zellen zählen 0; NULL/außerhalb beim Budget ist ungültig. Keine zusätzliche einzelne Zellgrenze außerhalb dieses Gesamtbudgets."}, {"name": "@MaxOutputBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes des gesamten CsvText, Default 16777216. Einschließlich Quoteverdopplung, Hüllen, NullTokens, Separatoren und sämtlicher Recordabschlüsse. NULL/außerhalb ungültig; vor Allokation/Veröffentlichung exakt gemessen."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei >0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.file.csv-memory/Source/USP_WriteCsv.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_WriteCsv

## Zweck und Einsatzfälle

Schreibt einen read-only Snapshot vier typgenauer caller-lokaler Temp-Spalten als vollständig budgetiertes CSV.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandener SAFE-Provider; Quelle ist keine ResultTable und bleibt unverändert.

## Parameter und Zugriff

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
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Vollständiger CSV-Text; leere Quelle ohne Header ergibt leer.

Anzahl DATA-Records.

Rechteckige Breite; leere Quelle ohne Header ergibt 0.

## Aufrufbeispiele

```sql
CREATE TABLE #CsvCells(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,Value nvarchar(max)); INSERT #CsvCells VALUES('DATA',1,1,N'Contoso'); EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCells'; DROP TABLE #CsvCells;
```

## Rechte

EXECUTE und sichtbare eigene lokale Temps; ResultTable zusätzlich vorhandene Helperberechtigung. Keine Rechteausweitung.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Begrenzte Argument-/Syntax-/Form-/Budget-/Transportfehler; ursprüngliche Enginefehler bleiben erhalten.

## Aussagegrenzen

In-memory UTF-16; kein I/O, Casting, Trim oder Streaming. NUL/unpaired Surrogate bleiben Zelltext.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.file.csv-memory/Documentation/USP_WriteCsv.md`

Keine Installations-, Definitions- oder Rechteattestation.
