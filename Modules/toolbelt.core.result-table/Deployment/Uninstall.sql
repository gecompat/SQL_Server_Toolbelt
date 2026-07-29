:On Error exit

-- ============================================================================
-- Zweck:     Kontrollierte Deinstallation von Result Table Infrastructure
-- Modul:     toolbelt.core.result-table
-- Modus:     SQLCMD
-- Hinweis:   Bei zentraler Installation muss ConfirmNoExternalConsumers=1
--            ausdrücklich bestätigen, dass keine externen Aufrufer verbleiben.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionPropertyName sysname =
          N'Toolbelt.Module.toolbelt.core.result-table.Version'
    , @ModePropertyName sysname =
          N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode'
    , @InstalledVersion nvarchar(64)
    , @DeploymentMode nvarchar(16)
    , @ProcedureId int
    , @ReferencingSchema sysname
    , @ReferencingObject sysname;

IF @ConfirmNoExternalConsumers IS NULL
BEGIN
    THROW 51035, N'Die SQLCMD-Variable ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
END;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = @VersionPropertyName;

SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = @ModePropertyName;

IF @InstalledVersion IS NULL
BEGIN
    PRINT N'toolbelt.core.result-table ist nicht als installiert registriert; keine Änderung erforderlich.';
    RETURN;
END;

IF @InstalledVersion COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
BEGIN
    THROW 51033, N'Die installierte Modulversion ist diesem Uninstall-Skript nicht bekannt.', 1;
END;

IF @DeploymentMode NOT IN (N'local', N'central')
BEGIN
    THROW 51033, N'Der registrierte Deployment-Modus fehlt oder ist ungültig.', 1;
END;

IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
BEGIN
    THROW 51035, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 als ausdrückliche Betreiberbestätigung erforderlich.', 1;
END;

SET @ProcedureId = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable');

/*
 * SQL Server kann nur statische same-database Dependencies zuverlässig
 * ermitteln. Dynamische und externe dreiteilige Aufrufer erklären das
 * zusätzliche Confirm-Gate für zentrale Installationen.
 */
IF @ProcedureId IS NOT NULL
BEGIN
    SELECT TOP (1)
          @ReferencingSchema = OBJECT_SCHEMA_NAME(sed.referencing_id)
        , @ReferencingObject = OBJECT_NAME(sed.referencing_id)
    FROM sys.sql_expression_dependencies AS sed
    WHERE sed.referenced_id = @ProcedureId
      AND sed.referencing_id <> @ProcedureId
    ORDER BY
          OBJECT_SCHEMA_NAME(sed.referencing_id) COLLATE Latin1_General_100_BIN2
        , OBJECT_NAME(sed.referencing_id) COLLATE Latin1_General_100_BIN2;
END;

IF @ReferencingObject IS NOT NULL
BEGIN
    DECLARE @DependencyMessage nvarchar(2048) =
        N'Die Deinstallation wird durch same-database Dependency '
        + COALESCE(QUOTENAME(@ReferencingSchema), N'<ohne Schema>')
        + N'.'
        + COALESCE(QUOTENAME(@ReferencingObject), N'<unbekannt>')
        + N' blockiert.';
    SET @DependencyMessage = REPLACE(@DependencyMessage, N'%', N'%%');
    THROW 51036, @DependencyMessage, 1;
END;

