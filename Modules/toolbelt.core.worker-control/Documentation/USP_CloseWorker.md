# USP_CloseWorker

Schließt ausschließlich eine Generation ohne belegte oder ungeklärte Reservations.

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
