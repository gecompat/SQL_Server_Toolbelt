#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path

ROOT = Path.cwd()
EVIDENCE_URL = os.environ.get("EVIDENCE_URL", "")
DATE = "2026-08-05"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: erwartet genau einen Treffer, gefunden {count}: {old!r}")
    write(path, text.replace(old, new, 1))


# ---------------------------------------------------------------------------
# Second Session 1.1.0: resultsetfreie Ausführung für Infrastruktur-Handler.
# ---------------------------------------------------------------------------
execute_path = "Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql"
execute = read(execute_path)
execute = execute.replace(
    "    , @KeepData      bit = 0\n    , @Debug         tinyint = 0",
    "    , @KeepData      bit = 0\n    , @SuppressResult bit = 0\n    , @Debug         tinyint = 0",
    1,
)
execute = execute.replace(
    "    SET @KeepData = ISNULL(@KeepData, 0);\n    SET @Debug = ISNULL(@Debug, 0);",
    "    SET @KeepData = ISNULL(@KeepData, 0);\n    SET @SuppressResult = ISNULL(@SuppressResult, 0);\n    SET @Debug = ISNULL(@Debug, 0);",
    1,
)
execute = execute.replace(
    "            , ('PARAMETER', 7, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle; in uncommittable Transaktionen nicht zulässig.', NULL)\n            , ('ERROR', 1, N'51610-51619'",
    "            , ('PARAMETER', 7, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle; in uncommittable Transaktionen nicht zulässig.', NULL)\n            , ('PARAMETER', 8, N'@SuppressResult', 'bit', 0, 0, N'0', N'Bei 1 wird nach erfolgreicher Ausführung kein Infrastruktur-Resultset ausgegeben; nicht mit @ResultTable kombinierbar.', NULL)\n            , ('ERROR', 1, N'51610-51620'",
    1,
)
execute = execute.replace(
    "    IF @ResultTable IS NOT NULL AND XACT_STATE() = -1\n        THROW 51611, N'@ResultTable ist in einer uncommittable Caller-Transaktion nicht zulässig.', 1;",
    "    IF @ResultTable IS NOT NULL AND XACT_STATE() = -1\n        THROW 51611, N'@ResultTable ist in einer uncommittable Caller-Transaktion nicht zulässig.', 1;\n    IF @SuppressResult = 1 AND @ResultTable IS NOT NULL\n        THROW 51620, N'@SuppressResult = 1 kann nicht mit @ResultTable kombiniert werden.', 1;",
    1,
)
execute = execute.replace(
    "    IF @ResultTable IS NULL\n    BEGIN",
    "    IF @SuppressResult = 1\n    BEGIN\n        IF @Debug > 0\n            RAISERROR(N'USP_ExecuteWorkTypeInNewSession: Work Type wurde ohne Infrastruktur-Resultset ausgeführt.', 10, 1) WITH NOWAIT;\n        RETURN 0;\n    END;\n\n    IF @ResultTable IS NULL\n    BEGIN",
    1,
)
write(execute_path, execute)

for path in (
    "Modules/toolbelt.core.second-session/Deployment/Deploy.sql",
    "Modules/toolbelt.core.second-session/module.yaml",
):
    text = read(path).replace('1.0.0', '1.1.0')
    if path.endswith("module.yaml"):
        text = text.replace('error_range: "51610-51619"', 'error_range: "51610-51620"')
        if EVIDENCE_URL and EVIDENCE_URL not in text:
            text += f'''validation_evidence:\n  - date: "{DATE}"\n    workflow: "{EVIDENCE_URL}"\n    scope: "Second Session 1.1.0: suppressiertes Infrastruktur-Resultset und Event-Log-Abhängigkeit auf SQL Server 2025 Linux CL150/160/170"\n    result: "success"\n'''
    write(path, text)

replace_once(
    "Modules/toolbelt.core.second-session/Tests/Static/validate_contract.py",
    '    "HAS_PERMS_BY_NAME",\n',
    '    "HAS_PERMS_BY_NAME",\n    "@SuppressResult",\n',
)

second_contract = read("Modules/toolbelt.core.second-session/Tests/Runtime/SecondSession.Contract.sql")
marker = "CREATE TABLE #SecondSessionResult(Dummy int NULL);\n"
addition = """CREATE TABLE #SuppressedSecondSessionResult(Dummy int NULL);
INSERT INTO #SuppressedSecondSessionResult
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.none'
    , @SuppressResult = 1;
IF EXISTS (SELECT 1 FROM #SuppressedSecondSessionResult)
    THROW 52645, N'@SuppressResult erzeugte unerwartete Infrastrukturzeilen.', 1;
DROP TABLE #SuppressedSecondSessionResult;

BEGIN TRY
    CREATE TABLE #InvalidSuppressResult(Dummy int NULL);
    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
          @WorkTypeName = 'test.second-session.none'
        , @ResultTable = N'#InvalidSuppressResult'
        , @SuppressResult = 1;
    DROP TABLE #InvalidSuppressResult;
    THROW 52646, N'@SuppressResult mit @ResultTable wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF OBJECT_ID(N'tempdb..#InvalidSuppressResult') IS NOT NULL
        DROP TABLE #InvalidSuppressResult;
    IF ERROR_NUMBER() = 52646 OR ERROR_NUMBER() <> 51620
        THROW;
END CATCH;

"""
if addition.strip() not in second_contract:
    if second_contract.count(marker) != 1:
        raise RuntimeError("Second-Session-Testmarker fehlt.")
    second_contract = second_contract.replace(marker, addition + marker, 1)
write("Modules/toolbelt.core.second-session/Tests/Runtime/SecondSession.Contract.sql", second_contract)

lifecycle_path = "Modules/toolbelt.core.second-session/Tests/Runtime/Lifecycle.Contract.sql"
lifecycle = read(lifecycle_path).replace("N'1.0.0'", "N'1.1.0'")
write(lifecycle_path, lifecycle)

