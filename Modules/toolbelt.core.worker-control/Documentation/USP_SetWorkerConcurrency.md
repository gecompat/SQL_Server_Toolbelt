# USP_SetWorkerConcurrency

Ändert das globale Live-Admissionbudget versionsgebunden ohne laufende Arbeit abzubrechen.

Öffentliche Worker-Control-Fassade.

## Parameter

- `@MaxConcurrentExecutions int = NULL`
- `@ExpectedConfigVersion binary(8) = NULL`
- `@ResultTable sysname = NULL`
- `@KeepData bit = 0`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

## Ergebnis

ConfigVersion binary(8) NOT NULL; MaxConcurrentExecutions int NOT NULL; OccupiedSlots bigint NOT NULL

Hilfe zuerst ohne Fachprüfung; Debug nur Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Sourcevorbereitung: not executed, unreleased.
