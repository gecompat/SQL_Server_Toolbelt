# toolbelt_core.SVF_IsCancellationRequested

## Zweck

Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.

## Verhalten und Ergebnis

Liefert `1`, wenn für die übergebene `ExecutionId` eine persistierte
Cancellation-Anforderung existiert, andernfalls `0`. Der Wrapper eignet sich
für kleine Worker-Checkpoints.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CANCELLATION_OBJECTS](EXECUTION_CANCELLATION_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Kontextfallback. Rückgabe 1 bei vorhandener Anforderung, sonst 0, ausdrücklich auch bei NULL. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS ResultValue;
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_IsCancellationRequested.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
