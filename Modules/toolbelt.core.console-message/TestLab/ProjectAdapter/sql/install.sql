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
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.core.console-message.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.core.console-message.DeploymentMode'
    , @DeploymentMode nvarchar(16) = LOWER(N'local')
    , @InstalledVersion nvarchar(64)
    , @ProductMajorVersion int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'));

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 51270, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51271, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @VersionProperty;

IF @InstalledVersion IS NOT NULL AND @InstalledVersion <> N'1.0.0'
    THROW 51273, N'Die installierte Modulversion ist diesem Deployment nicht bekannt.', 1;

IF @InstalledVersion IS NULL
   AND OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage') IS NOT NULL
    THROW 51274, N'Das Zielobjekt stammt nicht aus einem bekannten Toolbelt-Release.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
   AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    THROW 51272, N'In der Installationsdatenbank fehlt CREATE SCHEMA.', 1;
IF SCHEMA_ID(N'toolbelt_core') IS NOT NULL
   AND HAS_PERMS_BY_NAME(N'toolbelt_core', N'SCHEMA', N'ALTER') <> 1
    THROW 51272, N'Für toolbelt_core fehlt ALTER.', 1;
IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE PROCEDURE') <> 1
    THROW 51272, N'In der Installationsdatenbank fehlt CREATE PROCEDURE.', 1;

BEGIN TRANSACTION;
DECLARE @LockResult int;
EXEC @LockResult = sys.sp_getapplock
      @Resource = N'toolbelt.deploy.toolbelt.core.console-message'
    , @LockMode = N'Exclusive'
    , @LockOwner = N'Transaction'
    , @LockTimeout = 0
    , @DbPrincipal = N'public';
IF @LockResult < 0
    THROW 51277, N'Ein paralleles Deployment dieses Moduls ist bereits aktiv.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
