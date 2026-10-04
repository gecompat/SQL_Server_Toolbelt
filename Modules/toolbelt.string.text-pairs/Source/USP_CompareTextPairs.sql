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
        DECLARE @Help TABLE
        (
            HelpContractVersion varchar(16) NOT NULL, SchemaName sysname NOT NULL,
            ObjectName sysname NOT NULL, Section varchar(32) NOT NULL, Ordinal int NOT NULL,
            ItemName sysname NULL, SqlDataType varchar(256) NULL, IsRequired bit NULL,
            IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
            Description nvarchar(max) NOT NULL, ExampleSql nvarchar(max) NULL
        );
        INSERT @Help VALUES
        ('1.0',N'toolbelt_string',N'USP_CompareTextPairs','DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,
         N'Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.',NULL);
        INSERT @Help
        SELECT '1.0',N'toolbelt_string',N'USP_CompareTextPairs','PARAMETER',v.Ordinal,
               v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,NULL
        FROM (VALUES
          (1,N'@PairsTable','sysname',1,0,N'NULL',N'Lokale #Temp mit PairOrdinal bigint, LeftText und RightText nvarchar(max). Ordinals nicht NULL und eindeutig, inklusive negativer Werte.'),
          (2,N'@Algorithm','nvarchar(max)',1,0,N'NULL',N'Bytegenau levenshtein, osa oder jaro-winkler; global für alle Paare.'),
          (3,N'@MaxDistance','int',0,1,N'NULL',N'Unveränderte Distanzschwelle; bei Jaro ausschließlich NULL.'),
          (4,N'@Profile','nvarchar(max)',0,1,N'N''standard''',N'Unverändert standard/large oder fachlicher Profilfehler; NULL bleibt NULL.'),
          (5,N'@MaxPairs','int',0,0,N'10000',N'1..100000, alle Inputzeilen zählen.'),
          (6,N'@MaxTotalTextBytes','bigint',0,0,N'2097152',N'1..16777216, beide DATALENGTH-Textseiten auch bei NULL-Gegenseite.'),
          (7,N'@MaxTotalWork','bigint',0,0,N'16777216',N'1..67108864 konservative UTF16-Produktcharge mit kanonischem Paircap; keine tatsächliche CPU-Zählung.'),
          (8,N'@ResultTable','sysname',0,1,N'NULL',N'NULL liefert sortierten SELECT; vorhandene lokale #Temp empfängt atomaren Helper+Insert.'),
          (9,N'@KeepData','bit',0,1,N'0',N'0 Replace, 1 Append nach ResultTable-Vertrag. NULL bedeutet 0.'),
          (10,N'@Debug','tinyint',0,1,N'0',N'Messages ohne Textpayload; NULL bedeutet 0.'),
          (11,N'@Hilfe','bit',0,1,N'0',N'1 ausschließlich Help, ohne Tabellen-/Dependency-/Transaktionsprüfung.')
        ) v(Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description);
        INSERT @Help
        SELECT '1.0',N'toolbelt_string',N'USP_CompareTextPairs','RESULT_COLUMN',v.Ordinal,
               v.ItemName,v.SqlDataType,NULL,v.IsNullable,NULL,v.Description,NULL
        FROM (VALUES
          (1,N'PairOrdinal','bigint',0,N'Unveränderte Inputidentität; SELECT ordinal sortiert.'),
          (2,N'Distance','int',1,N'Distanzwert oder NULL; bei Jaro immer NULL.'),
          (3,N'ExceedsMaxDistance','bit',1,N'Distanz-Thresholdnachweis oder NULL; bei Jaro immer NULL.'),
          (4,N'Similarity','float(53)',1,N'Jaro-Winkler 0..1 oder NULL; bei Distanz immer NULL.'),
          (5,N'ErrorCode','int',0,N'Kanonischer Fachcode 0..6; Jaro verwendet keinen Code 2.')
        ) v(Ordinal,ItemName,SqlDataType,IsNullable,Description);
        INSERT @Help VALUES
        ('1.0',N'toolbelt_string',N'USP_CompareTextPairs','ERROR',1,N'55100-55104',NULL,NULL,NULL,NULL,
         N'Algorithmus, globale Parameter, lokale Namen/Shape oder interne Tempkollision ungültig; kein fachliches Resultat.',NULL),
        ('1.0',N'toolbelt_string',N'USP_CompareTextPairs','ERROR',2,N'55105-55108',NULL,NULL,NULL,NULL,
         N'Admission/Stabilität/Ordinals/Work oder Providerkohärenz verletzt; keine Teilveröffentlichung. Engine-/Helperfehler bleiben erhalten.',NULL),
        ('1.0',N'toolbelt_string',N'USP_CompareTextPairs','PERMISSION',1,NULL,NULL,NULL,NULL,NULL,
         N'Vorhandenes EXECUTE und bestehende TVF-/Helper-Rechte beziehungsweise Ownershipchain; caller-eigene Tempmetadaten. Keine Rechteerteilung und keine Runtime-Assemblyhash-/DB-VIEW-DEFINITION-Pflicht.',NULL),
        ('1.0',N'toolbelt_string',N'USP_CompareTextPairs','EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,
         N'Synthetischer Aufruf ohne generisches INSERT EXEC.',
         N'CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max)); INSERT #Pairs VALUES(1,N''kitten'',N''sitting''); EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N''#Pairs'',@Algorithm=N''levenshtein'';'),
        ('1.0',N'toolbelt_string',N'USP_CompareTextPairs','LIMITATION',1,NULL,NULL,NULL,NULL,NULL,
         N'Keine MARS-/parallele Mutation, keine globale/permanente Inputtable. Distributed Caller-Savepoints sind nicht unterstützt. Technische Fehler verwerfen den gesamten Aufruf.',NULL);
        SELECT HelpContractVersion,SchemaName,ObjectName,Section,Ordinal,ItemName,SqlDataType,
               IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help
        ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
                 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5
                 WHEN 'LIMITATION' THEN 6 WHEN 'EXAMPLE' THEN 7 ELSE 8 END,Ordinal;
        RETURN 0;
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
