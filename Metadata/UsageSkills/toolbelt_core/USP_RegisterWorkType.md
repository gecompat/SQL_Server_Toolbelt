---
name: "toolbelt-toolbelt-toolbelt-core-usp-registerworktype"
description: "Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_RegisterWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Erforderlicher kanonischer varchar(128)-Schlüssel: LEN 3..128, beginnt a-z, danach ausschließlich a-z/0-9/Punkt/Unterstrich/Bindestrich. Lowercase wird verlangt, nicht hergestellt; keine abschließenden oder doppelten Punkte. Z.B. app.import.rows. NULL/leer ungültig; bestehende Registrierung folgt AllowUpdate/Reactivate/RowVersion."}, {"name": "@HandlerSchema", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Einzelner unquotierter Schemaname als sysname in der aktuellen Datenbank, nicht mehrteilig und kein SQL-Ausdruck. NULL/leer oder Schema sys ist unzulässig. Mit HandlerProcedure muss eine vorhandene, nicht von Microsoft ausgelieferte T-SQL- oder CLR-Procedure entstehen; Caller benötigt EXECUTE."}, {"name": "@HandlerProcedure", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Einzelner unquotierter Procedurename als sysname in HandlerSchema; keine Argumentliste oder Datenbankqualifikation. NULL/leer/fehlende Procedure bzw. fehlende Metadatensicht/EXECUTE wird abgewiesen. Registrierung führt den Handler nicht aus; der Dispatcher prüft den zum ParameterMode gehörenden Aufrufvertrag."}, {"name": "@ParameterMode", "sql_type": "varchar(16)", "sql_default": "'NONE'", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ nach UPPER-Normalisierung: NONE = Handleraufruf ohne Payload, PayloadContractJson muss NULL sein (Default und NULL); JSON_PAYLOAD = JSON-Payload-Modus, PayloadContractJson muss ein JSON-Objekt sein. Keine weiteren Modi; SQL-Space-Padding gilt beim Vergleich."}, {"name": "@PayloadContractJson", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei NONE ausschließlich NULL. Bei JSON_PAYLOAD erforderlicher JSON-Objekttext als nvarchar(4000), z.B. N'{\"description\":\"synthetic payload\"}'; nach LTRIM normaler Spaces muss { folgen. Leer/Array/Scalar/ungültiges JSON ist ungültig. Die Felder sind deklarative Metadaten; diese Procedure führt weder SQL noch eine allgemeine JSON-Schema-Validierung daraus aus."}, {"name": "@DefaultTimeoutSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl 1..86400 Sekunden einschließlich; Default/NULL=300. Wird als Work-Type-Metadatum gespeichert, nicht als Garantie eines autonomen harten Serverabbruchs. Andere Werte ungültig."}, {"name": "@IsIdempotent", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 = Handler nicht als idempotent gekennzeichnet (Default/NULL); 1 = deklarativ idempotent gekennzeichnet. Das Flag implementiert selbst keine Idempotenz oder Exactly-once-Ausführung."}, {"name": "@Description", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(1000), NULL/leer erlaubt; keine besonderen Felder, keine Ausführung, keine automatische Redigierung."}, {"name": "@AllowUpdate", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 weist eine abweichende vorhandene Konfiguration ab (Default/NULL); 1 erlaubt deren Update. Ein identischer aktiver Eintrag bleibt auch mit 0 idempotent. Für die Reaktivierung eines deaktivierten Eintrags zusätzlich Reactivate beachten."}, {"name": "@Reactivate", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 lässt eine deaktivierte Registrierung nicht still reaktivieren (Default/NULL); 1 erlaubt ihre Reaktivierung. Bei gleichzeitig abweichender Konfiguration ist außerdem AllowUpdate=1 erforderlich."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Wird nur gegen einen vorhandenen Work Type geprüft; kein Eingabewert für die neue RowVersion."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile vor Fach-/Handler-/Katalogprüfung oder Änderungen. Danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_RegisterWorkType.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# USP_RegisterWorkType

## Zweck und Einsatzfälle

Registriert eine bereits vorhandene T-SQL-/CLR-Prozedur als benannten Work Type oder aktualisiert/reaktiviert dessen Katalogzeile mit ausdrücklichen Schaltern. Kein freier ausführbarer SQL-Text, keine Handlererstellung oder -ausführung.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. WorkType und VW_WorkTypes in derselben Datenbank, sichtbare vorhandene Handlerprozedur P/PC in dieser Datenbank, nicht sys oder is_ms_shipped. Vorhandenes Handler-EXECUTE des registrierenden Principals erforderlich. Für Routing zusätzlich existierender sameDB ResultTable-Helper und gültige lokale Caller-Temp. ParameterMode ist eine Deklaration: diese Prozedur prüft NICHT die passende Handler-Parametersignatur; der spätere Dispatcher prüft diese separat. NONE ohne Payloadvertrag; JSON_PAYLOAD verlangt ein JSON-Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces, kein ausführbares JSON-Schema.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Erforderlicher kanonischer varchar(128)-Schlüssel: LEN 3..128, beginnt a-z, danach ausschließlich a-z/0-9/Punkt/Unterstrich/Bindestrich. Lowercase wird verlangt, nicht hergestellt; keine abschließenden oder doppelten Punkte. Z.B. app.import.rows. NULL/leer ungültig; bestehende Registrierung folgt AllowUpdate/Reactivate/RowVersion. |
| `@HandlerSchema` | `sysname` | `NULL` | Einzelner unquotierter Schemaname als sysname in der aktuellen Datenbank, nicht mehrteilig und kein SQL-Ausdruck. NULL/leer oder Schema sys ist unzulässig. Mit HandlerProcedure muss eine vorhandene, nicht von Microsoft ausgelieferte T-SQL- oder CLR-Procedure entstehen; Caller benötigt EXECUTE. |
| `@HandlerProcedure` | `sysname` | `NULL` | Einzelner unquotierter Procedurename als sysname in HandlerSchema; keine Argumentliste oder Datenbankqualifikation. NULL/leer/fehlende Procedure bzw. fehlende Metadatensicht/EXECUTE wird abgewiesen. Registrierung führt den Handler nicht aus; der Dispatcher prüft den zum ParameterMode gehörenden Aufrufvertrag. |
| `@ParameterMode` | `varchar(16)` | `'NONE'` | Taxativ nach UPPER-Normalisierung: NONE = Handleraufruf ohne Payload, PayloadContractJson muss NULL sein (Default und NULL); JSON_PAYLOAD = JSON-Payload-Modus, PayloadContractJson muss ein JSON-Objekt sein. Keine weiteren Modi; SQL-Space-Padding gilt beim Vergleich. |
| `@PayloadContractJson` | `nvarchar(4000)` | `NULL` | Bei NONE ausschließlich NULL. Bei JSON_PAYLOAD erforderlicher JSON-Objekttext als nvarchar(4000), z.B. N'{"description":"synthetic payload"}'; nach LTRIM normaler Spaces muss { folgen. Leer/Array/Scalar/ungültiges JSON ist ungültig. Die Felder sind deklarative Metadaten; diese Procedure führt weder SQL noch eine allgemeine JSON-Schema-Validierung daraus aus. |
| `@DefaultTimeoutSeconds` | `int` | `300` | Ganzzahl 1..86400 Sekunden einschließlich; Default/NULL=300. Wird als Work-Type-Metadatum gespeichert, nicht als Garantie eines autonomen harten Serverabbruchs. Andere Werte ungültig. |
| `@IsIdempotent` | `bit` | `0` | Taxativ für bit: 0 = Handler nicht als idempotent gekennzeichnet (Default/NULL); 1 = deklarativ idempotent gekennzeichnet. Das Flag implementiert selbst keine Idempotenz oder Exactly-once-Ausführung. |
| `@Description` | `nvarchar(1000)` | `NULL` | Optionaler Unicode-Freitext nvarchar(1000), NULL/leer erlaubt; keine besonderen Felder, keine Ausführung, keine automatische Redigierung. |
| `@AllowUpdate` | `bit` | `0` | Taxativ für bit: 0 weist eine abweichende vorhandene Konfiguration ab (Default/NULL); 1 erlaubt deren Update. Ein identischer aktiver Eintrag bleibt auch mit 0 idempotent. Für die Reaktivierung eines deaktivierten Eintrags zusätzlich Reactivate beachten. |
| `@Reactivate` | `bit` | `0` | Taxativ für bit: 0 lässt eine deaktivierte Registrierung nicht still reaktivieren (Default/NULL); 1 erlaubt ihre Reaktivierung. Bei gleichzeitig abweichender Konfiguration ist außerdem AllowUpdate=1 erforderlich. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Wird nur gegen einen vorhandenen Work Type geprüft; kein Eingabewert für die neue RowVersion. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1: bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile vor Fach-/Handler-/Katalogprüfung oder Änderungen. Danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |

## Ergebnisse

| Ergebnisfeld | Typ/NULL/Collation |
|---|---|
| `WorkTypeId` | `bigint NOT NULL` |
| `WorkTypeName` | `varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `HandlerSchema` | `sysname NOT NULL` |
| `HandlerProcedure` | `sysname NOT NULL` |
| `HandlerQualifiedName` | `nvarchar(517) NOT NULL` |
| `ParameterMode` | `varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `PayloadContractJson` | `nvarchar(4000) NULL` |
| `DefaultTimeoutSeconds` | `int NOT NULL` |
| `IsIdempotent` | `bit NOT NULL` |
| `IsEnabled` | `bit NOT NULL` |
| `Description` | `nvarchar(1000) NULL` |
| `CreatedAtUtc` | `datetime2(7) NOT NULL` |
| `CreatedBy` | `sysname NOT NULL` |
| `ModifiedAtUtc` | `datetime2(7) NOT NULL` |
| `ModifiedBy` | `sysname NOT NULL` |
| `DisabledAtUtc` | `datetime2(7) NULL` |
| `DisabledBy` | `sysname NULL` |
| `DisabledReason` | `nvarchar(1000) NULL` |
| `RowVersion` | `binary(8) NOT NULL` |
| `HandlerExists` | `bit NOT NULL` |

Genau eine Katalogzeile nach erfolgreicher Registrierung/Update/No-op. HandlerQualifiedName ist QUOTENAME(Schema)+Punkt+QUOTENAME(Procedure); HandlerExists nur sichtbares OBJECT_ID P/PC. Bei ResultTable=NULL direkter SELECT ohne Reihenfolgegarantie, sonst Routing in vorhandene caller-lokale #Temp über sameDB USP_PrepareResultTable; KeepData=0 ersetzt,1 hängt kompatibel an,NULL=>0. RETURN 0, keine OUTPUT-Parameter. Hilfe: zuerst zwölfspaltige Standardhilfe, zusätzlich genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), dann früher RETURN 0. Keine Ausgabe eines Changed-Flags als Fachspalte; dieses erscheint nur in optionaler Debugmessage.

## Aufrufbeispiele

```sql
-- Vorhandener synthetischer Handler dbo.ContosoNoop ohne Parameter vorausgesetzt.
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='contoso.noop',@HandlerSchema=N'dbo',@HandlerProcedure=N'ContosoNoop',@ParameterMode='NONE';
-- Ändert den Katalog im autorisierten Verwaltungsscope; kein Handleraufruf.
EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Verwaltungs-USP, gültige bestehende Katalog-/Ownershiprechte und sichtbare Objektmetadaten. Der aktuelle Principal muss nach HAS_PERMS_BY_NAME EXECUTE auf dem Zielhandler haben. Kein zusätzlicher CONTROL-Check auf WorkTypePermission wie bei SetPermission; Registrierung erteilt aber weder SQL-Objektrechte noch ENQUEUE/CLAIM/EXECUTE_NEW_SESSION-Policies. Zentrale Aufrufe benötigen gültige Ziel-DB-Authentifizierung/Mapping. Kein automatisches Grant, Loginmapping, Rollenwechsel oder Provider-Setup.

## Ressourcenbedarf

Einzelner PK-/Namenskatalogeintrag, zwei private feste Temp-Ergebnistabellen mit 20 Spalten, unter UPDLOCK,HOLDLOCK Katalogsuche/Insert/Update. Sperren können bei Callertransaktion bis zu deren Ende bestehen; kein eigener Lock-/Wallclock-/CPU-/Heapdeckel. WorkTypeName varchar(128), PayloadContractJson nvarchar(4000), Description nvarchar(1000) nach SQL-Parameterbindung; keine separate Raw-LOB-Längenzulassung. DefaultTimeoutSeconds 1..86400 ist nur Metadatum und implementiert hier keinen harten Abbruch, IsIdempotent keine Deduplikation/Exactly-once-Ausführung. Keine allgemeine JSON-Schema-Validierung oder automatische Retention.

## Nebenwirkungen

SET NOCOUNT ON, XACT_ABORT OFF; vor Hilfe ParameterMode=UPPER(COALESCE(...,NONE)), Timeout=NULL=>300, IsIdempotent/AllowUpdate/Reactivate/KeepData/Debug/Hilfe NULL=>0. Neue Registrierung IsEnabled=1, Auditzeit SYSUTCDATETIME und Auditprincipal ORIGINAL_LOGIN. Bestehender Eintrag: optional ExpectedRowVersion prüfen; abweichende Konfiguration verlangt AllowUpdate=1, deaktivierter Eintrag Reactivate=1. Beide Grenzen gelten unabhängig. Vergleich erfolgt mit SQL-Textgleichheit der beteiligten Variablen/DBcollation und ISNULL(Text,N''): kein JSON-Struktur- oder garantiert bytegenauer Textvergleich. Groß-/Kleinschreibung, trailing Spaces und NULL/leer können je Feld als gleich gelten. Aktiver so gleicher Eintrag bleibt unverändert, inklusive RowVersion. Tatsächliches Update/Reaktivierung setzt Enabled=1, ersetzt Konfiguration/Modified-Audit und löscht Disabled-Audit; neue RowVersion macht alte gebundene App-Policies unwirksam. Es entstehen keine neuen Policyzeilen. ExpectedRowVersion ist bei Neuanlage kein Existenzfence und wird dort nicht verglichen. Ohne Callertransaktion eigener BEGIN/COMMIT um Katalogarbeit, sonst Savepoint TBX_WorkType_Register. Eigener Rollback bzw. Caller-Savepoint nur bei committable Zustand, kein vollständiger Callercommit/-rollback; BEGIN/SAVE vor TRY und Rollbackfehler nicht separat geschützt. Wichtig: eigener Katalog-COMMIT liegt VOR ResultTable-Helperprüfung/Routing. Ein späterer Routingfehler kann bereits persistente Registrierung/Änderung hinterlassen; kein pauschales atomisches Gesamt-Routingversprechen. Debug>0: abstrakte Severity-10-NOWAIT-Message mit Änderung=0/1, ohne freie Texte. Hilfe kehrt vor Fach-/Temp-/Katalogoperationen zurück.

## Fehlerbehandlung

Prüfpriorität: 51500 Name nicht lowercase ASCII/LEN3..128/erster Buchstabe a..z/unerlaubte Zeichen/abschließende oder doppelte Punkte; 51501 Handlernamen fehlen; 51502 Schema sys; 51503 ParameterMode; 51504 Payloadvertrag bei NONE; 51505 fehlendes/ungültiges JSON-Objekt bei JSON_PAYLOAD; 51506 Timeout außerhalb1..86400; 51507 Handler fehlt/unsichtbar; 51508 is_ms_shipped; 51509 Handler-EXECUTE fehlt. Unter Katalogsperre bei bestehendem Eintrag: 51510 RowVersionabweichung,51511 Update nicht erlaubt,51512 Reaktivierung nicht erlaubt. 51518 fehlender Routinghelper erst nach Katalogarbeit, gegebenenfalls eigenem Commit. Kein eigener dedizierter Geschäfts-THROW für uncommittable Caller; technische Temp-/Transaktions-/Berechtigungs-/Constraintfehler bleiben erhalten. Keine automatische Kompensation einer bereits committed Registrierung wegen späterem Outputfehler.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechte-/Recoveryabnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. Katalogzeile/HandlerExists/IsIdempotent/Payloadvertrag garantieren weder funktionierenden Handler noch sichere Payload, Providerbereitschaft, effektive App-Policy oder genau eine Ausführung. Auditnamen und freie Texte sind keine Sicherheitsgrenze; tatsächliche Ausgaben privat behandeln. Beschreibung bestätigt weder Installation noch Callerrechte.
