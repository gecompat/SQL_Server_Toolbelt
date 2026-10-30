# toolbelt_core.USP_EndExecution

## Zweck

Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte.

## Verhalten und Ergebnis

Verringert den `ScopeDepth`. Bei Tiefe 1 werden alle namespaceten Sessionwerte gelöscht. Ein fehlender oder nicht passender Context ist ein Fehler und kein stiller Erfolg.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CONTEXT_OBJECTS](EXECUTION_CONTEXT_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | Input | Muss der aktiven Execution-ID entsprechen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Beispielaufruf

```sql
-- Voraussetzung: aktiver Context in derselben Session.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL, @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_EndExecution.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
