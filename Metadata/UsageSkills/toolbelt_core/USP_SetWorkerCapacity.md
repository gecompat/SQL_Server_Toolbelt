---
name: "toolbelt-core-usp-setworkercapacity"
description: "Ändert versionsgebunden die lokale Kapazität einer exakt adressierten nicht geschlossenen Generation."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkerCapacity"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID."}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine vorhandene nicht geschlossene Generation wird adressiert; der Aufruf übernimmt keine Generation."}, {"name": "@Capacity", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Live-Capacity genau dieser Generation. NULL/0/negativ ungültig. Eine Absenkung bricht laufende Arbeit nicht ab; neue Admission wartet auf freie Kapazität."}, {"name": "@ExpectedConfigVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_SetWorkerCapacity.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_SetWorkerCapacity

## Zweck und Einsatzfälle

Ändert versionsgebunden die lokale Kapazität einer exakt adressierten nicht geschlossenen Generation.

## Voraussetzungen

Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine vorhandene nicht geschlossene Generation wird adressiert; der Aufruf übernimmt keine Generation. |
| `@Capacity` | `int` | `NULL` | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Live-Capacity genau dieser Generation. NULL/0/negativ ungültig. Eine Absenkung bricht laufende Arbeit nicht ab; neue Admission wartet auf freie Kapazität. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen fachlichen Ersatzidentitäten. Quelle und Effekte unterscheiden admin- und tokengebundene Pfade ausdrücklich.

## Ergebnisse

WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,Capacity int NOT NULL,ConfigVersion binary(8) NOT NULL Bei normalem Erfolg RETURN0; keine OUTPUT-Parameter. NULLResultTable:direkte eine Zeile nach Commit. Sonst Formvorbereitung und INSERT in die vom Caller bereits angelegte lokale #Temp innerhalb derselben Mutationstransaktion; kein weiterer direkter Fachresultset. KeepData unverändert zum kanonischen Helper. Hilfe: bisheriger zwölfspaltiger Standardhelp-Resultset plus genau eine zusätzliche Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); RETURN0 vor Fachprüfung.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_SetWorkerCapacity @Hilfe=1;

-- Nur mit realer adressierter Workeridentität und frischer globaler Version verwenden:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Version binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerCapacity @WorkerId=@Id,@WorkerGeneration=1,@Capacity=2,@ExpectedConfigVersion=@Version;
-- Synthetische/veraltete Werte werden abgewiesen.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur. Dies ist ein administrativer Steuerpfad ohne Owner-/WorkerTokenprüfung; dafür getrennte passende EXECUTE-Rechte voraussetzen, nicht aus einem Statusleserecht ableiten. Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Keine Rechtevergabe, Serverrolle, Hostauthentifizierung oder pauschalen direkten Tabellenrechte. Für ResultTable-/Statuslese-/CrossDB-Zugriffe jeweils bestehende passende Rechte und Identitätsmapping; ein Dreiteilname überträgt keine Autorität.

## Ressourcenbedarf

Kurze eigene Transaktion, globale Gate-/Scheduler-/Konfigurationssperren und Workerregistrationszugriffe; Register liest neueste Generation und aktualisiert gegebenenfalls mehrere Vorgänger, SetState mehrere AdmissionPaused-Zeilen. Keine implementierte CPU-/Zeit-/Log-/Heap-/Ausgabebytequote oder eigener Locktimeout. Blockierung/Deadlock/Log-/tempdbdruck bleibt möglich. Technische Token-/Principalwerte niemals in öffentliche Testnachweise übernehmen.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Prozedurcode vor dem positiven Hilfezweig; dort keine fachlichen Prüfungen, temporären Ergebnisobjekte oder Mutationen und keine eigenen Debugmessages. Private feste #tbx_-Ergebnistemp vor Callertransaktionsguard. Fachpfad verlangt @@TRANCOUNT0/XACT_STATE0, danach eigene BEGIN TRANSACTION und TRY. Reihenfolge UPDLOCK/HOLDLOCK Gate→Scheduler→Konfigurationszeile. UPDATE des adressierten WorkerId/WorkerGeneration-Tupels mit State<>CLOSED. Keine Owner-/WorkerToken-/Latest-/Heartbeatfrischeprüfung in dieser administrativen Prozedur: auch eine ältere oder UNREACHABLE-Generation kann adressiert werden, wenn sie nicht CLOSED ist. Gültige Capacity1..2147483647; Absenkung gibt keine Slots frei und beendet keinen Handler. Selbstupdate der globalen Konfiguration erzeugt neue ConfigVersion auch bei gleicher Capacity. Keine neuen Registrierungsintervalle oder Generationen. Direkte Ergebnisausgabe erfolgt erst nach Commit. Ein späterer Client-/Transportfehler kann einen bereits erfolgreichen Commit nicht rückgängig machen. ResultTable-Helper und INSERT liegen vor Commit; bei Fehlern rollt die eigene aktive Transaktion zurück. Keine Savepointunterstützung für Callertransaktionen und kein eigener Retry. @Debug erzeugt keine eigenen Messages; nicht an den ResultTable-Helper weitergereicht.

## Fehlerbehandlung

54210/1 Callertransaktion bzw.nichtneutraler XACT_STATE.54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag; fehlende Tabellen/kompilierte Abhängigkeiten können bereits als ursprüngliche Enginefehler auftreten. 54212/1 NULL/veraltete globale ConfigVersion.54213/4 CapacityNULL-oder<1 bzw.WorkerId/WorkerGenerationNULL.54215/3 nicht exakt eine passende nichtCLOSED-Generation. Ursprüngliche Sperr-, Constraint-, Arithmetic-, Helper-, INSERT- und Enginefehler bleiben sichtbar. CATCH rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine fachliche Fehlerstatuszeile.

## Aussagegrenzen

Getrennte administrative EXECUTE-Autorität, kein tokengebundener Worker-Selbstverwaltungsaufruf. Aktuelle globale ConfigVersion ist erforderlich, kein optionaler Check. Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Bindung. Keine Exactly-once-/Hostverlust-/Kill- oder vollständige Betriebsqualifikation allein aus Status/Token/Registrierung. Zusätzliche Skillhilfe wird nicht durch alte Standardhilfe-Nachweise qualifiziert.
