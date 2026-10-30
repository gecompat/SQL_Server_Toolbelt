# toolbelt_core.USP_EnqueueWork

## Zweck

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

## Verhalten und Ergebnis

Das ältere `USP_EnqueueWork` benötigt neben seinem EXECUTE und der expliziten
ENQUEUE-Policy Metadatensicht auf den registrierten Handler, etwa ein enges
VIEW DEFINITION auf genau diese Procedure. Ohne Sicht kann seine
`OBJECT_ID`-Prüfung mit 51902 abbrechen, auch wenn der Handler existiert.
Handler-EXECUTE ist hierfür nicht erforderlich. Policy-/Barrier-Enqueue
haben diese zusätzliche Handler-Metadatenprüfung nicht; Claim verlangt
weiterhin Handler-EXECUTE. Rechte müssen dem tatsächlichen Aufrufpfad entsprechen.

`USP_EnqueueWork` behält den V1-Vertrag und reiht mit Gruppe `default`, Priorität `0`, Modus `SHARED` und der Retry-Policy drei Versuche, 60 Sekunden Basis- sowie 3.600 Sekunden Maximalverzögerung ein. Der erweiterte öffentliche Vertrag `USP_EnqueueWorkWithPolicy` ergänzt Idempotency Key, Priority, ExecutionGroup, Retry-Policy und ExecutionMode. Gruppen und Keys werden binär verglichen; ein Key ist je Work Type eindeutig, solange das Item existiert. Gleiche Payload und Policy liefern das vorhandene Item, Abweichungen werden abgewiesen.

`USP_EnqueueBarrierWork` ist die getrennt berechtigte Kurzform für `DRAIN_BARRIER`. Beim Enqueue speichert sie unter dem Scheduler-Mutex die zugehörigen aktiven Claim-Generationen als Blocker-Snapshot. Die öffentliche Sicht `VW_WorkQueueBarrierBlockers` zeigt diese Blocker ohne Payload oder Claim-Token.

Beide Prozeduren liefern über `@Hilfe = 1` einen eigenen Help-Vertrag mit
Objektname, Parametern, Queue-Resultspalten, Berechtigung und Beispiel.
`USP_EnqueueBarrierWork` dokumentiert `@Priority` als fachlich erforderlich,
obwohl der technische Default `NULL` einen reinen Help-Aufruf ermöglicht.
`USP_EnqueueWorkWithPolicy` und die Barrier-Kurzform unterstützen
`@ResultTable` über `toolbelt.core.result-table`. Die Shape-Änderung, die
Queue-Mutation und das Einfügen der Statuszeile liegen in derselben
Transaktion; ein Fehler rollt die Änderung zum eigenen Transaktionsanfang
oder Savepoint zurück. `@KeepData = 1` erhält bestehende Zielzeilen.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Ergebnisspalten

Die SQL-Hilfe beschreibt folgende Ergebnisspalten:

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | Eindeutige Queue-ID. |
| `WorkTypeName` | `varchar(128)` | Kanonischer Work-Type-Name. |
| `Status` | `varchar(16)` | Nach Enqueue stets QUEUED. |
| `EnqueuedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt der Einreihung. |
| `EnqueuedBy` | `sysname` | Original-Login der Einreihung. |
| `ClaimedAtUtc` | `datetime2(7)` | UTC-Zeitpunkt des Claims; nach Enqueue NULL. |
| `ClaimedBy` | `sysname` | Original-Login des Claimers; nach Enqueue NULL. |
| `CompletedAtUtc` | `datetime2(7)` | UTC-Abschlusszeit; nach Enqueue NULL. |
| `CompletedBy` | `sysname` | Original-Login des Abschlusses; nach Enqueue NULL. |
| `FailedAtUtc` | `datetime2(7)` | UTC-Fehlerzeit; nach Enqueue NULL. |
| `FailedBy` | `sysname` | Original-Login des Fail-Aufrufs; nach Enqueue NULL. |
| `FailureCode` | `varchar(64)` | Stabiler Fehlercode; nach Enqueue NULL. |
| `FailureMessage` | `nvarchar(1000)` | Optionale bereinigte Fehlermeldung; nach Enqueue NULL. |
| `RowVersion` | `binary(8)` | Aktueller Concurrency-Marker. |
| `ClaimGeneration` | `bigint` | Nach Enqueue 0; wird bei jedem Claim erhöht. |
| `LeaseDurationSeconds` | `int` | Nach Enqueue NULL. |
| `LeaseUntilUtc` | `datetime2(7)` | Nach Enqueue NULL. |
| `LastHeartbeatAtUtc` | `datetime2(7)` | Nach Enqueue NULL. |
| `IsLeaseExpired` | `bit` | Nach Enqueue 0. |
| `RecoveryCount` | `bigint` | Nach Enqueue 0. |
| `LastRecoveredAtUtc` | `datetime2(7)` | Nach Enqueue NULL. |
| `LastRecoveredBy` | `sysname` | Nach Enqueue NULL. |

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer Name eines aktiven Work Types. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei JSON_PAYLOAD ein JSON-Objekt mit höchstens 64 KiB; bei NONE ausschließlich NULL. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Statuszeile. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='demo.json', @PayloadJson=N'{"value":1}';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_EnqueueWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
