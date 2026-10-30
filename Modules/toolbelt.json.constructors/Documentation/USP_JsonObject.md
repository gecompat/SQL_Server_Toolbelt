# USP_JsonObject

Freigegeben am 2026-10-01 gemäß kanonischem Backlog TC-2026-009 Slice B.

Signatur (Parameterreihenfolge): EntriesTable sysname=NULL, MaxEntries int=10000,
MaxTotalValueBytes bigint=2097152, MaxResultBytes bigint=2097152,
ResultTable sysname=NULL, KeepData bit=0, Debug tinyint=0, Hilfe bit=0.
Hilfe=1 ignoriert alle anderen Parameter vollständig. Standardparameter NULL
entsprechen 0; Ressourcenparameter NULL/0 sind ungültig.

Caller-lokale #Temp: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max), zusätzlich Key nvarchar(max).
Erforderliche Spalten exakt, zusätzliche Spalten ignoriert; nullable Metadaten
sind erlaubt, Werte werden vollständig geprüft. Positive einzigartige Ordinals,
Lücken erlaubt; Ausgabe in Ordinalreihenfolge. Eingabeobjekt darf nicht Ausgabeobjekt sein.
Keine globale Temp/permanente Tabelle/Tabellenvariable; reserviertes #tbx_ nicht als Eingabe.
Keys nicht NULL/leer, maximal 1024 UTF-16-Codeeinheiten. BIN2 plus Bytelänge; keine Normalisierung, a und a[Space] sind verschieden. Binär identische Keys sind Fehler.

Exakte ValueKinds string/number/boolean/null/json. String vollständig JSON-escaped,
Number strikt -?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)? ohne Präzisionsverlust,
Boolean exakt true/false. null verlangt Value IS NULL; andere Kinds verlangen
nicht-NULL. json ist ein vollständiges validiertes Objekt/Array, kein Scalar.
Tatsächliche und in JSON-Stringwerten/Keys decodierte UTF-16-Surrogatfolgen
müssen gültig gepaart sein, auch bei \\uHHHH. Fragmente bleiben sonst wörtlich erhalten.

Ergebnis genau eine Spalte/Zeile JsonValue nvarchar(max) NOT NULL, BIN2.
Leere Tabelle ergibt {}. Kein PrettyPrint, keine Inferenz oder Membernormalisierung;
eingebettetes validiertes JSON wird nicht umformatiert.

Positive MaxEntries bis100000; TotalValueBytes und ResultBytes jeweils bis16777216.
TotalValueBytes = SUM(DATALENGTH(Value)), NULL zählt0. ResultBytes zählt exakte
UTF-16-Ausgabe inklusive Keys/Escapes/Interpunktion. Konstruktion/Validierung vor
ResultTable-Mutation. Ressourcen sind keine RAM-/Durchsatz-/Wallclockgarantie.

Fehlerpriorität: Hilfe; reservierter Caller-Tempnamespace vor Core-Kompilierung;
Ressourcen; Dependency; Eingabename/Schematyp/sameTarget;
Count/Ordinals; Keynull/Leer/Länge; Kindlänge; rohe Gesamtwert-/minimale Ergebnisbytes
vor LOB-Copy; Snapshot-Keyduplicates; exakter ValueKind; NULLvertrag;
weitere minimale Ergebnisbytes; je Ordinal Unicode/Literal/decodiertes JSON-Unicode;
fertige Ergebnisbytes; Outputpreflight. Precopy-Count/DATALENGTH-Aggregate und Snapshot
liegen unter TABLOCK/HOLDLOCK in eigener Transaktion oder Caller-savepoint.
Fehler53600 Ressourcenparameter,53601 Input,53602 Ordinals,53603 Key,
53604 DuplicateKey,53605 Kind,53606 NULL,53607 Unicode,53608 Literal,
53609 Ressourcenüberschreitung,53610 Dependency. Enginefehler bleiben unverändert.

ResultTable: kanonischer Helper; Replace/Append nach USP_CONTRACT. Eigene
Transaktion oder Caller-savepoint; keine fremde Transaktion committen. Bei
uncommittable Callertransaktion ist deren Rollback Callerpflicht. Keine Teilausgabe.
Debug ausschließlich Messages ohne Payload. EXECUTE/Tempmetadatensicht und bei
ResultTable zusätzlich Helper-EXECUTE; keine Hochprivilegierung oder pauschale CrossDB-Rechtezusage.

Runtime: Am 2026-10-01 im ausgewählten Scope2019Linux/latest und2025Windows/CU8
erfolgreich, siehe Testmatrix. Weitere Ziel-/Rechtekontexte bleiben offen;
`partially validated`, keine Produktionskapazitätszusage.

## Beispielaufruf

```sql
CREATE TABLE #Entries(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,N'name',N'string',N'Contoso'),(2,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#Entries';
DROP TABLE #Entries;
```

Die Beispiele verwenden synthetische Werte. Vorlagen mit registrierten
Handlern, Tabellen oder Dateien setzen deren beschriebene Vorbereitung voraus.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Leere Tabelle ergibt genau [] beziehungsweise {}. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#json-konstruktion).
