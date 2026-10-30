# toolbelt_core.USP_ScheduleWorkRetry

## Zweck

Plant einen tokengebundenen Retry oder verschiebt nach Dead Letter.

## Verhalten und Ergebnis

Recovery ist ein ausdrücklicher Supervisor-Aufruf. `@MaxItems` begrenzt den Batch auf 1 bis 1.000, Default 100. Abgelaufene Claims wechseln nach ihrer gespeicherten Retry-Policy entweder in `RETRY_WAIT` oder `DEAD_LETTER`. `USP_ScheduleWorkRetry` trifft dieselbe tokengebundene Entscheidung für einen aktiven Worker-Claim. Der Backoff ist `min(Basis × 2^(Versuch−1), Maximum)` ohne Jitter. Claim- und Leasefelder werden gelöscht; eine Barrier gibt dadurch ihre Gruppe frei. Beide Procedures lehnen eine Caller-Transaktion ab.

`USP_ScheduleWorkRetry @Hilfe = 1` gibt die vollständigen Parameter und die
Statusspalten des Queue-Resultsets aus. Die Procedure unterstützt derzeit kein
ResultTable-Routing; Nicht-NULL wird mit Fehler 51989 abgewiesen.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | ID des tatsächlich angelegten Work Items. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Das tatsächlich vom Claim zurückgelieferte Token; kein frei erfundenes Token. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Stabiler ASCII-Fehlercode des Workers. |
| `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Bereinigter Worker-Fehlertext, höchstens 1000 Unicode-Codeeinheiten. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- ID und Token stammen aus dem eigenen aktuellen Claim.
DECLARE @WorkItemId bigint=NULL, @ClaimToken uniqueidentifier=NULL; -- tatsächliche Claimwerte einsetzen
EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@WorkItemId, @ClaimToken=@ClaimToken,
 @FailureCode='EXAMPLE_RETRY', @FailureMessage=N'Synthetischer Testfehler';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ScheduleWorkRetry.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
