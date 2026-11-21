SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DeleteEventsBefore]
(
      @BeforeOccurredAtUtc datetime2(7) = NULL
    , @BatchSize int = 1000
    , @MaxBatches int = 1
    , @DeletedRows bigint = NULL OUTPUT
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-usp-deleteeventsbefore"
-- description: "Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.event-log"
-- schema_name: "toolbelt_core"
-- object_name: "USP_DeleteEventsBefore"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@BeforeOccurredAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich OccurredAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung."}, {"name": "@BatchSize", "sql_type": "int", "sql_default": "1000", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen."}, {"name": "@MaxBatches", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt."}, {"name": "@DeletedRows", "sql_type": "bigint", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.core.event-log/Source/USP_DeleteEventsBefore.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_DeleteEventsBefore
--
-- ## Zweck und Einsatzfälle
--
-- Explizite begrenzte Retention ausschließlich nach OccurredAtUtc < @BeforeOccurredAtUtc. Gleichheit bleibt erhalten. Callerbeeinflussbarer fachlicher Ereigniszeitpunkt; nicht serverseitige Aufzeichnungszeit.
--
-- ## Voraussetzungen
--
-- Installiertes EventLog, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal oder zentral. Gültiger datetime2(7)-Cutoff als UTC-Konvention ohne automatische Zeitzonenkonvertierung. Kein Second-Session-Provider für Retention erforderlich. Fehlender Cutoff wird im Fachpfad abgewiesen. Committable Callertransaktion erlaubt, uncommittable nicht.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@BeforeOccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich OccurredAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
-- | `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen. |
-- | `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
-- | `@DeletedRows` | `bigint` | `NULL` | INPUT/OUTPUT | bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- Kein fachliches SELECT-Resultset. RETURN 0 bei Erfolg. @DeletedRows bigint OUTPUT enthält die Summe tatsächlich gelöschter Zeilen des erfolgreichen Aufrufs; bei Hilfe 0. Ein OUTPUT-Wert nach Fehler beweist keine committed Löschung. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- DECLARE @Deleted bigint;
-- EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2000-01-01T00:00:00',@BatchSize=100,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
-- SELECT @Deleted AS DeletedRows;
-- -- Nur im autorisierten synthetischen Scope; persistente Löschung.
-- EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser administrativen Retention-USP und funktionierende bestehende Ownership-/Objektrechte auf EventLog. Keine Empfehlung einer pauschalen DELETE-Berechtigung für Lesekonsumenten. Zentraler Aufruf benötigt gültige Ziel-DB-Identität/Mapping und Rechte; die Prozedur erteilt sie nicht. Kein Serverstatusrecht, kein direkter Zugriff auf Second-Session-Transport nötig.
--
-- ## Ressourcenbedarf
--
-- BatchSize 1..10000, MaxBatches 1..100: höchstens 1000000 Löschungen je Aufruf. NULL-BatchSize=1000, NULL-MaxBatches=1. Schleife stoppt zusätzlich beim ersten Batch mit 0 Treffern; kein Hintergrundjob oder automatisches Fortsetzen. Deterministische Auswahl je Batch ORDER BY EventId, nicht nach OccurredAtUtc; vorhandene EventId-/OccurredAtUtc-Indexe sind keine Zusage eines bestimmten Plans. Alle Batches gehören zu EINER Transaktion; Log/Sperren können trotz kleiner Batches bis zum gesamten Commit bzw. Callercommit bestehen. Keine READPAST-/NOLOCK- oder stabile Gesamtsnapshotgarantie, keine feste CPU-/Heap-/Latenzquote.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON, SET XACT_ABORT OFF; BatchSize/MaxBatches/Debug/Hilfe normalisiert und @DeletedRows=0 bereits vor Hilfe. Ohne Callertransaktion eigener BEGIN/COMMIT um die gesamte Schleife, sonst fester SAVEPOINT TBX_EventLog_Retention. Fehler: eigener Scope Rollback, bestehender Caller nur bei XACT_STATE()=1 zum Savepoint; niemals vollständiger Callercommit/-rollback. Ein späterer Callerrollback kann erfolgreiche Retention zurücknehmen. BEGIN/SAVE steht vor TRY, etwa fehlende Distributed-Savepoint-Unterstützung bleibt Enginefehler. Rollbackfehler werden nicht separat abgefangen. Debug 1..255: erst nach Erfolg Severity-10-NOWAIT-Meldung mit Löschzahl, ohne Eventdaten; 0/NULL ohne Diagnose. Keine automatische Planung, kein Purge bei Installation.
--
-- ## Fehlerbehandlung
--
-- 51710 fehlender Cutoff, 51711 ungültige BatchSize, 51712 ungültige MaxBatches, 51713 XACT_STATE=-1, in dieser Priorität. Hilfe kehrt davor zurück. Die gelegentlich dokumentierte Bereichsobergrenze 51714 bedeutet keinen implementierten eigenen THROW 51714 in dieser Prozedur. Unerwartete Engine-/Berechtigungs-/Sperr-/Rollbackfehler bleiben sichtbar.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @BatchSize = ISNULL(@BatchSize, 1000);
    SET @MaxBatches = ISNULL(@MaxBatches, 1);
    SET @DeletedRows = 0;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_DeleteEventsBefore' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51710-51714', NULL, NULL, NULL, NULL, CAST(N'Grenz-, Pflichtparameter- und Transaktionsfehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Löscht höchstens 5000 alte Events.' AS nvarchar(max)), CAST(N'DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc=''2026-01-01'', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@BeforeOccurredAtUtc', N'datetime2(7)', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),''2026-10-30T00:00:00'',126). Löscht ausschließlich OccurredAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@BatchSize', N'int', 0, 1, N'1000', CAST(N'Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxBatches', N'int', 0, 1, N'1', CAST(N'Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@DeletedRows', N'bigint', 0, 1, N'NULL', CAST(N'bigint OUTPUT: Der Eingabewert wird immer auf 0 gesetzt, auch im Hilfemodus; danach Anzahl der in diesem Aufruf gelöschten Zeilen. Zum Empfangen eine bigint-Variable mit OUTPUT übergeben; Eingabe-NULL ist kein Löschlimit.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_DeleteEventsBefore' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-core-usp-deleteeventsbefore"
