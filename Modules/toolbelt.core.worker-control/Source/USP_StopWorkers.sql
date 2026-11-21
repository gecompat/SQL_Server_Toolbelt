-- Objekt: toolbelt_core.USP_StopWorkers
-- Zweck: Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_StopWorkers
 @WorkersTable sysname=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-stopworkers"
-- description: "Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_StopWorkers"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkersTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation>0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_StopWorkers.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_StopWorkers
--
-- ## Zweck und Einsatzfälle
--
-- Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds.
--
-- ## Voraussetzungen
--
-- Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@WorkersTable` | `sysname` | `NULL` | Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation>0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
--
-- SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.
--
-- ## Ergebnisse
--
-- WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,SlotReservationId uniqueidentifier NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NULL. Je ausgewählter Generation Zeilen für eingefrorene belegte Reservations; ohne solche Reservation eine Zeile mit SlotNULL,NO_ACTIVE_EXECUTION und HoldVersionNULL. Bei vorhandener Reservation ohne passende Disposition ebenfalls StopStatus-FallbackNO_ACTIVE_EXECUTION, also keine universelle Nichtausführungsattestation. Leere Workerwahl liefert null Zeilen; keine garantierte Reihenfolge. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
--
-- CREATE TABLE #ContosoWorkers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
-- -- Nur tatsächlich gewählte vorhandene IDs/Generationen einfügen.
-- EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N'#ContosoWorkers';
-- -- Diese leere Beispielauswahl stoppt keinen Worker.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Administrative EXECUTE-Autorität für die ausdrücklich ausgewählten Generationen, keine WorkerToken-/Ownerprüfung. Vorhandener Zugriff auf die eigene lokale Eingabetemp sowie optionales ResultTable-Routing; keine automatische Erweiterung auf aktuelle/neue Generationen durch frei sichtbare Hostnamen. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.
--
-- ## Ressourcenbedarf
--
-- Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Die Grenzen von 1000 Workern und 100000 Reservations werden erst nach vollständigem Kopieren geprüft; sie sind keine Materialisierungs-, Byte- oder CPUquote. Lokale FAST_FORWARD-Cursor, AppLock-Timeout0 und prozeduraler LOCK_TIMEOUT0. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- Der Code setzt vor dem Fachpfad NOCOUNT ON und XACT_ABORT OFF. Hilfe kehrt vor Ergebnistemp, LOCK_TIMEOUT0, Datenprüfung und Mutation zurück. Im Fachpfad wird die Auswahl in einer eigenen Transaktion unter den globalen Gate-/Scheduler-/Konfigurationssperren eingefroren. Die Zweispaltentemp wird vollständig in eine private PK-Tabelle kopiert; erst dann gelten die Grenze1000 und positive/existierende Generationen. Doppelte Paare scheitern beim Kopieren. Danach werden sämtliche IsOccupied1-Reservations der ausgewählten Generationen kopiert und erst anschließend gegen100000 geprüft.
--
-- Alle privaten Transaction-Disposition-AppLocks werden in Slotreihenfolge mit Timeout0 gewonnen; ein Konflikt bricht die eigene Gesamttransaktion ab. Bereits COMPLETED-WorkItems mit passender ManagedReservationId und vorhandenem Slot-Witness werden als COMMITTED/frei gebucht. Der Batchzweig prüft Witnessexistenz am Slot, nicht noch einmal getrennt Nonce/Execution/Claimgeneration. Andere eingefrorene Reservations erhalten Stop/Hold. AdmissionPaused wird auf ALLEN Generationen ausgewählter stabiler IDs gesetzt; nur die ausdrücklich gewählten Generationen werden PAUSED, sofern ihr State nicht CLOSED oder UNREACHABLE ist. Die globale ConfigVersion bleibt unverändert.
--
-- Keine Handlerunterbrechung, KILL oder Rollbackerfindung. Ergebnisrouting und Mutationen liegen vor Commit in derselben Transaktion; bei geworfenem Fehler keine teilweise erfolgreiche Workerauswahl. Leere Auswahl verändert keine Worker, kann aber eine ResultTable vorbereiten/leeren. Eine Caller-ResultTable, die zugleich Eingabetabelle ist, kann nach dem Einfrieren durch das Routing verändert werden. Private #tbx_-Namen vermeiden; der Namecheck ist keine vollständige Reserviertnamensraum- oder Definitionsprüfung. Eigene Debugmessages entstehen nicht. Direkte Ausgabe erst nach Commit; ein späterer Transportfehler kann einen erfolgten Commit nicht zurücknehmen.
--
-- ## Fehlerbehandlung
--
-- 54210/1 CallerTX;54211/1 Integrationspflichtzeile fehlt.54226/1 EingabenameNULL/nicht#/##;54226/2 fehlende oder nicht passende Zweispaltentemp;54226/3 nach Kopie>1000 oder nichtpositive Generation;54226/4 fehlende exakte Registration;54226/5 nach Snapshot>100000 Reservations. Duplikate ergeben private PK-Enginefehler, keinen eigenen Duplikatstatus.54222/4 negativer privater Gate-AppLock-Rückgabecode. SET LOCK_TIMEOUT0 kann ursprünglichen1222 erzeugen; gesamter eigener TX wird im äußeren CATCH zurückgerollt, kein partieller PASS. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_StopWorkers' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkerId', N'uniqueidentifier', 0, 0, NULL, CAST(N'WorkerId gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkerGeneration', N'bigint', 0, 0, NULL, CAST(N'WorkerGeneration gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'SlotReservationId', N'uniqueidentifier', 0, 1, NULL, CAST(N'SlotReservationId gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'StopStatus', N'varchar(24)', 0, 0, NULL, CAST(N'StopStatus gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'HoldVersion', N'binary(8)', 0, 1, NULL, CAST(N'HoldVersion gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkersTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation>0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_StopWorkers' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-stopworkers"
description: "Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_StopWorkers"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkersTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation>0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt' AS nvarchar(max)) + N' Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_StopWorkers.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_StopWorkers

## Zweck und Einsatzfälle

Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autor' + N'isierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation>0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-s' + N'paltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.

## Ergebnisse

WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,SlotReservationId uniqueidentifier NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NULL. Je ausgewählter Generation Zeilen für eingefrorene belegte Reservations; ohne solche Reservation eine Zeile mit SlotNULL,NO_ACTIVE_EXECUTION und HoldVersionNULL. Bei vorhandener Reservation ohne passende Disposition ebenfalls StopStatus-FallbackNO_ACTIVE_EXECUTION, also keine universelle Nichtausführungsattestation. Leere Workerwahl liefert null Zeilen; keine garantierte Reihenfolge. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;

CREATE TABLE #ContosoWorkers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
-- Nur tatsächlich gewählte vorhandene IDs/Generationen einfügen.
EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N''#ContosoWorkers'';
-- Diese leere Beispielauswahl stoppt keinen Worker.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzu' + N'griff und Identitätsmapping bei zentralem Dreiteilaufruf. Administrative EXECUTE-Autorität für die ausdrücklich ausgewählten Generationen, keine WorkerToken-/Ownerprüfung. Vorhandener Zugriff auf die eigene lokale Eingabetemp sowie optionales ResultTable-Routing; keine automatische Erweiterung auf aktuelle/neue Generationen durch frei sichtbare Hostnamen. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Die Grenzen von 1000 Workern und 100000 Reservations werden erst nach vollständigem Kopieren geprüft; sie sind keine Materialisierungs-, Byte- oder CPUquote. Lokale FAST_FORWARD-Cursor, AppLock-Timeout0 und prozeduraler LOCK_TIMEOUT0. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

Der Code setzt vor dem Fachpfad NOCOUNT ON und XACT_ABORT OFF. Hilfe kehrt vor Ergebnistemp, LOCK_TIMEOUT0, Datenprüfung und Mutation zurück. Im Fachpfad wird die Auswahl in einer eigenen Transaktion unter den globalen Gate-/Scheduler-/Konfigurationssperren eingefroren. Die Zweispaltentemp wird vollständig in eine private PK-Tabelle kopiert; erst dann gelten die Grenze1000 und positive/existierende Generationen. Doppelte Paare scheitern beim Kopieren. Danach werden sämtliche IsOccupied1-Reservations der ausgewählten Generationen kopiert und erst anschließend gegen100000 geprüft.

Alle privaten Transaction-Disposition-AppLocks werden in Slotreihenfolge mit Timeout0 gewonnen; ein Konflikt bricht die eigene Gesamttransaktion ab. Bereits COMPLETED-WorkItems mit passender ManagedReservationId und vorhandenem ' + N'Slot-Witness werden als COMMITTED/frei gebucht. Der Batchzweig prüft Witnessexistenz am Slot, nicht noch einmal getrennt Nonce/Execution/Claimgeneration. Andere eingefrorene Reservations erhalten Stop/Hold. AdmissionPaused wird auf ALLEN Generationen ausgewählter stabiler IDs gesetzt; nur die ausdrücklich gewählten Generationen werden PAUSED, sofern ihr State nicht CLOSED oder UNREACHABLE ist. Die globale ConfigVersion bleibt unverändert.

Keine Handlerunterbrechung, KILL oder Rollbackerfindung. Ergebnisrouting und Mutationen liegen vor Commit in derselben Transaktion; bei geworfenem Fehler keine teilweise erfolgreiche Workerauswahl. Leere Auswahl verändert keine Worker, kann aber eine ResultTable vorbereiten/leeren. Eine Caller-ResultTable, die zugleich Eingabetabelle ist, kann nach dem Einfrieren durch das Routing verändert werden. Private #tbx_-Namen vermeiden; der Namecheck ist keine vollständige Reserviertnamensraum- oder Definitionsprüfung. Eigene Debugmessages entstehen nicht. Direkte Ausgabe erst nach Commit; ein späterer Transportfehler kann einen erfolgten Commit nicht zurücknehmen.

## Fehlerbehandlung

54210/1 CallerTX;54211/1 Integrationspflichtzeile fehlt.54226/1 EingabenameNULL/nicht#/##;54226/2 fehlende oder nicht passende Zweispaltentemp;54226/3 nach Kopie>1000 oder nichtpositive Generation;54226/4 fehlende exakte Registration;54226/5 nach Snapshot>100000 Reservations. Duplikate ergeben private PK-Enginefehler, keinen eigenen Duplikatstatus.54222/4 negativer privater Gate-AppLock-Rückgabecode. SET LOCK_TIMEOUT0 kann ursprünglichen1222 erzeugen; gesamter eigener TX wird im äußeren CATCH zurückgerollt, kein partieller PASS. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine n' + N'eue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_StopWorkers_Result(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,SlotReservationId uniqueidentifier NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NULL);
 -- Prozedurscope: SQL Server restauriert SET-Optionen bei Return/THROW.
 -- Kein dynamisches SET kann den Aufruferkontext restaurieren.
 SET LOCK_TIMEOUT 0;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 BEGIN THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;END;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkersTable IS NULL OR LEFT(@WorkersTable,1)<>N'#' OR LEFT(@WorkersTable,2)=N'##' THROW 54226,N'WorkersTable muss caller-lokal sein.',1;
 DECLARE @WorkersObjectId int=OBJECT_ID(N'tempdb..'+@WorkersTable,N'U');
 IF @WorkersObjectId IS NULL OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@WorkersObjectId)<>2
 OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@WorkersObjectId AND name=N'WorkerId' AND system_type_id=36 AND user_type_id=36 AND is_nullable=0)
 OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@WorkersObjectId AND name=N'WorkerGeneration' AND system_type_id=127 AND user_type_id=127 AND is_nullable=0) THROW 54226,N'Die WorkersTable besitzt keine exakte zweispaltige Form.',2;
 CREATE TABLE #tbx_StopWorkersSelection(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,PRIMARY KEY(WorkerId,WorkerGeneration));
 DECLARE @SelectionSql nvarchar(max)=N'INSERT #tbx_StopWorkersSelection(WorkerId,WorkerGeneration) SELECT WorkerId,WorkerGeneration FROM '+QUOTENAME(@WorkersTable);
 EXEC sys.sp_executesql @SelectionSql;
 IF (SELECT COUNT_BIG(*) FROM #tbx_StopWorkersSelection)>1000 OR EXISTS(SELECT 1 FROM #tbx_StopWorkersSelection WHERE WorkerGeneration<=0) THROW 54226,N'Die eingefrorene Workerselektion ist ungültig.',3;
 IF EXISTS(SELECT 1 FROM #tbx_StopWorkersSelection s WHERE NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration w WHERE w.WorkerId=s.WorkerId AND w.WorkerGeneration=s.WorkerGeneration)) THROW 54226,N'Eine ausgewählte exakte Generation fehlt.',4;
 CREATE TABLE #tbx_StopWorkersReservations(SlotReservationId uniqueidentifier NOT NULL PRIMARY KEY,WorkItemId bigint NOT NULL,WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
 INSERT #tbx_StopWorkersReservations SELECT r.SlotReservationId,r.WorkItemId,r.WorkerId,r.WorkerGeneration FROM toolbelt_core.WorkerSlotReservation r JOIN #tbx_StopWorkersSelection s ON s.WorkerId=r.WorkerId AND s.WorkerGeneration=r.WorkerGeneration WHERE r.IsOccupied=1;
 IF (SELECT COUNT_BIG(*) FROM #tbx_StopWorkersReservations)>100000 THROW 54226,N'Das explizite Reservationselektionslimit ist überschritten.',5;
 -- Alle Gates ohne Warten gewinnen oder atomar vollständig abbrechen: globale Locks
 -- werden niemals beim Warten auf einen privaten äußeren Commit festgehalten.
 DECLARE @Reservation uniqueidentifier,@Resource nvarchar(255),@Lock int;
 DECLARE stop_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT SlotReservationId FROM #tbx_StopWorkersReservations ORDER BY SlotReservationId;
 OPEN stop_cursor;FETCH NEXT FROM stop_cursor INTO @Reservation;
 WHILE @@FETCH_STATUS=0 BEGIN
 SET @Resource=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@Reservation);
 EXEC @Lock=sys.sp_getapplock @Resource=@Resource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @Lock<0 BEGIN CLOSE stop_cursor;DEALLOCATE stop_cursor;THROW 54222,N'Die atomare Stopselektion kollidiert mit einem privaten Completionpfad.',4;END;
 FETCH NEXT FROM stop_cursor INTO @Reservation; END;
 CLOSE stop_cursor;DEALLOCATE stop_cursor;
 CREATE TABLE #tbx_StopWorkersCommitted(SlotReservationId uniqueidentifier NOT NULL PRIMARY KEY);
 DECLARE @CommittedReservation uniqueidentifier;
 DECLARE committed_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT r.SlotReservationId FROM #tbx_StopWorkersReservations r JOIN toolbelt_core.WorkItem wi ON wi.WorkItemId=r.WorkItemId AND wi.Status='COMPLETED' AND wi.ManagedReservationId=r.SlotReservationId;
 OPEN committed_cursor;FETCH NEXT FROM committed_cursor INTO @CommittedReservation;
 WHILE @@FETCH_STATUS=0 BEGIN
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(READCOMMITTEDLOCK) WHERE SlotReservationId=@CommittedReservation)
 INSERT #tbx_StopWorkersCommitted VALUES(@CommittedReservation);
 FETCH NEXT FROM committed_cursor INTO @CommittedReservation;END;
 CLOSE committed_cursor;DEALLOCATE committed_cursor;
 UPDATE reservation SET State='COMMITTED',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) FROM toolbelt_core.WorkerSlotReservation reservation JOIN #tbx_StopWorkersCommitted committed ON committed.SlotReservationId=reservation.SlotReservationId;
 UPDATE d SET StopStatus='ALREADY_COMMITTED',IsHeld=0 FROM toolbelt_core.WorkerExecutionDisposition d JOIN #tbx_StopWorkersCommitted committed ON committed.SlotReservationId=d.SlotReservationId;
 UPDATE w SET AdmissionPaused=1 FROM toolbelt_core.WorkerRegistration w WHERE EXISTS(SELECT 1 FROM #tbx_StopWorkersSelection s WHERE s.WorkerId=w.WorkerId);
 UPDATE w SET State=CASE WHEN State IN('CLOSED','UNREACHABLE') THEN State ELSE 'PAUSED' END FROM toolbelt_core.WorkerRegistration w JOIN #tbx_StopWorkersSelection s ON s.WorkerId=w.WorkerId AND s.WorkerGeneration=w.WorkerGeneration;
 UPDATE d SET IsHeld=1,StopStatus='REQUESTED' FROM toolbelt_core.WorkerExecutionDisposition d JOIN #tbx_StopWorkersReservations r ON r.SlotReservationId=d.SlotReservationId WHERE NOT EXISTS(SELECT 1 FROM #tbx_StopWorkersCommitted committed WHERE committed.SlotReservationId=r.SlotReservationId);
 UPDATE wi SET ManagedHold=1 FROM toolbelt_core.WorkItem wi JOIN #tbx_StopWorkersReservations r ON r.WorkItemId=wi.WorkItemId WHERE wi.ManagedReservationId=r.SlotReservationId AND NOT EXISTS(SELECT 1 FROM #tbx_StopWorkersCommitted committed WHERE committed.SlotReservationId=r.SlotReservationId);
 UPDATE r SET State='STOP_REQUESTED' FROM toolbelt_core.WorkerSlotReservation r JOIN #tbx_StopWorkersReservations s ON s.SlotReservationId=r.SlotReservationId WHERE r.IsOccupied=1;
 INSERT #tbx_USP_StopWorkers_Result SELECT s.WorkerId,s.WorkerGeneration,r.SlotReservationId,ISNULL(d.StopStatus,'NO_ACTIVE_EXECUTION'),d.HoldVersion FROM #tbx_StopWorkersSelection s LEFT JOIN #tbx_StopWorkersReservations r ON r.WorkerId=s.WorkerId AND r.WorkerGeneration=s.WorkerGeneration LEFT JOIN toolbelt_core.WorkerExecutionDisposition d ON d.SlotReservationId=r.SlotReservationId;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_StopWorkers_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkerId,WorkerGeneration,SlotReservationId,StopStatus,HoldVersion) SELECT WorkerId,WorkerGeneration,SlotReservationId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkers_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;

 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION;  THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkerId,WorkerGeneration,SlotReservationId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkers_Result;
 RETURN 0;
END;
GO
