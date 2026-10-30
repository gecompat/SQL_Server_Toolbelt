# toolbelt_string.SVF_RegexCount

## Zweck

Zählt Regex-Treffer ab der angegebenen Startposition.

## Verhalten und Ergebnis

`@Start int = 1` legt die erste zulässige Suchposition fest. Gezählt werden
nicht überlappende Treffer. Nach einem leeren Treffer schreitet die Engine um
eine UTF-16-Codeeinheit fort; am Inputende ist genau ein letzter leerer
Treffer möglich.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [REGEX_FUNCTIONS](REGEX_FUNCTIONS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Start` | `int` | `1` | Input | Regex: positive 1-basierte UTF-16-Startposition. Serie: erster Wert. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |

## Beispielaufruf

```sql
SELECT toolbelt_string.SVF_RegexCount(N'abc123 def456', N'[0-9]+', 1, N'c') AS ResultValue;
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/RegexFunctions.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
