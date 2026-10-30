# toolbelt_core.USP_BeginExecution

## Zweck

Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.

## Verhalten und Ergebnis

Beginnt einen Root-Context oder erhöht bei erlaubter Verschachtelung den `ScopeDepth`. Eine explizit übergebene Execution-ID wird am Root verwendet; andernfalls wird `NEWID()` erzeugt. Die Correlation-ID erbt standardmäßig die Execution-ID.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CONTEXT_OBJECTS](EXECUTION_CONTEXT_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | OUTPUT | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Korrelations-ID für zusammengehörige Ausführungen/Events. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Actor-Kennung des Ausführungskontexts. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Tenant-Kennung des Ausführungskontexts. |
| `@AllowNested` | `bit` | `1` | Input | 1 erlaubt verschachtelte Execution Contexts; 0 lehnt sie ab. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Beispielaufruf

```sql
DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_BeginExecution @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_BeginExecution.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
