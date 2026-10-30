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

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@ErrorNumber` | `int` | `NULL` | Input | ERROR_NUMBER() aus dem aufrufenden CATCH. |
| `@ErrorSeverity` | `int` | `NULL` | Input | ERROR_SEVERITY() aus dem aufrufenden CATCH. |
| `@ErrorState` | `int` | `NULL` | Input | ERROR_STATE() aus dem aufrufenden CATCH. |
| `@ErrorProcedure` | `nvarchar(776)` | `NULL` | Input | ERROR_PROCEDURE() aus dem aufrufenden CATCH. |
| `@ErrorLine` | `int` | `NULL` | Input | ERROR_LINE() aus dem aufrufenden CATCH. |
| `@ErrorMessage` | `nvarchar(4000)` | `NULL` | Input | ERROR_MESSAGE() aus dem aufrufenden CATCH. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Optionale Execution-ID; NULL liest den aktiven Toolbelt Execution Context. |
| `@AdditionalContext` | `nvarchar(4000)` | `NULL` | Input | Optionale synthetische oder bereits bereinigte Zusatzinformation. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für das Ergebnis. |
| `@KeepData` | `bit` | `0` | Input | Steuert die ResultTable-Vorbereitung. |
| `@Debug` | `tinyint` | `0` | Input | Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung. |
| `@Hilfe` | `bit` | `0` | Input | 1 gibt ausschließlich dieses Help-Resultset aus. |

## Beispielaufruf

```sql
BEGIN TRY
    THROW 50000,N'Synthetischer Beispielfehler',1;
END TRY
BEGIN CATCH
    DECLARE @Number int=ERROR_NUMBER(), @Severity int=ERROR_SEVERITY(),
            @State int=ERROR_STATE(), @Line int=ERROR_LINE(),
            @Procedure nvarchar(128)=ERROR_PROCEDURE(),
            @Message nvarchar(4000)=ERROR_MESSAGE();
    EXEC toolbelt_core.USP_CaptureErrorEnvelope
      @ErrorNumber=@Number, @ErrorSeverity=@Severity, @ErrorState=@State,
      @ErrorProcedure=@Procedure, @ErrorLine=@Line, @ErrorMessage=@Message;
END CATCH;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_CaptureErrorEnvelope.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
