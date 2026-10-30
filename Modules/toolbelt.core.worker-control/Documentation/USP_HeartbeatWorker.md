# USP_HeartbeatWorker

Erneuert ausschließlich die aktuelle lebende Workergeneration ohne Claims zu übernehmen.

Öffentliche Worker-Control-Fassade.

## Parameter

- `@WorkerId uniqueidentifier = NULL`
- `@WorkerGeneration bigint = NULL`
- `@WorkerToken uniqueidentifier = NULL`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

## Ergebnis

Kein fachliches Resultset.

Hilfe zuerst ohne Fachprüfung; Debug nur Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Sourcevorbereitung: not executed, unreleased.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Privates Token aus derselben Registrierung; nicht protokollieren oder veröffentlichen. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_HeartbeatWorker.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
