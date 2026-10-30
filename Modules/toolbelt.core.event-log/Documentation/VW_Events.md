# toolbelt_core.VW_Events

## Zweck

Zeigt protokollierte Toolbelt-Events.

## Verhalten und Ergebnis

Read-only-Sicht auf Eventzeit, Aufzeichnungszeit, Eventklassifikation, Context, Source, Caller- und Remote-Session sowie optionale SQL-Fehlerdaten.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EVENT_LOG_OBJECTS](EVENT_LOG_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_Events;
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_Events.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
