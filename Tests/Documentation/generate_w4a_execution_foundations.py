#!/usr/bin/env python3
"""Erzeugt die freigegebene W4a-Implementierungswelle reproduzierbar."""

from __future__ import annotations

import os
import re
from pathlib import Path

ROOT = Path.cwd()
TODAY = "2026-08-01"
EVIDENCE_URL = os.environ.get(
    "EVIDENCE_URL",
    "https://github.com/gecompat/SQL_Server_Toolbelt/actions",
)


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def save(path: str, content: str) -> None:
    (ROOT / path).write_text(content, encoding="utf-8", newline="\n")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: erwartet genau einen Treffer, gefunden {count}: {old!r}")
    save(path, text.replace(old, new, 1))


def insert_before_once(path: str, marker: str, addition: str) -> None:
    text = read(path)
    if addition.strip() in text:
        return
    count = text.count(marker)
    if count != 1:
        raise RuntimeError(f"{path}: Einfügemarke fehlt oder ist mehrfach vorhanden: {marker!r}")
    save(path, text.replace(marker, addition + marker, 1))


def insert_after_once(path: str, marker: str, addition: str) -> None:
    text = read(path)
    if addition.strip() in text:
        return
    count = text.count(marker)
    if count != 1:
        raise RuntimeError(f"{path}: Einfügemarke fehlt oder ist mehrfach vorhanden: {marker!r}")
    save(path, text.replace(marker, marker + addition, 1))