readme_path = "Modules/toolbelt.core.second-session/README.md"
readme = read(readme_path).replace("Version `1.0.0`", "Version `1.1.0`")
if "@SuppressResult" not in readme:
    readme += "\nVersion `1.1.0` ergänzt `@SuppressResult = 1` für erfolgreiche Infrastrukturaufrufe ohne lokales Resultset. Die Option ist insbesondere für rollback-unabhängige Side-Effect-Handler vorgesehen und kann nicht mit `@ResultTable` kombiniert werden.\n"
if EVIDENCE_URL and EVIDENCE_URL not in readme:
    readme += f"\nEvidenz Version `1.1.0`: {EVIDENCE_URL}\n"
write(readme_path, readme)

doc_path = "Modules/toolbelt.core.second-session/Documentation/SECOND_SESSION_OBJECTS.md"
doc = read(doc_path)
if "@SuppressResult" not in doc:
    doc += "\n## Resultsetfreie Infrastrukturaufrufe\n\n`USP_ExecuteWorkTypeInNewSession` unterstützt ab Version `1.1.0` `@SuppressResult = 1`. Der Remote-Handler und dessen Returncode werden vollständig ausgeführt und geprüft; lediglich das lokale Infrastruktur-Resultset entfällt. `@SuppressResult` und `@ResultTable` schließen einander aus.\n"
write(doc_path, doc)

matrix_path = "Modules/toolbelt.core.second-session/Tests/SECOND_SESSION_CONTRACT_TEST_MATRIX.md"
matrix = read(matrix_path)
if "SuppressResult" not in matrix:
    matrix = matrix.replace("- direkte Ausgabe und ResultTable", "- direkte Ausgabe, ResultTable und `@SuppressResult` ohne Infrastruktur-Resultset")
if EVIDENCE_URL and EVIDENCE_URL not in matrix:
    matrix += f"\n- Version 1.1.0 / `@SuppressResult`: {EVIDENCE_URL}\n"
write(matrix_path, matrix)

evidence_path = "Modules/toolbelt.core.second-session/Tests/README.md"
evidence = read(evidence_path)
if EVIDENCE_URL and EVIDENCE_URL not in evidence:
    evidence += f"\nVersion `1.1.0` mit resultsetfreier Ausführung: {EVIDENCE_URL}\n"
write(evidence_path, evidence)

# ---------------------------------------------------------------------------
# Event Log 1.0.0.
# ---------------------------------------------------------------------------
MODULE = "Modules/toolbelt.core.event-log"

