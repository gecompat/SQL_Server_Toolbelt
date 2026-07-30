:On Error exit

-- ============================================================================
-- Zweck:     Erst-, Upgrade- und Wiederholungsdeployment
-- Modul:     toolbelt.string.split-characters v1.0.0
-- Schema:    toolbelt_string
-- Erfordert: SQL Server 2019, 2022 oder 2025
-- Modus:     SQLCMD; Ausführung aus diesem Deployment-Verzeichnis
-- Parameter: DeploymentMode=local|central
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID(N'tempdb..#tbx_SplitCharactersReleaseObjects', N'U') IS NOT NULL
BEGIN
    DROP TABLE #tbx_SplitCharactersReleaseObjects;
END;

IF OBJECT_ID(N'tempdb..#tbx_SplitCharactersDeployState', N'U') IS NOT NULL
BEGIN
    DROP TABLE #tbx_SplitCharactersDeployState;
END;

CREATE TABLE #tbx_SplitCharactersReleaseObjects
(
      ReleaseVersion nvarchar(64) NOT NULL
    , SchemaName     sysname      NOT NULL
    , ObjectName     sysname      NOT NULL
    , ObjectType     char(2)      NOT NULL
    , CONSTRAINT PK_tbx_SplitCharactersReleaseObjects
          PRIMARY KEY (ReleaseVersion, SchemaName, ObjectName)
);

INSERT INTO #tbx_SplitCharactersReleaseObjects
(
      ReleaseVersion
    , SchemaName
    , ObjectName
    , ObjectType
)
VALUES
      (N'1.0.0', N'toolbelt_string', N'TVF_SplitByCharacters', 'IF');

CREATE TABLE #tbx_SplitCharactersDeployState
(
      TargetVersion    nvarchar(64) NOT NULL
    , InstalledVersion nvarchar(64) NULL
    , DeploymentMode   nvarchar(16) NOT NULL
    , SchemaCreated     bit          NOT NULL
);

DECLARE
      @TargetVersion        nvarchar(64) = N'1.0.0'
    , @DeploymentMode       nvarchar(16) = LOWER(N'$(DeploymentMode)')
    , @InstalledVersion     nvarchar(64)
    , @DependencyVersion    nvarchar(64)
    , @VersionPropertyName  sysname =
          N'Toolbelt.Module.toolbelt.string.split-characters.Version'
    , @ProductMajorVersion  int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @SchemaId             int = SCHEMA_ID(N'toolbelt_string')
    , @CollisionSchema      sysname
    , @CollisionObject      sysname
    , @LockResult           int
    , @DropSql              nvarchar(max)
    , @SchemaCreated        bit = 0;

IF @ProductMajorVersion NOT IN (15, 16, 17)
BEGIN
    THROW 51070, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
END;

IF @DeploymentMode NOT IN (N'local', N'central')
BEGIN
    THROW 51071, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;
END;

SELECT @DependencyVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = N'Toolbelt.Module.toolbelt.core.generate-series.Version';

IF ISNULL(@DependencyVersion, N'')
       COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
   OR OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt', N'IF') IS NULL
BEGIN
    THROW 51079, N'toolbelt.core.generate-series Version 1.0.0 muss vor diesem Modul in derselben Datenbank installiert sein.', 1;
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
           FROM #tbx_SplitCharactersReleaseObjects AS ro
           WHERE ro.ReleaseVersion COLLATE Latin1_General_100_BIN2
                     = @InstalledVersion COLLATE Latin1_General_100_BIN2
       )
BEGIN
    THROW 51073, N'Die installierte Modulversion ist diesem Deployment nicht als unterstütztes Vorgängerrelease bekannt.', 1;
END;

IF @SchemaId IS NULL
BEGIN
    IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    BEGIN
        THROW 51072, N'Zum Anlegen von toolbelt_string fehlt CREATE SCHEMA in der Installationsdatenbank.', 1;
    END;
END;
ELSE IF HAS_PERMS_BY_NAME(N'toolbelt_string', N'SCHEMA', N'ALTER') <> 1
BEGIN
    THROW 51072, N'Für das vorhandene Schema toolbelt_string fehlt ALTER.', 1;
