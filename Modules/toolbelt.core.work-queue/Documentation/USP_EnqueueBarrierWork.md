# toolbelt_core.USP_EnqueueBarrierWork

## Zweck

Reiht DRAIN_BARRIER-Arbeit ein, die vor ihrem exklusiven Claim die relevanten aktiven Claims derselben ExecutionGroup abwartet; Retry-Policy und optionaler Idempotency Key bleiben gebunden.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | JSON-Objekt-Payload gemäß dem registrierten Handlervertrag. |
| `@ExecutionGroup` | `varchar(128)` | `NULL` | Input | Binär verglichene Queuegruppe; Barriers beziehen sich auf diese Gruppe. |
| `@Priority` | `tinyint` | `NULL` | Input | 0–255; höhere Priorität wird zuerst berücksichtigt. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler binär verglichener Schlüssel, je Work Type eindeutig solange das Item existiert. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Maximale Versuchszahl der gespeicherten Retrypolicy. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Basis des exponentiellen Retry-Backoffs. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Obergrenze des Retry-Backoffs. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- Voraussetzung: registrierter passender Handler; Barrier hat Seiteneffekte auf Claims.
EXEC toolbelt_core.USP_EnqueueBarrierWork
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @ExecutionGroup=N'example-group', @Priority=10;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_EnqueueBarrierWork @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_EnqueueBarrierWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
