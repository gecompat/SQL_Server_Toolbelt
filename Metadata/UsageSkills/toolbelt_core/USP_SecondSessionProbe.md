---
name: "toolbelt-toolbelt-core-usp-secondsessionprobe"
description: "Interne Probe für den tatsächlich aufrufenden Session-/Datenbankkontext; keine eigenständige Remote-Ausführung."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_SecondSessionProbe"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@RemoteSessionId", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT: im Normalpfad @@SPID der tatsächlich aufrufenden Session. SQL-Default NULL; ein vorhandener Eingabewert wird im Normalpfad überschrieben. Der vorhandene Help-Pfad verändert den OUTPUT-Wert nicht."}, {"name": "@RemoteDatabaseName", "sql_type": "sysname", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT: im Normalpfad DB_NAME() der tatsächlich aufrufenden Session. SQL-Default NULL; vorhandener Wert wird im Normalpfad überschrieben. Im Help-Pfad unverändert."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit, Default 0; gebundenes 1 liefert Hilfe vor Sessionabfragen und kehrt zurück. NULL wird wie 0 behandelt. 0 führt die interne Probe aus; keine neue Session wird hier erstellt."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_SecondSessionProbe.sql"]
review_status: "verified"
source_module_version: "1.1.0"
public_entrypoints: ["toolbelt_core.USP_ConfigureSecondSessionLoopback", "toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
---

# USP_SecondSessionProbe

## Zweck und Einsatzfälle

Interner Bestandteil des administrierten Second-Session-Vertrags. Erfasst Session-ID und Datenbankname der Session, in der die Procedure tatsächlich ausgeführt wird.

## Voraussetzungen

Nur im bereits autorisierten Kontext des Second-Session-Moduls verwenden. Der Helper erstellt weder einen Linked Server noch eine andere Session. Die öffentlichen Einstiege sind USP_ConfigureSecondSessionLoopback und USP_ExecuteWorkTypeInNewSession.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RemoteSessionId` | `int` | `NULL` | OUTPUT | OUTPUT: im Normalpfad @@SPID der tatsächlich aufrufenden Session. SQL-Default NULL; ein vorhandener Eingabewert wird im Normalpfad überschrieben. Der vorhandene Help-Pfad verändert den OUTPUT-Wert nicht. |
| `@RemoteDatabaseName` | `sysname` | `NULL` | OUTPUT | OUTPUT: im Normalpfad DB_NAME() der tatsächlich aufrufenden Session. SQL-Default NULL; vorhandener Wert wird im Normalpfad überschrieben. Im Help-Pfad unverändert. |
| `@Hilfe` | `bit` | `0` | Input | bit, Default 0; gebundenes 1 liefert Hilfe vor Sessionabfragen und kehrt zurück. NULL wird wie 0 behandelt. 0 führt die interne Probe aus; keine neue Session wird hier erstellt. |

## Ergebnisse

Kein fachliches Resultset; RemoteSessionId und RemoteDatabaseName werden im Normalpfad per OUTPUT gesetzt, RETURN 0. Hilfe kehrt vor diesen Zuweisungen zurück; bestehende OUTPUT-Werte bleiben dabei erhalten. Nach dem bisherigen Help-Resultset folgt genau ein zusätzliches Skill-Resultset mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); eine Zeile mit dem vollständigen kanonischen Skill.

## Aufrufbeispiele

```sql
-- Nur Metadaten; keine Remote-Session wird erzeugt.
EXEC toolbelt_core.USP_SecondSessionProbe @Hilfe=1;
```

## Rechte

Kein allgemeiner öffentlicher Fachaufruf. Vorhandene EXECUTE-/Providerrechte im bereits administrierten Second-Session-Vertrag nutzen; keine Rechtevergabe oder Änderung von Login-Mappings durch diesen Helper.

## Ressourcenbedarf

Konstante Session-/Datenbankkontextabfrage im Normalpfad. Kein Tabellen- oder Dateizugriff, keine Kapazitäts-/Remoteverfügbarkeitsgarantie.

## Nebenwirkungen

Normalpfad setzt ausschließlich die zwei OUTPUT-Werte. Kein DML, keine Sessionerzeugung und keine Serverkonfigurationsänderung.

## Fehlerbehandlung

Der Helper definiert keine eigenen Vertragsfehler; fehlende Objekt-/Ausführungsrechte oder unerwartete Engineprobleme bleiben Enginefehler.

## Aussagegrenzen

Ein direkter lokaler Aufruf belegt keinen funktionierenden Remote-/Linked-Server-Pfad. OUTPUT beschreibt nur den wirklichen Ausführungskontext, keine Transportidentität, TLS- oder Rechteabnahme.
