# Work-Type-Katalog – Moduldesign

## Sicherheitsgrenze

`toolbelt.core.work-type` ist ein persistenter Katalog, aber kein allgemeiner SQL-Executor. Ein Work Type verweist ausschließlich auf eine vorhandene Stored Procedure derselben Datenbank. SQL-Text, Batch-Text, frei zusammengesetzte Commands und versteckte Raw-SQL-Optionen sind ausgeschlossen.

## Parametervertrag

Version 1 kennt nur `NONE` und `JSON_PAYLOAD`. Der JSON-Vertrag ist deklarative Metadaten. Eine spätere Ausführung darf daraus keine ungeprüfte dynamische Parameterliste erzeugen. Ein Session-Provider muss je Mode eine feste parametrisierte Aufrufoberfläche besitzen.

## Mutation und Concurrency

Registrierungen werden unter `UPDLOCK, HOLDLOCK` serialisiert. Exakte Wiederholungen verändern die Zeile nicht. Konfigurationsänderungen benötigen `@AllowUpdate`; Reaktivierung benötigt ein eigenes Flag. Optionales `@ExpectedRowVersion` schützt administrative Änderungen vor Lost Updates.

Version `1.1.0` ergänzt eine bewusst getrennte Removal-Operation. Ein Work Type muss zuerst deaktiviert werden. Die eigentliche Entfernung benötigt `@AllowDelete = 1` und kann zusätzlich mit der erwarteten `rowversion` abgesichert werden. Dadurch bleibt die normale Deaktivierung reversibel, während die irreversible Löschung weder versehentlich noch auf einer veralteten Katalogsicht erfolgt.

## Transaktionsvertrag

Register, Disable und Remove verwenden eine eigene Transaktion oder bei vorhandener Caller-Transaktion einen Modul-Savepoint. Erwartete Fehler rollen nur die jeweilige Modulmutation zurück. Eine Katalogmutation bei `XACT_STATE() = -1` ist nicht möglich; `USP_RemoveWorkType` lehnt diesen Zustand vor der ersten Mutation ab.

## Persistenz und Lifecycle

Die interne Tabelle `toolbelt_core.WorkType` bleibt bei Redeploy erhalten. Uninstall mit vorhandenen Zeilen benötigt `AllowDataLoss = 1`. Zentrale Installation registriert ausschließlich Handler in der zentralen Toolbelt-Datenbank.

Modulabhängige Capabilities dürfen ihren eigenen Work Type beim Uninstall nur über den öffentlichen Ablauf Disable → Remove abbauen. Direkte DML auf `toolbelt_core.WorkType` bleibt außerhalb des öffentlichen Vertrags.

## Berechtigungen

Das Modul erweitert keine Rechte. Registrierung verlangt, dass der aufrufende Principal die Zielprocedure ausführen darf. Rechte für einen Second-Session- oder Worker-Provider werden separat entschieden und nicht aus der Registrierung abgeleitet.
