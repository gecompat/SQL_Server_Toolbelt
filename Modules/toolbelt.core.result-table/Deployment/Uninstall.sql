:On Error exit
:setvar ConfirmNoExternalConsumers "0"

-- ============================================================================
-- Zweck:     Kontrollierte Deinstallation von Result Table Infrastructure
-- Modul:     toolbelt.core.result-table v1.0.0
-- Schema:    toolbelt_core
-- Modus:     SQLCMD
-- Hinweis:   Bei zentraler Installation muss ConfirmNoExternalConsumers=1
--            ausdrücklich bestätigen, dass keine externen Aufrufer verbleiben.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @SchemaId                   int = SCHEMA_ID(N'toolbelt_core')
    , @ProcedureId                int = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P')
    , @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @SchemaManaged              int
    , @SchemaCategory             nvarchar(128)
    , @ModuleId                   nvarchar(256)
    , @ModuleVersion              nvarchar(64)
    , @DeploymentMode             nvarchar(16)
    , @ReferencingSchema          sysname
    , @ReferencingObject          sysname;

IF @ConfirmNoExternalConsumers IS NULL
BEGIN
    THROW 51035, N'Die SQLCMD-Variable ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
END;

IF @SchemaId IS NULL
BEGIN
    PRINT N'toolbelt.core.result-table ist nicht installiert; keine Änderung erforderlich.';
    RETURN;
END;

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

IF ISNULL(@SchemaManaged, 0) <> 1
   OR ISNULL(@SchemaCategory, N'') COLLATE Latin1_General_100_BIN2 <> N'core'
BEGIN
    THROW 51033, N'Das Schema toolbelt_core besitzt fremde oder unvollständige Ownership-Marker und wird nicht verändert.', 1;
END;

IF HAS_PERMS_BY_NAME(N'toolbelt_core', N'SCHEMA', N'ALTER') <> 1
BEGIN
    THROW 51032, N'Für die Deinstallation fehlt ALTER auf dem Schema toolbelt_core.', 1;
END;

IF @ProcedureId IS NOT NULL
BEGIN
    SELECT
          @ModuleId = MAX
          (
              CASE
                  WHEN ep.name = N'Toolbelt.ModuleId'
                      THEN TRY_CONVERT(nvarchar(256), ep.value)
              END
          )
        , @ModuleVersion = MAX
          (
              CASE
                  WHEN ep.name = N'Toolbelt.ModuleVersion'
                      THEN TRY_CONVERT(nvarchar(64), ep.value)
              END
          )
        , @DeploymentMode = MAX
          (
              CASE
                  WHEN ep.name = N'Toolbelt.DeploymentMode'
                      THEN TRY_CONVERT(nvarchar(16), ep.value)
              END
          )
    FROM sys.extended_properties AS ep
    WHERE ep.class = 1
      AND ep.major_id = @ProcedureId
      AND ep.minor_id = 0;

    IF ISNULL(@ModuleId, N'') COLLATE Latin1_General_100_BIN2
           <> N'toolbelt.core.result-table'
       OR ISNULL(@ModuleVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
       OR ISNULL(@DeploymentMode, N'') NOT IN (N'local', N'central')
    BEGIN
        THROW 51033, N'Die vorhandene Procedure besitzt fremde, unbekannte oder unvollständige Modulmarker und wird nicht entfernt.', 1;
    END;

    IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    BEGIN
        THROW 51035, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 als ausdrückliche Betreiberbestätigung erforderlich.', 1;
    END;

    /*
     * SQL Server kann nur statische same-database Dependencies zuverlässig
     * auflisten. Dynamische und externe dreiteilige Aufrufer bleiben außerhalb
     * dieser Nachweisgrenze und erklären das zusätzliche zentrale Confirm-Gate.
     */
    SELECT TOP (1)
          @ReferencingSchema = OBJECT_SCHEMA_NAME(sed.referencing_id)
        , @ReferencingObject = OBJECT_NAME(sed.referencing_id)
    FROM sys.sql_expression_dependencies AS sed
    WHERE sed.referenced_id = @ProcedureId
      AND sed.referencing_id <> @ProcedureId
    ORDER BY
          OBJECT_SCHEMA_NAME(sed.referencing_id) COLLATE Latin1_General_100_BIN2
        , OBJECT_NAME(sed.referencing_id) COLLATE Latin1_General_100_BIN2;

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
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF @ProcedureId IS NOT NULL
    BEGIN
        DROP PROCEDURE [toolbelt_core].[USP_PrepareResultTable];
    END;

    /*
     * Das Schema wird nur entfernt, wenn weder reguläre Schemaobjekte noch
     * benutzerdefinierte Types oder XML Schema Collections verbleiben. Fremde
     * beziehungsweise andere Toolbelt-Objekte bleiben vollständig erhalten.
     */
    IF NOT EXISTS
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
