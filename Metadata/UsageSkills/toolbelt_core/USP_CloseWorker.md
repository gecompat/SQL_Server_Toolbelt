---
name: "toolbelt-core-usp-closeworker"
description: "Schließt eine exakt token-/principalgebundene Generation ohne belegte Reservations."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_CloseWorker"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID."}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Belegte oder ungeklärte Reservations dieser Generation blockieren Close."}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_CloseWorker.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_CloseWorker

## Zweck und Einsatzfälle

Schließt eine exakt token-/principalgebundene Generation ohne belegte Reservations.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Belegte oder ungeklärte Reservations dieser Generation blockieren Close. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.

## Ergebnisse

Kein fachlicher Resultset, keine OUTPUT-Parameter und keine ResultTable-/KeepData-Option. RETURN0 nach erfolgreichem Close oder Hilfe.  Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_CloseWorker @Hilfe=1;

-- Synthetische Bindung durch die eigene tatsächliche Registrierung ersetzen:
DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
EXEC toolbelt_core.USP_CloseWorker @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. WorkerId/Generation/WorkerToken müssen zur Registration und aktuellem USER_ID passen. Kein administrativer Close beliebiger Generationen allein anhand sichtbarer IDs; keine zusätzliche Hostidentitätsattestation. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Globale Gate-, Scheduler-, Konfigurations- und Registrationssperren bis zum Transaktionsende. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor dem positiven Hilfezweig. Hilfe ignoriert Fachwerte, erzeugt keine fachlichen Mutationen oder eigenen Debugmessages und kehrt vor Ergebnistemp/Routing zurück. Eigene kurze Transaktion,UPDLOCK/HOLDLOCK Gate→Scheduler→globale Konfiguration, dann exakte Worker-/Token-/Principalbindung mit State<>CLOSED. Jede IsOccupied1-Reservation derselben WorkerId/Generation blockiert, unabhängig von State (auch UNKNOWN). Ohne belegte Slots nur Registration.State=CLOSED setzen. Keine Latest-/Heartbeatfrischeprüfung: auch eine ältere oder UNREACHABLE-Generation kann bei passender Autorität und leeren Slots geschlossen werden. Bereits CLOSED ist kein erfolgreicher No-op, sondern scheitert am Autoritätsfilter. Kein Löschen von Generation,Token,Reservations oder History; AdmissionPaused/Intervalle und globale ConfigVersion unverändert. Keine Claims beenden oder Slots freigeben. Ohne geworfenen Fehler RETURN0; dies beweist über die beschriebene Mutation hinaus keinen erfolgreich beendeten Handler. Technische Fehler nach Commit, bei Sessionlockrelease oder Ergebnistransport können eine bereits begangene Mutation nicht zurücknehmen.

## Fehlerbehandlung

54210/1 nichtneutraler Caller;54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag;54215/1 NULL oder keine passende nichtCLOSED-Worker-/Token-/Principalbindung;54216/1 IsOccupied1-Reservation dieser Generation. Technische Enginefehler bleiben sichtbar. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
