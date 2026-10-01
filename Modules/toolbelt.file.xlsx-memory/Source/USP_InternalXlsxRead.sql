/*
Interne Compiler-/Routinggrenze der beiden öffentlichen XLSX-USPs.
Kein zusätzlicher öffentlicher Funktionsvertrag. Dependency: SAFE Status-TVFs
und ResultTable-Helper. Reservierte Tempnamen prüft der öffentliche Wrapper
vor EXEC; hier erfolgt die erste Kompilierung der fachlichen Tempstatements.
Erwartete Inputfehler vor Mutation; eigene Transaktion oder Caller-Savepoint.
Direkter Aufruf ist intern, keine Grant-Zusage.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_file.USP_InternalXlsxRead
(
    @ReadCells bit = NULL,
    @XlsxBinary varbinary(max) = NULL,
    @SheetOrdinal int = NULL,
    @MaxArchiveBytes bigint = 16777216,
    @MaxPartBytes bigint = 16777216,
    @MaxTotalUncompressedBytes bigint = 67108864,
    @MaxParts int = 256,
    @MaxSheets int = 32,
    @MaxCells int = 100000,
    @MaxSharedStrings int = 50000,
    @MaxSharedStringBytes bigint = 8388608,
    @MaxXmlDepth int = 64,
    @MaxCompressionRatio decimal(18,4) = 200,
    @BudgetMilliseconds int = 5000,
    @ResultTable sysname = NULL,
    @KeepData bit = 0,
    @Debug tinyint = 0,
    @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        DECLARE @Help TABLE
        (HelpContractVersion varchar(16) NOT NULL DEFAULT '1.0',
         SchemaName sysname NOT NULL DEFAULT N'toolbelt_file',
         ObjectName sysname NOT NULL DEFAULT N'USP_InternalXlsxRead',
         Section varchar(32) NOT NULL, Ordinal int NOT NULL, ItemName sysname NULL,
         SqlDataType varchar(256) NULL, IsRequired bit NULL, IsNullable bit NULL,
         DefaultValue nvarchar(4000) NULL, Description nvarchar(max) NOT NULL, ExampleSql nvarchar(max) NULL);
        INSERT @Help (Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql) VALUES
        ('PARAMETER',1,N'@ReadCells','bit',1,0,N'NULL',N'Interner Modus: 0 Sheetliste, 1 Zellliste; öffentliche USPs bevorzugen.',NULL),
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.',NULL),
        ('PARAMETER',2,N'@XlsxBinary','varbinary(max)',0,1,N'NULL',N'NULL liefert keine Zeilen und verändert kein ResultTable.',NULL),
        ('PARAMETER',3,N'@SheetOrdinal','int',1,0,N'NULL',N'Positive Worksheetposition aus ListXlsxWorksheets.',NULL),
        ('PARAMETER',4,N'@MaxArchiveBytes','bigint',0,0,N'16777216',N'Containerbytes, höchstens 16 MiB.',NULL),
        ('PARAMETER',5,N'@MaxPartBytes','bigint',0,0,N'16777216',N'Unkomprimierte Bytes je Part, höchstens 16 MiB.',NULL),
        ('PARAMETER',6,N'@MaxTotalUncompressedBytes','bigint',0,0,N'67108864',N'Deklarierte Gesamtbytes, höchstens 64 MiB.',NULL),
        ('PARAMETER',7,N'@MaxParts','int',0,0,N'256',N'ZIP-Parts, höchstens 256.',NULL),
        ('PARAMETER',8,N'@MaxSheets','int',0,0,N'32',N'Worksheets, höchstens 32.',NULL),
        ('PARAMETER',9,N'@MaxCells','int',0,0,N'100000',N'Vorhandene Zellen im gewählten Sheet, höchstens 100000.',NULL),
        ('PARAMETER',10,N'@MaxSharedStrings','int',0,0,N'50000',N'Shared Strings, höchstens 50000.',NULL),
        ('PARAMETER',11,N'@MaxSharedStringBytes','bigint',0,0,N'8388608',N'Dekodierter Shared-String-UTF16-Text, höchstens 8 MiB.',NULL),
        ('PARAMETER',12,N'@MaxXmlDepth','int',0,0,N'64',N'XML-Tiefe, höchstens 64.',NULL),
        ('PARAMETER',13,N'@MaxCompressionRatio','decimal(18,4)',0,0,N'200',N'Maximales deklarierter Ratio, höchstens 200.',NULL),
        ('PARAMETER',14,N'@BudgetMilliseconds','int',0,0,N'5000',N'Kooperatives Gesamtbudget, höchstens 5000 ms; keine harte Wallclockzusage.',NULL),
        ('PARAMETER',15,N'@ResultTable','sysname',0,1,N'NULL',N'Vorhandene caller-lokale Temp-Tabelle, sonst SELECT.',NULL),
        ('PARAMETER',16,N'@KeepData','bit',0,1,N'0',N'Replace 0 oder Append 1; NULL entspricht 0.',NULL),
        ('PARAMETER',17,N'@Debug','tinyint',0,1,N'0',N'Nur Messages ohne Workbookinhalte.',NULL),
        ('PARAMETER',18,N'@Hilfe','bit',0,1,N'0',N'Ausschließlich standardisierte Hilfe.',NULL),
        ('RESULT_COLUMN',1,N'RowOrdinal','int',1,0,NULL,N'Einsbasierte Zeile.',NULL),
        ('RESULT_COLUMN',2,N'ColumnOrdinal','int',1,0,NULL,N'Einsbasierte Spalte.',NULL),
        ('RESULT_COLUMN',3,N'StoredType','nvarchar(16)',1,0,NULL,N'Gespeicherter Zelltyp, keine Typinferenz.',NULL),
        ('RESULT_COLUMN',4,N'ValuePresent','bit',1,0,NULL,N'Gespeichertes v-Element vorhanden, auch wenn leer.',NULL),
        ('RESULT_COLUMN',5,N'RawValue','nvarchar(max)',1,1,NULL,N'Rohtext aus v, NULL bei fehlendem v.',NULL),
        ('RESULT_COLUMN',6,N'TextValue','nvarchar(max)',1,1,NULL,N'Shared-/Inline-/str-Text, kein Excel-Anzeigeformat.',NULL),
        ('RESULT_COLUMN',7,N'FormulaPresent','bit',1,0,NULL,N'f-Element vorhanden.',NULL),
        ('RESULT_COLUMN',8,N'FormulaText','nvarchar(max)',1,1,NULL,N'Unveränderter Formeltext, keine Berechnung.',NULL),
        ('RESULT_COLUMN',9,N'FormulaKind','nvarchar(16)',1,1,NULL,N'normal, shared, array oder dataTable.',NULL),
        ('RESULT_COLUMN',10,N'SharedFormulaIndex','int',1,1,NULL,N'Gespeichertes si, keine Formelrekonstruktion.',NULL),
        ('RESULT_COLUMN',11,N'CachePresent','bit',1,0,NULL,N'Formel und v-Element vorhanden.',NULL),
        ('RESULT_COLUMN',12,N'CacheValue','nvarchar(max)',1,1,NULL,N'Gespeicherter Formelcache-Rohtext.',NULL),
        ('ERROR',1,N'51520',NULL,NULL,NULL,NULL,N'Begrenzte Kategorie eines erwarteten Input-/Container-/XML-/Feature-/Ressourcenfehlers; keine Teilausgabe.',NULL),
        ('ERROR',2,N'51529',NULL,NULL,NULL,NULL,N'Fehlende oder inkonsistente registrierte Dependency bzw. interner Providervertrag.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE auf USP; ResultTable zusätzlich Helper-EXECUTE und Sichtbarkeit der caller-lokalen Tabelle. Keine Rechteausweitung.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Transitional XLSX, klassische Stored-/Deflate-ZIPs. Kein ZIP64, externe Beziehungen, Makros oder Strict Open XML. Unicode bleibt unverändert, Tabellen brauchen explizite Ordinals zum Sortieren.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hilfe ohne fachliche Eingaben.',N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;');
        -- Technische Hilfe benennt die tatsächliche Modus-0-Resultshape;
        -- ohne expliziten Modus bleibt die dokumentierte Zellshape sichtbar.
        IF @ReadCells=0
        BEGIN
            DELETE FROM @Help WHERE Section='RESULT_COLUMN';
            UPDATE @Help SET IsRequired=0,IsNullable=1,
                Description=N'Für den Sheetlistenmodus nicht verwendet.'
                WHERE Section='PARAMETER' AND ItemName=N'@SheetOrdinal';
            INSERT @Help (Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql) VALUES
            ('RESULT_COLUMN',1,N'SheetOrdinal','int',1,0,NULL,N'Einsbasierte Worksheetposition.',NULL),
            ('RESULT_COLUMN',2,N'SheetName','nvarchar(max)',1,0,NULL,N'Unveränderter Worksheetname.',NULL),
            ('RESULT_COLUMN',3,N'Visibility','nvarchar(16)',1,0,NULL,N'visible, hidden oder veryHidden.',NULL),
            ('RESULT_COLUMN',4,N'Date1904','bit',1,0,NULL,N'Gespeichertes Workbook-Datumssystem.',NULL);
        END;
        SELECT HelpContractVersion,SchemaName,ObjectName,
               Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
           WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5
           WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
        RETURN 0;
    END;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0);
    IF @ReadCells IS NULL THROW 51529,N'Interner XLSX-Routingmodus fehlt.',1;
    IF @ReadCells=0
    BEGIN
    CREATE TABLE #tbx_ListXlsxWorksheets_ResultSource
    (
        [SheetOrdinal] int NOT NULL,
        [SheetName] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
        [Visibility] nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
        [Date1904] bit NOT NULL
    );
    IF @XlsxBinary IS NULL
    BEGIN
        IF @ResultTable IS NULL SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM #tbx_ListXlsxWorksheets_ResultSource;
        RETURN 0;
    END;
    IF OBJECT_ID(N'toolbelt_file.TVF_InternalXlsxSheets',N'FT') IS NULL
        THROW 51529,N'Der interne XLSX-Provider fehlt.',1;
    DECLARE @SheetsSnapshot TABLE
    (ErrorNumber int NULL, ErrorMessage nvarchar(4000) NULL,
        [SheetOrdinal] int NULL,
        [SheetName] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [Visibility] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [Date1904] bit NULL
    );
    INSERT @SheetsSnapshot SELECT ErrorNumber,ErrorMessage,[SheetOrdinal],[SheetName],[Visibility],[Date1904]
    FROM toolbelt_file.TVF_InternalXlsxSheets(@XlsxBinary,@MaxArchiveBytes,@MaxPartBytes,@MaxTotalUncompressedBytes,@MaxParts,@MaxSheets,@MaxCells,@MaxSharedStrings,@MaxSharedStringBytes,@MaxXmlDepth,@MaxCompressionRatio,@BudgetMilliseconds);
    IF EXISTS(SELECT 1 FROM @SheetsSnapshot WHERE ErrorNumber IS NOT NULL)
    BEGIN
        IF (SELECT COUNT_BIG(*) FROM @SheetsSnapshot)<>1
            THROW 51529,N'Inkonsistenter XLSX-Statusvertrag.',1;
        DECLARE @SheetsError int,@SheetsMessage nvarchar(2048);
        SELECT @SheetsError=ErrorNumber,@SheetsMessage=CONVERT(nvarchar(2048),ErrorMessage) FROM @SheetsSnapshot;
        IF @SheetsError<>51520 OR @SheetsMessage IS NULL
            THROW 51529,N'Ungültiger XLSX-Statusvertrag.',1;
        THROW @SheetsError,@SheetsMessage,1;
    END;
    IF EXISTS(SELECT 1 FROM @SheetsSnapshot WHERE [SheetOrdinal] IS NULL OR [SheetName] IS NULL OR [Visibility] IS NULL OR [Date1904] IS NULL)
        THROW 51529,N'Unvollständige XLSX-Datenzeile.',1;
    INSERT #tbx_ListXlsxWorksheets_ResultSource([SheetOrdinal],[SheetName],[Visibility],[Date1904]) SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM @SheetsSnapshot;
    IF @Debug>0 RAISERROR(N'XLSX: validierter Ergebnissnapshot bereit.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM #tbx_ListXlsxWorksheets_ResultSource ORDER BY SheetOrdinal;
        RETURN 0;
    END;
    DECLARE @SheetsDependencyVersion nvarchar(64),@SheetsDependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
    SELECT @SheetsDependencyVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
    WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
    DECLARE @SheetsMajor int=TRY_CONVERT(int,PARSENAME(@SheetsDependencyVersion,3)),
            @SheetsMinor int=TRY_CONVERT(int,PARSENAME(@SheetsDependencyVersion,2)),
            @SheetsPatch int=TRY_CONVERT(int,PARSENAME(@SheetsDependencyVersion,1));
    IF @SheetsDependencyId IS NULL OR @SheetsMajor IS NULL OR @SheetsMajor<1 OR @SheetsMinor IS NULL OR @SheetsMinor<0 OR @SheetsPatch IS NULL OR @SheetsPatch<0
       OR CONVERT(varbinary(max),@SheetsDependencyVersion)<>CONVERT(varbinary(max),CONCAT(@SheetsMajor,N'.',@SheetsMinor,N'.',@SheetsPatch))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@SheetsDependencyId AND minor_id=0
           AND name=N'Toolbelt.ModuleId' AND TRY_CONVERT(nvarchar(128),value)=N'toolbelt.core.result-table')
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@SheetsDependencyId AND minor_id=0
           AND name=N'Toolbelt.ModuleVersion'
           AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@SheetsDependencyVersion))
        THROW 51529,N'ResultTable-Dependency >= 1.0.0 fehlt oder ist ungeeignet.',1;
    DECLARE @SheetsOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @SheetsSavepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-',''),@SheetsSavepointSet bit=0;
    BEGIN TRY
        IF @SheetsOwnTransaction=1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @SheetsSavepoint; SET @SheetsSavepointSet=1; END;
        EXEC toolbelt_core.USP_PrepareResultTable
             @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ListXlsxWorksheets_ResultSource',
             @KeepData=@KeepData,@Debug=@Debug;
        DECLARE @SheetsSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)
           +N' ([SheetOrdinal],[SheetName],[Visibility],[Date1904]) SELECT [SheetOrdinal],[SheetName],[Visibility],[Date1904] FROM #tbx_ListXlsxWorksheets_ResultSource;';
        EXEC sys.sp_executesql @SheetsSql;
        IF @SheetsOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @SheetsOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @SheetsSavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @SheetsSavepoint;
        THROW;
    END CATCH;
    RETURN 0;

    END
    ELSE
    BEGIN
    CREATE TABLE #tbx_ReadXlsxWorksheetCells_ResultSource
    (
        [RowOrdinal] int NOT NULL,
        [ColumnOrdinal] int NOT NULL,
        [StoredType] nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
        [ValuePresent] bit NOT NULL,
        [RawValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [TextValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaPresent] bit NOT NULL,
        [FormulaText] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaKind] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [SharedFormulaIndex] int NULL,
        [CachePresent] bit NOT NULL,
        [CacheValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL
    );
    IF @XlsxBinary IS NULL
    BEGIN
        IF @ResultTable IS NULL SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM #tbx_ReadXlsxWorksheetCells_ResultSource;
        RETURN 0;
    END;
    IF OBJECT_ID(N'toolbelt_file.TVF_InternalXlsxCells',N'FT') IS NULL
        THROW 51529,N'Der interne XLSX-Provider fehlt.',1;
    DECLARE @CellsSnapshot TABLE
    (ErrorNumber int NULL, ErrorMessage nvarchar(4000) NULL,
        [RowOrdinal] int NULL,
        [ColumnOrdinal] int NULL,
        [StoredType] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [ValuePresent] bit NULL,
        [RawValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [TextValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaPresent] bit NULL,
        [FormulaText] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        [FormulaKind] nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,
        [SharedFormulaIndex] int NULL,
        [CachePresent] bit NULL,
        [CacheValue] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL
    );
    INSERT @CellsSnapshot SELECT ErrorNumber,ErrorMessage,[RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue]
    FROM toolbelt_file.TVF_InternalXlsxCells(@XlsxBinary,@SheetOrdinal,@MaxArchiveBytes,@MaxPartBytes,@MaxTotalUncompressedBytes,@MaxParts,@MaxSheets,@MaxCells,@MaxSharedStrings,@MaxSharedStringBytes,@MaxXmlDepth,@MaxCompressionRatio,@BudgetMilliseconds);
    IF EXISTS(SELECT 1 FROM @CellsSnapshot WHERE ErrorNumber IS NOT NULL)
    BEGIN
        IF (SELECT COUNT_BIG(*) FROM @CellsSnapshot)<>1
            THROW 51529,N'Inkonsistenter XLSX-Statusvertrag.',1;
        DECLARE @CellsError int,@CellsMessage nvarchar(2048);
        SELECT @CellsError=ErrorNumber,@CellsMessage=CONVERT(nvarchar(2048),ErrorMessage) FROM @CellsSnapshot;
        IF @CellsError<>51520 OR @CellsMessage IS NULL
            THROW 51529,N'Ungültiger XLSX-Statusvertrag.',1;
        THROW @CellsError,@CellsMessage,1;
    END;
    IF EXISTS(SELECT 1 FROM @CellsSnapshot WHERE [RowOrdinal] IS NULL OR [ColumnOrdinal] IS NULL OR [StoredType] IS NULL OR [ValuePresent] IS NULL OR [FormulaPresent] IS NULL OR [CachePresent] IS NULL)
        THROW 51529,N'Unvollständige XLSX-Datenzeile.',1;
    INSERT #tbx_ReadXlsxWorksheetCells_ResultSource([RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue]) SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM @CellsSnapshot;
    IF @Debug>0 RAISERROR(N'XLSX: validierter Ergebnissnapshot bereit.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM #tbx_ReadXlsxWorksheetCells_ResultSource ORDER BY RowOrdinal,ColumnOrdinal;
        RETURN 0;
    END;
    DECLARE @CellsDependencyVersion nvarchar(64),@CellsDependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
    SELECT @CellsDependencyVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
    WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
    DECLARE @CellsMajor int=TRY_CONVERT(int,PARSENAME(@CellsDependencyVersion,3)),
            @CellsMinor int=TRY_CONVERT(int,PARSENAME(@CellsDependencyVersion,2)),
            @CellsPatch int=TRY_CONVERT(int,PARSENAME(@CellsDependencyVersion,1));
    IF @CellsDependencyId IS NULL OR @CellsMajor IS NULL OR @CellsMajor<1 OR @CellsMinor IS NULL OR @CellsMinor<0 OR @CellsPatch IS NULL OR @CellsPatch<0
       OR CONVERT(varbinary(max),@CellsDependencyVersion)<>CONVERT(varbinary(max),CONCAT(@CellsMajor,N'.',@CellsMinor,N'.',@CellsPatch))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@CellsDependencyId AND minor_id=0
           AND name=N'Toolbelt.ModuleId' AND TRY_CONVERT(nvarchar(128),value)=N'toolbelt.core.result-table')
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@CellsDependencyId AND minor_id=0
           AND name=N'Toolbelt.ModuleVersion'
           AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@CellsDependencyVersion))
        THROW 51529,N'ResultTable-Dependency >= 1.0.0 fehlt oder ist ungeeignet.',1;
    DECLARE @CellsOwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @CellsSavepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-',''),@CellsSavepointSet bit=0;
    BEGIN TRY
        IF @CellsOwnTransaction=1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @CellsSavepoint; SET @CellsSavepointSet=1; END;
        EXEC toolbelt_core.USP_PrepareResultTable
             @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_ReadXlsxWorksheetCells_ResultSource',
             @KeepData=@KeepData,@Debug=@Debug;
        DECLARE @CellsSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)
           +N' ([RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue]) SELECT [RowOrdinal],[ColumnOrdinal],[StoredType],[ValuePresent],[RawValue],[TextValue],[FormulaPresent],[FormulaText],[FormulaKind],[SharedFormulaIndex],[CachePresent],[CacheValue] FROM #tbx_ReadXlsxWorksheetCells_ResultSource;';
        EXEC sys.sp_executesql @CellsSql;
        IF @CellsOwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @CellsOwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @CellsSavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @CellsSavepoint;
        THROW;
    END CATCH;
    RETURN 0;

    END;
END;
GO
