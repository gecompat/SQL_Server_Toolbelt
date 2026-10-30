# toolbelt_core.USP_RenewWorkLease

## Zweck

Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.

## Verhalten und Ergebnis

Heartbeat verlangt `WorkItemId` und das aktuelle `ClaimToken`, läuft in einer kurzen eigenen Transaktion und verlängert ab Engine-Zeit um die beim Claim gespeicherte Dauer. Fremde Tokens, terminale Items und bereits abgelaufene Leases verändern nichts.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Ergebnisspalten

Die SQL-Hilfe beschreibt folgende Ergebnisspalten:

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | Eindeutige Queue-ID. |
| `ClaimGeneration` | `bigint` | Aktuelle Ownership-Generation. |
| `LeaseUntilUtc` | `datetime2(7)` | Neue exklusive UTC-Grenze der Lease. |
| `LastHeartbeatAtUtc` | `datetime2(7)` | Engine-Zeit dieses Heartbeats. |

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Eindeutige Queue-ID. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Geheimes Ownership-Token des aktiven Claims. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Lease-Zeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken='00000000-0000-0000-0000-000000000001';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RenewWorkLease.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
