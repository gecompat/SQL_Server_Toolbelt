# USP_ClaimWorkerWork

Fachliche Fassade der privaten atomaren Managed-Admission.

Öffentliche Steuerfassade.

## Parameter

- `@WorkerId uniqueidentifier=NULL`
- `@WorkerGeneration bigint=NULL`
- `@WorkerToken uniqueidentifier=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

WorkItemId bigint NOT NULL; WorkTypeName varchar(128) NOT NULL; PayloadJson nvarchar(max) NULL; ClaimToken uniqueidentifier NOT NULL; ClaimedAtUtc datetime2(7) NOT NULL; ClaimGeneration bigint NOT NULL; LeaseUntilUtc datetime2(7) NOT NULL; LastHeartbeatAtUtc datetime2(7) NOT NULL; SlotReservationId uniqueidentifier NOT NULL; ExecutionId uniqueidentifier NOT NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Privates Token aus derselben Registrierung; nicht protokollieren oder veröffentlichen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ClaimWorkerWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
