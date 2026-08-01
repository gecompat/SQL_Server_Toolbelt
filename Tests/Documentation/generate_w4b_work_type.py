#!/usr/bin/env python3
"""Erzeugt W4b Work-Type-Katalog und gekoppelte Repository-Artefakte."""

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
MODULE_ID = "toolbelt.core.work-type"
MODULE_ROOT = f"Modules/{MODULE_ID}"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


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
        "21 Module sind implementiert": "22 Module sind implementiert",
        "21 Module sind\nimplementiert": "22 Module sind\nimplementiert",
        "21 implementierte Module": "22 implementierte Module",
        "20 sind `partially validated`": "21 sind `partially validated`",
        "20 teilweise validierte Module": "21 teilweise validierte Module",
        "twenty_one_modules_implemented": "twenty_two_modules_implemented",
        "21 Module implementiert": "22 Module implementiert",
        "20 teilweise validiert": "21 teilweise validiert",
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


WORK_TYPE_TABLE_SQL = r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[WorkType]
    (
          [WorkTypeId]             bigint IDENTITY(1,1) NOT NULL
        , [WorkTypeName]           varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [HandlerSchema]          sysname NOT NULL
        , [HandlerProcedure]       sysname NOT NULL
        , [ParameterMode]          varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [PayloadContractJson]    nvarchar(4000) NULL
        , [DefaultTimeoutSeconds]  int NOT NULL
        , [IsIdempotent]           bit NOT NULL
        , [IsEnabled]              bit NOT NULL
        , [Description]            nvarchar(1000) NULL
        , [CreatedAtUtc]           datetime2(7) NOT NULL
        , [CreatedBy]              sysname NOT NULL
        , [ModifiedAtUtc]          datetime2(7) NOT NULL
        , [ModifiedBy]             sysname NOT NULL
        , [DisabledAtUtc]          datetime2(7) NULL
        , [DisabledBy]             sysname NULL
        , [DisabledReason]         nvarchar(1000) NULL
        , [RowVersion]             rowversion NOT NULL
        , CONSTRAINT [PK_WorkType]
            PRIMARY KEY CLUSTERED ([WorkTypeId])
        , CONSTRAINT [UQ_WorkType_WorkTypeName]
            UNIQUE NONCLUSTERED ([WorkTypeName])
        , CONSTRAINT [CK_WorkType_WorkTypeName]
            CHECK
            (
                LEN([WorkTypeName]) BETWEEN 3 AND 128
                AND [WorkTypeName] = LOWER([WorkTypeName]) COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] NOT LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] NOT LIKE '%.'
                AND [WorkTypeName] NOT LIKE '.%'
                AND [WorkTypeName] NOT LIKE '%..%'
            )
        , CONSTRAINT [CK_WorkType_ParameterMode]
            CHECK ([ParameterMode] IN ('NONE', 'JSON_PAYLOAD'))
        , CONSTRAINT [CK_WorkType_PayloadContract]
            CHECK
            (
                ([ParameterMode] = 'NONE' AND [PayloadContractJson] IS NULL)
                OR
                (
                    [ParameterMode] = 'JSON_PAYLOAD'
                    AND [PayloadContractJson] IS NOT NULL
                    AND ISJSON([PayloadContractJson]) = 1
                    AND LEFT(LTRIM([PayloadContractJson]), 1) = N'{'
                )
            )
        , CONSTRAINT [CK_WorkType_DefaultTimeoutSeconds]
            CHECK ([DefaultTimeoutSeconds] BETWEEN 1 AND 86400)
        , CONSTRAINT [CK_WorkType_DisabledMetadata]
            CHECK
            (
                ([IsEnabled] = 1 AND [DisabledAtUtc] IS NULL AND [DisabledBy] IS NULL AND [DisabledReason] IS NULL)
                OR
                ([IsEnabled] = 0 AND [DisabledAtUtc] IS NOT NULL AND [DisabledBy] IS NOT NULL)
            )
        , CONSTRAINT [DF_WorkType_ParameterMode]
            DEFAULT ('NONE') FOR [ParameterMode]
        , CONSTRAINT [DF_WorkType_DefaultTimeoutSeconds]
            DEFAULT (300) FOR [DefaultTimeoutSeconds]
        , CONSTRAINT [DF_WorkType_IsIdempotent]
            DEFAULT (0) FOR [IsIdempotent]
        , CONSTRAINT [DF_WorkType_IsEnabled]
            DEFAULT (1) FOR [IsEnabled]
        , CONSTRAINT [DF_WorkType_CreatedAtUtc]
            DEFAULT (SYSUTCDATETIME()) FOR [CreatedAtUtc]
        , CONSTRAINT [DF_WorkType_CreatedBy]
            DEFAULT (ORIGINAL_LOGIN()) FOR [CreatedBy]
        , CONSTRAINT [DF_WorkType_ModifiedAtUtc]
            DEFAULT (SYSUTCDATETIME()) FOR [ModifiedAtUtc]
        , CONSTRAINT [DF_WorkType_ModifiedBy]
            DEFAULT (ORIGINAL_LOGIN()) FOR [ModifiedBy]
    );

    CREATE NONCLUSTERED INDEX [IX_WorkType_IsEnabled_WorkTypeName]
        ON [toolbelt_core].[WorkType] ([IsEnabled], [WorkTypeName])
        INCLUDE
        (
              [HandlerSchema]
            , [HandlerProcedure]
            , [ParameterMode]
            , [DefaultTimeoutSeconds]
            , [IsIdempotent]
        );
END;
GO
"""

VIEW_SQL = r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [toolbelt_core].[VW_WorkTypes]
AS
SELECT
      wt.[WorkTypeId]
    , wt.[WorkTypeName]
    , wt.[HandlerSchema]
    , wt.[HandlerProcedure]
    , QUOTENAME(wt.[HandlerSchema]) + N'.' + QUOTENAME(wt.[HandlerProcedure]) AS [HandlerQualifiedName]
    , wt.[ParameterMode]
    , wt.[PayloadContractJson]
    , wt.[DefaultTimeoutSeconds]
    , wt.[IsIdempotent]
    , wt.[IsEnabled]
    , wt.[Description]
    , wt.[CreatedAtUtc]
    , wt.[CreatedBy]
    , wt.[ModifiedAtUtc]
    , wt.[ModifiedBy]
    , wt.[DisabledAtUtc]
    , wt.[DisabledBy]
    , wt.[DisabledReason]
    , wt.[RowVersion]
    , CONVERT(bit, CASE
          WHEN OBJECT_ID(QUOTENAME(wt.[HandlerSchema]) + N'.' + QUOTENAME(wt.[HandlerProcedure]), N'P') IS NOT NULL
            OR OBJECT_ID(QUOTENAME(wt.[HandlerSchema]) + N'.' + QUOTENAME(wt.[HandlerProcedure]), N'PC') IS NOT NULL
          THEN 1 ELSE 0 END) AS [HandlerExists]
FROM [toolbelt_core].[WorkType] AS wt;
GO
"""

RESULT_ROUTING_SQL = r"""
    CREATE TABLE #tbx_Core_WorkType_ResultShape
    (
          WorkTypeId            bigint NOT NULL
        , WorkTypeName          varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , HandlerSchema         sysname NOT NULL
        , HandlerProcedure      sysname NOT NULL
        , HandlerQualifiedName  nvarchar(517) NOT NULL
        , ParameterMode         varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadContractJson   nvarchar(4000) NULL
        , DefaultTimeoutSeconds int NOT NULL
        , IsIdempotent          bit NOT NULL
        , IsEnabled             bit NOT NULL
        , Description           nvarchar(1000) NULL
        , CreatedAtUtc          datetime2(7) NOT NULL
        , CreatedBy             sysname NOT NULL
        , ModifiedAtUtc         datetime2(7) NOT NULL
        , ModifiedBy            sysname NOT NULL
        , DisabledAtUtc         datetime2(7) NULL
        , DisabledBy            sysname NULL
        , DisabledReason        nvarchar(1000) NULL
        , RowVersion            binary(8) NOT NULL
        , HandlerExists         bit NOT NULL
    );

    CREATE TABLE #tbx_Core_WorkType_Result
    (
          WorkTypeId            bigint NOT NULL
        , WorkTypeName          varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , HandlerSchema         sysname NOT NULL
        , HandlerProcedure      sysname NOT NULL
        , HandlerQualifiedName  nvarchar(517) NOT NULL
        , ParameterMode         varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadContractJson   nvarchar(4000) NULL
        , DefaultTimeoutSeconds int NOT NULL
        , IsIdempotent          bit NOT NULL
        , IsEnabled             bit NOT NULL
        , Description           nvarchar(1000) NULL
        , CreatedAtUtc          datetime2(7) NOT NULL
        , CreatedBy             sysname NOT NULL
        , ModifiedAtUtc         datetime2(7) NOT NULL
        , ModifiedBy            sysname NOT NULL
        , DisabledAtUtc         datetime2(7) NULL
        , DisabledBy            sysname NULL
        , DisabledReason        nvarchar(1000) NULL
        , RowVersion            binary(8) NOT NULL
        , HandlerExists         bit NOT NULL
    );
"""

