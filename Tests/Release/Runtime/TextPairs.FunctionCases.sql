DECLARE @ExpectedApiCount int=1;
INSERT @Apis VALUES
(1,N'toolbelt_string',N'USP_CompareTextPairs','EXECUTE',N'EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N''#ContosoPairs'',@Algorithm=N''osa'';',N'DECLARE @InitialTransactionCount int=@@TRANCOUNT,@InitialTransactionState smallint=XACT_STATE();
CREATE TABLE #ContosoPairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max));
INSERT #ContosoPairs VALUES(-9223372036854775808,N''CA'',N''AC''),(0,N''A'',N''A''),(7,NULL,N''ignored''),
 (8,N'''',N''''),(9,NCHAR(0xD800),N''x''),(10,NCHAR(0xD83D)+NCHAR(0xDE00),N''''),(11,N''ABC'',N''ACB'');
CREATE TABLE #ContosoResult(Sentinel int);
CREATE TABLE #ContosoAnswer(PairOrdinal bigint NOT NULL,Distance int NULL,ExceedsMaxDistance bit NULL,Similarity float NULL,ErrorCode int NOT NULL);
DECLARE @ExpectedIdentityDistance int=0;
DECLARE @Expected table(PairOrdinal bigint PRIMARY KEY,Distance int,ExceedsMaxDistance bit,Similarity float,ErrorCode int);
DECLARE @Algorithm int=1,@Name nvarchar(32),@Route int;
WHILE @Algorithm<=3
BEGIN
 SET @Name=CASE @Algorithm WHEN 1 THEN N''levenshtein'' WHEN 2 THEN N''osa'' ELSE N''jaro-winkler'' END;
 DELETE @Expected;
 INSERT @Expected
 SELECT PairOrdinal,CASE WHEN @Algorithm=3 THEN NULL ELSE Distance END,
  CASE WHEN @Algorithm=3 OR Distance IS NULL THEN NULL ELSE 0 END,
  CASE WHEN @Algorithm=3 THEN Similarity ELSE NULL END,ErrorCode
 FROM(VALUES
  (CONVERT(bigint,-9223372036854775808),CASE WHEN @Algorithm=1 THEN 2 ELSE 1 END,CONVERT(float,0),0),
  (CONVERT(bigint,0),@ExpectedIdentityDistance,CONVERT(float,1),0),
  (CONVERT(bigint,7),NULL,CONVERT(float,NULL),0),(CONVERT(bigint,8),0,CONVERT(float,1),0),
  (CONVERT(bigint,9),NULL,CONVERT(float,NULL),4),(CONVERT(bigint,10),1,CONVERT(float,0),0),
  (CONVERT(bigint,11),CASE WHEN @Algorithm=1 THEN 2 ELSE 1 END,CONVERT(float,5)/9,0)
 )v(PairOrdinal,Distance,Similarity,ErrorCode);
 SET @Route=0;
 WHILE @Route<2
 BEGIN
  DELETE #ContosoAnswer;
  IF @Route=0
   INSERT #ContosoAnswer EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N''#ContosoPairs'',@Algorithm=@Name;
  ELSE
  BEGIN
   EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N''#ContosoPairs'',@Algorithm=@Name,@ResultTable=N''#ContosoResult'';
   EXEC sys.sp_executesql N''INSERT #ContosoAnswer SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #ContosoResult;'';
  END;
  IF (SELECT COUNT(*) FROM #ContosoAnswer)<>7
   OR EXISTS(SELECT PairOrdinal FROM #ContosoAnswer GROUP BY PairOrdinal HAVING COUNT(*)<>1)
   OR EXISTS(SELECT 1 FROM #ContosoAnswer a FULL JOIN @Expected e ON e.PairOrdinal=a.PairOrdinal
    WHERE a.PairOrdinal IS NULL OR e.PairOrdinal IS NULL OR a.ErrorCode<>e.ErrorCode
     OR a.Distance<>e.Distance OR (a.Distance IS NULL AND e.Distance IS NOT NULL) OR (a.Distance IS NOT NULL AND e.Distance IS NULL)
     OR a.ExceedsMaxDistance<>e.ExceedsMaxDistance OR (a.ExceedsMaxDistance IS NULL AND e.ExceedsMaxDistance IS NOT NULL) OR (a.ExceedsMaxDistance IS NOT NULL AND e.ExceedsMaxDistance IS NULL)
     OR ABS(a.Similarity-e.Similarity)>1e-12 OR (a.Similarity IS NULL AND e.Similarity IS NOT NULL) OR (a.Similarity IS NOT NULL AND e.Similarity IS NULL))
   THROW 52097,N''TextPairs fixed value/NULL/error/shape oracle.'',12;
  DECLARE @AfterTransactionCount int=@@TRANCOUNT,@AfterTransactionState smallint=XACT_STATE();
  IF (SELECT COUNT(*) FROM #ContosoPairs)<>7
   THROW 52097,N''TextPairs input count invariant.'',13;
  IF @AfterTransactionCount<>@InitialTransactionCount OR @AfterTransactionState<>@InitialTransactionState
   THROW 52097,N''TextPairs standalone session invariant.'',14;
  SET @Route+=1;
 END;
 SET @Algorithm+=1;
END;');
INSERT @Denied VALUES
(1,N'toolbelt_string',N'TVF_LevenshteinDistance','SELECT',N'SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N''CA'',N''AC'',NULL,N''standard'');'),
(2,N'toolbelt_string',N'TVF_OsaDistance','SELECT',N'SELECT * FROM toolbelt_string.TVF_OsaDistance(N''CA'',N''AC'',NULL,N''standard'');'),
(3,N'toolbelt_string',N'TVF_JaroWinklerSimilarity','SELECT',N'SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N''A'',N''A'',N''standard'');'),
(4,N'toolbelt_string',N'TVF_LevenshteinDistanceCore','SELECT',N'SELECT * FROM toolbelt_string.TVF_LevenshteinDistanceCore(N''CA'',N''AC'',NULL,N''standard'');'),
(5,N'toolbelt_string',N'TVF_OsaDistanceCore','SELECT',N'SELECT * FROM toolbelt_string.TVF_OsaDistanceCore(N''CA'',N''AC'',NULL,N''standard'');'),
(6,N'toolbelt_string',N'TVF_JaroWinklerSimilarityCore','SELECT',N'SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarityCore(N''A'',N''A'',N''standard'');'),
(7,N'toolbelt_core',N'USP_PrepareResultTable','EXECUTE',N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;');
