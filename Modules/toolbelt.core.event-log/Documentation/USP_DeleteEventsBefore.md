# toolbelt_core.USP_DeleteEventsBefore

## Zweck

Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.

## Verhalten und Ergebnis

Löscht Events mit älterem `OccurredAtUtc` in explizit begrenzten Batches. Es gibt keine automatische Zeitplanung und keinen stillen Volltabellen-Delete.

Alle Batches eines Aufrufs gehören zu einer gemeinsamen eigenen Transaktion
oder zum Caller-Savepoint, nicht zu einzelnen Batchcommits. Bei Callertransaktion
ist das Ergebnis erst mit deren Commit dauerhaft. Ein OUTPUT-Zähler nach Fehler
kann zurückgerollte Löschungen enthalten und ist kein Erfolgsbeleg.
Der [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_DeleteEventsBefore.md)
steht in der DDL und wird bei `@Hilfe=1` zusätzlich zur Standardhilfe ausgegeben;
`@DeletedRows` wird dabei wie bisher auf 0 gesetzt.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EVENT_LOG_OBJECTS](EVENT_LOG_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeOccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich OccurredAtUtc &lt; Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/&gt;10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/&gt;100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Vorhandenes EXECUTE und gültige Abhängigkeitsrechte auf EventLog. Für dieses
  lokale Löschen ist kein Second-Session-Provider erforderlich. Ein gültiger
  Cutoff und committable Transaktionszustand sind notwendig; Retention verändert
  persistente Daten.

## Beispielaufruf

```sql
DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2026-01-01', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_DeleteEventsBefore.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
