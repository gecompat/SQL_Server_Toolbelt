CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max));
INSERT #Pairs VALUES(-3,N'kitten',N'sitting'),(0,N'ab',N'ba'),(7,NULL,N'unchanged');
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa';
CREATE TABLE #Comparison(AnyDummy varbinary(9) NULL);
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'jaro-winkler',@ResultTable=N'#Comparison';
SELECT PairOrdinal,Distance,ExceedsMaxDistance,Similarity,ErrorCode FROM #Comparison ORDER BY PairOrdinal;
DROP TABLE #Comparison;
DROP TABLE #Pairs;
