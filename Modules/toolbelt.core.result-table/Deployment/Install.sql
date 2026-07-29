:On Error exit
:setvar DeploymentMode "local"

-- ============================================================================
-- Zweck:     Erstinstallation von Result Table Infrastructure
-- Modul:     toolbelt.core.result-table v1.0.0
-- Schema:    toolbelt_core
-- Erfordert: SQL Server 2019, 2022 oder 2025
-- Modus:     SQLCMD; Ausführung aus diesem Deployment-Verzeichnis
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ProductMajorVersion int = TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @DeploymentMode      nvarchar(16) = N'$(DeploymentMode)'
    , @SchemaId            int = SCHEMA_ID(N'toolbelt_core')
    , @ProcedureId         int = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P')
    , @SchemaManaged       int
    , @SchemaCategory      nvarchar(128)
    , @ModuleId            nvarchar(256)
    , @ModuleVersion       nvarchar(64)
    , @ContractVersion     nvarchar(64)
    , @ExistingDeploymentMode nvarchar(16)
    , @RecordedSourceHash  varchar(64)
    , @ActualSourceHash    varchar(64);

IF @ProductMajorVersion NOT IN (15, 16, 17)
BEGIN
    THROW 51030, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
END;

IF @DeploymentMode NOT IN (N'local', N'central')
BEGIN
    THROW 51031, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;
END;

IF @SchemaId IS NULL
   AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
BEGIN
    THROW 51032, N'Zum Anlegen von toolbelt_core fehlt CREATE SCHEMA in der Installationsdatenbank.', 1;
END;

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

    IF ISNULL(@SchemaManaged, 0) <> 1
       OR ISNULL(@SchemaCategory, N'') COLLATE Latin1_General_100_BIN2 <> N'core'
    BEGIN
        THROW 51032, N'Das vorhandene Schema toolbelt_core ist nicht eindeutig als verwaltetes Toolbelt-Core-Schema markiert.', 1;
    END;

    IF HAS_PERMS_BY_NAME(N'toolbelt_core', N'SCHEMA', N'ALTER') <> 1
    BEGIN
        THROW 51032, N'Für das vorhandene Schema toolbelt_core fehlt ALTER.', 1;
    END;
END;

IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE PROCEDURE') <> 1
BEGIN
    THROW 51032, N'In der Installationsdatenbank fehlt CREATE PROCEDURE.', 1;
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
        , @ContractVersion = MAX
          (
              CASE
                  WHEN ep.name = N'Toolbelt.ContractVersion'
                      THEN TRY_CONVERT(nvarchar(64), ep.value)
              END
          )
        , @ExistingDeploymentMode = MAX
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

    IF ISNULL(@ModuleId, N'') COLLATE Latin1_General_100_BIN2
           <> N'toolbelt.core.result-table'
    BEGIN
        THROW 51033, N'Die vorhandene Procedure besitzt keinen passenden Toolbelt.ModuleId-Marker und wird nicht überschrieben.', 1;
    END;

    IF ISNULL(@ModuleVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
       OR ISNULL(@ContractVersion, N'') COLLATE Latin1_General_100_BIN2 <> N'1.0'
       OR ISNULL(@ExistingDeploymentMode, N'') COLLATE Latin1_General_100_BIN2
              <> @DeploymentMode COLLATE Latin1_General_100_BIN2
    BEGIN
        THROW 51033, N'Modulversion, Contract-Version oder Deployment-Modus entsprechen nicht der angeforderten identischen Installation. Verwenden Sie den kontrollierten Upgrade-Pfad.', 1;
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
        THROW 51034, N'Die vorhandene Procedure weicht von ihrem aufgezeichneten Source-Hash ab und wird nicht stillschweigend überschrieben.', 1;
    END;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF @SchemaId IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];';
    END;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO

/*
 * Kanonische Source wird über SQLCMD eingebunden. Die offene Transaktion bleibt
 * über die Batch-Grenze bestehen. :On Error exit beziehungsweise sqlcmd -b
 * beendet bei einem Source-Fehler die Verbindung; SQL Server rollt die offene
 * Transaktion dadurch zurück.
 */