/*
 * Der Preflight ist abgeschlossen. Das Release-Manifest von 1.0.0 enthält
 * genau toolbelt_core.USP_PrepareResultTable. Andere Objekte werden durch
 * dieses Skript nie ausgewählt.
 */
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @LockResult int;

    EXEC @LockResult = sys.sp_getapplock
          @Resource    = N'toolbelt.deploy.toolbelt.core.result-table'
        , @LockMode    = N'Exclusive'
        , @LockOwner   = N'Transaction'
        , @LockTimeout = 0
        , @DbPrincipal = N'public';

    IF @LockResult < 0
    BEGIN
        THROW 51037, N'Ein paralleles Deployment von toolbelt.core.result-table ist bereits aktiv.', 1;
    END;

    DECLARE @CurrentInstalledVersion nvarchar(64);

    SELECT @CurrentInstalledVersion = TRY_CONVERT(nvarchar(64), ep.value)
    FROM sys.extended_properties AS ep
    WHERE ep.class = 0
      AND ep.major_id = 0
      AND ep.minor_id = 0
      AND ep.name = @VersionPropertyName;

    IF ISNULL(@CurrentInstalledVersion, N'') COLLATE Latin1_General_100_BIN2
           <> @InstalledVersion COLLATE Latin1_General_100_BIN2
    BEGIN
        THROW 51037, N'Der installierte Modulstand hat sich seit dem Uninstall-Preflight verändert.', 1;
    END;

    SET @ProcedureId = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable');

    IF @ProcedureId IS NOT NULL
    BEGIN
        DECLARE @ActualType char(2);

        SELECT @ActualType = o.type
        FROM sys.objects AS o
        WHERE o.object_id = @ProcedureId;

        IF @ActualType IN ('P', 'PC')
        BEGIN
            DROP PROCEDURE [toolbelt_core].[USP_PrepareResultTable];
        END;
        ELSE IF @ActualType = 'V'
        BEGIN
            DROP VIEW [toolbelt_core].[USP_PrepareResultTable];
        END;
        ELSE IF @ActualType IN ('FN', 'FS', 'FT', 'IF', 'TF')
        BEGIN
            DROP FUNCTION [toolbelt_core].[USP_PrepareResultTable];
        END;
        ELSE
        BEGIN
            THROW 51033, N'Das Release-Objekt besitzt einen nicht unterstützten lokal veränderten Objekttyp.', 1;
        END;
    END;

    EXEC sys.sp_dropextendedproperty @name = @VersionPropertyName;
    EXEC sys.sp_dropextendedproperty @name = @ModePropertyName;

    DECLARE
          @SchemaId int = SCHEMA_ID(N'toolbelt_core')
        , @SchemaManaged int
        , @SchemaCategory nvarchar(128);

    IF @SchemaId IS NOT NULL
    BEGIN
        SELECT
              @SchemaManaged = MAX
              (
                  CASE
                      WHEN ep.name = N'Toolbelt.Managed'
                          THEN TRY_CONVERT(int, ep.value)
                  END
              )
            , @SchemaCategory = MAX
              (
                  CASE
                      WHEN ep.name = N'Toolbelt.SchemaCategory'
                          THEN TRY_CONVERT(nvarchar(128), ep.value)
                  END
              )
        FROM sys.extended_properties AS ep
        WHERE ep.class = 3
          AND ep.major_id = @SchemaId
          AND ep.minor_id = 0;

        /*
         * Ein vor der Installation vorhandenes unmarkiertes Schema wird nicht
         * adoptiert und folglich niemals entfernt. Ein vom Toolbelt angelegtes
         * Schema darf nur in vollständig leerem Zustand verschwinden.
         */
        IF ISNULL(@SchemaManaged, 0) = 1
           AND ISNULL(@SchemaCategory, N'') COLLATE Latin1_General_100_BIN2 = N'core'
           AND NOT EXISTS
               (
                   SELECT 1
                   FROM sys.objects AS o
                   WHERE o.schema_id = @SchemaId
               )
           AND NOT EXISTS
               (
                   SELECT 1
                   FROM sys.types AS t
                   WHERE t.schema_id = @SchemaId
                     AND t.is_user_defined = 1
               )
           AND NOT EXISTS
               (
                   SELECT 1
                   FROM sys.xml_schema_collections AS xsc
                   WHERE xsc.schema_id = @SchemaId
                     AND xsc.xml_collection_id > 0
               )
        BEGIN
            DROP SCHEMA [toolbelt_core];
        END;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO
