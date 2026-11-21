-- ============================================================================
-- Objekt: toolbelt_core.USP_SetWorkTypePermission; Typ: Stored Procedure
-- Zweck: Explizite Delegation pro Work Type, Datenbankprincipal und Aktion.
-- Vertrag: Documentation/USP_SetWorkTypePermission.md; kein Datenresultset.
-- Rechte: EXECUTE und CONTROL auf WorkTypePermission; keine Rechtevergabe.
-- Plattform: SQL Server 2019/2022/2025 Windows/Linux; lokaler Katalog.
-- Fehler: 51590-51594; Help ohne Seiteneffekt; Caller-Savepoint bei Mutation.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_SetWorkTypePermission
    @WorkTypeName varchar(128)=NULL,
    @Principal sysname=NULL,
    @PermissionName varchar(32)=NULL,
    @PermissionState varchar(8)='ALLOW',
    @Debug tinyint=0,
    @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-usp-setworktypepermission"
-- description: "Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-type"
-- schema_name: "toolbelt_core"
-- object_name: "USP_SetWorkTypePermission"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@Principal", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig."}, {"name": "@PermissionName", "sql_type": "varchar(32)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig."}, {"name": "@PermissionState", "sql_type": "varchar(8)", "sql_default": "'ALLOW'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Parametervalidierung/CONTROL-/Katalogprüfung oder Policyänderung. 0 oder NULL führt den Fachpfad aus. Alle Argumente besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.core.work-type/Source/USP_SetWorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- ---
--
-- # USP_SetWorkTypePermission
--
-- ## Zweck und Einsatzfälle
--
-- Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025 auf Windows/Linux, passende CL150/160/170, lokal/zentral. WorkType-Katalog und Policyobjekte in derselben Datenbank; zentrale Verwendung wertet den tatsächlichen DBtoken dieses Katalogs aus. Kein Second-Session- oder Queue-Provider für diese lokale Policyverwaltung/-entscheidung erforderlich. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen. Principal muss im lokalen sys.database_principals sichtbar sein, type in S/U/G/R/E/X und principal_id ungleich 0; keine Erstellung fehlender Identitäten. Work Type muss registriert sein, nicht zwingend enabled. Auch REMOVE setzt vorhandenen Principal und Work Type voraus und ist kein allgemeiner Bereiniger verwaister Zeilen.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@WorkTypeName` | `varchar(128)` | `NULL` | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
-- | `@Principal` | `sysname` | `NULL` | Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig. |
-- | `@PermissionName` | `varchar(32)` | `NULL` | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig. |
-- | `@PermissionState` | `varchar(8)` | `'ALLOW'` | Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | 1 liefert bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Parametervalidierung/CONTROL-/Katalogprüfung oder Policyänderung. 0 oder NULL führt den Fachpfad aus. Alle Argumente besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- Kein fachlicher SELECT-Resultset und keine OUTPUT-Parameter. RETURN 0 bei Erfolg. @Hilfe=1: zuerst bestehende zwölfspaltige Standardhilfe, dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); vor Fach-/Rechte-/Katalogprüfung. ALLOW/DENY ersetzen die einzelne Zuordnung mit frischer Identitäts-/Versionsbindung; REMOVE löscht sie. Kein SQL-GRANT/-REVOKE und keine Ausgabe einer effektiv für alle Tokens berechneten Rechteliste.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Bestehender synthetischer Work Type und DBprincipal sind Voraussetzung.
-- EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='contoso.noop',@Principal=N'ContosoProducer',@PermissionName='ENQUEUE',@PermissionState='ALLOW';
-- -- Persistente App-Delegation, nur im autorisierten Verwaltungsscope.
-- EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf der USP plus ausdrückliches CONTROL auf toolbelt_core.WorkTypePermission, geprüft durch HAS_PERMS_BY_NAME im aktuellen Principal-Kontext. EXECUTE allein genügt nicht. Vorhandene Katalogsichtbarkeit und Objekt-/Ownershiprechte müssen funktionieren; Hilfe benötigt keine erfolgreiche fachliche CONTROL-Prüfung. Keine automatisch erteilten Server-/Datenbankrollen, SQL-GRANTs oder erweiterten Rechte. Gleichnamiger Login in einer anderen Datenbank ersetzt kein gültiges DBprincipal-Mapping.
--
-- ## Ressourcenbedarf
--
-- Eine Zeile je Aufruf wird nach Principalauflösung unter UPDLOCK,HOLDLOCK auf dem WorkType gelöscht und bei ALLOW/DENY neu eingefügt. Sperren können in einer Callertransaktion bis zu deren Ende bleiben; kein eigener Lock-/Wallclocktimeout in diesem Kern. Keine feste CPU-/Heap-/Grant-/Latenz- oder Parallelitätszusage.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON, SET XACT_ABORT OFF. Nach Validierung CONTROL und committable Zustand prüfen, dann Principal auflösen. Ohne Callertransaktion eigener BEGIN/COMMIT, sonst fester Savepoint TBX_WorkType_Permission. Unter Elternzeilensperre alte einzelne Policy löschen; bei ALLOW/DENY aktuelle SID/create_date/WorkType-RowVersion und IsDenied neu einfügen. Parent wird dabei nicht aktualisiert. REMOVE fügt nichts ein. Eigener Fehler-Rollback bzw. Caller-Savepoint nur bei XACT_STATE=1, niemals vollständiger Callercommit/-rollback. BEGIN/SAVE liegt vor TRY; Rollbackfehler werden nicht separat geschützt. Debug>0/NULL=>0: nach Erfolg abstrakte Severity-10-NOWAIT-Meldung ohne Principal-/Policyinhalte. Hilfe kehrt vor allen Fachprüfungen zurück.
--
-- ## Fehlerbehandlung
--
-- 51590 NULL-Pflichtwerte/ungültige Aktion oder State; 51591 fehlendes CONTROL; 51594 uncommittable Caller; 51592 Principal fehlt/ungeeigneter Typ/ID0; 51593 Work Type fehlt, in dieser tatsächlichen Prüfpriorität. Leerer WorkType-/Principalname kann erst beim Kataloglookup scheitern, nicht automatisch 51590. Parameterwerte werden nicht generell normalisiert; SQL-Padding bleibt bei BIN2-Gleichheit wirksam. Unerwartete Engine-/Sperr-/Savepointfehler bleiben erhalten.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Policy-/Minimalrechte-/Skill-/Installerabnahme. Historische Belege behalten ihre ursprüngliche Bindung. App-Delegation ist kein SQL-GRANT und ersetzt keine Objekt-/Datenbank-/Handlerrechte. Keine SQL-Server-Rollenanlage, Identitätsumschaltung, Tenant-Isolation oder pauschale Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    IF ISNULL(@Hilfe,0)=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_SetWorkTypePermission' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51590-51594', NULL, NULL, NULL, NULL, CAST(N'Parameter, Autorität, Principal, Work Type oder Transaktionszustand ungültig.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und CONTROL auf toolbelt_core.WorkTypePermission.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Konfiguriert einen vorhandenen synthetischen Producerprincipal.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName=''demo.noop'',@Principal=N''ContosoProducer'',@PermissionName=''ENQUEUE'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Principal', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@PermissionName', N'varchar(32)', 1, 0, N'NULL', CAST(N'Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@PermissionState', N'varchar(8)', 0, 0, N'''ALLOW''', CAST(N'Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_SetWorkTypePermission' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-core-usp-setworktypepermission"
description: "Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkTypePermission"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@Principal", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig."}, {"name": "@PermissionName", "sql_type": "varchar(32)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig."}, {"name": "@PermissionState", "sql_type": "varchar(8)", "sql_default": "''ALLOW''", "is_output"' AS nvarchar(max)) + N': false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Parametervalidierung/CONTROL-/Katalogprüfung oder Policyänderung. 0 oder NULL führt den Fachpfad aus. Alle Argumente besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_SetWorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# USP_SetWorkTypePermission

## Zweck und Einsatzfälle

Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Roll' + N'en werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen.

## Voraussetzungen

SQL Server 2019/2022/2025 auf Windows/Linux, passende CL150/160/170, lokal/zentral. WorkType-Katalog und Policyobjekte in derselben Datenbank; zentrale Verwendung wertet den tatsächlichen DBtoken dieses Katalogs aus. Kein Second-Session- oder Queue-Provider für diese lokale Policyverwaltung/-entscheidung erforderlich. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen. Principal muss im lokalen sys.database_principals sichtbar sein, type in S/U/G/R/E/X und principal_id ungleich 0; keine Erstellung fehlender Identitäten. Work Type muss registriert sein, nicht zwingend enabled. Auch REMOVE setzt vorhandenen Principal und Work Type voraus und ist kein allgemeiner Bereiniger verwaister Zeilen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@Principal` | `sysname` | `NULL` | Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/l' + N'eer/fehlender Eintrag ist ungültig. |
| `@PermissionName` | `varchar(32)` | `NULL` | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig. |
| `@PermissionState` | `varchar(8)` | `''ALLOW''` | Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1 liefert bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile, danach RETURN 0 vor Parametervalidierung/CONTROL-/Katalogprüfung oder Policyänderung. 0 oder NULL führt den Fachpfad aus. Alle Argumente besitzen technische Defaults. |

## Ergebnisse

Kein fachlicher SELECT-Resultset und keine OUTPUT-Parameter. RETURN 0 bei Erfolg. @Hilfe=1: zuerst bestehende zwölfspaltige Standardhilfe, dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); vor Fach-/Rechte-/Katalogprüfung. ALLOW/DENY ersetzen die einzelne Zuordnung mit frischer Identitäts-/Versionsbindung; REMOVE löscht sie. Kein SQL-GRANT/-REVOKE und keine Ausgabe einer effektiv für alle Tokens berechneten Rechteliste.

