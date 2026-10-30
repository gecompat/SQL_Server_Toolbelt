# USP_StopWorkerExecution

Persistiert generationgebunden Stop und Hold vor Providerabbruch; Completiongewinner bleibt committed.

Öffentliche Steuerfassade.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@ExpectedClaimGeneration bigint=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

SlotReservationId uniqueidentifier NOT NULL; ExecutionId uniqueidentifier NOT NULL; StopStatus varchar(24) NOT NULL; HoldVersion binary(8) NOT NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | Exakte eigene Reservation; niemals eine Sessionnummer. |
| `@ExpectedClaimGeneration` | `bigint` | `NULL` | Input | Exakte Claim-Generation der ausgewählten Verarbeitung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_StopWorkerExecution.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
