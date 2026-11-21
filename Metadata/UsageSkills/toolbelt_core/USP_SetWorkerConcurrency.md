---
name: "toolbelt-core-usp-setworkerconcurrency"
description: "Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkerConcurrency"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@MaxConcurrentExecutions", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal."}, {"name": "@ExpectedConfigVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_SetWorkerConcurrency.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_SetWorkerConcurrency

## Zweck und Einsatzfälle

Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen.

## Voraussetzungen

Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@MaxConcurrentExecutions` | `int` | `NULL` | Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

NULL-Defaults erforderlicher Fachwerte dienen nur dem Hilfeaufruf. Eingabekonvertierung auf die SQL-Parametertypen geschieht vor dem Prozedurcode; zu lange Namen/Bytes nicht als eigene Validierung behandeln.

## Ergebnisse

Bei direkter Ausgabe genau eine Zeile mit ConfigVersion binary(8) NOT NULL, MaxConcurrentExecutions int NOT NULL, OccupiedSlots bigint NOT NULL. Kein OUTPUT-Parameter; RETURN0. Bei nicht-NULL ResultTable wird die Zeile innerhalb derselben Mutationstransaktion über USP_PrepareResultTable und explizites dynamisches INSERT geroutet, ohne zusätzlichen direkten Fachresultset. KeepData wird unverändert an den Helper übergeben. Keine Tokens oder Payloads im Ergebnis. Neue ConfigVersion ist nach jedem erfolgreichen UPDATE neu, auch bei identischen Werten. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine Zeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=2,@ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Steuerprozedur; fachliche Mutation ist getrennt von bloßem SELECT auf Statusviews berechtigt. Zugriff auf interne Tabellen folgt den tatsächlichen Ownership-Chains/Objektrechten; keine automatische Rechtevergabe, Identitätsumschaltung, Serverrolle oder serverweite Sichtbarkeit. Für die vorherige Versionsabfrage sind Rechte auf die gewählte lesende Oberfläche separat nötig. ResultTable-Routing verlangt die tatsächlichen Caller-/Helper-/Temp-Rechte, kein pauschales direktes Tabellen-SELECT als neue Vorgabe.

## Ressourcenbedarf

Eigene kurze Transaktion mit UPDLOCK/HOLDLOCK auf Gate, Scheduler und globaler Konfigurationszeile; Sperren bleiben bis Commit/Rollback. Keine implementierte CPU-/Zeit-/Ausgabebytequote oder eigener Locktimeout. Eine globale COUNT_BIG-Abfrage über belegte Reservations liefert die Budgetbelegung. Optionale Helper-DDL/INSERT erhöht Transaktionsumfang. Deadlocks, Sperr-/Log-/tempdb-/Speicherdruck bleiben möglich.

## Nebenwirkungen

Im Prozedurcode SET NOCOUNT ON und SET XACT_ABORT OFF bereits vor dem positiven Hilfezweig. Die Hilfe kehrt vor CREATE TABLE, Datenabfragen oder fachlichen Mutationen zurück; keine fachlichen Callerwertevalidierung oder eigenen Debugmessages. Fachpfad legt eine private feste #tbx_-Ergebnistemp an, prüft anschließend Callertransaktion, startet eigene Transaktion und sperrt Gate→Scheduler→Konfiguration. Keine Savepoints/Commit/Rollback einer erlaubten Callertransaktion, da Callertransaktionen abgewiesen werden. Aktualisiert nur MaxConcurrentExecutions. 0 oder ein Budget unter bereits belegten Slots beendet keine laufende Arbeit und gibt keine unbekannten Reservations frei. OccupiedSlots zählt global ausschließlich IsOccupied1 unabhängig von State. Wiederholter gleicher Budgetwert verändert dennoch ConfigVersion. Ein Selbstupdate der globalen Konfiguration erzeugt die neue Version auch beim Moduswechsel. ResultTable-Form/Zeilen werden vor Commit in derselben Transaktion vorbereitet/eingefügt; bei Helper-/INSERTfehlern wird die eigene Mutation zurückgerollt. Direkte Ergebnisausgabe erfolgt erst nach Commit; ein späterer Transport-/Clientfehler kann bereits begangene Mutation nicht zurücknehmen. @Debug erzeugt keine eigenen zusätzlichen Messages und wird hier nicht an den Helper weitergereicht.

## Fehlerbehandlung

54210/State1 bei Callertransaktion oder nichtneutralem XACT_STATE, vor eigener BEGIN TRANSACTION. Innerhalb TRY:54211/1 fehlendes Gate/Scheduler-/Konfigurationsobjekt bzw. fehlende Pflichtzeile,54212/1 NULL/veraltete ExpectedConfigVersion; tatsächliche fehlende Tabellen können bereits als technische Kompilierungs-/Enginefehler auftreten, keine universelle54211-Abbildung. 54213/1 bei NULL/negativem MaxConcurrentExecutions; int-Maximum2147483647 ist zulässig. Helper-/Tempnamespace-/DDL-/INSERT-/Sperr-/Deadlockfehler bleiben Engine-/Helperfehler. Catch rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler sind nicht separat geschützt. Kein eingebauter Retry. Return0 nur nach Erfolg oder Hilfe; keine fachlichen Fehlerstatuszeilen.

## Aussagegrenzen

Quellgeprüfter aktueller Fach-/Hilfevertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installerabnahme. Historische unveränderte Fachbelege qualifizieren nur ihre ursprünglichen Artefakte, nicht die zusätzliche Skillausgabe. Kein automatisches Enable CLR/Trust/Serverneustart, kein Workerstart oder Abbruch laufender Handler. ConfigVersion ist ein SQL-Concurrencytoken, keine globale Betriebsgesundheit oder Ausführungsautorität. Hilfeprojektion und alte Bootstrap-Parameterreferenzen müssen bei der abschließenden Einquellenmigration konsistent abgeglichen werden.
