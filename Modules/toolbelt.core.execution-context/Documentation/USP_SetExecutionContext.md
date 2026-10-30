# toolbelt_core.USP_SetExecutionContext

## Zweck

Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand.

## Verhalten und Ergebnis

Ändert Correlation-ID, Actor oder Tenant. `@ExpectedExecutionId` muss dem aktiven Context entsprechen. Actor und Tenant besitzen getrennte Clear-Flags, damit `NULL` eindeutig als „nicht ändern“ behandelt werden kann.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CONTEXT_OBJECTS](EXECUTION_CONTEXT_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | Muss der aktiven Execution-ID entsprechen. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Korrelations-ID für zusammengehörige Ausführungen/Events. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Actor-Kennung des Ausführungskontexts. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Tenant-Kennung des Ausführungskontexts. |
| `@ClearActor` | `bit` | `0` | Input | 1 löscht den Actor; nicht zugleich mit @Actor verwenden. |
| `@ClearTenant` | `bit` | `0` | Input | 1 löscht den Tenant; nicht zugleich mit @Tenant verwenden. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Beispielaufruf

```sql
-- Voraussetzung: in derselben Session zuvor USP_BeginExecution aufrufen.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id, @Actor=N'Contoso example', @Tenant=N'Fabrikam';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=NULL, @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_SetExecutionContext.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