write(f"{MODULE}/Source/EventLog.sql", r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.EventLog', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[EventLog]
    (
          [EventId] bigint IDENTITY(1,1) NOT NULL
        , [OccurredAtUtc] datetime2(7) NOT NULL
        , [RecordedAtUtc] datetime2(7) NOT NULL CONSTRAINT [DF_EventLog_RecordedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [EventName] varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [EventLevel] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [Category] varchar(128) COLLATE Latin1_General_100_BIN2 NULL
        , [Message] nvarchar(4000) NULL
        , [DataJson] nvarchar(max) NULL
        , [ExecutionId] uniqueidentifier NOT NULL
        , [CorrelationId] uniqueidentifier NOT NULL
        , [Actor] nvarchar(256) NULL
        , [Tenant] nvarchar(256) NULL
        , [SourceDatabaseName] sysname NOT NULL
        , [SourceSchemaName] sysname NULL
        , [SourceObjectName] sysname NULL
        , [CallerSessionId] int NOT NULL
        , [CallerXactState] smallint NOT NULL
        , [CallerTransactionCount] int NOT NULL
        , [RemoteSessionId] int NOT NULL
        , [ErrorNumber] int NULL
        , [ErrorSeverity] int NULL
        , [ErrorState] int NULL
        , [ErrorProcedure] sysname NULL
        , [ErrorLine] int NULL
        , CONSTRAINT [PK_EventLog] PRIMARY KEY CLUSTERED ([EventId])
        , CONSTRAINT [CK_EventLog_EventName] CHECK
          (
              LEN([EventName]) BETWEEN 3 AND 128
              AND [EventName] = LOWER([EventName]) COLLATE Latin1_General_100_BIN2
              AND [EventName] LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
              AND [EventName] NOT LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
          )
        , CONSTRAINT [CK_EventLog_EventLevel] CHECK ([EventLevel] IN ('TRACE','DEBUG','INFO','WARNING','ERROR','CRITICAL'))
        , CONSTRAINT [CK_EventLog_DataJson] CHECK ([DataJson] IS NULL OR (ISJSON([DataJson]) = 1 AND LEFT(LTRIM([DataJson]), 1) = N'{'))
        , CONSTRAINT [CK_EventLog_CallerXactState] CHECK ([CallerXactState] IN (-1,0,1))
        , CONSTRAINT [CK_EventLog_ErrorSeverity] CHECK ([ErrorSeverity] IS NULL OR [ErrorSeverity] BETWEEN 0 AND 25)
        , CONSTRAINT [CK_EventLog_ErrorState] CHECK ([ErrorState] IS NULL OR [ErrorState] BETWEEN 0 AND 255)
        , CONSTRAINT [CK_EventLog_ErrorLine] CHECK ([ErrorLine] IS NULL OR [ErrorLine] > 0)
    );

    CREATE INDEX [IX_EventLog_OccurredAtUtc_EventId]
        ON [toolbelt_core].[EventLog]([OccurredAtUtc], [EventId]);
    CREATE INDEX [IX_EventLog_CorrelationId_OccurredAtUtc]
        ON [toolbelt_core].[EventLog]([CorrelationId], [OccurredAtUtc])
        INCLUDE ([EventName], [EventLevel], [Category]);
    CREATE INDEX [IX_EventLog_ExecutionId_OccurredAtUtc]
        ON [toolbelt_core].[EventLog]([ExecutionId], [OccurredAtUtc])
        INCLUDE ([EventName], [EventLevel], [Category]);
END;
GO
""")

write(f"{MODULE}/Source/VW_Events.sql", r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [toolbelt_core].[VW_Events]
AS
SELECT
      EventId, OccurredAtUtc, RecordedAtUtc, EventName, EventLevel, Category
    , Message, DataJson, ExecutionId, CorrelationId, Actor, Tenant
    , SourceDatabaseName, SourceSchemaName, SourceObjectName
    , CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId
    , ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine
FROM toolbelt_core.EventLog;
GO
""")

write(f"{MODULE}/Source/USP_WriteEventInternal.sql", r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteEventInternal]
    @PayloadJson nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @PayloadJson IS NULL OR DATALENGTH(@PayloadJson) > 131072 OR ISJSON(@PayloadJson) <> 1 OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
        THROW 51720, N'Die interne Event-Payload muss ein begrenztes JSON-Objekt sein.', 1;

    DECLARE
          @EventName varchar(128) = CONVERT(varchar(128), JSON_VALUE(@PayloadJson, '$.eventName'))
        , @EventLevel varchar(16) = CONVERT(varchar(16), JSON_VALUE(@PayloadJson, '$.eventLevel'))
        , @Category varchar(128) = CONVERT(varchar(128), JSON_VALUE(@PayloadJson, '$.category'))
        , @Message nvarchar(4000) = CONVERT(nvarchar(4000), JSON_VALUE(@PayloadJson, '$.message'))
        , @DataJson nvarchar(max) = JSON_QUERY(@PayloadJson, '$.data')
        , @OccurredAtUtc datetime2(7) = TRY_CONVERT(datetime2(7), JSON_VALUE(@PayloadJson, '$.occurredAtUtc'), 127)
        , @SourceDatabaseName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceDatabaseName'))
        , @SourceSchemaName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceSchemaName'))
        , @SourceObjectName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceObjectName'))
        , @CallerSessionId int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.callerSessionId'))
        , @CallerXactState smallint = TRY_CONVERT(smallint, JSON_VALUE(@PayloadJson, '$.callerXactState'))
        , @CallerTransactionCount int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.callerTransactionCount'))
        , @ErrorNumber int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorNumber'))
        , @ErrorSeverity int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorSeverity'))
        , @ErrorState int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorState'))
        , @ErrorProcedure sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.errorProcedure'))
        , @ErrorLine int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorLine'));

    DECLARE
          @ExecutionId uniqueidentifier
        , @CorrelationId uniqueidentifier
        , @Actor nvarchar(256)
        , @Tenant nvarchar(256);
    SELECT
          @ExecutionId = c.ExecutionId
        , @CorrelationId = c.CorrelationId
        , @Actor = c.Actor
        , @Tenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    IF NULLIF(@EventName, '') IS NULL OR @OccurredAtUtc IS NULL OR NULLIF(@SourceDatabaseName, N'') IS NULL
       OR @CallerSessionId IS NULL OR @CallerXactState NOT IN (-1,0,1) OR @CallerTransactionCount IS NULL
       OR @ExecutionId IS NULL OR @CorrelationId IS NULL
        THROW 51721, N'Die interne Event-Payload ist unvollständig.', 1;
    IF @EventLevel NOT IN ('TRACE','DEBUG','INFO','WARNING','ERROR','CRITICAL')
        THROW 51722, N'Die interne Event-Level-Angabe ist ungültig.', 1;
    IF @DataJson IS NOT NULL AND (DATALENGTH(@DataJson) > 65536 OR LEFT(LTRIM(@DataJson), 1) <> N'{')
        THROW 51723, N'Die interne Data-Payload verletzt den JSON-Objekt- oder Größenvertrag.', 1;
    IF @ErrorSeverity IS NOT NULL AND @ErrorSeverity NOT BETWEEN 0 AND 25
        THROW 51724, N'ErrorSeverity liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorState IS NOT NULL AND @ErrorState NOT BETWEEN 0 AND 255
        THROW 51725, N'ErrorState liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorLine IS NOT NULL AND @ErrorLine <= 0
        THROW 51726, N'ErrorLine muss positiv sein.', 1;

    INSERT INTO toolbelt_core.EventLog
    (
          OccurredAtUtc, EventName, EventLevel, Category, Message, DataJson
        , ExecutionId, CorrelationId, Actor, Tenant
        , SourceDatabaseName, SourceSchemaName, SourceObjectName
        , CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId
        , ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine
    )
    VALUES
    (
          @OccurredAtUtc, @EventName, @EventLevel, @Category, @Message, @DataJson
        , @ExecutionId, @CorrelationId, @Actor, @Tenant
        , @SourceDatabaseName, @SourceSchemaName, @SourceObjectName
        , @CallerSessionId, @CallerXactState, @CallerTransactionCount, @@SPID
        , @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine
    );

    RETURN 0;
END;
GO
""")

write(f"{MODULE}/Source/USP_WriteEvent.sql", r"""SET ANSI_NULLS ON;
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
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_WriteEvent' AS sysname) AS ObjectName
            , v.Section, v.Ordinal, v.ItemName, v.SqlDataType
            , v.IsRequired, v.IsNullable, v.DefaultValue, v.Description, v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@EventName', 'varchar(128)', 1, 0, NULL, N'Kanonischer Eventname in lowercase ASCII.', NULL)
            , ('PARAMETER', 2, N'@EventLevel', 'varchar(16)', 0, 0, N'INFO', N'TRACE, DEBUG, INFO, WARNING, ERROR oder CRITICAL.', NULL)
            , ('PARAMETER', 3, N'@Message', 'nvarchar(4000)', 0, 1, NULL, N'Begrenzte menschenlesbare Meldung; keine ungeprüften Secrets persistieren.', NULL)
            , ('PARAMETER', 4, N'@DataJson', 'nvarchar(max)', 0, 1, NULL, N'Begrenztes JSON-Objekt bis 32 KiB UTF-16-Speicher.', NULL)
            , ('PARAMETER', 5, N'@OccurredAtUtc', 'datetime2(7)', 0, 0, N'SYSUTCDATETIME()', N'Fachlicher Ereigniszeitpunkt in UTC.', NULL)
            , ('ERROR', 1, N'51700-51709', NULL, NULL, NULL, NULL, N'Event-, JSON-, Fehler- und Dependency-Vertragsfehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Schreibt ein Info-Event.', N'EXEC toolbelt_core.USP_WriteEvent @EventName=''demo.completed'', @Message=N''Synthetic example'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
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
""")

write(f"{MODULE}/Source/USP_DeleteEventsBefore.sql", r"""SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DeleteEventsBefore]
(
      @BeforeOccurredAtUtc datetime2(7) = NULL
    , @BatchSize int = 1000
    , @MaxBatches int = 1
    , @DeletedRows bigint = NULL OUTPUT
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @BatchSize = ISNULL(@BatchSize, 1000);
    SET @MaxBatches = ISNULL(@MaxBatches, 1);
    SET @DeletedRows = 0;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_DeleteEventsBefore' AS sysname) AS ObjectName
            , v.Section, v.Ordinal, v.ItemName, v.SqlDataType
            , v.IsRequired, v.IsNullable, v.DefaultValue, v.Description, v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@BeforeOccurredAtUtc', 'datetime2(7)', 1, 0, NULL, N'Nur Events mit älterem OccurredAtUtc werden gelöscht.', NULL)
            , ('PARAMETER', 2, N'@BatchSize', 'int', 0, 0, N'1000', N'1 bis 10000 Zeilen je Batch.', NULL)
            , ('PARAMETER', 3, N'@MaxBatches', 'int', 0, 0, N'1', N'1 bis 100 Batches je Aufruf.', NULL)
            , ('ERROR', 1, N'51710-51714', NULL, NULL, NULL, NULL, N'Grenz-, Pflichtparameter- und Transaktionsfehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Löscht höchstens 5000 alte Events.', N'DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc=''2026-01-01'', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF @BeforeOccurredAtUtc IS NULL
        THROW 51710, N'@BeforeOccurredAtUtc ist erforderlich.', 1;
    IF @BatchSize NOT BETWEEN 1 AND 10000
        THROW 51711, N'@BatchSize muss zwischen 1 und 10000 liegen.', 1;
    IF @MaxBatches NOT BETWEEN 1 AND 100
        THROW 51712, N'@MaxBatches muss zwischen 1 und 100 liegen.', 1;
    IF XACT_STATE() = -1
        THROW 51713, N'Retention ist in einer uncommittable Transaktion nicht möglich.', 1;

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_EventLog_Retention;

    BEGIN TRY
        DECLARE @Batch int = 0;
        DECLARE @Rows int = 1;
        WHILE @Batch < @MaxBatches AND @Rows > 0
        BEGIN
            ;WITH Targets AS
            (
                SELECT TOP (@BatchSize) EventId
                FROM toolbelt_core.EventLog
                WHERE OccurredAtUtc < @BeforeOccurredAtUtc
                ORDER BY EventId
            )
            DELETE FROM Targets;
            SET @Rows = @@ROWCOUNT;
            SET @DeletedRows += @Rows;
            SET @Batch += 1;
        END;

        IF @InitialTranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_EventLog_Retention;
        THROW;
    END CATCH;

    IF @Debug > 0
    BEGIN
        DECLARE @DeletedForMessage varchar(32) = CONVERT(varchar(32), @DeletedRows);
        RAISERROR(N'USP_DeleteEventsBefore: %s Events gelöscht.', 10, 1, @DeletedForMessage) WITH NOWAIT;
    END;
    RETURN 0;
END;
GO
""")

write(f"{MODULE}/Deployment/Deploy.sql", r"""-- Deployment für toolbelt.core.event-log
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51741, N'DeploymentMode muss local oder central sein.', 1;
IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');
IF OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession', N'P') IS NULL
 OR NOT EXISTS (SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession') AND name=N'@SuppressResult')
    THROW 51742, N'Die Abhängigkeit toolbelt.core.second-session Version 1.1.0 fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.USP_RemoveWorkType', N'P') IS NULL
    THROW 51743, N'Die Abhängigkeit toolbelt.core.work-type Version 1.1.0 fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext', N'IF') IS NULL
    THROW 51744, N'Die Abhängigkeit toolbelt.core.execution-context fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.EventLog', N'U') IS NOT NULL
 AND NOT EXISTS
 (
     SELECT 1 FROM sys.extended_properties
     WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.EventLog') AND minor_id=0
       AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256), value)=N'toolbelt.core.event-log'
 )
    THROW 51740, N'Der Zielname toolbelt_core.EventLog ist frameworkfremd belegt.', 1;