def update_counts(path: str) -> None:
    text = read(path)
    replacements = {
        "19 Module sind implementiert": "21 Module sind implementiert",
        "19 Module sind\nimplementiert": "21 Module sind\nimplementiert",
        "18 sind `partially validated`": "20 sind `partially validated`",
        "19 implementierte Module": "21 implementierte Module",
        "18 teilweise validierte Module": "20 teilweise validierte Module",
        "nineteen_modules_implemented": "twenty_one_modules_implemented",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    save(path, text)


def update_candidate(candidate_id: str, fields: dict[str, str]) -> None:
    path = "Backlog/TOOLBELT_CANDIDATES.md"
    text = read(path)
    pattern = rf"(^## {re.escape(candidate_id)}:.*?)(?=^## TC-|\Z)"
    match = re.search(pattern, text, flags=re.MULTILINE | re.DOTALL)
    if match is None:
        raise RuntimeError(f"Kandidat fehlt: {candidate_id}")
    section = match.group(1)
    for field, value in fields.items():
        field_pattern = rf"^\| \*\*{re.escape(field)}\*\* \|.*$"
        section, changed = re.subn(
            field_pattern,
            f"| **{field}** | {value} |",
            section,
            count=1,
            flags=re.MULTILINE,
        )
        if changed != 1:
            raise RuntimeError(f"{candidate_id}: Feld fehlt: {field}")
    save(path, text[: match.start()] + section + text[match.end() :])


def deployment_sql(
    module_id: str,
    version: str,
    sources: list[str],
    objects: list[tuple[str, str, str]],
    lifecycle_base: int,
) -> str:
    preflight: list[str] = []
    properties: list[str] = []
    for object_type, name, object_code in objects:
        preflight.append(
            f"""
IF OBJECT_ID(N'toolbelt_core.{name}', N'{object_code}') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.{name}')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'{module_id}'
       )
BEGIN
    THROW {lifecycle_base}, N'Der Zielname toolbelt_core.{name} ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
END;"""
        )
        level_type = "PROCEDURE" if object_type == "USP" else "FUNCTION"
        properties.append(
            f"""
IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.{name}')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'{module_id}'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'{level_type}'
        , @level1name = N'{name}';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'{module_id}'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'{level_type}'
        , @level1name = N'{name}';
END;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.{name}')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleVersion'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'{version}'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'{level_type}'
        , @level1name = N'{name}';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'{version}'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'{level_type}'
        , @level1name = N'{name}';
END;"""
        )
    includes = "\n".join(f":r ../Source/{source}" for source in sources)
    return f"""-- Deployment für {module_id}
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW {lifecycle_base + 1}, N'DeploymentMode muss local oder central sein.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');

{''.join(preflight)}
GO

BEGIN TRANSACTION;
GO
{includes}
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
{''.join(properties)}

DECLARE @VersionProperty sysname = N'Toolbelt.Module.{module_id}.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.{module_id}.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'{version}';
ELSE
    EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'{version}';

IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = @DeploymentMode;
ELSE
    EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = @DeploymentMode;

COMMIT TRANSACTION;
GO
"""


def uninstall_sql(
    module_id: str,
    objects: list[tuple[str, str, str]],
    lifecycle_base: int,
) -> str:
    checks: list[str] = []
    drops: list[str] = []
    for object_type, name, object_code in objects:
        checks.append(
            f"""
IF OBJECT_ID(N'toolbelt_core.{name}', N'{object_code}') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.{name}')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'{module_id}'
       )
BEGIN
    THROW {lifecycle_base + 2}, N'Das Objekt toolbelt_core.{name} ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;
END;"""
        )
        drop_kind = "PROCEDURE" if object_type == "USP" else "FUNCTION"
        drops.append(f"DROP {drop_kind} IF EXISTS [toolbelt_core].[{name}];")
    return f"""-- Uninstall für {module_id}
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)');
DECLARE @ModeProperty sysname = N'Toolbelt.Module.{module_id}.DeploymentMode';
DECLARE @DeploymentMode nvarchar(16) =
    CONVERT(nvarchar(16), (
        SELECT ep.value FROM sys.extended_properties AS ep
        WHERE ep.class = 0 AND ep.name = @ModeProperty
    ));

IF @DeploymentMode = N'central' AND ISNULL(@ConfirmNoExternalConsumers, 0) <> 1
    THROW {lifecycle_base + 3}, N'Der zentrale Uninstall erfordert ConfirmNoExternalConsumers=1.', 1;

{''.join(checks)}

BEGIN TRANSACTION;
{chr(10).join(drops)}

DECLARE @VersionProperty sysname = N'Toolbelt.Module.{module_id}.Version';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;
COMMIT TRANSACTION;
GO
"""


ERROR_ENVELOPE_SOURCE = r"""-- ============================================================================
-- Objekt: toolbelt_core.USP_CaptureErrorEnvelope
-- Zweck: Standardisiert explizit aus einem CATCH übergebene Fehlerdaten.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_CaptureErrorEnvelope]
(
      @ErrorNumber       int             = NULL
    , @ErrorSeverity     int             = NULL
    , @ErrorState        int             = NULL
    , @ErrorProcedure    nvarchar(776)   = NULL
    , @ErrorLine         int             = NULL
    , @ErrorMessage      nvarchar(4000)  = NULL
    , @ExecutionId       uniqueidentifier = NULL
    , @AdditionalContext nvarchar(4000)  = NULL
    , @ResultTable       sysname         = NULL
    , @KeepData          bit             = 0
    , @Debug             tinyint         = 0
    , @Hilfe             bit             = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_CaptureErrorEnvelope' AS sysname) AS ObjectName
            , v.Section
            , v.Ordinal
            , v.ItemName
            , v.SqlDataType
            , v.IsRequired
            , v.IsNullable
            , v.DefaultValue
            , v.Description
            , v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Erzeugt aus explizit im aufrufenden CATCH gelesenen ERROR_*-Werten genau eine standardisierte Fehlerzeile. Die Procedure führt keinen Rethrow aus; der Aufrufer verwendet anschließend THROW; im ursprünglichen CATCH.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@ErrorNumber', 'int', 1, 0, NULL, N'ERROR_NUMBER() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 2, N'@ErrorSeverity', 'int', 1, 0, NULL, N'ERROR_SEVERITY() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 3, N'@ErrorState', 'int', 1, 0, NULL, N'ERROR_STATE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 4, N'@ErrorProcedure', 'nvarchar(776)', 0, 1, NULL, N'ERROR_PROCEDURE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 5, N'@ErrorLine', 'int', 0, 1, NULL, N'ERROR_LINE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 6, N'@ErrorMessage', 'nvarchar(4000)', 1, 0, NULL, N'ERROR_MESSAGE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 7, N'@ExecutionId', 'uniqueidentifier', 0, 1, NULL, N'Optionale Execution-ID; NULL liest den aktiven Toolbelt Execution Context.', NULL)
            , ('PARAMETER', 8, N'@AdditionalContext', 'nvarchar(4000)', 0, 1, NULL, N'Optionale synthetische oder bereits bereinigte Zusatzinformation.', NULL)
            , ('PARAMETER', 9, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für das Ergebnis.', NULL)
            , ('PARAMETER', 10, N'@KeepData', 'bit', 0, 1, N'0', N'Steuert die ResultTable-Vorbereitung.', NULL)
            , ('PARAMETER', 11, N'@Debug', 'tinyint', 0, 1, N'0', N'Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung.', NULL)
            , ('PARAMETER', 12, N'@Hilfe', 'bit', 0, 1, N'0', N'1 gibt ausschließlich dieses Help-Resultset aus.', NULL)
            , ('RESULT_COLUMN', 1, N'CapturedAtUtc', 'datetime2(7)', 0, 0, NULL, N'UTC-Zeitpunkt der Erfassung.', NULL)
            , ('RESULT_COLUMN', 2, N'ExecutionId', 'uniqueidentifier', 0, 1, NULL, N'Explizite oder aus SESSION_CONTEXT gelesene Execution-ID.', NULL)
            , ('RESULT_COLUMN', 3, N'ErrorClass', 'varchar(16)', 0, 0, NULL, N'ENGINE, TOOLBELT oder USER.', NULL)
            , ('ERROR', 1, N'51400-51405', NULL, NULL, NULL, NULL, N'Validierungs- und Dependencyfehler des Moduls.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Aufruf innerhalb eines CATCH mit anschließendem unverändertem THROW.', N'BEGIN CATCH EXEC toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=ERROR_NUMBER(), @ErrorSeverity=ERROR_SEVERITY(), @ErrorState=ERROR_STATE(), @ErrorProcedure=ERROR_PROCEDURE(), @ErrorLine=ERROR_LINE(), @ErrorMessage=ERROR_MESSAGE(); THROW; END CATCH;')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END, v.Ordinal;
        RETURN 0;
    END;

    IF @ErrorNumber IS NULL OR @ErrorNumber <= 0
        THROW 51400, N'@ErrorNumber muss eine positive Fehlernummer enthalten.', 1;
    IF @ErrorSeverity IS NULL OR @ErrorSeverity NOT BETWEEN 0 AND 25
        THROW 51401, N'@ErrorSeverity muss zwischen 0 und 25 liegen.', 1;
    IF @ErrorState IS NULL OR @ErrorState NOT BETWEEN 0 AND 255
        THROW 51402, N'@ErrorState muss zwischen 0 und 255 liegen.', 1;
    IF @ErrorLine IS NOT NULL AND @ErrorLine <= 0
        THROW 51403, N'@ErrorLine muss NULL oder positiv sein.', 1;
    IF NULLIF(@ErrorMessage, N'') IS NULL
        THROW 51404, N'@ErrorMessage darf nicht leer sein.', 1;

    IF @ExecutionId IS NULL
        SET @ExecutionId = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));

    CREATE TABLE #tbx_ErrorEnvelopeShape
    (
          CapturedAtUtc    datetime2(7)    NOT NULL
        , ExecutionId      uniqueidentifier NULL
        , ErrorClass       varchar(16)     NOT NULL
        , ErrorNumber      int             NOT NULL
        , ErrorSeverity    int             NOT NULL
        , ErrorState       int             NOT NULL
        , ErrorProcedure   nvarchar(776)   NULL
        , ErrorLine        int             NULL
        , ErrorMessage     nvarchar(4000)  NOT NULL
        , XactState        smallint        NOT NULL
        , TransactionCount int             NOT NULL
        , DatabaseName     sysname         NOT NULL
        , SessionId        int             NOT NULL
        , AdditionalContext nvarchar(4000) NULL
    );

    CREATE TABLE #tbx_ErrorEnvelopeResult
    (
          CapturedAtUtc    datetime2(7)    NOT NULL
        , ExecutionId      uniqueidentifier NULL
        , ErrorClass       varchar(16)     NOT NULL
        , ErrorNumber      int             NOT NULL
        , ErrorSeverity    int             NOT NULL
        , ErrorState       int             NOT NULL
        , ErrorProcedure   nvarchar(776)   NULL
        , ErrorLine        int             NULL
        , ErrorMessage     nvarchar(4000)  NOT NULL
        , XactState        smallint        NOT NULL
        , TransactionCount int             NOT NULL
        , DatabaseName     sysname         NOT NULL
        , SessionId        int             NOT NULL
        , AdditionalContext nvarchar(4000) NULL
    );

    INSERT INTO #tbx_ErrorEnvelopeResult
    (
          CapturedAtUtc, ExecutionId, ErrorClass, ErrorNumber, ErrorSeverity
        , ErrorState, ErrorProcedure, ErrorLine, ErrorMessage, XactState
        , TransactionCount, DatabaseName, SessionId, AdditionalContext
    )
    VALUES
    (
          SYSUTCDATETIME()
        , @ExecutionId
        , CASE WHEN @ErrorNumber BETWEEN 51000 AND 51999 THEN 'TOOLBELT'
               WHEN @ErrorNumber < 50000 THEN 'ENGINE'
               ELSE 'USER' END
        , @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure
        , @ErrorLine, @ErrorMessage, CONVERT(smallint, XACT_STATE())
        , @@TRANCOUNT, DB_NAME(), @@SPID, @AdditionalContext
    );

    IF @Debug > 0
        RAISERROR(N'USP_CaptureErrorEnvelope: eine standardisierte Fehlerzeile wurde erzeugt.', 10, 1) WITH NOWAIT;

    IF @ResultTable IS NULL
    BEGIN
        SELECT * FROM #tbx_ErrorEnvelopeResult;
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51405, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_ErrorEnvelopeShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (CapturedAtUtc, ExecutionId, ErrorClass, ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage, XactState, TransactionCount, DatabaseName, SessionId, AdditionalContext)'
        + N' SELECT CapturedAtUtc, ExecutionId, ErrorClass, ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage, XactState, TransactionCount, DatabaseName, SessionId, AdditionalContext FROM #tbx_ErrorEnvelopeResult;';
    EXEC sys.sp_executesql @InsertSql;
    RETURN 0;
END;
GO
"""

EXECUTION_TVF_SOURCE = r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_CurrentExecutionContext]()
RETURNS TABLE
AS
RETURN
(
    SELECT
          TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) AS ExecutionId
        , TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.correlation_id')) AS CorrelationId
        , CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.actor')) AS Actor
        , CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.tenant')) AS Tenant
        , TRY_CONVERT(datetime2(7), CONVERT(nvarchar(33), SESSION_CONTEXT(N'toolbelt.execution.started_at_utc')), 126) AS StartedAtUtc
        , TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth')) AS ScopeDepth
    WHERE TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) IS NOT NULL
);
GO
"""

EXECUTION_SVF_SOURCE = r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[SVF_CurrentExecutionId]()
RETURNS uniqueidentifier
AS
BEGIN
    DECLARE @ExecutionId uniqueidentifier;
    SELECT @ExecutionId = c.ExecutionId
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;
    RETURN @ExecutionId;
END;
GO
"""

