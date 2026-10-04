SET NOCOUNT ON;
CREATE TABLE #Pairs(PairOrdinal bigint NULL,LeftText nvarchar(max) NULL,RightText nvarchar(max) NULL,Ignored int NULL);
CREATE TABLE #Result(Dummy uniqueidentifier NULL);
INSERT #Pairs(PairOrdinal,LeftText,RightText) VALUES
 (-9223372036854775808,N'kitten',N'sitting'),(0,N'ab',N'ba'),(9,N'MARTHA',N'MARHTA'),
 (21,NULL,N'ignored'),(22,N'',N''),(23,N'x ',N'x'),(24,NCHAR(0),N''),
 (25,NCHAR(0xD83D)+NCHAR(0xDE00),N''),(26,NCHAR(0xD800),N'x');
DECLARE @Algorithms TABLE(Ordinal int NOT NULL,Name nvarchar(32) NOT NULL);
INSERT @Algorithms VALUES(1,N'levenshtein'),(2,N'osa'),(3,N'jaro-winkler');
DECLARE @i int=1,@Algorithm nvarchar(32);
WHILE @i<=3
BEGIN
    SELECT @Algorithm=Name FROM @Algorithms WHERE Ordinal=@i;
    EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=@Algorithm,@ResultTable=N'#Result';
    IF (SELECT COUNT_BIG(*) FROM #Result)<>9 THROW 55190,N'Contract: vollständige Resultanzahl fehlt.',1;
    IF @i=1
    BEGIN
        IF EXISTS(SELECT p.PairOrdinal,f.Distance,f.ExceedsMaxDistance,CONVERT(float,NULL),f.ErrorCode FROM #Pairs p CROSS APPLY toolbelt_string.TVF_LevenshteinDistance(p.LeftText,p.RightText,NULL,N'standard') f
                  EXCEPT SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #Result)
          OR EXISTS(SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #Result
                  EXCEPT SELECT p.PairOrdinal,f.Distance,f.ExceedsMaxDistance,CONVERT(float,NULL),f.ErrorCode FROM #Pairs p CROSS APPLY toolbelt_string.TVF_LevenshteinDistance(p.LeftText,p.RightText,NULL,N'standard') f)
            THROW 55190,N'Contract: Levenshtein-Providerparität fehlt.',2;
        IF NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=-9223372036854775808 AND Distance=3 AND ExceedsMaxDistance=0 AND ErrorCode=0)
           OR NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=0 AND Distance=2 AND ErrorCode=0)
            THROW 55190,N'Contract: unabhängige Levenshtein-Goldens fehlen.',3;
    END;
    ELSE IF @i=2
    BEGIN
        IF EXISTS(SELECT p.PairOrdinal,f.Distance,f.ExceedsMaxDistance,CONVERT(float,NULL),f.ErrorCode FROM #Pairs p CROSS APPLY toolbelt_string.TVF_OsaDistance(p.LeftText,p.RightText,NULL,N'standard') f
                  EXCEPT SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #Result)
          OR EXISTS(SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #Result
                  EXCEPT SELECT p.PairOrdinal,f.Distance,f.ExceedsMaxDistance,CONVERT(float,NULL),f.ErrorCode FROM #Pairs p CROSS APPLY toolbelt_string.TVF_OsaDistance(p.LeftText,p.RightText,NULL,N'standard') f)
            THROW 55190,N'Contract: OSA-Providerparität fehlt.',4;
        IF NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=0 AND Distance=1 AND ExceedsMaxDistance=0 AND ErrorCode=0)
            THROW 55190,N'Contract: OSA-Transpositionsgolden fehlt.',5;
    END;
    ELSE
    BEGIN
        IF EXISTS(SELECT p.PairOrdinal,CONVERT(int,NULL),CONVERT(bit,NULL),f.Similarity,f.ErrorCode FROM #Pairs p CROSS APPLY toolbelt_string.TVF_JaroWinklerSimilarity(p.LeftText,p.RightText,N'standard') f
                  EXCEPT SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #Result)
          OR EXISTS(SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #Result
                  EXCEPT SELECT p.PairOrdinal,CONVERT(int,NULL),CONVERT(bit,NULL),f.Similarity,f.ErrorCode FROM #Pairs p CROSS APPLY toolbelt_string.TVF_JaroWinklerSimilarity(p.LeftText,p.RightText,N'standard') f)
            THROW 55190,N'Contract: Jaro-Providerparität fehlt.',6;
        IF NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=9 AND ABS(Similarity-CONVERT(float,173)/180)<1e-12 AND ErrorCode=0)
            THROW 55190,N'Contract: Jaro-Golden fehlt.',7;
    END;
    IF NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=21 AND Distance IS NULL AND ExceedsMaxDistance IS NULL AND Similarity IS NULL AND ErrorCode=0)
       OR NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=26 AND Distance IS NULL AND ExceedsMaxDistance IS NULL AND Similarity IS NULL AND ErrorCode=4)
        THROW 55190,N'Contract: gemischte NULL-/UTF16-Codes fehlen.',8;
    SET @i+=1;
END;
-- Profilfehler werden nicht zu globalen Wrapperfehlern; NULL gewinnt weiterhin.
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@Profile=NULL,@ResultTable=N'#Result';
IF EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal<>21 AND ErrorCode<>1)
   OR NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=21 AND ErrorCode=0)
    THROW 55190,N'Contract: Profil-/NULL-Priorität geändert.',9;
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'levenshtein',@MaxDistance=1,@ResultTable=N'#Result';
IF NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=-9223372036854775808 AND Distance IS NULL AND ExceedsMaxDistance=1 AND ErrorCode=0)
    THROW 55190,N'Contract: Thresholdnachweis fehlt.',10;
DROP TABLE #Result;
DROP TABLE #Pairs;
SELECT N'PASS' AS Status;