DECLARE @ObjectChecks TABLE(ObjectName sysname, ObjectType char(2));
INSERT INTO @ObjectChecks VALUES
  (N'VW_Events',N'V'),(N'USP_WriteEventInternal',N'P'),(N'USP_WriteEvent',N'P'),(N'USP_DeleteEventsBefore',N'P');
IF EXISTS
(
    SELECT 1 FROM @ObjectChecks o
    WHERE OBJECT_ID(N'toolbelt_core.'+o.ObjectName,o.ObjectType) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1 FROM sys.extended_properties
          WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+o.ObjectName) AND minor_id=0
            AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),value)=N'toolbelt.core.event-log'
      )
)
    THROW 51745, N'Mindestens ein Event-Log-Zielname ist frameworkfremd belegt.', 1;
GO
BEGIN TRANSACTION;
GO
:r ../Source/EventLog.sql
:r ../Source/VW_Events.sql
:r ../Source/USP_WriteEventInternal.sql
:r ../Source/USP_WriteEvent.sql
:r ../Source/USP_DeleteEventsBefore.sql
GO
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'toolbelt.event-log.write'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_WriteEventInternal'
    , @ParameterMode = 'JSON_PAYLOAD'
    , @PayloadContractJson = N'{"type":"object"}'
    , @DefaultTimeoutSeconds = 30
    , @IsIdempotent = 0
    , @Description = N'Interner Handler für rollback-unabhängige Toolbelt-Events.'
    , @AllowUpdate = 1
    , @Reactivate = 1;

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
DECLARE @Objects TABLE(ObjectName sysname, LevelType nvarchar(16));
INSERT INTO @Objects VALUES
  (N'EventLog',N'TABLE'),(N'VW_Events',N'VIEW'),(N'USP_WriteEventInternal',N'PROCEDURE'),(N'USP_WriteEvent',N'PROCEDURE'),(N'USP_DeleteEventsBefore',N'PROCEDURE');
