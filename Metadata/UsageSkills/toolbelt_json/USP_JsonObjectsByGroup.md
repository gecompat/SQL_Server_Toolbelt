---
name: "toolbelt-toolbelt-toolbelt-json-usp-jsonobjectsbygroup"
description: "JSON-Object aus GroupOrdinal/Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet."
skill_format_version: "1.0"
module_id: "toolbelt.json.constructors"
schema_name: "toolbelt_json"
object_name: "USP_JsonObjectsByGroup"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EntriesTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {\"x\":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung."}, {"name": "@MaxTotalValueBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig."}, {"name": "@MaxResultBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei >0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.json.constructors/Source/USP_JsonObjectsByGroup.sql"]
review_status: "draft"
source_module_version: "1.3.0"
---

# USP_JsonObjectsByGroup

## Zweck und Einsatzfälle

JSON-Object aus GroupOrdinal/Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EntriesTable` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp, kein ##-/mehrteiliger Name und kein #tbx_-Präfix, nicht dieselbe Tabelle wie ResultTable. Erforderliche bytegenaue Basisspalten ohne Aliastyp/computed: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max). Zusatzspalten werden ignoriert. Ordinal positiv/nicht NULL und je Gruppe eindeutig. Zusätzlich Key nvarchar(max): Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. Zusätzlich GroupOrdinal int, positiv/nicht NULL; Ordinals und Keys müssen nur innerhalb dieser Gruppe eindeutig sein. Ausgabe nach GroupOrdinal; leere Tabelle ergibt keine Gruppenzeilen. ValueKind/Value verwenden diesen vollständigen Entryvertrag: Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Technischer EntriesTable-Default NULL ist im Fachaufruf ungültig. |
| `@MaxEntries` | `int` | `10000` | Input | Ganzzahl 1..100000 Einträge über alle Gruppen zusammen, Default 10000. NULL/0/negativ/größer ungültig; Überschreitung verhindert die gesamte Veröffentlichung. |
| `@MaxTotalValueBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Bytes für die Summe DATALENGTH(Value), Default 2097152. SQL-NULL trägt 0 bei; Keys/JSON-Syntax werden separat im Ergebnisbudget berücksichtigt. NULL/andere Werte ungültig. |
| `@MaxResultBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 UTF-16-Ergebnisbytes, Default 2097152; einschließlich Keys, Escaping und JSON-Syntax, bei ByGroup Summe aller Gruppenergebnisse. NULL/andere Werte ungültig. Keine gültige Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntriesTable sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei &gt;0 meldet der JSON-Kern die vollständig validierte Bereitstellung; im Temp-Pfad wird der Wert zusätzlich an den Helper weitergegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Positive Gruppenordinal, Lücken erlaubt; SELECT sortiert danach.

Ein JSON-Wert je Gruppe, BIN2; leere Eingabe erzeugt null Zeilen.

## Aufrufbeispiele

```sql
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'name',N'string',N'Contoso'),(2,1,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#Entries';
DROP TABLE #Entries;
```

```sql
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'name',N'string',N'Contoso'),(2,1,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObjectsByGroup
 @EntriesTable = N'#Entries', @MaxEntries = 10000,
 @MaxTotalValueBytes = 2097152, @MaxResultBytes = 2097152,
 @ResultTable = NULL, @KeepData = 0, @Debug = 0, @Hilfe = 0;
DROP TABLE #Entries;
```

## Rechte

EXECUTE und lokale Temp-Sicht; ResultTable-Pfad zusätzlich Helper-EXECUTE.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Parameter/Schema/Ordinal/Key/Kind/NULL/Unicode/Literal/Ressourcen/Dependency; Enginefehler unverändert.

## Aussagegrenzen

Nur string/number/boolean/null/json; json ist vollständiges Objekt/Array, kein Scalar. Keine Typinferenz.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.json.constructors/Documentation/USP_JsonObjectsByGroup.md`

Keine Installations-, Definitions- oder Rechteattestation.