description: "Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus."
skill_format_version: "1.0"
module_id: "toolbelt.core.event-log"
schema_name: "toolbelt_core"
object_name: "USP_DeleteEventsBefore"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@BeforeOccurredAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),''2026-10-30T00:00:00'',126). Löscht ausschließlich OccurredAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung."}, {"name": "@BatchSize", "sql_type": "int", "sql_default": "1000", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen."}, {"name": "@MaxBatches", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt."}, {"name": "@DeletedRows", "sql_type": "bigint", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable ' AS nvarchar(max)) + N'mit OUTPUT übergeben; kein Löschlimit."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.event-log/Source/USP_DeleteEventsBefore.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_DeleteEventsBefore

## Zweck und Einsatzfälle

Explizite begrenzte Retention ausschließlich nach OccurredAtUtc < @BeforeOccurredAtUtc. Gleichheit bleibt erhalten. Callerbeeinflussbarer fachlicher Ereigniszeitpunkt; nicht serverseitige Aufzeichnungszeit.

## Voraussetzungen

Installiertes EventLog, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal oder zentral. Gültiger datetime2(7)-Cutoff als UTC-Konvention ohne automatische Zeitzonenkonvertierung. Kein Second-Session-Provider für Retention erforderlich. Fehlender Cutoff wird im Fachpfad abgewiesen. Committable Callertransaktion erlaubt, uncommittable nicht.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@BeforeOccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),''2026-10-30T00:00:00'',126). Löscht ausschließlich OccurredAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zei' + N'tzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | INPUT/OUTPUT | bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

## Ergebnisse

Kein fachliches SELECT-Resultset. RETURN 0 bei Erfolg. @DeletedRows bigint OUTPUT enthält die Summe tatsächlich gelöschter Zeilen des erfolgreichen Aufrufs; bei Hilfe 0. Ein OUTPUT-Wert nach Fehler beweist keine committed Löschung. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam.

## Aufrufbeispiele