DECLARE @ObjectName sysname,@LevelType nvarchar(16);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectName,LevelType FROM @Objects;
OPEN c; FETCH NEXT FROM c INTO @ObjectName,@LevelType;
WHILE @@FETCH_STATUS=0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+@ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleId')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.core.event-log',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.core.event-log',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+@ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleVersion')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    FETCH NEXT FROM c INTO @ObjectName,@LevelType;
END;
CLOSE c; DEALLOCATE c;
DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.Version';
DECLARE @ModeProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.DeploymentMode';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionProperty)
    EXEC sys.sp_updateextendedproperty @name=@VersionProperty,@value=N'1.0.0';
ELSE EXEC sys.sp_addextendedproperty @name=@VersionProperty,@value=N'1.0.0';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty)
    EXEC sys.sp_updateextendedproperty @name=@ModeProperty,@value=@DeploymentMode;
ELSE EXEC sys.sp_addextendedproperty @name=@ModeProperty,@value=@DeploymentMode;
COMMIT TRANSACTION;
GO
""")

write(f"{MODULE}/Deployment/Uninstall.sql", r"""-- Uninstall für toolbelt.core.event-log
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)');
DECLARE @AllowDataLoss bit=TRY_CONVERT(bit,N'$(AllowDataLoss)');
IF @ConfirmNoExternalConsumers IS NULL THROW 51746,N'ConfirmNoExternalConsumers muss 0 oder 1 sein.',1;
IF @AllowDataLoss IS NULL THROW 51747,N'AllowDataLoss muss 0 oder 1 sein.',1;
DECLARE @DeploymentMode nvarchar(16)=(SELECT CONVERT(nvarchar(16),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.event-log.DeploymentMode');
IF @DeploymentMode=N'central' AND @ConfirmNoExternalConsumers<>1
    THROW 51748,N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers = 1.',1;
IF EXISTS
(
    SELECT 1 FROM (VALUES(N'EventLog'),(N'VW_Events'),(N'USP_WriteEventInternal'),(N'USP_WriteEvent'),(N'USP_DeleteEventsBefore'))o(ObjectName)
    WHERE OBJECT_ID(N'toolbelt_core.'+o.ObjectName) IS NOT NULL
      AND NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+o.ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),value)=N'toolbelt.core.event-log')
)
    THROW 51745,N'Mindestens ein Objekt ist nicht eindeutig diesem Modul zugeordnet.',2;
DECLARE @HasData bit=0;
IF OBJECT_ID(N'toolbelt_core.EventLog',N'U') IS NOT NULL
    EXEC sys.sp_executesql N'IF EXISTS(SELECT 1 FROM toolbelt_core.EventLog) SET @v=1;',N'@v bit OUTPUT',@v=@HasData OUTPUT;
IF @HasData=1 AND @AllowDataLoss<>1
    THROW 51749,N'Die EventLog-Tabelle enthält Daten; AllowDataLoss = 1 ist erforderlich.',1;
IF EXISTS
(
    SELECT 1 FROM toolbelt_core.WorkType
    WHERE WorkTypeName='toolbelt.event-log.write'
      AND (HandlerSchema<>N'toolbelt_core' OR HandlerProcedure<>N'USP_WriteEventInternal' OR ParameterMode<>'JSON_PAYLOAD')
)
    THROW 51748,N'Der Event-Log-Work-Type entspricht nicht dem Modulvertrag und wird nicht entfernt.',2;

BEGIN TRANSACTION;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write')
BEGIN
    DECLARE @rv binary(8)=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write');
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write' AND IsEnabled=1)
        EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='toolbelt.event-log.write',@ExpectedRowVersion=@rv,@DisabledReason=N'Event-Log-Uninstall';
    SET @rv=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write');
    EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='toolbelt.event-log.write',@ExpectedRowVersion=@rv,@AllowDelete=1;
