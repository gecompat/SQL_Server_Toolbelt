---
name: "toolbelt-core-usp-stopworkers"
description: "Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_StopWorkers"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkersTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation>0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_StopWorkers.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_StopWorkers

## Zweck und Einsatzfälle

Friert eine explizite Worker-generationen-Auswahl ein und persistiert atomar Pause/Stop/Holds.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Vorhandene caller-lokale #Temp-Tabelle, keine ##Temp oder persistente Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. Spaltenreihenfolge, Index und Identity werden nicht geprüft, Columnnamen folgen tempdb-Kollation. 0..1000 eindeutige Paare, Generation>0, jede exakte Generation muss existieren. Duplikate scheitern beim Kopieren am privaten PK. Grenzen erst nach vollständiger Kopie/Snapshot: keine Scanquote, maximal100000 eingefrorene Reservations. Leer bedeutet keine Workeraktion; optionale ResultTable-Vorbereitung bleibt möglich. Keine privaten #tbx_-Namen verwenden. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.

## Ergebnisse

WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,SlotReservationId uniqueidentifier NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NULL. Je ausgewählter Generation Zeilen für eingefrorene belegte Reservations; ohne solche Reservation eine Zeile mit SlotNULL,NO_ACTIVE_EXECUTION und HoldVersionNULL. Bei vorhandener Reservation ohne passende Disposition ebenfalls StopStatus-FallbackNO_ACTIVE_EXECUTION, also keine universelle Nichtausführungsattestation. Leere Workerwahl liefert null Zeilen; keine garantierte Reihenfolge. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;

CREATE TABLE #ContosoWorkers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
-- Nur tatsächlich gewählte vorhandene IDs/Generationen einfügen.
EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N'#ContosoWorkers';
-- Diese leere Beispielauswahl stoppt keinen Worker.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Administrative EXECUTE-Autorität für die ausdrücklich ausgewählten Generationen, keine WorkerToken-/Ownerprüfung. Vorhandener Zugriff auf die eigene lokale Eingabetemp sowie optionales ResultTable-Routing; keine automatische Erweiterung auf aktuelle/neue Generationen durch frei sichtbare Hostnamen. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Die Grenzen von 1000 Workern und 100000 Reservations werden erst nach vollständigem Kopieren geprüft; sie sind keine Materialisierungs-, Byte- oder CPUquote. Lokale FAST_FORWARD-Cursor, AppLock-Timeout0 und prozeduraler LOCK_TIMEOUT0. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

Der Code setzt vor dem Fachpfad NOCOUNT ON und XACT_ABORT OFF. Hilfe kehrt vor Ergebnistemp, LOCK_TIMEOUT0, Datenprüfung und Mutation zurück. Im Fachpfad wird die Auswahl in einer eigenen Transaktion unter den globalen Gate-/Scheduler-/Konfigurationssperren eingefroren. Die Zweispaltentemp wird vollständig in eine private PK-Tabelle kopiert; erst dann gelten die Grenze1000 und positive/existierende Generationen. Doppelte Paare scheitern beim Kopieren. Danach werden sämtliche IsOccupied1-Reservations der ausgewählten Generationen kopiert und erst anschließend gegen100000 geprüft.

Alle privaten Transaction-Disposition-AppLocks werden in Slotreihenfolge mit Timeout0 gewonnen; ein Konflikt bricht die eigene Gesamttransaktion ab. Bereits COMPLETED-WorkItems mit passender ManagedReservationId und vorhandenem Slot-Witness werden als COMMITTED/frei gebucht. Der Batchzweig prüft Witnessexistenz am Slot, nicht noch einmal getrennt Nonce/Execution/Claimgeneration. Andere eingefrorene Reservations erhalten Stop/Hold. AdmissionPaused wird auf ALLEN Generationen ausgewählter stabiler IDs gesetzt; nur die ausdrücklich gewählten Generationen werden PAUSED, sofern ihr State nicht CLOSED oder UNREACHABLE ist. Die globale ConfigVersion bleibt unverändert.

Keine Handlerunterbrechung, KILL oder Rollbackerfindung. Ergebnisrouting und Mutationen liegen vor Commit in derselben Transaktion; bei geworfenem Fehler keine teilweise erfolgreiche Workerauswahl. Leere Auswahl verändert keine Worker, kann aber eine ResultTable vorbereiten/leeren. Eine Caller-ResultTable, die zugleich Eingabetabelle ist, kann nach dem Einfrieren durch das Routing verändert werden. Private #tbx_-Namen vermeiden; der Namecheck ist keine vollständige Reserviertnamensraum- oder Definitionsprüfung. Eigene Debugmessages entstehen nicht. Direkte Ausgabe erst nach Commit; ein späterer Transportfehler kann einen erfolgten Commit nicht zurücknehmen.

## Fehlerbehandlung

54210/1 CallerTX;54211/1 Integrationspflichtzeile fehlt.54226/1 EingabenameNULL/nicht#/##;54226/2 fehlende oder nicht passende Zweispaltentemp;54226/3 nach Kopie>1000 oder nichtpositive Generation;54226/4 fehlende exakte Registration;54226/5 nach Snapshot>100000 Reservations. Duplikate ergeben private PK-Enginefehler, keinen eigenen Duplikatstatus.54222/4 negativer privater Gate-AppLock-Rückgabecode. SET LOCK_TIMEOUT0 kann ursprünglichen1222 erzeugen; gesamter eigener TX wird im äußeren CATCH zurückgerollt, kein partieller PASS. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
