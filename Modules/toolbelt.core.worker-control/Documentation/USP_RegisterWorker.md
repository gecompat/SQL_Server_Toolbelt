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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@Capacity` | `int` | `NULL` | Input | Lokales positives int-Budget, zur Laufzeit steuerbar; keine Kapazitätszusage. |
| `@RunMode` | `varchar(16)` | `'BOUNDED'` | Input | BOUNDED oder ausdrücklich CONTINUOUS; Default BOUNDED. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

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

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RegisterWorker.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
