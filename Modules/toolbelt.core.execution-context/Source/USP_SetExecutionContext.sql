SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_SetExecutionContext]
(
      @ExpectedExecutionId uniqueidentifier
    , @CorrelationId       uniqueidentifier = NULL
    , @Actor               nvarchar(256)    = NULL
    , @Tenant              nvarchar(256)    = NULL
    , @ClearActor          bit              = 0
    , @ClearTenant         bit              = 0
    , @Debug               tinyint          = 0
    , @Hilfe               bit              = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @ClearActor = ISNULL(@ClearActor, 0);
    SET @ClearTenant = ISNULL(@ClearTenant, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_SetExecutionContext' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: in derselben Session zuvor USP_BeginExecution aufrufen.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id, @Actor=N''Contoso example'', @Tenant=N''Fabrikam'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@ExpectedExecutionId', N'uniqueidentifier', 1, 0, NULL, CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@CorrelationId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL (Default) erhält die bisherige CorrelationId; eine explizite ID ersetzt sie. Es gibt hier kein Correlation-Clear-Flag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Actor', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearActor=1 verwenden; Actor muss dann NULL sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Tenant', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Text nvarchar(256): NULL (Default) bedeutet nicht ändern, leerer Text setzt einen leeren Wert. Zum Löschen ClearTenant=1 verwenden; Tenant muss dann NULL sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ClearActor', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 erhält den Actor bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Actor aus dem Sessionkontext. Bei 1 darf Actor auch nicht als Leertext übergeben werden, sondern muss NULL sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ClearTenant', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 erhält den Tenant bzw. erlaubt dessen expliziten Ersatz (Default/NULL); 1 entfernt den Tenant. Bei 1 muss Tenant NULL sein, auch Leertext ist ein Konflikt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    IF @CurrentExecutionId IS NULL
        THROW 51426, N'In dieser Session ist kein Execution Context aktiv.', 1;
    IF @ExpectedExecutionId IS NULL OR @ExpectedExecutionId <> @CurrentExecutionId
        THROW 51427, N'@ExpectedExecutionId stimmt nicht mit dem aktiven Context überein.', 1;
    IF @ClearActor = 1 AND @Actor IS NOT NULL
        THROW 51428, N'@Actor und @ClearActor dürfen nicht gleichzeitig gesetzt sein.', 1;
    IF @ClearTenant = 1 AND @Tenant IS NOT NULL
        THROW 51429, N'@Tenant und @ClearTenant dürfen nicht gleichzeitig gesetzt sein.', 1;

    IF @CorrelationId IS NOT NULL
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=@CorrelationId;
    IF @ClearActor = 1
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=NULL;
    ELSE IF @Actor IS NOT NULL
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=@Actor;
    IF @ClearTenant = 1
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=NULL;
    ELSE IF @Tenant IS NOT NULL
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=@Tenant;

    IF @Debug > 0
        RAISERROR(N'USP_SetExecutionContext: Execution Context wurde aktualisiert.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
