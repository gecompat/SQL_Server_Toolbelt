# toolbelt_string.SVF_RegexInstr

## Zweck

Liefert eine UTF-16-Position eines ausgewählten Regex-Treffers.

## Verhalten und Ergebnis

Zusätzliche Parameter sind `@Start int = 1`, `@Occurrence int = 1` und
`@ReturnOption int = 0`. Start und Occurrence beginnen bei 1.
`ReturnOption = 0` liefert den 1-basierten Start, `1` das 1-basierte
Ende-exklusiv. Positionen zählen UTF-16-Codeeinheiten. Ohne Treffer ist das
Ergebnis 0; eine Startposition nach Inputende liefert ebenfalls 0.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [REGEX_FUNCTIONS](REGEX_FUNCTIONS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Start` | `int` | `1` | Input | Regex: positive 1-basierte UTF-16-Startposition. Serie: erster Wert. |
| `@Occurrence` | `int` | `1` | Input | 1-basierte Treffernummer; Replace erlaubt 0 für alle Treffer. |
| `@ReturnOption` | `int` | `0` | Input | 0 = Trefferbeginn, 1 = Ende exklusiv, jeweils 1-basiert. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |

## Beispielaufruf

```sql
SELECT toolbelt_string.SVF_RegexInstr(N'abc123 def456', N'[0-9]+', 1, 1, 0, N'c') AS ResultValue;
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/RegexFunctions.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
