# toolbelt_core.USP_DeleteEventsBefore

## Zweck

Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.

## Verhalten und Ergebnis

Löscht Events mit älterem `OccurredAtUtc` in explizit begrenzten Batches. Es gibt keine automatische Zeitplanung und keinen stillen Volltabellen-Delete.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EVENT_LOG_OBJECTS](EVENT_LOG_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@BeforeOccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Nur Events mit älterem OccurredAtUtc werden gelöscht. |
| `@BatchSize` | `int` | `1000` | Input | 1 bis 10000 Zeilen je Batch. |
| `@MaxBatches` | `int` | `1` | Input | 1 bis 100 Batches je Aufruf. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | OUTPUT: Anzahl der gelöschten Eventzeilen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Beispielaufruf

```sql
DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2026-01-01', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_DeleteEventsBefore.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
