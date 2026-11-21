---
name: "toolbelt-filesystem-internal-route-result"
description: "Interner Router für eine bereits gefüllte caller-lokale Dateisystem-Ergebnistabelle."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "USP_InternalRouteResult"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler einzelner caller-lokaler Temp-Tabellenname als sysname. NULL liefert #tbx_fs_result direkt als Resultset. Nicht-NULL wird durch USP_PrepareResultTable geprüft und vorbereitet; keine permanente/globale Tabelle oder vierteiliger Name. Keine eigene Berechtigungs-/Identitätsausweitung."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit, Default 0; bei Nicht-NULL-ResultTable an USP_PrepareResultTable durchgereicht. 0 leert/ersetzt gemäß dessen Vertrag, 1 erhält Daten und lehnt nötigen Schemaumbau bei nicht leerem Ziel ab. NULL wird dort wie 0 behandelt. Bei direkter Resultsetausgabe ohne Bedeutung."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_ReadBinaryFileChunk", "toolbelt_filesystem.USP_ListDirectory"]
---

# USP_InternalRouteResult

## Zweck und Einsatzfälle

Interner Router für eine bereits gefüllte caller-lokale Dateisystem-Ergebnistabelle. Internes Implementierungsdetail; Anwendungen verwenden die öffentlichen Dateisystem-Prozeduren mit deren vollständigem Autorisierungsvertrag.

## Voraussetzungen

Dateisystem-Modul unterstützt Windows SQL Server 2019/2022/2025. Dieser Helfer ist reines T-SQL; sein eigener @Hilfe=1-Pfad benötigt weder eine Ergebnistabelle noch Rootkonfiguration, Windowsimpersonation oder einen CLR-/Dateiaufruf. Im Normalpfad muss #tbx_fs_result bereits mit dem erwarteten Caller-Schema vorhanden sein. Für Tabellenrouting zusätzlich ResultTable-Modul und passende lokale Zieltable.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ResultTable` | `sysname` | `NULL` | Optionaler einzelner caller-lokaler Temp-Tabellenname als sysname. NULL liefert #tbx_fs_result direkt als Resultset. Nicht-NULL wird durch USP_PrepareResultTable geprüft und vorbereitet; keine permanente/globale Tabelle oder vierteiliger Name. Keine eigene Berechtigungs-/Identitätsausweitung. |
| `@KeepData` | `bit` | `0` | bit, Default 0; bei Nicht-NULL-ResultTable an USP_PrepareResultTable durchgereicht. 0 leert/ersetzt gemäß dessen Vertrag, 1 erhält Daten und lehnt nötigen Schemaumbau bei nicht leerem Ziel ab. NULL wird dort wie 0 behandelt. Bei direkter Resultsetausgabe ohne Bedeutung. |
| `@Hilfe` | `bit` | `0` | Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich. |

## Ergebnisse

Bei @Hilfe=1 genau eine konstante Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), RETURN 0. Normalpfad ohne ResultTable: SELECT * aus #tbx_fs_result und RETURN 0, Schema stammt vom Caller. Mit ResultTable: keine eigene fachliche Resultsetausgabe, sondern vollständiges INSERT der vorhandenen Ergebnistokens in das vorbereitete Ziel. Keine OUTPUT-Parameter.

## Aufrufbeispiele

```sql
EXEC toolbelt_filesystem.USP_InternalRouteResult @Hilfe=1;
-- Nur der eigene Skill; keine Dateisystemoperation.
```

## Rechte

Vorhandene EXECUTE-Rechte im autorisierten Modulpfad, keine automatische Rechtevergabe. Normale Routingoperationen benötigen vorhandene Temp-Tabellen und die Rechte des ResultTable-Vertrags. Hilfe vergibt keine Rechte und ersetzt keine Windows-/Root-/ServiceAccount-Freigabe öffentlicher Dateioperationen.

## Ressourcenbedarf

Direkte Ausgabe bzw. INSERT proportional zur Zeilenzahl und Breite der caller-lokalen #tbx_fs_result. Shape wird mit SELECT TOP(0) in #tbx_fs_shape ermittelt. Keine eigene Row-/Bytequote; gültige Begrenzungen stammen vom öffentlichen Fachcaller. Skillhilfe ist konstant, Unicode und ohne Runtime-Katalogabfrage.

## Nebenwirkungen

Mit ResultTable kann USP_PrepareResultTable das lokale Zielschema verändern oder vorhandene Zeilen gemäß KeepData entfernen; danach INSERT. #tbx_fs_shape ist eine lokale Temp-Tabelle des Helfers. Kein eigener Commit/Rollback und kein eigener Datei-/Netzwerk-/CLR-Aufruf. Neuer Hilfezweig führt nichts davon aus und verändert keine OUTPUT-Werte.

## Fehlerbehandlung

Es gibt keine neuen fachlichen Fehlercodes. Fehlende Pflichtargumente, Objekt-/Ausführungsrechte, nicht vorhandene Caller-Temps und unerwartete Enginefehler bleiben Fehler. Beim Routing werden Fehler des ResultTable-Kerns unverändert weitergegeben; keine automatische Wiederholung oder Rechteausweitung.

## Aussagegrenzen

Interner Helfer, keine öffentliche Datei- oder Berechtigungs-API. Ergebnistabelle und Schema werden vom aufrufenden Fachpfad bereitgestellt; dieser Helfer prüft keine Herkunft der Daten und besitzt keine eigene atomare Dateisystemoperation. ResultTable-Name wird als Identifier gequotet, nicht als SQL-Ausdruck interpretiert. Native Akzeptanz des neuen Hilfezweigs ist separat offen; historische Fachbelege gelten nur für den unveränderten Normalpfad.
