# toolbelt_core.USP_ClaimWork

## Zweck

Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.

## Verhalten und Ergebnis

`@LeaseDurationSeconds` besitzt den Default 300 und erlaubt 5 bis 86.400 Sekunden. Claim darf nicht in einer Caller-Transaktion laufen. Er liefert null oder eine Zeile mit Work Item, Work Type, Payload, geheimem ClaimToken, Claimzeit, Generation, Leasegrenze und Heartbeatzeit.

Prioritäten von `0` bis `255` werden absteigend gereiht. Eine Barrier sperrt nur normale Claims ihrer ExecutionGroup. Gleichpriorige Barriers derselben Gruppe können gleichzeitig laufen; unterschiedlich priorige Barriers laufen nicht gleichzeitig. Laufende Arbeit wird nie präemptiert.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Ergebnisspalten

Die SQL-Hilfe beschreibt folgende Ergebnisspalten:

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | Eindeutige Queue-ID. |
| `WorkTypeName` | `varchar(128)` | Kanonischer Work-Type-Name. |
| `PayloadJson` | `nvarchar(max)` | Optionale bereinigte JSON-Payload. |
| `ClaimToken` | `uniqueidentifier` | Geheimes Ownership-Token für Heartbeat, Complete oder Fail. |
| `ClaimedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt des Claims. |
| `ClaimGeneration` | `bigint` | Monotoner Ownership-Zähler dieses Work Items. |
| `LeaseUntilUtc` | `datetime2(7)` | Exklusive UTC-Grenze der Lease. |
| `LastHeartbeatAtUtc` | `datetime2(7)` | Beim Claim identisch mit ClaimedAtUtc. |

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ClaimWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
