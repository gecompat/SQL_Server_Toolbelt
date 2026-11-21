---
name: "toolbelt-toolbelt-toolbelt-core-usp-setworktypepermission"
description: "Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkTypePermission"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@Principal", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig."}, {"name": "@PermissionName", "sql_type": "varchar(32)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig."}, {"name": "@PermissionState", "sql_type": "varchar(8)", "sql_default": "'ALLOW'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Parametervalidierung/CONTROL-/Katalogprüfung oder Policyänderung. 0 oder NULL führt den Fachpfad aus. Alle Argumente besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_SetWorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# USP_SetWorkTypePermission

## Zweck und Einsatzfälle

Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen.

## Voraussetzungen

SQL Server 2019/2022/2025 auf Windows/Linux, passende CL150/160/170, lokal/zentral. WorkType-Katalog und Policyobjekte in derselben Datenbank; zentrale Verwendung wertet den tatsächlichen DBtoken dieses Katalogs aus. Kein Second-Session- oder Queue-Provider für diese lokale Policyverwaltung/-entscheidung erforderlich. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen. Principal muss im lokalen sys.database_principals sichtbar sein, type in S/U/G/R/E/X und principal_id ungleich 0; keine Erstellung fehlender Identitäten. Work Type muss registriert sein, nicht zwingend enabled. Auch REMOVE setzt vorhandenen Principal und Work Type voraus und ist kein allgemeiner Bereiniger verwaister Zeilen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@Principal` | `sysname` | `NULL` | Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig. |
| `@PermissionName` | `varchar(32)` | `NULL` | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig. |
| `@PermissionState` | `varchar(8)` | `'ALLOW'` | Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1 liefert bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Parametervalidierung/CONTROL-/Katalogprüfung oder Policyänderung. 0 oder NULL führt den Fachpfad aus. Alle Argumente besitzen technische Defaults. |

## Ergebnisse

Kein fachlicher SELECT-Resultset und keine OUTPUT-Parameter. RETURN 0 bei Erfolg. @Hilfe=1: zuerst bestehende zwölfspaltige Standardhilfe, dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); vor Fach-/Rechte-/Katalogprüfung. ALLOW/DENY ersetzen die einzelne Zuordnung mit frischer Identitäts-/Versionsbindung; REMOVE löscht sie. Kein SQL-GRANT/-REVOKE und keine Ausgabe einer effektiv für alle Tokens berechneten Rechteliste.

## Aufrufbeispiele

```sql
-- Bestehender synthetischer Work Type und DBprincipal sind Voraussetzung.
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='contoso.noop',@Principal=N'ContosoProducer',@PermissionName='ENQUEUE',@PermissionState='ALLOW';
-- Persistente App-Delegation, nur im autorisierten Verwaltungsscope.
EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf der USP plus ausdrückliches CONTROL auf toolbelt_core.WorkTypePermission, geprüft durch HAS_PERMS_BY_NAME im aktuellen Principal-Kontext. EXECUTE allein genügt nicht. Vorhandene Katalogsichtbarkeit und Objekt-/Ownershiprechte müssen funktionieren; Hilfe benötigt keine erfolgreiche fachliche CONTROL-Prüfung. Keine automatisch erteilten Server-/Datenbankrollen, SQL-GRANTs oder erweiterten Rechte. Gleichnamiger Login in einer anderen Datenbank ersetzt kein gültiges DBprincipal-Mapping.

## Ressourcenbedarf

Eine Zeile je Aufruf wird nach Principalauflösung unter UPDLOCK,HOLDLOCK auf dem WorkType gelöscht und bei ALLOW/DENY neu eingefügt. Sperren können in einer Callertransaktion bis zu deren Ende bleiben; kein eigener Lock-/Wallclocktimeout in diesem Kern. Keine feste CPU-/Heap-/Grant-/Latenz- oder Parallelitätszusage.

## Nebenwirkungen

SET NOCOUNT ON, SET XACT_ABORT OFF. Nach Validierung CONTROL und committable Zustand prüfen, dann Principal auflösen. Ohne Callertransaktion eigener BEGIN/COMMIT, sonst fester Savepoint TBX_WorkType_Permission. Unter Elternzeilensperre alte einzelne Policy löschen; bei ALLOW/DENY aktuelle SID/create_date/WorkType-RowVersion und IsDenied neu einfügen. Parent wird dabei nicht aktualisiert. REMOVE fügt nichts ein. Eigener Fehler-Rollback bzw. Caller-Savepoint nur bei XACT_STATE=1, niemals vollständiger Callercommit/-rollback. BEGIN/SAVE liegt vor TRY; Rollbackfehler werden nicht separat geschützt. Debug>0/NULL=>0: nach Erfolg abstrakte Severity-10-NOWAIT-Meldung ohne Principal-/Policyinhalte. Hilfe kehrt vor allen Fachprüfungen zurück.

## Fehlerbehandlung

51590 NULL-Pflichtwerte/ungültige Aktion oder State; 51591 fehlendes CONTROL; 51594 uncommittable Caller; 51592 Principal fehlt/ungeeigneter Typ/ID0; 51593 Work Type fehlt, in dieser tatsächlichen Prüfpriorität. Leerer WorkType-/Principalname kann erst beim Kataloglookup scheitern, nicht automatisch 51590. Parameterwerte werden nicht generell normalisiert; SQL-Padding bleibt bei BIN2-Gleichheit wirksam. Unerwartete Engine-/Sperr-/Savepointfehler bleiben erhalten.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Policy-/Minimalrechte-/Skill-/Installerabnahme. Historische Belege behalten ihre ursprüngliche Bindung. App-Delegation ist kein SQL-GRANT und ersetzt keine Objekt-/Datenbank-/Handlerrechte. Keine SQL-Server-Rollenanlage, Identitätsumschaltung, Tenant-Isolation oder pauschale Rechteattestation.
