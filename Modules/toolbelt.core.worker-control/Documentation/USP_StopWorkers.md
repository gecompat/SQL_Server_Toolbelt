# USP_StopWorkers

Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen.

Öffentliche Steuerfassade.

## Parameter

- `@WorkersTable sysname=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

WorkerId uniqueidentifier NOT NULL; WorkerGeneration bigint NOT NULL; SlotReservationId uniqueidentifier NULL; StopStatus varchar(24) NOT NULL; HoldVersion binary(8) NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

Der interne Locktimeout wird mit einem SQL2019-kompatiblen Literal ausschließlich im Stored-Procedure-Scope gesetzt. SQL Server restauriert die SET-Option beim Return oder THROW im Aufruferkontext; variable Restore-SETs und dynamische Restoreversuche werden nicht verwendet. Die Basicfixture prüft tatsächlich Caller1234 nach Erfolg und Fehler. Grundlage: [Microsoft SET Statements](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statements-transact-sql?view=sql-server-ver17). Laufzeitqualifikation dieser USPs bleibt bis erfolgreichem Test offen.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Input | Vorhandene lokale Temp-Tabelle mit WorkerId uniqueidentifier NOT NULL und WorkerGeneration bigint NOT NULL. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_StopWorkers.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
