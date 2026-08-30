[CmdletBinding()]
param(
    [string] $RepositoryRoot = (
        Resolve-Path (Join-Path $PSScriptRoot '../../../..')
    ).Path,

    [string] $OutputDirectory = (Join-Path $PSScriptRoot 'sql')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$moduleRoot = Join-Path $repositoryPath 'Modules/toolbelt.core.console-message'
$deployPath = Join-Path $moduleRoot 'Deployment/Deploy.sql'
$uninstallPath = Join-Path $moduleRoot 'Deployment/Uninstall.sql'
$sourcePath = Join-Path $moduleRoot 'Source/USP_WriteConsoleMessage.sql'

foreach ($path in @($deployPath, $uninstallPath, $sourcePath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Kanonische Console-Message-Quelle fehlt: $path"
    }
}

function ConvertTo-AdapterDeployment {
    param(
        [Parameter(Mandatory)] [string] $Deployment,
        [Parameter(Mandatory)] [string] $Source
    )

    $result = [Text.RegularExpressions.Regex]::Replace(
        $Deployment,
        '(?m)^:On Error exit\r?\n',
        ''
    )
    $result = $result.Replace("N'`$(DeploymentMode)'", "N'local'")
    return $result.Replace(
        ':r ../Source/USP_WriteConsoleMessage.sql',
        $Source.TrimEnd()
    )
}

function ConvertTo-AdapterUninstall {
    param([Parameter(Mandatory)] [string] $Uninstall)

    $result = [Text.RegularExpressions.Regex]::Replace(
        $Uninstall,
        '(?m)^:On Error exit\r?\n',
        ''
    )
    return $result.Replace(
        "N'`$(ConfirmNoExternalConsumers)'",
        "N'0'"
    )
}

function Write-GeneratedSql {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Content
    )

    $normalized = [Text.RegularExpressions.Regex]::Replace(
        $Content,
        '[\t ]+(?=\r?$)',
        '',
        [Text.RegularExpressions.RegexOptions]::Multiline
    ).Replace("`r`n", "`n").TrimEnd() + "`n"
    [IO.File]::WriteAllText(
        $Path,
        $normalized,
        [Text.UTF8Encoding]::new($false)
    )
}

$deploy = [IO.File]::ReadAllText($deployPath, [Text.Encoding]::UTF8)
$uninstall = [IO.File]::ReadAllText($uninstallPath, [Text.Encoding]::UTF8)
$source = [IO.File]::ReadAllText($sourcePath, [Text.Encoding]::UTF8)
$adapterDeployment = ConvertTo-AdapterDeployment `
    -Deployment $deploy `
    -Source $source
$adapterUninstall = ConvertTo-AdapterUninstall -Uninstall $uninstall

$installHeader = @'
/*
Generated from the canonical toolbelt.core.console-message deployment.
Do not edit directly; run Build-AdapterSql.ps1.
*/
USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS
(
    SELECT 1
    FROM [sys].[databases]
    WHERE [database_id] > 4
      AND [name] <> N'ToolbeltConsoleMessageAdapter'
)
    THROW 55501, N'ADAPTER_ISOLATION_REQUIRED: Die Instanz enthält eine fremde Benutzerdatenbank.', 1;

IF DB_ID(N'ToolbeltConsoleMessageAdapter') IS NULL
    CREATE DATABASE [ToolbeltConsoleMessageAdapter]
    COLLATE SQL_Latin1_General_CP1_CS_AS;
GO
USE [ToolbeltConsoleMessageAdapter];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @ProjectId nvarchar(128) = N'sql-server-toolbelt-console-message';
DECLARE @ContractVersion nvarchar(32) = N'0.1';
DECLARE @ExistingProject nvarchar(128);
DECLARE @ExistingContract nvarchar(32);

SELECT
      @ExistingProject = MAX(CASE WHEN [name] = N'Toolbelt.AdapterProject'
          THEN CONVERT(nvarchar(128), [value]) END)
    , @ExistingContract = MAX(CASE WHEN [name] = N'Toolbelt.AdapterContractVersion'
          THEN CONVERT(nvarchar(32), [value]) END)
