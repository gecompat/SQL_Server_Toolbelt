---
name: "toolbelt-toolbelt-toolbelt-metadata-usp-copytableclonedata"
description: "Kopiert einen begrenzten SameDB-Tabellenverbund atomar in bereits vorhandene leere formgleiche Ziele; keine Strukturkopie oder Rechtevergabe."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.table-clone"
schema_name: "toolbelt_metadata"
object_name: "USP_CopyTableCloneData"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@TableMap", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Fachlich erforderlich, NULL ungültig. Hier müssen die fünf Spalten zusätzlich exakt in der genannten Reihenfolge und ohne IDENTITY stehen. Source und Target müssen beide existieren, formgleich und als Mengen von ObjectIDs disjunkt sein; jedes Ziel muss leer sein. Keine Filter/Upserts/CrossDB oder impliziten Typkonvertierungen."}, {"name": "@IdentityMode", "sql_type": "varchar(16)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: KEEP kopiert Identitywerte unter vorhandenen erforderlichen Rechten; REGENERATE lässt Identityspalten beim Transport weg und erzeugt neue Zielwerte. REGENERATE ist bei identityabhängigen Beziehungen ausgeschlossen. NULL/leer/andere Werte ungültig. Keine neue ID-Zuordnung/RESEED; Identity-Zählerfortschritt kann trotz Rollback bleiben."}, {"name": "@ConsistencyMode", "sql_type": "varchar(16)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: SNAPSHOT verwendet die bereits aktivierte Datenbankoption; SERIALIZABLE hält Quellbereichssperren. NULL/leer/andere Werte ungültig. Keine automatische Optionsänderung; aktive Callertransaktion wird abgelehnt."}, {"name": "@RowLimit", "sql_type": "bigint", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 global kopierte Zeilen über alle gemappten Tabellen, Default 100000. NULL/außerhalb ungültig; Überschreitung verhindert die gesamte Kopie, kein TOP-Teilimport."}, {"name": "@PayloadByteLimit", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes globaler tatsächlich transportierter SQL-Nutzdaten, Default 16777216. Summe bigint-DATALENGTH, NULL zählt 0; computed/rowversion und bei REGENERATE Identity zählen nicht. Kein Gesamt-Heap-/Dateigrößenbudget; NULL/außerhalb ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht TableMap. Die späte ResultTable-Ausgabe ist Teil derselben eigenen Transaktion wie Kopie/FK-DDL."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Aktuell keine eigenen zusätzlichen Copy-Diagnosemessages; bei ResultTable wird der Wert an den Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.metadata.table-clone/Source/USP_CopyTableCloneData.sql"]
review_status: "draft"
source_module_version: "4.1.1"
---

# USP_CopyTableCloneData

## Zweck und Einsatzfälle

Kopiert einen begrenzten SameDB-Tabellenverbund atomar in bereits vorhandene leere formgleiche Ziele; keine Strukturkopie oder Rechtevergabe.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandene reguläre SameDB-Quellen und leere formgleiche Ziele, keine aktive Callertransaktion. SERIALIZABLE hält Quellsperren; SNAPSHOT benötigt eine bereits aktivierte Datenbankoption.
- Vorhandene DB-Metadatensicht und Source-/Target-Rechte; fehlende FKs verlangen zusätzlich Server-DDL-Sicht und DDL-Rechte. KEEP benötigt vorhandenes Identity-ALTER. Aktive Targettrigger, RLS und nicht tabellenlokale Ausführung blockieren.
- Verändert Zielinhalte und kann fehlende gemappte FKs erzeugen. Identity-Zähler können trotz Rollback fortgeschritten bleiben; kein RESEED oder Identitätszuordnungsversprechen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@TableMap` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Fachlich erforderlich, NULL ungültig. Hier müssen die fünf Spalten zusätzlich exakt in der genannten Reihenfolge und ohne IDENTITY stehen. Source und Target müssen beide existieren, formgleich und als Mengen von ObjectIDs disjunkt sein; jedes Ziel muss leer sein. Keine Filter/Upserts/CrossDB oder impliziten Typkonvertierungen. |
| `@IdentityMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: KEEP kopiert Identitywerte unter vorhandenen erforderlichen Rechten; REGENERATE lässt Identityspalten beim Transport weg und erzeugt neue Zielwerte. REGENERATE ist bei identityabhängigen Beziehungen ausgeschlossen. NULL/leer/andere Werte ungültig. Keine neue ID-Zuordnung/RESEED; Identity-Zählerfortschritt kann trotz Rollback bleiben. |
| `@ConsistencyMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: SNAPSHOT verwendet die bereits aktivierte Datenbankoption; SERIALIZABLE hält Quellbereichssperren. NULL/leer/andere Werte ungültig. Keine automatische Optionsänderung; aktive Callertransaktion wird abgelehnt. |
| `@RowLimit` | `bigint` | `100000` | Input | Ganzzahl 1..100000 global kopierte Zeilen über alle gemappten Tabellen, Default 100000. NULL/außerhalb ungültig; Überschreitung verhindert die gesamte Kopie, kein TOP-Teilimport. |
| `@PayloadByteLimit` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes globaler tatsächlich transportierter SQL-Nutzdaten, Default 16777216. Summe bigint-DATALENGTH, NULL zählt 0; computed/rowversion und bei REGENERATE Identity zählen nicht. Kein Gesamt-Heap-/Dateigrößenbudget; NULL/außerhalb ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht TableMap. Die späte ResultTable-Ausgabe ist Teil derselben eigenen Transaktion wie Kopie/FK-DDL. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Aktuell keine eigenen zusätzlichen Copy-Diagnosemessages; bei ResultTable wird der Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Anzahl validierter Maps.

Tatsächlich eingefügte Gesamtzeilen.

Globale DATALENGTH-Summe tatsächlich transportierter Spalten; NULL0.

Tatsächlich neu angelegte fehlende FKs.

Exakt COPIED.

## Aufrufbeispiele

```sql
CREATE TABLE #CopyMap
(
 MapOrdinal int NOT NULL,
 SourceSchema nvarchar(max) NOT NULL, SourceTable nvarchar(max) NOT NULL,
 TargetSchema nvarchar(max) NOT NULL, TargetTable nvarchar(max) NOT NULL
);
-- Eigene synthetische Tabellen bestehen bereits; SyntheticClone ist leer und formgleich.
INSERT #CopyMap VALUES (1,N'dbo',N'SyntheticSource',N'dbo',N'SyntheticClone');
EXEC toolbelt_metadata.USP_CopyTableCloneData
 @TableMap=N'#CopyMap', @IdentityMode='KEEP', @ConsistencyMode='SERIALIZABLE';
DROP TABLE #CopyMap;
```

## Rechte

Vorhandene datenbankweite VIEW DEFINITION, Katalog-SELECT und Source-SELECT/Target-SELECT/INSERT; fehlende FK-DDL zusätzlich volle Server-DDL-Sicht und ALTER/REFERENCES. Keine Rechtevergabe.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

53940 Argumente/Map/Temp,53941 Rechte/Sicht/Form,53942 Seiteneffekte,53943 Row-/Nutzdatenbudget,53944 Shape/FKs/Admission/Drift,53945 reserviert,53946 Lifecycle-Lock; Caller-TX50000/1 mit TBX_TABLE_CLONE_COPY_CALLER_TRANSACTION; Enginefehler unverändert.

## Aussagegrenzen

Identity-Zähler können Rollback überleben; kein RESEED/Zuordnungsversprechen. Nur leere SameDB-Targets, keine aktiven Targettrigger/RLS/Sonderformen; XML/LOB innerhalb vorhandener Shapegrenze. Keine Config-/Owner-/Rechteänderung.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.metadata.table-clone/Documentation/USP_CopyTableCloneData.md`

Keine Installations-, Definitions- oder Rechteattestation.