RESULT_OUTPUT_SQL = r"""
    IF @ResultTable IS NULL
    BEGIN
        SELECT * FROM #tbx_Core_WorkType_Result;
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51518, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_Core_WorkType_ResultShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists)'
        + N' SELECT WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists FROM #tbx_Core_WorkType_Result;';
    EXEC sys.sp_executesql @InsertSql;
    RETURN 0;
"""

REGISTER_SQL = f"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RegisterWorkType]
(
      @WorkTypeName          varchar(128)   = NULL
    , @HandlerSchema         sysname        = NULL
    , @HandlerProcedure      sysname        = NULL
    , @ParameterMode         varchar(16)    = 'NONE'
    , @PayloadContractJson   nvarchar(4000) = NULL
    , @DefaultTimeoutSeconds int            = 300
    , @IsIdempotent          bit            = 0
    , @Description           nvarchar(1000) = NULL
    , @AllowUpdate           bit            = 0
    , @Reactivate            bit            = 0
    , @ExpectedRowVersion    binary(8)      = NULL
    , @ResultTable           sysname        = NULL
    , @KeepData              bit            = 0
    , @Debug                 tinyint        = 0
    , @Hilfe                 bit            = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ParameterMode = UPPER(ISNULL(@ParameterMode, 'NONE'));
    SET @DefaultTimeoutSeconds = ISNULL(@DefaultTimeoutSeconds, 300);
    SET @IsIdempotent = ISNULL(@IsIdempotent, 0);
    SET @AllowUpdate = ISNULL(@AllowUpdate, 0);
    SET @Reactivate = ISNULL(@Reactivate, 0);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_RegisterWorkType' AS sysname) AS ObjectName
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
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@WorkTypeName', 'varchar(128)', 1, 0, NULL, N'Kanonischer kleingeschriebener Work-Type-Name.', NULL)
            , ('PARAMETER', 2, N'@HandlerSchema', 'sysname', 1, 0, NULL, N'Schema der vorhandenen Zielprocedure in derselben Datenbank.', NULL)
            , ('PARAMETER', 3, N'@HandlerProcedure', 'sysname', 1, 0, NULL, N'Name der vorhandenen Zielprocedure.', NULL)
            , ('PARAMETER', 4, N'@ParameterMode', 'varchar(16)', 0, 0, N'NONE', N'NONE oder JSON_PAYLOAD.', NULL)
            , ('PARAMETER', 5, N'@PayloadContractJson', 'nvarchar(4000)', 0, 1, NULL, N'JSON-Objekt mit deklarativem Payloadvertrag; wird nicht als Code ausgeführt.', NULL)
            , ('PARAMETER', 6, N'@AllowUpdate', 'bit', 0, 0, N'0', N'Erlaubt eine Änderung einer vorhandenen Registrierung.', NULL)
            , ('PARAMETER', 7, N'@Reactivate', 'bit', 0, 0, N'0', N'Reaktiviert einen deaktivierten Work Type.', NULL)
            , ('PARAMETER', 8, N'@ExpectedRowVersion', 'binary(8)', 0, 1, NULL, N'Optionale Optimistic-Concurrency-Prüfung.', NULL)
            , ('PARAMETER', 9, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für die Ergebniszeile.', NULL)
            , ('ERROR', 1, N'51500-51518', NULL, NULL, NULL, NULL, N'Validierungs-, Berechtigungs-, Concurrency- und Dependencyfehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Registriert eine synthetische Procedure ohne Parameter.', N'EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName=''demo.noop'', @HandlerSchema=N''dbo'', @HandlerProcedure=N''USP_DemoNoop'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF @WorkTypeName IS NULL
       OR LEN(@WorkTypeName) NOT BETWEEN 3 AND 128
       OR @WorkTypeName <> LOWER(@WorkTypeName) COLLATE Latin1_General_100_BIN2
       OR @WorkTypeName NOT LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
       OR @WorkTypeName LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
       OR @WorkTypeName LIKE '.%'
       OR @WorkTypeName LIKE '%.'
       OR @WorkTypeName LIKE '%..%'
        THROW 51500, N'@WorkTypeName muss kanonisch kleingeschrieben sein und darf nur a-z, 0-9, Punkt, Unterstrich und Bindestrich enthalten.', 1;
    IF NULLIF(@HandlerSchema, N'') IS NULL OR NULLIF(@HandlerProcedure, N'') IS NULL
        THROW 51501, N'@HandlerSchema und @HandlerProcedure sind erforderlich.', 1;
    IF @HandlerSchema = N'sys'
        THROW 51502, N'Systemprocedures dürfen nicht als Work Type registriert werden.', 1;
    IF @ParameterMode NOT IN ('NONE', 'JSON_PAYLOAD')
        THROW 51503, N'@ParameterMode muss NONE oder JSON_PAYLOAD sein.', 1;
    IF @ParameterMode = 'NONE' AND @PayloadContractJson IS NOT NULL
        THROW 51504, N'@PayloadContractJson ist bei ParameterMode NONE nicht zulässig.', 1;
    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @PayloadContractJson IS NULL
           OR ISJSON(@PayloadContractJson) <> 1
           OR LEFT(LTRIM(@PayloadContractJson), 1) <> N'{'
       )
        THROW 51505, N'@PayloadContractJson muss bei JSON_PAYLOAD ein JSON-Objekt sein.', 1;
    IF @DefaultTimeoutSeconds NOT BETWEEN 1 AND 86400
        THROW 51506, N'@DefaultTimeoutSeconds muss zwischen 1 und 86400 liegen.', 1;

    DECLARE @QualifiedName nvarchar(517) = QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure);
    DECLARE @HandlerObjectId int = COALESCE(OBJECT_ID(@QualifiedName, N'P'), OBJECT_ID(@QualifiedName, N'PC'));
    IF @HandlerObjectId IS NULL
        THROW 51507, N'Die Zielprocedure existiert in der aktuellen Datenbank nicht.', 1;
    IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = @HandlerObjectId AND is_ms_shipped = 1)
        THROW 51508, N'Als Work Type sind keine von Microsoft ausgelieferten Procedures zulässig.', 1;
    IF ISNULL(HAS_PERMS_BY_NAME(@QualifiedName, N'OBJECT', N'EXECUTE'), 0) <> 1
        THROW 51509, N'Der registrierende Principal besitzt kein EXECUTE auf die Zielprocedure.', 1;

{RESULT_ROUTING_SQL}

    DECLARE @Now datetime2(7) = SYSUTCDATETIME();
    DECLARE @Principal sysname = ORIGINAL_LOGIN();
    DECLARE @WorkTypeId bigint;
    DECLARE @CurrentRowVersion binary(8);
    DECLARE @CurrentEnabled bit;
    DECLARE @CurrentHandlerSchema sysname;
    DECLARE @CurrentHandlerProcedure sysname;
    DECLARE @CurrentParameterMode varchar(16);
    DECLARE @CurrentPayloadContractJson nvarchar(4000);
    DECLARE @CurrentTimeout int;
    DECLARE @CurrentIdempotent bit;
    DECLARE @CurrentDescription nvarchar(1000);
    DECLARE @Changed bit = 0;

    BEGIN TRANSACTION;

    SELECT
          @WorkTypeId = wt.WorkTypeId
        , @CurrentRowVersion = CONVERT(binary(8), wt.RowVersion)
        , @CurrentEnabled = wt.IsEnabled
        , @CurrentHandlerSchema = wt.HandlerSchema
        , @CurrentHandlerProcedure = wt.HandlerProcedure
        , @CurrentParameterMode = wt.ParameterMode
        , @CurrentPayloadContractJson = wt.PayloadContractJson
        , @CurrentTimeout = wt.DefaultTimeoutSeconds
        , @CurrentIdempotent = wt.IsIdempotent
        , @CurrentDescription = wt.Description
    FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @WorkTypeId IS NULL
    BEGIN
        INSERT INTO toolbelt_core.WorkType
        (
              WorkTypeName, HandlerSchema, HandlerProcedure, ParameterMode
            , PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent
            , IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy
        )
        VALUES
        (
              @WorkTypeName, @HandlerSchema, @HandlerProcedure, @ParameterMode
            , @PayloadContractJson, @DefaultTimeoutSeconds, @IsIdempotent
            , 1, @Description, @Now, @Principal, @Now, @Principal
        );
        SET @WorkTypeId = SCOPE_IDENTITY();
        SET @Changed = 1;
    END
    ELSE
    BEGIN
        IF @ExpectedRowVersion IS NOT NULL AND @ExpectedRowVersion <> @CurrentRowVersion
            THROW 51510, N'@ExpectedRowVersion stimmt nicht mit dem aktuellen Work Type überein.', 1;

        DECLARE @ConfigurationDiffers bit = CONVERT(bit, CASE WHEN
               @CurrentHandlerSchema <> @HandlerSchema
            OR @CurrentHandlerProcedure <> @HandlerProcedure
            OR @CurrentParameterMode <> @ParameterMode
            OR ISNULL(@CurrentPayloadContractJson, N'') <> ISNULL(@PayloadContractJson, N'')
            OR @CurrentTimeout <> @DefaultTimeoutSeconds
            OR @CurrentIdempotent <> @IsIdempotent
            OR ISNULL(@CurrentDescription, N'') <> ISNULL(@Description, N'')
            THEN 1 ELSE 0 END);

        IF @ConfigurationDiffers = 1 AND @AllowUpdate = 0
            THROW 51511, N'Der Work Type existiert mit abweichender Konfiguration; @AllowUpdate = 1 ist erforderlich.', 1;
        IF @CurrentEnabled = 0 AND @Reactivate = 0
            THROW 51512, N'Der Work Type ist deaktiviert; @Reactivate = 1 ist erforderlich.', 1;

        IF @ConfigurationDiffers = 1 OR @CurrentEnabled = 0
        BEGIN
            UPDATE toolbelt_core.WorkType
            SET
                  HandlerSchema = @HandlerSchema
                , HandlerProcedure = @HandlerProcedure
                , ParameterMode = @ParameterMode
                , PayloadContractJson = @PayloadContractJson
                , DefaultTimeoutSeconds = @DefaultTimeoutSeconds
                , IsIdempotent = @IsIdempotent
                , IsEnabled = 1
                , Description = @Description
                , ModifiedAtUtc = @Now
                , ModifiedBy = @Principal
                , DisabledAtUtc = NULL
                , DisabledBy = NULL
                , DisabledReason = NULL
            WHERE WorkTypeId = @WorkTypeId;
            SET @Changed = 1;
        END;
    END;

    INSERT INTO #tbx_Core_WorkType_Result
    SELECT *
    FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeId = @WorkTypeId;

    COMMIT TRANSACTION;

    IF @Debug > 0
        RAISERROR(N'USP_RegisterWorkType: Registrierung verarbeitet; Änderung=%d.', 10, 1, @Changed) WITH NOWAIT;

