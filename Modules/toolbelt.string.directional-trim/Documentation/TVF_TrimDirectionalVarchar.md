# TVF_TrimDirectionalVarchar

`toolbelt_string.TVF_TrimDirectionalVarchar(@Value, @Characters = ' ', @Direction = 'BOTH')` liefert genau eine `varchar(max)`-Spalte `Value`. Der Vertrag entspricht der Unicode-Variante; ein `varchar`-Zeichen wird bytepositionsbasiert verarbeitet. UTF-8-`varchar` ist deshalb kein Unicode-Codepoint-Vertrag und wird separat bewertet.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Characters` | `varchar(8000)` | `' '` | Input | Menge der zu entfernenden Zeichen. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | LEADING, TRAILING oder BOTH. |

## Beispielaufruf

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalVarchar('  Contoso  ', N' ', 'BOTH');
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TrimDirectionalVarchar.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
