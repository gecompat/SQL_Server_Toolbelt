# TVF_TrimDirectionalNvarchar

`toolbelt_string.TVF_TrimDirectionalNvarchar(@Value, @Characters = N' ', @Direction = 'BOTH')` liefert genau eine `nvarchar(max)`-Spalte `Value`. Jeder Eintrag in `@Characters` ist ein einzelnes zu entfernendes UTF-16-Zeichen. Der Vergleich folgt der Collation der Toolbelt-Datenbank; eine dynamische Caller-Collation kann eine T-SQL-Funktion nicht portabel garantieren.

`NCHAR(0)` wird aus Sicherheits- und Plattformgründen nicht entfernt. Die Funktion verwendet keine Pattern-Syntax; `[` und `%` sind literale Zeichen.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Characters` | `nvarchar(4000)` | `N' '` | Input | Menge der zu entfernenden Zeichen. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | LEADING, TRAILING oder BOTH. |

## Beispielaufruf

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'  Contoso-123  ', N' ', 'BOTH');
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TrimDirectionalNvarchar.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