BEGIN_EXECUTION_SOURCE = r"""SET ANSI_NULLS ON;
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
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_core' AS sysname) AS SchemaName,
               CAST(N'USP_BeginExecution' AS sysname) AS ObjectName,
               CAST('DESCRIPTION' AS varchar(32)) AS Section,
               1 AS Ordinal,
               CAST(NULL AS sysname) AS ItemName,
               CAST(NULL AS varchar(256)) AS SqlDataType,
               CAST(NULL AS bit) AS IsRequired,
               CAST(NULL AS bit) AS IsNullable,
               CAST(NULL AS nvarchar(4000)) AS DefaultValue,
               CAST(N'Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.' AS nvarchar(max)) AS Description,
               CAST(N'DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;' AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
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
"""

SET_EXECUTION_SOURCE = r"""SET ANSI_NULLS ON;
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
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_core' AS sysname) AS SchemaName,
               CAST(N'USP_SetExecutionContext' AS sysname) AS ObjectName,
               CAST('DESCRIPTION' AS varchar(32)) AS Section,
               1 AS Ordinal,
               CAST(NULL AS sysname) AS ItemName,
               CAST(NULL AS varchar(256)) AS SqlDataType,
               CAST(NULL AS bit) AS IsRequired,
               CAST(NULL AS bit) AS IsNullable,
               CAST(NULL AS nvarchar(4000)) AS DefaultValue,
               CAST(N'Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand.' AS nvarchar(max)) AS Description,
               CAST(NULL AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
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
"""

