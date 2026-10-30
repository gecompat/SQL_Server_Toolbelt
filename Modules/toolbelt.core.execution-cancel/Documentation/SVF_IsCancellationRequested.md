# toolbelt_core.SVF_IsCancellationRequested

## Zweck

Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.

## Verhalten und Ergebnis

Liefert `1`, wenn für die übergebene `ExecutionId` eine persistierte
Cancellation-Anforderung existiert, andernfalls `0`. Der Wrapper eignet sich
für kleine Worker-Checkpoints.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CANCELLATION_OBJECTS](EXECUTION_CANCELLATION_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |

## Beispielaufruf

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS ResultValue;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_IsCancellationRequested.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
