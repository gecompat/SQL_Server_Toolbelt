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
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Explizites Argument ohne SQL-Default. NULL findet keine Anforderung und ergibt keine Zeilen. Auch Null-GUID ist kein Parameterfehler; sie findet regulär keinen über die öffentliche Request-USP angelegten Eintrag. |
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