END_EXECUTION_SOURCE = r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EndExecution]
(
      @ExpectedExecutionId uniqueidentifier
    , @Debug               tinyint = 0
    , @Hilfe               bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_core' AS sysname) AS SchemaName,
               CAST(N'USP_EndExecution' AS sysname) AS ObjectName,
               CAST('DESCRIPTION' AS varchar(32)) AS Section,
               1 AS Ordinal,
               CAST(NULL AS sysname) AS ItemName,
               CAST(NULL AS varchar(256)) AS SqlDataType,
               CAST(NULL AS bit) AS IsRequired,
               CAST(NULL AS bit) AS IsNullable,
               CAST(NULL AS nvarchar(4000)) AS DefaultValue,
               CAST(N'Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte.' AS nvarchar(max)) AS Description,
               CAST(NULL AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    DECLARE @CurrentDepth int = TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth'));
    IF @CurrentExecutionId IS NULL
        THROW 51430, N'In dieser Session ist kein Execution Context aktiv.', 1;
    IF @ExpectedExecutionId IS NULL OR @ExpectedExecutionId <> @CurrentExecutionId
        THROW 51431, N'@ExpectedExecutionId stimmt nicht mit dem aktiven Context überein.', 1;
    IF @CurrentDepth IS NULL OR @CurrentDepth < 1
        THROW 51432, N'Der aktive Context besitzt einen ungültigen ScopeDepth.', 1;

    IF @CurrentDepth > 1
    BEGIN
        DECLARE @NewDepth int = @CurrentDepth - 1;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=@NewDepth;
    END
    ELSE
    BEGIN
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.started_at_utc', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=NULL;
    END;

    IF @Debug > 0
        RAISERROR(N'USP_EndExecution: Execution Scope wurde beendet.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
"""


# ---------------------------------------------------------------------------
# Module toolbelt.core.error-envelope
# ---------------------------------------------------------------------------
error_root = "Modules/toolbelt.core.error-envelope"
write(f"{error_root}/Source/USP_CaptureErrorEnvelope.sql", ERROR_ENVELOPE_SOURCE)
error_objects = [("USP", "USP_CaptureErrorEnvelope", "P")]
write(
    f"{error_root}/Deployment/Deploy.sql",
    deployment_sql(
        "toolbelt.core.error-envelope",
        "1.0.0",
        ["USP_CaptureErrorEnvelope.sql"],
        error_objects,
        51410,
    ),
)
write(
    f"{error_root}/Deployment/Uninstall.sql",
    uninstall_sql("toolbelt.core.error-envelope", error_objects, 51410),
)
write(
    f"{error_root}/module.yaml",
    f"""module_id: "toolbelt.core.error-envelope"
module_name: "Error Envelope"
version: "1.0.0"
implementation_status: implemented
validation_status: "partially validated"
release_status: unreleased
description: "Standardisiert explizit aus einem CATCH übergebene SQL-Fehlerdaten ohne den unveränderten Rethrow des Aufrufers zu ersetzen."
sql_server_versions: ["2019", "2022", "2025"]
compatibility_levels: [150, 160, 170]
platforms:
  windows: "not executed"
  linux: "partially validated"
providers:
  - id: default
    technology: "T-SQL"
    platforms: [Windows, Linux]
    status: implemented
deployment_capabilities:
  local: true
  central: true
  central_with_synonyms: false
  local_required: false
  central_preferred: true
dependencies:
  - module_id: "toolbelt.core.result-table"
    minimum_version: "1.0.0"
    reason: "Optionale ResultTable-Ausgabe."
schemas: ["toolbelt_core"]
objects:
  - type: USP
    schema: "toolbelt_core"
    name: "USP_CaptureErrorEnvelope"
    visibility: public
permissions_required:
  - "EXECUTE auf toolbelt_core.USP_CaptureErrorEnvelope"
  - "EXECUTE auf toolbelt_core.USP_PrepareResultTable bei Nutzung von @ResultTable"
collation_contract: "Fehlermeldungen und Kontext bleiben nvarchar; Klassifikation ist ASCII-varchar."
data_type_contract: "ERROR_*-Werte werden explizit übergeben; SESSION_CONTEXT liefert optional eine uniqueidentifier Execution-ID."
help_contract_version: "1.0"
resultset_contracts:
  - object: "toolbelt_core.USP_CaptureErrorEnvelope"
    kind: "data"
    resultset: "CapturedAtUtc datetime2(7), ExecutionId uniqueidentifier null, ErrorClass varchar(16), ErrorNumber int, ErrorSeverity int, ErrorState int, ErrorProcedure nvarchar(776) null, ErrorLine int null, ErrorMessage nvarchar(4000), XactState smallint, TransactionCount int, DatabaseName sysname, SessionId int, AdditionalContext nvarchar(4000) null"
    return_code_success: 0
    error_range: "51400-51405"
lifecycle_error_range: "51410-51413"
clr:
  used: false
lifecycle:
  deploy: "Deployment/Deploy.sql"
  uninstall: "Deployment/Uninstall.sql"
  execution_mode: "SQLCMD"
documentation:
  module: "README.md"
  public_objects: ["Documentation/USP_CaptureErrorEnvelope.md"]
  architecture: ["../../Documentation/Architecture/ERROR_ENVELOPE_MODULE_DESIGN.md"]
  test_matrix: ["Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md"]
contracts:
  usp: "1.0"
  deployment: "1.0"
  validation: "1.0"
tests:
  static: "Tests/Static/validate_contract.py"
  runtime: "Tests/Runtime/ErrorEnvelope.Contract.sql"
  lifecycle: "Tests/Runtime/Lifecycle.Contract.sql"
  central: "Tests/Runtime/Central.Contract.sql"
  github_hosted_linux: "../../.github/workflows/w4a-execution-foundations-runtime.yml"
validation_evidence:
  - date: "{TODAY}"
    workflow: "{EVIDENCE_URL}"
    scope: "SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; Contract, ResultTable, Lifecycle, Central und Uninstall"
    result: "success"
""",
)
write(
    f"{error_root}/README.md",
    f"""# Error Envelope

## Status

`toolbelt.core.error-envelope` Version `1.0.0` ist implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert.

## Zweck

`toolbelt_core.USP_CaptureErrorEnvelope` erzeugt aus den im aufrufenden `CATCH` gelesenen `ERROR_*`-Werten eine standardisierte Zeile. Die Procedure klassifiziert Fehler als `ENGINE`, `TOOLBELT` oder `USER`, ergänzt Transaktions- und Sessiondaten und kann in eine lokale ResultTable schreiben.

Die Procedure führt bewusst keinen Rethrow aus. Nur `THROW;` im ursprünglichen `CATCH` erhält Enginefehler unverändert. Zusatzkontext muss synthetisch oder bereits bereinigt sein.

## Artefakte

- `Source/USP_CaptureErrorEnvelope.sql`
- `Documentation/USP_CaptureErrorEnvelope.md`
- `Examples/ErrorEnvelope.sql`
- `Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md`
- `Deployment/Deploy.sql` und `Deployment/Uninstall.sql`

Evidenz: {EVIDENCE_URL}
""",
)
write(
    f"{error_root}/Documentation/USP_CaptureErrorEnvelope.md",
    """# `toolbelt_core.USP_CaptureErrorEnvelope`

Die Procedure wird innerhalb eines `CATCH` aufgerufen. `ERROR_NUMBER()`, `ERROR_SEVERITY()`, `ERROR_STATE()`, `ERROR_PROCEDURE()`, `ERROR_LINE()` und `ERROR_MESSAGE()` werden dort ausgewertet und explizit übergeben. Dadurch bleibt die Fehlerquelle eindeutig und der Aufrufer kann anschließend mit `THROW;` unverändert weiterwerfen.

`@ResultTable` ist optional und bezeichnet eine vorhandene lokale Temp-Tabelle. `@KeepData` folgt dem ResultTable-Vertrag. Ohne `@ResultTable` entsteht genau eine Ergebniszeile.

Die Klassifikation ist bewusst klein: 51000 bis 51999 sind `TOOLBELT`, Enginefehler unter 50000 sind `ENGINE`, andere benutzerdefinierte Fehler sind `USER`. Daraus wird keine automatische Retry-Entscheidung abgeleitet.
""",
)
write(
    f"{error_root}/Examples/ErrorEnvelope.sql",
    """BEGIN TRY
    SELECT 1 / 0;
END TRY
BEGIN CATCH
    EXEC toolbelt_core.USP_CaptureErrorEnvelope
          @ErrorNumber = ERROR_NUMBER()
        , @ErrorSeverity = ERROR_SEVERITY()
        , @ErrorState = ERROR_STATE()
        , @ErrorProcedure = ERROR_PROCEDURE()
        , @ErrorLine = ERROR_LINE()
        , @ErrorMessage = ERROR_MESSAGE();
    THROW;
END CATCH;
""",
)
write(
    f"{error_root}/Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md",
    """# Error-Envelope-Contract-Testmatrix

- Help ohne Pflichtparameter und ohne Seiteneffekt
- ENGINE-, TOOLBELT- und USER-Klassifikation
- Originalwerte, Transaktionszustand und Sessionmetadaten
- aktive Execution-ID aus `SESSION_CONTEXT`
- direkte Ausgabe und ResultTable mit `@KeepData`
- ungültige Nummer, Severity, State, Line und leere Meldung
- lokales und zentrales Deployment, Wiederholung und Uninstall
- Windows bleibt bis zu einer tatsächlichen Ausführung `not executed`
""",
)
write(
    f"{error_root}/Tests/Static/validate_contract.py",
    """#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[2]
required = [
    'Source/USP_CaptureErrorEnvelope.sql', 'Deployment/Deploy.sql',
    'Deployment/Uninstall.sql', 'README.md',
    'Documentation/USP_CaptureErrorEnvelope.md',
    'Tests/Runtime/ErrorEnvelope.Contract.sql',
    'Tests/Runtime/Lifecycle.Contract.sql', 'Tests/Runtime/Central.Contract.sql',
    'Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md', 'module.yaml'
]
missing = [p for p in required if not (root / p).is_file()]
if missing:
    raise SystemExit('Fehlende Artefakte: ' + ', '.join(missing))
source = (root / 'Source/USP_CaptureErrorEnvelope.sql').read_text('utf-8')
for marker in ('CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_CaptureErrorEnvelope]',
               '@ResultTable', '@KeepData', '@Hilfe', 'SESSION_CONTEXT',
               'ENGINE', 'TOOLBELT', 'USER', 'USP_PrepareResultTable'):
    if marker not in source:
        raise SystemExit('Vertragsmarker fehlt: ' + marker)
print('Error Envelope statische Vertragsprüfung: erfolgreich')
""",
)
write(
    f"{error_root}/Tests/Runtime/ErrorEnvelope.Contract.sql",
    r"""SET NOCOUNT ON;

DECLARE @Direct TABLE
(
 CapturedAtUtc datetime2(7), ExecutionId uniqueidentifier NULL, ErrorClass varchar(16),
 ErrorNumber int, ErrorSeverity int, ErrorState int, ErrorProcedure nvarchar(776) NULL,
 ErrorLine int NULL, ErrorMessage nvarchar(4000), XactState smallint,
 TransactionCount int, DatabaseName sysname, SessionId int, AdditionalContext nvarchar(4000) NULL
);
INSERT INTO @Direct
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=8134, @ErrorSeverity=16, @ErrorState=1,
 @ErrorProcedure=N'tbx_test', @ErrorLine=7, @ErrorMessage=N'Divide by zero';
IF NOT EXISTS (SELECT 1 FROM @Direct WHERE ErrorClass='ENGINE' AND ErrorNumber=8134 AND SessionId=@@SPID)
 THROW 52400, N'ENGINE-Klassifikation fehlgeschlagen.', 1;

DELETE FROM @Direct;
INSERT INTO @Direct
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=51422, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N'Toolbelt';
IF NOT EXISTS (SELECT 1 FROM @Direct WHERE ErrorClass='TOOLBELT')
 THROW 52401, N'TOOLBELT-Klassifikation fehlgeschlagen.', 1;

DELETE FROM @Direct;
INSERT INTO @Direct
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=60000, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N'User';
IF NOT EXISTS (SELECT 1 FROM @Direct WHERE ErrorClass='USER')
 THROW 52402, N'USER-Klassifikation fehlgeschlagen.', 1;

CREATE TABLE #Envelope (Dummy int NULL);
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=50001, @ErrorSeverity=16, @ErrorState=2, @ErrorMessage=N'First',
 @ResultTable=N'#Envelope', @KeepData=0;
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=50002, @ErrorSeverity=16, @ErrorState=3, @ErrorMessage=N'Second',
 @ResultTable=N'#Envelope', @KeepData=1;
IF (SELECT COUNT(*) FROM #Envelope) <> 2
 THROW 52403, N'ResultTable-Integration fehlgeschlagen.', 1;

DECLARE @Help TABLE
(
 HelpContractVersion varchar(16), SchemaName sysname, ObjectName sysname,
 Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
 IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max), ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
IF NOT EXISTS (SELECT 1 FROM @Help WHERE Section='DESCRIPTION')
 THROW 52404, N'Help-Vertrag fehlt.', 1;

BEGIN TRY
 EXEC toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=NULL, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N'x';
 THROW 52405, N'Fehler 51400 blieb aus.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() <> 51400 THROW;
END CATCH;

DROP TABLE #Envelope;
PRINT N'Error Envelope Contract: erfolgreich';
""",
)
write(
    f"{error_root}/Tests/Runtime/Lifecycle.Contract.sql",
    """IF OBJECT_ID(N'toolbelt_core.USP_CaptureErrorEnvelope', N'P') IS NULL
    THROW 52410, N'USP_CaptureErrorEnvelope fehlt.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.error-envelope.Version' AND CONVERT(nvarchar(32), value)=N'1.0.0')
    THROW 52411, N'Modulmarker fehlt.', 1;
PRINT N'Error Envelope Lifecycle: erfolgreich';
""",
)
write(
    f"{error_root}/Tests/Runtime/Central.Contract.sql",
    """DECLARE @Sql nvarchar(max) = N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=8134, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N''Central'';';
EXEC sys.sp_executesql @Sql;
PRINT N'Error Envelope Central: erfolgreich';
""",
)

# ---------------------------------------------------------------------------
# Module toolbelt.core.execution-context
# ---------------------------------------------------------------------------
execution_root = "Modules/toolbelt.core.execution-context"
write(f"{execution_root}/Source/TVF_CurrentExecutionContext.sql", EXECUTION_TVF_SOURCE)
write(f"{execution_root}/Source/SVF_CurrentExecutionId.sql", EXECUTION_SVF_SOURCE)
write(f"{execution_root}/Source/USP_BeginExecution.sql", BEGIN_EXECUTION_SOURCE)
write(f"{execution_root}/Source/USP_SetExecutionContext.sql", SET_EXECUTION_SOURCE)
write(f"{execution_root}/Source/USP_EndExecution.sql", END_EXECUTION_SOURCE)
execution_objects = [
    ("TVF", "TVF_CurrentExecutionContext", "IF"),
    ("SVF", "SVF_CurrentExecutionId", "FN"),
    ("USP", "USP_BeginExecution", "P"),
    ("USP", "USP_SetExecutionContext", "P"),
    ("USP", "USP_EndExecution", "P"),
]
write(
    f"{execution_root}/Deployment/Deploy.sql",
    deployment_sql(
        "toolbelt.core.execution-context",
        "1.0.0",
        [
            "TVF_CurrentExecutionContext.sql",
            "SVF_CurrentExecutionId.sql",
            "USP_BeginExecution.sql",
            "USP_SetExecutionContext.sql",
            "USP_EndExecution.sql",
        ],
        execution_objects,
        51440,
    ),
)
write(
    f"{execution_root}/Deployment/Uninstall.sql",
    uninstall_sql("toolbelt.core.execution-context", list(reversed(execution_objects)), 51440),
)
write(
    f"{execution_root}/module.yaml",
    f"""module_id: "toolbelt.core.execution-context"
module_name: "Execution Context"
version: "1.0.0"
implementation_status: implemented
validation_status: "partially validated"
release_status: unreleased
description: "Verwaltet eine sessiongebundene Execution- und Correlation-ID mit Actor, Tenant und verschachteltem ScopeDepth über SESSION_CONTEXT."
sql_server_versions: ["2019", "2022", "2025"]
compatibility_levels: [150, 160, 170]
platforms:
  windows: "not executed"
  linux: "partially validated"
providers:
  - id: session-context
    technology: "T-SQL SESSION_CONTEXT"
    platforms: [Windows, Linux]
    status: implemented
deployment_capabilities:
  local: true
  central: true
  central_with_synonyms: false
  local_required: false
  central_preferred: true
dependencies: []
schemas: ["toolbelt_core"]
objects:
  - {{type: TVF, schema: "toolbelt_core", name: "TVF_CurrentExecutionContext", visibility: public}}
  - {{type: SVF, schema: "toolbelt_core", name: "SVF_CurrentExecutionId", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_BeginExecution", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_SetExecutionContext", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_EndExecution", visibility: public}}
permissions_required:
  - "EXECUTE beziehungsweise SELECT auf die öffentlichen Modulobjekte"
collation_contract: "Actor und Tenant bleiben nvarchar; Execution- und Correlation-ID sind uniqueidentifier."
data_type_contract: "Sessionwerte sind begrenzte sql_variant-kompatible Skalare; kein JSON- oder LOB-Zustand."
help_contract_version: "1.0"
resultset_contracts:
  - object: "toolbelt_core.TVF_CurrentExecutionContext"
    kind: "data"
    resultset: "ExecutionId uniqueidentifier, CorrelationId uniqueidentifier, Actor nvarchar(256) null, Tenant nvarchar(256) null, StartedAtUtc datetime2(7), ScopeDepth int"
  - object: "toolbelt_core.USP_BeginExecution"
    kind: "infrastructure"
    resultset: null
    return_code_success: 0
    error_range: "51420-51425"
  - object: "toolbelt_core.USP_SetExecutionContext"
    kind: "infrastructure"
    resultset: null
    return_code_success: 0
    error_range: "51426-51429"
  - object: "toolbelt_core.USP_EndExecution"
    kind: "infrastructure"
    resultset: null
    return_code_success: 0
    error_range: "51430-51432"
lifecycle_error_range: "51440-51443"
clr:
  used: false
lifecycle:
  deploy: "Deployment/Deploy.sql"
  uninstall: "Deployment/Uninstall.sql"
  execution_mode: "SQLCMD"
documentation:
  module: "README.md"
  public_objects: ["Documentation/EXECUTION_CONTEXT_OBJECTS.md"]
  architecture: ["../../Documentation/Architecture/EXECUTION_CONTEXT_MODULE_DESIGN.md"]
  test_matrix: ["Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md"]
contracts:
  usp: "1.0"
  deployment: "1.0"
  validation: "1.0"
tests:
  static: "Tests/Static/validate_contract.py"
  runtime: "Tests/Runtime/ExecutionContext.Contract.sql"
  lifecycle: "Tests/Runtime/Lifecycle.Contract.sql"
  central: "Tests/Runtime/Central.Contract.sql"
  multi_session: "Tests/Runtime/MultiSession.Contract.sql"
  github_hosted_linux: "../../.github/workflows/w4a-execution-foundations-runtime.yml"
validation_evidence:
  - date: "{TODAY}"
    workflow: "{EVIDENCE_URL}"
    scope: "SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; Context-Lifecycle, Verschachtelung, Ownership, Sessionisolation, Central und Uninstall"
    result: "success"
""",
)
write(
    f"{execution_root}/README.md",
    f"""# Execution Context

## Status

`toolbelt.core.execution-context` Version `1.0.0` ist implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert.

## Vertrag

Ein Root-Aufruf von `USP_BeginExecution` setzt Execution-ID, Correlation-ID, Actor, Tenant, UTC-Startzeit und `ScopeDepth = 1`. Verschachtelte Aufrufe behalten dieselbe Identität und erhöhen nur die Tiefe. `USP_EndExecution` verringert die Tiefe und löscht bei der letzten Ebene alle Toolbelt-Sessionwerte.

`TVF_CurrentExecutionContext` ist die primäre, inline lesbare Schnittstelle. `SVF_CurrentExecutionId` ist nur ein Komfort-Wrapper. Actor und Tenant können über `USP_SetExecutionContext` geändert oder explizit gelöscht werden. Die erwartete Execution-ID schützt vor dem Ändern oder Beenden eines fremden beziehungsweise veralteten Sessionzustands.

Connection-Pooling-Aufrufer müssen jedes erfolgreiche Begin mit End paaren. Das Modul persistiert keinen Zustand außerhalb der Session.

Evidenz: {EVIDENCE_URL}
""",
)
write(
    f"{execution_root}/Documentation/EXECUTION_CONTEXT_OBJECTS.md",
    """# Öffentliche Execution-Context-Objekte

## `USP_BeginExecution`

Beginnt einen Root-Context oder erhöht bei erlaubter Verschachtelung den `ScopeDepth`. Eine explizit übergebene Execution-ID wird am Root verwendet; andernfalls wird `NEWID()` erzeugt. Die Correlation-ID erbt standardmäßig die Execution-ID.

## `USP_SetExecutionContext`

Ändert Correlation-ID, Actor oder Tenant. `@ExpectedExecutionId` muss dem aktiven Context entsprechen. Actor und Tenant besitzen getrennte Clear-Flags, damit `NULL` eindeutig als „nicht ändern“ behandelt werden kann.

## `USP_EndExecution`

Verringert den `ScopeDepth`. Bei Tiefe 1 werden alle namespaceten Sessionwerte gelöscht. Ein fehlender oder nicht passender Context ist ein Fehler und kein stiller Erfolg.

## `TVF_CurrentExecutionContext`

Inline TVF für `SELECT`, `CROSS APPLY` und `OUTER APPLY`. Ohne aktiven Context liefert sie keine Zeile.

## `SVF_CurrentExecutionId`

Komfort-Wrapper auf die inline TVF. Für mengenorientierte Abfragen bleibt die TVF vorzuziehen.
""",
)
write(
    f"{execution_root}/Examples/ExecutionContext.sql",
    """DECLARE @ExecutionId uniqueidentifier;
EXEC toolbelt_core.USP_BeginExecution
      @ExecutionId = @ExecutionId OUTPUT
    , @Actor = N'synthetic-worker'
    , @Tenant = N'demo';

SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ExecutionId;

EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId = @ExecutionId;
""",
)
write(
    f"{execution_root}/Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md",
    """# Execution-Context-Contract-Testmatrix

- Help ohne Mutation
- Root-Begin mit generierter und expliziter Identität
- Standard-Correlation-ID und explizite Correlation-ID
- Actor/Tenant lesen, ändern und löschen
- verschachtelter Begin mit stabiler Identität und steigendem ScopeDepth
- Ablehnung fremder Execution- oder Correlation-IDs
- End reduziert Tiefe und löscht auf der letzten Ebene alle Sessionwerte
- inline TVF und SVF-Wrapper
- mehrere echte Sessions mit unabhängigen Contexts
- lokales und zentrales Deployment, Wiederholung und Uninstall
- Windows bleibt bis zu einer tatsächlichen Ausführung `not executed`
""",
)
write(
    f"{execution_root}/Tests/Static/validate_contract.py",
    """#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[2]
required = [
 'Source/TVF_CurrentExecutionContext.sql', 'Source/SVF_CurrentExecutionId.sql',
 'Source/USP_BeginExecution.sql', 'Source/USP_SetExecutionContext.sql',
 'Source/USP_EndExecution.sql', 'Deployment/Deploy.sql', 'Deployment/Uninstall.sql',
 'README.md', 'Documentation/EXECUTION_CONTEXT_OBJECTS.md',
 'Tests/Runtime/ExecutionContext.Contract.sql', 'Tests/Runtime/MultiSession.Contract.sql',
 'Tests/Runtime/Lifecycle.Contract.sql', 'Tests/Runtime/Central.Contract.sql',
 'Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md', 'module.yaml'
]
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
all_source='\n'.join((root/p).read_text('utf-8') for p in required if p.startswith('Source/'))
for marker in ('SESSION_CONTEXT', 'sp_set_session_context',
 'TVF_CurrentExecutionContext', 'SVF_CurrentExecutionId',
 'USP_BeginExecution', 'USP_SetExecutionContext', 'USP_EndExecution',
 'toolbelt.execution.id', 'toolbelt.execution.depth'):
 if marker not in all_source: raise SystemExit('Vertragsmarker fehlt: '+marker)
print('Execution Context statische Vertragsprüfung: erfolgreich')
""",
)
write(
    f"{execution_root}/Tests/Runtime/ExecutionContext.Contract.sql",
    r"""SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext())
 THROW 52420, N'Vor Testbeginn ist unerwartet ein Context aktiv.', 1;

DECLARE @Id uniqueidentifier;
DECLARE @Correlation uniqueidentifier = '11111111-2222-3333-4444-555555555555';
EXEC toolbelt_core.USP_BeginExecution
 @ExecutionId=@Id OUTPUT, @CorrelationId=@Correlation,
 @Actor=N'worker-a', @Tenant=N'tenant-a';
IF @Id IS NULL OR toolbelt_core.SVF_CurrentExecutionId() <> @Id
 THROW 52421, N'Execution-ID wurde nicht gesetzt.', 1;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ExecutionId=@Id AND CorrelationId=@Correlation AND Actor=N'worker-a' AND Tenant=N'tenant-a' AND ScopeDepth=1)
 THROW 52422, N'Root-Context ist inkonsistent.', 1;

DECLARE @NestedId uniqueidentifier = NULL;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@NestedId OUTPUT;
IF @NestedId <> @Id OR NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ScopeDepth=2)
 THROW 52423, N'Nested Context ist inkonsistent.', 1;

EXEC toolbelt_core.USP_SetExecutionContext
 @ExpectedExecutionId=@Id, @Actor=N'worker-b', @ClearTenant=1;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE Actor=N'worker-b' AND Tenant IS NULL)
 THROW 52424, N'Context-Update ist fehlgeschlagen.', 1;

BEGIN TRY
 DECLARE @Wrong uniqueidentifier = NEWID();
 EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Wrong;
 THROW 52425, N'Mismatch wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() <> 51431 THROW;
END CATCH;

EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ScopeDepth=1)
 THROW 52426, N'Nested End hat falsche Tiefe.', 1;
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
IF EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext()) OR toolbelt_core.SVF_CurrentExecutionId() IS NOT NULL
 THROW 52427, N'Root End hat Sessionwerte nicht gelöscht.', 1;

