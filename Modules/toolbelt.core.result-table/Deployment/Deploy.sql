:On Error exit

-- ============================================================================
-- Zweck:     Erst-, Upgrade- und Wiederholungsdeployment
-- Modul:     toolbelt.core.result-table v1.0.0
-- Schema:    toolbelt_core
-- Erfordert: SQL Server 2019, 2022 oder 2025
-- Modus:     SQLCMD; Ausführung aus diesem Deployment-Verzeichnis
-- Parameter: DeploymentMode=local|central
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID(N'tempdb..#tbx_ResultTableReleaseObjects', N'U') IS NOT NULL
BEGIN
    DROP TABLE #tbx_ResultTableReleaseObjects;
END;

IF OBJECT_ID(N'tempdb..#tbx_ResultTableDeployState', N'U') IS NOT NULL
BEGIN
    DROP TABLE #tbx_ResultTableDeployState;
END;

/*
 * Dieses Manifest enthält jedes bekannte Release. Bei einem neuen Release
 * bleiben die Zeilen der unterstützten Vorgänger erhalten. Dadurch kann das
 * Deployment objektgenau unterscheiden zwischen:
 * - bereits zum Framework gehörenden Objekten,
 * - im Zielrelease neu hinzukommenden Namen,
 * - im Zielrelease weggefallenen Framework-Objekten.
 */
CREATE TABLE #tbx_ResultTableReleaseObjects
(
      ReleaseVersion nvarchar(64) NOT NULL
    , SchemaName     sysname      NOT NULL
    , ObjectName     sysname      NOT NULL
    , ObjectType     char(2)      NOT NULL
    , CONSTRAINT PK_tbx_ResultTableReleaseObjects
          PRIMARY KEY (ReleaseVersion, SchemaName, ObjectName)
);

INSERT INTO #tbx_ResultTableReleaseObjects
(
      ReleaseVersion
    , SchemaName
    , ObjectName
    , ObjectType
)
VALUES
(
      N'1.0.0'
    , N'toolbelt_core'
    , N'USP_PrepareResultTable'
    , 'P'
);

CREATE TABLE #tbx_ResultTableDeployState
(
      TargetVersion    nvarchar(64) NOT NULL
    , InstalledVersion nvarchar(64) NULL
    , DeploymentMode   nvarchar(16) NOT NULL
    , SchemaCreated     bit          NOT NULL
);

DECLARE
      @TargetVersion        nvarchar(64)  = N'1.0.0'
    , @DeploymentMode       nvarchar(16)  = LOWER(N'$(DeploymentMode)')
    , @InstalledVersion     nvarchar(64)
    , @VersionPropertyName  sysname =
          N'Toolbelt.Module.toolbelt.core.result-table.Version'
    , @ProductMajorVersion  int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @SchemaId             int = SCHEMA_ID(N'toolbelt_core')
    , @CollisionSchema      sysname
    , @CollisionObject      sysname
    , @LockResult           int
    , @DropSql              nvarchar(max)
    , @SchemaCreated        bit = 0;

IF @ProductMajorVersion NOT IN (15, 16, 17)
BEGIN
    THROW 51030, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
END;

IF @DeploymentMode NOT IN (N'local', N'central')
BEGIN
    THROW 51031, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;
END;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = @VersionPropertyName;

IF @InstalledVersion IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM #tbx_ResultTableReleaseObjects AS ro
           WHERE ro.ReleaseVersion COLLATE Latin1_General_100_BIN2
                     = @InstalledVersion COLLATE Latin1_General_100_BIN2
       )
BEGIN
    THROW 51033, N'Die installierte Modulversion ist diesem Deployment nicht als unterstütztes Vorgängerrelease bekannt.', 1;
END;

IF @SchemaId IS NULL
BEGIN
    IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    BEGIN
        THROW 51032, N'Zum Anlegen von toolbelt_core fehlt CREATE SCHEMA in der Installationsdatenbank.', 1;
    END;
END;
ELSE IF HAS_PERMS_BY_NAME(N'toolbelt_core', N'SCHEMA', N'ALTER') <> 1
BEGIN
    THROW 51032, N'Für das vorhandene Schema toolbelt_core fehlt ALTER.', 1;
END;

IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE PROCEDURE') <> 1
BEGIN
    THROW 51032, N'In der Installationsdatenbank fehlt CREATE PROCEDURE.', 1;
END;

/*
 * Ein vorhandener Zielname ist nur dann Framework-Bestand, wenn genau dieser
 * Name im bekannten installierten Release enthalten war. Bei einer
 * Erstinstallation oder einem im Zielrelease neuen Namen wird niemals ein
 * bereits vorhandenes fremdes Objekt überschrieben.
 */
SELECT TOP (1)
      @CollisionSchema = t.SchemaName
    , @CollisionObject = t.ObjectName
FROM #tbx_ResultTableReleaseObjects AS t
INNER JOIN sys.schemas AS s
    ON s.name COLLATE Latin1_General_100_BIN2
          = t.SchemaName COLLATE Latin1_General_100_BIN2
INNER JOIN sys.objects AS o
    ON o.schema_id = s.schema_id
   AND o.name COLLATE Latin1_General_100_BIN2
          = t.ObjectName COLLATE Latin1_General_100_BIN2
WHERE t.ReleaseVersion = @TargetVersion
  AND
  (
      @InstalledVersion IS NULL
      OR NOT EXISTS
         (
             SELECT 1
             FROM #tbx_ResultTableReleaseObjects AS p
             WHERE p.ReleaseVersion COLLATE Latin1_General_100_BIN2
                       = @InstalledVersion COLLATE Latin1_General_100_BIN2
               AND p.SchemaName COLLATE Latin1_General_100_BIN2
                       = t.SchemaName COLLATE Latin1_General_100_BIN2
               AND p.ObjectName COLLATE Latin1_General_100_BIN2
                       = t.ObjectName COLLATE Latin1_General_100_BIN2
         )
  )
ORDER BY
      t.SchemaName COLLATE Latin1_General_100_BIN2
    , t.ObjectName COLLATE Latin1_General_100_BIN2;

IF @CollisionObject IS NOT NULL
BEGIN
    DECLARE @CollisionMessage nvarchar(2048) =
        N'Das neue Framework-Objekt '
        + QUOTENAME(@CollisionSchema)
        + N'.'
        + QUOTENAME(@CollisionObject)
        + N' ist bereits vorhanden, stammt aber nicht aus dem bekannten installierten Release.';
    SET @CollisionMessage = REPLACE(@CollisionMessage, N'%', N'%%');
    THROW 51034, @CollisionMessage, 1;
END;

INSERT INTO #tbx_ResultTableDeployState
(
      TargetVersion
    , InstalledVersion
    , DeploymentMode
    , SchemaCreated
)
VALUES
(
      @TargetVersion
    , @InstalledVersion
    , @DeploymentMode
    , 0
);

/*
 * Der vollständige Preflight ist abgeschlossen. Erst jetzt beginnt die kurze
 * Mutationstransaktion. Eine Transaction-owned Application Lock serialisiert
 * Deployments dieses Moduls innerhalb der Zieldatenbank.
 */
BEGIN TRY
    BEGIN TRANSACTION;

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
           <> ISNULL(@InstalledVersion, N'') COLLATE Latin1_General_100_BIN2
    BEGIN
        THROW 51037, N'Der installierte Modulstand hat sich seit dem Preflight verändert.', 1;
    END;

    SET @CollisionSchema = NULL;
    SET @CollisionObject = NULL;

    SELECT TOP (1)
          @CollisionSchema = t.SchemaName
        , @CollisionObject = t.ObjectName
    FROM #tbx_ResultTableReleaseObjects AS t
    INNER JOIN sys.schemas AS s
        ON s.name COLLATE Latin1_General_100_BIN2
              = t.SchemaName COLLATE Latin1_General_100_BIN2
    INNER JOIN sys.objects AS o
        ON o.schema_id = s.schema_id
       AND o.name COLLATE Latin1_General_100_BIN2
              = t.ObjectName COLLATE Latin1_General_100_BIN2
    WHERE t.ReleaseVersion = @TargetVersion
      AND
      (
          @InstalledVersion IS NULL
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM #tbx_ResultTableReleaseObjects AS p
                 WHERE p.ReleaseVersion COLLATE Latin1_General_100_BIN2
                           = @InstalledVersion COLLATE Latin1_General_100_BIN2
                   AND p.SchemaName COLLATE Latin1_General_100_BIN2
                           = t.SchemaName COLLATE Latin1_General_100_BIN2
                   AND p.ObjectName COLLATE Latin1_General_100_BIN2
                           = t.ObjectName COLLATE Latin1_General_100_BIN2
             )
      );

    IF @CollisionObject IS NOT NULL
    BEGIN
        THROW 51037, N'Ein Zielobjekt hat sich seit dem Preflight verändert oder ist neu hinzugekommen.', 1;
    END;

    SET @SchemaId = SCHEMA_ID(N'toolbelt_core');

    IF @SchemaId IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_core];';
        SET @SchemaCreated = 1;
        SET @SchemaId = SCHEMA_ID(N'toolbelt_core');

        EXEC sys.sp_addextendedproperty
              @name       = N'Toolbelt.Managed'
            , @value      = 1
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core';

        EXEC sys.sp_addextendedproperty
              @name       = N'Toolbelt.SchemaCategory'
            , @value      = N'core'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core';
    END;

    UPDATE #tbx_ResultTableDeployState
    SET SchemaCreated = @SchemaCreated;

    /*
     * Ein Objekt verschwindet nur dann, wenn es im bekannten installierten
     * Release enthalten war und im Zielrelease fehlt. Andere Objekte werden
     * durch diesen Block weder ausgewählt noch verändert.
     */
    SELECT @DropSql =
        STUFF
        (
            (
                SELECT
                      NCHAR(10)
                    + CASE
                          WHEN o.type IN ('P', 'PC')
                              THEN N'DROP PROCEDURE '
                          WHEN o.type = 'V'
                              THEN N'DROP VIEW '
                          WHEN o.type IN ('FN', 'FS', 'FT', 'IF', 'TF')
                              THEN N'DROP FUNCTION '
                          ELSE N''
                      END
                    + QUOTENAME(s.name)
                    + N'.'
                    + QUOTENAME(o.name)
                    + N';'
                FROM #tbx_ResultTableReleaseObjects AS p
                INNER JOIN sys.schemas AS s
                    ON s.name COLLATE Latin1_General_100_BIN2
                          = p.SchemaName COLLATE Latin1_General_100_BIN2
                INNER JOIN sys.objects AS o
                    ON o.schema_id = s.schema_id
                   AND o.name COLLATE Latin1_General_100_BIN2
                          = p.ObjectName COLLATE Latin1_General_100_BIN2
                WHERE p.ReleaseVersion COLLATE Latin1_General_100_BIN2
                          = @InstalledVersion COLLATE Latin1_General_100_BIN2
                  AND NOT EXISTS
                      (
                          SELECT 1
                          FROM #tbx_ResultTableReleaseObjects AS t
                          WHERE t.ReleaseVersion = @TargetVersion
                            AND t.SchemaName COLLATE Latin1_General_100_BIN2
                                  = p.SchemaName COLLATE Latin1_General_100_BIN2
                            AND t.ObjectName COLLATE Latin1_General_100_BIN2
                                  = p.ObjectName COLLATE Latin1_General_100_BIN2
                      )
                  AND o.type IN ('P', 'PC', 'V', 'FN', 'FS', 'FT', 'IF', 'TF')
                ORDER BY
                      s.name COLLATE Latin1_General_100_BIN2
                    , o.name COLLATE Latin1_General_100_BIN2
                FOR XML PATH(N''), TYPE
            ).value(N'.', N'nvarchar(max)')
          , 1
          , 1
          , N''
        );

    IF NULLIF(@DropSql, N'') IS NOT NULL
    BEGIN
        EXEC sys.sp_executesql @DropSql;
    END;

    /*
     * Wurde ein Framework-Objekt lokal in einen anderen unterstützten
     * Objekttyp umgebaut, bleibt seine Herkunft aus dem Vorgängerrelease
     * maßgeblich. Der falsche Typ wird entfernt, damit die kanonische Source
     * den Zieltyp neu anlegen kann.
     */
    SET @DropSql = NULL;

    SELECT @DropSql =
        STUFF
        (
            (
                SELECT
                      NCHAR(10)
                    + CASE
                          WHEN o.type IN ('P', 'PC')
                              THEN N'DROP PROCEDURE '
                          WHEN o.type = 'V'
                              THEN N'DROP VIEW '
                          WHEN o.type IN ('FN', 'FS', 'FT', 'IF', 'TF')
                              THEN N'DROP FUNCTION '
                          ELSE N''
                      END
                    + QUOTENAME(s.name)
                    + N'.'
                    + QUOTENAME(o.name)
                    + N';'
                FROM #tbx_ResultTableReleaseObjects AS t
                INNER JOIN #tbx_ResultTableReleaseObjects AS p
                    ON p.ReleaseVersion COLLATE Latin1_General_100_BIN2
                          = @InstalledVersion COLLATE Latin1_General_100_BIN2
                   AND p.SchemaName COLLATE Latin1_General_100_BIN2
                          = t.SchemaName COLLATE Latin1_General_100_BIN2
                   AND p.ObjectName COLLATE Latin1_General_100_BIN2
                          = t.ObjectName COLLATE Latin1_General_100_BIN2
                INNER JOIN sys.schemas AS s
                    ON s.name COLLATE Latin1_General_100_BIN2
                          = t.SchemaName COLLATE Latin1_General_100_BIN2
                INNER JOIN sys.objects AS o
                    ON o.schema_id = s.schema_id
                   AND o.name COLLATE Latin1_General_100_BIN2
                          = t.ObjectName COLLATE Latin1_General_100_BIN2
                WHERE t.ReleaseVersion = @TargetVersion
                  AND o.type <> t.ObjectType
                  AND o.type IN ('P', 'PC', 'V', 'FN', 'FS', 'FT', 'IF', 'TF')
                ORDER BY
                      s.name COLLATE Latin1_General_100_BIN2
                    , o.name COLLATE Latin1_General_100_BIN2
                FOR XML PATH(N''), TYPE
            ).value(N'.', N'nvarchar(max)')
          , 1
          , 1
          , N''
        );

    IF NULLIF(@DropSql, N'') IS NOT NULL
    BEGIN
        EXEC sys.sp_executesql @DropSql;
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
 * Die kanonische Source liegt exakt einmal im Repository. CREATE OR ALTER
 * überschreibt bei Erst-, Upgrade- und Wiederholungsdeployment die
 * Framework-Procedure innerhalb der bereits geöffneten Transaktion.
 */
:r ../Source/USP_PrepareResultTable.sql

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    DECLARE
          @ProcedureId          int =
              OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P')
        , @DeploymentMode       nvarchar(16)
        , @TargetVersion        nvarchar(64)
        , @SourceHash           varchar(64)
        , @VersionPropertyName  sysname =
              N'Toolbelt.Module.toolbelt.core.result-table.Version'
        , @ModePropertyName     sysname =
              N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode';

    SELECT
          @DeploymentMode = DeploymentMode
        , @TargetVersion = TargetVersion
    FROM #tbx_ResultTableDeployState;

    IF XACT_STATE() <> 1 OR @ProcedureId IS NULL
    BEGIN
        THROW 51038, N'Die Framework-Procedure wurde nicht vollständig innerhalb der Deployment-Transaktion angelegt.', 1;
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

    DECLARE @ObjectProperties TABLE
    (
          PropertyOrdinal int IDENTITY(1, 1) NOT NULL
        , PropertyName    sysname            NOT NULL
        , PropertyValue   nvarchar(4000)     NOT NULL
    );

    INSERT INTO @ObjectProperties (PropertyName, PropertyValue)
    VALUES
          (N'Toolbelt.ModuleId', N'toolbelt.core.result-table')
        , (N'Toolbelt.ModuleVersion', @TargetVersion)
        , (N'Toolbelt.ContractVersion', N'1.0')
        , (N'Toolbelt.DeploymentMode', @DeploymentMode)
        , (N'Toolbelt.SourceHash', CONVERT(nvarchar(4000), @SourceHash));

    DECLARE
          @PropertyOrdinal int = 1
        , @PropertyCount   int = (SELECT COUNT(*) FROM @ObjectProperties)
        , @PropertyName    sysname
        , @PropertyValue   nvarchar(4000);

    WHILE @PropertyOrdinal <= @PropertyCount
    BEGIN
        SELECT
              @PropertyName = PropertyName
            , @PropertyValue = PropertyValue
        FROM @ObjectProperties
        WHERE PropertyOrdinal = @PropertyOrdinal;

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

        SET @PropertyOrdinal += 1;
    END;

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 0
             AND ep.major_id = 0
             AND ep.minor_id = 0
             AND ep.name = @VersionPropertyName
       )
    BEGIN
        EXEC sys.sp_updateextendedproperty
              @name = @VersionPropertyName
            , @value = @TargetVersion;
    END;
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
              @name = @VersionPropertyName
            , @value = @TargetVersion;
    END;

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 0
             AND ep.major_id = 0
             AND ep.minor_id = 0
             AND ep.name = @ModePropertyName
       )
    BEGIN
        EXEC sys.sp_updateextendedproperty
              @name = @ModePropertyName
            , @value = @DeploymentMode;
    END;
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
              @name = @ModePropertyName
            , @value = @DeploymentMode;
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
