# toolbelt_core.USP_RecoverExpiredWork

## Zweck

Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.

## Verhalten und Ergebnis

Recovery ist ein ausdrücklicher Supervisor-Aufruf. `@MaxItems` begrenzt den Batch auf 1 bis 1.000, Default 100. Abgelaufene Claims wechseln nach ihrer gespeicherten Retry-Policy entweder in `RETRY_WAIT` oder `DEAD_LETTER`. `USP_ScheduleWorkRetry` trifft dieselbe tokengebundene Entscheidung für einen aktiven Worker-Claim. Der Backoff ist `min(Basis × 2^(Versuch−1), Maximum)` ohne Jitter. Claim- und Leasefelder werden gelöscht; eine Barrier gibt dadurch ihre Gruppe frei. Beide Procedures lehnen eine Caller-Transaktion ab.

`USP_ScheduleWorkRetry @Hilfe = 1` gibt die vollständigen Parameter und die
Statusspalten des Queue-Resultsets aus. Die Procedure unterstützt derzeit kein
ResultTable-Routing; Nicht-NULL wird mit Fehler 51989 abgewiesen.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Ergebnisspalten

Die SQL-Hilfe beschreibt folgende Ergebnisspalten:

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | Eindeutige Queue-ID. |
| `WorkTypeName` | `varchar(128)` | Kanonischer Work-Type-Name. |
| `Status` | `varchar(16)` | RETRY_WAIT oder DEAD_LETTER nach gespeicherter Policy. |
| `ClaimGeneration` | `bigint` | Letzte invalidierte Ownership-Generation. |
| `RecoveryCount` | `bigint` | Kumulierte Zahl kontrollierter Recoveries. |
| `LastRecoveredAtUtc` | `datetime2(7)` | Engine-Zeit der Recovery. |
| `LastRecoveredBy` | `sysname` | Original-Login der Recovery. |

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@MaxItems` | `int` | `100` | Input | Batchgrenze von 1 bis 1000. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für recoverte Items. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RecoverExpiredWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
