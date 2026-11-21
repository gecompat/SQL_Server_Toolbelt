SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteEvent]
(
      @EventName varchar(128) = NULL
    , @EventLevel varchar(16) = 'INFO'
    , @Category varchar(128) = NULL
    , @Message nvarchar(4000) = NULL
    , @DataJson nvarchar(max) = NULL
    , @OccurredAtUtc datetime2(7) = NULL
    , @ExecutionId uniqueidentifier = NULL
    , @CorrelationId uniqueidentifier = NULL
    , @Actor nvarchar(256) = NULL
    , @Tenant nvarchar(256) = NULL
    , @SourceDatabaseName sysname = NULL
    , @SourceSchemaName sysname = NULL
    , @SourceObjectName sysname = NULL
    , @ErrorNumber int = NULL
    , @ErrorSeverity int = NULL
    , @ErrorState int = NULL
    , @ErrorProcedure sysname = NULL
    , @ErrorLine int = NULL
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-usp-writeevent"
-- description: "Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.event-log"
-- schema_name: "toolbelt_core"
-- object_name: "USP_WriteEvent"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@EventName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher lowercase-ASCII-Schlüssel varchar(128), LEN 3..128, beginnt mit a-z; weitere Zeichen ausschließlich a-z, 0-9, Punkt, Unterstrich oder Bindestrich, z.B. app.import.started. Kein Trim oder automatisches Lowercasing. Technischer Default NULL nur für Hilfe; NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@EventLevel", "sql_type": "varchar(16)", "sql_default": "'INFO'", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ: TRACE = feinste Ablaufdetails; DEBUG = technische Diagnose; INFO = normale Information (Default und NULL); WARNING = Warnung; ERROR = Fehler; CRITICAL = kritischer Fehler. UPPER normalisiert die Schreibweise; SQL-Gleichheitsregeln gelten. Die Werte sind Klassifikationen, keine automatische Retry-, Abbruch- oder Filtersteuerung."}, {"name": "@Category", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler varchar(128)-Kategorietext mit Zeichen A-Z, a-z, 0-9, Punkt, Unterstrich und Bindestrich. NULL und leer sind zulässig; keine automatische Normalisierung."}, {"name": "@Message", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler menschenlesbarer Unicode-Text nvarchar(4000); NULL/leer erlaubt. Er wird persistiert, nicht ausgeführt; Secrets/vertrauliche Inhalte müssen vorher bereinigt werden."}, {"name": "@DataJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler JSON-Objekttext nvarchar(max), höchstens 65536 UTF-16-Bytes (64 KiB); Arrays/Scalarroots und ungültiges JSON werden abgewiesen. Nach Entfernen gewöhnlicher führender Spaces muss { folgen; führender Tab/CR/LF genügt dieser LTRIM-Prüfung nicht. NULL bedeutet keine Zusatzdaten; leer ist ungültig. Beispiel N'{\"rows\":12}'."}, {"name": "@OccurredAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-datetime2(7) als fachlicher UTC-Zeitpunkt, z.B. CONVERT(datetime2(7),'2026-10-30T12:00:00',126); kein Offset im Typ und keine Zeitzonenkonvertierung. NULL/Default verwendet SYSUTCDATETIME()."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung."}, {"name": "@SourceDatabaseName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Datenbankkennzeichnung als sysname (bis 128 UTF-16-Codeeinheiten), als reiner Name/Text. NULL/Default wird DB_NAME(); leer wird abgewiesen. Eine explizite Kennzeichnung wird nicht auf Existenz geprüft."}, {"name": "@SourceSchemaName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale Schemakennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Kein zusammengesetzter Objektname, keine Existenz- oder Rechteprüfung."}, {"name": "@SourceObjectName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale Objektkennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Text-Metadatum, keine Ausführung und keine Objektauflösung."}, {"name": "@ErrorNumber", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale int-Fehlernummer aus ERROR_NUMBER(), NULL bedeutet kein Fehlerkontext. Anders als ErrorEnvelope wird hier keine Positivitätsprüfung dieses Feldes durchgeführt."}, {"name": "@ErrorSeverity", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler int-Wert 0..25 einschließlich aus ERROR_SEVERITY(); NULL erlaubt, außerhalb Fehler. Die EventLevel-Klassifikation wird dadurch nicht automatisch geändert."}, {"name": "@ErrorState", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler int-Wert 0..255 einschließlich aus ERROR_STATE(); NULL erlaubt, außerhalb Fehler."}, {"name": "@ErrorProcedure", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale Fehlerprocedure als sysname (höchstens 128 Codeeinheiten), etwa ERROR_PROCEDURE(); NULL/leer erlaubt, kein auszuführender Aufruf."}, {"name": "@ErrorLine", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL erlaubt, 0/negativ wird abgewiesen."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql", "Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql", "Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql", "Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_WriteEvent
--
-- ## Zweck und Einsatzfälle
--
-- Schreibt ein strukturiertes Event synchron über den registrierten Work Type toolbelt.event-log.write in einer eigenen Loopback-Session. Kein direktes lokales INSERT und keine allgemeine Serverdiagnose.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025 Windows/Linux, passende CL150/160/170, lokal/zentral. EventLog und execution-context installiert. Konfigurierter aktivierter Loopback-Provider in second-session >=1.1.0 mit RPC OUT und Remote-Proc-Transaction-Promotion OFF. Aktiv registrierter JSON_PAYLOAD-Work-Type toolbelt.event-log.write mit kanonischem Handler USP_WriteEventInternal(@PayloadJson nvarchar(max),@Hilfe bit=0), ohne fachliches Resultset. Vorhandene lokale und Remote-Policy EXECUTE_NEW_SESSION plus Remote-Handler-EXECUTE. Runtime-Preflight prüft unter anderem OBJECT_ID und @SuppressResult-Parameter; er installiert/konfiguriert nichts.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@EventName` | `varchar(128)` | `NULL` | Input | Fachlich erforderlicher lowercase-ASCII-Schlüssel varchar(128), LEN 3..128, beginnt mit a-z; weitere Zeichen ausschließlich a-z, 0-9, Punkt, Unterstrich oder Bindestrich, z.B. app.import.started. Kein Trim oder automatisches Lowercasing. Technischer Default NULL nur für Hilfe; NULL/leer/ungültige Lexik wird abgewiesen. |
-- | `@EventLevel` | `varchar(16)` | `'INFO'` | Input | Taxativ: TRACE = feinste Ablaufdetails; DEBUG = technische Diagnose; INFO = normale Information (Default und NULL); WARNING = Warnung; ERROR = Fehler; CRITICAL = kritischer Fehler. UPPER normalisiert die Schreibweise; SQL-Gleichheitsregeln gelten. Die Werte sind Klassifikationen, keine automatische Retry-, Abbruch- oder Filtersteuerung. |
-- | `@Category` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Kategorietext mit Zeichen A-Z, a-z, 0-9, Punkt, Unterstrich und Bindestrich. NULL und leer sind zulässig; keine automatische Normalisierung. |
-- | `@Message` | `nvarchar(4000)` | `NULL` | Input | Optionaler menschenlesbarer Unicode-Text nvarchar(4000); NULL/leer erlaubt. Er wird persistiert, nicht ausgeführt; Secrets/vertrauliche Inhalte müssen vorher bereinigt werden. |
-- | `@DataJson` | `nvarchar(max)` | `NULL` | Input | Optionaler JSON-Objekttext nvarchar(max), höchstens 65536 UTF-16-Bytes (64 KiB); Arrays/Scalarroots und ungültiges JSON werden abgewiesen. Nach Entfernen gewöhnlicher führender Spaces muss { folgen; führender Tab/CR/LF genügt dieser LTRIM-Prüfung nicht. NULL bedeutet keine Zusatzdaten; leer ist ungültig. Beispiel N'{"rows":12}'. |
-- | `@OccurredAtUtc` | `datetime2(7)` | `NULL` | Input | SQL-datetime2(7) als fachlicher UTC-Zeitpunkt, z.B. CONVERT(datetime2(7),'2026-10-30T12:00:00',126); kein Offset im Typ und keine Zeitzonenkonvertierung. NULL/Default verwendet SYSUTCDATETIME(). |
-- | `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
-- | `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
-- | `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
-- | `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
-- | `@SourceDatabaseName` | `sysname` | `NULL` | Input | Datenbankkennzeichnung als sysname (bis 128 UTF-16-Codeeinheiten), als reiner Name/Text. NULL/Default wird DB_NAME(); leer wird abgewiesen. Eine explizite Kennzeichnung wird nicht auf Existenz geprüft. |
-- | `@SourceSchemaName` | `sysname` | `NULL` | Input | Optionale Schemakennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Kein zusammengesetzter Objektname, keine Existenz- oder Rechteprüfung. |
-- | `@SourceObjectName` | `sysname` | `NULL` | Input | Optionale Objektkennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Text-Metadatum, keine Ausführung und keine Objektauflösung. |
-- | `@ErrorNumber` | `int` | `NULL` | Input | Optionale int-Fehlernummer aus ERROR_NUMBER(), NULL bedeutet kein Fehlerkontext. Anders als ErrorEnvelope wird hier keine Positivitätsprüfung dieses Feldes durchgeführt. |
-- | `@ErrorSeverity` | `int` | `NULL` | Input | Optionaler int-Wert 0..25 einschließlich aus ERROR_SEVERITY(); NULL erlaubt, außerhalb Fehler. Die EventLevel-Klassifikation wird dadurch nicht automatisch geändert. |
-- | `@ErrorState` | `int` | `NULL` | Input | Optionaler int-Wert 0..255 einschließlich aus ERROR_STATE(); NULL erlaubt, außerhalb Fehler. |
-- | `@ErrorProcedure` | `sysname` | `NULL` | Input | Optionale Fehlerprocedure als sysname (höchstens 128 Codeeinheiten), etwa ERROR_PROCEDURE(); NULL/leer erlaubt, kein auszuführender Aufruf. |
-- | `@ErrorLine` | `int` | `NULL` | Input | Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL erlaubt, 0/negativ wird abgewiesen. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- Kein fachlicher oder infrastruktureller SELECT-Resultset und keine OUTPUT-Parameter; RETURN 0 bei Erfolg. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam. Erfolgreicher synchroner Remote-Dispatcherabschluss bestätigt den Remote-Commit. Fehler kann auch erst nach Commit oder bei verlorener Antwort auftreten: daraus niemals sicher auf nicht geschrieben schließen. Gleiche ExecutionId/CorrelationId dedupliziert keine Events; Wiederholung kann Duplikate erzeugen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_WriteEvent @EventName='contoso.example',@EventLevel='INFO',@Message=N'Synthetic event',@DataJson=N'{"rows":1}';
-- -- Persistiert über den zuvor autorisierten/konfigurierten Provider.
-- EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf USP_WriteEvent und gültige bestehende Abhängigkeitsrechte. Beide beteiligten DBprincipals benötigen die passende WorkType-Policy EXECUTE_NEW_SESSION; Remoteprincipal zusätzlich vorhandenes EXECUTE auf Dispatcher/Handler und gültige Linked-Server-Anmeldung. Katalogsichtbarkeit für WorkType, Provider und Signaturen muss bestehen. Ein öffentlicher USP-Grant allein ist keine Zusage funktionierenden Transports. Keine neuen Rollen/Grants, kein automatisches Abschalten von Sicherheitsregeln. Quellnamen, Actor/Tenant und Context IDs verleihen keine Rechte.
--
-- ## Ressourcenbedarf
--
-- DataJson höchstens 65536 UTF-16-Bytes =64 KiB, trotz älterem Fehlertext mit 32-KiB-Bezeichnung. FOR JSON erzeugt eine ganze zusätzliche Payload mit Escaping; interner Handler begrenzt diese auf 131072 Bytes, Transport auf 1048576 Bytes. Diese Grenzen gelten getrennt, keine Streaming-/Heapzusage. Message bis gebundenem nvarchar(4000), Namen/weitere Felder nach Parametertyp. Persistente Tabellen-/Indexkosten ohne globale Zeilenquote oder automatische Retention. Synchroner Linked-Server-RPC kann auf Provider, Remote-Locks, Commit und Cleanup warten. Ein Caller mit Locks auf benötigten Remoteobjekten kann den eigenen Remoteaufruf blockieren. Keine neue globale Zeit-/CPU-/Speicherquote, keine automatische Wiederholung.
--
-- ## Nebenwirkungen
--
-- Vor Hilfe lokale Defaultnormalisierung von EventLevel=UPPER(COALESCE(...,INFO)), Ereigniszeit, Quell-DB, Debug/Hilfe. Fachpfad liest Kontext: ExecutionId explizit > Kontext > NEWID; CorrelationId explizit > Kontext > gewählte ExecutionId; Actor explizit > Kontext > ORIGINAL_LOGIN, Tenant explizit > Kontext > NULL. Bindet Caller-SPID/XACT_STATE/@@TRANCOUNT als Auditdaten. RPC ruft Dispatcher in derselben Toolbelt-DB über den konfigurierten Linked Server auf; Payloadwerte sind parametergebunden, Namen QUOTENAME-geschützt. Dispatcher bindet Remote-Kontext, führt Handler innerhalb eigener Transaktion WITH RESULT SETS NONE aus, committet und räumt Kontext auf. Callertransaktion wird nicht committed/rollbackt, auch uncommittable Caller ohne ResultTable zulässig. SuppressResult=1 unterdrückt Infrastrukturresultset; Debug bleibt abstrakte Transportdiagnose. Keine automatische Provider-/Work-Type-Einrichtung. Gespeicherte Message/DataJson und Auditwerte werden nicht automatisch redigiert; keine Secrets oder vertraulichen Inhalte übergeben.
--
-- ## Fehlerbehandlung
--
-- 51700 EventName-Lexik (lowercase ASCII, LEN3..128, erstes Zeichen a..z, sonst a..z/0..9/._-); 51701 Level (TRACE,DEBUG,INFO,WARNING,ERROR,CRITICAL nach UPPER/NULL=>INFO); 51702 Category-Lexik; 51703 DataJson; 51704 Quell-DB leer; 51705 Severity0..25; 51706 State0..255; 51707 ErrorLine>0; 51708 Second-Session-Abhängigkeit, in dieser Reihenfolge. SQL-Textvergleich einschließlich Padding ist kein allgemeiner bytegenauer Wertevergleich. DataJson verlangt ISJSON und { nach LTRIM gewöhnlicher Spaces, nicht beliebiger führender JSON-Whitespace. Technische Provider-/Policy-/Remote-Handler-/Kontextfehler werden weitergegeben; Remote-Kontextcleanup kann nach Commit fehlschlagen. Kein Catch mit verstecktem Erfolg und kein automatisches Retry.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;

    SET @EventLevel = UPPER(ISNULL(@EventLevel, 'INFO'));
    SET @OccurredAtUtc = ISNULL(@OccurredAtUtc, SYSUTCDATETIME());
    SET @SourceDatabaseName = ISNULL(@SourceDatabaseName, DB_NAME());
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_WriteEvent' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51700-51709', NULL, NULL, NULL, NULL, CAST(N'Event-, JSON-, Fehler- und Dependency-Vertragsfehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schreibt ein Info-Event.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_WriteEvent @EventName=''demo.completed'', @Message=N''Synthetic example'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@EventName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher lowercase-ASCII-Schlüssel varchar(128), LEN 3..128, beginnt mit a-z; weitere Zeichen ausschließlich a-z, 0-9, Punkt, Unterstrich oder Bindestrich, z.B. app.import.started. Kein Trim oder automatisches Lowercasing. Technischer Default NULL nur für Hilfe; NULL/leer/ungültige Lexik wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@EventLevel', N'varchar(16)', 0, 1, N'''INFO''', CAST(N'Taxativ: TRACE = feinste Ablaufdetails; DEBUG = technische Diagnose; INFO = normale Information (Default und NULL); WARNING = Warnung; ERROR = Fehler; CRITICAL = kritischer Fehler. UPPER normalisiert die Schreibweise; SQL-Gleichheitsregeln gelten. Die Werte sind Klassifikationen, keine automatische Retry-, Abbruch- oder Filtersteuerung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Category', N'varchar(128)', 0, 1, N'NULL', CAST(N'Optionaler varchar(128)-Kategorietext mit Zeichen A-Z, a-z, 0-9, Punkt, Unterstrich und Bindestrich. NULL und leer sind zulässig; keine automatische Normalisierung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Message', N'nvarchar(4000)', 0, 1, N'NULL', CAST(N'Optionaler menschenlesbarer Unicode-Text nvarchar(4000); NULL/leer erlaubt. Er wird persistiert, nicht ausgeführt; Secrets/vertrauliche Inhalte müssen vorher bereinigt werden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@DataJson', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Optionaler JSON-Objekttext nvarchar(max), höchstens 65536 UTF-16-Bytes (64 KiB); Arrays/Scalarroots und ungültiges JSON werden abgewiesen. Nach Entfernen gewöhnlicher führender Spaces muss { folgen; führender Tab/CR/LF genügt dieser LTRIM-Prüfung nicht. NULL bedeutet keine Zusatzdaten; leer ist ungültig. Beispiel N''{"rows":12}''.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@OccurredAtUtc', N'datetime2(7)', 0, 1, N'NULL', CAST(N'SQL-datetime2(7) als fachlicher UTC-Zeitpunkt, z.B. CONVERT(datetime2(7),''2026-10-30T12:00:00'',126); kein Offset im Typ und keine Zeitzonenkonvertierung. NULL/Default verwendet SYSUTCDATETIME().' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ExecutionId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@CorrelationId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Actor', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Tenant', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@SourceDatabaseName', N'sysname', 0, 1, N'NULL', CAST(N'Datenbankkennzeichnung als sysname (bis 128 UTF-16-Codeeinheiten), als reiner Name/Text. NULL/Default wird DB_NAME(); leer wird abgewiesen. Eine explizite Kennzeichnung wird nicht auf Existenz geprüft.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@SourceSchemaName', N'sysname', 0, 1, N'NULL', CAST(N'Optionale Schemakennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Kein zusammengesetzter Objektname, keine Existenz- oder Rechteprüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@SourceObjectName', N'sysname', 0, 1, N'NULL', CAST(N'Optionale Objektkennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Text-Metadatum, keine Ausführung und keine Objektauflösung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 14, N'@ErrorNumber', N'int', 0, 1, N'NULL', CAST(N'Optionale int-Fehlernummer aus ERROR_NUMBER(), NULL bedeutet kein Fehlerkontext. Anders als ErrorEnvelope wird hier keine Positivitätsprüfung dieses Feldes durchgeführt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 15, N'@ErrorSeverity', N'int', 0, 1, N'NULL', CAST(N'Optionaler int-Wert 0..25 einschließlich aus ERROR_SEVERITY(); NULL erlaubt, außerhalb Fehler. Die EventLevel-Klassifikation wird dadurch nicht automatisch geändert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 16, N'@ErrorState', N'int', 0, 1, N'NULL', CAST(N'Optionaler int-Wert 0..255 einschließlich aus ERROR_STATE(); NULL erlaubt, außerhalb Fehler.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 17, N'@ErrorProcedure', N'sysname', 0, 1, N'NULL', CAST(N'Optionale Fehlerprocedure als sysname (höchstens 128 Codeeinheiten), etwa ERROR_PROCEDURE(); NULL/leer erlaubt, kein auszuführender Aufruf.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 18, N'@ErrorLine', N'int', 0, 1, N'NULL', CAST(N'Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL erlaubt, 0/negativ wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 19, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 20, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_WriteEvent' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-core-usp-writeevent"
description: "Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion."
skill_format_version: "1.0"
module_id: "toolbelt.core.event-log"
schema_name: "toolbelt_core"
object_name: "USP_WriteEvent"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EventName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher lowercase-ASCII-Schlüssel varchar(128), LEN 3..128, beginnt mit a-z; weitere Zeichen ausschließlich a-z, 0-9, Punkt, Unterstrich oder Bindestrich, z.B. app.import.started. Kein Trim oder automatisches Lowercasing. Technischer Default NULL nur für Hilfe; NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@EventLevel", "sql_type": "varchar(16)", "sql_default": "''INFO''", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ: TRACE = feinste Ablaufdetails; DEBUG = technische Diagnose; INFO = normale Information (Default und NULL); WARNING = Warnung; ERROR = Fehler; CRITICAL = kritischer Fehler. UPPER normalisiert die Schreibweise; SQL-Gleichheitsregeln gelten. Die Werte sind Klassifikationen, keine automatische Retry-, Abbruch- oder Filtersteuerung."}, {"name": "@Category", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler varchar(128)-Kategorietext mit Zeichen A-Z, a-z, 0-9, Punkt, Unterstrich und Bindestrich. NULL und leer sind zulässig; keine automatische Normalisierung."}, {"name": "@Message", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "descripti' AS nvarchar(max)) + N'on": "Optionaler menschenlesbarer Unicode-Text nvarchar(4000); NULL/leer erlaubt. Er wird persistiert, nicht ausgeführt; Secrets/vertrauliche Inhalte müssen vorher bereinigt werden."}, {"name": "@DataJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler JSON-Objekttext nvarchar(max), höchstens 65536 UTF-16-Bytes (64 KiB); Arrays/Scalarroots und ungültiges JSON werden abgewiesen. Nach Entfernen gewöhnlicher führender Spaces muss { folgen; führender Tab/CR/LF genügt dieser LTRIM-Prüfung nicht. NULL bedeutet keine Zusatzdaten; leer ist ungültig. Beispiel N''{\"rows\":12}''."}, {"name": "@OccurredAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-datetime2(7) als fachlicher UTC-Zeitpunkt, z.B. CONVERT(datetime2(7),''2026-10-30T12:00:00'',126); kein Offset im Typ und keine Zeitzonenkonvertierung. NULL/Default verwendet SYSUTCDATETIME()."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite' + N' ID hat Vorrang."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung."}, {"name": "@SourceDatabaseName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Datenbankkennzeichnung als sysname (bis 128 UTF-16-Codeeinheiten), als reiner Name/Text. NULL/Default wird DB_NAME(); leer wird abgewiesen. Eine explizite Kennzeichnung wird nicht auf Existenz geprüft."}, {"name": "@SourceSchemaName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale Schemakennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Kein zusammengesetzter Objektname, keine Existenz- oder Rechteprüfung."}, {"name": "@SourceObjectName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale Objektkennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Text-Metadatum, keine Ausführung und keine Objektauflösung."}, {"name": "@ErrorNumber", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "d' + N'escription": "Optionale int-Fehlernummer aus ERROR_NUMBER(), NULL bedeutet kein Fehlerkontext. Anders als ErrorEnvelope wird hier keine Positivitätsprüfung dieses Feldes durchgeführt."}, {"name": "@ErrorSeverity", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler int-Wert 0..25 einschließlich aus ERROR_SEVERITY(); NULL erlaubt, außerhalb Fehler. Die EventLevel-Klassifikation wird dadurch nicht automatisch geändert."}, {"name": "@ErrorState", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler int-Wert 0..255 einschließlich aus ERROR_STATE(); NULL erlaubt, außerhalb Fehler."}, {"name": "@ErrorProcedure", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale Fehlerprocedure als sysname (höchstens 128 Codeeinheiten), etwa ERROR_PROCEDURE(); NULL/leer erlaubt, kein auszuführender Aufruf."}, {"name": "@ErrorLine", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL erlaubt, 0/negativ wird abgewiesen."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile ' + N'vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql", "Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql", "Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql", "Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_WriteEvent

## Zweck und Einsatzfälle

Schreibt ein strukturiertes Event synchron über den registrierten Work Type toolbelt.event-log.write in einer eigenen Loopback-Session. Kein direktes lokales INSERT und keine allgemeine Serverdiagnose.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux, passende CL150/160/170, lokal/zentral. EventLog und execution-context installiert. Konfigurierter aktivierter Loopback-Provider in second-session >=1.1.0 mit RPC OUT und Remote-Proc-Transaction-Promotion OFF. Aktiv registrierter JSON_PAYLOAD-Work-Type toolbelt.event-log.write mit kanonischem Handler USP_WriteEventInternal(@PayloadJson nvarchar(max),@Hilfe bit=0), ohne fachliches Resultset. Vorhandene lokale und Remote-Policy EXECUTE_NEW_SESSION plus Remote-Handler-EXECUTE. Runtime-Preflight prüft unter anderem OBJECT_ID und @SuppressResult-Parameter; er installiert/konfiguriert nichts.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@EventName` | `varchar(128)` | `NULL` | Input | Fachlich erforderlicher lowercase-ASCII-Schlüssel varchar(128), LEN 3..128, beginnt mit a-z; weitere Zeichen ausschließlich a-z, 0-9, Punkt, Unterstrich oder Bindestrich, z.B. app.import.started. Kein Trim oder automatisches Lowercasing. Technischer Default NULL nur für Hilfe; NULL/leer/ungültige Lexik wird abgewiesen. |
| `@EventLevel` | `varchar(16)` | `''INFO''` | Input | Taxativ: TRACE = feinste Ablaufdetails; DEBUG = technis' + N'che Diagnose; INFO = normale Information (Default und NULL); WARNING = Warnung; ERROR = Fehler; CRITICAL = kritischer Fehler. UPPER normalisiert die Schreibweise; SQL-Gleichheitsregeln gelten. Die Werte sind Klassifikationen, keine automatische Retry-, Abbruch- oder Filtersteuerung. |
| `@Category` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Kategorietext mit Zeichen A-Z, a-z, 0-9, Punkt, Unterstrich und Bindestrich. NULL und leer sind zulässig; keine automatische Normalisierung. |
| `@Message` | `nvarchar(4000)` | `NULL` | Input | Optionaler menschenlesbarer Unicode-Text nvarchar(4000); NULL/leer erlaubt. Er wird persistiert, nicht ausgeführt; Secrets/vertrauliche Inhalte müssen vorher bereinigt werden. |
| `@DataJson` | `nvarchar(max)` | `NULL` | Input | Optionaler JSON-Objekttext nvarchar(max), höchstens 65536 UTF-16-Bytes (64 KiB); Arrays/Scalarroots und ungültiges JSON werden abgewiesen. Nach Entfernen gewöhnlicher führender Spaces muss { folgen; führender Tab/CR/LF genügt dieser LTRIM-Prüfung nicht. NULL bedeutet keine Zusatzdaten; leer ist ungültig. Beispiel N''{"rows":12}''. |
| `@OccurredAtUtc` | `datetime2(7)` | `NULL` | Input | SQL-datetime2(7) als fachlicher UTC-Zeitpunkt, z.B. CONVERT(datetime2(7),''2026-10-30T12:00:00'',126); kein Offset im Typ und keine Zeitzonenkonvertierung. NULL/Default verwendet SYSUTCDATETIME(). |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine' + N' explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@SourceDatabaseName` | `sysname` | `NULL` | Input | Datenbankkennzeichnung als sysname (bis 128 UTF-16-Codeeinheiten), als reiner Name/Text. NULL/Default wird DB_NAME(); leer wird abgewiesen. Eine explizite Kennzeichnung wird nicht auf Existenz geprüft. |
| `@SourceSchemaName` | `sysname` | `NULL` | Input | Optionale Schemakennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Kein zusammengesetzter Objektname, keine Existenz- oder Rechteprüfung. |
| `@SourceObjectName` | `sysname` | `NULL` | Input | Optionale Objektkennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Text-Metadatum, keine Ausführung und keine Objektauflösung. |
| `@ErrorNumber` | `int` | `NULL` | Input | Optionale int-Fehlernummer aus ERROR_NUMBER(), NULL bedeutet kein Fehlerkontext. Anders als ErrorEnvelope wird hier keine Positivitätsprüfung dieses Feldes durchgeführt. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Optionaler int-Wert 0..25 einschließlich aus ERROR_SEVERITY(); NULL erlaubt, außerhalb Fehler. Die EventLevel-Klassifikation wird dadurch nicht automatisch geändert. |
| `@ErrorState` | `int` | `NULL` | Input | Optionaler int-Wert 0..255 einschließlich aus ERROR_STATE(); NULL erlaubt, außerhalb Fehler. |
| `@ErrorProcedure` | `sysname` | `NULL` | Input | Optionale Fehlerprocedure als sysname (höchstens 128 Codeeinheiten), etwa ERROR_PROCEDURE(); NULL/leer erlaubt, kein auszuführender Aufruf. |
| `@ErrorLine` | `int` | `NULL` | Input | Optionale positive in' + N't-Zeilennummer aus ERROR_LINE(); NULL erlaubt, 0/negativ wird abgewiesen. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

## Ergebnisse

Kein fachlicher oder infrastruktureller SELECT-Resultset und keine OUTPUT-Parameter; RETURN 0 bei Erfolg. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam. Erfolgreicher synchroner Remote-Dispatcherabschluss bestätigt den Remote-Commit. Fehler kann auch erst nach Commit oder bei verlorener Antwort auftreten: daraus niemals sicher auf nicht geschrieben schließen. Gleiche ExecutionId/CorrelationId dedupliziert keine Events; Wiederholung kann Duplikate erzeugen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_WriteEvent @EventName=''contoso.example'',@EventLevel=''INFO'',@Message=N''Synthetic event'',@DataJson=N''{"rows":1}'';
-- Persistiert über den zuvor autorisierten/konfigurierten Provider.
EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf USP_WriteEvent und gültige bestehende Abhängigkeitsrechte. Beide beteiligten DBprincipals benötigen die passende WorkType-Policy EXECUTE_NEW_SESSION; Remoteprincipal zusätzlich vorhandenes EXECUTE auf Dispatcher/Handler und gültige Linked-Server-Anmeldung. Katalogsichtbarkeit für WorkType, Provider und Signaturen muss bestehen. Ein ' + N'öffentlicher USP-Grant allein ist keine Zusage funktionierenden Transports. Keine neuen Rollen/Grants, kein automatisches Abschalten von Sicherheitsregeln. Quellnamen, Actor/Tenant und Context IDs verleihen keine Rechte.

## Ressourcenbedarf

DataJson höchstens 65536 UTF-16-Bytes =64 KiB, trotz älterem Fehlertext mit 32-KiB-Bezeichnung. FOR JSON erzeugt eine ganze zusätzliche Payload mit Escaping; interner Handler begrenzt diese auf 131072 Bytes, Transport auf 1048576 Bytes. Diese Grenzen gelten getrennt, keine Streaming-/Heapzusage. Message bis gebundenem nvarchar(4000), Namen/weitere Felder nach Parametertyp. Persistente Tabellen-/Indexkosten ohne globale Zeilenquote oder automatische Retention. Synchroner Linked-Server-RPC kann auf Provider, Remote-Locks, Commit und Cleanup warten. Ein Caller mit Locks auf benötigten Remoteobjekten kann den eigenen Remoteaufruf blockieren. Keine neue globale Zeit-/CPU-/Speicherquote, keine automatische Wiederholung.

## Nebenwirkungen

Vor Hilfe lokale Defaultnormalisierung von EventLevel=UPPER(COALESCE(...,INFO)), Ereigniszeit, Quell-DB, Debug/Hilfe. Fachpfad liest Kontext: ExecutionId explizit > Kontext > NEWID; CorrelationId explizit > Kontext > gewählte ExecutionId; Actor explizit > Kontext > ORIGINAL_LOGIN, Tenant explizit > Kontext > NULL. Bindet Caller-SPID/XACT_STATE/@@TRANCOUNT als Auditdaten. RPC ruft Dispatcher in derselben Toolbelt-DB über den konfigurierten Linked Server auf; Payloadwerte sind parametergebunden, Namen QUOTENAME-geschützt. Dispatcher bindet Remote-Kontext, führt Handler innerhalb eigener Transaktion WITH RESULT SETS NONE aus, committet und räumt Kontext auf. Callertransaktion wird nicht committed/rollbackt, auch uncommittable Caller ohne ResultTable zulässig. SuppressResult=1 unterdrückt Infrastrukturresultset; Debug bleibt abstrakte Transportdiagnose. Keine automatische Provider-/Work-Type-Einrichtung. Gespeicherte Message/DataJson und Auditwerte werden nicht automatisch redigiert; keine Secrets oder' + N' vertraulichen Inhalte übergeben.

## Fehlerbehandlung

51700 EventName-Lexik (lowercase ASCII, LEN3..128, erstes Zeichen a..z, sonst a..z/0..9/._-); 51701 Level (TRACE,DEBUG,INFO,WARNING,ERROR,CRITICAL nach UPPER/NULL=>INFO); 51702 Category-Lexik; 51703 DataJson; 51704 Quell-DB leer; 51705 Severity0..25; 51706 State0..255; 51707 ErrorLine>0; 51708 Second-Session-Abhängigkeit, in dieser Reihenfolge. SQL-Textvergleich einschließlich Padding ist kein allgemeiner bytegenauer Wertevergleich. DataJson verlangt ISJSON und { nach LTRIM gewöhnlicher Spaces, nicht beliebiger führender JSON-Whitespace. Technische Provider-/Policy-/Remote-Handler-/Kontextfehler werden weitergegeben; Remote-Kontextcleanup kann nach Commit fehlschlagen. Kein Catch mit verstecktem Erfolg und kein automatisches Retry.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF NULLIF(@EventName, '') IS NULL
       OR LEN(@EventName) NOT BETWEEN 3 AND 128
       OR @EventName <> LOWER(@EventName) COLLATE Latin1_General_100_BIN2
       OR @EventName NOT LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
       OR @EventName LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
        THROW 51700, N'@EventName muss ein kanonischer lowercase ASCII-Name sein.', 1;
    IF @EventLevel NOT IN ('TRACE','DEBUG','INFO','WARNING','ERROR','CRITICAL')
        THROW 51701, N'@EventLevel ist ungültig.', 1;
    IF @Category IS NOT NULL AND (LEN(@Category) > 128 OR @Category LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2)
        THROW 51702, N'@Category enthält ungültige Zeichen oder ist zu lang.', 1;
    IF @DataJson IS NOT NULL AND (DATALENGTH(@DataJson) > 65536 OR ISJSON(@DataJson) <> 1 OR LEFT(LTRIM(@DataJson), 1) <> N'{')
        THROW 51703, N'@DataJson muss ein JSON-Objekt mit höchstens 32 KiB UTF-16-Speicher sein.', 1;
    IF NULLIF(@SourceDatabaseName, N'') IS NULL
        THROW 51704, N'@SourceDatabaseName ist erforderlich.', 1;
    IF @ErrorSeverity IS NOT NULL AND @ErrorSeverity NOT BETWEEN 0 AND 25
        THROW 51705, N'@ErrorSeverity liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorState IS NOT NULL AND @ErrorState NOT BETWEEN 0 AND 255
        THROW 51706, N'@ErrorState liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorLine IS NOT NULL AND @ErrorLine <= 0
        THROW 51707, N'@ErrorLine muss positiv sein.', 1;
    IF OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession', N'P') IS NULL
       OR NOT EXISTS
          (
              SELECT 1 FROM sys.parameters
              WHERE object_id = OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession')
                AND name = N'@SuppressResult'
          )
        THROW 51708, N'Die Abhängigkeit toolbelt.core.second-session Version 1.1.0 fehlt.', 1;

    DECLARE
          @CurrentExecutionId uniqueidentifier
        , @CurrentCorrelationId uniqueidentifier
        , @CurrentActor nvarchar(256)
        , @CurrentTenant nvarchar(256);
    SELECT
          @CurrentExecutionId = c.ExecutionId
        , @CurrentCorrelationId = c.CorrelationId
        , @CurrentActor = c.Actor
        , @CurrentTenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    SET @ExecutionId = COALESCE(@ExecutionId, @CurrentExecutionId, NEWID());
    SET @CorrelationId = COALESCE(@CorrelationId, @CurrentCorrelationId, @ExecutionId);
    SET @Actor = COALESCE(@Actor, @CurrentActor, CONVERT(nvarchar(256), ORIGINAL_LOGIN()));
    SET @Tenant = COALESCE(@Tenant, @CurrentTenant);

    DECLARE @CallerSessionId int = @@SPID;
    DECLARE @CallerXactState smallint = CONVERT(smallint, XACT_STATE());
    DECLARE @CallerTransactionCount int = @@TRANCOUNT;
    DECLARE @PayloadJson nvarchar(max);

    SELECT @PayloadJson =
    (
        SELECT
              @EventName AS eventName
            , @EventLevel AS eventLevel
            , @Category AS category
            , @Message AS message
            , JSON_QUERY(@DataJson) AS data
            , CONVERT(nvarchar(33), @OccurredAtUtc, 127) AS occurredAtUtc
            , @SourceDatabaseName AS sourceDatabaseName
            , @SourceSchemaName AS sourceSchemaName
            , @SourceObjectName AS sourceObjectName
            , @CallerSessionId AS callerSessionId
            , @CallerXactState AS callerXactState
            , @CallerTransactionCount AS callerTransactionCount
            , @ErrorNumber AS errorNumber
            , @ErrorSeverity AS errorSeverity
            , @ErrorState AS errorState
            , @ErrorProcedure AS errorProcedure
            , @ErrorLine AS errorLine
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
    );

    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
          @WorkTypeName = 'toolbelt.event-log.write'
        , @PayloadJson = @PayloadJson
        , @ExecutionId = @ExecutionId
        , @CorrelationId = @CorrelationId
        , @Actor = @Actor
        , @Tenant = @Tenant
        , @SuppressResult = 1
        , @Debug = @Debug;

    RETURN 0;
END;
GO