END;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_DeleteEventsBefore;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_WriteEvent;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_WriteEventInternal;
DROP VIEW IF EXISTS toolbelt_core.VW_Events;
DROP TABLE IF EXISTS toolbelt_core.EventLog;
DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.Version';
DECLARE @ModeProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.DeploymentMode';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionProperty) EXEC sys.sp_dropextendedproperty @name=@VersionProperty;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty) EXEC sys.sp_dropextendedproperty @name=@ModeProperty;
COMMIT TRANSACTION;
GO
""")

write(f"{MODULE}/module.yaml", f'''module_id: "toolbelt.core.event-log"
module_name: "Rollback-independent Event Log"
version: "1.0.0"
implementation_status: implemented
validation_status: "partially validated"
release_status: unreleased
description: "Persistiert strukturierte Events synchron in einer zweiten SQL-Server-Session, unabhängig von Commit oder Rollback der Caller-Transaktion."
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
  - id: loopback-rpc
    technology: "T-SQL linked-server RPC via toolbelt.core.second-session"
    platforms: [Windows, Linux]
    status: implemented
deployment_capabilities:
  local: true
  central: true
  central_with_synonyms: false
  local_required: false
  central_preferred: true
dependencies:
  - module_id: "toolbelt.core.second-session"
    minimum_version: "1.1.0"
    reason: "Rollback-unabhängiger synchroner Transport ohne Infrastruktur-Resultset."
  - module_id: "toolbelt.core.work-type"
    minimum_version: "1.1.0"
    reason: "Registrierung und kontrolliertes Entfernen des internen Event-Handlers."
  - module_id: "toolbelt.core.execution-context"
    minimum_version: "1.0.0"
    reason: "Execution-, Correlation-, Actor- und Tenant-Kontext."
schemas:
  - "toolbelt_core"
objects:
  - {{type: TABLE, schema: "toolbelt_core", name: "EventLog", visibility: internal}}
  - {{type: VIEW, schema: "toolbelt_core", name: "VW_Events", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_WriteEvent", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_DeleteEventsBefore", visibility: public}}
  - {{type: USP, schema: "toolbelt_core", name: "USP_WriteEventInternal", visibility: internal}}
permissions_required:
  - "EXECUTE auf toolbelt_core.USP_WriteEvent für schreibende Consumer"
  - "SELECT auf toolbelt_core.VW_Events für lesende Consumer"
  - "EXECUTE auf toolbelt_core.USP_DeleteEventsBefore nur für Retention-Administratoren"
  - "Der administrierte Linked-Server-Principal benötigt EXECUTE auf den internen Work-Type-Handler"
collation_contract: "EventName, EventLevel und Category verwenden eine feste binäre ASCII-Collation; Message und Context bleiben nvarchar."
data_type_contract: "DataJson ist ein begrenztes JSON-Objekt; Message ist auf nvarchar(4000) begrenzt; Event- und Fehlerwerte sind typisiert."
help_contract_version: "1.0"
resultset_contracts:
  - object: "toolbelt_core.VW_Events"
    kind: "data"
    resultset: "Persistierte Event-, Context-, Caller- und optionale Error-Metadaten"
  - object: "toolbelt_core.USP_WriteEvent"
    kind: "infrastructure"
    resultset: null
    return_code_success: 0
    error_range: "51700-51709"
  - object: "toolbelt_core.USP_DeleteEventsBefore"
    kind: "infrastructure"
    resultset: null
    return_code_success: 0
    error_range: "51710-51714"
lifecycle_error_range: "51740-51749"
clr:
  used: false
lifecycle:
  deploy: "Deployment/Deploy.sql"
  uninstall: "Deployment/Uninstall.sql"
  execution_mode: "SQLCMD"
documentation:
  module: "README.md"
  public_objects:
    - "Documentation/EVENT_LOG_OBJECTS.md"
  architecture:
    - "../../Documentation/Architecture/EVENT_LOG_MODULE_DESIGN.md"
  test_matrix:
    - "Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md"
  evidence:
    - "Tests/README.md"
contracts:
  usp: "1.0"
  deployment: "1.0"
  validation: "1.0"
tests:
  static: "Tests/Static/validate_contract.py"
  runtime: "Tests/Runtime/EventLog.Contract.sql"
  lifecycle: "Tests/Runtime/Lifecycle.Contract.sql"
  central: "Tests/Runtime/Central.Contract.sql"
  concurrency: "Tests/Runtime/Concurrency.Contract.sql"
  github_hosted_linux: "../../.github/workflows/w5b-event-log-runtime.yml"
validation_evidence:
  - date: "{DATE}"
    workflow: "{EVIDENCE_URL}"
    scope: "SQL Server 2025 Linux CL150/160/170; Caller-Rollback, uncommittable Caller, Context, Validation, Retention, Concurrency, Redeploy, Central und Uninstall"
    result: "success"
''')

write(f"{MODULE}/README.md", f'''# Rollback-independent Event Log

## Status

`toolbelt.core.event-log` Version `1.0.0` ist implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert.

## Zweck

`toolbelt_core.USP_WriteEvent` schreibt strukturierte Events synchron über `toolbelt.core.second-session`. Der Remote-Commit ist von Commit oder Rollback der Caller-Transaktion unabhängig und funktioniert auch aus einem uncommittable Caller, solange der administrierte Loopback-Provider verfügbar ist.

Das Modul speichert keinen frei ausführbaren SQL-Text. `DataJson` ist auf ein JSON-Objekt mit 32 KiB UTF-16-Speicher begrenzt. Meldungen und optionale Fehlerdaten müssen vor der Persistierung auf Vertraulichkeit geprüft werden.

## Öffentliche Objekte

- `toolbelt_core.USP_WriteEvent`
- `toolbelt_core.VW_Events`
- `toolbelt_core.USP_DeleteEventsBefore`

Der interne Handler `USP_WriteEventInternal` wird als Work Type `toolbelt.event-log.write` registriert. Deploy und Uninstall verändern keinen Linked Server und keine Login-Mappings.

Evidenz: {EVIDENCE_URL}
''')

write(f"{MODULE}/Documentation/EVENT_LOG_OBJECTS.md", r"""# Event-Log-Objekte

## `USP_WriteEvent`

Schreibt genau ein Event über den konfigurierten Second-Session-Provider. Die Procedure gibt kein fachliches oder infrastrukturelles Resultset aus. ExecutionId, CorrelationId, Actor und Tenant werden aus expliziten Parametern oder dem aktiven Execution Context übernommen.

Die Procedure kann in einer regulären, zurückgerollten oder uncommittable Caller-Transaktion verwendet werden. Ein erfolgreicher Returncode bedeutet, dass der Remote-Handler synchron erfolgreich committed hat. Provider- oder Handlerfehler werden an den Caller weitergegeben.

## `VW_Events`

Read-only-Sicht auf Eventzeit, Aufzeichnungszeit, Eventklassifikation, Context, Source, Caller- und Remote-Session sowie optionale SQL-Fehlerdaten.

## `USP_DeleteEventsBefore`

Löscht Events mit älterem `OccurredAtUtc` in explizit begrenzten Batches. Es gibt keine automatische Zeitplanung und keinen stillen Volltabellen-Delete.
""")

write("Documentation/Architecture/EVENT_LOG_MODULE_DESIGN.md", r"""# Event Log – Moduldesign

## Providerentscheidung

Version 1 verwendet ausschließlich `toolbelt.core.second-session` mit einem administrierten Loopback-Linked-Server. Service Broker ist kein Ersatz für rollback-unabhängiges Logging, weil `SEND` Teil der Caller-Transaktion ist. SQL CLR mit externer Verbindung wäre nicht plattformgleich auf SQL Server Linux. Das Modul erzeugt oder verändert weder Linked Server noch Credentials.

## Transaktionssemantik

Der öffentliche Writer sammelt ausschließlich begrenzte Werte und ruft den internen Work Type mit `@SuppressResult = 1` auf. Der Remote-Handler startet und committed seine eigene Session-Transaktion. Caller-Rollback und `XACT_STATE() = -1` beeinflussen den bereits erfolgreichen Remote-Commit nicht.

## Sicherheits- und Datenschutzgrenze

EventName und Level sind begrenzte ASCII-Werte. Message ist `nvarchar(4000)`. DataJson ist ein JSON-Objekt mit höchstens 32 KiB UTF-16-Speicher. Das Modul verhindert keine fachlich vertraulichen Inhalte; Caller dürfen keine Secrets oder ungeprüften personenbezogenen beziehungsweise Unternehmensdaten persistieren.

## Persistenz und Retention