BEGIN
    EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_core];';
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.Managed', @value = 1
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_core';
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.SchemaCategory', @value = N'core'
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_core';
END;
GO
-- ============================================================================
-- Objekt:          toolbelt_core.USP_WriteConsoleMessage
-- Typ:             Stored Procedure
-- Zweck:           Gibt lange Unicode-Texte vollständig und optional sofort
--                  im Messages-Kanal des Clients aus.
-- Vertrag:         Documentation/Architecture/CONSOLE_MESSAGE_MODULE_DESIGN.md
-- Parameter:       @Message nvarchar(max) = NULL
--                  @Immediate bit = 0
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
-- Resultset:       Kein fachliches Resultset; bei @Hilfe = 1 genau ein
--                  standardisiertes Help-Resultset.
-- Dependencies:    Keine weiteren Toolbelt-Module.
-- Rechte:          EXECUTE auf der Procedure.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux; Clientdarstellung separat bewerten.
-- Fehlerverhalten: Keine fachlichen Fehler. Engine- und Clientfehler werden
--                  nicht abgefangen oder umklassifiziert.
-- Performance:     Lineare Message-Ausgabe; nicht für Hot Paths bestimmt.
-- Einschränkungen: Client und Treiber bestimmen Pufferung und Darstellung der
--                  einzelnen Message-Frames. Keine Präfixe oder Zeitstempel.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteConsoleMessage]
(
      @Message   nvarchar(max) = NULL
    , @Immediate bit           = 0
    , @Debug     tinyint       = 0
    , @Hilfe     bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Immediate = ISNULL(@Immediate, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    /*
     * Der Help-Pfad steht vor der fachlichen Ausgabe. Dadurch ignoriert ein
     * Hilfeaufruf Message, Immediate und Debug vollständig.
     */
    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_WriteConsoleMessage' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Gibt bis zu 1 MiB UTF-16 in höchstens 512 Frames vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Die Procedure besitzt kein fachliches Resultset. Text wird ausschließlich als Messages ausgegeben.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'52801-52802', NULL, NULL, NULL, NULL, CAST(N'52801: über 1 MiB UTF-16; 52802: über 512 Frames. Ablehnung vor erster Ausgabe, keine Kürzung.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erforderlich ist EXECUTE auf toolbelt_core.USP_WriteConsoleMessage. Die Procedure erweitert keine Rechte.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Client und Treiber bestimmen Pufferung, Präfixe und Darstellung von Message-Frame-Grenzen. Die Procedure garantiert Reihenfolge und vollständige Payload-Chunks, aber keine byteidentische Clientformatierung.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Gibt einen synthetischen Fortschrittstext sofort aus.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N''Schritt 1 abgeschlossen.''
    , @Immediate = 1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@Message', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Immediate', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert ausschließlich Hilfe und ignoriert alle anderen Argumente; 0 führt die Messageausgabe aus (Default). NULL wird wie 0 behandelt.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @Message IS NULL OR DATALENGTH(@Message) = 0
        RETURN 0;

    IF DATALENGTH(@Message)>1048576
        THROW 52801,N'Console-Nachrichten dürfen höchstens 1 MiB UTF-16 umfassen.',1;

    DECLARE
          @Position      bigint = 1
        , @CodeUnitCount bigint
        , @ChunkSize     int
        , @ChunkLength   int
        , @Chunk         nvarchar(4000);

    /*
     * LEN ignoriert normalerweise nachgestellte Leerzeichen. Das angehängte
     * Nicht-Leerzeichen macht sie zählbar. Die explizite Nicht-SC-Collation
     * zählt UTF-16-Codeunits; damit stimmt die Positionsrechnung mit den
     * nvarchar- und Message-Grenzen überein.
     */
    SET @CodeUnitCount =
        LEN((@Message + NCHAR(1)) COLLATE Latin1_General_100_BIN2) - 1;
    SET @ChunkSize = CASE WHEN @Immediate = 1 THEN 2000 ELSE 4000 END;

    -- Höchstens ein Surrogate-Paar verschiebt eine Chunkgrenze um eine Einheit.
    -- Diese obere Framezahl wird vor der ersten Ausgabe geprüft.
    IF (@CodeUnitCount+@ChunkSize-2)/(@ChunkSize-1)>512
        THROW 52802,N'Console-Nachrichten dürfen höchstens 512 Frames erzeugen.',1;

    WHILE @Position <= @CodeUnitCount
    BEGIN
        SET @ChunkLength = CONVERT
        (
            int,
            CASE
                WHEN @CodeUnitCount - @Position + 1 < @ChunkSize
                THEN @CodeUnitCount - @Position + 1
                ELSE @ChunkSize
            END
        );

        SET @Chunk = SUBSTRING
        (
              @Message COLLATE Latin1_General_100_BIN2
            , @Position
            , @ChunkLength
        );

        /*
         * BIN2 zählt die beiden UTF-16-Codeunits eines Supplementary
         * Characters getrennt. Endet ein noch nicht letzter Chunk mit einem
         * High Surrogate und beginnt der nächste mit dem zugehörigen Low
         * Surrogate, bleibt das Paar vollständig im nächsten Chunk.
         */
        IF @Position + @ChunkLength - 1 < @CodeUnitCount
           AND UNICODE
               (
                   RIGHT(@Chunk COLLATE Latin1_General_100_BIN2, 1)
               ) BETWEEN 55296 AND 56319
           AND UNICODE
               (
                   SUBSTRING
                   (
                         @Message COLLATE Latin1_General_100_BIN2
                       , @Position + @ChunkLength
                       , 1
                   )
               ) BETWEEN 56320 AND 57343
        BEGIN
            SET @ChunkLength -= 1;
            SET @Chunk = SUBSTRING
            (
                  @Message COLLATE Latin1_General_100_BIN2
                , @Position
                , @ChunkLength
            );
        END;

        IF @Immediate = 1
        BEGIN
            /*
             * Das feste Format verhindert, dass Prozentzeichen des Payloads
             * als Format-Spezifikationen interpretiert werden. 2.000 Zeichen
             * lassen Reserve unterhalb des RAISERROR-Limits von 2.047.
             */
            RAISERROR (N'%s', 0, 1, @Chunk) WITH NOWAIT;
        END;
        ELSE
        BEGIN
            PRINT @Chunk;
        END;

        SET @Position += @ChunkLength;
    END;

    RETURN 0;
END;
GO
SET NOCOUNT ON;
BEGIN TRY
    DECLARE
          @VersionProperty sysname =
              N'Toolbelt.Module.toolbelt.core.console-message.Version'
        , @ModeProperty sysname =
              N'Toolbelt.Module.toolbelt.core.console-message.DeploymentMode';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties
           WHERE class = 0 AND major_id = 0 AND minor_id = 0
             AND name = @VersionProperty
       )
        EXEC sys.sp_updateextendedproperty
             @name = @VersionProperty, @value = N'1.0.0';
    ELSE
        EXEC sys.sp_addextendedproperty
             @name = @VersionProperty, @value = N'1.0.0';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties
           WHERE class = 0 AND major_id = 0 AND minor_id = 0
             AND name = @ModeProperty
       )
        EXEC sys.sp_updateextendedproperty
             @name = @ModeProperty, @value = N'local';
    ELSE
        EXEC sys.sp_addextendedproperty
             @name = @ModeProperty, @value = N'local';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
