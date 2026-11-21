# Öffentliche Execution-Context-Objekte

## Einzelreferenzen

Die folgenden Seiten erläutern die einzelnen Aufrufe mit Parametern und
Beispielen. Die gemeinsamen Fachregeln auf dieser Seite gelten weiterhin.

- [`toolbelt_core.TVF_CurrentExecutionContext`](TVF_CurrentExecutionContext.md)
- [`toolbelt_core.SVF_CurrentExecutionId`](SVF_CurrentExecutionId.md)
- [`toolbelt_core.USP_BeginExecution`](USP_BeginExecution.md)
- [`toolbelt_core.USP_SetExecutionContext`](USP_SetExecutionContext.md)
- [`toolbelt_core.USP_EndExecution`](USP_EndExecution.md)

## `USP_BeginExecution`

Beginnt einen Root-Context oder erhöht bei erlaubter Verschachtelung den `ScopeDepth`. Eine explizit übergebene Execution-ID wird am Root verwendet; andernfalls wird `NEWID()` erzeugt. Die Correlation-ID erbt standardmäßig die Execution-ID.

## `USP_SetExecutionContext`

Ändert Correlation-ID, Actor oder Tenant. `@ExpectedExecutionId` muss dem aktiven Context entsprechen. Actor und Tenant besitzen getrennte Clear-Flags, damit `NULL` eindeutig als „nicht ändern“ behandelt werden kann.

## `USP_EndExecution`

Verringert den `ScopeDepth`. Bei Tiefe 1 werden die sechs festen Toolbelt-Ausführungskontextkeys gelöscht; andere Sessionwerte bleiben erhalten. Ein fehlender oder nicht passender Context ist ein Fehler und kein stiller Erfolg.

## `TVF_CurrentExecutionContext`

Inline TVF für `SELECT`, `CROSS APPLY` und `OUTER APPLY`. Ohne aktiven Context liefert sie keine Zeile.

## `SVF_CurrentExecutionId`

Komfort-Wrapper auf die inline TVF. Für mengenorientierte Abfragen bleibt die TVF vorzuziehen.

## Vollständige Skills und Hilfe

Die [Modulübersicht](../README.md#vollständige-skills-und-hilfe) verlinkt die
fünf kanonischen Skillquellen. Dieselben vollständigen Texte stehen in der DDL;
die Prozeduren liefern sie zusätzlich zur bisherigen Standardhilfe als genau
ein vierkolumniges Resultset (`SkillFormatVersion`, `SchemaName`, `ObjectName`,
`SkillMarkdown nvarchar(max)`). Die neue Hilfe ist offline geprüft, ihre native
Abnahme bleibt separat.

`@Hilfe=1` erfolgt vor fachlichem Kontextlesen/-schreiben. Ein vorhandener
Begin-OUTPUT-Wert bleibt dabei erhalten. Set und End behalten ihr syntaktisches
Pflichtargument, beispielsweise
`EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL,@Hilfe=1;`.
Die Keys gelten für die gesamte Verbindung über Datenbankgrenzen hinweg.
Actor/Tenant sind frei gesetzte Kontextlabels und keine Autorisierung.
