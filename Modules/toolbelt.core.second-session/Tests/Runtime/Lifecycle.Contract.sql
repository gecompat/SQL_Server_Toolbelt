:on error exit
SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NULL
 OR OBJECT_ID(N'toolbelt_core.VW_SecondSessionProviders', N'V') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_SecondSessionProbe', N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_DispatchWorkType', N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_ConfigureSecondSessionLoopback', N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession', N'P') IS NULL
    THROW 52660, N'Second-Session-Objektbestand ist unvollständig.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID(N'toolbelt_core.SecondSessionProvider')
      AND name = N'PK_SecondSessionProvider'
)
 OR NOT EXISTS
(
    SELECT 1
    FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID(N'toolbelt_core.SecondSessionProvider')
      AND name = N'UQ_SecondSessionProvider_LinkedServerName'
)
    THROW 52661, N'Benannte Second-Session-Tabellenartefakte fehlen.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.extended_properties
    WHERE class = 0
      AND name = N'Toolbelt.Module.toolbelt.core.second-session.Version'
      AND CONVERT(nvarchar(32), value) = N'1.1.0'
)
    THROW 52662, N'Second-Session-Modulmarker fehlt.', 1;

DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
INSERT @Help EXEC toolbelt_core.USP_SecondSessionProbe @Hilfe=1;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_SecondSessionProbe' AND Section='PARAMETER' AND ItemName=N'@Hilfe')
 OR NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_SecondSessionProbe' AND Section='RESULT_COLUMN' AND ItemName IS NULL)
 OR EXISTS(SELECT 1 FROM @Help WHERE HelpContractVersion<>'1.0' OR SchemaName<>N'toolbelt_core')
    THROW 52663,N'SecondSessionProbe-Hilfevertrag ist unvollständig.',1;
DELETE FROM @Help;
INSERT @Help EXEC toolbelt_core.USP_DispatchWorkType @Hilfe=1;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_DispatchWorkType' AND Section='PARAMETER' AND ItemName=N'@ExecutionId')
 OR NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_DispatchWorkType' AND Section='PARAMETER' AND ItemName=N'@Hilfe')
 OR NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_DispatchWorkType' AND Section='RESULT_COLUMN' AND ItemName IS NULL)
 OR EXISTS(SELECT 1 FROM @Help WHERE HelpContractVersion<>'1.0' OR SchemaName<>N'toolbelt_core')
    THROW 52664,N'DispatchWorkType-Hilfevertrag ist unvollständig.',1;

PRINT N'Second Session Lifecycle: erfolgreich';
GO
