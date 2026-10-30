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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |

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
