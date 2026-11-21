---
name: "toolbelt-core-usp-beginexecution"
description: "Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-context"
schema_name: "toolbelt_core"
object_name: "USP_BeginExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt."}, {"name": "@AllowNested", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten."}]
source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_BeginExecution.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_BeginExecution

## Zweck und Einsatzfälle

Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung.

## Voraussetzungen

Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen. |
| `@Actor` | `nvarchar(256)` | `NULL` | Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@AllowNested` | `bit` | `1` | Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |

## Ergebnisse

Kein fachlicher Resultset. RETURN 0 bei Erfolg; @ExecutionId ist INPUT/OUTPUT und enthält die gewählte aktive ID. Ohne gültige aktuelle ID wird die übergebene ID oder NEWID verwendet, CorrelationId standardmäßig gleichgesetzt, Zeit neu erfasst und Tiefe 1 gesetzt. Im Nested-Pfad bleibt die ID gleich und nur die Tiefe wächst; vorhandene Correlation-/Actor-/Tenant-Werte und Startzeit werden nicht neu geschrieben. Bei Hilfe keine Änderung des bereits übergebenen OUTPUT-Werts. Hilfe=1 liefert stattdessen bisherige Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0 vor fachlichen Kontextzugriffen.

## Aufrufbeispiele

```sql
-- Eigene Sitzung ohne vorher aktiven Context verwenden.
DECLARE @Id uniqueidentifier;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Actor=N'Contoso example';
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Hilfe liest/schreibt keinen Context und erhält einen vorhandenen OUTPUT-Wert:
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Prozedur/Funktion im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.

## Ressourcenbedarf

Feste Anzahl Keylese-/Schreibaufrufe, begrenzte Labels nvarchar(256) und ISO-Zeittext nvarchar(33). Tiefe nach regulärem Begin maximal 32767; kein persistenter Stack mit gespeicherten Vorgängerwerten. Die Engine verwaltet Sessionkontextspeicher, kein eigener Heap-/Laufzeitvertrag.

## Nebenwirkungen

Root schreibt die sechs Sessionkeys sequentiell, Nested nur depth. Keine eigene Transaktion, keine Kompensations-/Rollbackklammer und kein automatisches End bei Fehlern. Ein späterer Schreibfehler kann nach bereits erfolgreichen Keyänderungen auftreten; kein atomarer Mehrkey-Vertrag. Debug>0 erzeugt erst nach erfolgreichem Fachpfad eine abstrakte Severity-10-Nachricht WITH NOWAIT ohne Payload.

## Fehlerbehandlung

51420: aktiver Kontext bei AllowNested=0; 51421: Nested-Tiefe fehlt, <1 oder >=32767; 51422: explizite ExecutionId weicht ab; 51423: explizite CorrelationId nach SQL-<> abweichend; 51424/51425: Actor/Tenant nach SQL-Vergleich abweichend. Ein extern beschädigter Kontext mit NULL-CorrelationId besitzt SQL-NULL-Vergleichssemantik; keine Reparatur-/Authentizitätsprüfung daraus ableiten. Typbindungs-, Konvertierungs-, read_only-Key- und andere Enginefehler bleiben sichtbar. Ohne aktive gültige ID wird ein neuer Root gesetzt, nicht ein beliebiger Restzustand vollständig validiert.

## Aussagegrenzen

Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
