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
