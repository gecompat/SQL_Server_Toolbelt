# USP_RegisterWorker

Registriert eine neue principal- und generationgebundene Workeridentität; übernimmt keine alten Reservations.

Öffentliche Worker-Control-Fassade.

## Parameter

- `@WorkerId uniqueidentifier = NULL`
- `@Capacity int = NULL`
- `@RunMode varchar(16) = 'BOUNDED'`
- `@ResultTable sysname = NULL`
- `@KeepData bit = 0`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

## Ergebnis

WorkerId uniqueidentifier NOT NULL; WorkerGeneration bigint NOT NULL; WorkerToken uniqueidentifier NOT NULL; ConfigVersion binary(8) NOT NULL

Hilfe zuerst ohne Fachprüfung; Debug nur Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Sourcevorbereitung: not executed, unreleased.

Bei Neuregistrierung werden frühere nichtterminale ACTIVE/PAUSED-Generationen desselben WorkerId auf DRAINING gesetzt. Sie erhalten keine neuen Claims; vorhandene Reservations bleiben belegt und können ihre gebundenen Abschlusswege verwenden. Die dauerhafte AdmissionPaused-Entscheidung wird unverändert in die neue Generation übernommen.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING. |
| `@Capacity` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich. |
| `@RunMode` | `varchar(16)` | `'BOUNDED'` | Input | Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RegisterWorker.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
