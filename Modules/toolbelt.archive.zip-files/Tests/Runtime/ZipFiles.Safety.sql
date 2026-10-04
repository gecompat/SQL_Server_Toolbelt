-- Kein Publish in diesen Fällen; bewusst ungültiger Root ist nur ein Reihenfolgeorakel.
SET NOCOUNT ON;
DECLARE @Seen bit=0;
BEGIN TRANSACTION;
BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>54621 OR ERROR_STATE()<>1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW;
    END;
    SET @Seen=1;
END CATCH;
IF @Seen<>1 OR @@TRANCOUNT<>1
BEGIN
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW 54690,N'ZIP_FILES_CALLER_TRANSACTION',1;
END;
ROLLBACK TRANSACTION;
CREATE TABLE #ZipFiles_WriteStage(Dummy int);
SET @Seen=0;
BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryToFile @RootAlias=N'ContosoZipFiles',@RelativePath=N'never.txt';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>54624 OR ERROR_STATE()<>1 THROW;
    SET @Seen=1;
END CATCH;
IF @Seen<>1 OR OBJECT_ID(N'tempdb..#ZipFiles_WriteStage',N'U') IS NULL
    THROW 54690,N'ZIP_FILES_COLLISION_PRESERVATION',1;
DROP TABLE #ZipFiles_WriteStage;
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'ok.txt',0x01);
-- Gleiches Input-/Outputobjekt muss vor Writer/Filesystem abgewiesen werden.
SET @Seen=0;
BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',@ResultTable=N'#Entries',@RootAlias=N'ContosoZipFiles',@RelativePath=N'never.zip';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>54620 OR ERROR_STATE()<>1 THROW;
    SET @Seen=1;
END CATCH;
IF @Seen<>1 OR (SELECT COUNT(*) FROM #Entries WHERE Ordinal=1 AND Payload=0x01)<>1
    THROW 54690,N'ZIP_FILES_SAME_INPUT_OUTPUT',1;
SET @Seen=0;
BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',@RootAlias=N'ContosoZipFiles',@RelativePath=N'never.zip',@MaxEntries=NULL;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51350 OR ERROR_STATE()<>1 THROW;
    SET @Seen=1;
END CATCH;
IF @Seen<>1 THROW 54690,N'ZIP_FILES_INHERITED_WRITER_LIMIT',1;
-- Manipulation ausschließlich des synthetisch installierten Dependencyzustands.
DECLARE @Prior1 sql_variant=(SELECT value FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.filesystem.windows.Version');
IF @Prior1 IS NULL THROW 54690,N'ZIP_FILES_DEPENDENCY_FIXTURE_PRESTATE',1;
BEGIN TRY
    EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.filesystem.windows.Version',@value=N'0.0.0';
    SET @Seen=0;
    BEGIN TRY
        EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',@RootAlias=N'ContosoZipFiles',@RelativePath=N'never.zip';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>54622 OR ERROR_STATE()<>1 THROW;
        SET @Seen=1;
    END CATCH;
    IF @Seen<>1 THROW 54690,N'ZIP_FILES_DEPENDENCY_REJECTION',1;
    EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.filesystem.windows.Version',@value=@Prior1;
END TRY
BEGIN CATCH
    EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.filesystem.windows.Version',@value=@Prior1;
    THROW;
END CATCH;
-- Manipulation ausschließlich des synthetisch installierten Dependencyzustands.
DECLARE @Prior2 sql_variant=(SELECT value FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_archive.USP_CreateZipFromEntries') AND minor_id=0 AND name=N'Toolbelt.ModuleVersion');
IF @Prior2 IS NULL THROW 54690,N'ZIP_FILES_DEPENDENCY_FIXTURE_PRESTATE',1;
BEGIN TRY
    EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'0.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_archive',@level1type=N'PROCEDURE',@level1name=N'USP_CreateZipFromEntries';
    SET @Seen=0;
    BEGIN TRY
        EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',@RootAlias=N'ContosoZipFiles',@RelativePath=N'never.zip';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>54622 OR ERROR_STATE()<>1 THROW;
        SET @Seen=1;
    END CATCH;
    IF @Seen<>1 THROW 54690,N'ZIP_FILES_DEPENDENCY_REJECTION',1;
    EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Prior2,@level0type=N'SCHEMA',@level0name=N'toolbelt_archive',@level1type=N'PROCEDURE',@level1name=N'USP_CreateZipFromEntries';
END TRY
BEGIN CATCH
    EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=@Prior2,@level0type=N'SCHEMA',@level0name=N'toolbelt_archive',@level1type=N'PROCEDURE',@level1name=N'USP_CreateZipFromEntries';
    THROW;
END CATCH;
DROP TABLE #Entries;
PRINT N'PASS ZIP_FILES_SAFETY';
GO
