# toolbelt_core.TVF_ExecutionCancellationStatus

## Zweck

Liest den registrierten kooperativen Abbruchstatus einer Ausführung.

## Verhalten und Ergebnis

Liefert für eine `ExecutionId` keine oder genau eine sichere Statuszeile mit
`ExecutionId`, `IsCancellationRequested` und `RequestedAtUtc`. Grund,
anfordernde Identität, Claim-Tokens, Payloads, Sessions und Fehlerdaten sind
nicht sichtbar.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CANCELLATION_OBJECTS](EXECUTION_CANCELLATION_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Fallback auf den aktuellen Kontext. Bei NULL oder fehlender Anforderung keine Zeile; bei vorhandener Anforderung genau eine nicht sensible Statuszeile. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_ExecutionCancellationStatus.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
