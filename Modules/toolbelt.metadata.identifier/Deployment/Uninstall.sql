:On Error exit

-- ============================================================================
-- Zweck:     Kontrollierte Deinstallation von toolbelt.metadata.identifier
-- Modus:     SQLCMD
-- Parameter: ConfirmNoExternalConsumers=0|1
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionPropertyName sysname =
          N'Toolbelt.Module.toolbelt.metadata.identifier.Version'
    , @ModePropertyName sysname =
          N'Toolbelt.Module.toolbelt.metadata.identifier.DeploymentMode'
    , @InstalledVersion nvarchar(64)
    , @DeploymentMode nvarchar(16)
    , @ReferencingSchema sysname
    , @ReferencingObject sysname;

IF @ConfirmNoExternalConsumers IS NULL
BEGIN
    THROW 51065, N'Die SQLCMD-Variable ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
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
    PRINT N'toolbelt.metadata.identifier ist nicht als installiert registriert; keine Änderung erforderlich.';
    RETURN;
END;

IF @InstalledVersion COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
BEGIN
    THROW 51063, N'Die installierte Modulversion ist diesem Uninstall-Skript nicht bekannt.', 1;
END;

IF @DeploymentMode NOT IN (N'local', N'central')
BEGIN
    THROW 51063, N'Der registrierte Deployment-Modus fehlt oder ist ungültig.', 1;
END;

IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
BEGIN
    THROW 51065, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 als ausdrückliche Betreiberbestätigung erforderlich.', 1;
END;

SELECT TOP (1)
      @ReferencingSchema = OBJECT_SCHEMA_NAME(dependencies.referencing_id)
    , @ReferencingObject = OBJECT_NAME(dependencies.referencing_id)
FROM sys.sql_expression_dependencies AS dependencies
WHERE dependencies.referenced_id IN
      (
          OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName')
        , OBJECT_ID(N'toolbelt_metadata.SVF_QuoteMultipartName')
      )
  AND dependencies.referencing_id NOT IN
      (
          OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName')
        , OBJECT_ID(N'toolbelt_metadata.SVF_QuoteMultipartName')
      )
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
    THROW 51066, @DependencyMessage, 1;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @LockResult int;

    EXEC @LockResult = sys.sp_getapplock
          @Resource    = N'toolbelt.deploy.toolbelt.metadata.identifier'
        , @LockMode    = N'Exclusive'
        , @LockOwner   = N'Transaction'
        , @LockTimeout = 0
        , @DbPrincipal = N'public';

    IF @LockResult < 0
    BEGIN
        THROW 51067, N'Ein paralleles Deployment von toolbelt.metadata.identifier ist bereits aktiv.', 1;
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
        THROW 51067, N'Der installierte Modulstand hat sich seit dem Uninstall-Preflight verändert.', 1;
    END;

    DECLARE @ReleaseObjects TABLE
    (
          ObjectOrdinal int IDENTITY(1, 1) NOT NULL
        , ObjectName    sysname            NOT NULL
    );

    INSERT INTO @ReleaseObjects (ObjectName)
    /*
     * Die Scalar Function hängt vom Parser ab und wird deshalb zuerst
     * entfernt.
     */
    VALUES (N'SVF_QuoteMultipartName'), (N'TVF_ParseMultipartName');

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
                THROW 51063, N'Ein Release-Objekt besitzt einen nicht unterstützten lokal veränderten Objekttyp.', 1;
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
           AND ISNULL(@SchemaCategory, N'')
                   COLLATE Latin1_General_100_BIN2 = N'core'
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