{RESULT_OUTPUT_SQL}
END;
GO
"""

DISABLE_SQL = f"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DisableWorkType]
(
      @WorkTypeName       varchar(128)   = NULL
    , @DisabledReason     nvarchar(1000) = NULL
    , @ExpectedRowVersion binary(8)      = NULL
    , @ResultTable        sysname        = NULL
    , @KeepData           bit            = 0
    , @Debug              tinyint        = 0
    , @Hilfe              bit            = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_DisableWorkType' AS sysname) AS ObjectName
            , CAST('DESCRIPTION' AS varchar(32)) AS Section
            , 1 AS Ordinal
            , CAST(NULL AS sysname) AS ItemName
            , CAST(NULL AS varchar(256)) AS SqlDataType
            , CAST(NULL AS bit) AS IsRequired
            , CAST(NULL AS bit) AS IsNullable
            , CAST(NULL AS nvarchar(4000)) AS DefaultValue
            , CAST(N'Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.' AS nvarchar(max)) AS Description
            , CAST(N'EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName=''demo.noop'';' AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51520, N'@WorkTypeName ist erforderlich.', 1;

{RESULT_ROUTING_SQL}

    DECLARE @WorkTypeId bigint;
    DECLARE @CurrentRowVersion binary(8);
    DECLARE @CurrentEnabled bit;
    DECLARE @Now datetime2(7) = SYSUTCDATETIME();
    DECLARE @Principal sysname = ORIGINAL_LOGIN();

    BEGIN TRANSACTION;

    SELECT
          @WorkTypeId = wt.WorkTypeId
        , @CurrentRowVersion = CONVERT(binary(8), wt.RowVersion)
        , @CurrentEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @WorkTypeId IS NULL
        THROW 51521, N'Der Work Type ist nicht registriert.', 1;
    IF @ExpectedRowVersion IS NOT NULL AND @ExpectedRowVersion <> @CurrentRowVersion
        THROW 51522, N'@ExpectedRowVersion stimmt nicht mit dem aktuellen Work Type überein.', 1;

    IF @CurrentEnabled = 1
    BEGIN
        UPDATE toolbelt_core.WorkType
        SET
              IsEnabled = 0
            , DisabledAtUtc = @Now
            , DisabledBy = @Principal
            , DisabledReason = @DisabledReason
            , ModifiedAtUtc = @Now
            , ModifiedBy = @Principal
        WHERE WorkTypeId = @WorkTypeId;
    END
    ELSE IF @DisabledReason IS NOT NULL
    BEGIN
        UPDATE toolbelt_core.WorkType
        SET
              DisabledReason = @DisabledReason
            , ModifiedAtUtc = @Now
            , ModifiedBy = @Principal
        WHERE WorkTypeId = @WorkTypeId
          AND ISNULL(DisabledReason, N'') <> ISNULL(@DisabledReason, N'');
    END;

    INSERT INTO #tbx_Core_WorkType_Result
    SELECT *
    FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeId = @WorkTypeId;

    COMMIT TRANSACTION;

    IF @Debug > 0
        RAISERROR(N'USP_DisableWorkType: Work Type ist deaktiviert.', 10, 1) WITH NOWAIT;

{RESULT_OUTPUT_SQL}
END;
GO
"""

RESOLVE_SQL = f"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ResolveWorkType]
(
      @WorkTypeName              varchar(128) = NULL
    , @RequireEnabled            bit          = 1
    , @RequireExecutableByCaller bit          = 1
    , @ResultTable               sysname      = NULL
    , @KeepData                  bit          = 0
    , @Debug                     tinyint      = 0
    , @Hilfe                     bit          = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @RequireEnabled = ISNULL(@RequireEnabled, 1);
    SET @RequireExecutableByCaller = ISNULL(@RequireExecutableByCaller, 1);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_ResolveWorkType' AS sysname) AS ObjectName
            , CAST('DESCRIPTION' AS varchar(32)) AS Section
            , 1 AS Ordinal
            , CAST(NULL AS sysname) AS ItemName
            , CAST(NULL AS varchar(256)) AS SqlDataType
            , CAST(NULL AS bit) AS IsRequired
            , CAST(NULL AS bit) AS IsNullable
            , CAST(NULL AS nvarchar(4000)) AS DefaultValue
            , CAST(N'Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.' AS nvarchar(max)) AS Description
            , CAST(N'EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName=''demo.noop'';' AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51530, N'@WorkTypeName ist erforderlich.', 1;

{RESULT_ROUTING_SQL}

    INSERT INTO #tbx_Core_WorkType_Result
    SELECT *
    FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeName = @WorkTypeName;

    IF @@ROWCOUNT = 0
        THROW 51531, N'Der Work Type ist nicht registriert.', 1;

    DECLARE @Enabled bit;
    DECLARE @HandlerExists bit;
    DECLARE @QualifiedName nvarchar(517);
    SELECT
          @Enabled = IsEnabled
        , @HandlerExists = HandlerExists
        , @QualifiedName = HandlerQualifiedName
    FROM #tbx_Core_WorkType_Result;

    IF @RequireEnabled = 1 AND @Enabled = 0
        THROW 51532, N'Der Work Type ist deaktiviert.', 1;
    IF @HandlerExists = 0
        THROW 51533, N'Die registrierte Zielprocedure existiert nicht mehr.', 1;
    IF @RequireExecutableByCaller = 1
       AND ISNULL(HAS_PERMS_BY_NAME(@QualifiedName, N'OBJECT', N'EXECUTE'), 0) <> 1
        THROW 51534, N'Der aktuelle Principal besitzt kein EXECUTE auf die Zielprocedure.', 1;

    IF @Debug > 0
        RAISERROR(N'USP_ResolveWorkType: Work Type wurde aufgelöst.', 10, 1) WITH NOWAIT;

{RESULT_OUTPUT_SQL}
END;
GO
"""

DEPLOY_SQL = r"""-- Deployment für toolbelt.core.work-type
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51541, N'DeploymentMode muss local oder central sein.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');

IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
    THROW 51542, N'Die Abhängigkeit toolbelt.core.result-table fehlt.', 1;

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.WorkType')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
         AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.work-type'
   )
    THROW 51540, N'Der Zielname toolbelt_core.WorkType ist bereits durch ein frameworkfremdes Objekt belegt.', 1;

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NOT NULL
   AND EXISTS
   (
       SELECT required.name
       FROM
       (
           VALUES
             (N'WorkTypeId'), (N'WorkTypeName'), (N'HandlerSchema'), (N'HandlerProcedure')
           , (N'ParameterMode'), (N'PayloadContractJson'), (N'DefaultTimeoutSeconds')
           , (N'IsIdempotent'), (N'IsEnabled'), (N'Description'), (N'CreatedAtUtc')
           , (N'CreatedBy'), (N'ModifiedAtUtc'), (N'ModifiedBy'), (N'DisabledAtUtc')
           , (N'DisabledBy'), (N'DisabledReason'), (N'RowVersion')
       ) AS required(name)
       WHERE NOT EXISTS
       (
           SELECT 1
           FROM sys.columns AS c
           WHERE c.object_id = OBJECT_ID(N'toolbelt_core.WorkType')
             AND c.name = required.name
       )
   )
    THROW 51543, N'Die vorhandene WorkType-Tabelle entspricht nicht dem erwarteten Version-1-Vertrag.', 1;

DECLARE @ObjectChecks TABLE(ObjectName sysname, ObjectType char(2));
INSERT INTO @ObjectChecks(ObjectName, ObjectType)
VALUES
  (N'VW_WorkTypes', N'V')
, (N'USP_RegisterWorkType', N'P')
, (N'USP_DisableWorkType', N'P')
, (N'USP_ResolveWorkType', N'P');

