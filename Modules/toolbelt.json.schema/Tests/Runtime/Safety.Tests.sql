SET NOCOUNT ON;
CREATE TABLE #Help(HelpContractVersion varchar(16),SchemaName sysname NULL,ObjectName sysname NULL,Section varchar(32),Ordinal int,ItemName sysname NULL,SqlDataType varchar(256),
 IsRequired bit,IsNullable bit,DefaultValue nvarchar(4000),Description nvarchar(max),ExampleSql nvarchar(max));
CREATE TABLE #tbx_JsonSchema_Result(Sentinel int);
INSERT #tbx_JsonSchema_Result VALUES(7);
INSERT #Help EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1,@Profile='invalid',@MaxDepth=0,@MaxEvaluationSteps=NULL;
IF (SELECT COUNT(*) FROM #Help WHERE Section='PARAMETER')<>12
 OR (SELECT COUNT(*) FROM #Help WHERE Section='RESULT_COLUMN')<>10
 OR NOT EXISTS(SELECT 1 FROM #tbx_JsonSchema_Result WHERE Sentinel=7)
 THROW 55691,N'Synthetic help-first oracle failed.',1;
DECLARE @Rejected bit=0;
BEGIN TRY
 EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true';
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>55601 OR ERROR_STATE()<>1 THROW;
 SET @Rejected=1;
END CATCH;
IF @Rejected<>1 OR NOT EXISTS(SELECT 1 FROM #tbx_JsonSchema_Result WHERE Sentinel=7)
 THROW 55691,N'Synthetic reserved caller temp oracle failed.',2;
DROP TABLE #tbx_JsonSchema_Result;
CREATE TABLE #Destination(Sentinel int);
INSERT #Destination VALUES(11);
SET @Rejected=0;
BEGIN TRY
 EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true',@MaxErrors=-1,@ResultTable=N'#Destination';
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>55600 OR ERROR_STATE()<>1 THROW;
 SET @Rejected=1;
END CATCH;
IF @Rejected<>1 OR NOT EXISTS(SELECT 1 FROM #Destination WHERE Sentinel=11)
 THROW 55691,N'Synthetic argument-before-mutation oracle failed.',3;
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true',@ResultTable=N'#Destination';
EXEC sys.sp_executesql N'IF (SELECT COUNT(*) FROM #Destination)<>1 OR NOT EXISTS(SELECT 1 FROM #Destination WHERE Status=''VALID'' AND IsValid=1 AND ErrorOrdinal=0) THROW 55691,N''Synthetic replacement result failed.'',4;';
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'2',@Schema=N'true',@ResultTable=N'#Destination',@KeepData=1;
EXEC sys.sp_executesql N'IF (SELECT COUNT(*) FROM #Destination)<>2 THROW 55691,N''Synthetic appended result failed.'',5;';
DECLARE @BeforeCount int;
BEGIN TRANSACTION;
SET @BeforeCount=@@TRANCOUNT;
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'3',@Schema=N'true',@ResultTable=N'#Destination',@KeepData=1;
IF @@TRANCOUNT<>@BeforeCount OR XACT_STATE()<>1 THROW 55691,N'Synthetic caller transaction changed.',6;
EXEC sys.sp_executesql N'IF (SELECT COUNT(*) FROM #Destination)<>3 THROW 55691,N''Synthetic caller result failed.'',7;';
ROLLBACK;
EXEC sys.sp_executesql N'IF (SELECT COUNT(*) FROM #Destination)<>2 THROW 55691,N''Synthetic caller rollback failed.'',8;';
DROP TABLE #Destination;
DROP TABLE #Help;
-- Gleiche Ergebnisform mit eigener CHECK-Constraint: Insert scheitert erst
-- nach dem Routing. Dadurch werden echte Own-/Savepoint-/doomed-Pfade geprüft.
DECLARE @OriginalXactAbort bit=CASE WHEN (@@OPTIONS&16384)=16384 THEN 1 ELSE 0 END;
SET XACT_ABORT OFF;
CREATE TABLE #SchemaConstrained(
 RowKind varchar(8) COLLATE Latin1_General_100_BIN2 NOT NULL,ErrorOrdinal int NOT NULL,
 Status varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL CHECK(Status='sentinel'),
 Profile varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,IsValid bit NULL,
 DocumentPointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
 SchemaPointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
 Keyword nvarchar(128) COLLATE Latin1_General_100_BIN2 NULL,
 ErrorCode varchar(32) COLLATE Latin1_General_100_BIN2 NULL,ErrorsTruncated bit NOT NULL);
INSERT #SchemaConstrained VALUES('SUMMARY',0,'sentinel','toolbelt-2020-12-v1',NULL,NULL,NULL,NULL,NULL,0);
BEGIN TRY
 EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true',@ResultTable=N'#SchemaConstrained';
 THROW 55691,N'Synthetic constrained own insert unexpectedly succeeded.',9;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55691,N'Synthetic own routing transaction leaked.',10;
IF (SELECT COUNT(*) FROM #SchemaConstrained)<>1 THROW 55691,N'Synthetic own routing row count changed.',16;
IF NOT EXISTS(SELECT 1 FROM #SchemaConstrained WHERE Status='sentinel') THROW 55691,N'Synthetic own routing value changed.',17;
CREATE TABLE #SchemaCallerWitness(Value int NOT NULL);
INSERT #SchemaCallerWitness VALUES(7);
BEGIN TRANSACTION;
INSERT #SchemaCallerWitness VALUES(11);
BEGIN TRY
 EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true',@ResultTable=N'#SchemaConstrained';
 THROW 55691,N'Synthetic constrained caller insert unexpectedly succeeded.',11;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 BEGIN ROLLBACK; THROW; END; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR (SELECT COUNT(*) FROM #SchemaConstrained)<>1
 OR NOT EXISTS(SELECT 1 FROM #SchemaConstrained WHERE Status='sentinel')
 OR (SELECT COUNT(*) FROM #SchemaCallerWitness)<>2
BEGIN ROLLBACK; THROW 55691,N'Synthetic caller savepoint changed previous work.',12; END;
ROLLBACK;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT #SchemaCallerWitness VALUES(22);
BEGIN TRY
 EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true',@ResultTable=N'#SchemaConstrained';
 THROW 55691,N'Synthetic doomed insert unexpectedly succeeded.',13;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 BEGIN IF XACT_STATE()<>0 ROLLBACK; THROW; END; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1
BEGIN IF XACT_STATE()<>0 ROLLBACK; THROW 55691,N'Synthetic doomed caller was rolled back by callee.',14; END;
ROLLBACK;
IF (SELECT COUNT(*) FROM #SchemaCallerWitness)<>1 OR (SELECT COUNT(*) FROM #SchemaConstrained)<>1
 OR NOT EXISTS(SELECT 1 FROM #SchemaConstrained WHERE Status='sentinel')
 THROW 55691,N'Synthetic explicit caller rollback failed.',15;
DROP TABLE #SchemaCallerWitness;
DROP TABLE #SchemaConstrained;
IF @OriginalXactAbort=0 SET XACT_ABORT OFF;
PRINT N'PASS JSON_SCHEMA_NATIVE_SAFETY';
GO
