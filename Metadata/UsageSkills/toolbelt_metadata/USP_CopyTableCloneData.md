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
parameters: [{"name": "@TableMap", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Fachlich erforderlich, NULL ungültig. Hier müssen die fünf Spalten zusätzlich exakt in der genannten Reihenfolge und ohne IDENTITY stehen. Source und Target müssen beide existieren, formgleich und als Mengen von ObjectIDs disjunkt sein; jedes Ziel muss leer sein. Keine Filter/Upserts/CrossDB oder impliziten Typkonvertierungen."}, {"name": "@IdentityMode", "sql_type": "varchar(16)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: KEEP kopiert Identitywerte unter vorhandenen erforderlichen Rechten; REGENERATE lässt Identityspalten beim Transport weg und erzeugt neue Zielwerte. REGENERATE ist bei identityabhängigen Beziehungen ausgeschlossen. NULL/leer/andere Werte ungültig. Keine neue ID-Zuordnung/RESEED; Identity-Zählerfortschritt kann trotz Rollback bleiben."}, {"name": "@ConsistencyMode", "sql_type": "varchar(16)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: SNAPSHOT verwendet die bereits aktivierte Datenbankoption; SERIALIZABLE hält Quellbereichssperren. NULL/leer/andere Werte ungültig. Keine automatische Optionsänderung; aktive Callertransaktion wird abgelehnt. SERIALIZABLE verwendet TABLOCK/HOLDLOCK an Quellen; Ziele werden unabhängig vom Quellmodus mit TABLOCKX/UPDLOCK/HOLDLOCK gesperrt. Isolations-/SET-Änderungen bleiben im Prozedurscope."}, {"name": "@RowLimit", "sql_type": "bigint", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 global kopierte Zeilen über alle gemappten Tabellen, Default 100000. NULL/außerhalb ungültig; Überschreitung verhindert die gesamte Kopie, kein TOP-Teilimport."}, {"name": "@PayloadByteLimit", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes globaler tatsächlich transportierter SQL-Nutzdaten, Default 16777216. Summe bigint-DATALENGTH, NULL zählt 0; computed/rowversion und bei REGENERATE Identity zählen nicht. Kein Gesamt-Heap-/Dateigrößenbudget; NULL/außerhalb ungültig. Gezählt wird SUM(DATALENGTH) nur tatsächlich transportierter Sourcefelder; NULL zählt0, Computed/rowversion und bei REGENERATE Identity bleiben außerhalb. Kein Heap-, Log-, Index-, Versionstore- oder physischer Tabellenbytes-Nachweis."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht TableMap. Die späte ResultTable-Ausgabe ist Teil derselben eigenen Transaktion wie Kopie/FK-DDL."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Aktuell keine eigenen zusätzlichen Copy-Diagnosemessages; bei ResultTable wird der Wert an den Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.metadata.table-clone/Source/USP_CopyTableCloneData.sql"]
review_status: "verified"
source_module_version: "4.1.1"
---

# USP_CopyTableCloneData

## Zweck und Einsatzfälle

Kopiert einen begrenzten SameDB-Tabellenverbund atomar in bereits vorhandene leere formgleiche Ziele; keine Strukturkopie oder Rechtevergabe.

## Voraussetzungen

Modul4.1.1 in der tatsächlich ausgewählten Installationsdatenbank; ausschließlich SameDB-Quell-/Zielobjekte. Ein dreiteiliger zentraler Prozeduraufruf verlegt die Quellobjekte nicht in die Caller-Datenbank. Bestehender ResultTable-Helper>=1.0.0. Basisplanung/Executor/Copy sind TSQL auf Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Trigger-Opt-in ist gesondert Windows-only mit bereits vorhandenem exakt gebundenem Parser2.0.1 und vier Parser-TVFs; kein Nachinstallieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@TableMap` | `sysname` | `NULL` | Input | Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Fachlich erforderlich, NULL ungültig. Hier müssen die fünf Spalten zusätzlich exakt in der genannten Reihenfolge und ohne IDENTITY stehen. Source und Target müssen beide existieren, formgleich und als Mengen von ObjectIDs disjunkt sein; jedes Ziel muss leer sein. Keine Filter/Upserts/CrossDB oder impliziten Typkonvertierungen. |
| `@IdentityMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: KEEP kopiert Identitywerte unter vorhandenen erforderlichen Rechten; REGENERATE lässt Identityspalten beim Transport weg und erzeugt neue Zielwerte. REGENERATE ist bei identityabhängigen Beziehungen ausgeschlossen. NULL/leer/andere Werte ungültig. Keine neue ID-Zuordnung/RESEED; Identity-Zählerfortschritt kann trotz Rollback bleiben. |
| `@ConsistencyMode` | `varchar(16)` | `NULL` | Input | Taxativ, bytegenau ohne Trim/Casefold und fachlich erforderlich: SNAPSHOT verwendet die bereits aktivierte Datenbankoption; SERIALIZABLE hält Quellbereichssperren. NULL/leer/andere Werte ungültig. Keine automatische Optionsänderung; aktive Callertransaktion wird abgelehnt. SERIALIZABLE verwendet TABLOCK/HOLDLOCK an Quellen; Ziele werden unabhängig vom Quellmodus mit TABLOCKX/UPDLOCK/HOLDLOCK gesperrt. Isolations-/SET-Änderungen bleiben im Prozedurscope. |
| `@RowLimit` | `bigint` | `100000` | Input | Ganzzahl 1..100000 global kopierte Zeilen über alle gemappten Tabellen, Default 100000. NULL/außerhalb ungültig; Überschreitung verhindert die gesamte Kopie, kein TOP-Teilimport. |
| `@PayloadByteLimit` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes globaler tatsächlich transportierter SQL-Nutzdaten, Default 16777216. Summe bigint-DATALENGTH, NULL zählt 0; computed/rowversion und bei REGENERATE Identity zählen nicht. Kein Gesamt-Heap-/Dateigrößenbudget; NULL/außerhalb ungültig. Gezählt wird SUM(DATALENGTH) nur tatsächlich transportierter Sourcefelder; NULL zählt0, Computed/rowversion und bei REGENERATE Identity bleiben außerhalb. Kein Heap-, Log-, Index-, Versionstore- oder physischer Tabellenbytes-Nachweis. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht TableMap. Die späte ResultTable-Ausgabe ist Teil derselben eigenen Transaktion wie Kopie/FK-DDL. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Aktuell keine eigenen zusätzlichen Copy-Diagnosemessages; bei ResultTable wird der Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | NULL | Bedeutung |
|---|---|---|---|
| `MappedTables` | `int` | nein | AnzahlMaps |
| `CopiedRows` | `bigint` | nein | Summe eingefügterZeilen |
| `PayloadBytes` | `bigint` | nein | gezählte transportierte DATALENGTH-Bytes |
| `CreatedForeignKeys` | `int` | nein | neu angelegte FKs |
| `Status` | `varchar(16)` | nein | COPIED |

ResultTableNULL direkte Fachausgabe, sonst Routing in vorhandene lokale Caller-#Temp. Plantexte/Resultshape Latin1_General_100_BIN2. Hilfe: bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile(SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)),frühe Rückkehr ohne Fachprüfung oder Mutation. Öffentliche Planner-/Execute-/Copy-Hilfe RETURN0; interne Corehilfe behält ihr ursprüngliches RETURN; unverändert. Kein zusätzliches Fachresultset bei Zielrouting.

## Aufrufbeispiele

```sql
EXEC toolbelt_metadata.USP_CopyTableCloneData @Hilfe=1;
CREATE TABLE #ContosoMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,
 SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #ContosoMap VALUES(1,N'dbo',N'ContosoSource',N'dbo',N'ContosoClone');
-- Bestehendes leeres formgleiches Ziel, vorhandene Rechte vorausgesetzt; ändert Daten.
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#ContosoMap',
 @IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@RowLimit=1000,@PayloadByteLimit=1048576;
DROP TABLE #ContosoMap;
```

## Rechte

Vorhandenes EXECUTE auf Copy/Core-Ownershipchain und ResultTable-Helper. DB VIEW DEFINITION; SELECT sys.sql_expression_dependencies,sys.security_predicates,sys.security_policies; SELECT auf Quellen und Ziele sowie INSERT auf Ziele. KEEP mit Identity zusätzlich ALTER auf jeweiliges Ziel. Nur fehlende FK-DDL zusätzlich Server VIEW ANY DEFINITION, lesbare DB-/Server-DDL-Kataloge und ALTER/REFERENCES auf betroffene Zielobjekte. Kein pauschales sysadmin, keine Rechteerteilung; bereits vorhandene Isolationsoption bei SNAPSHOT.

## Ressourcenbedarf

Map1..64,jeQuelle<=1024Spalten;RowLimit1..100000 und PayloadByteLimit1..16777216 global über alleMaps, nur absenkbar,keine NULL/0unlimitedoption. Tatsächlich transportierte Source-DATALENGTH-Summe,NULL0;keine Index-/Log-/Versionstore-/Heapquote. Mehrfachscans,Shape-/FK-/Count-/Payloadadmission vorDML und Target-TABLOCKX/Quell-SERIALIZABLE-Sperren können blockieren. SNAPSHOT benötigt Versionstore. Kein hartes Zeitbudget/Deadlockfreiheits-/Peakmemoryversprechen; kooperierender AppLock Timeout0 ist kein Statementtimeout.

## Nebenwirkungen

Frühe Hilfe vor Fach-/Callerprüfung. Aktive Caller-TX mit prozeduralem XACT_ABORT OFF/RAISERROR50000 ablehnen, keine Callerarbeit zurückrollen. IdentityMode KEEP/REGENERATE und ConsistencyMode SNAPSHOT/SERIALIZABLE explizit wählen, endliche globale Row-/Payloadlimits. Lokale unterschiedliche Map-/Ergebnistemp und reservierte eigene Namespaces prüfen; Copy verlangt zusätzlich exakte Mapspaltenreihenfolge und keine IDENTITY. Höchstens65 Kandidaten mit begrenzten128er-Identifierwerten in Admission aufnehmen,1..64 gültige eindeutige Maps zulassen. Vorhandene SameDB-Source-/Targetobjekte als jeweils eindeutige disjunkte Mengen binden; keine Tabellenanlage/Truncate/Upsert.

DB-Vollsicht, Dependency-/Securitykatalog-SELECT und Source-SELECT/Target-SELECT+INSERT verlangen. Normale unterstützte Tabellen-/Spaltenformen, keine RLS-Prädikate (auch nicht still ignorierte inaktive), aktiven Target-DML-Trigger oder nicht tabellenlokalen Default/CHECK/Computed-Ausführungspfad. Die Copy-Systemtypmenge enthält auch text/ntext/image; Quell-/Zieltypen und geordnete Columnpositionen müssen aber exakt passen, keine Konvertierung. Name/Typ/UserType/Länge/Precision/Scale/Nullability/Collation/Computeddefinition/Persisted/Identityseed+increment/ANSI_PADDING/XMLmetadaten als bytegebundene Form vergleichen und mehrfach gegen Drift prüfen.

SNAPSHOT setzt bereits aktivierte DB-Option voraus, niemals automatisch einschalten; SERIALIZABLE hält Quell-TABLOCK/HOLDLOCK. Ziele in globaler ObjectID-Reihenfolge mit TABLOCKX/UPDLOCK/HOLDLOCK sperren und leer verlangen. Eigener TX mit XACT_ABORT ON und shared Transaction-AppLock/Timeout0. Geordnete Columnshape binden; Computed/rowversion nie transportieren, REGENERATE zusätzlich Identity auslassen, KEEP nur mit vorhandenem Target-ALTER für Identity. Keine Source-/Target-Reseeds oder neue Keymappingtabelle.

Interner Core COPY_FK validiert alle relevanten Source-FK-Tupel, verlangt gemappte Referenzen und vergleicht vorhandene Target-FKs strukturell samt Aktionen/Zuständen/Spaltenreihenfolge. Fehlende FKs getrennt planen, abweichende/zusätzliche/mehrdeutige Existing-FKs ablehnen. Nur tatsächlich fehlende FK-DDL aktiviert Server-DDL-Vollsicht/Seiteneffektprüfungen und zusätzliche Target-ALTER/REFERENCES. REGENERATE bei identityabhängigen Beziehungen unzulässig. Zuerst Count aller Quellen global begrenzen, danach nur transportierte Payload-DATALENGTH-Summen aller Quellen global begrenzen, noch keine Inserts.

In bestehender aktiver Target-FK-Reihenfolge kopieren; ein Zyklus kann nach vorherigen eigenen Inserts erkannt werden und führt zum eigenen Gesamtrollback. Explizites INSERT SELECT mit gebundenen Spalten oder begrenzte DEFAULT-VALUES-Schleife, falls keine transportierten Spalten. KEEP-ID:ON/INSERT/OFF im selben dynamischen Batch; Ownershipflag schaltet nur den eigenen erfolgreich aktivierten Zustand ab, sekundärer OFF-Fehler als feste Meldung, Primärfehler erhalten. Insertcount muss Admissioncount entsprechen. Vor FK-DDL Safety erneut prüfen, Coreplan unter derselben TX erneut erzeugen und Hashgleichheit verlangen, Safety unmittelbar danach erneut prüfen. Fehlende FKs samt Quellzuständen hinzufügen, Ergebnisrouting in derselben TX, Commit vor direktem Receipt. CATCH nur eigener Rollback mit redigierter sekundärer Meldung. Identity-Zähler können Rollback überleben; keine externe oder nichttransaktionale Atomizität/Retry-Zusage.

## Fehlerbehandlung

AktiveCaller-TX:RAISERROR50000/State1 ohneDoomen.53940Argument/Map/Namespace,53941Rechte/Sicht/Shape/Option,53942RLS/Trigger/externeExpression/DDL-Seiteneffekte,53943globalesRow-/Payloadbudget,53944Target-/FK-/Insertcount-/Shape-/Hashdrift,53946AppLock. Core-/Engine-/Helperfehler original; sekundäreIdentity-OFF-/RollbackfehlerfesteSeverity10, Primärfehler erhalten.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/DDL-/Copy-/Installerabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Keine Installations-/Rechteattestation; Vorschau ist kein Ausführungsauftrag, Hash ist keine Herkunftssignatur. Keine automatische Rechte-/Owner-/Konfigurationsänderung, Trustvorbereitung oder externe Kopie. Reale Kataloge, Definitionen, DB-Identitäten, Hashkontexte und Nutzdaten privat halten.
