:On Error exit

-- ============================================================================
-- Zweck:     Erst- und Wiederholungsdeployment
-- Modul:     toolbelt.datetime.date-spine v1.0.0
-- Schema:    toolbelt_datetime
-- Erfordert: SQL Server 2019, 2022 oder 2025; Generate Series 1.0.0;
--            Datetime Truncate 1.0.0
-- Modus:     SQLCMD; Ausführung aus diesem Deployment-Verzeichnis
-- Parameter: DeploymentMode=local|central
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID(N'tempdb..#tbx_DateSpineReleaseObjects', N'U') IS NOT NULL
    DROP TABLE #tbx_DateSpineReleaseObjects;
IF OBJECT_ID(N'tempdb..#tbx_DateSpineDeployState', N'U') IS NOT NULL
    DROP TABLE #tbx_DateSpineDeployState;

CREATE TABLE #tbx_DateSpineReleaseObjects
(
      ReleaseVersion nvarchar(64) NOT NULL
    , SchemaName     sysname      NOT NULL
    , ObjectName     sysname      NOT NULL
    , ObjectType     char(2)      NOT NULL
    , CONSTRAINT PK_tbx_DateSpineReleaseObjects
          PRIMARY KEY (ReleaseVersion, SchemaName, ObjectName)
);

INSERT INTO #tbx_DateSpineReleaseObjects
    (ReleaseVersion, SchemaName, ObjectName, ObjectType)
VALUES
      (N'1.0.0', N'toolbelt_datetime', N'TVF_DateSpineCore', 'IF')
    , (N'1.0.0', N'toolbelt_datetime', N'TVF_DateSpineDay', 'IF')
    , (N'1.0.0', N'toolbelt_datetime', N'TVF_DateSpineIsoWeek', 'IF')
    , (N'1.0.0', N'toolbelt_datetime', N'TVF_DateSpineMonth', 'IF');

CREATE TABLE #tbx_DateSpineDeployState
(
      TargetVersion    nvarchar(64) NOT NULL
    , InstalledVersion nvarchar(64) NULL
    , DeploymentMode   nvarchar(16) NOT NULL
);

DECLARE
      @TargetVersion          nvarchar(64) = N'1.0.0'
    , @DeploymentMode         nvarchar(16) = LOWER(N'$(DeploymentMode)')
    , @InstalledVersion       nvarchar(64)
    , @GenerateSeriesVersion  nvarchar(64)
    , @TruncateVersion        nvarchar(64)
    , @VersionPropertyName    sysname =
          N'Toolbelt.Module.toolbelt.datetime.date-spine.Version'
    , @ProductMajorVersion    int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @CollisionSchema        sysname
    , @CollisionObject        sysname
    , @LockResult             int
    , @DropSql                nvarchar(max);

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 51800, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51801, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;

SELECT @GenerateSeriesVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0 AND ep.major_id = 0 AND ep.minor_id = 0
  AND ep.name = N'Toolbelt.Module.toolbelt.core.generate-series.Version';

SELECT @TruncateVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0 AND ep.major_id = 0 AND ep.minor_id = 0
  AND ep.name = N'Toolbelt.Module.toolbelt.datetime.truncate.Version';

IF ISNULL(@GenerateSeriesVersion, N'') COLLATE Latin1_General_100_BIN2
       <> N'1.0.0'
   OR OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesInt', N'IF') IS NULL
   OR ISNULL(@TruncateVersion, N'') COLLATE Latin1_General_100_BIN2
       <> N'1.0.0'
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDate', N'IF') IS NULL
BEGIN
    THROW 51809, N'toolbelt.core.generate-series 1.0.0 und toolbelt.datetime.truncate 1.0.0 müssen vor diesem Modul in derselben Datenbank installiert sein.', 1;
END;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0 AND ep.major_id = 0 AND ep.minor_id = 0
  AND ep.name = @VersionPropertyName;

IF @InstalledVersion IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM #tbx_DateSpineReleaseObjects AS release_objects
           WHERE release_objects.ReleaseVersion COLLATE Latin1_General_100_BIN2
                 = @InstalledVersion COLLATE Latin1_General_100_BIN2
       )
    THROW 51803, N'Die installierte Modulversion ist diesem Deployment nicht als unterstütztes Vorgängerrelease bekannt.', 1;

IF SCHEMA_ID(N'toolbelt_datetime') IS NULL
   AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    THROW 51802, N'In der Installationsdatenbank fehlt CREATE SCHEMA.', 1;
IF SCHEMA_ID(N'toolbelt_datetime') IS NOT NULL
   AND HAS_PERMS_BY_NAME(N'toolbelt_datetime', N'SCHEMA', N'ALTER') <> 1
    THROW 51802, N'Für toolbelt_datetime fehlt ALTER.', 1;
IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE FUNCTION') <> 1
    THROW 51802, N'In der Installationsdatenbank fehlt CREATE FUNCTION.', 1;

SELECT TOP (1)
      @CollisionSchema = target.SchemaName
    , @CollisionObject = target.ObjectName
FROM #tbx_DateSpineReleaseObjects AS target
JOIN sys.schemas AS schemas
  ON schemas.name COLLATE Latin1_General_100_BIN2
     = target.SchemaName COLLATE Latin1_General_100_BIN2
JOIN sys.objects AS objects
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
             FROM #tbx_DateSpineReleaseObjects AS previous
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
        N'Das neue Framework-Objekt ' + QUOTENAME(@CollisionSchema) + N'.'
        + QUOTENAME(@CollisionObject)
        + N' ist bereits vorhanden, stammt aber nicht aus einem bekannten Release.';
    THROW 51804, @CollisionMessage, 1;
END;

INSERT INTO #tbx_DateSpineDeployState
    (TargetVersion, InstalledVersion, DeploymentMode)
VALUES (@TargetVersion, @InstalledVersion, @DeploymentMode);

BEGIN TRY
    BEGIN TRANSACTION;

    EXEC @LockResult = sys.sp_getapplock
          @Resource = N'toolbelt.deploy.toolbelt.datetime.date-spine'
        , @LockMode = N'Exclusive'
        , @LockOwner = N'Transaction'
        , @LockTimeout = 0
        , @DbPrincipal = N'public';
    IF @LockResult < 0
        THROW 51807, N'Ein paralleles Deployment von toolbelt.datetime.date-spine ist bereits aktiv.', 1;

    DECLARE @CurrentInstalledVersion nvarchar(64);
    SELECT @CurrentInstalledVersion = TRY_CONVERT(nvarchar(64), ep.value)
    FROM sys.extended_properties AS ep
    WHERE ep.class = 0 AND ep.major_id = 0 AND ep.minor_id = 0
      AND ep.name = @VersionPropertyName;

    IF ISNULL(@CurrentInstalledVersion, N'') COLLATE Latin1_General_100_BIN2
       <> ISNULL(@InstalledVersion, N'') COLLATE Latin1_General_100_BIN2
        THROW 51807, N'Der installierte Modulstand hat sich seit dem Preflight verändert.', 1;

    IF SCHEMA_ID(N'toolbelt_datetime') IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_datetime];';
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_datetime';
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.SchemaCategory', @value = N'datetime'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_datetime';
    END;

    /*
     * Ein Objekt mit falschem Typ darf nur ersetzt werden, wenn der Name im
     * bekannten installierten Release enthalten war.
     */
    SELECT @DropSql = STUFF
    (
        (
            SELECT NCHAR(10)
                 + CASE
                       WHEN objects.type IN ('P', 'PC') THEN N'DROP PROCEDURE '
                       WHEN objects.type = 'V' THEN N'DROP VIEW '
                       WHEN objects.type IN ('FN', 'FS', 'FT', 'IF', 'TF')
                           THEN N'DROP FUNCTION '
                       ELSE N''
                   END
                 + QUOTENAME(schemas.name) + N'.' + QUOTENAME(objects.name) + N';'
            FROM #tbx_DateSpineReleaseObjects AS target
            JOIN #tbx_DateSpineReleaseObjects AS previous
              ON previous.ReleaseVersion COLLATE Latin1_General_100_BIN2
                 = @InstalledVersion COLLATE Latin1_General_100_BIN2
             AND previous.SchemaName COLLATE Latin1_General_100_BIN2
                 = target.SchemaName COLLATE Latin1_General_100_BIN2
             AND previous.ObjectName COLLATE Latin1_General_100_BIN2
                 = target.ObjectName COLLATE Latin1_General_100_BIN2
            JOIN sys.schemas AS schemas
              ON schemas.name COLLATE Latin1_General_100_BIN2
                 = target.SchemaName COLLATE Latin1_General_100_BIN2
            JOIN sys.objects AS objects
              ON objects.schema_id = schemas.schema_id
             AND objects.name COLLATE Latin1_General_100_BIN2
                 = target.ObjectName COLLATE Latin1_General_100_BIN2
            WHERE target.ReleaseVersion = @TargetVersion
              AND objects.type COLLATE Latin1_General_100_BIN2
                  <> target.ObjectType COLLATE Latin1_General_100_BIN2
              AND objects.type IN ('P', 'PC', 'V', 'FN', 'FS', 'FT', 'IF', 'TF')
            ORDER BY objects.name COLLATE Latin1_General_100_BIN2
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 1, N''
    );
    IF NULLIF(@DropSql, N'') IS NOT NULL
        EXEC sys.sp_executesql @DropSql;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/TVF_DateSpineCore.sql
:r ../Source/TVF_DateSpineDay.sql
:r ../Source/TVF_DateSpineIsoWeek.sql
:r ../Source/TVF_DateSpineMonth.sql

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    DECLARE
          @DeploymentMode      nvarchar(16)
        , @TargetVersion       nvarchar(64)
        , @VersionPropertyName sysname =
              N'Toolbelt.Module.toolbelt.datetime.date-spine.Version'
        , @ModePropertyName    sysname =
              N'Toolbelt.Module.toolbelt.datetime.date-spine.DeploymentMode';

    SELECT
          @DeploymentMode = DeploymentMode
        , @TargetVersion = TargetVersion
    FROM #tbx_DateSpineDeployState;

    IF XACT_STATE() <> 1
       OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineCore', N'IF') IS NULL
       OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineDay', N'IF') IS NULL
       OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineIsoWeek', N'IF') IS NULL
       OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineMonth', N'IF') IS NULL
        THROW 51808, N'Die Date-Spine-Funktionen wurden nicht vollständig innerhalb der Deployment-Transaktion angelegt.', 1;

    DECLARE @Objects TABLE
    (
          ObjectOrdinal int IDENTITY(1, 1) NOT NULL
        , ObjectName sysname NOT NULL
    );
    INSERT INTO @Objects (ObjectName)
    VALUES
          (N'TVF_DateSpineCore')
        , (N'TVF_DateSpineDay')
        , (N'TVF_DateSpineIsoWeek')
        , (N'TVF_DateSpineMonth');

    DECLARE
          @ObjectOrdinal int = 1
        , @ObjectCount int = (SELECT COUNT(*) FROM @Objects)
        , @ObjectName sysname
        , @ObjectId int
        , @SourceHash varchar(64)
        , @PropertyOrdinal int
        , @PropertyName sysname
        , @PropertyValue nvarchar(4000);

    DECLARE @Properties TABLE
    (
          PropertyOrdinal int NOT NULL PRIMARY KEY
        , PropertyName sysname NOT NULL
        , PropertyValue nvarchar(4000) NOT NULL
    );

    WHILE @ObjectOrdinal <= @ObjectCount
    BEGIN
        SELECT @ObjectName = ObjectName
        FROM @Objects WHERE ObjectOrdinal = @ObjectOrdinal;
        SET @ObjectId = OBJECT_ID
            (QUOTENAME(N'toolbelt_datetime') + N'.' + QUOTENAME(@ObjectName));
        SET @SourceHash = CONVERT
        (
            varchar(64),
            HASHBYTES(N'SHA2_256', CONVERT(varbinary(max), OBJECT_DEFINITION(@ObjectId))),
            2
        );

        INSERT INTO @Properties VALUES
              (1, N'Toolbelt.ModuleId', N'toolbelt.datetime.date-spine')
            , (2, N'Toolbelt.ModuleVersion', @TargetVersion)
            , (3, N'Toolbelt.ContractVersion', N'1.0')
            , (4, N'Toolbelt.DeploymentMode', @DeploymentMode)
            , (5, N'Toolbelt.SourceHash', CONVERT(nvarchar(4000), @SourceHash));

        SET @PropertyOrdinal = 1;
        WHILE @PropertyOrdinal <= 5
        BEGIN
            SELECT @PropertyName = PropertyName, @PropertyValue = PropertyValue
            FROM @Properties WHERE PropertyOrdinal = @PropertyOrdinal;
            IF EXISTS
               (
                   SELECT 1 FROM sys.extended_properties
                   WHERE class = 1 AND major_id = @ObjectId AND minor_id = 0
                     AND name = @PropertyName
               )
                EXEC sys.sp_updateextendedproperty
                      @name = @PropertyName, @value = @PropertyValue
                    , @level0type = N'SCHEMA', @level0name = N'toolbelt_datetime'
                    , @level1type = N'FUNCTION', @level1name = @ObjectName;
            ELSE
                EXEC sys.sp_addextendedproperty
                      @name = @PropertyName, @value = @PropertyValue
                    , @level0type = N'SCHEMA', @level0name = N'toolbelt_datetime'
                    , @level1type = N'FUNCTION', @level1name = @ObjectName;
            SET @PropertyOrdinal += 1;
        END;
        DELETE FROM @Properties;
        SET @ObjectOrdinal += 1;
    END;

    IF EXISTS
       (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionPropertyName)
        EXEC sys.sp_updateextendedproperty @name = @VersionPropertyName, @value = @TargetVersion;
    ELSE
        EXEC sys.sp_addextendedproperty @name = @VersionPropertyName, @value = @TargetVersion;

    IF EXISTS
       (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModePropertyName)
        EXEC sys.sp_updateextendedproperty @name = @ModePropertyName, @value = @DeploymentMode;
    ELSE
        EXEC sys.sp_addextendedproperty @name = @ModePropertyName, @value = @DeploymentMode;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
