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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Positives, innerhalb der Gruppe eindeutiges int-Ordinal. |
| `@Key` | `nvarchar(max)` | `kein Default` | Input | JSON-Objektschlüssel, je Gruppe eindeutige längensensitive UTF-16-Identität. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | string, number, boolean, null, array oder object. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Profile` | `tinyint` | `kein Default` | Input | JSON-Aggregate: 1 oder 2, innerhalb jeder Gruppe identisch. |

## Beispielaufruf

```sql
DECLARE @Entries TABLE(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(1,N'name',N'string',N'Contoso',1),(2,N'count',N'number',N'2',1);
SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/JsonAggregates.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
