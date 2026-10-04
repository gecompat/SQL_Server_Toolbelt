SET NOCOUNT ON;
CREATE TABLE #Pairs(PairOrdinal bigint NULL,LeftText nvarchar(max) NULL,RightText nvarchar(max) NULL);
CREATE TABLE #Result(PairOrdinal bigint NOT NULL,Distance int NULL,ExceedsMaxDistance bit NULL,Similarity float NULL,ErrorCode int NOT NULL);
INSERT #Pairs VALUES(1,N'ab',N'cd');
INSERT #Result VALUES(73,73,0,NULL,0);
-- at boundaries: one row, eight bytes, four work units.
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@MaxPairs=1,@MaxTotalTextBytes=8,@MaxTotalWork=4,@ResultTable=N'#Result';
IF NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=1 AND Distance=2 AND ErrorCode=0) THROW 55191,N'Boundary: at admission failed.',1;
TRUNCATE TABLE #Result;
INSERT #Result VALUES(73,73,0,NULL,0);
DECLARE @Case int=1,@Expected int,@Caught bit;
WHILE @Case<=9
BEGIN
    SET @Caught=0;
    SET @Expected=CASE @Case WHEN 1 THEN 55105 WHEN 2 THEN 55107 WHEN 3 THEN 55101 WHEN 4 THEN 55100 WHEN 5 THEN 55100 WHEN 6 THEN 55106 WHEN 7 THEN 55106 WHEN 8 THEN 55105 ELSE 55102 END;
    BEGIN TRY
        IF @Case=1 EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@MaxTotalTextBytes=7,@ResultTable=N'#Result';
        IF @Case=2 EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@MaxTotalWork=3,@ResultTable=N'#Result';
        IF @Case=3 EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@MaxPairs=NULL,@ResultTable=N'#Result';
        IF @Case=4 EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa ',@ResultTable=N'#Result';
        IF @Case=5 EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'jaro-winkler',@MaxDistance=0,@ResultTable=N'#Result';
        IF @Case=6
        BEGIN
            UPDATE #Pairs SET PairOrdinal=NULL;
            EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result';
        END;
        IF @Case=7
        BEGIN
            UPDATE #Pairs SET PairOrdinal=1;
            INSERT #Pairs VALUES(1,N'a',N'b');
            EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result';
        END;
        IF @Case=8 EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@MaxPairs=1,@ResultTable=N'#Result';
        IF @Case=9 EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Pairs';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>@Expected THROW;
        SET @Caught=1;
    END CATCH;
    IF @Caught<>1 OR (SELECT COUNT(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=73 AND Distance=73)
        THROW 55191,N'Boundary: expected rejection or untouched output missing.',2;
    SET @Case+=1;
END;
-- NULL counterpart discounts work, never the non-NULL text bytes.
TRUNCATE TABLE #Pairs;
INSERT #Pairs VALUES(0,NULL,N'abcd');
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@MaxTotalTextBytes=8,@MaxTotalWork=1,@ResultTable=N'#Result';
IF NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=0 AND Distance IS NULL AND ErrorCode=0) THROW 55191,N'Boundary: NULL work charge changed.',3;
DROP TABLE #Result;
DROP TABLE #Pairs;
SELECT N'PASS' AS Status;
