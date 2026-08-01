# Work-Type-Katalog – Moduldesign

## Sicherheitsgrenze

`toolbelt.core.work-type` ist ein persistenter Katalog, aber kein allgemeiner SQL-Executor. Ein Work Type verweist ausschließlich auf eine vorhandene Stored Procedure derselben Datenbank. SQL-Text, Batch-Text, frei zusammengesetzte Commands und versteckte Raw-SQL-Optionen sind ausgeschlossen.

## Parametervertrag

Version 1 kennt nur `NONE` und `JSON_PAYLOAD`. Der JSON-Vertrag ist deklarative Metadaten. Eine spätere Ausführung darf daraus keine ungeprüfte dynamische Parameterliste erzeugen. Ein Session-Provider muss je Mode eine feste parametrisierte Aufrufoberfläche besitzen.

## Mutation und Concurrency

Registrierungen werden unter `UPDLOCK, HOLDLOCK` serialisiert. Exakte Wiederholungen verändern die Zeile nicht. Konfigurationsänderungen benötigen `@AllowUpdate`; Reaktivierung benötigt ein eigenes Flag. Optionales `@ExpectedRowVersion` schützt administrative Änderungen vor Lost Updates.

## Persistenz und Lifecycle

Die interne Tabelle `toolbelt_core.WorkType` bleibt bei Redeploy erhalten. Uninstall mit vorhandenen Zeilen benötigt `AllowDataLoss = 1`. Zentrale Installation registriert ausschließlich Handler in der zentralen Toolbelt-Datenbank.

## Berechtigungen

Das Modul erweitert keine Rechte. Registrierung verlangt, dass der aufrufende Principal die Zielprocedure ausführen darf. Rechte für einen späteren Second-Session-Provider werden separat entschieden und nicht aus der Registrierung abgeleitet.
