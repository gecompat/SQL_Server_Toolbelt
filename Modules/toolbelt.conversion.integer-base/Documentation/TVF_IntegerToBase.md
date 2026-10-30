# toolbelt_conversion.TVF_IntegerToBase

**Typ:** Inline Table-valued Function

Codiert `@Value bigint` mit `@Alphabet varchar(93)` und liefert genau eine
Zeile mit `EncodedValue varchar(65)`. Ungültige oder `NULL`-Eingaben ergeben
eine Zeile mit `NULL`.

Das Alphabet enthält 2 bis 93 binär eindeutige Zeichen aus ASCII `!` bis `~`;
`-` ist als Vorzeichen reserviert. Das erste Zeichen steht für Null.
`decimal(38,0)` deckt auch die Magnitude von
`-9223372036854775808` ab.

```sql
SELECT source.Value, encoded.EncodedValue
FROM (VALUES (CONVERT(bigint, -255)), (255)) AS source(Value)
OUTER APPLY
    toolbelt_conversion.TVF_IntegerToBase
    (
          source.Value
        , '0123456789ABCDEF'
    ) AS encoded;
```

Die inline TVF ist der kanonische relationale Kern. Die rekursive
Ziffernbildung benötigt für `bigint` höchstens 64 Schritte und bleibt damit
unter dem regulären Rekursionslimit von SQL Server.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2–93 binär eindeutige ASCII-Zeichen; Minus ist für das Vorzeichen reserviert. |

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_IntegerToBase.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
