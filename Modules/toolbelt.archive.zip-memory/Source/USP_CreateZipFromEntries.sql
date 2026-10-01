-- ============================================================================
-- Objekt: toolbelt_archive.USP_CreateZipFromEntries; Typ: Stored Procedure
-- Zweck: Begrenztes In-memory-ZIP aus caller-lokaler Entrytabelle erzeugen.
-- Vertrag: Documentation/USP_CreateZipFromEntries.md; USP_CONTRACT 1.0.
-- Parameter: EntryTable, Stored/Deflate, positive Ressourcenlimits; Standard-
-- Defaults 256 Entries/16 MiB Entry/64 MiB Summe/68 MiB Output und Envelope.
-- Resultset: ArchivePayload, ArchiveBytes, EntryCount, TotalPayloadBytes,
-- CompressionMethod; Dependencies: SAFE-ZIP-CLR, ResultTable >=1.0.0.
-- Rechte: EXECUTE, eigene lokale Temps; keine Rechte-/Trustausweitung.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehler: 51350–51359; keine Teilarchive, callerfreundliche Savepoints.
-- Performance: Snapshot/Envelope/Output materialisiert, LOB-.WRITE statt
-- wachsender Variablenkonkatenation; CLR-Budget kooperativ, kein SQL-Timeout.
-- Einschränkungen: kein Datei-I/O/ZIP64/TVP/Encryption; Readerlimits bleiben.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_archive.USP_CreateZipFromEntries
      @EntryTable sysname = NULL
    , @CompressionMethod varchar(max) = 'Stored'
    , @MaxEntries int = 256
    , @MaxEntryNameCodeUnits int = 1024
    , @MaxEntryBytes bigint = 16777216
    , @MaxTotalPayloadBytes bigint = 67108864
    , @MaxArchiveBytes bigint = 71303168
    , @MaxEnvelopeBytes bigint = 71303168
    , @WriterBudgetMilliseconds int = 30000
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData=ISNULL(@KeepData,0), @Debug=ISNULL(@Debug,0), @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe = 1
    BEGIN
        -- Reiner Helpweg ignoriert fachliche Parameter und Dependencies.
        DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
        INSERT @Help SELECT CONVERT(varchar(16),'1.0') AS HelpContractVersion,
               CONVERT(sysname,N'toolbelt_archive') AS SchemaName,
               CONVERT(sysname,N'USP_CreateZipFromEntries') AS ObjectName,
               CONVERT(varchar(32),v.Section) AS Section, v.Ordinal,
               CONVERT(sysname,v.ItemName) AS ItemName,
               CONVERT(varchar(256),v.SqlDataType) AS SqlDataType,
               CONVERT(bit,v.IsRequired) AS IsRequired,
               CONVERT(bit,v.IsNullable) AS IsNullable,
               CONVERT(nvarchar(4000),v.DefaultValue) AS DefaultValue,
               CONVERT(nvarchar(max),v.Description) AS Description,
               CONVERT(nvarchar(max),v.ExampleSql) AS ExampleSql
        FROM (VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.',NULL),
        ('PARAMETER',1,N'@EntryTable','sysname',1,0,N'NULL',N'Vorhandene lokale Temp-Tabelle, kein freies SQL.',NULL),
        ('PARAMETER',2,N'@CompressionMethod','varchar(max)',0,0,N'Stored',N'Exakt Stored oder Deflate; Default Stored.',NULL),
        ('PARAMETER',3,N'@MaxEntries','int',0,0,N'256',N'Positiv, höchstens 1024 Entries.',NULL),
        ('PARAMETER',4,N'@MaxEntryNameCodeUnits','int',0,0,N'1024',N'Positiv, höchstens 2048 UTF-16-Codeeinheiten; Reader bleibt 1024.',NULL),
        ('PARAMETER',5,N'@MaxEntryBytes','bigint',0,0,N'16777216',N'Positiv, höchstens 33554432 Payloadbytes je Entry.',NULL),
        ('PARAMETER',6,N'@MaxTotalPayloadBytes','bigint',0,0,N'67108864',N'Positiv, höchstens 134217728 Payloadbytes insgesamt.',NULL),
        ('PARAMETER',7,N'@MaxArchiveBytes','bigint',0,0,N'71303168',N'Positiv, höchstens 150994944 Outputbytes inklusive ZIP-Header.',NULL),
        ('PARAMETER',8,N'@MaxEnvelopeBytes','bigint',0,0,N'71303168',N'Positiv, höchstens 142606336 Transportbytes inklusive Namen/Framing.',NULL),
        ('PARAMETER',9,N'@WriterBudgetMilliseconds','int',0,0,N'30000',N'1 bis 60000, kooperatives CLR-Budget; keine SQL-End-to-End-Frist.',NULL),
        ('PARAMETER',10,N'@ResultTable','sysname',0,1,N'NULL',N'NULL: SELECT, sonst vorhandene lokale Temp-Tabelle; nicht identisch zum Input.',NULL),
        ('PARAMETER',11,N'@KeepData','bit',0,0,N'0',N'0 Replace; 1 Append nach USP-Vertrag.',NULL),
        ('PARAMETER',12,N'@Debug','tinyint',0,0,N'0',N'Nur Messages ohne Payloads oder Entrynamen.',NULL),
        ('PARAMETER',13,N'@Hilfe','bit',0,0,N'0',N'1: ausschließlich diese Hilfe, keine fachlichen Prüfungen/Mutation.',NULL),
        ('RESULT_COLUMN',1,N'ArchivePayload','varbinary(max)',NULL,0,NULL,N'Vollständig finalisiertes ZIP-Binary.',NULL),
        ('RESULT_COLUMN',2,N'ArchiveBytes','bigint',NULL,0,NULL,N'Tatsächliche Archivgröße in Bytes.',NULL),
        ('RESULT_COLUMN',3,N'EntryCount','int',NULL,0,NULL,N'Anzahl vorhandener Dateien, leere Liste erlaubt.',NULL),
        ('RESULT_COLUMN',4,N'TotalPayloadBytes','bigint',NULL,0,NULL,N'Summe unkomprimierter Payloadbytes.',NULL),
        ('RESULT_COLUMN',5,N'CompressionMethod','int',NULL,0,NULL,N'ZIP-Methode 0 Stored oder 8 Deflate.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer In-memory-Aufruf.',N'CREATE TABLE #ZipInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); INSERT #ZipInput VALUES(1,N''hello.txt'',0x4869); EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N''#ZipInput'';'),
        ('ERROR',1,N'51350-51359',NULL,NULL,NULL,NULL,N'TBX_ZIP_WRITE_*; kein Teiloutput; Original-Enginefehler und Callertransaktionszustand erhalten.',NULL)
        ) v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ;
        SELECT * FROM @Help ORDER BY Section,Ordinal;
        RETURN 0;
    END;

    IF @CompressionMethod IS NULL OR
       NOT ((@CompressionMethod COLLATE Latin1_General_100_BIN2 = 'Stored' AND DATALENGTH(@CompressionMethod)=6)
         OR (@CompressionMethod COLLATE Latin1_General_100_BIN2 = 'Deflate' AND DATALENGTH(@CompressionMethod)=7))
       OR @MaxEntries IS NULL OR @MaxEntries NOT BETWEEN 1 AND 1024
       OR @MaxEntryNameCodeUnits IS NULL OR @MaxEntryNameCodeUnits NOT BETWEEN 1 AND 2048
       OR @MaxEntryBytes IS NULL OR @MaxEntryBytes NOT BETWEEN 1 AND 33554432
       OR @MaxTotalPayloadBytes IS NULL OR @MaxTotalPayloadBytes NOT BETWEEN 1 AND 134217728
       OR @MaxArchiveBytes IS NULL OR @MaxArchiveBytes NOT BETWEEN 1 AND 150994944
       OR @MaxEnvelopeBytes IS NULL OR @MaxEnvelopeBytes NOT BETWEEN 1 AND 142606336
       OR @WriterBudgetMilliseconds IS NULL OR @WriterBudgetMilliseconds NOT BETWEEN 1 AND 60000
        THROW 51350,N'TBX_ZIP_WRITE_INVALID_ARGUMENT: Parameter oder Ressourcenlimit ungültig.',1;
    DECLARE @DependencyVersion nvarchar(64)=(SELECT TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version');
    IF OBJECT_ID(N'toolbelt_archive.TVF_InternalZipWriterName',N'FT') IS NULL
       OR OBJECT_ID(N'toolbelt_archive.TVF_InternalZipWriterArchive',N'FT') IS NULL
       OR OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL
       OR @DependencyVersion IS NULL
       OR PARSENAME(@DependencyVersion,4) IS NOT NULL
       OR TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)) IS NULL
       OR TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)) IS NULL
       OR TRY_CONVERT(int,PARSENAME(@DependencyVersion,1)) IS NULL
       OR TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)) < 1
       OR TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)) < 0
       OR TRY_CONVERT(int,PARSENAME(@DependencyVersion,1)) < 0
       OR CONVERT(varbinary(128),@DependencyVersion) <> CONVERT(varbinary(128),CONCAT(TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)),N'.',TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)),N'.',TRY_CONVERT(int,PARSENAME(@DependencyVersion,1))))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@DependencyVersion))
        THROW 51357,N'TBX_ZIP_WRITE_DEPENDENCY: ZIP-Writer oder ResultTable >=1.0.0 fehlt.',1;
    IF @EntryTable IS NULL OR LEFT(@EntryTable,1)<>N'#' OR LEFT(@EntryTable,2)=N'##'
       OR LEN(@EntryTable)>116 OR CHARINDEX(N'.',@EntryTable)>0
       OR (@ResultTable IS NOT NULL AND (LEFT(@ResultTable,1)<>N'#' OR LEFT(@ResultTable,2)=N'##' OR LEN(@ResultTable)>116 OR CHARINDEX(N'.',@ResultTable)>0))
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Nur vorhandene caller-lokale Temps sind zulässig.',1;
    DECLARE @InputId int=OBJECT_ID(N'tempdb..'+QUOTENAME(@EntryTable),N'U'),
            @OutputId int=CASE WHEN @ResultTable IS NOT NULL THEN OBJECT_ID(N'tempdb..'+QUOTENAME(@ResultTable),N'U') END;
    IF @InputId IS NULL OR (@ResultTable IS NOT NULL AND @OutputId IS NULL) OR @InputId=@OutputId
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Temp fehlt oder Input und Output sind identisch.',2;
    IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@InputId AND
          ((name COLLATE Latin1_General_100_BIN2=N'Ordinal' AND system_type_id=56 AND max_length=4)
          OR (name COLLATE Latin1_General_100_BIN2=N'EntryName' AND system_type_id=231 AND max_length=-1)
          OR (name COLLATE Latin1_General_100_BIN2=N'Payload' AND system_type_id=165 AND max_length=-1))
          AND is_computed=0 AND encryption_type IS NULL) <> 3
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Erwartet Ordinal int, EntryName nvarchar(max), Payload varbinary(max).',3;
    IF XACT_STATE()=-1 THROW 51350,N'TBX_ZIP_WRITE_INVALID_ARGUMENT: Callertransaktion nicht committable.',2;
    IF LEFT(@EntryTable,15)=N'#tbx_ZipWriter_' OR LEFT(@ResultTable,15)=N'#tbx_ZipWriter_'
        THROW 51351,N'TBX_ZIP_WRITE_INPUT_SCHEMA: Interne Helpernamen sind reserviert.',4;

    -- Keine MARS-/Parallelmutation derselben Caller-Temps während des
    -- synchronen Aufrufs. Eine Lese-Transaktion stabilisiert Preflight/Snapshot.
    DECLARE @OwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @SavepointSet bit=0,
            @Savepoint varchar(32)='tbxZW'+REPLACE(CONVERT(varchar(36),NEWID()),'-',''),
            @Sql nvarchar(max), @Count bigint, @Total bigint, @Invalid bigint,
            @TooLarge bigint, @Duplicate bigint, @Envelope varbinary(max),
            @Archive varbinary(max), @Method int=CASE WHEN @CompressionMethod='Stored' THEN 0 ELSE 8 END;
    BEGIN TRY
        IF @OwnTransaction=1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @SavepointSet=1; END;
        SET @Sql=N'SELECT @Count=COUNT_BIG(*), @Total=COALESCE(SUM(CONVERT(bigint,DATALENGTH(Payload))),0),
          @Invalid=COALESCE(SUM(CONVERT(bigint,CASE WHEN Ordinal IS NULL OR Ordinal<1 OR EntryName IS NULL OR Payload IS NULL THEN 1 ELSE 0 END)),0),
          @TooLarge=COALESCE(SUM(CONVERT(bigint,CASE WHEN DATALENGTH(Payload)>@EntryMax OR DATALENGTH(EntryName)>CONVERT(bigint,@NameMax)*2 THEN 1 ELSE 0 END)),0)
          FROM '+QUOTENAME(@EntryTable)+N' WITH(HOLDLOCK);
          SELECT @Duplicate=COUNT_BIG(*) FROM(SELECT Ordinal FROM '+QUOTENAME(@EntryTable)+N' GROUP BY Ordinal HAVING COUNT_BIG(*)>1)d;';
        EXEC sys.sp_executesql @Sql,N'@Count bigint OUTPUT,@Total bigint OUTPUT,@Invalid bigint OUTPUT,@TooLarge bigint OUTPUT,@Duplicate bigint OUTPUT,@EntryMax bigint,@NameMax int',
            @Count OUTPUT,@Total OUTPUT,@Invalid OUTPUT,@TooLarge OUTPUT,@Duplicate OUTPUT,@MaxEntryBytes,@MaxEntryNameCodeUnits;
        IF @Invalid>0 OR @Duplicate>0 THROW 51350,N'TBX_ZIP_WRITE_INVALID_ARGUMENT: NULL, ungültige oder doppelte Ordinals.',3;
        IF @Count>@MaxEntries OR @Total>@MaxTotalPayloadBytes OR @TooLarge>0
            THROW 51354,N'TBX_ZIP_WRITE_RESOURCE_LIMIT: Input überschreitet die Ressourcenlimits.',1;
        CREATE TABLE #tbx_ZipWriter_Snapshot(Ordinal int NOT NULL PRIMARY KEY, EntryName nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL, Payload varbinary(max) NOT NULL, NameBytes varbinary(max) NULL, NameError int NULL);
        SET @Sql=N'INSERT #tbx_ZipWriter_Snapshot(Ordinal,EntryName,Payload) SELECT Ordinal,EntryName,Payload FROM '+QUOTENAME(@EntryTable)+N' WITH(HOLDLOCK);';
        EXEC sys.sp_executesql @Sql;
        -- Encoding wird vor verlustbehafteter UTF8-Konvertierung durch CLR mit
        -- Exceptionfallback validiert; Namensduplikate inklusive Länge/Bytes.
        UPDATE s SET NameBytes=p.Payload,NameError=p.ErrorNumber
        FROM #tbx_ZipWriter_Snapshot s CROSS APPLY toolbelt_archive.TVF_InternalZipWriterName(EntryName COLLATE DATABASE_DEFAULT,@MaxEntryNameCodeUnits) p;
        IF EXISTS(SELECT 1 FROM #tbx_ZipWriter_Snapshot WHERE NameError IS NULL OR NameError<>0 OR NameBytes IS NULL)
            THROW 51352,N'TBX_ZIP_WRITE_INVALID_NAME: Name oder UTF-16 ungültig.',1;
        IF EXISTS(SELECT 1 FROM #tbx_ZipWriter_Snapshot a JOIN #tbx_ZipWriter_Snapshot b ON a.Ordinal<b.Ordinal
            AND DATALENGTH(a.NameBytes)=DATALENGTH(b.NameBytes) AND a.NameBytes=b.NameBytes)
            THROW 51353,N'TBX_ZIP_WRITE_DUPLICATE_NAME: Binär identische Namen.',1;
        DECLARE @EnvelopeSize bigint=12+@Total+@Count*16+(SELECT COALESCE(SUM(CONVERT(bigint,DATALENGTH(NameBytes))),0) FROM #tbx_ZipWriter_Snapshot);
        IF @EnvelopeSize>@MaxEnvelopeBytes THROW 51354,N'TBX_ZIP_WRITE_RESOURCE_LIMIT: Envelope inklusive Namen/Framing zu groß.',2;
        CREATE TABLE #tbx_ZipWriter_Envelope(Value varbinary(max) NOT NULL);
        DECLARE @CountBinary binary(4)=CONVERT(binary(4),CONVERT(int,@Count));
        INSERT #tbx_ZipWriter_Envelope VALUES(0x54425A5701000000+SUBSTRING(@CountBinary,4,1)+SUBSTRING(@CountBinary,3,1)+SUBSTRING(@CountBinary,2,1)+SUBSTRING(@CountBinary,1,1));
        DECLARE @Ordinal int,@Name varbinary(max),@Payload varbinary(max),@Chunk varbinary(max);
        DECLARE EntryCursor CURSOR LOCAL FAST_FORWARD FOR SELECT Ordinal,NameBytes,Payload FROM #tbx_ZipWriter_Snapshot ORDER BY Ordinal;
        OPEN EntryCursor;
        FETCH NEXT FROM EntryCursor INTO @Ordinal,@Name,@Payload;
        WHILE @@FETCH_STATUS=0
        BEGIN
            -- REVERSE(binary) liefert varchar und ist deshalb kein sicherer
            -- Binarytransport. Byteweise SUBSTRING bleibt varbinary.
            DECLARE @OrdinalBinary binary(4)=CONVERT(binary(4),@Ordinal),@NameBinary binary(4)=CONVERT(binary(4),DATALENGTH(@Name)),@PayloadBinary binary(8)=CONVERT(binary(8),CONVERT(bigint,DATALENGTH(@Payload)));
            SET @Chunk=SUBSTRING(@OrdinalBinary,4,1)+SUBSTRING(@OrdinalBinary,3,1)+SUBSTRING(@OrdinalBinary,2,1)+SUBSTRING(@OrdinalBinary,1,1)
              +SUBSTRING(@NameBinary,4,1)+SUBSTRING(@NameBinary,3,1)+SUBSTRING(@NameBinary,2,1)+SUBSTRING(@NameBinary,1,1)
              +SUBSTRING(@PayloadBinary,8,1)+SUBSTRING(@PayloadBinary,7,1)+SUBSTRING(@PayloadBinary,6,1)+SUBSTRING(@PayloadBinary,5,1)
              +SUBSTRING(@PayloadBinary,4,1)+SUBSTRING(@PayloadBinary,3,1)+SUBSTRING(@PayloadBinary,2,1)+SUBSTRING(@PayloadBinary,1,1)+@Name;
            -- .WRITE fügt LOB-Teile an; kein @Envelope=@Envelope+Payload mit
            -- quadratischen Komplettkopien bei vielen Entries.
            UPDATE #tbx_ZipWriter_Envelope SET Value.WRITE(@Chunk,NULL,0);
            UPDATE #tbx_ZipWriter_Envelope SET Value.WRITE(@Payload,NULL,0);
            FETCH NEXT FROM EntryCursor INTO @Ordinal,@Name,@Payload;
        END;
        CLOSE EntryCursor; DEALLOCATE EntryCursor;
        SELECT @Envelope=Value FROM #tbx_ZipWriter_Envelope;
        IF DATALENGTH(@Envelope)<>@EnvelopeSize THROW 51358,N'TBX_ZIP_WRITE_TRANSPORT_INVALID: Envelope-Länge widersprüchlich.',1;
        DECLARE @Provider TABLE(ErrorNumber int,ErrorMessage nvarchar(4000),Payload varbinary(max));
        INSERT @Provider SELECT ErrorNumber,ErrorMessage,Payload
        FROM toolbelt_archive.TVF_InternalZipWriterArchive(@Envelope,@Method,@MaxEntries,@MaxEntryNameCodeUnits,@MaxEntryBytes,@MaxTotalPayloadBytes,@MaxArchiveBytes,@MaxEnvelopeBytes,@WriterBudgetMilliseconds);
        IF (SELECT COUNT(*) FROM @Provider)<>1 THROW 51359,N'TBX_ZIP_WRITE_PROVIDER_FAILURE: Statusrow fehlt oder mehrdeutig.',1;
        DECLARE @ProviderError int,@ProviderMessage nvarchar(4000);
        SELECT @ProviderError=ErrorNumber,@ProviderMessage=ErrorMessage,@Archive=Payload FROM @Provider;
        IF @ProviderError IS NULL OR @ProviderError NOT BETWEEN 0 AND 51359 OR (@ProviderError<>0 AND @ProviderError<51350)
            THROW 51359,N'TBX_ZIP_WRITE_PROVIDER_FAILURE: Fehlerstatus ungültig.',2;
        IF @ProviderError<>0 THROW @ProviderError,@ProviderMessage,1;
        IF @Archive IS NULL THROW 51359,N'TBX_ZIP_WRITE_PROVIDER_FAILURE: Archiv fehlt.',1;
        CREATE TABLE #tbx_ZipWriter_Result(ArchivePayload varbinary(max) NOT NULL,ArchiveBytes bigint NOT NULL,EntryCount int NOT NULL,TotalPayloadBytes bigint NOT NULL,CompressionMethod int NOT NULL);
        INSERT #tbx_ZipWriter_Result VALUES(@Archive,DATALENGTH(@Archive),CONVERT(int,@Count),@Total,@Method);
        IF @ResultTable IS NOT NULL
        BEGIN
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ZipWriter_Result',@KeepData=@KeepData,@Debug=@Debug;
            SET @Sql=N'INSERT '+QUOTENAME(@ResultTable)+N'(ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod) SELECT ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod FROM #tbx_ZipWriter_Result;';
            EXEC sys.sp_executesql @Sql;
        END;
        IF @OwnTransaction=1 COMMIT TRANSACTION;
        IF @Debug>0 PRINT N'ZIP-Writer: vollständiges Archiv erfolgreich erzeugt; Inhalte werden nicht ausgegeben.';
        IF @ResultTable IS NULL SELECT ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod FROM #tbx_ZipWriter_Result;
        DROP TABLE #tbx_ZipWriter_Result,#tbx_ZipWriter_Envelope,#tbx_ZipWriter_Snapshot;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @OwnTransaction=0 AND @SavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
        -- Lokale statische Temps werden bei Scopeende auch dann entfernt,
        -- wenn ein Caller-Doom-Zustand kein weiteres DDL erlaubt.
        THROW;
    END CATCH;
END;
GO
