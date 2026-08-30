USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'ToolbeltConsoleMessageAdapter') IS NULL
    THROW 55503, N'PROJECT_ASSERTION_FAILED: Die Adapterdatenbank fehlt.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM [ToolbeltConsoleMessageAdapter].[sys].[extended_properties]
    WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
      AND [name] = N'Toolbelt.AdapterProject'
      AND CONVERT(nvarchar(128), [value]) = N'sql-server-toolbelt-console-message'
)
OR NOT EXISTS
(
    SELECT 1 FROM [ToolbeltConsoleMessageAdapter].[sys].[extended_properties]
    WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
      AND [name] = N'Toolbelt.AdapterContractVersion'
      AND CONVERT(nvarchar(32), [value]) = N'0.1'
)
    THROW 55503, N'PROJECT_ASSERTION_FAILED: Die Adaptermarker stimmen nicht überein.', 1;
GO
USE [ToolbeltConsoleMessageAdapter];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS
(
    SELECT 1 FROM [sys].[extended_properties]
    WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
      AND [name] = N'Toolbelt.Module.toolbelt.core.console-message.Version'
      AND CONVERT(nvarchar(64), [value]) = N'1.0.0'
)
OR NOT EXISTS
(
    SELECT 1 FROM [sys].[extended_properties]
    WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
      AND [name] = N'Toolbelt.Module.toolbelt.core.console-message.DeploymentMode'
      AND CONVERT(nvarchar(16), [value]) = N'local'
)
    THROW 55503, N'PROJECT_ASSERTION_FAILED: Version oder Deploymentmodus des Moduls stimmt nicht.', 1;

IF OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage', N'P') IS NULL
    THROW 55503, N'PROJECT_ASSERTION_FAILED: Die öffentliche Console-Message-Procedure fehlt.', 1;

IF (SELECT COUNT(*) FROM [sys].[parameters]
    WHERE [object_id] = OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage')) <> 4
OR NOT EXISTS
(
    SELECT 1 FROM [sys].[parameters]
    WHERE [object_id] = OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage')
      AND [name] = N'@Message' AND TYPE_NAME([user_type_id]) = N'nvarchar'
      AND [max_length] = -1
)
OR NOT EXISTS
(
    SELECT 1 FROM [sys].[parameters]
    WHERE [object_id] = OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage')
      AND [name] = N'@Immediate' AND TYPE_NAME([user_type_id]) = N'bit'
)
OR NOT EXISTS
(
    SELECT 1 FROM [sys].[parameters]
    WHERE [object_id] = OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage')
      AND [name] = N'@Debug' AND TYPE_NAME([user_type_id]) = N'tinyint'
)
OR NOT EXISTS
(
    SELECT 1 FROM [sys].[parameters]
    WHERE [object_id] = OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage')
      AND [name] = N'@Hilfe' AND TYPE_NAME([user_type_id]) = N'bit'
)
    THROW 55503, N'PROJECT_ASSERTION_FAILED: Die öffentliche Signatur stimmt nicht.', 1;

CREATE TABLE [#Help]
(
      [HelpContractVersion] varchar(16) NOT NULL
    , [SchemaName] sysname NOT NULL
    , [ObjectName] sysname NOT NULL
    , [Section] varchar(32) NOT NULL
    , [Ordinal] int NOT NULL
    , [ItemName] sysname NULL
    , [SqlDataType] varchar(256) NULL
    , [IsRequired] bit NULL
    , [IsNullable] bit NULL
    , [DefaultValue] nvarchar(4000) NULL
    , [Description] nvarchar(max) NOT NULL
    , [ExampleSql] nvarchar(max) NULL
);

DECLARE @ReturnCode int;
INSERT INTO [#Help]
EXEC @ReturnCode = [toolbelt_core].[USP_WriteConsoleMessage] @Hilfe = 1;

IF @ReturnCode <> 0
   OR NOT EXISTS
      (
          SELECT 1 FROM [#Help]
          WHERE [HelpContractVersion] = '1.0'
            AND [SchemaName] = N'toolbelt_core'
            AND [ObjectName] = N'USP_WriteConsoleMessage'
            AND [Section] = 'DESCRIPTION'
      )
   OR (SELECT COUNT(*) FROM [#Help] WHERE [Section] = 'PARAMETER') <> 4
    THROW 55503, N'PROJECT_ASSERTION_FAILED: Der Help-Vertrag stimmt nicht.', 1;

EXEC @ReturnCode = [toolbelt_core].[USP_WriteConsoleMessage]
      @Message = NULL
    , @Immediate = 1;
IF @ReturnCode <> 0
    THROW 55503, N'PROJECT_ASSERTION_FAILED: Der NULL-Ausgabevertrag ist fehlgeschlagen.', 1;

SELECT
      N'ADP-008' AS [WorkItem]
    , N'VALIDATE' AS [Phase]
    , N'PASS' AS [Outcome]
    , N'toolbelt.core.console-message' AS [ModuleId]
    , N'1.0.0' AS [ModuleVersion];
GO
