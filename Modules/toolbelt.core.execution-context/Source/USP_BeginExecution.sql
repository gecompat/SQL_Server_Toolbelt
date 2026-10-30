SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_BeginExecution]
(
      @ExecutionId   uniqueidentifier = NULL OUTPUT
    , @CorrelationId uniqueidentifier = NULL
    , @Actor         nvarchar(256)    = NULL
    , @Tenant        nvarchar(256)    = NULL
    , @AllowNested   bit              = 1
    , @Debug         tinyint          = 0
    , @Hilfe         bit              = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @AllowNested = ISNULL(@AllowNested, 1);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_BeginExecution' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@ExecutionId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@CorrelationId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Actor', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root bleiben NULL/leer so gespeichert; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Tenant', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root NULL/leer zulässig; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@AllowNested', N'bit', 0, 1, N'1', CAST(N'Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    DECLARE @CurrentCorrelationId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.correlation_id'));
    DECLARE @CurrentDepth int = TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth'));
    DECLARE @CurrentActor nvarchar(256) = CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.actor'));
    DECLARE @CurrentTenant nvarchar(256) = CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.tenant'));

    IF @CurrentExecutionId IS NULL
    BEGIN
        SET @ExecutionId = ISNULL(@ExecutionId, NEWID());
        SET @CorrelationId = ISNULL(@CorrelationId, @ExecutionId);
        DECLARE @StartedAtUtc nvarchar(33) = CONVERT(nvarchar(33), SYSUTCDATETIME(), 126);
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id', @value=@ExecutionId;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=@CorrelationId;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=@Actor;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=@Tenant;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.started_at_utc', @value=@StartedAtUtc;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=1;
    END
    ELSE
    BEGIN
        IF @AllowNested = 0
            THROW 51420, N'In dieser Session ist bereits ein Execution Context aktiv.', 1;
        IF @CurrentDepth IS NULL OR @CurrentDepth < 1 OR @CurrentDepth >= 32767
            THROW 51421, N'Der vorhandene Execution Context besitzt einen ungültigen ScopeDepth.', 1;
        IF @ExecutionId IS NOT NULL AND @ExecutionId <> @CurrentExecutionId
            THROW 51422, N'Die angeforderte Execution-ID stimmt nicht mit dem aktiven Context überein.', 1;
        IF @CorrelationId IS NOT NULL AND @CorrelationId <> @CurrentCorrelationId
            THROW 51423, N'Die angeforderte Correlation-ID stimmt nicht mit dem aktiven Context überein.', 1;
        IF @Actor IS NOT NULL AND ISNULL(@CurrentActor, N'') <> @Actor
            THROW 51424, N'Ein verschachtelter Begin-Aufruf darf Actor nicht ändern.', 1;
        IF @Tenant IS NOT NULL AND ISNULL(@CurrentTenant, N'') <> @Tenant
            THROW 51425, N'Ein verschachtelter Begin-Aufruf darf Tenant nicht ändern.', 1;
        SET @ExecutionId = @CurrentExecutionId;
        DECLARE @NewDepth int = @CurrentDepth + 1;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=@NewDepth;
    END;

    IF @Debug > 0
        RAISERROR(N'USP_BeginExecution: Execution Context ist aktiv.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
