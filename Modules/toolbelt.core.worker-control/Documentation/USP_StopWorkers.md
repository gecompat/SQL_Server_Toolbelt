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

Hilfe zuerst ohne fachliche Mutation; Debug erzeugt hier keine eigenen Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Nachweise und offene Grenzen: [Modulstatus](../README.md); unveröffentlicht.

Der interne Locktimeout wird mit einem SQL2019-kompatiblen Literal ausschließlich im Stored-Procedure-Scope gesetzt. SQL Server restauriert die SET-Option beim Return oder THROW im Aufruferkontext; variable Restore-SETs und dynamische Restoreversuche werden nicht verwendet. Die Basicfixture prüft tatsächlich Caller1234 nach Erfolg und Fehler. Grundlage: [Microsoft SET Statements](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statements-transact-sql?view=sql-server-ver17). Die aktuelle Nachweisabgrenzung steht im [Modulstatus](../README.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Input | Fachlich erforderlicher sysname einer vorhandenen caller-lokalen #Temp-Tabelle, keine ##Temp/persistente oder mehrteilige Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten: WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. 0..1000 eindeutige (WorkerId,WorkerGeneration)-Paare, Generation &gt;0, jede exakte Generation muss existieren. Doppelpaare werden abgewiesen; leere Auswahl ist ein No-op. Die Auswahl wird vor Stop eingefroren, maximal 100000 Reservations; Beispiel CREATE TABLE #Workers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL). |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Aktuelle Nachweise und Grenzen stehen im [Modulstatus](../README.md).

## Beispielaufruf

Zusammenhängende Betriebsbeispiele mit Beschaffung der IDs/Versionen und
Ergebnisdeutung: [Worker starten und steuern](../../../Workers/ExternalQueue/USAGE.md).
Ein untenstehender `@Hilfe=1`-Aufruf liest nur die Referenz, er führt keine
Workeraktion aus.

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
```

## Hilfe und Fehlerklärung

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_StopWorkers.md)
steht auch in der kanonischen DDL. `@Hilfe=1` ergänzt die Standardhilfe um
eine vollständige Skillzeile mit `SkillFormatVersion`, `SchemaName`,
`ObjectName` und `SkillMarkdown nvarchar(max)`. Die Referenz beschreibt
Prüfreihenfolge, genaue Statusbedeutung, Transaktionsgrenzen und tatsächliche
Berechtigungsbindung. RETURN0 allein ist kein Handlercommit-/Rollbackbeweis.
Historische Nachweise behalten ihre eigene Ziel- und Artefaktbindung.

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
