# toolbelt_core.VW_WorkQueueBarrierBlockers

## Zweck

Zeigt gespeicherte Blocker-Claimgenerationen und ihren aktuellen Auflösungsstatus.

Der [vollständige Skill](../../../Metadata/UsageSkills/toolbelt_core/VW_WorkQueueBarrierBlockers.md)
beschreibt alle sechs Ergebnisfelder. `IsResolved=0` bedeutet ausschließlich,
dass das blockierende Item weiterhin CLAIMED mit derselben Generation ist;
eine abgelaufene Lease genügt nicht zur Auflösung. `IsResolved=1` beweist keinen
erfolgreichen fachlichen Abschluss. Die View filtert weder auf die aktuelle
Barrier-Epoch noch auf ausschließlich ungelöste Einträge.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_WorkQueueBarrierBlockers.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
