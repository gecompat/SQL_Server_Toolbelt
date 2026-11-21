---
name: "toolbelt-toolbelt-toolbelt-core-usp-configuresecondsess-1d3283c6"
description: "Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_ConfigureSecondSessionLoopback"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@LinkedServerName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an."}, {"name": "@Enabled", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql", "Modules/toolbelt.core.second-session/Source/SecondSessionProvider.sql", "Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql", "Modules/toolbelt.core.second-session/Source/USP_SecondSessionProbe.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# USP_ConfigureSecondSessionLoopback

## Zweck und Einsatzfälle

Bindet einen vorhandenen administrativ vorbereiteten Linked Server als Loopback-Provider und prüft dessen sichtbare Flags sowie eine synchrone Probe. Erstellt/ändert keinen Linked Server, Provider oder Loginmapping.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Vorhandener sichtbarer is_linked=1-Eintrag in master.sys.servers, RPC OUT=1, Remote-Proc-Transaction-Promotion=0. Remote-Ziel muss unter DB_NAME() den kanonischen USP_SecondSessionProbe mit passenden Rechten erreichen. Probe gilt auch für Enabled=0 und vor der Providerzeilenänderung. Name und SQL-Typ sind kein Connection String; QUOTENAME schützt die dynamischen Objektidentifier. Datenbankname/SPID der Probe sind Rückgabedaten, kein kryptografischer Nachweis derselben physischen SQLinstanz; das tatsächliche Loopbackziel ist administrativ festzulegen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an. |
| `@Enabled` | `bit` | `1` | Input | Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults. |

## Ergebnisse

Unterstütztes ResultTable-Zielschema:

| Feld | Typ/NULL/Collation |
|---|---|
| `ProviderName` | `varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `LinkedServerName` | `sysname NOT NULL` |
| `IsEnabled` | `bit NOT NULL` |
| `RowVersion` | `binary(8) NOT NULL` |
| `LinkedServerExists` | `bit NOT NULL` |
| `RpcOutEnabled` | `bit NOT NULL` |
| `RemoteProcTransactionPromotionEnabled` | `bit NOT NULL` |
| `ProbeRemoteSessionId` | `int NOT NULL` |
| `ProbeDatabaseName` | `sysname NOT NULL` |

Direkter SELECT verwendet Ausdrücke und Variablen; physische Nullable-/Collation-Metadaten können vom festen Temp-Zielschema abweichen. Kein ORDER-BY-Vertrag für die Einzelzeile. Bei ResultTable=NULL direktes Ergebnis, sonst vorhandene caller-lokale #Temp über sameDB USP_PrepareResultTable (KeepData=0 ersetzt,1 hängt kompatibel an,NULL=>0). RETURN 0; keine OUTPUT-Parameter. Hilfe liefert zuerst die vorhandene zwölfspaltige Standardhilfe und genau eine zusätzliche vollständige Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); danach RETURN 0 vor fachlichen Prüfungen, Katalog-/Kontextlesen, RPC oder Mutation. SQL-Typbindung und ausdrücklich genannte lokale Initialisierung bleiben erhalten. Ausgegeben werden gespeicherter Provider/Enabled/RowVersion und Flags/DBname/SPID der vorherigen Probe. Kein stabiler Snapshot des späteren Verbindungszustands und kein TLS-/Treiber-/Authentifizierungszertifikat.

## Aufrufbeispiele

```sql
-- Vorhandener administrativ korrekter synthetischer Loopback vorausgesetzt.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'ContosoLoopback',@Enabled=1;
-- Führt Probe-RPC aus und kann Konfigurationsdaten ändern.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser administrativen Konfigurations-USP und funktionierende bestehende Katalog-/Ownershiprechte. Sichtbarkeit von master.sys.servers und gültige Linked-Server-Anmeldung sowie Remote-EXECUTE auf USP_SecondSessionProbe nötig. Kein automatisches Serverrecht oder Loginmapping. Ergebnisrouting benötigt zusätzlich vorhandene Helper-/Temp-Rechte; keine allgemeine CONTROL-Prüfung in dieser Prozedur.

## Ressourcenbedarf

Ein synchroner RPC-Probeaufruf vor Transaktionsänderung und eine einzelne Providerzeile unter UPDLOCK,HOLDLOCK, danach gegebenenfalls Temp-/Helperarbeit. Kein eigener Probe-/Lock-/CPU-/Heap-/Wallclocktimeout. Sperren der lokalen Konfigurationszeile können bis zu einem bestehenden Callercommit bleiben; keine Streaming- oder Kapazitätszusage.

## Nebenwirkungen

SET NOCOUNT ON,XACT_ABORT OFF; Enabled=NULL=>1,KeepData/Debug/Hilfe NULL=>0. Probe kommt auch bei Deaktivierung und identischer Konfiguration vor der lokalen Transaktion. Eigener BEGIN/COMMIT oder Caller-Savepoint TBX_SecondSession_Config; vorhandene RowVersion optional prüfen, Neuanlage ignoriert ExpectedRowVersion als Existenzfence. Insert ProviderName=loopback und Audit von SYSUTCDATETIME/ORIGINAL_LOGIN. Nur abweichender LinkedServerName oder Enabled führt zum Update/Modified-Audit; Namevergleich der lokalen Variablen behält DBcollation/SQL-Padding. Keine automatische Reparatur anderer Providerzustände. Eigener Fehler-Rollback oder Caller-Savepoint nur bei XACT_STATE=1, kein vollständiger Callercommit/-rollback; BEGIN/SAVE vor TRY, Rollbackfehler nicht separat geschützt. Wichtig: eigener Konfigurations-COMMIT liegt VOR Ergebnistemp/Routing. Späterer Output-/Helperfehler kann bereits persistente Konfiguration hinterlassen. Debugmessage nur am Ende des ResultTable-Pfads; direkter SELECT kehrt vorher zurück. Keine Serveroption, Rechte- oder Truständerung.

## Fehlerbehandlung

51600 uncommittable Caller vor allen übrigen Fachprüfungen; 51601 Name fehlt/QUOTENAME ungültig;51602 Linked Server fehlt/unsichtbar;51603 RPC OUT aus;51604 Promotion an; RPC-Engine-/Loginfehler bleiben original;51605 Probe-Returncode NULL/nicht0;51606 abweichender zurückgegebener DBname;51607 SPID NULL oder gleich lokaler @@SPID;51608 vorhandene RowVersionabweichung;51609 Routinghelper fehlt nach Konfigurationsarbeit. DBnameprüfung ist SQL-Textungleichheit, keine generelle NOT-NULL-/Endpoint-Identitätsprüfung gegen manipulierte Probeobjekte. Kanonischer Probe liefert die tatsächlichen Werte.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Skill-/Caller-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. IDs/Actor/Tenant und Quellnamen sind Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Ein Katalogeintrag/Probe/Returncode ist kein universeller Exactly-once-/Serveridentitäts-/Gesundheitsnachweis; reale Metadaten privat behandeln.
