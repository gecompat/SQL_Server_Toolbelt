USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Major int = TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'));

IF @Major NOT IN (15, 16, 17)
    THROW 55500, N'ADAPTER_UNSUPPORTED_SQL_VERSION: SQL Server 2019, 2022 oder 2025 ist erforderlich.', 1;

IF IS_SRVROLEMEMBER(N'sysadmin') <> 1
    THROW 55500, N'ADAPTER_PERMISSION_MISSING: Der isolierte Toolbelt-Pilot benötigt sysadmin.', 1;

IF EXISTS
(
    SELECT 1 FROM [sys].[databases]
    WHERE [database_id] > 4
      AND [name] <> N'ToolbeltConsoleMessageAdapter'
)
    THROW 55501, N'ADAPTER_ISOLATION_REQUIRED: Die Instanz enthält eine fremde Benutzerdatenbank.', 1;

DECLARE @OwnershipMarkerCount int = 0;
IF DB_ID(N'ToolbeltConsoleMessageAdapter') IS NOT NULL
BEGIN
    EXEC [sys].[sp_executesql]
          N'SELECT @MarkerCount = COUNT(*)
            FROM [ToolbeltConsoleMessageAdapter].[sys].[extended_properties]
            WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
              AND
              (
                  ([name] = N''Toolbelt.AdapterProject''
                   AND CONVERT(nvarchar(128), [value]) = N''sql-server-toolbelt-console-message'')
                  OR
                  ([name] = N''Toolbelt.AdapterContractVersion''
                   AND CONVERT(nvarchar(32), [value]) = N''0.1'')
              );'
        , N'@MarkerCount int OUTPUT'
        , @MarkerCount = @OwnershipMarkerCount OUTPUT;

    IF @OwnershipMarkerCount <> 2
        THROW 55502, N'ADAPTER_STATE_CONFLICT: Die vorhandene Datenbank besitzt nicht die erwarteten Adaptermarker.', 1;
END;

SELECT
      N'ADP-008' AS [WorkItem]
    , N'PREFLIGHT' AS [Phase]
    , N'PASS' AS [Outcome]
    , @Major AS [ProductMajorVersion];
GO
