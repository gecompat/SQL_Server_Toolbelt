---
name: "toolbelt-toolbelt-toolbelt-core-usp-removeworktype"
description: "Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_RemoveWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss bereits deaktiviert sein; aktive Einträge sind nicht entfernbar."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen."}, {"name": "@AllowDelete", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Taxativ für bit: 1 ist die ausdrückliche Zustimmung zum irreversiblen Entfernen; 0 (Default) und NULL werden vor der Entfernung abgewiesen. Der Work Type muss zusätzlich deaktiviert sein."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_RemoveWorkType.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# USP_RemoveWorkType

## Zweck und Einsatzfälle

Entfernt ausschließlich einen bereits deaktivierten Katalogeintrag mit ausdrücklichem AllowDelete=1; löscht nicht die Handlerprozedur und führt sie nicht aus.

## Voraussetzungen

WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. ExpectedRowVersion NULL deaktiviert nur den optimistischen Versionsvergleich; sonst exakte binary(8)-Bytes aus zuletzt gelesenem Katalog verwenden, keinen Hextext. Aktive Einträge können nicht entfernt werden. Bestehende Referenzen können den DELETE durch Engine-/FK-Fehler verhindern; kein automatisches Entfernen von Workitems oder anderen Verbrauchern.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss bereits deaktiviert sein; aktive Einträge sind nicht entfernbar. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
| `@AllowDelete` | `bit` | `0` | Taxativ für bit: 1 ist die ausdrückliche Zustimmung zum irreversiblen Entfernen; 0 (Default) und NULL werden vor der Entfernung abgewiesen. Der Work Type muss zusätzlich deaktiviert sein. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
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

Genau eine Katalogzeile bei erfolgreichem Fachaufruf, keine Zeilenreihenfolgegarantie. Snapshot VOR Entfernung, keine Bestätigung, dass der Katalogeintrag danach noch besteht. HandlerQualifiedName ist QUOTENAME(Schema)+Punkt+QUOTENAME(Procedure); HandlerExists beruht auf sichtbarem OBJECT_ID vom Typ P oder PC, nicht auf erfolgreicher Ausführung. PayloadContractJson ist deklarative Metadatenbeschreibung, Timeout und IsIdempotent sind kein in dieser Prozedur durchgesetzter Laufzeit-/Duplikatschutz. Bei ResultTable=NULL SELECT, sonst Routing in caller-lokale bereits bestehende #Temp über sameDB USP_PrepareResultTable; KeepData=0 ersetzt, 1 hängt kompatibel an, NULL=>0. RETURN 0, keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst Standardhilfe, dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='contoso.noop',@AllowDelete=1;
-- Nur bereits deaktivierter synthetischer Eintrag im autorisierten Scope.
EXEC toolbelt_core.USP_RemoveWorkType @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser öffentlichen Prozedur und gültige bestehende Objekt-/Ownershiprechte auf Katalog/View. Administrativer Anwendungseinstieg; diese Prozedur führt selbst keinen zusätzlichen CONTROL-Check wie USP_SetWorkTypePermission aus. Ausreichendes EXECUTE/Ownership kann daher Katalogänderung erlauben; Grant nicht pauschal an Lesekonsumenten vergeben. Routing benötigt bestehende Helper-/Temp-Rechte. Zentraler Name ersetzt weder DBmapping noch Rechte. Kein automatisches GRANT, Rollenwechsel oder Policy-ALLOW.

## Ressourcenbedarf

Begrenzte Einzelzeile aus dem WorkType-Katalog, zwei eigene feste Temp-Ergebnistabellen und bei Routing weitere Helperarbeit/Temp-DDL. Kein eigener globaler Lock-/Wallclock-/CPU-/Heap-/Grantdeckel. UPDLOCK,HOLDLOCK auf die ausgewählte Katalogzeile innerhalb eigener Transaktion bzw. Caller-Savepoint; Sperren können bis zu Callercommit bestehen. Die gesamte Operation ist kein Background- oder Warteschlangenjob.

## Nebenwirkungen

SET NOCOUNT ON, KeepData/Debug/Hilfe NULL=>0. SET XACT_ABORT OFF. Ohne Callertransaktion eigener BEGIN/COMMIT um Katalogarbeit, sonst fester Savepoint TBX_WorkType_Remove. Fehler: eigener Rollback oder Caller-Savepoint nur bei XACT_STATE=1, kein vollständiger Callercommit/-rollback. BEGIN/SAVE steht vor TRY, Rollbackfehler werden nicht separat geschützt. ResultTable-Aufbereitung und INSERT liegen INNERHALB desselben TRY-/Transaktionsscopes vor dem DELETE; eigene Fehler rollen den zugehörigen Scope zurück. DELETE kaskadiert WorkTypePermission-Zeilen über den bestehenden FK, andere Referenzen können blockieren. Handlerprozedur bleibt bestehen. Ein späterer Callerrollback kann die Entfernung zurücknehmen. Debug>0: abstrakte Severity-10-NOWAIT-Meldung ohne Kataloginhalte, kein zusätzlicher Resultset. Hilfe kehrt vor all diesen Fachoperationen zurück.

## Fehlerbehandlung

51523 Name fehlt; 51527 AllowDelete ungleich 1; 51528 uncommittable Caller; danach unter Sperre 51524 nicht registriert,51525 RowVersionabweichung,51526 noch aktiv. 51518 fehlender Routinghelper innerhalb des Entfernungsscopes. FK-/Berechtigungs-/Enginefehler bleiben erhalten. Unerwartete technische Fehler werden nicht zu erfolgreichem No-op maskiert. SQL-Textvergleiche behalten ihre Collation-/Paddingregeln; keine generelle bytegenaue Namen-/Grundnormalisierung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechte-/Recoveryabnahme. Historische Evidenz behält ihren ursprünglichen Scope. Katalog-Metadaten und HandlerExists sind kein Ausführungs-/Idempotenz-/Gesundheitsnachweis. Hilfe/Beschreibung bestätigen weder Installation noch vorhandene Callerrechte; reale Auditdaten und freie Gründe privat behandeln.
