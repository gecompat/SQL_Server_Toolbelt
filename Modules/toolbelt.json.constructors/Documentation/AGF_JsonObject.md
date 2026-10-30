# toolbelt_json.AGF_JsonObject

## Zweck

Aggregiert typisierte Einträge mit eindeutigen Schlüsseln zu einem JSON-Objekt.

## Ergebnis und Grenzen

Das Aggregat liefert einen `nvarchar(max)`-Wert je SQL-Aggregationsgruppe.
Das Beispiel unten erwartet `{"name":"Contoso","count":2}`. `Ordinal`
steuert die Ausgabeanordnung; die SQL-Verarbeitungsreihenfolge hat keinen
Einfluss. Eine leere Aggregation liefert `{}`. Diese Angaben sind aus dem
Vertrag abgeleitete Ergebniserwartungen.

`ValueKind` steuert den JSON-Typ des Werts. Für JSON-null wird Kind `null`
mit SQL-NULL als Value verwendet. Doppelte Schlüssel oder Ordinals sind
Fehler. Schlüssel werden längensensitiv als UTF-16-Identitäten verglichen;
sie werden weder getrimmt noch nach Datenbank-Collation gleichgesetzt.
Gemischte Profile, ungültige Werte und Budgetüberschreitungen liefern kein
Teilobjekt. Die maximale Entrytiefe ist 127, einschließlich des äußeren
Containers maximal 128; weitere Grenzen stehen im gemeinsamen Vertrag.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [JSON_AGGREGATES](JSON_AGGREGATES.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647, nicht NULL und je Aggregatgruppe eindeutig. Bestimmt die Ausgabeordnung unabhängig von Callback-/Inputreihenfolge; Lücken sind erlaubt. |
| `@Key` | `nvarchar(max)` | `kein Default` | Input | Nicht-NULL-Key mit 1..1024 UTF-16-Einheiten, wohlgeformtes Unicode. Vollständige binäre UTF-16-Identität einschließlich Groß-/Kleinschreibung und nachgestellter Spaces; innerhalb einer Gruppe eindeutig. Kein SQL-Identifier, keine automatische Normalisierung; JSON-Escaping erfolgt durch das Objekt. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | Taxativ, bytegenau ohne Trim/Casefold: string = unquotierter Unicode-Text, der JSON-escaped/quotiert wird; number = vollständiges JSON-Zahlenliteral ohne zusätzliche Quotes/Spaces (optionales -, kanonischer Ganzzahlteil, optional Bruch/Exponent); boolean = exakt true oder false; null = JSON-null und verlangt SQL-NULL in Value; json = vollständiges Objekt oder Array, kein JSON-Skalar. NULL/andere Werte ungültig. Keine Typinferenz. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Rohwert gemäß ValueKind: string erlaubt auch leeren Text, number erwartet z.B. -12.5e2, boolean exakt true/false, json z.B. {"x":1} oder [1,2], null ausschließlich SQL-NULL. Für alle anderen Kinds ist SQL-NULL ungültig. Unicode einschließlich decodierter JSON-Escapes muss wohlgeformt sein; kein automatisches Trim/Coercion. Endliche Gesamt-/Ergebnisbudgets gelten zusätzlich. Bei json höchstens 127 Containerebenen, damit der äußere Aggregatcontainer Tiefe 128 nicht überschreitet. |
| `@Profile` | `tinyint` | `kein Default` | Input | Taxativ für tinyint: 1 = höchstens 10000 Entries, 2097152 Payloadbytes und 5242880 serialisierte Zustandsbytes; 2 = 100000 Entries, 16777216 Payloadbytes und 37748736 Zustandsbytes. Kein Default: an jedem Inputeintrag explizit übergeben. Muss in einer Aggregatgruppe gleich bleiben; NULL/andere/gemischte Werte sind Fehler. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
DECLARE @Entries TABLE(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(1,N'name',N'string',N'Contoso',1),(2,N'count',N'number',N'2',1);
SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#json-konstruktion).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/JsonAggregates.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
