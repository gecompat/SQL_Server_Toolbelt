:On Error exit

-- ============================================================================
-- Zweck:     Kontrollierte Deinstallation von toolbelt.metadata.table-clone
-- Modus:     SQLCMD
-- Parameter: ConfirmNoExternalConsumers=0|1
-- ============================================================================

-- RAISERROR statt THROW: geerbtes XACT_ABORT ON darf Caller-Tx nicht doomen.
IF @@TRANCOUNT>0
BEGIN
    RAISERROR(N'TBX_TABLE_CLONE_CALLER_TRANSACTION: Lifecycle erfordert keine aktive Caller-Transaktion.',16,1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
   OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
    THROW 53926,N'TableClone: vollständige Lifecycle-Dependency-Metadatensicht fehlt.',2;


DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionPropertyName sysname =
          N'Toolbelt.Module.toolbelt.metadata.table-clone.Version'
    , @ModePropertyName sysname =
          N'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode'
    , @InstalledVersion nvarchar(max)
    , @DeploymentMode nvarchar(max)
    , @ReferencingSchema sysname
    , @ReferencingObject sysname;

IF @ConfirmNoExternalConsumers IS NULL
BEGIN
    THROW 53925, N'Die SQLCMD-Variable ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
END;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(max), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = @VersionPropertyName;

SELECT @DeploymentMode = TRY_CONVERT(nvarchar(max), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0
  AND ep.major_id = 0
  AND ep.minor_id = 0
  AND ep.name = @ModePropertyName;

IF @InstalledVersion IS NULL
BEGIN
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name IN(@VersionPropertyName,@ModePropertyName))
       OR OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone') IS NOT NULL OR OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal') IS NOT NULL
        THROW 53923,N'TableClone: fremder oder inkohärenter Releasebestand.',1;
    PRINT N'toolbelt.metadata.table-clone ist nicht als installiert registriert; keine Änderung erforderlich.';
    RETURN;
END;

IF CONVERT(varbinary(max),@InstalledVersion) NOT IN(CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'2.0.0'))
BEGIN
    THROW 53923, N'Die installierte Modulversion ist diesem Uninstall-Skript nicht bekannt.', 1;
END;

IF @DeploymentMode IS NULL OR CONVERT(varbinary(max),@DeploymentMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
BEGIN
    THROW 53923, N'Der registrierte Deployment-Modus fehlt oder ist ungültig.', 1;
END;

IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
BEGIN
    THROW 53925, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 als ausdrückliche Betreiberbestätigung erforderlich.', 1;
END;

    IF EXISTS(SELECT 1 FROM (VALUES(N'USP_ScriptTableClone'),(N'USP_ScriptTableCloneInternal')) r(Name)
       LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_metadata') AND o.name=r.Name COLLATE DATABASE_DEFAULT
       WHERE o.object_id IS NULL OR o.type<>'P' OR NOT EXISTS(SELECT 1 FROM sys.extended_properties modeep WHERE modeep.class=1 AND modeep.major_id=o.object_id AND modeep.minor_id=0 AND modeep.name=N'Toolbelt.DeploymentMode'
          AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),modeep.value))=CONVERT(varbinary(max),(SELECT TRY_CONVERT(nvarchar(max),dbmode.value) FROM sys.extended_properties dbmode WHERE dbmode.class=0 AND dbmode.major_id=0 AND dbmode.minor_id=0 AND dbmode.name=N'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode'))) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
         AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.metadata.table-clone'))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
         AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),@InstalledVersion)))
        THROW 53923,N'TableClone: Releaseobjektmarker nicht kohärent.',1;
SELECT TOP (1)
      @ReferencingSchema = OBJECT_SCHEMA_NAME(dependencies.referencing_id)
    , @ReferencingObject = OBJECT_NAME(dependencies.referencing_id)
