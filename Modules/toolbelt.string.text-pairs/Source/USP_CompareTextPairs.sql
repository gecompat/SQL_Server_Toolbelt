-- Objekt: toolbelt_string.USP_CompareTextPairs; Version 1.0.0.
-- Vertrag: Documentation/Architecture/TEXT_PAIRS_CONTRACT.md.
-- Zweck: atomarer, begrenzter Batchwrapper über die drei bestehenden TVFs.
-- Rechte: EXECUTE, bestehende SELECT-/Ownershipchain; keine Rechteausweitung.
-- Fehler: 55100..55109; Fachcodes 0..6 unverändert, Enginefehler erhalten.
-- SQL Server 2019/2022/2025, Windows/Linux; Runtimequalifikation separat.
-- Keine Normalisierung, CPU-/Heap-/Hardwallzusage oder parallele MARS-Mutation.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_string.USP_CompareTextPairs
      @PairsTable sysname = NULL
    , @Algorithm nvarchar(max) = NULL
    , @MaxDistance int = NULL
    , @Profile nvarchar(max) = N'standard'
    , @MaxPairs int = 10000
    , @MaxTotalTextBytes bigint = 2097152
    , @MaxTotalWork bigint = 16777216
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);
    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_string' AS sysname) AS SchemaName,
            CAST(N'USP_CompareTextPairs' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'55100-55104', NULL, NULL, NULL, NULL, CAST(N'Algorithmus, globale Parameter, lokale Namen/Shape oder interne Tempkollision ungültig; kein fachliches Resultat.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'55105-55108', NULL, NULL, NULL, NULL, CAST(N'Admission/Stabilität/Ordinals/Work oder Providerkohärenz verletzt; keine Teilveröffentlichung. Engine-/Helperfehler bleiben erhalten.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Vorhandenes EXECUTE und bestehende TVF-/Helper-Rechte beziehungsweise Ownershipchain; caller-eigene Tempmetadaten. Keine Rechteerteilung und keine Runtime-Assemblyhash-/DB-VIEW-DEFINITION-Pflicht.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf ohne generisches INSERT EXEC.' AS nvarchar(max)), CAST(N'CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max)); INSERT #Pairs VALUES(1,N''kitten'',N''sitting''); EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N''#Pairs'',@Algorithm=N''levenshtein'';' AS nvarchar(max))),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Keine MARS-/parallele Mutation, keine globale/permanente Inputtable. Distributed Caller-Savepoints sind nicht unterstützt. Technische Fehler verwerfen den gesamten Aufruf.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'PairOrdinal', N'bigint', NULL, 0, NULL, CAST(N'Unveränderte Inputidentität; SELECT ordinal sortiert.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'Distance', N'int', NULL, 1, NULL, CAST(N'Distanzwert oder NULL; bei Jaro immer NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'ExceedsMaxDistance', N'bit', NULL, 1, NULL, CAST(N'Distanz-Thresholdnachweis oder NULL; bei Jaro immer NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'Similarity', N'float(53)', NULL, 1, NULL, CAST(N'Jaro-Winkler 0..1 oder NULL; bei Distanz immer NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'ErrorCode', N'int', NULL, 0, NULL, CAST(N'Kanonischer Fachcode 0..6; Jaro verwendet keinen Code 2.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@PairsTable', N'sysname', 1, 0, N'NULL', CAST(N'Vorhandene sichtbare lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name und kein reserviertes #tbx_-Präfix. Drei bytegenau benannte Basisspalten: PairOrdinal bigint, LeftText nvarchar(max), RightText nvarchar(max); zusätzliche Spalten sind erlaubt, Alias-/computed-/hidden-/generated-/verschlüsselte Vertragsspalten nicht. PairOrdinal muss pro Zeile nicht NULL und eindeutig sein (auch negative Werte erlaubt); Text-NULL und leere Tabelle sind erlaubt. NULL ist nur Help-Default, fachlich ungültig. Keine parallele Mutation.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Algorithm', N'nvarchar(max)', 1, 0, N'NULL', CAST(N'Taxativ, bytegenau ohne Trim: levenshtein = Einfügen/Löschen/Ersetzen; osa = zusätzlich eingeschränkte benachbarte Transposition; jaro-winkler = Ähnlichkeit mit Präfixbonus. NULL/leer/andere Schreibweisen ungültig. Bei jaro-winkler muss MaxDistance NULL sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@MaxDistance', N'int', 0, 1, N'NULL', CAST(N'NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift. Bei jaro-winkler ausschließlich NULL, jeder nicht-NULL-Wert wird bereits vor der Paarberechnung abgewiesen. Bei Distanzverfahren erfolgt die Schwellenvalidierung je Paar.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Profile', N'nvarchar(max)', 0, 1, N'N''standard''', CAST(N'Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. Wird je Paar vom Provider ausgewertet; eine leere Tabelle erzwingt keinen Profilfehler.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxPairs', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..100000 Paare, Default 10000; NULL/andere Werte ungültig. Mehr Inputzeilen werden vor Berechnung atomar abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxTotalTextBytes', N'bigint', 0, 0, N'2097152', CAST(N'Ganzzahl 1..16777216 Bytes für die Summe DATALENGTH(LeftText)+DATALENGTH(RightText) über alle Paare, Default 2097152. NULL/andere Werte ungültig. Ein nicht-NULL-Text zählt auch bei NULL-Gegenstück; keine Zeichenanzahl.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxTotalWork', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..67108864 konservative Admission-Arbeitseinheiten, Default 16777216. Pro Paar min(UTF-16-Länge links * Länge rechts, Profilcap 1048576 bzw. 16777216); bei einem NULL-Text 0. NULL/andere Werte ungültig. Zusätzlich gelten weiterhin die tatsächlichen Providerlimits je Paar.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Zusätzlich Name 2..116 UTF-16-Einheiten, kein #tbx_-Präfix und nicht dieselbe Tabelle wie PairsTable.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    -- RAISERROR+RETURN schützt den doomed Caller ohne zusätzliche XACT_ABORT-Wirkung.
    IF XACT_STATE() = -1
    BEGIN
        RAISERROR(N'USP_CompareTextPairs: uncommittable Caller-Transaktion.',16,1);
        RETURN 1;
    END;
    DECLARE @AlgorithmBytes varbinary(max) = CONVERT(varbinary(max),@Algorithm);
    IF @Algorithm IS NULL OR @AlgorithmBytes NOT IN
       (CONVERT(varbinary(max),N'levenshtein'),CONVERT(varbinary(max),N'osa'),CONVERT(varbinary(max),N'jaro-winkler'))
        THROW 55100,N'@Algorithm muss bytegenau levenshtein, osa oder jaro-winkler sein.',1;
    IF @AlgorithmBytes = CONVERT(varbinary(max),N'jaro-winkler') AND @MaxDistance IS NOT NULL
        THROW 55100,N'Jaro-Winkler unterstützt keine Distanzschwelle.',2;
    IF @MaxPairs IS NULL OR @MaxPairs NOT BETWEEN 1 AND 100000
       OR @MaxTotalTextBytes IS NULL OR @MaxTotalTextBytes NOT BETWEEN 1 AND 16777216
       OR @MaxTotalWork IS NULL OR @MaxTotalWork NOT BETWEEN 1 AND 67108864
        THROW 55101,N'Batchbudget fehlt oder überschreitet seinen zulässigen Bereich.',1;

    IF @PairsTable IS NULL OR DATALENGTH(@PairsTable) NOT BETWEEN 4 AND 232
       OR LEFT(@PairsTable,1) COLLATE Latin1_General_100_BIN2 <> N'#'
       OR LEFT(@PairsTable,2) COLLATE Latin1_General_100_BIN2 = N'##'
       OR LOWER(LEFT(@PairsTable,5) COLLATE Latin1_General_100_BIN2) = N'#tbx_'
       OR QUOTENAME(@PairsTable) IS NULL
        THROW 55102,N'@PairsTable muss eine vorhandene lokale #Temp ohne reservierten Präfix bezeichnen.',1;
    DECLARE @InputId int = OBJECT_ID(N'tempdb..'+QUOTENAME(@PairsTable),N'U'),
            @OutputId int, @Sql nvarchar(max), @Rows bigint, @Bytes bigint;
    IF @InputId IS NULL THROW 55102,N'Inputtable ist nicht sichtbar.',2;
    IF @ResultTable IS NOT NULL
    BEGIN
        IF DATALENGTH(@ResultTable) NOT BETWEEN 4 AND 232
           OR LEFT(@ResultTable,1) COLLATE Latin1_General_100_BIN2 <> N'#'
           OR LEFT(@ResultTable,2) COLLATE Latin1_General_100_BIN2 = N'##'
           OR LOWER(LEFT(@ResultTable,5) COLLATE Latin1_General_100_BIN2) = N'#tbx_'
           OR QUOTENAME(@ResultTable) IS NULL
            THROW 55102,N'@ResultTable muss eine vorhandene lokale #Temp ohne reservierten Präfix bezeichnen.',3;
        SET @OutputId = OBJECT_ID(N'tempdb..'+QUOTENAME(@ResultTable),N'U');
        IF @OutputId IS NULL OR @OutputId = @InputId
            THROW 55102,N'ResultTable fehlt oder bezeichnet die Inputtable.',4;
    END;
    IF (SELECT COUNT(*) FROM tempdb.sys.columns c WHERE c.object_id=@InputId
        AND CONVERT(varbinary(max),c.name) IN (CONVERT(varbinary(max),N'PairOrdinal'),CONVERT(varbinary(max),N'LeftText'),CONVERT(varbinary(max),N'RightText'))
        AND c.user_type_id=c.system_type_id AND c.is_computed=0 AND c.generated_always_type=0
        AND c.is_hidden=0 AND c.encryption_type IS NULL
        AND ((CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),N'PairOrdinal') AND c.system_type_id=127 AND c.max_length=8)
          OR (CONVERT(varbinary(max),c.name) IN (CONVERT(varbinary(max),N'LeftText'),CONVERT(varbinary(max),N'RightText')) AND c.system_type_id=231 AND c.max_length=-1))) <> 3
        THROW 55103,N'Input benötigt die drei bytegenau benannten Systemspalten bigint/nvarchar(max)/nvarchar(max).',1;
    IF OBJECT_ID(N'tempdb..#tbx_TextPairs_Input',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TextPairs_Stage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TextPairs_Result',N'U') IS NOT NULL
        THROW 55104,N'Reservierter interner Tempname kollidiert.',1;

    -- Admission liest LOB-Längen, kopiert noch keine Textpayloads.
    -- Die endliche Admission liest nur Längen. Restbudget vor jedem Add;
    -- frühes TOP begrenzt auch eine unerwartet große Inputtable auf MaxPairs+1.
    SET @Sql=N'DECLARE @NextBytes bigint;
SET @Rows=0; SET @Bytes=0; SET @Rejected=0;
DECLARE ByteAdmission CURSOR LOCAL FAST_FORWARD FOR
 SELECT TOP (@RowLimit) COALESCE(DATALENGTH(LeftText),CONVERT(bigint,0))+COALESCE(DATALENGTH(RightText),CONVERT(bigint,0)) FROM '+QUOTENAME(@PairsTable)+N';
OPEN ByteAdmission; FETCH NEXT FROM ByteAdmission INTO @NextBytes;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Rows+=1;
 IF @Rows>@PairLimit OR @NextBytes>@ByteLimit-@Bytes
 BEGIN SET @Rejected=1; BREAK; END;
 SET @Bytes+=@NextBytes;
 FETCH NEXT FROM ByteAdmission INTO @NextBytes;
END;
CLOSE ByteAdmission; DEALLOCATE ByteAdmission;';
    DECLARE @RowLimit int = @MaxPairs+1,@AdmissionRejected bit;
    EXEC sys.sp_executesql @Sql,N'@RowLimit int,@PairLimit int,@ByteLimit bigint,@Rows bigint OUTPUT,@Bytes bigint OUTPUT,@Rejected bit OUTPUT',
        @RowLimit,@MaxPairs,@MaxTotalTextBytes,@Rows OUTPUT,@Bytes OUTPUT,@AdmissionRejected OUTPUT;
    IF @AdmissionRejected IS NULL OR @AdmissionRejected<>0 OR @Rows>@MaxPairs OR @Bytes>@MaxTotalTextBytes
        THROW 55105,N'Zeilen- oder Textbytebudget überschritten.',1;
    CREATE TABLE #tbx_TextPairs_Input(PairOrdinal bigint NULL,LeftText nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,RightText nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
    SET @Sql=N'INSERT #tbx_TextPairs_Input(PairOrdinal,LeftText,RightText) SELECT TOP (@RowLimit) PairOrdinal,LeftText,RightText FROM '+QUOTENAME(@PairsTable)+N';';
    EXEC sys.sp_executesql @Sql,N'@RowLimit int',@RowLimit;
    DECLARE @SnapshotRows bigint,@SnapshotBytes bigint;
    SELECT @SnapshotRows=COUNT_BIG(*),@SnapshotBytes=COALESCE(SUM(COALESCE(DATALENGTH(LeftText),CONVERT(bigint,0))+COALESCE(DATALENGTH(RightText),CONVERT(bigint,0))),CONVERT(bigint,0)) FROM #tbx_TextPairs_Input;
    IF @SnapshotRows<>@Rows OR @SnapshotBytes<>@Bytes OR @SnapshotRows>@MaxPairs OR @SnapshotBytes>@MaxTotalTextBytes
        THROW 55105,N'Input ist während des Snapshots nicht stabil oder überschreitet das Budget.',2;
    IF EXISTS(SELECT 1 FROM #tbx_TextPairs_Input WHERE PairOrdinal IS NULL)
       OR EXISTS(SELECT PairOrdinal FROM #tbx_TextPairs_Input GROUP BY PairOrdinal HAVING COUNT_BIG(*)>1)
        THROW 55106,N'PairOrdinal muss nicht NULL und eindeutig sein.',1;
    DECLARE @PairCap bigint=CASE WHEN CONVERT(varbinary(max),@Profile)=CONVERT(varbinary(max),N'standard') THEN 1048576 ELSE 16777216 END,
            @TotalWork bigint=0,@LeftUnits bigint,@RightUnits bigint,@Charge bigint;
    -- nvarchar(max) maximal 1073741823 UTF16-Einheiten: das einzelne Produkt
    -- ist < 2^60. Nach Paircap höchstens 100000*16777216, also bigint-sicher.
    -- Der Admissioncursor liest nur Längen, führt keine Fachberechnung aus.
    DECLARE WorkAdmission CURSOR LOCAL FAST_FORWARD FOR
        SELECT DATALENGTH(LeftText)/2,DATALENGTH(RightText)/2 FROM #tbx_TextPairs_Input;
    OPEN WorkAdmission;
    FETCH NEXT FROM WorkAdmission INTO @LeftUnits,@RightUnits;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @Charge=CASE WHEN @LeftUnits IS NULL OR @RightUnits IS NULL THEN 0
            WHEN @LeftUnits*@RightUnits>@PairCap THEN @PairCap ELSE @LeftUnits*@RightUnits END;
        IF @Charge>@MaxTotalWork-@TotalWork
        BEGIN
            CLOSE WorkAdmission;
            DEALLOCATE WorkAdmission;
            THROW 55107,N'Konservatives Batchworkbudget überschritten.',1;
        END;
        SET @TotalWork+=@Charge;
        FETCH NEXT FROM WorkAdmission INTO @LeftUnits,@RightUnits;
    END;
    CLOSE WorkAdmission;
    DEALLOCATE WorkAdmission;
    CREATE TABLE #tbx_TextPairs_Stage(PairOrdinal bigint NULL,Distance int NULL,ExceedsMaxDistance bit NULL,Similarity float(53) NULL,ErrorCode int NULL);
    IF @AlgorithmBytes=CONVERT(varbinary(max),N'levenshtein')
        INSERT #tbx_TextPairs_Stage(PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode)
        SELECT p.PairOrdinal,f.Distance,f.ExceedsMaxDistance,NULL,f.ErrorCode FROM #tbx_TextPairs_Input p
        OUTER APPLY toolbelt_string.TVF_LevenshteinDistance(p.LeftText,p.RightText,@MaxDistance,@Profile) f;
    ELSE IF @AlgorithmBytes=CONVERT(varbinary(max),N'osa')
        INSERT #tbx_TextPairs_Stage(PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode)
        SELECT p.PairOrdinal,f.Distance,f.ExceedsMaxDistance,NULL,f.ErrorCode FROM #tbx_TextPairs_Input p
        OUTER APPLY toolbelt_string.TVF_OsaDistance(p.LeftText,p.RightText,@MaxDistance,@Profile) f;
    ELSE
        INSERT #tbx_TextPairs_Stage(PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode)
        SELECT p.PairOrdinal,NULL,NULL,f.Similarity,f.ErrorCode FROM #tbx_TextPairs_Input p
        OUTER APPLY toolbelt_string.TVF_JaroWinklerSimilarity(p.LeftText,p.RightText,@Profile) f;
    IF (SELECT COUNT_BIG(*) FROM #tbx_TextPairs_Stage)<>@SnapshotRows
       OR EXISTS(SELECT PairOrdinal FROM #tbx_TextPairs_Stage GROUP BY PairOrdinal HAVING COUNT_BIG(*)<>1)
       OR EXISTS(SELECT PairOrdinal FROM #tbx_TextPairs_Input EXCEPT SELECT PairOrdinal FROM #tbx_TextPairs_Stage)
       OR EXISTS(SELECT PairOrdinal FROM #tbx_TextPairs_Stage EXCEPT SELECT PairOrdinal FROM #tbx_TextPairs_Input)
        THROW 55108,N'Providerresultat verletzt die vollständige Ordinalrelation.',1;
    IF EXISTS
    (
        SELECT 1 FROM #tbx_TextPairs_Stage r JOIN #tbx_TextPairs_Input p ON p.PairOrdinal=r.PairOrdinal
        WHERE r.ErrorCode IS NULL OR r.ErrorCode NOT BETWEEN 0 AND 6
        OR (@AlgorithmBytes=CONVERT(varbinary(max),N'jaro-winkler') AND
            (r.ErrorCode=2 OR r.Distance IS NOT NULL OR r.ExceedsMaxDistance IS NOT NULL
             OR (r.ErrorCode<>0 AND r.Similarity IS NOT NULL)
             OR (r.ErrorCode=0 AND ((p.LeftText IS NULL OR p.RightText IS NULL) AND r.Similarity IS NOT NULL
                 OR (p.LeftText IS NOT NULL AND p.RightText IS NOT NULL) AND (r.Similarity IS NULL OR r.Similarity<0 OR r.Similarity>1)))))
        OR (@AlgorithmBytes<>CONVERT(varbinary(max),N'jaro-winkler') AND
            (r.Similarity IS NOT NULL OR (r.ErrorCode<>0 AND (r.Distance IS NOT NULL OR r.ExceedsMaxDistance IS NOT NULL))
             OR (r.ErrorCode=0 AND ((p.LeftText IS NULL OR p.RightText IS NULL) AND (r.Distance IS NOT NULL OR r.ExceedsMaxDistance IS NOT NULL)
                 OR (p.LeftText IS NOT NULL AND p.RightText IS NOT NULL) AND
                    (r.ExceedsMaxDistance IS NULL
                     OR (r.ExceedsMaxDistance=0 AND (r.Distance IS NULL OR r.Distance<0 OR (@MaxDistance IS NOT NULL AND r.Distance>@MaxDistance)))
                     OR (r.ExceedsMaxDistance=1 AND (r.Distance IS NOT NULL OR @MaxDistance IS NULL OR @MaxDistance<0)))))))
        OR ((p.LeftText IS NULL OR p.RightText IS NULL) AND r.ErrorCode<>0)
    ) THROW 55108,N'Providerresultat verletzt den kanonischen Wert-/NULL-/Fachcodevertrag.',2;
    CREATE TABLE #tbx_TextPairs_Result(PairOrdinal bigint NOT NULL,Distance int NULL,ExceedsMaxDistance bit NULL,Similarity float(53) NULL,ErrorCode int NOT NULL);
    INSERT #tbx_TextPairs_Result(PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode)
    SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #tbx_TextPairs_Stage;
    IF @Debug>0 RAISERROR(N'USP_CompareTextPairs: vollständiges Batchresultat materialisiert.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #tbx_TextPairs_Result ORDER BY PairOrdinal;
        RETURN 0;
    END;
    DECLARE @OwnTransaction bit=0,@Savepoint varchar(32)='tbx_pair_'+LEFT(REPLACE(CONVERT(varchar(36),NEWID()),'-',''),23);
    BEGIN TRY
        IF @@TRANCOUNT=0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnTransaction=1;
        END;
        ELSE SAVE TRANSACTION @Savepoint;
        EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_TextPairs_Result',@KeepData=@KeepData,@Debug=0,@Hilfe=0;
        SET @Sql=N'INSERT '+QUOTENAME(@ResultTable)+N'(PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode) SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #tbx_TextPairs_Result;';
        EXEC sys.sp_executesql @Sql;
        IF @OwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Jeder Cleanupversuch erhält den ersten ErrorRecord durch bare THROW.
        BEGIN TRY
            IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
            ELSE IF @OwnTransaction=0 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
        END TRY
        BEGIN CATCH
            RAISERROR(N'USP_CompareTextPairs: zusätzlicher Rollbackfehler; ursprünglicher Fehler bleibt maßgeblich.',10,1);
        END CATCH;
        THROW;
    END CATCH;
    RETURN 0;
END;
GO