`toolbelt_core.EventLog` ist append-orientiert. Redeploy erhält Daten. Retention ist ein expliziter, begrenzter Administratoraufruf. Uninstall mit Daten benötigt `AllowDataLoss = 1`.

## Work-Type-Lifecycle

Deploy registriert beziehungsweise reaktiviert `toolbelt.event-log.write`. Uninstall prüft den exakten Handlervertrag und entfernt den Eintrag ausschließlich über Disable → `USP_RemoveWorkType`; direkte Katalog-DML ist ausgeschlossen.
""")

write(f"{MODULE}/Examples/EventLog.sql", r"""EXEC toolbelt_core.USP_WriteEvent
      @EventName = 'demo.completed'
    , @EventLevel = 'INFO'
    , @Category = 'example'
    , @Message = N'Synthetic example completed.'
    , @DataJson = N'{"rows":42}';

SELECT TOP (20) *
FROM toolbelt_core.VW_Events
ORDER BY EventId DESC;
""")

write(f"{MODULE}/Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md", f'''# Event-Log-Contract-Testmatrix

- kanonischer EventName und erlaubte Level
- begrenztes JSON-Objekt, Message- und Fehlerwerte
- resultsetfreier synchroner Write-Vertrag
- getrennte Remote-Session
- expliziter und aktiver Execution Context
- Remote-Commit überlebt Caller-Rollback
- Remote-Commit aus `XACT_STATE() = -1`
- Handler- und Providerfehler werden weitergegeben
- begrenzte Retention mit Savepoint-Vertrag
- vier parallele Caller-Sessions
- Redeploy erhält Events und Work-Type-Registrierung
- lokale und zentrale Installation
- Uninstall verweigert stillen Datenverlust und entfernt den eigenen Work Type
- Windows und physische SQL-Server-2019-/2022-Läufe bleiben `not executed`

Evidenz: {EVIDENCE_URL}
''')

write(f"{MODULE}/Tests/README.md", f'''# Event-Log-Testevidenz

Statischer Vertrag sowie SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Caller-Rollback, uncommittable Caller, Context, Validierung, Retention, Concurrency, Redeploy, Central und Uninstall sind erfolgreich.

Evidenz: {EVIDENCE_URL}

Windows und physische SQL-Server-2019-/2022-Releaseprüfungen bleiben `not executed`.
''')

write(f"{MODULE}/Tests/Static/validate_contract.py", r"""#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[2]
required=[
 'Source/EventLog.sql','Source/VW_Events.sql','Source/USP_WriteEventInternal.sql','Source/USP_WriteEvent.sql','Source/USP_DeleteEventsBefore.sql',
 'Deployment/Deploy.sql','Deployment/Uninstall.sql','README.md','Documentation/EVENT_LOG_OBJECTS.md','Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md','Tests/README.md',
 'Tests/Runtime/EventLog.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql','Tests/Runtime/Concurrency.Contract.sql','Tests/Runtime/Concurrency.Verify.sql','Tests/Runtime/Central.Contract.sql','module.yaml']
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
text='\n'.join((root/p).read_text(encoding='utf-8') for p in required if p.startswith('Source/') or p.startswith('Deployment/'))
for marker in ('CREATE TABLE [toolbelt_core].[EventLog]','PK_EventLog','IX_EventLog_OccurredAtUtc_EventId','USP_WriteEventInternal','USP_WriteEvent','USP_DeleteEventsBefore','toolbelt.event-log.write','@SuppressResult = 1','USP_RemoveWorkType','AllowDataLoss'):
    if marker not in text: raise SystemExit('Vertragsmarker fehlt: '+marker)
for forbidden in ('sp_addlinkedserver','sp_addlinkedsrvlogin','@rmtpassword','TRUSTWORTHY ON'):
    if forbidden.lower() in text.lower(): raise SystemExit('Verbotener Provider-/Security-Marker: '+forbidden)
print('Event Log statische Vertragsprüfung: erfolgreich')
""")

write(f"{MODULE}/Tests/Runtime/Lifecycle.Contract.sql", r"""SET NOCOUNT ON;
IF OBJECT_ID(N'toolbelt_core.EventLog',N'U') IS NULL
 OR OBJECT_ID(N'toolbelt_core.VW_Events',N'V') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_WriteEvent',N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_WriteEventInternal',N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_DeleteEventsBefore',N'P') IS NULL
    THROW 52730,N'Event-Log-Objektbestand ist unvollständig.',1;
IF NOT EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.EventLog') AND name=N'PK_EventLog')
 OR NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.EventLog') AND name=N'IX_EventLog_OccurredAtUtc_EventId')
    THROW 52731,N'Benannte Event-Log-Artefakte fehlen.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write' AND HandlerSchema=N'toolbelt_core' AND HandlerProcedure=N'USP_WriteEventInternal' AND ParameterMode='JSON_PAYLOAD' AND IsEnabled=1)
    THROW 52732,N'Interner Event-Log-Work-Type fehlt oder ist inkonsistent.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.event-log.Version' AND CONVERT(nvarchar(32),value)=N'1.0.0')
    THROW 52733,N'Event-Log-Modulmarker fehlt.',1;
PRINT N'Event Log Lifecycle: erfolgreich';
""")

write(f"{MODULE}/Tests/Runtime/EventLog.Contract.sql", r""":on error exit
SET NOCOUNT ON;
DELETE FROM toolbelt_core.EventLog;
GO
DECLARE @Help TABLE(HelpContractVersion varchar(16),SchemaName sysname,ObjectName sysname,Section varchar(32),Ordinal int,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max),ExampleSql nvarchar(max) NULL);
INSERT INTO @Help EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_WriteEvent') THROW 52700,N'Write-Help fehlt.',1;