END;

IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE FUNCTION') <> 1
BEGIN
    THROW 51072, N'In der Installationsdatenbank fehlt CREATE FUNCTION.', 1;
END;

/*
 * Neue Zielnamen dürfen kein frameworkfremdes Objekt überschreiben. Ein Name
 * gilt nur dann als Framework-Bestand, wenn er im bekannten installierten
 * Release enthalten ist.
 */
SELECT TOP (1)
      @CollisionSchema = target.SchemaName
    , @CollisionObject = target.ObjectName
FROM #tbx_SplitCharactersReleaseObjects AS target
INNER JOIN sys.schemas AS schemas
    ON schemas.name COLLATE Latin1_General_100_BIN2
          = target.SchemaName COLLATE Latin1_General_100_BIN2
INNER JOIN sys.objects AS objects
    ON objects.schema_id = schemas.schema_id
   AND objects.name COLLATE Latin1_General_100_BIN2
          = target.ObjectName COLLATE Latin1_General_100_BIN2
WHERE target.ReleaseVersion = @TargetVersion
  AND
  (
      @InstalledVersion IS NULL
      OR NOT EXISTS
         (
             SELECT 1
             FROM #tbx_SplitCharactersReleaseObjects AS previous
             WHERE previous.ReleaseVersion COLLATE Latin1_General_100_BIN2
                       = @InstalledVersion COLLATE Latin1_General_100_BIN2
               AND previous.SchemaName COLLATE Latin1_General_100_BIN2
                       = target.SchemaName COLLATE Latin1_General_100_BIN2
               AND previous.ObjectName COLLATE Latin1_General_100_BIN2
                       = target.ObjectName COLLATE Latin1_General_100_BIN2
         )
  )
ORDER BY target.ObjectName COLLATE Latin1_General_100_BIN2;

IF @CollisionObject IS NOT NULL
BEGIN
    DECLARE @CollisionMessage nvarchar(2048) =
        N'Das neue Framework-Objekt '
        + QUOTENAME(@CollisionSchema)
        + N'.'
        + QUOTENAME(@CollisionObject)
        + N' ist bereits vorhanden, stammt aber nicht aus dem bekannten installierten Release.';
    SET @CollisionMessage = REPLACE(@CollisionMessage, N'%', N'%%');
    THROW 51074, @CollisionMessage, 1;
END;

INSERT INTO #tbx_SplitCharactersDeployState
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

