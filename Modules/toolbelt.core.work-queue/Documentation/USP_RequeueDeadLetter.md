# toolbelt_core.USP_RequeueDeadLetter

## Zweck

Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.

## Verhalten und Ergebnis

`USP_RequeueDeadLetter` beginnt für ein `DEAD_LETTER`-Item einen neuen Retry-Zyklus. Es unterstützt eine optionale `rowversion`-Prüfung und speichert den Requeue-Grund. Lifetime-Attempts, bereinigte letzte Fehlerdaten und der Idempotency Key bleiben erhalten. Eine Barrier erzeugt dabei einen neuen Claim-Snapshot.

Die eigene Hilfe nennt die tatsächlichen Spalten aus `VW_WorkQueue`, die
Rowversion-Option und den Requeue-Vertrag. `@ResultTable` verwendet dieselbe
transaktionale Ausgabe wie die Queue-Mutation; Callertransaktionen bleiben
für diesen USP ausgeschlossen.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | ID des tatsächlich angelegten Work Items. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Erwartete rowversion zur optimistischen Konkurrenzprüfung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Grund für den neuen Retryzyklus eines DEAD_LETTER-Items. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- Eine tatsächliche eigene DEAD_LETTER-ID einsetzen.
DECLARE @WorkItemId bigint=NULL;
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@WorkItemId, @RequeueReason=N'Synthetischer Wiederholungsversuch';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RequeueDeadLetter.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