## Aufrufbeispiele

```sql
-- Bestehender synthetischer Work Type und DBprincipal sind Voraussetzung.
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName=''contoso.noop'',@Princi' + N'pal=N''ContosoProducer'',@PermissionName=''ENQUEUE'',@PermissionState=''ALLOW'';
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

51590 NULL-Pflichtwerte/ungültige Aktion oder State; 51591 fehlendes CONTROL; 51594 uncommittable Caller; 51592 Principal fehlt/ungeeigneter Typ/ID' + N'0; 51593 Work Type fehlt, in dieser tatsächlichen Prüfpriorität. Leerer WorkType-/Principalname kann erst beim Kataloglookup scheitern, nicht automatisch 51590. Parameterwerte werden nicht generell normalisiert; SQL-Padding bleibt bei BIN2-Gleichheit wirksam. Unerwartete Engine-/Sperr-/Savepointfehler bleiben erhalten.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Policy-/Minimalrechte-/Skill-/Installerabnahme. Historische Belege behalten ihre ursprüngliche Bindung. App-Delegation ist kein SQL-GRANT und ersetzt keine Objekt-/Datenbank-/Handlerrechte. Keine SQL-Server-Rollenanlage, Identitätsumschaltung, Tenant-Isolation oder pauschale Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    IF @WorkTypeName IS NULL OR @Principal IS NULL OR @PermissionName IS NULL
        OR @PermissionName COLLATE Latin1_General_100_BIN2 NOT IN('ENQUEUE','CLAIM','EXECUTE_NEW_SESSION')
        OR @PermissionState IS NULL OR @PermissionState COLLATE Latin1_General_100_BIN2 NOT IN('ALLOW','DENY','REMOVE')
        THROW 51590,N'Work Type, Principal, Aktion und Zustand müssen gültig angegeben sein.',1;
    IF ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.WorkTypePermission',N'OBJECT',N'CONTROL'),0)<>1
        THROW 51591,N'CONTROL auf der Work-Type-Policy fehlt.',1;
    IF XACT_STATE()=-1 THROW 51594,N'Policyänderung ist in einer uncommittable Transaktion nicht möglich.',1;
    DECLARE @PrincipalId int,@Sid varbinary(85),@Created datetime;
    SELECT @PrincipalId=principal_id,@Sid=sid,@Created=create_date
    FROM sys.database_principals
    WHERE name=@Principal AND type IN('S','U','G','R','E','X') AND principal_id<>0;
    IF @PrincipalId IS NULL THROW 51592,N'Der Datenbankprincipal ist nicht verfügbar.',1;
    DECLARE @Initial int=@@TRANCOUNT,@WorkTypeId bigint,@Version binary(8);
    IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkType_Permission;
    BEGIN TRY
        SELECT @WorkTypeId=WorkTypeId,@Version=CONVERT(binary(8),RowVersion)
        FROM toolbelt_core.WorkType WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeName=@WorkTypeName;
        IF @WorkTypeId IS NULL THROW 51593,N'Der Work Type ist nicht registriert.',1;
        DELETE toolbelt_core.WorkTypePermission
        WHERE WorkTypeId=@WorkTypeId AND PrincipalId=@PrincipalId AND PermissionName=@PermissionName;
        IF @PermissionState<>'REMOVE'
            INSERT toolbelt_core.WorkTypePermission
            (WorkTypeId,PrincipalId,PermissionName,PrincipalSid,PrincipalCreatedAt,WorkTypeVersion,IsDenied)
            VALUES(@WorkTypeId,@PrincipalId,@PermissionName,@Sid,@Created,@Version,
                CASE WHEN @PermissionState='DENY' THEN 1 ELSE 0 END);
        IF @Initial=0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Initial=0 AND XACT_STATE()<>0 ROLLBACK;
        ELSE IF @Initial>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkType_Permission;
        THROW;
    END CATCH;
    IF ISNULL(@Debug,0)>0 RAISERROR(N'Work-Type-Policy aktualisiert.',10,1) WITH NOWAIT;
    RETURN 0;
END;
GO
