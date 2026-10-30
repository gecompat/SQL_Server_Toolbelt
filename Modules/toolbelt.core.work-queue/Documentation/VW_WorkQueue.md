# toolbelt_core.VW_WorkQueue

## Zweck

Zeigt Queue-Status und Auditmetadaten ohne Payload und ClaimToken.

## Verhalten und Ergebnis

Statusoberflächen liefern Audit-, Lease-, Generation-, Retry-, Dead-Letter-, Prioritäts-, Gruppen- und Barrier-Metadaten. Payload und ClaimToken bleiben verborgen. Direkte DML auf `WorkItem` ist kein öffentlicher Vertrag.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueue;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_WorkQueue.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
