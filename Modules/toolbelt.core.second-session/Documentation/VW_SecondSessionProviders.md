# toolbelt_core.VW_SecondSessionProviders

## Zweck

Zeigt konfigurierte Second-Session-Provider.

## Verhalten und Ergebnis

Zeigt die gespeicherte Providerkonfiguration und die aktuelle Drift gegenüber `master.sys.servers`: Existenz, `rpc out` und Remote-Transaction-Promotion. Der Vergleich des Linked-Server-Namens verwendet explizit eine binäre Collation und bleibt damit bei abweichenden Datenbank- und `master`-Collations funktionsfähig.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [SECOND_SESSION_OBJECTS](SECOND_SESSION_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_SecondSessionProviders;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/VW_SecondSessionProviders.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
