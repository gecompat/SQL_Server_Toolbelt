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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@LeaseDurationSeconds` | `int` | `300` | Input | Lease-Dauer von 5 bis 86400 Sekunden. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Claim-Zeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

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

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ClaimWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
