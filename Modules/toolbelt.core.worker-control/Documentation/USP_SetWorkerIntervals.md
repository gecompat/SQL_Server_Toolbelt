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

Hilfe zuerst ohne Fachprüfung; Debug nur Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Sourcevorbereitung: not executed, unreleased.