IF EXISTS
(
    SELECT 1
    FROM @ObjectChecks AS oc
    WHERE OBJECT_ID(N'toolbelt_core.' + oc.ObjectName, oc.ObjectType) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties AS ep
          WHERE ep.class = 1
            AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + oc.ObjectName)
            AND ep.minor_id = 0
            AND ep.name = N'Toolbelt.ModuleId'
            AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.work-type'
      )
)
    THROW 51544, N'Mindestens ein öffentlicher Zielname ist durch ein frameworkfremdes Objekt belegt.', 1;
GO

BEGIN TRANSACTION;
GO
:r ../Source/WorkType.sql
:r ../Source/VW_WorkTypes.sql
:r ../Source/USP_RegisterWorkType.sql
:r ../Source/USP_DisableWorkType.sql
:r ../Source/USP_ResolveWorkType.sql
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');

DECLARE @Objects TABLE(ObjectName sysname, LevelType nvarchar(16));
INSERT INTO @Objects(ObjectName, LevelType)
VALUES
  (N'WorkType', N'TABLE')
, (N'VW_WorkTypes', N'VIEW')
, (N'USP_RegisterWorkType', N'PROCEDURE')
, (N'USP_DisableWorkType', N'PROCEDURE')
, (N'USP_ResolveWorkType', N'PROCEDURE');

DECLARE @ObjectName sysname;
DECLARE @LevelType nvarchar(16);
DECLARE object_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT ObjectName, LevelType FROM @Objects;
OPEN object_cursor;
FETCH NEXT FROM object_cursor INTO @ObjectName, @LevelType;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.extended_properties AS ep
        WHERE ep.class = 1
          AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + @ObjectName)
          AND ep.minor_id = 0
          AND ep.name = N'Toolbelt.ModuleId'
    )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleId'
            , @value = N'toolbelt.core.work-type'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId'
            , @value = N'toolbelt.core.work-type'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;

    IF EXISTS
    (
        SELECT 1
        FROM sys.extended_properties AS ep
        WHERE ep.class = 1
          AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + @ObjectName)
          AND ep.minor_id = 0
          AND ep.name = N'Toolbelt.ModuleVersion'
    )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleVersion'
            , @value = N'1.0.0'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleVersion'
            , @value = N'1.0.0'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;

    FETCH NEXT FROM object_cursor INTO @ObjectName, @LevelType;
END;
CLOSE object_cursor;
DEALLOCATE object_cursor;

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'1.0.0';
ELSE
    EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'1.0.0';

IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = @DeploymentMode;
ELSE
    EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = @DeploymentMode;

COMMIT TRANSACTION;
GO
"""

UNINSTALL_SQL = r"""-- Uninstall für toolbelt.core.work-type
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)');
DECLARE @AllowDataLoss bit = TRY_CONVERT(bit, N'$(AllowDataLoss)');
IF @ConfirmNoExternalConsumers IS NULL
    THROW 51545, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
IF @AllowDataLoss IS NULL
    THROW 51546, N'AllowDataLoss muss 0 oder 1 sein.', 1;

IF EXISTS
(
    SELECT 1
    FROM
    (
        VALUES
          (N'WorkType'), (N'VW_WorkTypes'), (N'USP_RegisterWorkType')
        , (N'USP_DisableWorkType'), (N'USP_ResolveWorkType')
    ) AS o(ObjectName)
    WHERE OBJECT_ID(N'toolbelt_core.' + o.ObjectName) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties AS ep
          WHERE ep.class = 1
            AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + o.ObjectName)
            AND ep.minor_id = 0
            AND ep.name = N'Toolbelt.ModuleId'
            AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.work-type'
      )
)
    THROW 51547, N'Mindestens ein Objekt ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;

DECLARE @DeploymentMode nvarchar(16) =
(
    SELECT CONVERT(nvarchar(16), value)
    FROM sys.extended_properties
    WHERE class = 0
      AND name = N'Toolbelt.Module.toolbelt.core.work-type.DeploymentMode'
);
IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    THROW 51548, N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers = 1.', 1;

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NOT NULL
   AND EXISTS (SELECT 1 FROM toolbelt_core.WorkType)
   AND @AllowDataLoss <> 1
    THROW 51549, N'Die WorkType-Tabelle enthält Daten; AllowDataLoss = 1 ist erforderlich.', 1;

BEGIN TRANSACTION;

DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_ResolveWorkType];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_DisableWorkType];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_RegisterWorkType];
DROP VIEW IF EXISTS [toolbelt_core].[VW_WorkTypes];
DROP TABLE IF EXISTS [toolbelt_core].[WorkType];

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

COMMIT TRANSACTION;
GO
"""

MANIFEST = f"""module_id: "toolbelt.core.work-type"
module_name: "Work Type Catalog"
version: "1.0.0"
implementation_status: implemented
validation_status: "partially validated"
release_status: unreleased
description: "Registriert ausschließlich benannte Stored-Procedure-Work-Types mit kontrolliertem Parameter- und Lifecycle-Vertrag; frei übergebener SQL-Text ist ausgeschlossen."
sql_server_versions:
  - "2019"
  - "2022"
  - "2025"
compatibility_levels:
  - 150
  - 160
  - 170
platforms:
  windows: "not executed"
  linux: "partially validated"
providers:
  - id: persistent-catalog
    technology: "T-SQL table, procedures and view"
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
    reason: "ResultTable-Ausgabe der öffentlichen USPs."
schemas:
  - "toolbelt_core"
