# toolbelt_core.TVF_CurrentExecutionContext

## Zweck

Liest den Toolbelt-Ausführungskontext der aktuellen Session.

## Verhalten und Ergebnis

Inline TVF für `SELECT`, `CROSS APPLY` und `OUTER APPLY`. Ohne aktiven Context liefert sie keine Zeile.

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| `ExecutionId` | `uniqueidentifier` | Aktuelle Toolbelt-Ausführung dieser Session |
| `CorrelationId` | `uniqueidentifier` | Zugehörige fachliche Korrelations-ID |
| `Actor`, `Tenant` | `nvarchar(256)` | Optionale Kontextwerte des Aufrufers |
| `StartedAtUtc` | `datetime2(7)` | Gespeicherter UTC-Beginn des Kontexts |
| `ScopeDepth` | `int` | Aktuelle Verschachtelungstiefe |

`CROSS APPLY` entfernt eine Quellzeile, wenn kein Kontext vorhanden ist.
`OUTER APPLY` erhält sie mit NULL-Kontextspalten. Die Funktion liest den
Sessionkontext und erzeugt selbst keine neue Ausführung. Erzeuge einen
Kontext bei Bedarf über [USP_BeginExecution](USP_BeginExecution.md) und
beende den eigenen Scope mit [USP_EndExecution](USP_EndExecution.md).

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CONTEXT_OBJECTS](EXECUTION_CONTEXT_OBJECTS.md).

## Aufrufparameter

Dieses Objekt hat keine Eingabeparameter.

## Beispielaufruf

```sql
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
```

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_CurrentExecutionContext.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