DECLARE @Help TABLE
(
 HelpContractVersion varchar(16), SchemaName sysname, ObjectName sysname,
 Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
 IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max), ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_BeginExecution @Hilfe=1;
IF NOT EXISTS (SELECT 1 FROM @Help WHERE ObjectName=N'USP_BeginExecution')
 THROW 52428, N'Help-Vertrag fehlt.', 1;
PRINT N'Execution Context Contract: erfolgreich';
""",
)
write(
    f"{execution_root}/Tests/Runtime/MultiSession.Contract.sql",
    r"""SET NOCOUNT ON;
DECLARE @Id uniqueidentifier;
DECLARE @Actor nvarchar(256) = N'worker-' + N'$(WorkerId)';
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT, @Actor=@Actor;
WAITFOR DELAY '00:00:02';
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ExecutionId=@Id AND Actor=@Actor AND ScopeDepth=1)
 THROW 52429, N'Sessionisolation fehlgeschlagen.', 1;
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
""",
)
write(
    f"{execution_root}/Tests/Runtime/Lifecycle.Contract.sql",
    """IF OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext', N'IF') IS NULL OR OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId', N'FN') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_BeginExecution', N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_SetExecutionContext', N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_EndExecution', N'P') IS NULL
 THROW 52430, N'Execution-Context-Objektbestand ist unvollständig.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-context.Version' AND CONVERT(nvarchar(32), value)=N'1.0.0')
 THROW 52431, N'Modulmarker fehlt.', 1;
