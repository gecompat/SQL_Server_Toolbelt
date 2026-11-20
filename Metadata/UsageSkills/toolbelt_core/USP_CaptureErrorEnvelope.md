---
name: "toolbelt-core-usp-captureerrorenvelope"
description: "Formatiert explizit übergebene Fehlerdaten mit aktuellem Ausführungskontext als eine Fehlerzeile."
skill_format_version: "1.0"
module_id: "toolbelt.core.error-envelope"
schema_name: "toolbelt_core"
object_name: "USP_CaptureErrorEnvelope"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ErrorNumber", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlich: positive int-Fehlernummer 1..2147483647, üblicherweise ERROR_NUMBER() im aufrufenden CATCH. Technischer Default NULL dient nur Help; NULL/<=0 wird 51400."}, {"name": "@ErrorSeverity", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlich: int 0..25 einschließlich, üblicherweise ERROR_SEVERITY() aus demselben CATCH. NULL/außerhalb ergibt 51401; technischer Default NULL nur für Help."}, {"name": "@ErrorState", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlich: int 0..255 einschließlich aus ERROR_STATE() im CATCH. NULL/außerhalb ergibt 51402; technischer Default NULL nur für Help."}, {"name": "@ErrorProcedure", "sql_type": "nvarchar(776)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler reiner Unicode-Text nvarchar(776), normalerweise ERROR_PROCEDURE() im CATCH, kein auszuführender Objektname. NULL bleibt NULL, leerer Text wird nicht besonders validiert."}, {"name": "@ErrorLine", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL (Default) ist erlaubt, 0/negativ ergibt 51403."}, {"name": "@ErrorMessage", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher Unicode-Fehlertext nvarchar(4000), normalerweise ERROR_MESSAGE() im CATCH. NULL, leer und nach SQL-Gleichheit leere reine Spacefolgen ergeben 51404; keine automatische Redigierung geheimer Inhalte."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler SQL-uniqueidentifier, Default NULL. NULL liest SESSION_CONTEXT(N'toolbelt.execution.id') mit TRY_CONVERT(uniqueidentifier,...); fehlende oder nicht parsebare Werte können NULL ergeben, ausdrücklich nicht unterstützte Konvertierungen behalten Enginefehler. Explizite ID wird unverändert übernommen und muss keinem gespeicherten Kontext entsprechen. Kein automatischer Kontextschreibzugriff."}, {"name": "@AdditionalContext", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(4000), kein vorgeschriebenes JSON-Schema und keine Ausführung. NULL/leer wird unverändert ausgegeben; nur bereits bereinigte, für den Empfänger zulässige Zusatzinformation übergeben."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) gibt eine direkte Fehlerzeile aus, auch bei XACT_STATE()=-1. Sonst Name einer bereits vom Caller angelegten lokalen #Temp-Tabelle als sysname, z.B. N'#Envelope', keine globale oder mehrteilige Tabelle; ResultTable-Helper nötig. Bei uncommittable Caller zuerst Rollback, sonst 51406."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 bereitet Replace vor (Default), 1 hängt bei kompatibler ResultTable an; NULL wird vom kanonischen Helper wie 0 behandelt. Nur bei nicht-NULL ResultTable relevant."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) und NULL ohne Diagnose; 1..255 erzeugen eine abstrakte Informationsmeldung ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe plus genau ein vierkolumniges Skill-Resultset und kehrt vor Fachprüfungen und Fachausgabe zurück. 0 oder NULL führt den Normalpfad aus. Alle übrigen Parameter werden bei Hilfe fachlich ignoriert; ihre SQL-Typbindung gilt weiterhin."}]
source_paths: ["Modules/toolbelt.core.error-envelope/Source/USP_CaptureErrorEnvelope.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_CaptureErrorEnvelope

## Zweck und Einsatzfälle

Explizit vom Caller übergebene CATCH-Fehlerdaten in ein einheitliches Resultat überführen. Keine automatische Auswertung eines fremden CATCH, kein Abfangen oder Wiederwerfen des ursprünglichen Fehlers und kein persistenter Logger. Der Caller liest ERROR_NUMBER/SEVERITY/STATE/PROCEDURE/LINE/MESSAGE selbst in Variablen und übergibt sie.

## Voraussetzungen

Installierte T-SQL-Prozedur auf SQL Server 2019/2022/2025, Windows/Linux, lokal/zentral gemäß Modulvertrag. Direktes Resultset benötigt keine ResultTable-Operation und funktioniert im vorgesehenen uncommittable Callerpfad ohne Temp-DDL/INSERT. Für ResultTable-Ausgabe vorhandene lokale #Temp und USP_PrepareResultTable; zuerst Caller-Rollback bei XACT_STATE()=-1.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ErrorNumber` | `int` | `NULL` | Fachlich erforderlich: positive int-Fehlernummer 1..2147483647, üblicherweise ERROR_NUMBER() im aufrufenden CATCH. Technischer Default NULL dient nur Help; NULL/<=0 wird 51400. |
| `@ErrorSeverity` | `int` | `NULL` | Fachlich erforderlich: int 0..25 einschließlich, üblicherweise ERROR_SEVERITY() aus demselben CATCH. NULL/außerhalb ergibt 51401; technischer Default NULL nur für Help. |
| `@ErrorState` | `int` | `NULL` | Fachlich erforderlich: int 0..255 einschließlich aus ERROR_STATE() im CATCH. NULL/außerhalb ergibt 51402; technischer Default NULL nur für Help. |
| `@ErrorProcedure` | `nvarchar(776)` | `NULL` | Optionaler reiner Unicode-Text nvarchar(776), normalerweise ERROR_PROCEDURE() im CATCH, kein auszuführender Objektname. NULL bleibt NULL, leerer Text wird nicht besonders validiert. |
| `@ErrorLine` | `int` | `NULL` | Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL (Default) ist erlaubt, 0/negativ ergibt 51403. |
| `@ErrorMessage` | `nvarchar(4000)` | `NULL` | Fachlich erforderlicher Unicode-Fehlertext nvarchar(4000), normalerweise ERROR_MESSAGE() im CATCH. NULL, leer und nach SQL-Gleichheit leere reine Spacefolgen ergeben 51404; keine automatische Redigierung geheimer Inhalte. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Optionaler SQL-uniqueidentifier, Default NULL. NULL liest SESSION_CONTEXT(N'toolbelt.execution.id') mit TRY_CONVERT(uniqueidentifier,...); fehlende oder nicht parsebare Werte können NULL ergeben, ausdrücklich nicht unterstützte Konvertierungen behalten Enginefehler. Explizite ID wird unverändert übernommen und muss keinem gespeicherten Kontext entsprechen. Kein automatischer Kontextschreibzugriff. |
| `@AdditionalContext` | `nvarchar(4000)` | `NULL` | Optionaler Unicode-Freitext nvarchar(4000), kein vorgeschriebenes JSON-Schema und keine Ausführung. NULL/leer wird unverändert ausgegeben; nur bereits bereinigte, für den Empfänger zulässige Zusatzinformation übergeben. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) gibt eine direkte Fehlerzeile aus, auch bei XACT_STATE()=-1. Sonst Name einer bereits vom Caller angelegten lokalen #Temp-Tabelle als sysname, z.B. N'#Envelope', keine globale oder mehrteilige Tabelle; ResultTable-Helper nötig. Bei uncommittable Caller zuerst Rollback, sonst 51406. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 bereitet Replace vor (Default), 1 hängt bei kompatibler ResultTable an; NULL wird vom kanonischen Helper wie 0 behandelt. Nur bei nicht-NULL ResultTable relevant. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) und NULL ohne Diagnose; 1..255 erzeugen eine abstrakte Informationsmeldung ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe plus genau ein vierkolumniges Skill-Resultset und kehrt vor Fachprüfungen und Fachausgabe zurück. 0 oder NULL führt den Normalpfad aus. Alle übrigen Parameter werden bei Hilfe fachlich ignoriert; ihre SQL-Typbindung gilt weiterhin. |

