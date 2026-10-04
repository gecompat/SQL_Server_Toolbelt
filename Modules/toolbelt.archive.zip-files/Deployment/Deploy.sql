:On Error exit
-- SQLCMD-Lifecycle; keine Provider-, Assembly-, Root-, Trust- oder Rechteänderung.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0
BEGIN
    RAISERROR(N'TBX_ZIP_FILE_LIFECYCLE_CALLER_TRANSACTION: Keine aktive Callertransaktion zulässig.',16,1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
DECLARE @Slots TABLE(Name sysname NOT NULL PRIMARY KEY);
INSERT @Slots VALUES(N'USP_CreateZipFileFromEntries'),(N'USP_ExtractZipEntryToFile');
DECLARE @Pass int=1,@LockResult int,@Present int,@Version nvarchar(128),@Mode nvarchar(128);
DECLARE @RequestedMode nvarchar(max)=N'$(DeploymentMode)';
IF CONVERT(varbinary(max),@RequestedMode)<>CONVERT(varbinary(max),N'local')
    THROW 54631,N'TBX_ZIP_FILE_LIFECYCLE_ARGUMENT: Nur local ist zulässig.',1;
IF OBJECT_ID(N'tempdb..#tbx_ZipFiles_Deploy',N'U') IS NOT NULL
    THROW 54634,N'TBX_ZIP_FILE_LIFECYCLE_COLLISION: Lifecycle-Tempname belegt.',1;
    -- Keine zusätzliche DB-weite Metadatensicht für normale Aufrufer.
        DECLARE @Dependencies TABLE(ModuleId nvarchar(128),SchemaName sysname,ObjectName sysname,MinimumMajor int,MinimumMinor int,MinimumPatch int);
    INSERT @Dependencies VALUES
      (N'toolbelt.archive.zip-memory',N'toolbelt_archive',N'USP_CreateZipFromEntries',1,4,0),
      (N'toolbelt.archive.zip-memory',N'toolbelt_archive',N'USP_ExtractZipEntryFromBinary',1,4,0),
      (N'toolbelt.filesystem.windows',N'toolbelt_filesystem',N'USP_WriteBinaryFile',1,0,0),
      (N'toolbelt.core.result-table',N'toolbelt_core',N'USP_PrepareResultTable',1,0,0);
BEGIN TRY
    WHILE @Pass<=2
    BEGIN
        IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
           OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
            THROW 54632,N'TBX_ZIP_FILE_LIFECYCLE_VISIBILITY: Vollständige Lifecycle-Metadatensicht fehlt.',1;
        IF TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN(15,16,17)
           OR NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE CONVERT(varbinary(max),host_platform)=CONVERT(varbinary(max),N'Windows'))
            THROW 54631,N'TBX_ZIP_FILE_LIFECYCLE_ARGUMENT: Windows SQL Server 2019/2022/2025 erforderlich.',1;
        IF SCHEMA_ID(N'toolbelt_archive') IS NULL
            THROW 54633,N'TBX_ZIP_FILE_DEPENDENCY: Archivschema fehlt; keine fremde Schemaadoption.',1;
    IF EXISTS
    (
        SELECT 1 FROM @Dependencies d
        LEFT JOIN sys.extended_properties v ON v.class=0 AND v.major_id=0 AND v.minor_id=0
            AND v.name=N'Toolbelt.Module.'+d.ModuleId+N'.Version'
        CROSS APPLY (SELECT TRY_CONVERT(nvarchar(128),v.value) AS Version) t
        CROSS APPLY (SELECT TRY_CONVERT(int,PARSENAME(t.Version,3)) AS Major,
                            TRY_CONVERT(int,PARSENAME(t.Version,2)) AS Minor,
                            TRY_CONVERT(int,PARSENAME(t.Version,1)) AS Patch) n
        WHERE OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.ObjectName),N'P') IS NULL
           OR t.Version IS NULL OR PARSENAME(t.Version,4) IS NOT NULL
           OR n.Major IS NULL OR n.Minor IS NULL OR n.Patch IS NULL
           OR n.Major<0 OR n.Minor<0 OR n.Patch<0
           OR CONVERT(varbinary(max),t.Version)<>CONVERT(varbinary(max),CONCAT(n.Major,N'.',n.Minor,N'.',n.Patch))
           OR n.Major<d.MinimumMajor
           OR (n.Major=d.MinimumMajor AND n.Minor<d.MinimumMinor)
           OR (n.Major=d.MinimumMajor AND n.Minor=d.MinimumMinor AND n.Patch<d.MinimumPatch)
           OR (d.ModuleId<>N'toolbelt.filesystem.windows' AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=0 AND e.major_id=0 AND e.minor_id=0
               AND e.name=N'Toolbelt.Module.'+d.ModuleId+N'.DeploymentMode'
               AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'local')))
           OR (d.ModuleId<>N'toolbelt.filesystem.windows' AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.ObjectName)) AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId'
               AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),d.ModuleId)))
           OR (d.ModuleId<>N'toolbelt.filesystem.windows' AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.ObjectName)) AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleVersion'
               AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),t.Version)))
           OR (d.ModuleId=N'toolbelt.core.result-table' AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.ObjectName)) AND e.minor_id=0 AND e.name=N'Toolbelt.DeploymentMode'
               AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'local')))
    ) THROW 54633,N'TBX_ZIP_FILE_DEPENDENCY: Lokale Dependencies mit kohärenten P-Slots und Versionsmarkern fehlen.',1;
        -- Kollationgleiche Aliasnamen niemals als freie oder eigene Slots behandeln.
        IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o
            ON o.schema_id=SCHEMA_ID(N'toolbelt_archive')
            AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT
            WHERE CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name))
            THROW 54634,N'TBX_ZIP_FILE_LIFECYCLE_COLLISION: Kollationgleicher fremder Slotname.',1;
        SET @Present=(SELECT COUNT(*) FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_archive') AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),s.Name));
        SET @Version=NULL; SET @Mode=NULL;
        SELECT @Version=TRY_CONVERT(nvarchar(128),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-files.Version';
        SELECT @Mode=TRY_CONVERT(nvarchar(128),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-files.DeploymentMode';
        IF @Present=0 AND (@Version IS NOT NULL OR @Mode IS NOT NULL
            OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name IN(N'Toolbelt.Module.toolbelt.archive.zip-files.Version',N'Toolbelt.Module.toolbelt.archive.zip-files.DeploymentMode')))
            THROW 54634,N'TBX_ZIP_FILE_LIFECYCLE_COLLISION: Verwaiste Modulmarker.',1;
        IF @Present<>0 AND
            (@Present<>2 OR @Version IS NULL OR @Mode IS NULL
             OR CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0')
             OR CONVERT(varbinary(max),@Mode)<>CONVERT(varbinary(max),N'local')
             OR EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_archive') AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),s.Name)
                WHERE o.object_id IS NULL OR CONVERT(varbinary(2),o.type)<>CONVERT(varbinary(2),CONVERT(char(2),'P'))
                OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'toolbelt.archive.zip-files'))
                OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'1.0.0'))
                OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.ContractVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'1.0'))
                OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'local'))))
            THROW 54634,N'TBX_ZIP_FILE_LIFECYCLE_COLLISION: Unbekannter oder fremder Zwei-P-Releasezustand.',1;
        IF EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId'
           AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'toolbelt.archive.zip-files')
           AND NOT EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_archive') AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),s.Name) WHERE o.object_id=e.major_id))
            THROW 54634,N'TBX_ZIP_FILE_LIFECYCLE_COLLISION: Zusätzliche unbekannte Modulobjekte bleiben erhalten.',1;
        IF @Pass=1
        BEGIN
            BEGIN TRANSACTION;
            EXEC @LockResult=sys.sp_getapplock @Resource=N'Toolbelt.Module.toolbelt.archive.zip-files',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=15000;
            IF @LockResult<0 THROW 54635,N'TBX_ZIP_FILE_LIFECYCLE_APPLOCK: AppLock nicht erworben.',1;
        END;
        SET @Pass+=1;
    END;
    CREATE TABLE #tbx_ZipFiles_Deploy(Ready bit NOT NULL);
    INSERT #tbx_ZipFiles_Deploy VALUES(1);
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
:r ../Source/USP_CreateZipFileFromEntries.sql
:r ../Source/USP_ExtractZipEntryToFile.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    IF XACT_STATE()<>1 OR (SELECT COUNT(*) FROM #tbx_ZipFiles_Deploy WHERE Ready=1)<>1
        THROW 54636,N'TBX_ZIP_FILE_LIFECYCLE_INSTALL: Eigene Installationstransaktion fehlt.',1;
    DECLARE @Properties TABLE(Ordinal int IDENTITY PRIMARY KEY,Name sysname NOT NULL,Value nvarchar(4000) NOT NULL);
    INSERT @Properties(Name,Value) VALUES(N'Toolbelt.ModuleId',N'toolbelt.archive.zip-files'),(N'Toolbelt.ModuleVersion',N'1.0.0'),(N'Toolbelt.ContractVersion',N'1.0'),(N'Toolbelt.DeploymentMode',N'local');
    DECLARE @Objects TABLE(Ordinal int IDENTITY PRIMARY KEY,Name sysname);
    INSERT @Objects VALUES(N'USP_CreateZipFileFromEntries'),(N'USP_ExtractZipEntryToFile');
    DECLARE @j int=1,@i int,@Name sysname,@Value nvarchar(4000),@ObjectName sysname,@ObjectId int,@Hash nvarchar(64);
    WHILE @j<=2
    BEGIN
        SELECT @ObjectName=Name FROM @Objects WHERE Ordinal=@j;
        SET @ObjectId=OBJECT_ID(N'toolbelt_archive.'+QUOTENAME(@ObjectName),N'P');
        IF @ObjectId IS NULL THROW 54636,N'TBX_ZIP_FILE_LIFECYCLE_INSTALL: P-Slot fehlt.',1;
        SET @i=1;
        WHILE @i<=4
        BEGIN
            SELECT @Name=Name,@Value=Value FROM @Properties WHERE Ordinal=@i;
            IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@Name)
                EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_archive',@level1type=N'PROCEDURE',@level1name=@ObjectName;
            ELSE EXEC sys.sp_addextendedproperty @name=@Name,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_archive',@level1type=N'PROCEDURE',@level1name=@ObjectName;
            SET @i+=1;
        END;
        SET @Hash=CONVERT(nvarchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@ObjectId))),2);
        IF @Hash IS NULL THROW 54636,N'TBX_ZIP_FILE_LIFECYCLE_INSTALL: SourceHash nicht sichtbar.',1;
        IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=N'Toolbelt.SourceHash')
            EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.SourceHash',@value=@Hash,@level0type=N'SCHEMA',@level0name=N'toolbelt_archive',@level1type=N'PROCEDURE',@level1name=@ObjectName;
        ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SourceHash',@value=@Hash,@level0type=N'SCHEMA',@level0name=N'toolbelt_archive',@level1type=N'PROCEDURE',@level1name=@ObjectName;
        SET @j+=1;
    END;
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-files.Version')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.archive.zip-files.Version',@value=N'1.0.0';
    ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.archive.zip-files.Version',@value=N'1.0.0';
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-files.DeploymentMode')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.archive.zip-files.DeploymentMode',@value=N'local';
    ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.archive.zip-files.DeploymentMode',@value=N'local';
    DROP TABLE #tbx_ZipFiles_Deploy;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
