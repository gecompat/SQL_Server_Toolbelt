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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_archive' AS sysname) AS SchemaName,
            CAST(N'USP_CreateZipFromEntries' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'ArchivePayload', N'varbinary(max)', NULL, 0, NULL, CAST(N'Vollständig finalisiertes ZIP-Binary.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ArchiveBytes', N'bigint', NULL, 0, NULL, CAST(N'Tatsächliche Archivgröße in Bytes.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'EntryCount', N'int', NULL, 0, NULL, CAST(N'Anzahl vorhandener Dateien, leere Liste erlaubt.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'TotalPayloadBytes', N'bigint', NULL, 0, NULL, CAST(N'Summe unkomprimierter Payloadbytes.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'CompressionMethod', N'int', NULL, 0, NULL, CAST(N'ZIP-Methode 0 Stored oder 8 Deflate.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer In-memory-Aufruf.' AS nvarchar(max)), CAST(N'CREATE TABLE #ZipInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); INSERT #ZipInput VALUES(1,N''hello.txt'',0x4869); EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N''#ZipInput'';' AS nvarchar(max))),
        (N'ERROR', 1, N'51350-51359', NULL, NULL, NULL, NULL, CAST(N'TBX_ZIP_WRITE_*; kein Teiloutput; Original-Enginefehler und Callertransaktionszustand erhalten.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@EntryTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene sichtbare caller-lokale #Temp, Name ohne Punkt/## und höchstens 116 Zeichen, nicht dieselbe tatsächliche Tabelle wie ResultTable. Benötigt Ordinal int, EntryName nvarchar(max), Payload varbinary(max), nicht computed/verschlüsselt; Zusatzspalten und nullable Metadaten erlaubt, tatsächliche Werte alle nicht NULL. Ordinal positiv und eindeutig, Lücken erlaubt; Ausgabe nach Ordinal. EntryName 1..MaxEntryNameCodeUnits wohlgeformte UTF-16-Einheiten, binär/case-/längensensitiv eindeutig; relative /-Dateinamen ohne NUL, Backslash, Doppelpunkt, führenden/abschließenden /, leere Segmente sowie Segmente mit exakt einem oder zwei Punkten. Payload darf 0x sein. Leere Tabelle erzeugt ein gültiges 22-Byte-EOCD-ZIP. NULL ist fachlich ungültig; keine Parallelmutation.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@CompressionMethod', N'varchar(max)', 0, 0, N'''Stored''', CAST(N'Taxativ, exakt ASCII einschließlich Länge/Case: Stored (Default) = Method0, unkomprimierte Payload; Deflate = Method8, Deflate-Kompression. Gilt für alle Entries. NULL/leer/andere Schreibweisen/angehängte Spaces ungültig; keine freie Kompressionsstufe/Methodnummer.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxEntries', N'int', 0, 0, N'256', CAST(N'Ganzzahl 1..1024, Default 256: Entries über die gesamte Tabelle. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxEntryNameCodeUnits', N'int', 0, 0, N'1024', CAST(N'Ganzzahl 1..2048, Default 1024: UTF-16-Einheiten je Entryname; Reader bleibt unabhängig bei 1024. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxEntryBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..33554432, Default 16777216: unkomprimierte Payloadbytes je Entry. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxTotalPayloadBytes', N'bigint', 0, 0, N'67108864', CAST(N'Ganzzahl 1..134217728, Default 67108864: Summe unkomprimierter Payloadbytes aller Entries. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxArchiveBytes', N'bigint', 0, 0, N'71303168', CAST(N'Ganzzahl 1..150994944, Default 71303168: Bytes des vollständigen finalisierten ZIP einschließlich Header, Namen und Directory. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxEnvelopeBytes', N'bigint', 0, 0, N'71303168', CAST(N'Ganzzahl 1..142606336, Default 71303168: Bytes des internen Übergabe-Envelopes einschließlich Framing und Namen, nicht nur Payload. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@WriterBudgetMilliseconds', N'int', 0, 0, N'30000', CAST(N'Ganzzahl 1..60000, Default 30000: Millisekunden kooperatives Writerbudget; keine harte Gesamtwallclock-/SQL-Marshallingfrist. Innerhalb dieses Bereichs absenkbar oder erhöhbar; NULL/0/negativ/höher ungültig. Keine unbegrenzte Einstellung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf nicht die EntryTable sein; beim In-memory-Writer kein Punkt im Namen und kein reservierter #tbx_ZipWriter_-Name.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 kurze Abschlussmessage ohne Entrynamen/Payloads/Pfade; bei ResultTable zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
