# toolbelt_core.VW_SecondSessionProviders

## Zweck

Zeigt konfigurierte Second-Session-Provider.

## Verhalten und Ergebnis

Zeigt die gespeicherte Providerkonfiguration und die aktuelle Drift gegenüber `master.sys.servers`: Existenz, `rpc out` und Remote-Transaction-Promotion. Der Vergleich des Linked-Server-Namens verwendet explizit eine binäre Collation und bleibt damit bei abweichenden Datenbank- und `master`-Collations funktionsfähig.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [SECOND_SESSION_OBJECTS](SECOND_SESSION_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/VW_SecondSessionProviders.md)
steht in der ausgelieferten DDL. Die View zeigt elf Spalten einschließlich
Auditdaten und drei sichtbarer Serverflags. Ohne gespeicherten Provider gibt es
keine Zeile; fehlt nur die sichtbare Linked-Server-Zuordnung, sind Exists/RPC
0 und Promotion 1. Die Flags sind keine Probe, keine Authentifizierungs- oder
TLS-Bestätigung. Das einfache Viewlayout ist kein ausdrücklich erzwungenes
DML-Verbot; Lesekonsumenten benötigen SELECT.

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
