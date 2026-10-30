# toolbelt_core.VW_WorkQueueBarrierBlockers

## Zweck

Zeigt aktive Claim-Generationen, die eine Gruppenbarriere blockieren.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_WorkQueueBarrierBlockers.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
