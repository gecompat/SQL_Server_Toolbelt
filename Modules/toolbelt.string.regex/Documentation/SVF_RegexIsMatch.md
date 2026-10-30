# toolbelt_string.SVF_RegexIsMatch

## Zweck

Prüft, ob ein regulärer Ausdruck im Text trifft.

## Verhalten und Ergebnis

Gibt `bit` zurück: 1 bei mindestens einem Treffer, sonst 0. Bei `NULL` in
Input oder Pattern ist das Ergebnis `NULL`.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [REGEX_FUNCTIONS](REGEX_FUNCTIONS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu bearbeitender Text; NULL-Verhalten gemäß Objektvertrag. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Regulärer Ausdruck im begrenzten Toolbelt-Dialekt. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Duplikatfreie Kombination aus c oder i sowie m und s; c/i schließen einander aus. |

## Beispielaufruf

```sql
SELECT toolbelt_string.SVF_RegexIsMatch(N'abc123 def456', N'[0-9]+', N'c') AS ResultValue;
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/RegexFunctions.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