## Ergebnisse

Genau eine fachliche Fehlerzeile mit CapturedAtUtc datetime2(7) NOT NULL, ExecutionId uniqueidentifier NULL, ErrorClass varchar(16) NOT NULL, ErrorNumber/ErrorSeverity/ErrorState int NOT NULL, ErrorProcedure nvarchar(776) NULL, ErrorLine int NULL, ErrorMessage nvarchar(4000) NOT NULL, XactState smallint NOT NULL, TransactionCount int NOT NULL, DatabaseName sysname NOT NULL, SessionId int NOT NULL, AdditionalContext nvarchar(4000) NULL. ErrorClass ist TOOLBELT bei Nummer 51000..51999, ENGINE bei Nummer <50000, sonst USER; dies ist eine Bereichsklassifikation, keine Prüfung gegen sys.messages. CapturedAtUtc und Session-/DB-/Transaktionskontext stammen vom Aufrufzeitpunkt, nicht zwingend vom ursprünglichen Fehlerzeitpunkt. ResultTable=NULL liefert die Zeile direkt, sonst wird sie in das vorbereitete Ziel eingefügt. RETURN 0 bei Erfolg, keine OUTPUT-Parameter. Bei Hilfe=1 stattdessen bisherige Standardhilfe und zusätzlich genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0. Keine fachliche Message-/Fehlerausgabe oder ResultTable-Verarbeitung in diesem Zweig.

