-- Gezielte frühe Gates, Help-Priorität und nicht-doomende Caller-Ablehnung.
SET NOCOUNT ON;
DECLARE @Length int,@Hash varbinary(max),@Error int,@State int;
DECLARE LengthCases CURSOR LOCAL FAST_FORWARD FOR SELECT n FROM (VALUES(31),(33)) c(n);
OPEN LengthCases; FETCH NEXT FROM LengthCases INTO @Length;
WHILE @@FETCH_STATUS=0
BEGIN
    SET @Hash=CONVERT(varbinary(max),REPLICATE('x',@Length)); SET @Error=0;
    BEGIN TRY EXEC toolbelt_metadata.USP_ExecuteTableClone @ExpectedPlanHash=@Hash; END TRY
    BEGIN CATCH SET @Error=ERROR_NUMBER(); END CATCH;
    IF @Error<>53930 OR @@TRANCOUNT<>0 THROW 54941,N'Hash length gate failed.',1;
    FETCH NEXT FROM LengthCases INTO @Length;
END;
CLOSE LengthCases; DEALLOCATE LengthCases;
SET @Error=0;
BEGIN TRY EXEC toolbelt_metadata.USP_ExecuteTableClone; END TRY
BEGIN CATCH SET @Error=ERROR_NUMBER(); END CATCH;
IF @Error<>53930 THROW 54941,N'NULL hash gate failed.',2;

CREATE TABLE dbo.SyntheticExecuteSafety(Id int NOT NULL);
SET @Hash=CONVERT(binary(32),0x00);
SET @Error=0;
BEGIN TRY
    EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticExecuteSafety',
        @TargetSchema=N'dbo',@TargetTable=N'SyntheticExecuteSafetyClone',@ExpectedPlanHash=@Hash;
END TRY
BEGIN CATCH SET @Error=ERROR_NUMBER(); END CATCH;
IF @Error<>53934 OR OBJECT_ID(N'dbo.SyntheticExecuteSafetyClone') IS NOT NULL OR @@TRANCOUNT<>0
    THROW 54941,N'Hash mismatch caused target mutation.',3;

CREATE TABLE #TableCloneExecute_MapStage(OwnSentinel int NOT NULL);
INSERT #TableCloneExecute_MapStage VALUES(17);
SET @Error=0;
BEGIN TRY EXEC toolbelt_metadata.USP_ExecuteTableClone @ExpectedPlanHash=@Hash; END TRY
BEGIN CATCH SET @Error=ERROR_NUMBER(); END CATCH;
IF @Error<>53930 OR (SELECT COUNT(*) FROM #TableCloneExecute_MapStage)<>1
    OR NOT EXISTS(SELECT 1 FROM #TableCloneExecute_MapStage WHERE OwnSentinel=17)
    THROW 54941,N'Foreign bridge collision was not preserved.',4;
DROP TABLE #TableCloneExecute_MapStage;
SET @Error=0; SET @State=0;
BEGIN TRY EXEC toolbelt_metadata.USP_ExecuteTableClone @ExpectedPlanHash=@Hash,@ResultTable=N'#tablecloneexecute_planstage'; END TRY
BEGIN CATCH SELECT @Error=ERROR_NUMBER(),@State=ERROR_STATE(); END CATCH;
IF @Error<>53930 OR @State<>6 OR OBJECT_ID(N'tempdb..#tablecloneexecute_planstage') IS NOT NULL
    THROW 54941,N'Absent output alias of owned bridge was not rejected.',8;
SET @Error=0; SET @State=0;
BEGIN TRY EXEC toolbelt_metadata.USP_ExecuteTableClone @ExpectedPlanHash=@Hash,@TableMap=N'#tablecloneexecute_mapstage'; END TRY
BEGIN CATCH SELECT @Error=ERROR_NUMBER(),@State=ERROR_STATE(); END CATCH;
IF @Error<>53930 OR @State<>6 OR OBJECT_ID(N'tempdb..#tablecloneexecute_mapstage') IS NOT NULL
    THROW 54941,N'Absent input alias of owned bridge was not rejected.',9;

DECLARE @OriginalOptions int=@@OPTIONS,@OriginalXactAbort bit=CASE WHEN @@OPTIONS&16384<>0 THEN 1 ELSE 0 END;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @CallerBeforeTC int,@CallerBeforeXS int,@CallerBeforeOptions int;
SET @CallerBeforeTC=@@TRANCOUNT;
SET @CallerBeforeXS=XACT_STATE();
IF @CallerBeforeTC<>1 THROW 54941,N'Caller initial transaction count invalid.',40;
IF @CallerBeforeXS<>1 THROW 54941,N'Caller initial transaction state invalid.',41;
SET @Error=0;
SET @CallerBeforeOptions=@@OPTIONS;
BEGIN TRY EXEC toolbelt_metadata.USP_ExecuteTableClone @ExpectedPlanHash=@Hash; END TRY
BEGIN CATCH SET @Error=ERROR_NUMBER(); IF @Error<>50000 THROW; END CATCH;
DECLARE @CallerTC int,@CallerXS int,@CallerAfterOptions int;
SET @CallerAfterOptions=@@OPTIONS;
SET @CallerTC=@@TRANCOUNT;
SET @CallerXS=XACT_STATE();
IF @Error<>50000
BEGIN
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW 54941,N'Caller transaction unexpected error.',10;
END;
IF @CallerTC<>1
BEGIN
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW 54941,N'Caller transaction count changed.',11;
END;
IF @CallerXS<>1
BEGIN
    DECLARE @CallerObservedState tinyint=CASE @CallerXS WHEN -1 THEN 31 WHEN 0 THEN 30 ELSE 12 END;
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW 54941,N'Caller transaction state changed.',@CallerObservedState;
END;
IF @CallerAfterOptions<>@CallerBeforeOptions OR (@CallerBeforeOptions & 16384)<>16384 OR (@CallerAfterOptions & 16384)<>16384
BEGIN
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW 54941,N'Caller transaction SET options changed.',42;
END;
-- Help hat Vorrang vor ungültigem Hash, fremder Temp, Caller-TX und Ausgabe.
EXEC toolbelt_metadata.USP_ExecuteTableClone @ExpectedPlanHash=NULL,@ForeignKeyMode=NULL,
    @ResultTable=N'#MissingSyntheticOutput',@Hilfe=1;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 54941,N'Help changed Caller transaction.',6;
ROLLBACK TRANSACTION;
IF @OriginalXactAbort=0 SET XACT_ABORT OFF;
IF @@OPTIONS<>@OriginalOptions THROW 54941,N'Caller SET was not restored.',7;
DROP TABLE dbo.SyntheticExecuteSafety;
PRINT N'PASS TABLE_CLONE_EXECUTE_SAFETY';
GO
