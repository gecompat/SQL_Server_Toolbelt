# toolbelt_core.USP_EnqueueWorkWithPolicy

## Zweck

Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.

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

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | JSON-Objekt-Payload gemäß dem registrierten Handlervertrag. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler binär verglichener Schlüssel, je Work Type eindeutig solange das Item existiert. |
| `@Priority` | `tinyint` | `0` | Input | 0–255; höhere Priorität wird zuerst berücksichtigt. |
| `@ExecutionGroup` | `varchar(128)` | `'default'` | Input | Binär verglichene Queuegruppe; Barriers beziehen sich auf diese Gruppe. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Maximale Versuchszahl der gespeicherten Retrypolicy. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Basis des exponentiellen Retry-Backoffs. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Obergrenze des Retry-Backoffs. |
| `@ExecutionMode` | `varchar(16)` | `'SHARED'` | Input | SHARED oder DRAIN_BARRIER gemäß Queuevertrag. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- Voraussetzung: aktiver, ausführbarer Work Type demo.noop.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @IdempotencyKey=N'example-1',
 @Priority=10, @ExecutionGroup=N'example-group', @MaxAttempts=3,
 @RetryBaseDelaySeconds=60, @RetryMaxDelaySeconds=3600, @ExecutionMode='SHARED';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_EnqueueWorkWithPolicy.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
