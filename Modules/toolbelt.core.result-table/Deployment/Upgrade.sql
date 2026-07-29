:On Error exit

-- ============================================================================
-- Zweck:     Kontrolliertes Upgrade von Result Table Infrastructure
-- Modul:     toolbelt.core.result-table auf v1.0.0
-- Schema:    toolbelt_core
-- Erfordert: Bereits verwaltete bekannte Modulversion
-- Modus:     SQLCMD; Ausführung aus diesem Deployment-Verzeichnis
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ProductMajorVersion int = TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @SchemaId            int = SCHEMA_ID(N'toolbelt_core')
    , @ProcedureId         int = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P')
    , @SchemaManaged       int
    , @SchemaCategory      nvarchar(128)
    , @ModuleId            nvarchar(256)
    , @ModuleVersion       nvarchar(64)
    , @ContractVersion     nvarchar(64)
    , @DeploymentMode      nvarchar(16)
    , @RecordedSourceHash  varchar(64)
    , @ActualSourceHash    varchar(64);

IF @ProductMajorVersion NOT IN (15, 16, 17)
BEGIN
    THROW 51030, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
END;

IF @SchemaId IS NULL OR @ProcedureId IS NULL
BEGIN
    THROW 51033, N'Für ein Upgrade fehlt die vorhandene Modulinstallation. Verwenden Sie Install.sql.', 1;
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
    , @ContractVersion = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.ContractVersion'
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
    , @RecordedSourceHash = MAX
      (
          CASE
              WHEN ep.name = N'Toolbelt.SourceHash'
                  THEN TRY_CONVERT(varchar(64), ep.value)
          END
      )
FROM sys.extended_properties AS ep
WHERE ep.class = 1
  AND ep.major_id = @ProcedureId
  AND ep.minor_id = 0;

IF ISNULL(@SchemaManaged, 0) <> 1
   OR ISNULL(@SchemaCategory, N'') COLLATE Latin1_General_100_BIN2 <> N'core'
   OR ISNULL(@ModuleId, N'') COLLATE Latin1_General_100_BIN2
          <> N'toolbelt.core.result-table'
BEGIN
    THROW 51033, N'Die vorhandene Installation besitzt fremde oder unvollständige Ownership-Marker.', 1;
END;

/*
 * Version 1.0.0 ist die erste veröffentlichte Modulversion. Der aktuelle
 * Upgrade-Pfad ist deshalb nur als kontrolliert wiederholbare Aktualisierung
 * derselben Version zulässig. Spätere Versionen ergänzen explizite bekannte
 * Vorgänger; unbekannte Versionen werden niemals still überschrieben.
 */
IF ISNULL(@ModuleVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
   OR ISNULL(@ContractVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0'
   OR ISNULL(@DeploymentMode, N'') NOT IN (N'local', N'central')
BEGIN
    THROW 51033, N'Für die vorhandene Modulversion ist in diesem Artefakt kein unterstützter Upgrade-Pfad definiert.', 1;
END;

SET @ActualSourceHash = CONVERT
(
      varchar(64)
    , HASHBYTES
      (
          N'SHA2_256'
        , CONVERT(varbinary(max), OBJECT_DEFINITION(@ProcedureId))
      )
    , 2
);

IF @RecordedSourceHash IS NULL
   OR @ActualSourceHash IS NULL
   OR @RecordedSourceHash COLLATE Latin1_General_100_BIN2
          <> @ActualSourceHash COLLATE Latin1_General_100_BIN2
BEGIN
    THROW 51034, N'Die vorhandene Procedure weicht von ihrem aufgezeichneten Source-Hash ab. Das Upgrade überschreibt keine ungeklärte lokale Änderung.', 1;
END;

IF HAS_PERMS_BY_NAME(N'toolbelt_core', N'SCHEMA', N'ALTER') <> 1
   OR HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE PROCEDURE') <> 1
BEGIN
    THROW 51032, N'Für das Upgrade fehlen ALTER auf toolbelt_core oder CREATE PROCEDURE in der Datenbank.', 1;
END;

BEGIN TRANSACTION;
GO

:r ../Source/USP_PrepareResultTable.sql

BEGIN TRY
    DECLARE
          @ProcedureId        int = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P')
        , @SourceHash         varchar(64)
        , @DeploymentMode     nvarchar(16);

    IF XACT_STATE() <> 1 OR @ProcedureId IS NULL
    BEGIN
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW 51034, N'Die Procedure wurde im Upgrade nicht vollständig aktualisiert; die Transaktion wurde zurückgerollt.', 1;
    END;

    SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), ep.value)
    FROM sys.extended_properties AS ep
    WHERE ep.class = 1
      AND ep.major_id = @ProcedureId
      AND ep.minor_id = 0
      AND ep.name = N'Toolbelt.DeploymentMode';

    IF ISNULL(@DeploymentMode, N'') NOT IN (N'local', N'central')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51033, N'Der Deployment-Modus wurde beim Upgrade nicht erhalten.', 1;
    END;

    SET @SourceHash = CONVERT
    (
          varchar(64)
        , HASHBYTES
          (
              N'SHA2_256'
            , CONVERT(varbinary(max), OBJECT_DEFINITION(@ProcedureId))
          )
        , 2
    );

    EXEC sys.sp_updateextendedproperty
          @name       = N'Toolbelt.ModuleId'
        , @value      = N'toolbelt.core.result-table'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_PrepareResultTable';

    EXEC sys.sp_updateextendedproperty
          @name       = N'Toolbelt.ContractVersion'
        , @value      = N'1.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_PrepareResultTable';

    EXEC sys.sp_updateextendedproperty
          @name       = N'Toolbelt.SourceHash'
        , @value      = @SourceHash
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_PrepareResultTable';

    /*
     * Die Modulversion wird absichtlich zuletzt aktualisiert. Für Version
     * 1.0.0 bleibt sie gleich; dieses Muster bildet das Breaking-Change-Gate
     * für spätere bekannte Vorgängerversionen.
     */
    EXEC sys.sp_updateextendedproperty
          @name       = N'Toolbelt.ModuleVersion'
        , @value      = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_PrepareResultTable';

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