:r ../Source/USP_PrepareResultTable.sql

BEGIN TRY
    DECLARE
          @ProcedureId        int = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P')
        , @DeploymentMode     nvarchar(16) = N'$(DeploymentMode)'
        , @SourceHash         varchar(64);

    IF XACT_STATE() <> 1 OR @ProcedureId IS NULL
    BEGIN
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW 51034, N'Die Procedure wurde nicht vollständig angelegt; die Installation wurde zurückgerollt.', 1;
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

    IF EXISTS
    (
        SELECT 1
        FROM sys.extended_properties AS ep
        WHERE ep.class = 3
          AND ep.major_id = SCHEMA_ID(N'toolbelt_core')
          AND ep.name = N'Toolbelt.Managed'
    )
    BEGIN
        EXEC sys.sp_updateextendedproperty
              @name       = N'Toolbelt.Managed'
            , @value      = 1
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core';
    END;
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
              @name       = N'Toolbelt.Managed'
            , @value      = 1
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core';
    END;

    IF EXISTS
    (
        SELECT 1
        FROM sys.extended_properties AS ep
        WHERE ep.class = 3
          AND ep.major_id = SCHEMA_ID(N'toolbelt_core')
          AND ep.name = N'Toolbelt.SchemaCategory'
    )
    BEGIN
        EXEC sys.sp_updateextendedproperty
              @name       = N'Toolbelt.SchemaCategory'
            , @value      = N'core'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core';
    END;
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
              @name       = N'Toolbelt.SchemaCategory'
            , @value      = N'core'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core';
    END;

    DECLARE @ProcedureProperties TABLE
    (
          PropertyName  sysname       NOT NULL
        , PropertyValue nvarchar(4000) NOT NULL
    );

    INSERT INTO @ProcedureProperties (PropertyName, PropertyValue)
    VALUES
          (N'Toolbelt.ModuleId', N'toolbelt.core.result-table')
        , (N'Toolbelt.ModuleVersion', N'1.0.0')
        , (N'Toolbelt.ContractVersion', N'1.0')
        , (N'Toolbelt.DeploymentMode', @DeploymentMode)
        , (N'Toolbelt.SourceHash', CONVERT(nvarchar(4000), @SourceHash));

    DECLARE
          @PropertyName  sysname
        , @PropertyValue nvarchar(4000);

    -- Der Cursor verarbeitet eine feste, kleine Marker-Menge und hält die
    -- identischen Add-/Update-Aufrufe an genau einer Stelle.
    DECLARE PropertyCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT PropertyName, PropertyValue
        FROM @ProcedureProperties
        ORDER BY PropertyName;

    OPEN PropertyCursor;
    FETCH NEXT FROM PropertyCursor INTO @PropertyName, @PropertyValue;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS
        (
            SELECT 1
            FROM sys.extended_properties AS ep
            WHERE ep.class = 1
              AND ep.major_id = @ProcedureId
              AND ep.minor_id = 0
              AND ep.name = @PropertyName
        )
        BEGIN
            EXEC sys.sp_updateextendedproperty
                  @name       = @PropertyName
                , @value      = @PropertyValue
                , @level0type = N'SCHEMA'
                , @level0name = N'toolbelt_core'
                , @level1type = N'PROCEDURE'
                , @level1name = N'USP_PrepareResultTable';
        END;
        ELSE
        BEGIN
            EXEC sys.sp_addextendedproperty
                  @name       = @PropertyName
                , @value      = @PropertyValue
                , @level0type = N'SCHEMA'
                , @level0name = N'toolbelt_core'
                , @level1type = N'PROCEDURE'
                , @level1name = N'USP_PrepareResultTable';
        END;

        FETCH NEXT FROM PropertyCursor INTO @PropertyName, @PropertyValue;
    END;

    CLOSE PropertyCursor;
    DEALLOCATE PropertyCursor;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS(N'local', N'PropertyCursor') >= -1
    BEGIN
        IF CURSOR_STATUS(N'local', N'PropertyCursor') > -1
        BEGIN
            CLOSE PropertyCursor;
        END;

        DEALLOCATE PropertyCursor;
    END;

    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO
