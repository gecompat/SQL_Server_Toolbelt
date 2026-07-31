:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.archive.zip-memory.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.archive.zip-memory.DeploymentMode'
    , @DeploymentMode nvarchar(16)
    , @PublicObjectId int =
          OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary')
    , @InternalObjectId int =
          OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr')
    , @AssemblyId int =
          (
              SELECT assembly_id
              FROM sys.assemblies
              WHERE name = N'Toolbelt_Archive_ZipMemory'
          );

IF @ConfirmNoExternalConsumers IS NULL
    THROW 51336, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name = @VersionProperty
   )
    RETURN;

SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), value)
FROM sys.extended_properties
WHERE class = 0
  AND major_id = 0
  AND minor_id = 0
  AND name = @ModeProperty;

IF @DeploymentMode = N'central'
   AND @ConfirmNoExternalConsumers <> 1
    THROW 51336, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies
       WHERE referenced_id IN (@PublicObjectId, @InternalObjectId)
         AND referencing_id NOT IN (@PublicObjectId, @InternalObjectId)
   )
    THROW 51338, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (
           SELECT 1
           FROM sys.assembly_modules
           WHERE assembly_id = @AssemblyId
             AND object_id <> ISNULL(@InternalObjectId, -1)
       )
    THROW 51338, N'Die CLR-ZIP-Assembly wird von einem fremden SQL-Objekt verwendet.', 1;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (
           SELECT 1
           FROM sys.assembly_references
           WHERE referenced_assembly_id = @AssemblyId
       )
    THROW 51338, N'Die CLR-ZIP-Assembly wird von einer anderen Assembly referenziert.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP PROCEDURE IF EXISTS
        [toolbelt_archive].[USP_ExtractZipEntryFromBinary];

    DROP FUNCTION IF EXISTS
        [toolbelt_archive].[TVF_InternalExtractZipEntryClr];

    IF EXISTS
       (
           SELECT 1
           FROM sys.assemblies
           WHERE name = N'Toolbelt_Archive_ZipMemory'
       )
        DROP ASSEMBLY [Toolbelt_Archive_ZipMemory];

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 0
             AND major_id = 0
             AND minor_id = 0
             AND name = @VersionProperty
       )
        EXEC sys.sp_dropextendedproperty
              @name = @VersionProperty;

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 0
             AND major_id = 0
             AND minor_id = 0
             AND name = @ModeProperty
       )
        EXEC sys.sp_dropextendedproperty
              @name = @ModeProperty;

    IF SCHEMA_ID(N'toolbelt_archive') IS NOT NULL
       AND NOT EXISTS
           (
               SELECT 1
               FROM sys.objects
               WHERE schema_id = SCHEMA_ID(N'toolbelt_archive')
           )
       AND EXISTS
           (
               SELECT 1
               FROM sys.extended_properties
               WHERE class = 3
                 AND major_id = SCHEMA_ID(N'toolbelt_archive')
                 AND name = N'Toolbelt.Managed'
                 AND TRY_CONVERT(bit, value) = 1
           )
        DROP SCHEMA [toolbelt_archive];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
 * Der serverweite SHA2-512-Trust-Eintrag bleibt absichtlich bestehen. Seine
 * Entfernung ist ein separater administrativer Vorgang, weil derselbe Hash
 * außerhalb dieser Datenbank verwendet werden kann.
 */