## Aufrufbeispiele

```sql
-- Synthetische explizite Fehlerdaten, keine echte Fehlersitzung nötig:
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=50001,@ErrorSeverity=16,@ErrorState=1,
 @ErrorMessage=N'Example failure',@AdditionalContext=N'Synthetic example';
EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Prozedur; für Tabellenrouting zusätzlich vorhandener zulässiger Helper-/Temp-Tabellenkontext. Keine VIEW-SERVER-STATE-, Quelltabellen- oder neue Serverrechte aus dem direkten Formatieren ableiten. Keine automatische Rechtevergabe. Fehlertext/Zusatzkontext werden nicht redigiert und können vertrauliche Informationen enthalten; keine Secrets übergeben oder tatsächliche Runtimezeilen öffentlich speichern.

## Ressourcenbedarf

Direkt feste eine SELECT-Zeile. Tabellenpfad erstellt zwei lokale Temp-Tabellen mit fester Shape und einer materialisierten Zeile, danach Helper und dynamisches INSERT. Texte sind durch SQL-Argumenttypen begrenzt und können schon bei Bindung gekürzt werden; längere Originalfehler vorab berücksichtigen. Keine automatische Historie oder unbegrenzte Retention.

## Nebenwirkungen

Direkt keine Datenbank-DML, kein Schreiben des Execution-Contexts und keine neue Transaktion. Liest SESSION_CONTEXT nur bei fehlender ExecutionId und erfasst DB_NAME/@@SPID/XACT_STATE/@@TRANCOUNT. Tabellenpfad kann die caller-lokale ResultTable vorbereiten, leeren oder befüllen; der Wrapper besitzt dafür keine eigene umfassende Rollback-Klammer. Debug>0 sendet eine abstrakte Severity-10-Nachricht WITH NOWAIT, ohne Fehlertext oder Zusatzkontext darin zu wiederholen. Hilfe erfolgt vor allen fachlichen Arbeiten.

## Fehlerbehandlung

51400: ErrorNumber fehlt/nicht positiv; 51401: Severity fehlt/außerhalb 0..25; 51402: State fehlt/außerhalb 0..255; 51403: nicht-NULL ErrorLine nicht positiv; 51404: ErrorMessage NULL/leer beziehungsweise unter SQL-Gleichheit leer. 51405: für ResultTable fehlt Helper; 51406: ResultTable bei uncommittable Caller. Keine allgemeine CATCH-/Fehlerumklassifizierung; Helper-, Engine- und Typbindungsfehler bleiben sichtbar. Direkte Ausgabe ist der vorgesehene Fehlerdiagnosepfad vor Caller-Rollback; sie repariert dessen Transaktion nicht.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag. Neue native Skill-/Callerzustandsabnahme bleibt separat; unveränderte Fachnachweise nur bei passender Bindung wiederverwenden. Keine automatische Ermittlung der sechs ursprünglichen ERROR_*-Werte, keine garantierte dauerhafte Aufzeichnung, keine Rechteskalation, keine Aussage über einen früheren Transaktionszustand und keine Zusage atomarer ResultTable-Veröffentlichung durch diesen Wrapper.