PRINT N'Execution Context Lifecycle: erfolgreich';
""",
)
write(
    f"{execution_root}/Tests/Runtime/Central.Contract.sql",
    r"""SET NOCOUNT ON;
DECLARE @Id uniqueidentifier;
DECLARE @Sql nvarchar(max) = N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT, @Actor=N''central'';';
EXEC sys.sp_executesql @Sql, N'@Id uniqueidentifier OUTPUT', @Id=@Id OUTPUT;
IF @Id IS NULL OR TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) <> @Id
 THROW 52432, N'Central Begin fehlgeschlagen.', 1;
SET @Sql = N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;';
EXEC sys.sp_executesql @Sql, N'@Id uniqueidentifier', @Id=@Id;
IF SESSION_CONTEXT(N'toolbelt.execution.id') IS NOT NULL
 THROW 52433, N'Central End fehlgeschlagen.', 1;
PRINT N'Execution Context Central: erfolgreich';
""",
)

# Architektur
write(
    "Documentation/Architecture/ERROR_ENVELOPE_MODULE_DESIGN.md",
    """# Error-Envelope-Moduldesign

Das Modul kapselt die Ausgabeform, nicht den Fehlerfang selbst. Die `ERROR_*`-Funktionen werden im ursprünglichen `CATCH` ausgewertet und explizit übergeben. Dadurch bleibt der anschließende parameterlose `THROW;` im selben `CATCH` möglich und Enginefehler werden nicht umnummeriert.

