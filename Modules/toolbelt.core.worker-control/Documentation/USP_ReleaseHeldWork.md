# USP_ReleaseHeldWork

Beginnt ausschließlich nach bewiesenem Rollback eine explizite neue Retryphase; UNKNOWN und COMPLETED bleiben gesperrt.

Öffentliche Steuerfassade.

## Parameter

- `@WorkItemId bigint=NULL`
- `@ExpectedHoldVersion binary(8)=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

WorkItemId bigint NOT NULL; ClaimGeneration bigint NOT NULL; Status varchar(16) NOT NULL; HoldVersion binary(8) NOT NULL

Hilfe zuerst ohne fachliche Mutation; Debug erzeugt hier keine eigenen Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Nachweise und offene Grenzen: [Modulstatus](../README.md); unveröffentlicht.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. |
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
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;
```

## Hilfe und Fehlerklärung

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_ReleaseHeldWork.md)
steht auch in der kanonischen DDL. `@Hilfe=1` ergänzt die Standardhilfe um
eine vollständige Skillzeile mit `SkillFormatVersion`, `SchemaName`,
`ObjectName` und `SkillMarkdown nvarchar(max)`. Die Referenz beschreibt
Prüfreihenfolge, genaue Statusbedeutung, Transaktionsgrenzen und tatsächliche
Berechtigungsbindung. RETURN0 allein ist kein Handlercommit-/Rollbackbeweis.
Historische Nachweise behalten ihre eigene Ziel- und Artefaktbindung.

```sql
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ReleaseHeldWork.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
