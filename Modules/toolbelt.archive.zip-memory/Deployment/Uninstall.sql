:On Error exit
-- RAISERROR statt THROW: Caller-Transaktionen bei XACT_ABORT ON nicht beschädigen.
IF @@TRANCOUNT<>0
BEGIN
    RAISERROR(N'TBX_ZIP_LIFECYCLE_CALLER_TRANSACTION: Uninstall benötigt einen eigenen Transaktionsscope.',16,1);
    RETURN;
END;
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
    , @ExtractPublicObjectId int =
          OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary')
    , @ListPublicObjectId int =
          OBJECT_ID(N'toolbelt_archive.USP_ListZipEntriesFromBinary')
    , @ExtractInternalObjectId int =
          OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr')
    , @ListInternalObjectId int =
          OBJECT_ID(N'toolbelt_archive.TVF_InternalListZipEntriesClr')
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

DECLARE @InstalledVersion nvarchar(64)=(SELECT TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty);
DECLARE @OwnWriter bit=CASE WHEN @InstalledVersion IN(N'1.3.0',N'1.4.0') THEN 1 ELSE 0 END;
DECLARE @WriterPublicId int=CASE WHEN @OwnWriter=1 THEN OBJECT_ID(N'toolbelt_archive.USP_CreateZipFromEntries') END,
 @WriterNameId int=CASE WHEN @OwnWriter=1 THEN OBJECT_ID(N'toolbelt_archive.TVF_InternalZipWriterName') END,
 @WriterArchiveId int=CASE WHEN @OwnWriter=1 THEN OBJECT_ID(N'toolbelt_archive.TVF_InternalZipWriterArchive') END;
IF @OwnWriter=1 AND EXISTS(SELECT 1 FROM sys.objects o WHERE o.object_id IN(@WriterPublicId,@WriterNameId,@WriterArchiveId)
 AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(128),e.value)=N'toolbelt.archive.zip-memory'))
 THROW 51338,N'Writerobjekt besitzt keine passende Modulzuordnung.',3;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id IN(@WriterPublicId,@WriterNameId,@WriterArchiveId)
 AND referencing_id NOT IN(ISNULL(@WriterPublicId,-1),ISNULL(@WriterNameId,-1),ISNULL(@WriterArchiveId,-1)))
 THROW 51338,N'Der ZIP-Writer wird durch eine same-database Dependency verwendet.',2;

IF EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies
       WHERE referenced_id IN
             (
                 ISNULL(@ExtractPublicObjectId, -1),
                 ISNULL(@ListPublicObjectId, -1),
                 ISNULL(@ExtractInternalObjectId, -1),
                 ISNULL(@ListInternalObjectId, -1)
             )
         AND referencing_id NOT IN
             (
                 ISNULL(@ExtractPublicObjectId, -1),
                 ISNULL(@ListPublicObjectId, -1),
                 ISNULL(@ExtractInternalObjectId, -1),
                 ISNULL(@ListInternalObjectId, -1)
             )
   )
    THROW 51338, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (
           SELECT 1
           FROM sys.assembly_modules
           WHERE assembly_id = @AssemblyId
             AND object_id NOT IN
                 (
                     ISNULL(@ExtractInternalObjectId, -1),
                     ISNULL(@ListInternalObjectId, -1),
                     ISNULL(@WriterNameId,-1), ISNULL(@WriterArchiveId,-1)
                 )
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
    IF @OwnWriter=1 BEGIN
      DROP PROCEDURE IF EXISTS [toolbelt_archive].[USP_CreateZipFromEntries];
      DROP FUNCTION IF EXISTS [toolbelt_archive].[TVF_InternalZipWriterName];
      DROP FUNCTION IF EXISTS [toolbelt_archive].[TVF_InternalZipWriterArchive];
    END;

    DROP PROCEDURE IF EXISTS
        [toolbelt_archive].[USP_ExtractZipEntryFromBinary];

    DROP PROCEDURE IF EXISTS
        [toolbelt_archive].[USP_ListZipEntriesFromBinary];

    DROP FUNCTION IF EXISTS
        [toolbelt_archive].[TVF_InternalExtractZipEntryClr];

    DROP FUNCTION IF EXISTS
        [toolbelt_archive].[TVF_InternalListZipEntriesClr];

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
