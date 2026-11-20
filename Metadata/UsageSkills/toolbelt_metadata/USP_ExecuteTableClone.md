---
name: "toolbelt-toolbelt-toolbelt-metadata-usp-executetableclone"
description: "Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.table-clone"
schema_name: "toolbelt_metadata"
object_name: "USP_ExecuteTableClone"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SourceSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@SourceTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@TargetSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@TargetTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@IncludeIdentity", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen."}, {"name": "@IncludeExtendedProperties", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern."}, {"name": "@TableMap", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen."}, {"name": "@ExternalReferenceRule", "sql_type": "varchar(16)", "sql_default": "'REJECT'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig."}, {"name": "@ExpectedPlanHash", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakt 32 Bytes varbinary des SHA256-Planhashes aus dem dokumentierten Hashlayout1 für Modul4.1.0. Aus unveränderten triggerfreien Vorschauzeilen, exakten Optionen und Installationsdatenbankidentität gemäß TABLE_CLONE_EXECUTE_CONTRACT.md/Examples/CalculatePlanHash.py berechnen. Kein Hextext ohne Konvertierung, kein Hash allein des Scripttexts. NULL/falsche Länge ungültig, Abweichung vom frisch erzeugten Plan bricht ab."}, {"name": "@ForeignKeyMode", "sql_type": "varchar(16)", "sql_default": "'CREATE'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold: CREATE (Default) führt alle fachlichen Planzeilen einschließlich FKs/Zustände aus; DEFER überspringt ausschließlich FOREIGN_KEY und FOREIGN_KEY_STATE für spätere Datenkopie. Beide Zeilenarten bleiben im vollständigen Planhash. NULL/andere Werte ungültig; bestehende Constraints werden nicht deaktiviert."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Der Executor plant intern ausdrücklich mit Debug=0 und erzeugt keine eigenen zusätzlichen Diagnosemessages; bei ResultTable wird der übergebene Wert an den Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.metadata.table-clone/Source/USP_ExecuteTableClone.sql"]
review_status: "draft"
source_module_version: "4.1.1"
---

# USP_ExecuteTableClone

## Zweck und Einsatzfälle

Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Erzeugt neue Tabellen. @CalculatedPlanHash ist ein notwendiger Platzhalter für die externe kanonische Hashberechnung; der Beispielaufruf ist bis dahin nicht ausführbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@IncludeIdentity` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen. |
| `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig. |
| `@ExpectedPlanHash` | `varbinary(max)` | `NULL` | Input | Fachlich erforderliche exakt 32 Bytes varbinary des SHA256-Planhashes aus dem dokumentierten Hashlayout1 für Modul4.1.0. Aus unveränderten triggerfreien Vorschauzeilen, exakten Optionen und Installationsdatenbankidentität gemäß TABLE_CLONE_EXECUTE_CONTRACT.md/Examples/CalculatePlanHash.py berechnen. Kein Hextext ohne Konvertierung, kein Hash allein des Scripttexts. NULL/falsche Länge ungültig, Abweichung vom frisch erzeugten Plan bricht ab. |
| `@ForeignKeyMode` | `varchar(16)` | `'CREATE'` | Input | Taxativ, bytegenau ohne Trim/Casefold: CREATE (Default) führt alle fachlichen Planzeilen einschließlich FKs/Zustände aus; DEFER überspringt ausschließlich FOREIGN_KEY und FOREIGN_KEY_STATE für spätere Datenkopie. Beide Zeilenarten bleiben im vollständigen Planhash. NULL/andere Werte ungültig; bestehende Constraints werden nicht deaktiviert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Der Executor plant intern ausdrücklich mit Debug=0 und erzeugt keine eigenen zusätzlichen Diagnosemessages; bei ResultTable wird der übergebene Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Vollständiger Hash, kein Rechte- oder Driftbeleg.

Tatsächlich neu angelegte Tabellen.

Fachliche DDL-Zeilen ohne SESSION_OPTION und bei DEFER ohne FK-Zeilen.

## Aufrufbeispiele

```sql
-- Voraussetzung: eigene Quelltabelle und neues Ziel in vorhandenen Schemas.
-- Den Vorschauplan mit identischen Optionen erzeugen und seinen Hash
-- nach dem kanonischen Client-Framing berechnen; keine Konstante erfinden.
DECLARE @CalculatedPlanHash varbinary(max)=NULL; -- berechneten 32-Byte-Hash einsetzen
EXEC toolbelt_metadata.USP_ExecuteTableClone
 @SourceSchema=N'dbo', @SourceTable=N'SyntheticSource',
 @TargetSchema=N'dbo', @TargetTable=N'SyntheticClone',
 @ExpectedPlanHash=@CalculatedPlanHash, @ForeignKeyMode='CREATE';
```

## Rechte

Vorhandene V3-/Core-/DDL-Rechte, Server VIEW ANY DEFINITION, lesbare Trigger-/Eventkataloge; keine Rechteerteilung.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

53930 Argumente/Temps,53932 Sicht/Rechte,53933 DDL-Seiteneffekte,53934 Hash,53935 Plan/Ausführungspfade,53936 AppLock. Caller-TX: SQL50000/state1, Token TBX_TABLE_CLONE_EXECUTE_CALLER_TRANSACTION. Engine-/Plannerfehler unverändert.

## Aussagegrenzen

Nur neue Ziele, keine Datenkopie oder externe Atomik. Caller hält Quellen/Ziele/Serverbedingungen stabil. Map64 und vollständiger Plan2MiB; keine CPU/RAM/Wallclockgarantie.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.metadata.table-clone/Documentation/USP_ExecuteTableClone.md`

Keine Installations-, Definitions- oder Rechteattestation.
