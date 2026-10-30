-- ============================================================================
-- Objekt: toolbelt_file.USP_WriteCsv; Typ: Stored Procedure
-- Zweck: Rechteckige Textzellen kanonisch zu CSV im Speicher schreiben.
-- Vertrag: CSV_MEMORY_CONTRACT.md; USP_CONTRACT 1.0
-- Parameter: @CellsTable sysname=NULL; @Separator nvarchar(2)=N','; @HasHeader bit=0; @NullToken nvarchar(128)=NULL; @LineEnding varchar(4)='CRLF'; @MaxRows bigint=100000; @MaxColumns int=1024; @MaxCells bigint=1000000; @MaxValueBytes bigint=16777216; @MaxOutputBytes bigint=16777216; @ResultTable sysname=NULL; @KeepData bit=0; @Debug tinyint=0; @Hilfe bit=0
-- Resultset: CsvText nvarchar(max) NOT NULL; DataRows bigint NOT NULL; ColumnCount int NOT NULL
-- Dependencies: eigene SAFE-CLR-Bindungen; ResultTable >=1.0.0 same_database.
-- Rechte: EXECUTE, caller-lokale Temps; keine Rechtevergabe.
-- Versionen/Plattformen: SQL Server 2019+ CL150+, Windows/Linux; Qualifikation separat.
-- Fehler: 55300..55309; Originalenginefehler; eigene Transaktion oder Caller-Savepoint.
-- Performance: begrenzte private Snapshots, vollständige Charge vor Output; kein Heap-/Grantversprechen.
-- Grenzen: kein Datei-/Netzwerk-I/O, Casting oder Datenbereinigung.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_file.USP_WriteCsv
 @CellsTable sysname=NULL,
 @Separator nvarchar(2)=N',',
 @HasHeader bit=0,
 @NullToken nvarchar(128)=NULL,
 @LineEnding varchar(4)='CRLF',
 @MaxRows bigint=100000,
 @MaxColumns int=1024,
 @MaxCells bigint=1000000,
 @MaxValueBytes bigint=16777216,
 @MaxOutputBytes bigint=16777216,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF @Hilfe=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_file' AS sysname) AS SchemaName,
            CAST(N'USP_WriteCsv' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Rechteckige Textzellen kanonisch zu CSV im Speicher schreiben.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'CsvText', N'nvarchar(max)', 1, 0, NULL, CAST(N'Vollständiger CSV-Text; leere Quelle ohne Header ergibt leer.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'DataRows', N'bigint', 1, 0, NULL, CAST(N'Anzahl DATA-Records.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'ColumnCount', N'int', 1, 0, NULL, CAST(N'Rechteckige Breite; leere Quelle ohne Header ergibt 0.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'55300..55309', NULL, NULL, NULL, NULL, CAST(N'Begrenzte Argument-/Syntax-/Form-/Budget-/Transportfehler; ursprüngliche Enginefehler bleiben erhalten.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und sichtbare eigene lokale Temps; ResultTable zusätzlich vorhandene Helperberechtigung. Keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'In-memory UTF-16; kein I/O, Casting, Trim oder Streaming. NUL/unpaired Surrogate bleiben Zelltext.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Hilfe ohne fachliche Eingaben.' AS nvarchar(max)), CAST(N'EXEC toolbelt_file.USP_WriteCsv @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@CellsTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene caller-lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name/#tbx_-Präfix. Genau vier sichtbare nicht-computed Basisspalten ohne Alias-/Zusatzspalten: RowKind varchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max). RowKind bytegenau DATA = Datenrecord oder HEADER = Headerrecord; RowKind/Ordinals nicht NULL. HEADER nur bei HasHeader=1 mit RowOrdinal=0; DATA-Ordinals lückenlos 1..n, Spalten lückenlos 1..Breite und jede Zellposition eindeutig. DATA-Value darf nur bei aktivem NullToken NULL sein, HEADER niemals. Leere Quelle nur ohne Header zulässig; keine Mutation/Quell-Ziel-Identität.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Separator', N'nvarchar(2)', 0, 0, N'N'',''', CAST(N'Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@HasHeader', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 kein Header (Default); 1 erster Record als HEADER/RowOrdinal 0, DATA beginnt bei 1. NULL ist ungültig und kein Default. Header zählt zu MaxCells, nicht zu MaxRows. Writer verlangt bei 1 einen vollständigen nicht-NULL-Header.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@NullToken', N'nvarchar(128)', 0, 1, N'NULL', CAST(N'NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@LineEnding', N'varchar(4)', 0, 0, N'''CRLF''', CAST(N'Taxativ, bytegenau ohne Trim: CRLF (Default) = U+000D gefolgt von U+000A; LF = nur U+000A. Jeder ausgegebene Record einschließlich des letzten erhält diesen Abschluss. NULL/leer/andere Schreibweisen ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxRows', N'bigint', 0, 0, N'100000', CAST(N'Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxColumns', N'int', 0, 0, N'1024', CAST(N'Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxCells', N'bigint', 0, 0, N'1000000', CAST(N'Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@MaxValueBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216 UTF-16-Snapshotbytes als Summe DATALENGTH(Value), Default 16777216. NULL-Zellen zählen 0; NULL/außerhalb beim Budget ist ungültig. Keine zusätzliche einzelne Zellgrenze außerhalb dieses Gesamtbudgets.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@MaxOutputBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216 UTF-16-Bytes des gesamten CsvText, Default 16777216. Einschließlich Quoteverdopplung, Hüllen, NullTokens, Separatoren und sämtlicher Recordabschlüsse. NULL/außerhalb ungültig; vor Allokation/Veröffentlichung exakt gemessen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei >0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 14, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0);
 IF XACT_STATE()=-1 THROW 55309,N'CSV: Callertransaktion ist uncommittable.',1;
 IF @HasHeader IS NULL THROW 55300,N'CSV: erforderlicher Text oder Headerflag fehlt.',1;
 IF @MaxRows IS NULL OR @MaxRows NOT BETWEEN 1 AND 100000
 OR @MaxColumns IS NULL OR @MaxColumns NOT BETWEEN 1 AND 1024
 OR @MaxCells IS NULL OR @MaxCells NOT BETWEEN 1 AND 1000000
 OR @MaxValueBytes IS NULL OR @MaxValueBytes NOT BETWEEN 1 AND 16777216
 OR @MaxOutputBytes IS NULL OR @MaxOutputBytes NOT BETWEEN 1 AND 16777216
  THROW 55303,N'CSV: Ressourcenparameter ist ungültig.',1;
 IF @CellsTable IS NULL OR DATALENGTH(@CellsTable) NOT BETWEEN 4 AND 232 OR LEFT(@CellsTable,1) COLLATE Latin1_General_100_BIN2<>N'#' OR LEFT(@CellsTable,2) COLLATE Latin1_General_100_BIN2=N'##' OR QUOTENAME(@CellsTable) IS NULL
  THROW 55304,N'CSV: caller-lokaler Tempname erforderlich.',1;
 IF @LineEnding IS NULL OR CONVERT(varbinary(max),@LineEnding) NOT IN(0x43524C46,0x4C46) THROW 55300,N'CSV: LineEnding muss exakt CRLF oder LF sein.',1;
 -- Namespacegrenze VOR separater Workbatch-Kompilierung: kein Caller-Temp-Eclipsing.
 IF (@ResultTable IS NOT NULL AND LOWER(LEFT(@ResultTable COLLATE Latin1_General_100_BIN2,5))=N'#tbx_')
 OR LOWER(LEFT(@CellsTable COLLATE Latin1_General_100_BIN2,5))=N'#tbx_'
 OR OBJECT_ID(N'tempdb..#tbx_CsvWrite_Input',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_CsvWrite_Measure',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_CsvWrite_Fragments',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_CsvWrite_Records',N'U') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#tbx_CsvWrite_Result',N'U') IS NOT NULL
  THROW 55304,N'CSV: reservierter privater Tempnamensbereich ist belegt.',1;
 IF OBJECT_ID(N'toolbelt_file.SVF_InternalMeasureCsvCell',N'FS') IS NULL OR OBJECT_ID(N'toolbelt_file.SVF_InternalQuoteCsvCell',N'FS') IS NULL
  THROW 55309,N'CSV: interne CLR-Bindung fehlt.',1;
 -- Fester vertrauenswürdiger SQL-Text; sämtliche Callerwerte sind gebundene Parameter.
 DECLARE @WorkSql nvarchar(max)=N'IF @ResultTable IS NOT NULL
 BEGIN
  DECLARE @CoreId int=OBJECT_ID(N''toolbelt_core.USP_PrepareResultTable'',N''P''),@CoreVersion nvarchar(64),@Major int,@Minor int,@Patch int;
  SELECT @CoreVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N''Toolbelt.Module.toolbelt.core.result-table.Version'';
  SELECT @Major=TRY_CONVERT(int,PARSENAME(@CoreVersion,3)),@Minor=TRY_CONVERT(int,PARSENAME(@CoreVersion,2)),@Patch=TRY_CONVERT(int,PARSENAME(@CoreVersion,1));
  IF @CoreId IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
   OR CONVERT(varbinary(max),@CoreVersion)<>CONVERT(varbinary(max),CONCAT(@Major,N''.'',@Minor,N''.'',@Patch))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@CoreId AND minor_id=0 AND name=N''Toolbelt.ModuleId'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N''toolbelt.core.result-table''))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@CoreId AND minor_id=0 AND name=N''Toolbelt.ModuleVersion'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@CoreVersion))
   THROW 55309,N''CSV: registrierte ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.'',1;
 END;
 DECLARE @InputId int=OBJECT_ID(N''tempdb..''+QUOTENAME(@CellsTable),N''U'');
 IF @InputId IS NULL THROW 55304,N''CSV: caller-lokale Quelle fehlt oder ist nicht sichtbar.'',1;
 IF @ResultTable IS NOT NULL AND OBJECT_ID(N''tempdb..''+QUOTENAME(@ResultTable),N''U'')=@InputId THROW 55308,N''CSV: Quelle und ResultTable sind identisch.'',1;
 DECLARE @Expected TABLE(Name sysname NOT NULL,TypeId int NOT NULL,Length smallint NOT NULL);
 INSERT @Expected VALUES(N''RowKind'',167,6),(N''RowOrdinal'',127,8),(N''ColumnOrdinal'',56,4),(N''Value'',231,-1);
 IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@InputId)<>4
 OR EXISTS(SELECT 1 FROM @Expected e WHERE NOT EXISTS(SELECT 1 FROM tempdb.sys.columns c WHERE c.object_id=@InputId
  AND CONVERT(varbinary(256),c.name)=CONVERT(varbinary(256),e.Name) AND c.system_type_id=e.TypeId
  AND c.user_type_id=c.system_type_id AND c.max_length=e.Length AND c.is_computed=0 AND c.is_hidden=0))
  THROW 55305,N''CSV: Quelle benötigt genau die vier eingebauten Zellspalten.'',1;
 DECLARE @Probe bigint=toolbelt_file.SVF_InternalMeasureCsvCell(N'''',@Separator,@NullToken,CONVERT(bit,0)),@ErrorCode int;
 IF @Probe IS NULL OR (@Probe<0 AND @Probe NOT BETWEEN -55309 AND -55300) OR @Probe>0 THROW 55309,N''CSV: interner Messstatus ungültig.'',1;
 IF @Probe<0
 BEGIN
  SET @ErrorCode=TRY_CONVERT(int,-CONVERT(decimal(38,0),@Probe));
  DECLARE @ErrorMessage nvarchar(2048)=CASE @ErrorCode
 WHEN 55300 THEN N''CSV: ungültiges Pflichtargument oder Dialekt.''
 WHEN 55301 THEN N''CSV: ungültige Quote- oder Recordsyntax.''
 WHEN 55302 THEN N''CSV: Parserrecords sind nicht rechteckig.''
 WHEN 55303 THEN N''CSV: Ressourcenparameter oder Ressourcengrenze verletzt.''
 WHEN 55304 THEN N''CSV: zulässige caller-lokale Quelle fehlt.''
 WHEN 55305 THEN N''CSV: Quellmetadaten sind nicht exakt unterstützt.''
 WHEN 55306 THEN N''CSV: RowKind, Ordinals, Header oder Rechteck ungültig.''
 WHEN 55307 THEN N''CSV: SQL-NULL ist nicht darstellbar.''
 WHEN 55308 THEN N''CSV: Quelle und ResultTable sind identisch.''
 ELSE N''CSV: interner Transportvertrag verletzt.'' END;
 THROW @ErrorCode,@ErrorMessage,1;
 END;
 DECLARE @Own bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,@Saved bit=0,@Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),''-'',''''),@Sql nvarchar(max);
 BEGIN TRY
  IF @Own=1 BEGIN TRANSACTION; ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @Saved=1; END;
  -- Metadatencharge vor jeder LOB-Kopie, begrenzter Scan und stabiler Snapshot.
  DECLARE @Limit bigint=@MaxCells+1,@PreCells bigint,@PreBytes bigint,@PreDataRows bigint,@PreColumn int;
  SET @Sql=N''SELECT @c=COUNT_BIG(*),@b=COALESCE(SUM(CONVERT(bigint,DATALENGTH([Value]))),0),@r=COUNT_BIG(DISTINCT CASE WHEN CONVERT(varbinary(max),RowKind)=0x44415441 THEN RowOrdinal END),@k=MAX(ColumnOrdinal) FROM(SELECT TOP (@limit) RowKind,RowOrdinal,ColumnOrdinal,[Value] FROM ''+QUOTENAME(@CellsTable)+N'' WITH(TABLOCK,HOLDLOCK)) bounded;'';
  EXEC sys.sp_executesql @Sql,N''@limit bigint,@c bigint OUTPUT,@b bigint OUTPUT,@r bigint OUTPUT,@k int OUTPUT'',@Limit,@PreCells OUTPUT,@PreBytes OUTPUT,@PreDataRows OUTPUT,@PreColumn OUTPUT;
  IF @PreCells>@MaxCells OR @PreBytes>@MaxValueBytes OR @PreDataRows>@MaxRows OR @PreColumn>@MaxColumns THROW 55303,N''CSV: Zell-, Record-, Spalten- oder Snapshotbytegrenze überschritten.'',1;
  CREATE TABLE #tbx_CsvWrite_Input(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NULL,RowOrdinal bigint NULL,ColumnOrdinal int NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
  SET @Sql=N''INSERT #tbx_CsvWrite_Input(RowKind,RowOrdinal,ColumnOrdinal,[Value]) SELECT TOP (@limit) RowKind,RowOrdinal,ColumnOrdinal,[Value] FROM ''+QUOTENAME(@CellsTable)+N'' WITH(TABLOCK,HOLDLOCK);'';
  EXEC sys.sp_executesql @Sql,N''@limit bigint'',@Limit;
  IF (SELECT COUNT_BIG(*) FROM #tbx_CsvWrite_Input)>@MaxCells
   OR (SELECT COALESCE(SUM(CONVERT(bigint,DATALENGTH([Value]))),0) FROM #tbx_CsvWrite_Input)>@MaxValueBytes
   THROW 55303,N''CSV: Zell- oder Snapshotbytegrenze überschritten.'',1;
  IF EXISTS(SELECT 1 FROM #tbx_CsvWrite_Input WHERE RowKind IS NULL OR RowOrdinal IS NULL OR ColumnOrdinal IS NULL
   OR CONVERT(varbinary(max),RowKind) NOT IN(0x484541444552,0x44415441)
   OR ColumnOrdinal NOT BETWEEN 1 AND @MaxColumns
   OR (CONVERT(varbinary(max),RowKind)=0x484541444552 AND (@HasHeader=0 OR RowOrdinal<>0))
   OR (CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal<1))
   OR EXISTS(SELECT 1 FROM #tbx_CsvWrite_Input GROUP BY RowOrdinal,ColumnOrdinal HAVING COUNT_BIG(*)<>1)
   THROW 55306,N''CSV: RowKind, Ordinals oder Headerform ungültig.'',1;
  IF EXISTS(SELECT 1 FROM #tbx_CsvWrite_Input WHERE [Value] IS NULL AND (CONVERT(varbinary(max),RowKind)=0x484541444552 OR @NullToken IS NULL))
   THROW 55307,N''CSV: SQL-NULL ist nicht darstellbar.'',1;
  DECLARE @DataRows bigint=(SELECT COUNT_BIG(DISTINCT RowOrdinal) FROM #tbx_CsvWrite_Input WHERE CONVERT(varbinary(max),RowKind)=0x44415441),
   @ColumnCount int=COALESCE((SELECT MAX(ColumnOrdinal) FROM #tbx_CsvWrite_Input),0),
   @HeaderCells bigint=(SELECT COUNT_BIG(*) FROM #tbx_CsvWrite_Input WHERE CONVERT(varbinary(max),RowKind)=0x484541444552);
  IF @DataRows>@MaxRows THROW 55303,N''CSV: DATA-Recordgrenze überschritten.'',1;
  IF (@HasHeader=1 AND (@HeaderCells=0 OR @HeaderCells<>@ColumnCount)) OR (@HasHeader=0 AND @HeaderCells<>0)
   OR EXISTS(SELECT 1 FROM #tbx_CsvWrite_Input GROUP BY RowOrdinal HAVING MIN(ColumnOrdinal)<>1 OR MAX(ColumnOrdinal)<>@ColumnCount OR COUNT_BIG(*)<>@ColumnCount)
   OR (@DataRows>0 AND ((SELECT MIN(RowOrdinal) FROM #tbx_CsvWrite_Input WHERE CONVERT(varbinary(max),RowKind)=0x44415441)<>1 OR (SELECT MAX(RowOrdinal) FROM #tbx_CsvWrite_Input WHERE CONVERT(varbinary(max),RowKind)=0x44415441)<>@DataRows))
   THROW 55306,N''CSV: Quelle ist kein vollständiges rechteckiges Zellraster.'',1;
  -- Das zuvor geprüfte eindeutige Zellraster auch für den vollständigen
  -- Fragment-/Maßabgleich indizieren und gezielte Zellzugriffe ermöglichen.
  -- Unbenannte Temp-Constraints vermeiden Namenskollisionen zwischen Sitzungen.
  CREATE TABLE #tbx_CsvWrite_Measure(RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,Bytes bigint NULL,PRIMARY KEY CLUSTERED(RowOrdinal,ColumnOrdinal));
  INSERT #tbx_CsvWrite_Measure SELECT RowOrdinal,ColumnOrdinal,toolbelt_file.SVF_InternalMeasureCsvCell([Value],@Separator,@NullToken,CONVERT(bit,CASE WHEN RowOrdinal=0 THEN 1 ELSE 0 END)) FROM #tbx_CsvWrite_Input;
  IF EXISTS(SELECT 1 FROM #tbx_CsvWrite_Measure WHERE Bytes IS NULL OR (Bytes<0 AND Bytes NOT BETWEEN -55309 AND -55300))
   THROW 55309,N''CSV: interner Messstatus ungültig.'',1;
  IF EXISTS(SELECT 1 FROM #tbx_CsvWrite_Measure WHERE Bytes<0)
  BEGIN
   SELECT TOP(1) @ErrorCode=TRY_CONVERT(int,-CONVERT(decimal(38,0),Bytes)) FROM #tbx_CsvWrite_Measure WHERE Bytes<0 ORDER BY RowOrdinal,ColumnOrdinal;
   DECLARE @MeasuredErrorMessage nvarchar(2048)=N''CSV: fachlicher Zellmessfehler.'';
   THROW @ErrorCode,@MeasuredErrorMessage,1;
  END;
  IF EXISTS(SELECT 1 FROM #tbx_CsvWrite_Measure WHERE Bytes>@MaxOutputBytes OR Bytes%2<>0)
   THROW 55303,N''CSV: Zelloutputgrenze überschritten.'',1;
  DECLARE @Records bigint=@DataRows+CASE WHEN @HasHeader=1 THEN 1 ELSE 0 END,
   @Ending nvarchar(2)=CASE WHEN CONVERT(varbinary(4),@LineEnding)=0x43524C46 THEN CONVERT(nvarchar(2),NCHAR(13)+NCHAR(10)) ELSE CONVERT(nvarchar(2),NCHAR(10)) END,@OutputBytes bigint;
  SELECT @OutputBytes=COALESCE(SUM(Bytes),0)+@Records*DATALENGTH(@Ending)+(@PreCells-@Records)*CONVERT(bigint,DATALENGTH(@Separator)) FROM #tbx_CsvWrite_Measure;
  IF @OutputBytes>@MaxOutputBytes THROW 55303,N''CSV: globale Outputbytegrenze überschritten.'',1;
  -- Erst der vollständige globale Charge-PASS erlaubt LOB-Fragmente und Aggregation.
  CREATE TABLE #tbx_CsvWrite_Fragments(RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,Fragment nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY CLUSTERED(RowOrdinal,ColumnOrdinal));
  INSERT #tbx_CsvWrite_Fragments SELECT RowOrdinal,ColumnOrdinal,toolbelt_file.SVF_InternalQuoteCsvCell([Value],@Separator,@NullToken,CONVERT(bit,CASE WHEN RowOrdinal=0 THEN 1 ELSE 0 END),@MaxOutputBytes) FROM #tbx_CsvWrite_Input;
  IF EXISTS(SELECT 1 FROM #tbx_CsvWrite_Fragments f JOIN #tbx_CsvWrite_Measure m ON m.RowOrdinal=f.RowOrdinal AND m.ColumnOrdinal=f.ColumnOrdinal WHERE f.Fragment IS NULL OR DATALENGTH(f.Fragment)<>m.Bytes)
   THROW 55309,N''CSV: Quotingcharge und Fragment weichen ab.'',1;
  CREATE TABLE #tbx_CsvWrite_Records(RowOrdinal bigint NOT NULL,RecordText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
  INSERT #tbx_CsvWrite_Records SELECT RowOrdinal,STRING_AGG(CONVERT(nvarchar(max),Fragment),@Separator) WITHIN GROUP(ORDER BY ColumnOrdinal) FROM #tbx_CsvWrite_Fragments GROUP BY RowOrdinal;
  CREATE TABLE #tbx_CsvWrite_Result(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
  INSERT #tbx_CsvWrite_Result SELECT COALESCE(STRING_AGG(CONVERT(nvarchar(max),RecordText)+@Ending,N'''') WITHIN GROUP(ORDER BY RowOrdinal),N''''),@DataRows,@ColumnCount FROM #tbx_CsvWrite_Records;
  IF (SELECT DATALENGTH(CsvText) FROM #tbx_CsvWrite_Result)<>@OutputBytes THROW 55309,N''CSV: globale Outputcharge weicht ab.'',1;
  IF @Debug>0 RAISERROR(N''CSV: vollständiges Writergebnis bereit.'',10,1) WITH NOWAIT;
  IF @ResultTable IS NOT NULL
  BEGIN
   EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N''#tbx_CsvWrite_Result'',@KeepData=@KeepData,@Debug=@Debug;
   SET @Sql=N''INSERT ''+QUOTENAME(@ResultTable)+N'' (CsvText,DataRows,ColumnCount) SELECT CsvText,DataRows,ColumnCount FROM #tbx_CsvWrite_Result;'';
   EXEC sys.sp_executesql @Sql;
  END;
  IF @Own=1 COMMIT TRANSACTION;
  IF @ResultTable IS NULL SELECT CsvText,DataRows,ColumnCount FROM #tbx_CsvWrite_Result;
 END TRY
 BEGIN CATCH
  IF @Own=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  ELSE IF @Saved=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
  THROW;
 END CATCH;';
 EXEC sys.sp_executesql @WorkSql,N'@CellsTable sysname,@Separator nvarchar(2),@HasHeader bit,@NullToken nvarchar(128),@LineEnding varchar(4),@MaxRows bigint,@MaxColumns int,@MaxCells bigint,@MaxValueBytes bigint,@MaxOutputBytes bigint,@ResultTable sysname,@KeepData bit,@Debug tinyint',
  @CellsTable=@CellsTable,@Separator=@Separator,@HasHeader=@HasHeader,@NullToken=@NullToken,@LineEnding=@LineEnding,@MaxRows=@MaxRows,@MaxColumns=@MaxColumns,@MaxCells=@MaxCells,@MaxValueBytes=@MaxValueBytes,@MaxOutputBytes=@MaxOutputBytes,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
 RETURN 0;
END;
GO
