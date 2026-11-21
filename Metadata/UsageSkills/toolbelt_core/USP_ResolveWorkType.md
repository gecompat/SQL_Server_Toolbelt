---
name: "toolbelt-toolbelt-toolbelt-core-usp-resolveworktype"
description: "Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_ResolveWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@RequireEnabled", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren."}, {"name": "@RequireExecutableByCaller", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung."}, {"name": "@RequiredPermission", "sql_type": "varchar(32)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY."}, {"name": "@SuppressResult", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597)."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_ResolveWorkType.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# USP_ResolveWorkType

## Zweck und Einsatzfälle

Löst einen registrierten Work Type auf und prüft optionale App-Policy, Enabled-Zustand und Handlerrechte; kein Handleraufruf und keine Registrierung.

## Voraussetzungen

WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. RequireEnabled und RequireExecutableByCaller NULL=>1; RequiredPermission NULL bedeutet keine App-Policyprüfung. SuppressResult muss 0/1 sein, NULL oder 1 mit ResultTable wird abgewiesen. Ein deaktivierter Eintrag ist mit RequireEnabled=0 möglich; der Handler muss dennoch sichtbar existieren. RequireExecutableByCaller=0 überspringt nur dessen EXECUTE-Check, verleiht kein Recht.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@RequireEnabled` | `bit` | `1` | Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren. |
| `@RequireExecutableByCaller` | `bit` | `1` | Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung. |
| `@RequiredPermission` | `varchar(32)` | `NULL` | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY. |
| `@SuppressResult` | `bit` | `0` | Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597). |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |

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

Genau eine Katalogzeile bei erfolgreichem Fachaufruf, keine Zeilenreihenfolgegarantie. Aufgelöster Katalogsnapshot, kein Handleraufruf. Bei SuppressResult=1 kein fachlicher Resultset nach erfolgreich durchgeführten Prüfungen. HandlerQualifiedName ist QUOTENAME(Schema)+Punkt+QUOTENAME(Procedure); HandlerExists beruht auf sichtbarem OBJECT_ID vom Typ P oder PC, nicht auf erfolgreicher Ausführung. PayloadContractJson ist deklarative Metadatenbeschreibung, Timeout und IsIdempotent sind kein in dieser Prozedur durchgesetzter Laufzeit-/Duplikatschutz. Bei ResultTable=NULL SELECT, sonst Routing in caller-lokale bereits bestehende #Temp über sameDB USP_PrepareResultTable; KeepData=0 ersetzt, 1 hängt kompatibel an, NULL=>0. RETURN 0, keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst Standardhilfe, dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='contoso.noop',@RequiredPermission='EXECUTE_NEW_SESSION',@SuppressResult=1;
-- Nur Preflight; registrierter Handler, bestehende Rechte und Policy nötig.
EXEC toolbelt_core.USP_ResolveWorkType @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser öffentlichen Prozedur und gültige bestehende Objekt-/Ownershiprechte auf Katalog/View. Bei RequireExecutableByCaller=1 zusätzlich vorhandenes EXECUTE des aktuellen Principals auf den Handler; RequiredPermission verlangt separate gültige App-Policy im aktuellen DBtoken mit DENY-Vorrang. Sichtbarkeit für OBJECT_ID, HAS_PERMS_BY_NAME und Policykatalog ist erforderlich. Routing benötigt bestehende Helper-/Temp-Rechte. Zentraler Name ersetzt weder DBmapping noch Rechte. Kein automatisches GRANT, Rollenwechsel oder Policy-ALLOW.

## Ressourcenbedarf

Begrenzte Einzelzeile aus dem WorkType-Katalog, zwei eigene feste Temp-Ergebnistabellen und bei Routing weitere Helperarbeit/Temp-DDL. Kein eigener globaler Lock-/Wallclock-/CPU-/Heap-/Grantdeckel. Bei RequiredPermission wird die WorkType-Bindung mit HOLDLOCK gelesen; in bestehender Callertransaktion bleibt diese Sperre bis zu deren Abschluss, ohne Callertransaktion nur für das Statement. Kein transaktionsunabhängig stabiler Vorcheck bis zu späterer beliebiger Handlerausführung.

## Nebenwirkungen

SET NOCOUNT ON, KeepData/Debug/Hilfe NULL=>0. RequireEnabled/RequireExecutableByCaller NULL=>1. Keine Änderung des Katalogs und kein eigener BEGIN/COMMIT-Scope. Optionaler HOLDLOCK, Temp-Materialisierung und danach ResultTable-Helper/INSERT unter normalen Callertransaktionsregeln; kein eigener atomarer Wrapper um das Routing. Debug>0: abstrakte Severity-10-NOWAIT-Meldung ohne Kataloginhalte, kein zusätzlicher Resultset. Hilfe kehrt vor all diesen Fachoperationen zurück.

## Fehlerbehandlung

51595 unbekannte RequiredPermission; 51597 SuppressResult=NULL oder 1 mit ResultTable; 51596 fehlende gültige App-Policy; erst danach 51530 leerer WorkTypeName, 51531 nicht registriert, 51532 deaktiviert trotz RequireEnabled=1, 51533 Handler fehlt/unsichtbar, 51534 fehlendes Handler-EXECUTE. Bei gewählter Aktion kann auch fehlender Name/Eintrag zuerst 51596 ergeben. 51518 fehlender ResultTable-Helper erst nach Katalogprüfungen. Kein Erfolg bei fehlendem Handler allein durch Ausschalten des EXECUTE-Checks. Unerwartete technische Fehler werden nicht zu erfolgreichem No-op maskiert. SQL-Textvergleiche behalten ihre Collation-/Paddingregeln; keine generelle bytegenaue Namen-/Grundnormalisierung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechte-/Recoveryabnahme. Historische Evidenz behält ihren ursprünglichen Scope. Katalog-Metadaten und HandlerExists sind kein Ausführungs-/Idempotenz-/Gesundheitsnachweis. Hilfe/Beschreibung bestätigen weder Installation noch vorhandene Callerrechte; reale Auditdaten und freie Gründe privat behandeln.
