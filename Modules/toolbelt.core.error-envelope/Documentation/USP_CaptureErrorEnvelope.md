# `toolbelt_core.USP_CaptureErrorEnvelope`

Die Procedure wird innerhalb eines `CATCH` aufgerufen. `ERROR_NUMBER()`, `ERROR_SEVERITY()`, `ERROR_STATE()`, `ERROR_PROCEDURE()`, `ERROR_LINE()` und `ERROR_MESSAGE()` werden dort ausgewertet und explizit übergeben. Dadurch bleibt die Fehlerquelle eindeutig und der Aufrufer kann anschließend mit `THROW;` unverändert weiterwerfen.

`@ResultTable` ist optional und bezeichnet eine vorhandene lokale Temp-Tabelle. `@KeepData` folgt dem ResultTable-Vertrag. Ohne `@ResultTable` entsteht genau eine Ergebniszeile.

Die Klassifikation ist bewusst klein: 51000 bis 51999 sind `TOOLBELT`, Enginefehler unter 50000 sind `ENGINE`, andere benutzerdefinierte Fehler sind `USER`. Daraus wird keine automatische Retry-Entscheidung abgeleitet.
