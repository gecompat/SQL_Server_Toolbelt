SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55192,N'Atomicity fixture requires healthy own session.',1;
DECLARE @OriginalOptions int=@@OPTIONS;
CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max));
CREATE TABLE #Result(AnyDummy varbinary(9) NULL);
INSERT #Pairs VALUES(1,N'a',N'b');
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result',@KeepData=1;
IF (SELECT COUNT(*) FROM #Result)<>1 THROW 55192,N'Empty mismatched KeepData1 failed.',2;
CREATE INDEX ixResult ON #Result(PairOrdinal);
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result',@KeepData=1;
IF (SELECT COUNT(*) FROM #Result)<>2 THROW 55192,N'Matching populated append failed.',3;
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result',@KeepData=0;
IF (SELECT COUNT(*) FROM #Result)<>1 THROW 55192,N'Matching populated replace failed.',4;
TRUNCATE TABLE #Pairs;
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result',@KeepData=1;
IF (SELECT COUNT(*) FROM #Result)<>1 THROW 55192,N'Empty input append failed.',5;
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result',@KeepData=0;
IF EXISTS(SELECT 1 FROM #Result) THROW 55192,N'Empty input replace failed.',6;
INSERT #Result VALUES(73,0,0,NULL,0);
ALTER TABLE #Result ADD CHECK(PairOrdinal=73);
INSERT #Pairs VALUES(1,N'a',N'b');
DECLARE @Caught bit=0;
BEGIN TRY
    EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>547 THROW;
    SET @Caught=1;
END CATCH;
-- Capture transaction state before table reads can open an autocommit statement.
DECLARE @PublicationTranCount int=@@TRANCOUNT,@PublicationXactState int=XACT_STATE();
IF @Caught<>1 OR @PublicationTranCount<>0 OR @PublicationXactState<>0 OR (SELECT COUNT(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=73)
    THROW 55192,N'Late insert failure did not restore own publication.',7;
-- XACT_ABORT OFF permits rollback to own savepoint after constraint failure.
SET XACT_ABORT OFF;
BEGIN TRANSACTION;
SET @Caught=0;
BEGIN TRY
    EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>547 THROW;
    SET @Caught=1;
END CATCH;
SET @PublicationTranCount=@@TRANCOUNT;
SET @PublicationXactState=XACT_STATE();
IF @Caught<>1 OR @PublicationTranCount<>1 OR @PublicationXactState<>1 OR (SELECT COUNT(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=73)
BEGIN
    ROLLBACK TRANSACTION;
    THROW 55192,N'Caller savepoint or sentinel not preserved.',8;
END;
ROLLBACK TRANSACTION;
-- XACT_ABORT ON: successful publication leaves the healthy caller transaction open.
SET XACT_ABORT ON;
CREATE TABLE #CallerOutput(Dummy int NULL);
BEGIN TRANSACTION;
EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#CallerOutput';
SET @PublicationTranCount=@@TRANCOUNT;
SET @PublicationXactState=XACT_STATE();
IF @PublicationTranCount<>1 OR @PublicationXactState<>1 OR (SELECT COUNT(*) FROM #CallerOutput)<>1
BEGIN
    ROLLBACK TRANSACTION;
    THROW 55192,N'Healthy XACT_ABORT ON caller was not preserved.',10;
END;
ROLLBACK TRANSACTION;
DROP TABLE #CallerOutput;
-- A late constraint failure dooms the caller; only the caller may roll it back.
BEGIN TRANSACTION;
SET @Caught=0;
BEGIN TRY
    EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'osa',@ResultTable=N'#Result';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>547 THROW;
    SET @Caught=1;
END CATCH;
SET @PublicationTranCount=@@TRANCOUNT;
SET @PublicationXactState=XACT_STATE();
IF @Caught<>1 OR @PublicationTranCount<>1 OR @PublicationXactState<>-1
BEGIN
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    THROW 55192,N'Late failure did not preserve the doomed caller.',11;
END;
SET @Caught=0;
BEGIN TRY
    EXEC toolbelt_string.USP_CompareTextPairs @Algorithm=NULL;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>50000 OR ERROR_STATE()<>1 THROW;
    SET @Caught=1;
END CATCH;
SET @PublicationTranCount=@@TRANCOUNT;
SET @PublicationXactState=XACT_STATE();
IF @Caught<>1 OR @PublicationTranCount<>1 OR @PublicationXactState<>-1
BEGIN
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    THROW 55192,N'Doomed caller admission guard changed the transaction.',12;
END;
ROLLBACK TRANSACTION;
IF (SELECT COUNT(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE PairOrdinal=73)
    THROW 55192,N'Caller rollback did not restore the original sentinel.',13;
IF (@OriginalOptions&16384)=16384 SET XACT_ABORT ON;
ELSE SET XACT_ABORT OFF;
IF @@OPTIONS<>@OriginalOptions THROW 55192,N'Fixture options not restored.',9;
DROP TABLE #Result;
DROP TABLE #Pairs;
SELECT N'PASS' AS Status;