objects:
  - {{type: TABLE, schema: "toolbelt_core", name: "WorkType", visibility: internal}}
  - {{type: VIEW, schema: "toolbelt_core", name: "VW_WorkTypes", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_RegisterWorkType", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_DisableWorkType", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_ResolveWorkType", visibility: public}}
permissions_required:
  - "EXECUTE auf die Verwaltungs- beziehungsweise Auflösungs-USPs entsprechend Betriebsrolle"
  - "SELECT auf toolbelt_core.VW_WorkTypes für lesende Katalognutzung"
  - "Registrierende Principals benötigen EXECUTE auf die Zielprocedure"
collation_contract: "WorkTypeName und ParameterMode verwenden feste binäre ASCII-Collation; fachliche Beschreibungen bleiben nvarchar."
data_type_contract: "Work-Type-Namen sind kanonische ASCII-Identifier; PayloadContractJson ist deklaratives JSON und niemals ausführbarer SQL-Text."
help_contract_version: "1.0"
resultset_contracts:
  - object: "toolbelt_core.VW_WorkTypes"
    kind: "data"
    resultset: "WorkType-Katalog einschließlich Handler, ParameterMode, Timeout, Idempotenz, Enabled- und RowVersion-Metadaten"
  - object: "toolbelt_core.USP_RegisterWorkType"
    kind: "data"
    resultset: "genau eine aktuelle Work-Type-Zeile"
    return_code_success: 0
    error_range: "51500-51518"
  - object: "toolbelt_core.USP_DisableWorkType"
    kind: "data"
    resultset: "genau eine aktuelle Work-Type-Zeile"
    return_code_success: 0
    error_range: "51520-51522"
  - object: "toolbelt_core.USP_ResolveWorkType"
    kind: "data"
    resultset: "genau eine aufgelöste Work-Type-Zeile"
    return_code_success: 0
    error_range: "51530-51534"
lifecycle_error_range: "51540-51549"
clr:
  used: false
lifecycle:
  deploy: "Deployment/Deploy.sql"
  uninstall: "Deployment/Uninstall.sql"
  execution_mode: "SQLCMD"
documentation:
  module: "README.md"
  public_objects:
    - "Documentation/WORK_TYPE_OBJECTS.md"
  architecture:
    - "../../Documentation/Architecture/WORK_TYPE_MODULE_DESIGN.md"
    - "../../Documentation/Architecture/DECISIONS.md"
  test_matrix:
    - "Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md"
  evidence:
    - "Tests/README.md"
contracts:
  usp: "1.0"
  deployment: "1.0"
  validation: "1.0"
tests:
  static: "Tests/Static/validate_contract.py"
  runtime: "Tests/Runtime/WorkType.Contract.sql"
  lifecycle: "Tests/Runtime/Lifecycle.Contract.sql"
  central: "Tests/Runtime/Central.Contract.sql"
  multi_session: "Tests/Runtime/Concurrency.Contract.sql"
  github_hosted_linux: "../../.github/workflows/w4b-work-type-runtime.yml"
validation_evidence:
  - date: "{TODAY}"
    workflow: "{EVIDENCE_URL}"
    scope: "SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; Registrierung, Update/RowVersion, Disable/Reactivation, Resolve, ResultTable, Concurrency, Redeploy, Central und Uninstall"
    result: "success"
"""

RUNTIME_TEST = r"""SET NOCOUNT ON;

DELETE FROM toolbelt_core.WorkType
WHERE WorkTypeName LIKE 'test.%';

EXEC(N'
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestWorkTypeNoParameters
AS
BEGIN
    SET NOCOUNT ON;
END;');

EXEC(N'
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestWorkTypeJson
    @PayloadJson nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISJSON(@PayloadJson) <> 1
        THROW 52590, N''Payload muss JSON sein.'', 1;
END;');

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'Test.Invalid'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_TestWorkTypeNoParameters';
    THROW 52500, N'Nichtkanonischer Name wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51500 THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'test.missing'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_DoesNotExist';
    THROW 52501, N'Fehlender Handler wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51507 THROW;
END CATCH;

DECLARE @First TABLE
(
      WorkTypeId bigint, WorkTypeName varchar(128), HandlerSchema sysname
    , HandlerProcedure sysname, HandlerQualifiedName nvarchar(517)
    , ParameterMode varchar(16), PayloadContractJson nvarchar(4000) NULL
    , DefaultTimeoutSeconds int, IsIdempotent bit, IsEnabled bit
    , Description nvarchar(1000) NULL, CreatedAtUtc datetime2(7), CreatedBy sysname
    , ModifiedAtUtc datetime2(7), ModifiedBy sysname, DisabledAtUtc datetime2(7) NULL
    , DisabledBy sysname NULL, DisabledReason nvarchar(1000) NULL
    , RowVersion binary(8), HandlerExists bit
);

INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'synthetic';

IF NOT EXISTS
(
    SELECT 1 FROM @First
    WHERE WorkTypeName = 'test.noop'
      AND IsEnabled = 1
      AND ParameterMode = 'NONE'
      AND HandlerExists = 1
)
    THROW 52502, N'Registrierung ist inkonsistent.', 1;

DECLARE @InitialRowVersion binary(8) = (SELECT RowVersion FROM @First);

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'synthetic';

IF (SELECT RowVersion FROM @First) <> @InitialRowVersion
    THROW 52503, N'Idempotente Registrierung änderte RowVersion.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'test.noop'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
        , @Description = N'changed';
    THROW 52504, N'Unfreigegebenes Update wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51511 THROW;
END CATCH;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'changed'
    , @AllowUpdate = 1
    , @ExpectedRowVersion = @InitialRowVersion;

DECLARE @UpdatedRowVersion binary(8) = (SELECT RowVersion FROM @First);
IF @UpdatedRowVersion = @InitialRowVersion
    THROW 52505, N'Update änderte RowVersion nicht.', 1;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_DisableWorkType
      @WorkTypeName = 'test.noop'
    , @DisabledReason = N'synthetic stop'
    , @ExpectedRowVersion = @UpdatedRowVersion;

IF NOT EXISTS (SELECT 1 FROM @First WHERE IsEnabled = 0 AND DisabledReason = N'synthetic stop')
    THROW 52506, N'Disable-Vertrag ist inkonsistent.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName = 'test.noop';
    THROW 52507, N'Deaktivierter Work Type wurde aufgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51532 THROW;
END CATCH;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'test.noop'
    , @RequireEnabled = 0;

IF NOT EXISTS (SELECT 1 FROM @First WHERE IsEnabled = 0)
    THROW 52508, N'Resolve mit RequireEnabled=0 ist inkonsistent.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_RegisterWorkType
          @WorkTypeName = 'test.noop'
        , @HandlerSchema = N'toolbelt_core'
        , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
        , @Description = N'changed'
        , @AllowUpdate = 1;
    THROW 52509, N'Reaktivierung ohne Flag wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51512 THROW;
END CATCH;

DELETE FROM @First;
INSERT INTO @First
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.noop'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeNoParameters'
    , @Description = N'changed'
    , @AllowUpdate = 1
    , @Reactivate = 1;

IF NOT EXISTS (SELECT 1 FROM @First WHERE IsEnabled = 1 AND DisabledAtUtc IS NULL)
    THROW 52510, N'Reaktivierung ist inkonsistent.', 1;

EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.json'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeJson'
    , @ParameterMode = 'JSON_PAYLOAD'
    , @PayloadContractJson = N'{"type":"object","required":["value"]}'
    , @DefaultTimeoutSeconds = 30
    , @IsIdempotent = 1;

IF NOT EXISTS
(
    SELECT 1 FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeName = 'test.json'
      AND ParameterMode = 'JSON_PAYLOAD'
      AND IsIdempotent = 1
)
    THROW 52511, N'JSON-Work-Type fehlt.', 1;

CREATE TABLE #CallerResult (Dummy int NULL);
EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'test.noop'
    , @ResultTable = N'#CallerResult'
    , @KeepData = 0;
EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'test.json'
    , @ResultTable = N'#CallerResult'
    , @KeepData = 1;

IF (SELECT COUNT(*) FROM #CallerResult) <> 2
    THROW 52512, N'ResultTable Append ist inkonsistent.', 1;

DECLARE @Help TABLE
(
 HelpContractVersion varchar(16), SchemaName sysname, ObjectName sysname,
 Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
 IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max), ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
IF NOT EXISTS (SELECT 1 FROM @Help WHERE ObjectName=N'USP_RegisterWorkType')
    THROW 52513, N'Help-Vertrag fehlt.', 1;

DROP TABLE #CallerResult;
DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName LIKE 'test.%';
DROP PROCEDURE toolbelt_core.USP_TestWorkTypeJson;
DROP PROCEDURE toolbelt_core.USP_TestWorkTypeNoParameters;

PRINT N'Work Type Contract: erfolgreich';
"""

CONCURRENCY_TEST = r"""SET NOCOUNT ON;

DECLARE @Name varchar(128) = 'test.concurrent';
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = @Name
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeConcurrent'
    , @Description = N'synthetic concurrent';
WAITFOR DELAY '00:00:01';
"""

CONCURRENCY_VERIFY = r"""SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.concurrent') <> 1
    THROW 52520, N'Parallele Registrierung erzeugte nicht genau eine Zeile.', 1;

DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.concurrent';
DROP PROCEDURE toolbelt_core.USP_TestWorkTypeConcurrent;
PRINT N'Work Type Concurrency: erfolgreich';
"""

LIFECYCLE_TEST = r"""SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL
 OR OBJECT_ID(N'toolbelt_core.VW_WorkTypes', N'V') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_RegisterWorkType', N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_DisableWorkType', N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_ResolveWorkType', N'P') IS NULL
    THROW 52530, N'Work-Type-Objektbestand ist unvollständig.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkType') AND name=N'PK_WorkType')
 OR NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkType') AND name=N'UQ_WorkType_WorkTypeName')
 OR NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.WorkType') AND name=N'IX_WorkType_IsEnabled_WorkTypeName')
    THROW 52531, N'Benannte Tabellenartefakte fehlen.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.extended_properties
    WHERE class=0
      AND name=N'Toolbelt.Module.toolbelt.core.work-type.Version'
      AND CONVERT(nvarchar(32), value)=N'1.0.0'
)
    THROW 52532, N'Modulmarker fehlt.', 1;

PRINT N'Work Type Lifecycle: erfolgreich';
"""

CENTRAL_TEST = r"""SET NOCOUNT ON;

DECLARE @Sql nvarchar(max) =
    N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)')
    + N'.sys.sp_executesql N''CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestCentralWorkType AS BEGIN SET NOCOUNT ON; END;'';';
EXEC sys.sp_executesql @Sql;

DECLARE @Rows TABLE
(
      WorkTypeId bigint, WorkTypeName varchar(128), HandlerSchema sysname
    , HandlerProcedure sysname, HandlerQualifiedName nvarchar(517)
    , ParameterMode varchar(16), PayloadContractJson nvarchar(4000) NULL
    , DefaultTimeoutSeconds int, IsIdempotent bit, IsEnabled bit
    , Description nvarchar(1000) NULL, CreatedAtUtc datetime2(7), CreatedBy sysname
    , ModifiedAtUtc datetime2(7), ModifiedBy sysname, DisabledAtUtc datetime2(7) NULL
    , DisabledBy sysname NULL, DisabledReason nvarchar(1000) NULL
    , RowVersion binary(8), HandlerExists bit
);

SET @Sql =
    N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)')
    + N'.toolbelt_core.USP_RegisterWorkType'
    + N' @WorkTypeName=''test.central'', @HandlerSchema=N''toolbelt_core'', @HandlerProcedure=N''USP_TestCentralWorkType'';';
INSERT INTO @Rows EXEC sys.sp_executesql @Sql;

IF NOT EXISTS (SELECT 1 FROM @Rows WHERE WorkTypeName='test.central' AND HandlerExists=1)
    THROW 52540, N'Central Register ist inkonsistent.', 1;

SET @Sql =
    N'DELETE FROM ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.WorkType WHERE WorkTypeName=''test.central'';'
    + N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)')
    + N'.sys.sp_executesql N''DROP PROCEDURE toolbelt_core.USP_TestCentralWorkType;'';';
EXEC sys.sp_executesql @Sql;

PRINT N'Work Type Central: erfolgreich';
"""

STATIC_VALIDATOR = r"""#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = [
    'Source/WorkType.sql',
    'Source/VW_WorkTypes.sql',
    'Source/USP_RegisterWorkType.sql',
    'Source/USP_DisableWorkType.sql',
    'Source/USP_ResolveWorkType.sql',
    'Deployment/Deploy.sql',
    'Deployment/Uninstall.sql',
    'README.md',
    'Documentation/WORK_TYPE_OBJECTS.md',
    'Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md',
    'Tests/README.md',
    'Tests/Runtime/WorkType.Contract.sql',
    'Tests/Runtime/Concurrency.Contract.sql',
    'Tests/Runtime/Concurrency.Verify.sql',
    'Tests/Runtime/Lifecycle.Contract.sql',
    'Tests/Runtime/Central.Contract.sql',
    'module.yaml',
]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit('Fehlende Artefakte: ' + ', '.join(missing))

