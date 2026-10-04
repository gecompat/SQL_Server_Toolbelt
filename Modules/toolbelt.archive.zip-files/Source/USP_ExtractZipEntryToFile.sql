-- ============================================================================
-- Objekt: toolbelt_archive.USP_ExtractZipEntryToFile; Typ: Stored Procedure
-- Zweck: Vollständiges ZIP/Entry-Binary über den vorhandenen Windowsprovider schreiben.
-- Vertrag: ZIP_FILES_CONTRACT.md; USP 1.0; Version 1.0.0.
-- Dependencies: ZIP Memory >=1.4.0, Windows Filesystem/ResultTable >=1.0.0 lokal.
-- Rechte: bestehende EXECUTE-/NTFS-Rechte; kein GRANT/Owner-/Trust-/Configwechsel.
-- Plattform: Windows, SQL Server 2019/2022/2025; aktive Caller-TX abgewiesen.
-- Fehler: 54620-54624; kanonische Provider-/Enginefehler bleiben erhalten.
-- Performance: begrenzte vollständige Materialisierung; keine harte Gesamtfrist.
-- Einschränkung: keine SQL-/Dateisystematomarität, keine Verzeichnisanlage.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_archive.USP_ExtractZipEntryToFile
      @ZipArchive varbinary(max) = NULL
    , @EntryName nvarchar(1024) = NULL
    , @RootAlias sysname = NULL
    , @RelativePath nvarchar(4000) = NULL
    , @MaxEntryBytes bigint = 104857600
    , @MaxCompressionRatio decimal(9,2) = 200.00
    , @Overwrite bit = 0
    , @ExecutionIdentity varchar(16) = 'Caller'
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @Hilfe=ISNULL(@Hilfe,0),@Debug=ISNULL(@Debug,0),@KeepData=ISNULL(@KeepData,0);
    IF @Hilfe=1
    BEGIN
        DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
        INSERT @Help
        SELECT '1.0',N'toolbelt_archive',N'USP_ExtractZipEntryToFile',v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.',NULL) ,
        ('PARAMETER',1,N'@ZipArchive','varbinary(max)',CONVERT(bit,1),CONVERT(bit,0),N'NULL',N'ZIP-Binary; harte Readergrenze 268435456 Bytes.',NULL) ,
        ('PARAMETER',2,N'@EntryName','nvarchar(1024)',CONVERT(bit,1),CONVERT(bit,0),N'NULL',N'Exakter ordinaler Entryname; kein abgeleiteter Dateipfad.',NULL) ,
        ('PARAMETER',3,N'@RootAlias','sysname',CONVERT(bit,1),CONVERT(bit,0),N'NULL',N'Vorhandener freigegebener Filesystem-Root-Alias.',NULL) ,
        ('PARAMETER',4,N'@RelativePath','nvarchar(4000)',CONVERT(bit,1),CONVERT(bit,0),N'NULL',N'Expliziter relativer Zielpfad; Zielverzeichnis muss bestehen.',NULL) ,
        ('PARAMETER',5,N'@MaxEntryBytes','bigint',CONVERT(bit,0),CONVERT(bit,0),N'104857600',N'1 bis 2147483647 unkomprimierte Entrybytes; geerbte Obergrenze, kein Kapazitätsnachweis.',NULL) ,
        ('PARAMETER',6,N'@MaxCompressionRatio','decimal(9,2)',CONVERT(bit,0),CONVERT(bit,0),N'200.00',N'Mindestens 1; kanonische deklarierte und tatsächliche Readerprüfung.',NULL) ,
        ('PARAMETER',7,N'@Overwrite','bit',CONVERT(bit,0),CONVERT(bit,0),N'0',N'Unverändert an WriteBinaryFile; kein Direct-Write-Fallback.',NULL) ,
        ('PARAMETER',8,N'@ExecutionIdentity','varchar(16)',CONVERT(bit,0),CONVERT(bit,0),N'''Caller''',N'Caller als Default; ServiceAccount nur explizit gewählt.',NULL) ,
        ('PARAMETER',9,N'@ResultTable','sysname',CONVERT(bit,0),CONVERT(bit,1),N'NULL',N'NULL: ein SELECT; sonst vorhandene lokale Caller-Temp, ohne Resultset.',NULL) ,
        ('PARAMETER',10,N'@KeepData','bit',CONVERT(bit,0),CONVERT(bit,0),N'0',N'0 Replace, 1 Append; SQL-Publikation erst nach Dateipublikation.',NULL) ,
        ('PARAMETER',11,N'@Debug','tinyint',CONVERT(bit,0),CONVERT(bit,0),N'0',N'Nur Messages ohne Pfade, Entrynamen oder Payloads.',NULL) ,
        ('PARAMETER',12,N'@Hilfe','bit',CONVERT(bit,0),CONVERT(bit,0),N'0',N'1 ignoriert alle anderen Parameter, Dependencies und Transaktionen.',NULL) ,
        ('RESULT_COLUMN',1,N'BytesWritten','bigint',NULL,CONVERT(bit,0),NULL,N'Tatsächlich veröffentlichte Payloadbytes.',NULL) ,
        ('RESULT_COLUMN',2,N'RootAlias','nvarchar(128)',NULL,CONVERT(bit,0),NULL,N'Root-Alias aus dem Filesystemresultat.',NULL) ,
        ('RESULT_COLUMN',3,N'RelativePath','nvarchar(4000)',NULL,CONVERT(bit,0),NULL,N'Relativer Zielpfad aus dem Filesystemresultat.',NULL) ,
        ('RESULT_COLUMN',4,N'State','varchar(16)',NULL,CONVERT(bit,0),NULL,N'Unveränderter Filesystemstatus completed.',NULL) ,
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Aufruf mit zuvor eingerichtetem Root-Alias.',N'EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=0x504B03041400000000000000210000000000000000000000000009000000656D7074792E747874504B0102140014000000000000002100000000000000000000000000090000000000000000000000000000000000656D7074792E747874504B0506000000000100010037000000270000000000,@EntryName=N''empty.txt'',@RootAlias=N''ContosoOutput'',@RelativePath=N''empty.txt'';') ,
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Nach Publish kann SQL-Ausgabe scheitern; Datei bleibt bestehen. Vor Retry eigenen Zielzustand klären. Keine SQL-/Dateisystematomarität.',NULL) ,
        ('LIMITATION',2,NULL,NULL,NULL,NULL,NULL,N'Ein erfolgreicher unverschlüsselter leerer Entry wird als 0-Byte-Datei geschrieben; NULL oder Encryption wird niemals zu 0x umgedeutet.',NULL) ,
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Bestehende EXECUTE-/Ownershipchain-, Alias- und NTFS-Rechte; keine Rechtevergabe oder Identitätsfallback.',NULL) ,
        ('ERROR',1,NULL,NULL,NULL,NULL,NULL,N'54620-54624 TBX_ZIP_FILE_*; vorhandene ZIP-/Filesystem-/Helper- und Enginefehler unverändert.',NULL)
        ) v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
        SELECT HelpContractVersion,SchemaName,ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql FROM @Help
        ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5 WHEN 'LIMITATION' THEN 6 WHEN 'EXAMPLE' THEN 7 ELSE 8 END,Ordinal;
        RETURN 0;
    END;
    IF @@TRANCOUNT<>0 OR XACT_STATE()<>0
        THROW 54621,N'TBX_ZIP_FILE_CALLER_TRANSACTION_UNSUPPORTED: Dateipublikation benötigt einen transaktionsfreien Aufruf.',1;
    IF @RootAlias IS NULL OR DATALENGTH(@RootAlias)=0 OR @RelativePath IS NULL OR DATALENGTH(@RelativePath)=0
        THROW 54620,N'TBX_ZIP_FILE_INVALID_FACADE_ARGUMENT: RootAlias und RelativePath fehlen.',1;
    -- Enge Namingausnahme nur für diese statischen ResultTable-Brücken.
    IF OBJECT_ID(N'tempdb..#ZipFiles_CreateStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#ZipFiles_ExtractStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#ZipFiles_WriteStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_ZipFiles_Result',N'U') IS NOT NULL
        THROW 54624,N'TBX_ZIP_FILE_PRIVATE_TEMP_COLLISION: Eigener Tempname ist belegt.',1;
    IF @ResultTable IS NOT NULL AND
       (LEFT(@ResultTable,1)<>N'#' OR LEFT(@ResultTable,2)=N'##' OR DATALENGTH(@ResultTable) NOT BETWEEN 4 AND 232
        OR CHARINDEX(N'.',@ResultTable)>0
        OR LOWER(LEFT(@ResultTable,5) COLLATE Latin1_General_100_BIN2)=N'#tbx_'
        OR LOWER(@ResultTable COLLATE Latin1_General_100_BIN2) IN(N'#zipfiles_createstage',N'#zipfiles_extractstage',N'#zipfiles_writestage')
        OR OBJECT_ID(N'tempdb..'+QUOTENAME(@ResultTable),N'U') IS NULL)
        THROW 54620,N'TBX_ZIP_FILE_INVALID_FACADE_ARGUMENT: ResultTable muss eine vorhandene lokale Caller-Temp sein.',1;
    -- Keine zusätzliche DB-weite Metadatensicht für normale Aufrufer.
    DECLARE @Dependencies TABLE(ModuleId nvarchar(128),SchemaName sysname,ObjectName sysname,MinimumMajor int,MinimumMinor int,MinimumPatch int,RequireObjectMarkers bit NOT NULL);
    INSERT @Dependencies VALUES
      (N'toolbelt.archive.zip-memory',N'toolbelt_archive',N'USP_CreateZipFromEntries',1,4,0,1),
      (N'toolbelt.archive.zip-memory',N'toolbelt_archive',N'USP_ExtractZipEntryFromBinary',1,4,0,0),
      (N'toolbelt.filesystem.windows',N'toolbelt_filesystem',N'USP_WriteBinaryFile',1,0,0,0),
      (N'toolbelt.core.result-table',N'toolbelt_core',N'USP_PrepareResultTable',1,0,0,1);
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
           OR (d.RequireObjectMarkers=1 AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.ObjectName)) AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId'
               AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),d.ModuleId)))
           OR (d.RequireObjectMarkers=1 AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.ObjectName)) AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleVersion'
               AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),t.Version)))
           OR (d.ModuleId=N'toolbelt.core.result-table' AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(QUOTENAME(d.SchemaName)+N'.'+QUOTENAME(d.ObjectName)) AND e.minor_id=0 AND e.name=N'Toolbelt.DeploymentMode'
               AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'local')))
    ) THROW 54622,N'TBX_ZIP_FILE_DEPENDENCY: Lokale Dependencies mit kohärenten P-Slots und Versionsmarkern fehlen.',1;
    DECLARE @Payload varbinary(max),@Sql nvarchar(max);
    BEGIN TRY
        CREATE TABLE #ZipFiles_ExtractStage(EntryName nvarchar(1024) NOT NULL,CompressedBytes bigint NOT NULL,UncompressedBytes bigint NOT NULL,CompressionMethod int NOT NULL,Crc32 int NULL,IsEncrypted bit NOT NULL,EntryPayload varbinary(max) NULL);
        EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
            @ZipArchive=@ZipArchive,@EntryName=@EntryName,@MaxEntryBytes=@MaxEntryBytes,
            @MaxCompressionRatio=@MaxCompressionRatio,@FailIfEncrypted=1,
            @ResultTable=N'#ZipFiles_ExtractStage',@KeepData=0,@Debug=0,@Hilfe=0;
        IF (SELECT COUNT_BIG(*) FROM #ZipFiles_ExtractStage)<>1
           OR EXISTS(SELECT 1 FROM #ZipFiles_ExtractStage WHERE EntryPayload IS NULL
                OR IsEncrypted<>0 OR Crc32 IS NULL OR CompressedBytes<0 OR UncompressedBytes<0
                OR UncompressedBytes<>CONVERT(bigint,DATALENGTH(EntryPayload))
                OR CompressionMethod NOT IN(0,8)
                OR CONVERT(varbinary(max),EntryName)<>CONVERT(varbinary(max),@EntryName))
            THROW 54623,N'TBX_ZIP_FILE_INTERNAL_RESULT_INVALID: Extraktion ist nicht vollständig und unverschlüsselt.',1;
        SELECT @Payload=EntryPayload FROM #ZipFiles_ExtractStage;
        -- Erst nach vollständiger ZIP-/CRC-Prüfung, außerhalb jeder eigenen SQL-TX.
        CREATE TABLE #ZipFiles_WriteStage(BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL);
        EXEC toolbelt_filesystem.USP_WriteBinaryFile
            @RootAlias=@RootAlias,@RelativePath=@RelativePath,@Content=@Payload,
            @Overwrite=@Overwrite,@ExecutionIdentity=@ExecutionIdentity,
            @ResultTable=N'#ZipFiles_WriteStage',@KeepData=0,@Debug=0,@Hilfe=0;
        IF (SELECT COUNT_BIG(*) FROM #ZipFiles_WriteStage)<>1
           OR EXISTS(SELECT 1 FROM #ZipFiles_WriteStage WHERE BytesWritten<>CONVERT(bigint,DATALENGTH(@Payload))
                OR CONVERT(varbinary(max),State)<>CONVERT(varbinary(max),'completed'))
            THROW 54623,N'TBX_ZIP_FILE_INTERNAL_RESULT_INVALID: Filesystemstatus ist nicht eindeutig.',1;
        CREATE TABLE #tbx_ZipFiles_Result(BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL);
        INSERT #tbx_ZipFiles_Result(BytesWritten,RootAlias,RelativePath,State)
            SELECT BytesWritten,RootAlias,RelativePath,State FROM #ZipFiles_WriteStage;
        IF @ResultTable IS NOT NULL
        BEGIN
            -- Nur SQL-Zieldaten sind gemeinsam rückrollbar; Datei bleibt veröffentlicht.
            BEGIN TRANSACTION;
            EXEC toolbelt_core.USP_PrepareResultTable
                @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ZipFiles_Result',
                @KeepData=@KeepData,@Debug=@Debug,@Hilfe=0;
            SET @Sql=N'INSERT '+QUOTENAME(@ResultTable)+N'(BytesWritten,RootAlias,RelativePath,State) SELECT BytesWritten,RootAlias,RelativePath,State FROM #tbx_ZipFiles_Result;';
            EXEC sys.sp_executesql @Sql;
            COMMIT TRANSACTION;
        END;
        IF @Debug>0 PRINT N'ZIP-Datei: Dateipublikation und SQL-Ausgabe abgeschlossen.';
        IF @ResultTable IS NULL SELECT BytesWritten,RootAlias,RelativePath,State FROM #tbx_ZipFiles_Result;
        -- Alle eigenen statisch angelegten Temps enden automatisch mit dem Scope.
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Kein Caller-TX wurde angenommen. Ein Cleanupfehler ersetzt niemals den Primärfehler.
        BEGIN TRY
            IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        END TRY
        BEGIN CATCH
            PRINT N'TBX_ZIP_FILE_SECONDARY_SQL_ROLLBACK_FAILED';
        END CATCH;
        -- Kein Filesystem-Rollback oder kompensierendes Löschen.
        THROW;
    END CATCH;
END;
GO
