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
BEGIN TRY
    WHILE @Pass<=2
    BEGIN
        IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
           OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
            THROW 54632,N'TBX_ZIP_FILE_LIFECYCLE_VISIBILITY: Vollständige Lifecycle-Metadatensicht fehlt.',1;
        IF TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN(15,16,17)
           OR NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE CONVERT(varbinary(max),host_platform)=CONVERT(varbinary(max),N'Windows'))
            THROW 54631,N'TBX_ZIP_FILE_LIFECYCLE_ARGUMENT: Windows SQL Server 2019/2022/2025 erforderlich.',1;
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
        IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d
            WHERE NOT EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects own ON own.schema_id=SCHEMA_ID(N'toolbelt_archive') AND CONVERT(varbinary(max),own.name)=CONVERT(varbinary(max),s.Name) WHERE own.object_id=d.referencing_id)
            AND EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_archive') AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),s.Name)
                WHERE d.referenced_id=o.object_id OR (d.referenced_server_name IS NULL
                    AND (d.referenced_database_name IS NULL OR d.referenced_database_name COLLATE DATABASE_DEFAULT=DB_NAME() COLLATE DATABASE_DEFAULT)
                    AND d.referenced_schema_name COLLATE DATABASE_DEFAULT=N'toolbelt_archive' COLLATE DATABASE_DEFAULT
                    AND d.referenced_entity_name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT)))
            THROW 54637,N'TBX_ZIP_FILE_LIFECYCLE_CONSUMER: Sichtbarer Consumer blockiert Uninstall.',1;
        IF @Pass=1
        BEGIN
            BEGIN TRANSACTION;
            EXEC @LockResult=sys.sp_getapplock @Resource=N'Toolbelt.Module.toolbelt.archive.zip-files',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=15000;
            IF @LockResult<0 THROW 54635,N'TBX_ZIP_FILE_LIFECYCLE_APPLOCK: AppLock nicht erworben.',1;
        END;
        SET @Pass+=1;
    END;
    IF @Present=2
    BEGIN
        DROP PROCEDURE toolbelt_archive.USP_CreateZipFileFromEntries;
        DROP PROCEDURE toolbelt_archive.USP_ExtractZipEntryToFile;
        EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.archive.zip-files.Version';
        EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.archive.zip-files.DeploymentMode';
    END;
    -- Das Archivschema und alle Dependencies/Assemblys/Trusts/Roots/Dateien bleiben erhalten.
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
