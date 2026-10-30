# USP_ReconcileWorkerExecution

Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.

Öffentliche Steuerfassade.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@ExpectedHoldVersion binary(8)=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

SlotReservationId uniqueidentifier NOT NULL; Outcome varchar(24) NOT NULL; Occupied bit NOT NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

Der Witnessnachweis verwendet UPDLOCK und HOLDLOCK (serialisierbarer Schlüssel-/Absencebereich) innerhalb der kurzen Reconciletransaktion. Dadurch wird auch bei RCSI keine ältere Snapshotversion als Rollbacknachweis verwendet. Der Attemptsessionlock und dieser Bereichsschutz bleiben bis zum Commit bestehen. READCOMMITTEDLOCK wird nicht zusätzlich kombiniert, weil er HOLDLOCK widerspricht.

Der interne Locktimeout wird mit einem SQL2019-kompatiblen Literal ausschließlich im Stored-Procedure-Scope gesetzt. SQL Server restauriert die SET-Option beim Return oder THROW im Aufruferkontext; variable Restore-SETs und dynamische Restoreversuche werden nicht verwendet. Die Basicfixture prüft tatsächlich Caller1234 nach Erfolg und Fehler. Grundlage: [Microsoft SET Statements](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statements-transact-sql?view=sql-server-ver17). Laufzeitqualifikation dieser USPs bleibt bis erfolgreichem Test offen.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. Der Code prüft Sessionfence und Commitwitness; fehlende Beweisbarkeit bleibt UNKNOWN und ist keine Freigabe zum Replay. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ReconcileWorkerExecution.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
