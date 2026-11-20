---
name: "toolbelt-toolbelt-toolbelt-core-usp-captureerrorenvelope"
description: "Erzeugt aus explizit im aufrufenden CATCH gelesenen ERROR_*-Werten genau eine standardisierte Fehlerzeile. Die Procedure führt keinen Rethrow aus; der Aufrufer verwendet anschließend THROW; im ursprünglichen CATCH."
skill_format_version: "1.0"
module_id: "toolbelt.core.error-envelope"
schema_name: "toolbelt_core"
object_name: "USP_CaptureErrorEnvelope"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ErrorNumber", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlich: positive int-Fehlernummer 1..2147483647, üblicherweise ERROR_NUMBER() im aufrufenden CATCH. Technischer Default NULL dient nur Help; NULL/<=0 wird 51400."}, {"name": "@ErrorSeverity", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlich: int 0..25 einschließlich, üblicherweise ERROR_SEVERITY() aus demselben CATCH. NULL/außerhalb ergibt 51401; technischer Default NULL nur für Help."}, {"name": "@ErrorState", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlich: int 0..255 einschließlich aus ERROR_STATE() im CATCH. NULL/außerhalb ergibt 51402; technischer Default NULL nur für Help."}, {"name": "@ErrorProcedure", "sql_type": "nvarchar(776)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler reiner Unicode-Text nvarchar(776), normalerweise ERROR_PROCEDURE() im CATCH, kein auszuführender Objektname. NULL bleibt NULL, leerer Text wird nicht besonders validiert."}, {"name": "@ErrorLine", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL (Default) ist erlaubt, 0/negativ ergibt 51403."}, {"name": "@ErrorMessage", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher Unicode-Fehlertext nvarchar(4000), normalerweise ERROR_MESSAGE() im CATCH. NULL, leer und nach SQL-Gleichheit leere reine Spacefolgen ergeben 51404; keine automatische Redigierung geheimer Inhalte."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier). Default/NULL liest toolbelt.execution.id aus SESSION_CONTEXT mit TRY_CONVERT; fehlender/ungültiger Kontext bleibt NULL. Eine explizite ID muss keinem gespeicherten Kontext entsprechen."}, {"name": "@AdditionalContext", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(4000), kein vorgeschriebenes JSON-Schema und keine Ausführung. NULL/leer wird unverändert ausgegeben; nur bereits bereinigte, für den Empfänger zulässige Zusatzinformation übergeben."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) gibt eine direkte Fehlerzeile aus, auch bei XACT_STATE()=-1. Sonst Name einer bereits vom Caller angelegten lokalen #Temp-Tabelle als sysname, z.B. N'#Envelope', keine globale oder mehrteilige Tabelle; ResultTable-Helper nötig. Bei uncommittable Caller zuerst Rollback, sonst 51406."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 bereitet Replace vor (Default), 1 hängt bei kompatibler ResultTable an; NULL wird vom kanonischen Helper wie 0 behandelt. Nur bei nicht-NULL ResultTable relevant."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) und NULL ohne Diagnose; 1..255 erzeugen eine abstrakte Informationsmeldung ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur Hilfe vor Fachvalidierung; 0 (Default) und NULL führen die Fachoperation aus. Im Hilfemodus sind die fachlich erforderlichen Error*-Werte nicht nötig."}]
source_paths: ["Modules/toolbelt.core.error-envelope/Source/USP_CaptureErrorEnvelope.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_CaptureErrorEnvelope

## Zweck und Einsatzfälle

Erzeugt aus explizit im aufrufenden CATCH gelesenen ERROR_*-Werten genau eine standardisierte Fehlerzeile. Die Procedure führt keinen Rethrow aus; der Aufrufer verwendet anschließend THROW; im ursprünglichen CATCH.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

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

## Ergebnisse

UTC-Zeitpunkt der Erfassung.

Explizite oder aus SESSION_CONTEXT gelesene Execution-ID.

ENGINE, TOOLBELT oder USER.

## Aufrufbeispiele

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

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Validierungs- und Dependencyfehler des Moduls.

ResultTable-Ausgabe bei XACT_STATE()=-1 wird vor jeder Schreiboperation abgewiesen. Direkte Ausgabe bleibt lesend möglich.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.error-envelope/Documentation/USP_CaptureErrorEnvelope.md`

Keine Installations-, Definitions- oder Rechteattestation.
