# toolbelt_core.USP_GetWorkStatus

## Zweck

Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt.

## Verhalten und Ergebnis

Statusoberflächen liefern Audit-, Lease-, Generation-, Retry-, Dead-Letter-, Prioritäts-, Gruppen- und Barrier-Metadaten. Payload und ClaimToken bleiben verborgen. Direkte DML auf `WorkItem` ist kein öffentlicher Vertrag.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Ergebnisspalten

Die SQL-Hilfe beschreibt folgende Ergebnisspalten:

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | Eindeutige Queue-ID. |
| `WorkTypeName` | `varchar(128)` | Kanonischer Work-Type-Name. |
| `Status` | `varchar(16)` | QUEUED, CLAIMED, COMPLETED oder FAILED. |
| `EnqueuedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt der Einreihung. |
| `EnqueuedBy` | `sysname` | Original-Login der Einreihung. |
| `ClaimedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt des Claims. |
| `ClaimedBy` | `sysname` | Original-Login des Claimers. |
| `CompletedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt eines erfolgreichen Abschlusses. |
| `CompletedBy` | `sysname` | Original-Login des erfolgreichen Abschlusses. |
| `FailedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt eines Fehlabschlusses. |
| `FailedBy` | `sysname` | Original-Login des Fehlabschlusses. |
| `FailureCode` | `varchar(64)` | Optionaler stabiler Fehlercode. |
| `FailureMessage` | `nvarchar(1000)` | Optionale bereinigte Fehlermeldung. |
| `RowVersion` | `binary(8)` | Aktueller Concurrency-Marker. |
| `ClaimGeneration` | `bigint` | Monotoner Ownership-Zähler. |
| `LeaseDurationSeconds` | `int` | Dauer der aktuellen oder letzten Lease. |
| `LeaseUntilUtc` | `datetime2(7)` | Exklusive UTC-Grenze der aktuellen oder letzten Lease. |
| `LastHeartbeatAtUtc` | `datetime2(7)` | Zeitpunkt des letzten Heartbeats. |
| `IsLeaseExpired` | `bit` | 1 nur bei aktuell CLAIMED und abgelaufener Lease. |
| `RecoveryCount` | `bigint` | Kumulierte kontrollierte Recoveries. |
| `LastRecoveredAtUtc` | `datetime2(7)` | Zeitpunkt der letzten Recovery. |
| `LastRecoveredBy` | `sysname` | Original-Login der letzten Recovery. |

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eindeutige Queue-ID. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Statuszeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_GetWorkStatus.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