BEGIN TRY
    BEGIN TRANSACTION;

    EXEC @LockResult = sys.sp_getapplock
          @Resource    = N'toolbelt.deploy.toolbelt.string.split-characters'
        , @LockMode    = N'Exclusive'
        , @LockOwner   = N'Transaction'
        , @LockTimeout = 0
        , @DbPrincipal = N'public';

    IF @LockResult < 0
    BEGIN
        THROW 51077, N'Ein paralleles Deployment von toolbelt.string.split-characters ist bereits aktiv.', 1;
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
        THROW 51077, N'Der installierte Modulstand hat sich seit dem Preflight verändert.', 1;
    END;

    SET @CollisionSchema = NULL;
    SET @CollisionObject = NULL;

    SELECT TOP (1)
          @CollisionSchema = target.SchemaName
        , @CollisionObject = target.ObjectName
    FROM #tbx_SplitCharactersReleaseObjects AS target
    INNER JOIN sys.schemas AS schemas
        ON schemas.name COLLATE Latin1_General_100_BIN2
              = target.SchemaName COLLATE Latin1_General_100_BIN2
    INNER JOIN sys.objects AS objects
        ON objects.schema_id = schemas.schema_id
       AND objects.name COLLATE Latin1_General_100_BIN2
              = target.ObjectName COLLATE Latin1_General_100_BIN2
    WHERE target.ReleaseVersion = @TargetVersion
      AND
      (
          @InstalledVersion IS NULL
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM #tbx_SplitCharactersReleaseObjects AS previous
                 WHERE previous.ReleaseVersion COLLATE Latin1_General_100_BIN2
                           = @InstalledVersion COLLATE Latin1_General_100_BIN2
                   AND previous.SchemaName COLLATE Latin1_General_100_BIN2
                           = target.SchemaName COLLATE Latin1_General_100_BIN2
                   AND previous.ObjectName COLLATE Latin1_General_100_BIN2
                           = target.ObjectName COLLATE Latin1_General_100_BIN2
             )
      );

    IF @CollisionObject IS NOT NULL
    BEGIN
        THROW 51077, N'Ein Zielobjekt hat sich seit dem Preflight verändert oder ist neu hinzugekommen.', 1;
    END;

    IF SCHEMA_ID(N'toolbelt_string') IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_string];';
        SET @SchemaCreated = 1;

        EXEC sys.sp_addextendedproperty
              @name       = N'Toolbelt.Managed'
            , @value      = 1
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_string';

        EXEC sys.sp_addextendedproperty
              @name       = N'Toolbelt.SchemaCategory'
            , @value      = N'string'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_string';
    END;

    UPDATE #tbx_SplitCharactersDeployState
    SET SchemaCreated = @SchemaCreated;

    /*
     * Ein lokal verändertes Release-Objekt mit falschem Typ wird anhand des
     * bekannten Vorgänger-Manifests entfernt. Fremde Namen bleiben unberührt.
     */
    SELECT @DropSql =
        STUFF
        (
            (
                SELECT
                      NCHAR(10)
                    + CASE
                          WHEN objects.type IN ('P', 'PC')
                              THEN N'DROP PROCEDURE '
                          WHEN objects.type = 'V'
                              THEN N'DROP VIEW '
                          WHEN objects.type IN ('FN', 'FS', 'FT', 'IF', 'TF')
                              THEN N'DROP FUNCTION '
                          ELSE N''
                      END
                    + QUOTENAME(schemas.name)
                    + N'.'
                    + QUOTENAME(objects.name)
                    + N';'
                FROM #tbx_SplitCharactersReleaseObjects AS target
                INNER JOIN #tbx_SplitCharactersReleaseObjects AS previous
                    ON previous.ReleaseVersion COLLATE Latin1_General_100_BIN2
                          = @InstalledVersion COLLATE Latin1_General_100_BIN2
                   AND previous.SchemaName COLLATE Latin1_General_100_BIN2
                          = target.SchemaName COLLATE Latin1_General_100_BIN2
                   AND previous.ObjectName COLLATE Latin1_General_100_BIN2
                          = target.ObjectName COLLATE Latin1_General_100_BIN2
                INNER JOIN sys.schemas AS schemas
                    ON schemas.name COLLATE Latin1_General_100_BIN2
                          = target.SchemaName COLLATE Latin1_General_100_BIN2
                INNER JOIN sys.objects AS objects
                    ON objects.schema_id = schemas.schema_id
                   AND objects.name COLLATE Latin1_General_100_BIN2
                          = target.ObjectName COLLATE Latin1_General_100_BIN2
                WHERE target.ReleaseVersion = @TargetVersion
                  AND objects.type COLLATE Latin1_General_100_BIN2
                        <> target.ObjectType COLLATE Latin1_General_100_BIN2
                  AND objects.type IN ('P', 'PC', 'V', 'FN', 'FS', 'FT', 'IF', 'TF')
                ORDER BY objects.name COLLATE Latin1_General_100_BIN2
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

:r ../Source/TVF_SplitByCharacters.sql

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    DECLARE
          @DeploymentMode      nvarchar(16)
        , @TargetVersion       nvarchar(64)
        , @VersionPropertyName sysname =
              N'Toolbelt.Module.toolbelt.string.split-characters.Version'
        , @ModePropertyName    sysname =
              N'Toolbelt.Module.toolbelt.string.split-characters.DeploymentMode';

    SELECT
          @DeploymentMode = DeploymentMode
        , @TargetVersion = TargetVersion
    FROM #tbx_SplitCharactersDeployState;

    IF XACT_STATE() <> 1
       OR OBJECT_ID(N'toolbelt_string.TVF_SplitByCharacters', N'IF') IS NULL
    BEGIN
        THROW 51078, N'Die Framework-Funktionen wurden nicht vollständig innerhalb der Deployment-Transaktion angelegt.', 1;
    END;

    DECLARE @Objects TABLE
    (
          ObjectOrdinal int IDENTITY(1, 1) NOT NULL
        , ObjectName    sysname            NOT NULL
    );

    INSERT INTO @Objects (ObjectName)
    VALUES (N'TVF_SplitByCharacters');

    DECLARE
          @ObjectOrdinal int = 1
        , @ObjectCount   int = (SELECT COUNT(*) FROM @Objects)
        , @ObjectName    sysname
        , @ObjectId      int
        , @SourceHash    varchar(64)
        , @PropertyOrdinal int
        , @PropertyCount   int
        , @PropertyName    sysname
        , @PropertyValue   nvarchar(4000);

    DECLARE @Properties TABLE
    (
          PropertyOrdinal int            NOT NULL PRIMARY KEY
        , PropertyName    sysname        NOT NULL
        , PropertyValue   nvarchar(4000) NOT NULL
    );

    WHILE @ObjectOrdinal <= @ObjectCount
    BEGIN
        SELECT @ObjectName = ObjectName
        FROM @Objects
        WHERE ObjectOrdinal = @ObjectOrdinal;

        SET @ObjectId = OBJECT_ID
        (
            QUOTENAME(N'toolbelt_string') + N'.' + QUOTENAME(@ObjectName)
        );
        SET @SourceHash = CONVERT
        (
              varchar(64)
            , HASHBYTES
              (
                  N'SHA2_256'
                , CONVERT(varbinary(max), OBJECT_DEFINITION(@ObjectId))
              )
            , 2
        );

        INSERT INTO @Properties
        (
              PropertyOrdinal
            , PropertyName
            , PropertyValue
        )
        VALUES
              (1, N'Toolbelt.ModuleId', N'toolbelt.string.split-characters')
            , (2, N'Toolbelt.ModuleVersion', @TargetVersion)
            , (3, N'Toolbelt.ContractVersion', N'1.0')
            , (4, N'Toolbelt.DeploymentMode', @DeploymentMode)
            , (5, N'Toolbelt.SourceHash', CONVERT(nvarchar(4000), @SourceHash));

        SET @PropertyOrdinal = 1;
        SET @PropertyCount = (SELECT COUNT(*) FROM @Properties);

        WHILE @PropertyOrdinal <= @PropertyCount
        BEGIN
            SELECT
                  @PropertyName = PropertyName
                , @PropertyValue = PropertyValue
            FROM @Properties
            WHERE PropertyOrdinal = @PropertyOrdinal;

            IF EXISTS
               (
                   SELECT 1
                   FROM sys.extended_properties AS ep
                   WHERE ep.class = 1
                     AND ep.major_id = @ObjectId
                     AND ep.minor_id = 0
                     AND ep.name = @PropertyName
               )
            BEGIN
                EXEC sys.sp_updateextendedproperty
                      @name       = @PropertyName
                    , @value      = @PropertyValue
                    , @level0type = N'SCHEMA'
                    , @level0name = N'toolbelt_string'
                    , @level1type = N'FUNCTION'
                    , @level1name = @ObjectName;
            END;
            ELSE
            BEGIN
                EXEC sys.sp_addextendedproperty
                      @name       = @PropertyName
                    , @value      = @PropertyValue
                    , @level0type = N'SCHEMA'
                    , @level0name = N'toolbelt_string'
                    , @level1type = N'FUNCTION'
                    , @level1name = @ObjectName;
            END;

            SET @PropertyOrdinal += 1;
        END;

        DELETE FROM @Properties;
        SET @ObjectOrdinal += 1;
    END;

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 0 AND name = @VersionPropertyName
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
           FROM sys.extended_properties
           WHERE class = 0 AND name = @ModePropertyName
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