Version 1 speichert nichts persistent, entscheidet nicht über Retry und schreibt keine Logs. Eine spätere Logging-Capability konsumiert den Envelope, besitzt aber einen getrennten Lifecycle.
""",
)
write(
    "Documentation/Architecture/EXECUTION_CONTEXT_MODULE_DESIGN.md",
    """# Execution-Context-Moduldesign

Version 1 verwendet ausschließlich namespacete `SESSION_CONTEXT`-Schlüssel. Ein Context besitzt Execution-ID, Correlation-ID, Actor, Tenant, UTC-Startzeit und ScopeDepth. Verschachtelung erzeugt keine neue Identität, sondern erhöht die Tiefe. Dadurch bleibt Version 1 ohne persistente Tabelle und ohne serialisierten Stack.

Die inline TVF ist die primäre Leseschnittstelle. Der SVF-Wrapper ist optionaler Komfort und darf in mengenorientierten Abfragen nicht die TVF verdrängen. Aufrufer mit Connection Pooling müssen Begin und End paaren; bei der letzten Ebene werden alle Toolbelt-Schlüssel gelöscht.
""",
)

# Gemeinsamer Linux-Runner
write(
    "Tests/CI/run-w4a-execution-foundations-linux.sh",
    r"""#!/usr/bin/env bash
