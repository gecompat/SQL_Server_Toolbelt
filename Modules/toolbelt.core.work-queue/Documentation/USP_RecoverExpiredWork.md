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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MaxItems` | `int` | `100` | Input | Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/&gt;1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

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
