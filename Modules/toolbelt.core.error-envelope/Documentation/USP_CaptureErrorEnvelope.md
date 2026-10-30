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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ErrorNumber` | `int` | `NULL` | Input | Fachlich erforderlich: positive int-Fehlernummer 1..2147483647, üblicherweise ERROR_NUMBER() im aufrufenden CATCH. Technischer Default NULL dient nur Help; NULL/&lt;=0 wird 51400. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Fachlich erforderlich: int 0..25 einschließlich, üblicherweise ERROR_SEVERITY() aus demselben CATCH. NULL/außerhalb ergibt 51401; technischer Default NULL nur für Help. |
| `@ErrorState` | `int` | `NULL` | Input | Fachlich erforderlich: int 0..255 einschließlich aus ERROR_STATE() im CATCH. NULL/außerhalb ergibt 51402; technischer Default NULL nur für Help. |
| `@ErrorProcedure` | `nvarchar(776)` | `NULL` | Input | Optionaler reiner Unicode-Text nvarchar(776), normalerweise ERROR_PROCEDURE() im CATCH, kein auszuführender Objektname. NULL bleibt NULL, leerer Text wird nicht besonders validiert. |
| `@ErrorLine` | `int` | `NULL` | Input | Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL (Default) ist erlaubt, 0/negativ ergibt 51403. |
| `@ErrorMessage` | `nvarchar(4000)` | `NULL` | Input | Fachlich erforderlicher Unicode-Fehlertext nvarchar(4000), normalerweise ERROR_MESSAGE() im CATCH. NULL, leer und nach SQL-Gleichheit leere reine Spacefolgen ergeben 51404; keine automatische Redigierung geheimer Inhalte. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Optionaler SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier). Default/NULL liest toolbelt.execution.id aus SESSION_CONTEXT mit TRY_CONVERT; fehlender/ungültiger Kontext bleibt NULL. Eine explizite ID muss keinem gespeicherten Kontext entsprechen. |
| `@AdditionalContext` | `nvarchar(4000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(4000), kein vorgeschriebenes JSON-Schema und keine Ausführung. NULL/leer wird unverändert ausgegeben; nur bereits bereinigte, für den Empfänger zulässige Zusatzinformation übergeben. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) gibt eine direkte Fehlerzeile aus, auch bei XACT_STATE()=-1. Sonst Name einer bereits vom Caller angelegten lokalen #Temp-Tabelle als sysname, z.B. N'#Envelope', keine globale oder mehrteilige Tabelle; ResultTable-Helper nötig. Bei uncommittable Caller zuerst Rollback, sonst 51406. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 bereitet Replace vor (Default), 1 hängt bei kompatibler ResultTable an; NULL wird vom kanonischen Helper wie 0 behandelt. Nur bei nicht-NULL ResultTable relevant. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) und NULL ohne Diagnose; 1..255 erzeugen eine abstrakte Informationsmeldung ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur Hilfe vor Fachvalidierung; 0 (Default) und NULL führen die Fachoperation aus. Im Hilfemodus sind die fachlich erforderlichen Error*-Werte nicht nötig. |
<!-- API_PARAMETERS:END -->

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
