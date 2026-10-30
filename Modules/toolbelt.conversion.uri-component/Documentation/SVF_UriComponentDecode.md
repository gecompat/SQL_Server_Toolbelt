# SVF_UriComponentDecode

`toolbelt_conversion.SVF_UriComponentDecode(@Value nvarchar(max))` ist die bequeme Scalar-API über `TVF_UriComponentDecode`. Ungültige Eingabe wird als `NULL` zurückgegeben; zur Differenzierung der Gründe ist die TVF zu verwenden.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

## Beispielaufruf

```sql
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'a%20b%2F%C3%A4') AS ResultValue;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_UriComponentDecode.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
