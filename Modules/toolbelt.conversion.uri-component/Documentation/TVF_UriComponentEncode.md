# TVF_UriComponentEncode

`toolbelt_conversion.TVF_UriComponentEncode(@Value nvarchar(max))` liefert genau eine Zeile `EncodedValue nvarchar(max)`. RFC-3986-unreserved ASCII-Zeichen (`A-Z`, `a-z`, `0-9`, `-`, `.`, `_`, `~`) bleiben unverändert; alle anderen UTF-8-Octets werden mit großem `%HH` codiert. Bereits codierter Text wird erneut als Text behandelt, also `%` zu `%25`.

## Verwendung und Ergebnis

Verwende die Funktion für einen einzelnen Querywert oder ein einzelnes
Pfadsegment vor dem Zusammensetzen einer URI. Ein vollständiger URI-String
würde auch seine Trennzeichen wie `/` codieren. Ein Leerzeichen wird `%20`,
kein Pluszeichen; die Funktion implementiert keine Form-URL-Encoding-Regeln.

Das folgende Beispiel erwartet `EncodedValue=N'a%20b%2F%C3%A4'`.
Dies ist eine synthetische Erwartung aus dem Vertrag. Bei SQL-NULL oder
Überschreitung der Eingabegrenze liefert die Wertfassade NULL. Verwende
[TVF_UriComponentEncodeStatus](TVF_UriComponentEncodeStatus.md), wenn du
`SQL_NULL` und `LIMIT` unterscheiden musst. Der Statuskern begrenzt den
Eingang vor UTF-8-Konvertierung auf 65536 UTF-16-Bytes.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine noch nicht prozentcodierte Unicode-URI-Komponente; NULL wird weitergegeben. |

## Beispielaufruf

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncode(N'a b/ä');
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#uri).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_UriComponentEncode.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
