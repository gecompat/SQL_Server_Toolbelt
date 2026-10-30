# toolbelt_core.USP_CompleteWork

## Zweck

Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird nicht gespeichert.

## Verhalten und Ergebnis

`USP_CompleteWork` und `USP_FailWork` verlangen WorkItemId und ClaimToken. Unter demselben Row Lock werden Status, Token und aktive Lease geprüft. Complete speichert kein fachliches Ergebnis. Fail speichert einen stabilen ASCII-Code und optional höchstens 1.000 bereits bereinigte Unicode-Codeeinheiten. `USP_FailWork` bleibt terminal; einen Retry plant nur `USP_ScheduleWorkRetry`.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Ergebnisspalten

Die SQL-Hilfe beschreibt folgende Ergebnisspalten:

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | Eindeutige Queue-ID. |
| `WorkTypeName` | `varchar(128)` | Kanonischer Work-Type-Name. |
| `Status` | `varchar(16)` | Nach Erfolg stets COMPLETED. |
| `EnqueuedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt der Einreihung. |
| `EnqueuedBy` | `sysname` | Original-Login der Einreihung. |
| `ClaimedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt des Claims. |
| `ClaimedBy` | `sysname` | Original-Login des Claimers. |
| `CompletedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt des Abschlusses. |
| `CompletedBy` | `sysname` | Original-Login des Abschlusses. |
| `FailedAtUtc` | `datetime2(7)` | Bei COMPLETED NULL. |
| `FailedBy` | `sysname` | Bei COMPLETED NULL. |
| `FailureCode` | `varchar(64)` | Bei COMPLETED NULL. |
| `FailureMessage` | `nvarchar(1000)` | Bei COMPLETED NULL. |
| `RowVersion` | `binary(8)` | Aktueller Concurrency-Marker. |
| `ClaimGeneration` | `bigint` | Ownership-Generation des abgeschlossenen Claims. |
| `LeaseDurationSeconds` | `int` | Lease-Dauer des abgeschlossenen Claims. |
| `LeaseUntilUtc` | `datetime2(7)` | Lease-Grenze des abgeschlossenen Claims. |
| `LastHeartbeatAtUtc` | `datetime2(7)` | Letzter Heartbeat des abgeschlossenen Claims. |
| `IsLeaseExpired` | `bit` | Bei COMPLETED stets 0. |
| `RecoveryCount` | `bigint` | Kumulierte Recoveries vor diesem Abschluss. |
| `LastRecoveredAtUtc` | `datetime2(7)` | Zeitpunkt der letzten Recovery. |
| `LastRecoveredBy` | `sysname` | Original-Login der letzten Recovery. |

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eindeutige Queue-ID. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Vom erfolgreichen Claim zurückgegebenes Ownership-Token. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Statuszeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1, @ClaimToken='00000000-0000-0000-0000-000000000001';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_CompleteWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