FROM sys.sql_expression_dependencies AS dependencies
WHERE dependencies.referenced_id IN
      (
          OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone'),
          OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal')
      )
  AND NOT EXISTS
      (SELECT 1 FROM sys.objects owned JOIN sys.schemas s ON owned.schema_id=s.schema_id
       WHERE owned.object_id=dependencies.referencing_id AND s.name=N'toolbelt_metadata'
       AND owned.name IN(N'USP_ScriptTableClone',N'USP_ScriptTableCloneInternal'))
ORDER BY
      OBJECT_SCHEMA_NAME(dependencies.referencing_id)
          COLLATE Latin1_General_100_BIN2
    , OBJECT_NAME(dependencies.referencing_id)
          COLLATE Latin1_General_100_BIN2;

IF @ReferencingObject IS NOT NULL
BEGIN
    DECLARE @DependencyMessage nvarchar(2048) =
        N'Die Deinstallation wird durch same-database Dependency '
        + COALESCE(QUOTENAME(@ReferencingSchema), N'<ohne Schema>')
        + N'.'
        + COALESCE(QUOTENAME(@ReferencingObject), N'<unbekannt>')
        + N' blockiert.';
    SET @DependencyMessage = REPLACE(@DependencyMessage, N'%', N'%%');
    THROW 53926, @DependencyMessage, 1;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @LockResult int;

    EXEC @LockResult = sys.sp_getapplock
          @Resource    = N'toolbelt.deploy.toolbelt.metadata.table-clone'
        , @LockMode    = N'Exclusive'
        , @LockOwner   = N'Transaction'
        , @LockTimeout = 0
        , @DbPrincipal = N'public';

    IF COALESCE(@LockResult,-999) < 0
    BEGIN
        THROW 53927, N'Ein paralleles Deployment von toolbelt.metadata.table-clone ist bereits aktiv.', 1;
    END;

    IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
       OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
        THROW 53926,N'TableClone: vollständige Lifecycle-Dependency-Metadatensicht fehlt.',2;


    DECLARE @CurrentInstalledVersion nvarchar(max);

    SELECT @CurrentInstalledVersion = TRY_CONVERT(nvarchar(max), ep.value)
    FROM sys.extended_properties AS ep
    WHERE ep.class = 0
      AND ep.major_id = 0
      AND ep.minor_id = 0
      AND ep.name = @VersionPropertyName;

    IF (@CurrentInstalledVersion IS NULL AND @InstalledVersion IS NOT NULL) OR (@CurrentInstalledVersion IS NOT NULL AND @InstalledVersion IS NULL)
       OR CONVERT(varbinary(max),@CurrentInstalledVersion)<>CONVERT(varbinary(max),@InstalledVersion)
    BEGIN
        THROW 53927, N'Der installierte Modulstand hat sich seit dem Uninstall-Preflight verändert.', 1;
    END;

    IF EXISTS(SELECT 1 FROM (VALUES(N'USP_ScriptTableClone'),(N'USP_ScriptTableCloneInternal')) r(Name)
       LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_metadata') AND o.name=r.Name COLLATE DATABASE_DEFAULT
       WHERE o.object_id IS NULL OR o.type<>'P' OR NOT EXISTS(SELECT 1 FROM sys.extended_properties modeep WHERE modeep.class=1 AND modeep.major_id=o.object_id AND modeep.minor_id=0 AND modeep.name=N'Toolbelt.DeploymentMode'
          AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),modeep.value))=CONVERT(varbinary(max),(SELECT TRY_CONVERT(nvarchar(max),dbmode.value) FROM sys.extended_properties dbmode WHERE dbmode.class=0 AND dbmode.major_id=0 AND dbmode.minor_id=0 AND dbmode.name=N'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode'))) OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
         AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.metadata.table-clone'))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
         AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),@InstalledVersion)))
        THROW 53923,N'TableClone: Releaseobjektmarker nicht kohärent.',1;    IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModePropertyName
       AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@DeploymentMode))
        THROW 53927,N'TableClone: Modemarker seit Preflight verändert.',1;
    IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE d.referenced_id IN(OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone'),OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal'))
       AND NOT EXISTS(SELECT 1 FROM (VALUES(OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone')),(OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal'))) own(Id) WHERE own.Id=d.referencing_id))
        THROW 53926,N'TableClone: fremde same-database Dependency.',1;

    DECLARE @ReleaseObjects TABLE
    (
          ObjectOrdinal int IDENTITY(1, 1) NOT NULL
        , ObjectName    sysname            NOT NULL
    );

    INSERT INTO @ReleaseObjects (ObjectName)
    VALUES(N'USP_ScriptTableClone'),(N'USP_ScriptTableCloneInternal');

    DECLARE
          @ObjectOrdinal int = 1
        , @ObjectCount   int = (SELECT COUNT(*) FROM @ReleaseObjects)
        , @ObjectName    sysname
        , @ObjectId      int
        , @ObjectType    char(2)
        , @DropSql       nvarchar(max);

    WHILE @ObjectOrdinal <= @ObjectCount
    BEGIN
        SELECT @ObjectName = ObjectName
        FROM @ReleaseObjects
        WHERE ObjectOrdinal = @ObjectOrdinal;

        SET @ObjectId = OBJECT_ID
        (
            QUOTENAME(N'toolbelt_metadata') + N'.' + QUOTENAME(@ObjectName)
        );

        IF @ObjectId IS NOT NULL
        BEGIN
            SELECT @ObjectType = type
            FROM sys.objects
            WHERE object_id = @ObjectId;

            SET @DropSql =
                CASE
                    WHEN @ObjectType IN ('P', 'PC') THEN N'DROP PROCEDURE '
                    WHEN @ObjectType = 'V' THEN N'DROP VIEW '
                    WHEN @ObjectType IN ('FN', 'FS', 'FT', 'IF', 'TF')
                        THEN N'DROP FUNCTION '
                    ELSE NULL
                END
                + QUOTENAME(N'toolbelt_metadata')
                + N'.'
                + QUOTENAME(@ObjectName)
                + N';';

            IF @DropSql IS NULL
            BEGIN
                THROW 53923, N'Ein Release-Objekt besitzt einen nicht unterstützten lokal veränderten Objekttyp.', 1;
            END;

            EXEC sys.sp_executesql @DropSql;
        END;

        SET @ObjectOrdinal += 1;
    END;

    EXEC sys.sp_dropextendedproperty @name = @VersionPropertyName;
    EXEC sys.sp_dropextendedproperty @name = @ModePropertyName;

    DECLARE
          @SchemaId int = SCHEMA_ID(N'toolbelt_metadata')
        , @SchemaManaged int
        , @SchemaCategory nvarchar(128);

    IF @SchemaId IS NOT NULL
    BEGIN
        SELECT
              @SchemaManaged = MAX
              (
                  CASE WHEN ep.name = N'Toolbelt.Managed'
                      THEN TRY_CONVERT(int, ep.value) END
              )
            , @SchemaCategory = MAX
              (
                  CASE WHEN ep.name = N'Toolbelt.SchemaCategory'
                      THEN TRY_CONVERT(nvarchar(128), ep.value) END
              )
        FROM sys.extended_properties AS ep
        WHERE ep.class = 3
          AND ep.major_id = @SchemaId
          AND ep.minor_id = 0;

        IF ISNULL(@SchemaManaged, 0) = 1
           AND CONVERT(varbinary(max),@SchemaCategory)=CONVERT(varbinary(max),N'metadata')
           AND NOT EXISTS
               (
                   SELECT 1 FROM sys.objects WHERE schema_id = @SchemaId
               )
           AND NOT EXISTS
               (
                   SELECT 1
                   FROM sys.types
                   WHERE schema_id = @SchemaId AND is_user_defined = 1
               )
           AND NOT EXISTS
               (
                   SELECT 1
                   FROM sys.xml_schema_collections
                   WHERE schema_id = @SchemaId AND xml_collection_id > 0
               )
        BEGIN
            DROP SCHEMA [toolbelt_metadata];
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
