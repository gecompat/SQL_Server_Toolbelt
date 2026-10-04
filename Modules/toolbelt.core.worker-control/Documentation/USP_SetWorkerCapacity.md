# USP_SetWorkerCapacity

Ändert die Live-Capacity einer exakten Workergeneration ohne Übernahme oder Abbruch laufender Arbeit.

Öffentliche Worker-Control-Fassade.

## Parameter

- `@WorkerId uniqueidentifier = NULL`
- `@WorkerGeneration bigint = NULL`
- `@Capacity int = NULL`
- `@ExpectedConfigVersion binary(8) = NULL`
- `@ResultTable sysname = NULL`
- `@KeepData bit = 0`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

## Ergebnis

WorkerId uniqueidentifier NOT NULL; WorkerGeneration bigint NOT NULL; Capacity int NOT NULL; ConfigVersion binary(8) NOT NULL

Hilfe zuerst ohne Fachprüfung; Debug nur Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Sourcevorbereitung: not executed, unreleased.
