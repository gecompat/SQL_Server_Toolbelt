# Error-Envelope-Moduldesign

Das Modul kapselt die Ausgabeform, nicht den Fehlerfang selbst. Die `ERROR_*`-Funktionen werden im ursprünglichen `CATCH` ausgewertet und explizit übergeben. Dadurch bleibt der anschließende parameterlose `THROW;` im selben `CATCH` möglich und Enginefehler werden nicht umnummeriert.

Version 1 speichert nichts persistent, entscheidet nicht über Retry und schreibt keine Logs. Eine spätere Logging-Capability konsumiert den Envelope, besitzt aber einen getrennten Lifecycle.
