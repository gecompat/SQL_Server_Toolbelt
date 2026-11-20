---
name: "toolbelt-toolbelt-core-usp-prepareresulttable"
description: "Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein."
skill_format_version: "1.0"
module_id: "toolbelt.core.result-table"
schema_name: "toolbelt_core"
object_name: "USP_PrepareResultTable"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ResultTableToAlter", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche, bereits existierende caller-lokale #Temp im selben sichtbaren Session-Scope; logischer Name 2..116 UTF-16-Einheiten, genau ein führendes # und kein reserviertes #tbx_-Präfix. Ein einzelner Identifier, kein DDL und keine Tabellenvariable/permanente/globale Tabelle. NULL ist nur technischer Help-Default. Darf nicht dieselbe Tabelle wie LikeTable sein."}, {"name": "@LikeTable", "sql_type": "nvarchar(776)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche vorhandene Referenztabelle als #LocalTemplate, Schema.Table oder Database.Schema.Table, optional regulär quotierte Namensbestandteile. Keine einteilige permanente Tabelle, Server-/vierteilige Namen, Views, Synonyme oder ##Temps. NULL/leer ungültig. Referenzspalten müssen dem unterstützten einfügbaren Typ-/Metadatenvertrag in RESULT_TABLE_MODULE_DESIGN.md entsprechen; der Helper übernimmt Spaltenshape und keine fachlichen Zeilen."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 0 ersetzt/leert vorhandene Zielinhalte und baut nötigenfalls das Schema um (Default); 1 erhält vorhandene Zeilen und lehnt einen nötigen Schemaumbau bei nicht leerem Ziel mit 51025 ab. Ein leeres Ziel darf auch bei 1 angepasst werden. NULL wirkt wie 0. Keine Append-Operation des Helpers selbst; fachliche Zeilen fügt der Caller danach ein."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine Debugmessages, 1 Preflight/Ablauf, 2 zusätzlich zusammengefasste Metadaten/Schemaentscheidung, 3..255 zusätzlich normalisierte Referenzmetadaten und geplantes DDL. Die Schwellwerte gelten kumulativ; 255 besitzt im aktuellen Code keine weitere eigene Stufe. Nur Messages, kein Zusatzresultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_PrepareResultTable

## Zweck und Einsatzfälle

Eine bereits vorhandene caller-lokale #Temp als ResultTable anhand einer sichtbaren Tabelle vorbereiten. Der Helper fügt selbst keine fachlichen Ergebniszeilen ein.

## Voraussetzungen

Ziel-#Temp und Referenztabelle müssen im unterstützten Session-/Namensscope existieren. Kein frei geliefertes DDL, keine globale oder permanente Zieltabelle. Der Help-Pfad benötigt keine Ziel-/Referenztabelle.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ResultTableToAlter` | `sysname` | `NULL` | Input | Fachlich erforderliche, bereits existierende caller-lokale #Temp im selben sichtbaren Session-Scope; logischer Name 2..116 UTF-16-Einheiten, genau ein führendes # und kein reserviertes #tbx_-Präfix. Ein einzelner Identifier, kein DDL und keine Tabellenvariable/permanente/globale Tabelle. NULL ist nur technischer Help-Default. Darf nicht dieselbe Tabelle wie LikeTable sein. |
| `@LikeTable` | `nvarchar(776)` | `NULL` | Input | Fachlich erforderliche vorhandene Referenztabelle als #LocalTemplate, Schema.Table oder Database.Schema.Table, optional regulär quotierte Namensbestandteile. Keine einteilige permanente Tabelle, Server-/vierteilige Namen, Views, Synonyme oder ##Temps. NULL/leer ungültig. Referenzspalten müssen dem unterstützten einfügbaren Typ-/Metadatenvertrag in RESULT_TABLE_MODULE_DESIGN.md entsprechen; der Helper übernimmt Spaltenshape und keine fachlichen Zeilen. |
| `@KeepData` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 ersetzt/leert vorhandene Zielinhalte und baut nötigenfalls das Schema um (Default); 1 erhält vorhandene Zeilen und lehnt einen nötigen Schemaumbau bei nicht leerem Ziel mit 51025 ab. Ein leeres Ziel darf auch bei 1 angepasst werden. NULL wirkt wie 0. Keine Append-Operation des Helpers selbst; fachliche Zeilen fügt der Caller danach ein. |
| `@Debug` | `tinyint` | `0` | Input | Ganzzahl tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine Debugmessages, 1 Preflight/Ablauf, 2 zusätzlich zusammengefasste Metadaten/Schemaentscheidung, 3..255 zusätzlich normalisierte Referenzmetadaten und geplantes DDL. Die Schwellwerte gelten kumulativ; 255 besitzt im aktuellen Code keine weitere eigene Stufe. Nur Messages, kein Zusatzresultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

`argument_required` beschreibt SQL-Syntax, `business_required` die Fachpflicht. Technisches DEFAULT NULL erlaubt den Hilfeaufruf und ersetzt keine fachliche Eingabe.

## Ergebnisse

Kein fachliches Resultset; Erfolg RETURN 0. Bei @Hilfe=1 bisherige Standardhilfe sowie nach Integration genau ein zusätzliches vier­spaltiges Skill-Resultset. Dies ist keine aktuelle native Abnahme des neuen Skillpfads.

## Aufrufbeispiele

```sql
CREATE TABLE #Shape (ItemId int NOT NULL);
CREATE TABLE #Result (Dummy int NULL);
EXEC toolbelt_core.USP_PrepareResultTable
 @ResultTableToAlter=N'#Result', @LikeTable=N'#Shape', @KeepData=0;
```

## Rechte

EXECUTE auf der Procedure; Metadatensichtbarkeit auf die reguläre Referenztabelle. DDL-/Leserechte gemäß tatsächlich ausgeführtem Temp-/Referenzzugriff. Keine Rechtevergabe oder EXECUTE AS durch den Helper.

## Ressourcenbedarf

Metadaten-Preflight sowie bei abweichendem Schema TempDB-DDL. Bei passendem Schema und KeepData=0 können vorhandene Zielzeilen per TRUNCATE entfernt werden. Keine pauschale Laufzeit-/Kapazitätsgarantie.

## Nebenwirkungen

Kann ausschließlich die eigene gewählte lokale Ziel-#Temp leeren und ihr Schema umbauen. KeepData=1 erhält Zeilen; bei nötigem Umbau eines nicht leeren Ziels wird abgebrochen. Referenzdaten werden nicht kopiert.

## Fehlerbehandlung

Vertragsfehler 51020–51029 für fehlendes/ungültiges Ziel, nicht sichtbare oder ungeeignete Referenz, nicht unterstützte Typen, KeepData-Konflikt, Abhängigkeiten, Collation, Transaktionszustand und interne DDL-Grenzen. Enginefehler werden nach transaktionsgerechtem Cleanup weitergegeben.

## Aussagegrenzen

Keine Garantie für gleichzeitige fremde DDL-Manipulation. Keine Views/Synonyme/Linked Server als Referenz, kein pauschaler Tabellenklon. Der Skill beschreibt den gelieferten Quellvertrag und attestiert keine namensgleiche installierte Definition.