FROM [sys].[extended_properties]
WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0;

IF @ExistingProject IS NULL AND @ExistingContract IS NULL
BEGIN
    EXEC [sys].[sp_addextendedproperty]
          @name = N'Toolbelt.AdapterProject'
        , @value = @ProjectId;
    EXEC [sys].[sp_addextendedproperty]
          @name = N'Toolbelt.AdapterContractVersion'
        , @value = @ContractVersion;
END
ELSE IF @ExistingProject <> @ProjectId OR @ExistingContract <> @ContractVersion
    THROW 55502, N'ADAPTER_STATE_CONFLICT: Die Datenbank besitzt nicht die erwarteten Adaptermarker.', 1;
GO
'@

$updateHeader = @'
/*
Generated version-preserving update from the canonical
toolbelt.core.console-message deployment.
Do not edit directly; run Build-AdapterSql.ps1.
*/
USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'ToolbeltConsoleMessageAdapter') IS NULL
    THROW 55502, N'ADAPTER_STATE_CONFLICT: Die Adapterdatenbank fehlt.', 1;
GO
USE [ToolbeltConsoleMessageAdapter];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS
(
    SELECT 1 FROM [sys].[extended_properties]
    WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
      AND [name] = N'Toolbelt.AdapterProject'
      AND CONVERT(nvarchar(128), [value]) = N'sql-server-toolbelt-console-message'
)
OR NOT EXISTS
(
    SELECT 1 FROM [sys].[extended_properties]
    WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
      AND [name] = N'Toolbelt.AdapterContractVersion'
      AND CONVERT(nvarchar(32), [value]) = N'0.1'
)
    THROW 55502, N'ADAPTER_STATE_CONFLICT: Die Adaptermarker stimmen nicht überein.', 1;
GO
'@

$cleanupHeader = @'
/*
Generated from the canonical toolbelt.core.console-message uninstall.
Do not edit directly; run Build-AdapterSql.ps1.
*/
USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'ToolbeltConsoleMessageAdapter') IS NOT NULL
BEGIN
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
        THROW 55504, N'PROJECT_CLEANUP_FAILED: Die Datenbank besitzt nicht die erwarteten Adaptermarker.', 1;
END;
GO
USE [ToolbeltConsoleMessageAdapter];
GO
'@

$cleanupFooter = @'
USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'ToolbeltConsoleMessageAdapter') IS NOT NULL
BEGIN
    IF NOT EXISTS
    (
        SELECT 1 FROM [ToolbeltConsoleMessageAdapter].[sys].[extended_properties]
        WHERE [class] = 0 AND [major_id] = 0 AND [minor_id] = 0
          AND [name] = N'Toolbelt.AdapterProject'
          AND CONVERT(nvarchar(128), [value]) = N'sql-server-toolbelt-console-message'
    )
        THROW 55504, N'PROJECT_CLEANUP_FAILED: Der Adaptermarker fehlt vor dem Datenbank-Cleanup.', 1;

    ALTER DATABASE [ToolbeltConsoleMessageAdapter]
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [ToolbeltConsoleMessageAdapter];
END;

SELECT
      N'ADP-008' AS [WorkItem]
    , N'CLEANUP' AS [Phase]
    , N'PASS' AS [Outcome]
    , N'ADAPTER_DATABASE_REMOVED' AS [Code];
GO
'@

[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
Write-GeneratedSql `
    -Path (Join-Path $OutputDirectory 'install.sql') `
    -Content ($installHeader.TrimEnd() + "`n" + $adapterDeployment)
Write-GeneratedSql `
    -Path (Join-Path $OutputDirectory 'update.sql') `
    -Content ($updateHeader.TrimEnd() + "`n" + $adapterDeployment)
Write-GeneratedSql `
    -Path (Join-Path $OutputDirectory 'cleanup.sql') `
    -Content ($cleanupHeader.TrimEnd() + "`n" + $adapterUninstall.Trim() +
        "`n" + $cleanupFooter.TrimStart())

Write-Host "Generated install.sql, update.sql and cleanup.sql in $OutputDirectory."
