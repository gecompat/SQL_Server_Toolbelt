# USP_SetWorkerIntervals

Ändert Intervalldefaults ausschließlich für künftig registrierte Generationen.

Öffentliche Worker-Control-Fassade.

## Parameter

- `@HeartbeatSeconds int = NULL`
- `@UnreachableSeconds int = NULL`
- `@ExpectedConfigVersion binary(8) = NULL`
- `@ResultTable sysname = NULL`
- `@KeepData bit = 0`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

## Ergebnis

ConfigVersion binary(8) NOT NULL; HeartbeatSeconds int NOT NULL; UnreachableSeconds int NOT NULL

Hilfe zuerst ohne Fachprüfung; Debug erzeugt hier keine eigenen Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Nachweise und offene Grenzen: [Modulstatus](../README.md); unveröffentlicht.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@HeartbeatSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..3600 Sekunden. NULL ist ungültig; der technische NULL-Default bedeutet nicht den ursprünglichen Konfigurationswert 15. Wirkt als Registrierungsdefault nur für künftig erzeugte Generationen. |
| `@UnreachableSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 3..86400 Sekunden und mindestens 3*HeartbeatSeconds. NULL ist ungültig, nicht der ursprüngliche Konfigurationswert 60. Bestehende Generationen behalten die bei Registrierung kopierten Intervalle. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
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
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;
```

## Hilfe und Fehlerklärung

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_SetWorkerIntervals.md)
steht auch in der kanonischen DDL. `@Hilfe=1` liefert zusätzlich zur bisherigen
Standardhilfe genau eine Skillzeile mit `SkillFormatVersion`, `SchemaName`,
`ObjectName` und `SkillMarkdown nvarchar(max)`. Fachliche NULL-Defaults sind
nur für die Hilfe zulässig. Jeder erfolgreiche Konfigurationsaufruf ändert die
Version auch bei identischen Werten; für den nächsten Aufruf die neue Version
übernehmen. ResultTable-Routing liegt vor Commit in derselben Transaktion.

```sql
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_SetWorkerIntervals.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
