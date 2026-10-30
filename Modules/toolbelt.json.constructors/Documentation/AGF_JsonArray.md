# toolbelt_json.AGF_JsonArray

## Zweck

Aggregiert typisierte JSON-Einträge in Ordinal-Reihenfolge zu einem JSON-Array.

## Ergebnis und Grenzen

Das Aggregat liefert einen `nvarchar(max)`-Wert je SQL-Aggregationsgruppe.
Das Beispiel unten erwartet `["Contoso",2]`: `Ordinal` legt die Reihenfolge
fest, auch wenn die Eingabezeilen anders gelesen werden. Eine leere
Aggregation liefert `[]`. Diese Beispiele beschreiben die Vertragserwartung.

`ValueKind` entscheidet über die Interpretation: `string` erzeugt einen
JSON-String, `number` ein Zahlenliteral. Für JSON-null wird Kind `null`
mit SQL-NULL als Value verwendet. Doppelte Ordinals, ungültige Werte,
gemischte Profile oder überschrittene Budgets erzeugen Fehler und kein
Teilarray. Ein Entry darf höchstens Tiefe 127 besitzen; der äußere
Arraycontainer ergibt maximal Tiefe 128. Einzelheiten und Betriebsgrenzen
stehen im gemeinsamen Vertrag.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [JSON_AGGREGATES](JSON_AGGREGATES.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Ordinal` | `int` | `kein Default` | Input | Positives, innerhalb der Gruppe eindeutiges int-Ordinal. |
| `@ValueKind` | `nvarchar(max)` | `kein Default` | Input | string, number, boolean, null, array oder object. |
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Profile` | `tinyint` | `kein Default` | Input | JSON-Aggregate: 1 oder 2, innerhalb jeder Gruppe identisch. |

## Beispielaufruf

```sql
DECLARE @Entries TABLE(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(2,N'number',N'2',1),(1,N'string',N'Contoso',1);
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/JsonAggregates.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
