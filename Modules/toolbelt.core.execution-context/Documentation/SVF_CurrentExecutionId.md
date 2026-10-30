# toolbelt_core.SVF_CurrentExecutionId

## Zweck

Liest die Execution-ID der aktuellen Session.

## Verhalten und Ergebnis

Komfort-Wrapper auf die inline TVF. Für mengenorientierte Abfragen bleibt die TVF vorzuziehen.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CONTEXT_OBJECTS](EXECUTION_CONTEXT_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ResultValue;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_CurrentExecutionId.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
