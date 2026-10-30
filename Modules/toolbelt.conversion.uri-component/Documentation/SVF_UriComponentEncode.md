# SVF_UriComponentEncode

`toolbelt_conversion.SVF_UriComponentEncode(@Value nvarchar(max))` ist die bequeme Scalar-API über dem kanonischen Kern `TVF_UriComponentEncode`. Für mengenorientierte Aufrufe ist die TVF mit `APPLY` vorzuziehen.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |
<!-- API_PARAMETERS:END -->

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
