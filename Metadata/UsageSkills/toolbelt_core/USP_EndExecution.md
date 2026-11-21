---
name: "toolbelt-core-usp-endexecution"
description: "Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-context"
schema_name: "toolbelt_core"
object_name: "USP_EndExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExpectedExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten."}]
source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_EndExecution.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_EndExecution

## Zweck und Einsatzfälle

Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId.

## Voraussetzungen

Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |

## Ergebnisse

Kein fachlicher Resultset oder OUTPUT-Parameter, RETURN 0 bei Erfolg. Bei Tiefe>1 nur um 1 reduzieren; bei Tiefe=1 alle sechs Toolbelt-Keys löschen. Das Lesen des Kontexts liefert danach keine Zeile. Andere Sessionkeys bleiben unberührt. End prüft nur positive Tiefe, keine eigene 32767-Obergrenze für extern veränderte Werte. Hilfe=1 liefert stattdessen bisherige Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0 vor fachlichen Kontextzugriffen.

## Aufrufbeispiele

```sql
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
-- Nur den eigenen zuvor begonnenen Scope beenden:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Help benötigt das Pflichtargument, aber keinen aktiven Context:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL,@Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Prozedur/Funktion im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.

## Ressourcenbedarf

Feste Anzahl Kontextzugriffe, eine Dekrementierung oder sechs Löschaufrufe. Keine Rekursion und kein eigener gespeicherter Scope-Stack, keine Datei-/Tabellen-/Netzwerkressource.

## Nebenwirkungen

Ändert depth oder löscht die sechs Keys sequentiell. Keine eigene Transaktion, kein Stack-Restore alter Labels und keine Kompensation bereits gelöschter Keys bei einem späteren Enginefehler. Debug>0 erzeugt eine abstrakte Severity-10-Nachricht WITH NOWAIT. Schlüssel anderer Namespaces werden nicht gelöscht.

## Fehlerbehandlung

51430: keine gültige aktive ID; 51431: ExpectedExecutionId NULL oder abweichend; 51432: Tiefe fehlt oder <1. Der Pflichtparameter ohne SQL-Default bleibt auch beim Hilfeaufruf anzugeben, dann darf NULL übergeben werden. Read_only-Key-, Konvertierungs- und Enginefehler werden nicht unterdrückt; kein automatischer Cleanup fremder oder inkonsistenter Sessionwerte.

## Aussagegrenzen

Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
