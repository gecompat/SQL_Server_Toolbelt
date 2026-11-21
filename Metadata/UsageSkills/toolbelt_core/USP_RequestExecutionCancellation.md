---
name: "toolbelt-toolbelt-toolbelt-core-usp-requestexecutioncancellation"
description: "Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-cancel"
schema_name: "toolbelt_core"
object_name: "USP_RequestExecutionCancellation"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL."}, {"name": "@CancellationReason", "sql_type": "nvarchar(512)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Transaktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults."}]
source_paths: ["Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql", "Modules/toolbelt.core.execution-cancel/Source/ExecutionCancellation.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_RequestExecutionCancellation

## Zweck und Einsatzfälle

Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL. |
| `@CancellationReason` | `nvarchar(512)` | `NULL` | Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Transaktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults. |

## Ergebnisse

Keine fachlichen Resultsets und keine OUTPUT-Parameter. RETURN 0 auch bei idempotentem No-op. Anschließend Status über TVF lesen. @Hilfe=1 liefert zuerst zwölfspaltige Standardhilfe und danach genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
DECLARE @Id uniqueidentifier=NEWID();
EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id,@CancellationReason=N'Synthetic checkpoint';
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(@Id);
EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
-- Nur Testidentität in autorisiertem Scope; die Anforderung persistiert.
```

## Rechte

Vorhandenes EXECUTE auf dieser öffentlichen Request-USP und funktionierende bestehende Objekt-/Ownershiprechte auf Tabelle und Kontextfunktion. Sichtbarkeit der eigenen Zeile in sys.database_principals und Berechtigung zum transaktionsgebundenen public-AppLock müssen bestehen; keine automatische Rechtevergabe. Zentrale Nutzung erfordert gültige Datenbankauthentifizierung/Mapping und passende Rechte im Toolbelt-Ziel; ein Dreiteilname allein erteilt diese nicht. Keine Serverrollen oder Identitätsumschaltung durch diese Objekte.

## Ressourcenbedarf

Kurze eigene Transaktion mit exklusivem DBweitem AppLock bis Commit/Rollback. Quoten zählen Gesamtzeilen und aktuellen Requester; keine Volltabellen-Löschung. Wartende Anforderer können bis zum AppLocktimeout blockieren. Neue IDs: höchstens 100000 Tabellenzeilen insgesamt und 10000 je exaktem Tupel des tatsächlichen DBprincipals (ID/SID/create_date). Ein transaktionsgebundener exklusiver AppLock im public-Kontext serialisiert Quotenprüfung und Insert, Timeout 10000 ms; eine bereits vorhandene ExecutionId ist vor Quotenprüfung ein No-op. Kein automatisches Löschen abgelaufener Anforderungen. Direktes privilegiertes DML wird durch diese Anwendungsquoten nicht als Tabellenconstraint verhindert. Keine feste CPU-/Heap-/Durchsatz-/Latenzgarantie.

## Nebenwirkungen

SET NOCOUNT ON, SET XACT_ABORT ON, Debug/Hilfe NULL nach 0. Fachaufruf verbietet jede aktive Callertransaktion. Eigene Transaktion umfasst AppLock, Existenz-/Quotenprüfung und gegebenenfalls einmaliges Insert. Bei Fehler Rollback falls XACT_STATE ungleich 0; Rollbackfehler werden nicht separat geschützt. Wiederholte ID ändert weder Timestamp, Grund, Identitäten noch RowVersion. Debug>0: abstrakte Severity-10-NOWAIT-Meldung mit neu=0/1, keine ID oder Audittexte. Hilfe kehrt vor Kontextfunktion/Katalog/Tabelle/Transaktion zurück. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.

## Fehlerbehandlung

52600 aktive Callertransaktion; 52601 explizite/aktuelle ID fehlt; 52602 Null-GUID; 52604 DBprincipal-SID/create_date nicht bindbar; 52603 negativer AppLock-Rückgabewert; 52605 Gesamtquote; 52606 Principalquote. Prüfung in dieser tatsächlichen Reihenfolge, Quoten nur für neue IDs und zuerst Gesamtquote. Technische Engine-/Kontext-/Berechtigungsfehler bleiben erhalten; keine pauschale Erfolgsmaskierung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechteabnahme. Historische Fach-/Repeat-/Quotenbelege behalten ihre ursprüngliche Bindung. Keine Installations-/Rechteattestation, kein Echtzeit-/Unterbrechungsversprechen. Eine ExecutionId ist kein Authentifizierungsgeheimnis und diese APIs prüfen keine fachliche Eigentümerschaft einer ID. Kontextwerte sind keine Sicherheitsgrenze.
