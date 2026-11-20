---
name: "toolbelt-toolbelt-toolbelt-json-agf-jsonarray"
description: "Aggregiert typisierte JSON-Einträge in Ordinal-Reihenfolge zu einem JSON-Array."
skill_format_version: "1.0"
module_id: "toolbelt.json.constructors"
schema_name: "toolbelt_json"
object_name: "AGF_JsonArray"
object_type: "CLR_AGGREGATE"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Ordinal", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..2147483647, nicht NULL und je Aggregatgruppe eindeutig. Bestimmt die Ausgabeordnung unabhängig von Callback-/Inputreihenfolge; Lücken sind erlaubt."}, {"name": "@ValueKind", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz."}, {"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {\"x\":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Bei json höchstens 127 Containerebenen, damit der äußere Aggregatcontainer Tiefe 128 nicht überschreitet."}, {"name": "@Profile", "sql_type": "tinyint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ für tinyint: 1 = höchstens 10000 Entries, 2097152 Payloadbytes und 5242880 serialisierte Zustandsbytes; 2 = 100000 Entries, 16777216 Payloadbytes und 37748736 Zustandsbytes. Kein Default: an jedem Inputeintrag explizit übergeben. Muss in einer Aggregatgruppe gleich bleiben; NULL/andere/gemischte Werte sind Fehler."}]
source_paths: ["Modules/toolbelt.json.constructors/Source/JsonAggregates.sql"]
review_status: "draft"
source_module_version: "1.3.0"
---

# AGF_JsonArray

## Zweck und Einsatzfälle

Aggregiert typisierte JSON-Einträge in Ordinal-Reihenfolge zu einem JSON-Array.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647, nicht NULL und je Aggregatgruppe eindeutig. Bestimmt die Ausgabeordnung unabhängig von Callback-/Inputreihenfolge; Lücken sind erlaubt. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Bei json höchstens 127 Containerebenen, damit der äußere Aggregatcontainer Tiefe 128 nicht überschreitet. |
| `@Profile` | `tinyint` | `kein Default` | Input | Taxativ für tinyint: 1 = höchstens 10000 Entries, 2097152 Payloadbytes und 5242880 serialisierte Zustandsbytes; 2 = 100000 Entries, 16777216 Payloadbytes und 37748736 Zustandsbytes. Kein Default: an jedem Inputeintrag explizit übergeben. Muss in einer Aggregatgruppe gleich bleiben; NULL/andere/gemischte Werte sind Fehler. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
DECLARE @Entries TABLE(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(2,N'number',N'2',1),(1,N'string',N'Contoso',1);
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.json.constructors/Documentation/AGF_JsonArray.md`

Keine Installations-, Definitions- oder Rechteattestation.