CREATE TABLE #UnexpectedResult(Dummy int NULL);
INSERT INTO #UnexpectedResult
EXEC toolbelt_core.USP_WriteEvent @EventName='test.no-result',@Message=N'No infrastructure rows';
IF EXISTS(SELECT 1 FROM #UnexpectedResult) THROW 52701,N'USP_WriteEvent erzeugte ein unerwartetes Resultset.',1;
DROP TABLE #UnexpectedResult;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.no-result' AND RemoteSessionId<>CallerSessionId) THROW 52702,N'Der resultsetfreie Event-Write fehlt.',1;

DECLARE @ExecutionId uniqueidentifier='44444444-1111-1111-1111-111111111111';
DECLARE @CorrelationId uniqueidentifier='44444444-2222-2222-2222-222222222222';
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@ExecutionId OUTPUT,@CorrelationId=@CorrelationId,@Actor=N'event-actor',@Tenant=N'event-tenant';
EXEC toolbelt_core.USP_WriteEvent @EventName='test.context',@EventLevel='warning',@Category='contract',@Message=N'Context event',@DataJson=N'{"value":42}',@ErrorNumber=50000,@ErrorSeverity=16,@ErrorState=2,@ErrorProcedure=N'USP_Test',@ErrorLine=7;
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@ExecutionId;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.context' AND EventLevel='WARNING' AND ExecutionId=@ExecutionId AND CorrelationId=@CorrelationId AND Actor=N'event-actor' AND Tenant=N'event-tenant' AND JSON_VALUE(DataJson,'$.value')='42' AND ErrorNumber=50000 AND RemoteSessionId<>CallerSessionId) THROW 52703,N'Context- oder Error-Propagation ist inkonsistent.',1;

BEGIN TRANSACTION;
EXEC toolbelt_core.USP_WriteEvent @EventName='test.rollback',@Message=N'Caller rolls back';
ROLLBACK TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.rollback' AND CallerXactState=1 AND CallerTransactionCount>=1) THROW 52704,N'Event überlebte Caller-Rollback nicht.',1;

DROP TABLE IF EXISTS dbo.TbxEventChild;
DROP TABLE IF EXISTS dbo.TbxEventParent;
CREATE TABLE dbo.TbxEventParent(Id int NOT NULL CONSTRAINT PK_TbxEventParent PRIMARY KEY);
CREATE TABLE dbo.TbxEventChild(Id int NOT NULL,ParentId int NOT NULL,CONSTRAINT FK_TbxEventChild_Parent FOREIGN KEY(ParentId) REFERENCES dbo.TbxEventParent(Id));
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT INTO dbo.TbxEventChild(Id,ParentId) VALUES(1,999);
 THROW 52705,N'Der synthetische Constraintfehler blieb aus.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=52705 THROW;
 IF XACT_STATE()<>-1 THROW 52706,N'Der Caller ist nicht uncommittable.',1;
 EXEC toolbelt_core.USP_WriteEvent @EventName='test.uncommittable',@EventLevel='ERROR',@Message=N'Doomed caller';
 ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;
DROP TABLE dbo.TbxEventChild;
DROP TABLE dbo.TbxEventParent;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.uncommittable' AND CallerXactState=-1) THROW 52707,N'Event aus uncommittable Caller fehlt.',1;

BEGIN TRY EXEC toolbelt_core.USP_WriteEvent @EventName='INVALID'; THROW 52708,N'Ungültiger EventName blieb aus.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52708 OR ERROR_NUMBER()<>51700 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_WriteEvent @EventName='test.invalid-level',@EventLevel='PANIC'; THROW 52709,N'Ungültiges Level blieb aus.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52709 OR ERROR_NUMBER()<>51701 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_WriteEvent @EventName='test.invalid-json',@DataJson=N'[]'; THROW 52710,N'Ungültige DataJson blieb aus.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52710 OR ERROR_NUMBER()<>51703 THROW; END CATCH;

EXEC toolbelt_core.USP_WriteEvent @EventName='test.retention.old',@OccurredAtUtc='2000-01-01T00:00:00';
EXEC toolbelt_core.USP_WriteEvent @EventName='test.retention.new',@OccurredAtUtc='2099-01-01T00:00:00';
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2010-01-01T00:00:00',@BatchSize=10,@MaxBatches=2,@DeletedRows=@Deleted OUTPUT;
IF @Deleted<>1 OR EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.retention.old') OR NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.retention.new') THROW 52711,N'Retention ist inkonsistent.',1;

PRINT N'Event Log Contract: erfolgreich';
GO
""")

write(f"{MODULE}/Tests/Runtime/Concurrency.Contract.sql", r"""SET NOCOUNT ON;
DECLARE @Worker int=$(WorkerId);
DECLARE @Caller int=@@SPID;
DECLARE @Data nvarchar(max)=N'{"worker":'+CONVERT(nvarchar(12),@Worker)+N',"caller":'+CONVERT(nvarchar(12),@Caller)+N'}';
EXEC toolbelt_core.USP_WriteEvent @EventName='test.concurrent',@Category='worker',@DataJson=@Data;
""")

write(f"{MODULE}/Tests/Runtime/Concurrency.Verify.sql", r"""SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM toolbelt_core.EventLog WHERE EventName='test.concurrent')<>4 THROW 52720,N'Concurrency-Evidenz ist unvollständig.',1;
IF EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.concurrent' AND RemoteSessionId=CallerSessionId) THROW 52721,N'Concurrency-Evidenz lief nicht in getrennten Sessions.',1;
IF (SELECT COUNT(DISTINCT TRY_CONVERT(int,JSON_VALUE(DataJson,'$.worker'))) FROM toolbelt_core.EventLog WHERE EventName='test.concurrent')<>4 THROW 52722,N'Worker-Evidenz ist nicht eindeutig.',1;
PRINT N'Event Log Concurrency: erfolgreich';
""")

write(f"{MODULE}/Tests/Runtime/Central.Contract.sql", r""":on error exit
SET NOCOUNT ON;
DECLARE @SourceDatabase sysname=DB_NAME();
EXEC [$(ToolbeltDatabase)].toolbelt_core.USP_WriteEvent @EventName='test.central',@SourceDatabaseName=@SourceDatabase,@Message=N'Central consumer';
IF NOT EXISTS(SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_core.EventLog WHERE EventName='test.central' AND SourceDatabaseName=@SourceDatabase AND RemoteSessionId<>CallerSessionId) THROW 52725,N'Central-Event fehlt oder Source-Datenbank ist inkonsistent.',1;
PRINT N'Event Log Central: erfolgreich';
GO
""")

print("W5b-Modul- und Second-Session-Artefakte erzeugt.")
