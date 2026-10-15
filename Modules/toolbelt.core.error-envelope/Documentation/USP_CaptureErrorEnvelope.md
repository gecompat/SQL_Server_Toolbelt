# `toolbelt_core.USP_CaptureErrorEnvelope`

Die Procedure wird innerhalb eines `CATCH` aufgerufen. `ERROR_NUMBER()`, `ERROR_SEVERITY()`, `ERROR_STATE()`, `ERROR_PROCEDURE()`, `ERROR_LINE()` und `ERROR_MESSAGE()` werden dort ausgewertet und explizit übergeben. Dadurch bleibt die Fehlerquelle eindeutig und der Aufrufer kann anschließend mit `THROW;` unverändert weiterwerfen.

`@ResultTable` ist optional und bezeichnet eine vorhandene lokale Temp-Tabelle. `@KeepData` folgt dem ResultTable-Vertrag. Ohne `@ResultTable` entsteht genau eine Ergebniszeile.

Die direkte Ausgabe verwendet weder Temp-DDL noch INSERT und ist deshalb auch
bei `XACT_STATE()=-1` möglich. Die Procedure führt keinen Rollback aus und
verändert die Callertransaktion nicht. Der Aufrufer kann den ursprünglichen
Fehler anschließend mit `THROW;` erhalten. Eine ResultTable-Ausgabe wird in
diesem Zustand vor jeder Schreiboperation mit `51406` abgewiesen; dafür muss
der Aufrufer zuerst zurückrollen. `@Debug>0` liefert auch im direkten Pfad die
abstrakte Informationsmeldung. Typen und Nullability bleiben erhalten.

Die Klassifikation ist bewusst klein: 51000 bis 51999 sind `TOOLBELT`, Enginefehler unter 50000 sind `ENGINE`, andere benutzerdefinierte Fehler sind `USER`. Daraus wird keine automatische Retry-Entscheidung abgeleitet.
