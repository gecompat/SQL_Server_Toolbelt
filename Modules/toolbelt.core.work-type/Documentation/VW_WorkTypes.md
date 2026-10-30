# toolbelt_core.VW_WorkTypes

## Zweck

Zeigt registrierte Work Types und deren Konfiguration.

## Verhalten und Ergebnis

Read-only-Sicht auf registrierte Work Types. `HandlerExists` zeigt, ob die Zielprocedure aktuell vorhanden ist. Die View ist kein Ausführungsprovider.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_TYPE_OBJECTS](WORK_TYPE_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkTypes;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_WorkTypes.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
