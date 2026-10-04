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
