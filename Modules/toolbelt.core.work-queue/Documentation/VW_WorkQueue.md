# toolbelt_core.VW_WorkQueue

## Zweck

Zeigt Queue-Status und Auditmetadaten ohne Payload und ClaimToken.

## Verhalten und Ergebnis

Statusoberflächen liefern Audit-, Lease-, Generation-, Retry-, Dead-Letter-, Prioritäts-, Gruppen- und Barrier-Metadaten. Payload und ClaimToken bleiben verborgen. Direkte DML auf `WorkItem` ist kein öffentlicher Vertrag.

Die [vollständige Skillreferenz](../../../Metadata/UsageSkills/toolbelt_core/VW_WorkQueue.md)
nennt die 41 Spalten in Reihenfolge. Auch IdempotencyKey und die drei internen
Managedfelder werden nicht ausgegeben. Es gibt keinen Caller-/Policyzeilenfilter.
`IsLeaseExpired` vergleicht nur den aktuellen CLAIMED-Status und die Leasegrenze
mit der Engine-UTC-Zeit; der SELECT führt keine Recovery aus.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueue;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_WorkQueue.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
