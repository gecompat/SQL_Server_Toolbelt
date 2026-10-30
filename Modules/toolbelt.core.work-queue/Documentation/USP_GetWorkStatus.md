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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. Liest Status; Payload und ClaimToken sind absichtlich nicht Teil dieser Oberfläche. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

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
