# USP_SetWorkerState

Steuert ACTIVE, PAUSED oder DRAINING einer exakten lebenden Workergeneration.

Öffentliche Worker-Control-Fassade.

## Parameter

- `@WorkerId uniqueidentifier = NULL`
- `@WorkerGeneration bigint = NULL`
- `@RequestedState varchar(16) = NULL`
- `@ExpectedConfigVersion binary(8) = NULL`
- `@ResultTable sysname = NULL`
- `@KeepData bit = 0`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

## Ergebnis

WorkerId uniqueidentifier NOT NULL; WorkerGeneration bigint NOT NULL; State varchar(16) NOT NULL; ConfigVersion binary(8) NOT NULL

Hilfe zuerst ohne Fachprüfung; Debug nur Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Sourcevorbereitung: not executed, unreleased.

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Stabile eigene Workeridentität; NULL bei Registrierung erzeugt eine neue Identität. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte Generation der eigenen Registrierung. |
| `@RequestedState` | `varchar(16)` | `NULL` | Input | Expliziter administrativer Übergang gemäß Worker-Control-Zustandsvertrag. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Exakte aktuelle binary(8)-Konfigurationsversion; veraltete Werte blockieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert ein fachliches Resultset; sonst vorhandene caller-lokale Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 ersetzt, 1 ergänzt die vorbereitete ResultTable atomar. |
| `@Debug` | `tinyint` | `0` | Input | Optionale abstrakte Diagnose ohne Tokens oder vertrauliche Nutzdaten. |
| `@Hilfe` | `bit` | `0` | Input | 1 liefert ausschließlich den Help-Vertrag ohne Mutation. |

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_SetWorkerState.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
