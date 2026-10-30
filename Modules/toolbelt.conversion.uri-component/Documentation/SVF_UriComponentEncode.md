# SVF_UriComponentEncode

`toolbelt_conversion.SVF_UriComponentEncode(@Value nvarchar(max))` ist die bequeme Scalar-API über dem kanonischen Kern `TVF_UriComponentEncode`. Für mengenorientierte Aufrufe ist die TVF mit `APPLY` vorzuziehen.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |

## Beispielaufruf

```sql
SELECT toolbelt_conversion.SVF_UriComponentEncode(N'a b/ä') AS ResultValue;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#uri).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_UriComponentEncode.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