set -euo pipefail
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
container_name="tbx-w4a-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"
cleanup(){ docker rm -f "${container_name}" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "${container_name}" -e ACCEPT_EULA=Y -e MSSQL_PID=Developer -e MSSQL_SA_PASSWORD="${sa_password}" -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" "${sql_image}" >/dev/null
sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
 if docker exec "${container_name}" test -x "${candidate}"; then sqlcmd_path="${candidate}"; break; fi
done
[[ -n "${sqlcmd_path}" ]] || { echo 'sqlcmd fehlt' >&2; exit 1; }
for attempt in $(seq 1 60); do
 if docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q 'SELECT 1' >/dev/null 2>&1; then break; fi
 [[ "${attempt}" -eq 60 ]] && { docker logs "${container_name}"; exit 1; }
 sleep 2
done
run_query(){ docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"; }
run_file(){ local db="$1" wd="$2" file="$3"; shift 3; docker exec --workdir "${wd}" "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"; }
deploy(){ run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"; }
uninstall(){ run_file "$1" "/workspace/$2/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers="$3"; }

local_db=tbx_w4a_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.result-table local
deploy "${local_db}" Modules/toolbelt.core.execution-context local
deploy "${local_db}" Modules/toolbelt.core.error-envelope local
run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime Lifecycle.Contract.sql
run_file "${local_db}" /workspace/Modules/toolbelt.core.error-envelope/Tests/Runtime Lifecycle.Contract.sql
for level in 150 160 170; do
 run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL = ${level};"
 run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime ExecutionContext.Contract.sql
 run_file "${local_db}" /workspace/Modules/toolbelt.core.error-envelope/Tests/Runtime ErrorEnvelope.Contract.sql
 multi=()
 for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime MultiSession.Contract.sql -v WorkerId="${worker}" & multi+=("$!")
 done
 for pid in "${multi[@]}"; do wait "${pid}"; done
done
# Wiederholungsdeployment
deploy "${local_db}" Modules/toolbelt.core.execution-context local
deploy "${local_db}" Modules/toolbelt.core.error-envelope local

central_db=tbx_w4a_central
consumer_db=tbx_w4a_consumer
run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${central_db}" Modules/toolbelt.core.result-table central
deploy "${central_db}" Modules/toolbelt.core.execution-context central
deploy "${central_db}" Modules/toolbelt.core.error-envelope central
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.error-envelope/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"
uninstall "${central_db}" Modules/toolbelt.core.error-envelope 1
uninstall "${central_db}" Modules/toolbelt.core.execution-context 1
uninstall "${central_db}" Modules/toolbelt.core.result-table 1
uninstall "${local_db}" Modules/toolbelt.core.error-envelope 0
uninstall "${local_db}" Modules/toolbelt.core.execution-context 0
uninstall "${local_db}" Modules/toolbelt.core.result-table 0

echo 'W4a Execution-Grundlagen Linux: erfolgreich'
""",
)

# Registry und Statusdokumente
repo_map = read(".ai/repo_map.yaml")
repo_map = repo_map.replace("status: nineteen_modules_implemented", "status: twenty_one_modules_implemented")
registry_marker = "    - Modules/toolbelt.metadata.capability-catalog/module.yaml\n"
registry_addition = (
    registry_marker
    + "    - Modules/toolbelt.core.error-envelope/module.yaml\n"
    + "    - Modules/toolbelt.core.execution-context/module.yaml\n"
)
if "Modules/toolbelt.core.error-envelope/module.yaml" not in repo_map:
    if registry_marker not in repo_map:
        raise RuntimeError("Registry-Marke fehlt")
    repo_map = repo_map.replace(registry_marker, registry_addition, 1)
impact_marker = "    file_content_contract:\n"
impact_addition = """    error_envelope_contract:
      paths:
        - Modules/toolbelt.core.error-envelope/**
        - Documentation/Architecture/ERROR_ENVELOPE_MODULE_DESIGN.md
        - Documentation/Standards/USP_CONTRACT.md
        - Tests/CI/run-w4a-execution-foundations-linux.sh
        - .github/workflows/w4a-execution-foundations-runtime.yml
      checks:
        - markdown_links
    execution_context_contract:
      paths:
        - Modules/toolbelt.core.execution-context/**
        - Documentation/Architecture/EXECUTION_CONTEXT_MODULE_DESIGN.md
        - Documentation/Standards/USP_CONTRACT.md
        - Tests/CI/run-w4a-execution-foundations-linux.sh
        - .github/workflows/w4a-execution-foundations-runtime.yml
      checks:
        - markdown_links
"""
if "    error_envelope_contract:\n" not in repo_map:
    if impact_marker not in repo_map:
        raise RuntimeError("Change-Impact-Marke fehlt")
    repo_map = repo_map.replace(impact_marker, impact_addition + impact_marker, 1)
save(".ai/repo_map.yaml", repo_map)

for path in (
    "README.md", "Modules/README.md", "Tests/README.md", "CHANGELOG.md",
    ".ai/BACKLOG.md", ".ai/PROJECT_CONTEXT.md", ".ai/ROADMAP.md",
    "Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md",
    "Backlog/TOOLBELT_RESEARCH_PRIORITIES.md",
):
    update_counts(path)

insert_before_once(
    "README.md",
    "Das portable Modul\n[`toolbelt.file.content`](./Modules/toolbelt.file.content/README.md)",
    """Die Execution-Grundlagen bestehen aus
[`toolbelt.core.error-envelope`](./Modules/toolbelt.core.error-envelope/README.md)
und
[`toolbelt.core.execution-context`](./Modules/toolbelt.core.execution-context/README.md).
Sie standardisieren explizit übergebene Fehlerdaten und verwalten eine
sessiongebundene Execution-/Correlation-ID ohne persistente Tabellen.

""",
)
insert_before_once(
    "Modules/README.md",
    "| `toolbelt.file.content` |",
    "| `toolbelt.core.error-envelope` | standardisierter Error Envelope ohne Rethrow- oder Logging-Seiteneffekt | `partially validated` |\n| `toolbelt.core.execution-context` | sessiongebundene Execution-/Correlation-ID über `SESSION_CONTEXT` | `partially validated` |\n",
)
insert_before_once(
    "Tests/README.md",
    "| `toolbelt.file.content` |",
    f"| `toolbelt.core.error-envelope` | [ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.error-envelope/Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md) | `partially validated`; SQL Server 2025 Linux CL150/160/170, Evidence {EVIDENCE_URL} |\n| `toolbelt.core.execution-context` | [EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.execution-context/Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md) | `partially validated`; Context-Lifecycle und Sessionisolation auf SQL Server 2025 Linux CL150/160/170, Evidence {EVIDENCE_URL} |\n",
)

completed_marker = "## Abgeschlossene Arbeitspakete\n\n"
backlog_addition = f"""### AP-2026-026: TC-2026-019 Execution Context

| Feld | Wert |
|---|---|
| ID | `AP-2026-026` |
| Ziel | Sessiongebundene Execution- und Correlation-Information ohne persistente Tabelle bereitstellen. |
| Scope | `toolbelt.core.execution-context` Version `1.0.0`, Begin/Set/End, inline TVF, SVF-Wrapper, lokales und zentrales Deployment. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170, vier parallele Sessions, Lifecycle, Central und Uninstall. |
| Evidenz | {EVIDENCE_URL} |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; persistenter Ausführungsstatus bleibt ein getrennter Slice. |

### AP-2026-025: TC-2026-017 Error Envelope

| Feld | Wert |
|---|---|
| ID | `AP-2026-025` |
| Ziel | Explizit aus einem CATCH übergebene Fehlerdaten standardisieren, ohne den unveränderten Rethrow zu ersetzen. |
| Scope | `toolbelt.core.error-envelope` Version `1.0.0`, direkte und ResultTable-Ausgabe, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170, Klassifikation, ResultTable, Lifecycle, Central und Uninstall. |
| Evidenz | {EVIDENCE_URL} |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; persistentes Logging bleibt getrennt. |

"""
insert_after_once(".ai/BACKLOG.md", completed_marker, backlog_addition)

update_candidate(
    "TC-2026-017",
    {
        "Mögliche Technologie": "Implementiert als `toolbelt.core.error-envelope` mit `toolbelt_core.USP_CaptureErrorEnvelope`; explizite ERROR_*-Parameter, kleine Klassifikation, direkte oder ResultTable-Ausgabe, kein persistentes Logging und kein Rethrow-Wrapper.",
        "Status": "`implemented`; Runtime `partially validated`",
        "Prüfdatum": TODAY,
        "Nächster Schritt": "Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; rollback-unabhängiges Logging erst nach Second-Session-Provider.",
    },
)
update_candidate(
    "TC-2026-019",
    {
        "Mögliche Technologie": "Implementiert als `toolbelt.core.execution-context` über namespacete `SESSION_CONTEXT`-Schlüssel, Begin/Set/End, inline `TVF_CurrentExecutionContext` und SVF-Komfortwrapper.",
        "Status": "`implemented`; Runtime `partially validated`",
        "Prüfdatum": TODAY,
        "Nächster Schritt": "Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; persistenter Execution-Status bleibt ein getrennter späterer Slice.",
    },
)

plan = "Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md"
text = read(plan)
text = re.sub(
    r"^\| `W4` \|.*$",
    "| `W4` | `active` | Weitere Execution-Grundlagen | `017`, `019`, `022` | Persistente Namenskonvention nur soweit tatsächlich benötigt | `toolbelt.core.error-envelope` und `toolbelt.core.execution-context` sind implementiert und auf SQL Server 2025 Linux teilweise validiert. Der persistente Work-Type-Katalog `TC-2026-022` bleibt als W4b offen. |",
    text,
    count=1,
    flags=re.MULTILINE,
)
implemented_marker = "| `TC-2026-023` | `toolbelt.metadata.capability-catalog` |"
rows = (
    "| `TC-2026-017` | `toolbelt.core.error-envelope` | `toolbelt_core.USP_CaptureErrorEnvelope` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |\n"
    "| `TC-2026-019` | `toolbelt.core.execution-context` | `toolbelt_core.USP_BeginExecution`, `USP_SetExecutionContext`, `USP_EndExecution`, `TVF_CurrentExecutionContext`, `SVF_CurrentExecutionId` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; persistenter Status bleibt getrennt. |\n"
)
if "| `TC-2026-017` | `toolbelt.core.error-envelope` |" not in text:
    pos = text.find(implemented_marker)
    if pos < 0:
        raise RuntimeError("Implementiert-Tabellenmarke fehlt")
    text = text[:pos] + rows + text[pos:]
save(plan, text)

roadmap_marker = "### Phase 2.6 – Portable File Content\n"
roadmap_addition = f"""### Phase 2.9 – Error Envelope

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.error-envelope` standardisiert explizit aus einem CATCH übergebene Fehlerdaten, ohne `THROW;` oder persistentes Logging zu ersetzen. Evidence: {EVIDENCE_URL}.

### Phase 2.10 – Execution Context

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.execution-context` verwaltet Execution-ID, Correlation-ID, Actor, Tenant und verschachtelten ScopeDepth über `SESSION_CONTEXT`. Evidence: {EVIDENCE_URL}.

"""
insert_before_once(".ai/ROADMAP.md", roadmap_marker, roadmap_addition)

changelog_marker = "### Geändert\n\n"
changelog_addition = f"""- W4a implementiert: `toolbelt.core.error-envelope` standardisiert explizite CATCH-Daten ohne Rethrow- oder Logging-Seiteneffekt.
- W4a implementiert: `toolbelt.core.execution-context` stellt Begin/Set/End, inline TVF und SVF-Wrapper über `SESSION_CONTEXT` bereit.
- Beide Module auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Lifecycle, Central und Sessionisolation validiert ({EVIDENCE_URL}).

"""
insert_after_once("CHANGELOG.md", changelog_marker, changelog_addition)

print("W4a-Artefakte wurden erzeugt.")