```sql
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurred' + N'AtUtc=''2000-01-01T00:00:00'',@BatchSize=100,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
SELECT @Deleted AS DeletedRows;
-- Nur im autorisierten synthetischen Scope; persistente Löschung.
EXEC toolbelt_core.USP_DeleteEventsBefore @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser administrativen Retention-USP und funktionierende bestehende Ownership-/Objektrechte auf EventLog. Keine Empfehlung einer pauschalen DELETE-Berechtigung für Lesekonsumenten. Zentraler Aufruf benötigt gültige Ziel-DB-Identität/Mapping und Rechte; die Prozedur erteilt sie nicht. Kein Serverstatusrecht, kein direkter Zugriff auf Second-Session-Transport nötig.

## Ressourcenbedarf

BatchSize 1..10000, MaxBatches 1..100: höchstens 1000000 Löschungen je Aufruf. NULL-BatchSize=1000, NULL-MaxBatches=1. Schleife stoppt zusätzlich beim ersten Batch mit 0 Treffern; kein Hintergrundjob oder automatisches Fortsetzen. Deterministische Auswahl je Batch ORDER BY EventId, nicht nach OccurredAtUtc; vorhandene EventId-/OccurredAtUtc-Indexe sind keine Zusage eines bestimmten Plans. Alle Batches gehören zu EINER Transaktion; Log/Sperren können trotz kleiner Batches bis zum gesamten Commit bzw. Callercommit bestehen. Keine READPAST-/NOLOCK- oder stabile Gesamtsnapshotgarantie, keine feste CPU-/Heap-/Latenzquote.

## Nebenwirkungen

SET NOCOUNT ON, SET XACT_ABORT OFF; BatchSize/MaxBatches/Debug/Hilfe normalisiert und @DeletedRows=0 bereits vor Hilfe. Ohne Callertransaktion eigener BEGIN/COMMIT um die gesamte Schleife, sonst fester SAVEPOINT TBX_EventLog_Retention. Fehler: eigener Scope Rollback, bestehender Caller nur bei XACT_STATE()=1 zum Savepoint; niemals vollständiger Callercommit/-rollback. Ein späterer Callerrollback kann erfolgreiche Retention zurücknehmen. BEGIN/SAVE steht vor TRY, etwa fehlende Distributed-Savepoint-Unterstützung bleibt Enginefehler. Rollbackfehler werden nicht separat abgefangen. Debug 1..255: erst nach Erfolg Severity-10-NOWAIT-Meldung mit Löschzahl, ohne Eventdaten; 0/NULL ohne ' + N'Diagnose. Keine automatische Planung, kein Purge bei Installation.

## Fehlerbehandlung

51710 fehlender Cutoff, 51711 ungültige BatchSize, 51712 ungültige MaxBatches, 51713 XACT_STATE=-1, in dieser Priorität. Hilfe kehrt davor zurück. Die gelegentlich dokumentierte Bereichsobergrenze 51714 bedeutet keinen implementierten eigenen THROW 51714 in dieser Prozedur. Unerwartete Engine-/Berechtigungs-/Sperr-/Rollbackfehler bleiben sichtbar.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @BeforeOccurredAtUtc IS NULL
        THROW 51710, N'@BeforeOccurredAtUtc ist erforderlich.', 1;
    IF @BatchSize NOT BETWEEN 1 AND 10000
        THROW 51711, N'@BatchSize muss zwischen 1 und 10000 liegen.', 1;
    IF @MaxBatches NOT BETWEEN 1 AND 100
        THROW 51712, N'@MaxBatches muss zwischen 1 und 100 liegen.', 1;
    IF XACT_STATE() = -1
        THROW 51713, N'Retention ist in einer uncommittable Transaktion nicht möglich.', 1;

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_EventLog_Retention;

    BEGIN TRY
        DECLARE @Batch int = 0;
        DECLARE @Rows int = 1;
        WHILE @Batch < @MaxBatches AND @Rows > 0
        BEGIN
            ;WITH Targets AS
            (
                SELECT TOP (@BatchSize) EventId
                FROM toolbelt_core.EventLog
                WHERE OccurredAtUtc < @BeforeOccurredAtUtc
                ORDER BY EventId
            )
            DELETE FROM Targets;
            SET @Rows = @@ROWCOUNT;
            SET @DeletedRows += @Rows;
            SET @Batch += 1;
        END;

        IF @InitialTranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_EventLog_Retention;
        THROW;
    END CATCH;

    IF @Debug > 0
    BEGIN
        DECLARE @DeletedForMessage varchar(32) = CONVERT(varchar(32), @DeletedRows);
        RAISERROR(N'USP_DeleteEventsBefore: %s Events gelöscht.', 10, 1, @DeletedForMessage) WITH NOWAIT;
    END;
    RETURN 0;
END;
GO
