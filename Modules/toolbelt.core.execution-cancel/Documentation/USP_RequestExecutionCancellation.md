# toolbelt_core.USP_RequestExecutionCancellation

## Zweck

Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.

## Verhalten und Ergebnis

Nimmt optional eine `ExecutionId` und einen höchstens 512 Zeichen langen,
nicht sensiblen Grund entgegen. Ohne ID verwendet die Procedure die aktuelle
ExecutionId aus `toolbelt.core.execution-context`. Wiederholte Anforderungen
lassen den ersten Auditzeitpunkt und Grund unverändert. Die Procedure liefert
kein fachliches Resultset; der Status wird über die TVF abgefragt.

Der Aufruf benötigt eine Session ohne aktive Transaktion. Fehler `52600` bis
`52604` bezeichnen Parameter-, Context- oder Transaktionsfehler. Die Procedure
führt weder `KILL` aus noch requeued oder terminalisiert sie Work-Queue-Items.

`@Hilfe = 1` gibt vor Transaktions- und Contextprüfung das standardisierte
12-Spalten-Help-Resultset mit Parametern, Fehlerbereich, fehlendem Fachresultset
und vollständigem Beispielaufruf aus. Der Help-Aufruf speichert keine
Cancellation-Anforderung.

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation
    @CancellationReason = N'planned maintenance';

SELECT *
FROM toolbelt_core.TVF_ExecutionCancellationStatus
    (toolbelt_core.SVF_CurrentExecutionId());
```

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CANCELLATION_OBJECTS](EXECUTION_CANCELLATION_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL. |
| `@CancellationReason` | `nvarchar(512)` | `NULL` | Input | Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Transaktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N'planned maintenance';
```

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation
    @CancellationReason = N'planned maintenance';

SELECT *
FROM toolbelt_core.TVF_ExecutionCancellationStatus
    (toolbelt_core.SVF_CurrentExecutionId());
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RequestExecutionCancellation.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