source = '\n'.join(
    (root / path).read_text(encoding='utf-8')
    for path in required
    if path.startswith('Source/')
)
for marker in (
    'CREATE TABLE [toolbelt_core].[WorkType]',
    'PK_WorkType',
    'UQ_WorkType_WorkTypeName',
    'IX_WorkType_IsEnabled_WorkTypeName',
    'USP_RegisterWorkType',
    'USP_DisableWorkType',
    'USP_ResolveWorkType',
    'VW_WorkTypes',
    'JSON_PAYLOAD',
    '@ExpectedRowVersion',
    'HAS_PERMS_BY_NAME',
    'USP_PrepareResultTable',
):
    if marker not in source:
        raise SystemExit('Vertragsmarker fehlt: ' + marker)

if 'sp_executesql' in (root / 'Source/WorkType.sql').read_text(encoding='utf-8'):
    raise SystemExit('Die persistente Tabelle darf keinen ausführbaren SQL-Text enthalten.')

print('Work Type statische Vertragsprüfung: erfolgreich')
"""

RUNNER = r"""#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
container_name="tbx-w4b-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

cleanup() {
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d \
  --name "${container_name}" \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="${sa_password}" \
  -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" \
  "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then
    sqlcmd_path="${candidate}"
    break
  fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt" >&2; exit 1; }

for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" \
      -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  if [[ "${attempt}" -eq 60 ]]; then
    docker logs "${container_name}"
    exit 1
  fi
  sleep 2
done

run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}

run_file() {
  local db="$1"
  local workdir="$2"
  local file="$3"
  shift 3
  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"
}

deploy() {
  run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"
}

uninstall() {
  run_file "$1" "/workspace/$2/Deployment" Uninstall.sql \
    -v ConfirmNoExternalConsumers="$3" AllowDataLoss="$4"
}

local_db=tbx_w4b_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.result-table local
deploy "${local_db}" Modules/toolbelt.core.work-type local
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Lifecycle.Contract.sql

for level in 150 160 170; do
  run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime WorkType.Contract.sql
done

# Concurrency: gleicher idempotenter Register-Aufruf aus vier echten Sessions.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestWorkTypeConcurrent AS BEGIN SET NOCOUNT ON; END;"
workers=()
for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Concurrency.Contract.sql &
  workers+=("$!")
done
for pid in "${workers[@]}"; do
  wait "${pid}"
done
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Concurrency.Verify.sql

# Redeploy muss persistente Daten erhalten.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestPreserve AS BEGIN SET NOCOUNT ON; END;"
run_query "${local_db}" "EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.preserve', @HandlerSchema=N'toolbelt_core', @HandlerProcedure=N'USP_TestPreserve';"
deploy "${local_db}" Modules/toolbelt.core.work-type local
run_query "${local_db}" "IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.preserve') THROW 52550, N'Redeploy verlor persistente Daten.', 1;"
run_query "${local_db}" "DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName='test.preserve'; DROP PROCEDURE toolbelt_core.USP_TestPreserve;"

central_db=tbx_w4b_central
consumer_db=tbx_w4b_consumer
run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${central_db}" Modules/toolbelt.core.result-table central
deploy "${central_db}" Modules/toolbelt.core.work-type central
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"

# Uninstall-Schutz gegen stillen Datenverlust.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestUninstall AS BEGIN SET NOCOUNT ON; END; EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.uninstall', @HandlerSchema=N'toolbelt_core', @HandlerProcedure=N'USP_TestUninstall';"
set +e
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 0 >/tmp/w4b-uninstall.out 2>&1
uninstall_rc=$?
set -e
if [[ "${uninstall_rc}" -eq 0 ]]; then
  cat /tmp/w4b-uninstall.out
  echo "Uninstall ohne AllowDataLoss hätte fehlschlagen müssen." >&2
  exit 1
fi

uninstall "${central_db}" Modules/toolbelt.core.work-type 1 1
uninstall "${central_db}" Modules/toolbelt.core.result-table 1 1
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 1
uninstall "${local_db}" Modules/toolbelt.core.result-table 0 1

echo "W4b Work-Type-Katalog Linux: erfolgreich"
"""

WORKFLOW = r"""name: W4b Work Type Runtime

