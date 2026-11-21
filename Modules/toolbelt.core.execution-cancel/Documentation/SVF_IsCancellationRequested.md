# toolbelt_core.SVF_IsCancellationRequested

## Zweck

Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.

## Verhalten und Ergebnis

Liefert `1`, wenn für die übergebene `ExecutionId` eine persistierte
Cancellation-Anforderung existiert, andernfalls `0`. Der Wrapper eignet sich
für kleine Worker-Checkpoints.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CANCELLATION_OBJECTS](EXECUTION_CANCELLATION_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | Explizites Argument ohne SQL-Default. NULL findet keine Anforderung und ergibt 0. Auch Null-GUID ist kein Parameterfehler; sie findet regulär keinen über die öffentliche Request-USP angelegten Eintrag. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS ResultValue;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_IsCancellationRequested.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