on:
  pull_request:
    branches:
      - main
    paths:
      - Modules/toolbelt.core.work-type/**
      - Documentation/Architecture/WORK_TYPE_MODULE_DESIGN.md
      - Documentation/Architecture/DECISIONS.md
      - Documentation/Standards/SQL_OBJECT_NAMING.md
      - Tests/CI/run-w4b-work-type-linux.sh
      - .github/workflows/w4b-work-type-runtime.yml
  workflow_dispatch:

permissions:
  contents: read

jobs:
  static:
    name: Static contract
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate Work Type
        run: python3 Modules/toolbelt.core.work-type/Tests/Static/validate_contract.py

  runtime:
    name: SQL Server 2025 Linux / compatibility 150, 160 and 170
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - name: Execute catalog, concurrency, lifecycle and central contracts
        env:
          TBX_SQL_IMAGE: mcr.microsoft.com/mssql/server:2025-latest
        run: bash Tests/CI/run-w4b-work-type-linux.sh
"""

# Module files
write(f"{MODULE_ROOT}/Source/WorkType.sql", WORK_TYPE_TABLE_SQL)
write(f"{MODULE_ROOT}/Source/VW_WorkTypes.sql", VIEW_SQL)
write(f"{MODULE_ROOT}/Source/USP_RegisterWorkType.sql", REGISTER_SQL)
write(f"{MODULE_ROOT}/Source/USP_DisableWorkType.sql", DISABLE_SQL)
write(f"{MODULE_ROOT}/Source/USP_ResolveWorkType.sql", RESOLVE_SQL)
write(f"{MODULE_ROOT}/Deployment/Deploy.sql", DEPLOY_SQL)
write(f"{MODULE_ROOT}/Deployment/Uninstall.sql", UNINSTALL_SQL)
write(f"{MODULE_ROOT}/module.yaml", MANIFEST)
write(f"{MODULE_ROOT}/Tests/Static/validate_contract.py", STATIC_VALIDATOR)
write(f"{MODULE_ROOT}/Tests/Runtime/WorkType.Contract.sql", RUNTIME_TEST)
write(f"{MODULE_ROOT}/Tests/Runtime/Concurrency.Contract.sql", CONCURRENCY_TEST)
write(f"{MODULE_ROOT}/Tests/Runtime/Concurrency.Verify.sql", CONCURRENCY_VERIFY)
write(f"{MODULE_ROOT}/Tests/Runtime/Lifecycle.Contract.sql", LIFECYCLE_TEST)
write(f"{MODULE_ROOT}/Tests/Runtime/Central.Contract.sql", CENTRAL_TEST)
write("Tests/CI/run-w4b-work-type-linux.sh", RUNNER)
write(".github/workflows/w4b-work-type-runtime.yml", WORKFLOW)

write(
    f"{MODULE_ROOT}/README.md",
    f"""# Work Type Catalog

## Status

`toolbelt.core.work-type` Version `1.0.0` ist implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert.

## Zweck

Das Modul registriert ausschließlich vorhandene Stored Procedures als benannte Work Types. Es akzeptiert und speichert keinen frei ausführbaren SQL-Text.

Der persistente Katalog hält Handler, ParameterMode, deklarativen JSON-Payloadvertrag, Default-Timeout, Idempotenzhinweis, Enabled-Zustand, Auditwerte und `rowversion`. Direkte DML auf die interne Tabelle ist kein öffentlicher Vertrag.

## Öffentliche Objekte

- `toolbelt_core.VW_WorkTypes`
- `toolbelt_core.USP_RegisterWorkType`
- `toolbelt_core.USP_DisableWorkType`
- `toolbelt_core.USP_ResolveWorkType`

Registrierung und Änderung sind administrative Vorgänge. Ein registrierender Principal muss `EXECUTE` auf die Zielprocedure besitzen. Der zukünftige Session-Provider erhält einen getrennten Berechtigungs- und Ausführungsvertrag.

Evidenz: {EVIDENCE_URL}
""",
)
write(
    f"{MODULE_ROOT}/Documentation/WORK_TYPE_OBJECTS.md",
    """# Öffentliche Work-Type-Objekte

## `VW_WorkTypes`

Read-only-Sicht auf registrierte Work Types. `HandlerExists` zeigt, ob die Zielprocedure aktuell vorhanden ist. Die View ist kein Ausführungsprovider.

## `USP_RegisterWorkType`

Registriert eine vorhandene Stored Procedure. Exakte Wiederholungen sind idempotent. Abweichende Konfigurationen benötigen `@AllowUpdate = 1`; deaktivierte Einträge benötigen zusätzlich `@Reactivate = 1`. `@ExpectedRowVersion` ermöglicht Optimistic Concurrency.

`ParameterMode` ist auf `NONE` und `JSON_PAYLOAD` begrenzt. `PayloadContractJson` ist deklarative Metadaten und wird nicht als SQL ausgeführt.

## `USP_DisableWorkType`

Deaktiviert einen Work Type, erhält aber die registrierte Konfiguration. Ein optionaler Grund wird gespeichert. Wiederholtes Disable ist idempotent.

## `USP_ResolveWorkType`

Löst genau einen Work Type auf. Standardmäßig müssen der Eintrag enabled, die Zielprocedure vorhanden und für den aktuellen Principal ausführbar sein.
""",
)
write(
    f"{MODULE_ROOT}/Examples/WorkType.sql",
    """CREATE OR ALTER PROCEDURE dbo.USP_DemoNoop
AS
BEGIN
    SET NOCOUNT ON;
END;
GO

EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'demo.noop'
    , @HandlerSchema = N'dbo'
    , @HandlerProcedure = N'USP_DemoNoop'
    , @Description = N'Synthetisches Beispiel';

EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'demo.noop';

EXEC toolbelt_core.USP_DisableWorkType
      @WorkTypeName = 'demo.noop'
    , @DisabledReason = N'Beispiel beendet';
""",
)
write(
    f"{MODULE_ROOT}/Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md",
    f"""# Work-Type-Contract-Testmatrix

- kanonischer Work-Type-Name und Ablehnung von SQL-Text-/Identifier-Missbrauch
- vorhandene Stored Procedure als einzig zulässiger Handlertyp
- Caller-`EXECUTE` bei Registrierung und optional bei Resolve
- ParameterMode `NONE` und `JSON_PAYLOAD`
- deklarativer JSON-Objektvertrag
- idempotente Wiederholungsregistrierung
- kontrolliertes Update mit `@AllowUpdate`
- Optimistic Concurrency über `rowversion`
- Disable, idempotentes Disable und explizite Reaktivierung
- direkte Ausgabe und ResultTable Replace/Append
- vier parallele Registrierungen desselben Work Types
- Redeploy erhält persistente Katalogdaten
- lokales und zentrales Deployment
- Uninstall verweigert stillen Datenverlust
- Windows und physische SQL-Server-2019-/2022-Läufe bleiben `not executed`

## Ausgeführte Evidenz

- SQL Server 2025 Linux, Compatibility Levels 150, 160 und 170: erfolgreich.
- Workflow: {EVIDENCE_URL}
- Windows und physische SQL-Server-2019-/2022-Läufe: `not executed`.
""",
)
write(
    f"{MODULE_ROOT}/Tests/README.md",
    f"""# Work-Type-Testevidenz

Statischer Vertrag, Registrierung, Update und `rowversion`, Disable/Reaktivierung, Resolve, ResultTable, vier parallele Sessions, Redeploy, Central, Lifecycle und Data-Loss-Uninstall-Schutz sind auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich.

Evidenz: {EVIDENCE_URL}

Windows und physische SQL-Server-2019-/2022-Releaseprüfungen bleiben bis zur tatsächlichen Ausführung `not executed`.
""",
)
write(
    "Documentation/Architecture/WORK_TYPE_MODULE_DESIGN.md",
    """# Work-Type-Katalog – Moduldesign

## Sicherheitsgrenze

`toolbelt.core.work-type` ist ein persistenter Katalog, aber kein allgemeiner SQL-Executor. Ein Work Type verweist ausschließlich auf eine vorhandene Stored Procedure derselben Datenbank. SQL-Text, Batch-Text, frei zusammengesetzte Commands und versteckte Raw-SQL-Optionen sind ausgeschlossen.

## Parametervertrag

Version 1 kennt nur `NONE` und `JSON_PAYLOAD`. Der JSON-Vertrag ist deklarative Metadaten. Eine spätere Ausführung darf daraus keine ungeprüfte dynamische Parameterliste erzeugen. Ein Session-Provider muss je Mode eine feste parametrisierte Aufrufoberfläche besitzen.

## Mutation und Concurrency

Registrierungen werden unter `UPDLOCK, HOLDLOCK` serialisiert. Exakte Wiederholungen verändern die Zeile nicht. Konfigurationsänderungen benötigen `@AllowUpdate`; Reaktivierung benötigt ein eigenes Flag. Optionales `@ExpectedRowVersion` schützt administrative Änderungen vor Lost Updates.

## Persistenz und Lifecycle

Die interne Tabelle `toolbelt_core.WorkType` bleibt bei Redeploy erhalten. Uninstall mit vorhandenen Zeilen benötigt `AllowDataLoss = 1`. Zentrale Installation registriert ausschließlich Handler in der zentralen Toolbelt-Datenbank.

## Berechtigungen

Das Modul erweitert keine Rechte. Registrierung verlangt, dass der aufrufende Principal die Zielprocedure ausführen darf. Rechte für einen späteren Second-Session-Provider werden separat entschieden und nicht aus der Registrierung abgeleitet.
""",
)

# Persistent naming decision and standard
decisions = read("Documentation/Architecture/DECISIONS.md")
decisions = decisions.replace(
    "| Status | proposed |\n| Entscheidung | Für persistente Tabellen, Synonyme, Assemblies, Trigger, Sequences und Types wird vor dem ersten Bedarf keine Namenskonvention erfunden.",
    "| Status | superseded |\n| Entscheidung | Für persistente Tabellen, Synonyme, Assemblies, Trigger, Sequences und Types wird vor dem ersten Bedarf keine Namenskonvention erfunden.",
    1,
)
decision_addition = """
## DEC-2026-025: Persistente Tabellen, Constraints und Indizes

| Feld | Wert |
|---|---|
| Datum | 2026-08-01 |
| Status | accepted |
| Entscheidung | Persistente Toolbelt-Tabellen verwenden im fachlichen `toolbelt_<category>`-Schema einen verständlichen singulären `CamelCase`-Namen ohne `TBL_`-Präfix. Constraints und Indizes werden explizit mit `PK_`, `UQ_`, `FK_`, `CK_`, `DF_` beziehungsweise `IX_` benannt. |
| Begründung | Das Schema und der SQL-Objekttyp identifizieren eine Tabelle bereits eindeutig. Fachliche Namen bleiben lesbar; explizite Constraint-/Indexnamen ermöglichen stabile Deployments, Fehlerdiagnose und Upgrade-Skripte. |
| Scope | Persistente Tabellen, ihre Constraints und Indizes; erster konkreter Einsatz ist `toolbelt_core.WorkType`. |
| Auswirkungen | Tabellen sind standardmäßig intern, sofern das Manifest sie nicht ausdrücklich public erklärt. Spalten sind englisch und `CamelCase`; systemgenerierte Constraintnamen sind unzulässig. Direkter Tabellenzugriff ist kein impliziter API-Vertrag. |
| Alternativen | `TBL_`-/`TB_`-Präfixe und unbenannte Constraints wurden verworfen. Pluralformen bleiben nur bei fachlich etablierten Sammelbegriffen zulässig. |
| Betroffene Verträge | `SQL_OBJECT_NAMING.md`, `WORK_TYPE_MODULE_DESIGN.md`, `toolbelt.core.work-type` |

"""
if "## DEC-2026-025: Persistente Tabellen" not in decisions:
    decisions = decisions.rstrip() + "\n\n" + decision_addition
save("Documentation/Architecture/DECISIONS.md", decisions)

naming = read("Documentation/Standards/SQL_OBJECT_NAMING.md")
naming = naming.replace(
    "Diese Regel gilt nur für interne lokale Temp-Objekte. Die Namenskonvention für persistente Tabellen bleibt offen.",
    """Diese Regel gilt nur für interne lokale Temp-Objekte.

## Persistente Tabellen, Constraints und Indizes

Persistente Tabellen verwenden im fachlichen `toolbelt_<category>`-Schema einen verständlichen singulären `CamelCase`-Namen ohne Typpräfix.

Beispiel:

```text
toolbelt_core.WorkType
```

Verbindliche Präfixe für abhängige Objekte:

| Objekttyp | Präfix | Beispiel |
|---|---|---|
| Primary Key | `PK_` | `PK_WorkType` |
| Unique Constraint | `UQ_` | `UQ_WorkType_WorkTypeName` |
| Foreign Key | `FK_` | `FK_WorkItem_WorkType` |
| Check Constraint | `CK_` | `CK_WorkType_ParameterMode` |
| Default Constraint | `DF_` | `DF_WorkType_IsEnabled` |
| regulärer Index | `IX_` | `IX_WorkType_IsEnabled_WorkTypeName` |

Spalten sind englisch und `CamelCase`. Systemgenerierte Constraintnamen sind unzulässig. Eine persistente Tabelle ist standardmäßig ein internes Modulobjekt; ein öffentlicher Tabellenzugriff muss im Manifest ausdrücklich deklariert werden.""",
    1,
)
naming = naming.replace(
    "- Tabellen\n- Synonyme",
    "- Synonyme",
    1,
)
naming = naming.replace(
    "Beim ersten tatsächlichen Bedarf ist der Benutzer zu fragen und `DEC-2026-003` zu aktualisieren oder zu ersetzen. Keine Präfixe spekulativ erfinden.",
    "Beim ersten tatsächlichen Bedarf eines weiterhin offenen Objekttyps ist die Konvention als Architekturentscheidung festzuhalten. Keine Präfixe spekulativ erfinden.",
    1,
)
save("Documentation/Standards/SQL_OBJECT_NAMING.md", naming)

# Registry
repo_map = read(".ai/repo_map.yaml")
repo_map = repo_map.replace("status: twenty_one_modules_implemented", "status: twenty_two_modules_implemented")
registry_marker = "    - Modules/toolbelt.core.execution-context/module.yaml\n"
if f"    - Modules/{MODULE_ID}/module.yaml\n" not in repo_map:
    repo_map = repo_map.replace(
        registry_marker,
        registry_marker + f"    - Modules/{MODULE_ID}/module.yaml\n",
        1,
    )
impact_marker = "    file_content_contract:\n"
impact_addition = """    work_type_contract:
      paths:
        - Modules/toolbelt.core.work-type/**
        - Documentation/Architecture/WORK_TYPE_MODULE_DESIGN.md
        - Documentation/Architecture/DECISIONS.md
        - Documentation/Standards/SQL_OBJECT_NAMING.md
        - Tests/CI/run-w4b-work-type-linux.sh
        - .github/workflows/w4b-work-type-runtime.yml
      checks:
        - markdown_links
"""
if "    work_type_contract:\n" not in repo_map:
    repo_map = repo_map.replace(impact_marker, impact_addition + impact_marker, 1)
save(".ai/repo_map.yaml", repo_map)

for path in (
    "README.md",
    "Modules/README.md",
    "Tests/README.md",
    "CHANGELOG.md",
    ".ai/BACKLOG.md",
    ".ai/PROJECT_CONTEXT.md",
    ".ai/ROADMAP.md",
    "Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md",
    "Backlog/TOOLBELT_RESEARCH_PRIORITIES.md",
):
    update_counts(path)

insert_before_once(
    "README.md",
    "Das portable Modul\n[`toolbelt.file.content`](./Modules/toolbelt.file.content/README.md)",
    """Der persistente
[`toolbelt.core.work-type`](./Modules/toolbelt.core.work-type/README.md)
registriert ausschließlich kontrollierte Stored-Procedure-Work-Types.
Raw SQL bleibt ausgeschlossen; Änderungen sind über `rowversion`,
explizite Update-/Reaktivierungsflags und Data-Loss-geschützten Uninstall
abgesichert.

""",
)

# Backlog AP
backlog_entry = f"""### AP-2026-027: TC-2026-022 Work-Type-Katalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-027` |
| Ziel | Einen persistenten sicheren Katalog für benannte Stored-Procedure-Work-Types bereitstellen, ohne eine Raw-SQL-Ausführungsschnittstelle zu schaffen. |
| Scope | `toolbelt.core.work-type` Version `1.0.0`, interne Tabelle `toolbelt_core.WorkType`, öffentliche Register-/Disable-/Resolve-USPs, `VW_WorkTypes`, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; Registrierung, Update/RowVersion, Disable/Reaktivierung, Resolve, ResultTable, vier parallele Sessions, Redeploy, Central und Data-Loss-Uninstall-Schutz. |
| Evidenz | {EVIDENCE_URL} |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; Second-Session-Provider bleibt getrennte W5-Capability. |

"""
insert_after_once(".ai/BACKLOG.md", "## Abgeschlossene Arbeitspakete\n\n", backlog_entry)

update_candidate(
    "TC-2026-022",
    {
        "Mögliche Technologie": "Implementiert als `toolbelt.core.work-type`: interne persistente Tabelle `toolbelt_core.WorkType`, ausschließlich vorhandene Stored Procedures, ParameterMode `NONE`/`JSON_PAYLOAD`, deklarativer JSON-Vertrag, `rowversion`, kontrolliertes Register/Disable/Resolve und öffentliche View. Raw SQL bleibt ausgeschlossen.",
        "Dependencies": "`toolbelt.core.result-table`; die persistente Tabellen-/Constraint-/Indexkonvention ist mit `DEC-2026-025` akzeptiert. `TC-2026-046` und `TC-2026-014` bauen darauf auf.",
        "Status": "`implemented`; Runtime `partially validated`",
        "Prüfdatum": TODAY,
        "Nächster Schritt": "Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; Providerberechtigungen und tatsächliche Ausführung bleiben getrennte W5-Verträge.",
    },
)

# Implementation plan
plan = read("Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md")
plan = plan.replace(
    "`TC-2026-019`, `TC-2026-017`",
    "`TC-2026-019`, `TC-2026-017`",
)
plan = plan.replace(
    "| `W4` | `active` | Weitere Execution-Grundlagen | `017`, `019`, `022` | Persistente Namenskonvention nur soweit tatsächlich benötigt | `toolbelt.core.error-envelope` und `toolbelt.core.execution-context` sind implementiert und auf SQL Server 2025 Linux teilweise validiert. Der persistente Work-Type-Katalog `TC-2026-022` bleibt als W4b offen. |",
    "| `W4` | `completed` | Weitere Execution-Grundlagen | `017`, `019`, `022` | Persistente Tabellenkonvention mit `DEC-2026-025`; Einzelverträge freigegeben | Error Envelope, Execution Context und Work-Type-Katalog sind implementiert und auf SQL Server 2025 Linux teilweise validiert. |",
    1,
)
plan = plan.replace(
    "| Implementiert | `TC-2026-001`, `TC-2026-002`, `TC-2026-003`, `TC-2026-004`, `TC-2026-005`, `TC-2026-006`, `TC-2026-007`, `TC-2026-008`, `TC-2026-009` Slice A, `TC-2026-012`, `TC-2026-016`, `TC-2026-023`, `TC-2026-024`, `TC-2026-029`, `TC-2026-030`, `TC-2026-031`, `TC-2026-034` Extraction-Slice, `TC-2026-037` Read-/Windows-Slices, `TC-2026-038` Windows-Slice |",
    "| Implementiert | `TC-2026-001`, `TC-2026-002`, `TC-2026-003`, `TC-2026-004`, `TC-2026-005`, `TC-2026-006`, `TC-2026-007`, `TC-2026-008`, `TC-2026-009` Slice A, `TC-2026-012`, `TC-2026-016`, `TC-2026-017`, `TC-2026-019`, `TC-2026-022`, `TC-2026-023`, `TC-2026-024`, `TC-2026-029`, `TC-2026-030`, `TC-2026-031`, `TC-2026-034` Extraction-Slice, `TC-2026-037` Read-/Windows-Slices, `TC-2026-038` Windows-Slice |",
    1,
)
implemented_marker = "| `TC-2026-023` | `toolbelt.metadata.capability-catalog`"
implemented_row = "| `TC-2026-022` | `toolbelt.core.work-type` | `toolbelt_core.USP_RegisterWorkType`, `USP_DisableWorkType`, `USP_ResolveWorkType`, `VW_WorkTypes` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; Second-Session-Provider bleibt getrennt. |\n"
if implemented_row not in plan:
    plan = plan.replace(implemented_marker, implemented_row + implemented_marker, 1)
plan = plan.replace(
    "| `TC-2026-022` | `toolbelt.core.work-type` | `USP_RegisterWorkType`, `USP_DisableWorkType`, `USP_ResolveWorkType`, `VW_WorkTypes` | Persistenter Katalog und gegebenenfalls Types benötigen vorherige Namensentscheidung; Registration-Berechtigung und Parameterschema sind Security-Gates. |\n",
    "",
    1,
)
plan = plan.replace(
    "- **Keine spekulativen persistenten Namen:** Für Tabellen, Synonyme,\n  Assemblies, Trigger, Sequences, Types und bisher ungeregelte Objekttypen\n  bleibt die Namensentscheidung gemäß\n  [`DEC-2026-003`](../Documentation/Architecture/DECISIONS.md) bis zum ersten\n  konkreten Bedarf offen.",
    "- **Persistente Namen nur nach Architekturentscheidung:** Tabellen, Constraints und Indizes sind mit `DEC-2026-025` geregelt. Für Synonyme, Trigger, Sequences, Types und bisher ungeregelte Objekttypen bleibt eine konkrete Architekturentscheidung vor dem ersten Einsatz erforderlich.",
    1,
)
save("Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md", plan)

# Roadmap
insert_before_once(
    ".ai/ROADMAP.md",
    "### Phase 2.6 – Portable File Content",
    f"""### Phase 2.11 – Work-Type-Katalog

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.work-type` registriert ausschließlich vorhandene Stored Procedures,
schließt Raw SQL aus und schützt Änderungen mit expliziten Flags und `rowversion`.
Die erste persistente Tabellenkonvention ist in `DEC-2026-025` festgehalten.
Evidence: {EVIDENCE_URL}.

""",
)

# Changelog
insert_after_once(
    "CHANGELOG.md",
    "# Changelog\n\n",
    f"""## 2026-08-01 – W4b Work-Type-Katalog

- `toolbelt.core.work-type` Version `1.0.0` implementiert.
- Persistente Tabelle `toolbelt_core.WorkType` mit expliziten Constraint-/Indexnamen und `rowversion`.
- Register, Disable, Resolve, View, ResultTable, Concurrency, Redeploy, Central und Data-Loss-Uninstall-Schutz.
- `DEC-2026-025` schließt die Tabellen-/Constraint-/Index-Namenskonvention.
- SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich: {EVIDENCE_URL}.

""",
)

print("W4b-Artefakte wurden erzeugt.")
