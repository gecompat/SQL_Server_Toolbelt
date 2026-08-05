:on error exit
SET NOCOUNT ON;
DELETE FROM toolbelt_core.EventLog;
GO
DECLARE @Help TABLE(HelpContractVersion varchar(16),SchemaName sysname,ObjectName sysname,Section varchar(32),Ordinal int,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max),ExampleSql nvarchar(max) NULL);
INSERT INTO @Help EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE ObjectName=N'USP_WriteEvent') THROW 52700,N'Write-Help fehlt.',1;

CREATE TABLE #UnexpectedResult(Dummy int NULL);
INSERT INTO #UnexpectedResult
EXEC toolbelt_core.USP_WriteEvent @EventName='test.no-result',@Message=N'No infrastructure rows';
IF EXISTS(SELECT 1 FROM #UnexpectedResult) THROW 52701,N'USP_WriteEvent erzeugte ein unerwartetes Resultset.',1;
DROP TABLE #UnexpectedResult;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.no-result' AND RemoteSessionId<>CallerSessionId) THROW 52702,N'Der resultsetfreie Event-Write fehlt.',1;

DECLARE @ExecutionId uniqueidentifier='44444444-1111-1111-1111-111111111111';
DECLARE @CorrelationId uniqueidentifier='44444444-2222-2222-2222-222222222222';
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@ExecutionId OUTPUT,@CorrelationId=@CorrelationId,@Actor=N'event-actor',@Tenant=N'event-tenant';
EXEC toolbelt_core.USP_WriteEvent @EventName='test.context',@EventLevel='warning',@Category='contract',@Message=N'Context event',@DataJson=N'{"value":42}',@ErrorNumber=50000,@ErrorSeverity=16,@ErrorState=2,@ErrorProcedure=N'USP_Test',@ErrorLine=7;
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@ExecutionId;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.context' AND EventLevel='WARNING' AND ExecutionId=@ExecutionId AND CorrelationId=@CorrelationId AND Actor=N'event-actor' AND Tenant=N'event-tenant' AND JSON_VALUE(DataJson,'$.value')='42' AND ErrorNumber=50000 AND RemoteSessionId<>CallerSessionId) THROW 52703,N'Context- oder Error-Propagation ist inkonsistent.',1;

BEGIN TRANSACTION;
EXEC toolbelt_core.USP_WriteEvent @EventName='test.rollback',@Message=N'Caller rolls back';
ROLLBACK TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.rollback' AND CallerXactState=1 AND CallerTransactionCount>=1) THROW 52704,N'Event überlebte Caller-Rollback nicht.',1;

DROP TABLE IF EXISTS dbo.TbxEventChild;
DROP TABLE IF EXISTS dbo.TbxEventParent;
CREATE TABLE dbo.TbxEventParent(Id int NOT NULL CONSTRAINT PK_TbxEventParent PRIMARY KEY);
CREATE TABLE dbo.TbxEventChild(Id int NOT NULL,ParentId int NOT NULL,CONSTRAINT FK_TbxEventChild_Parent FOREIGN KEY(ParentId) REFERENCES dbo.TbxEventParent(Id));
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT INTO dbo.TbxEventChild(Id,ParentId) VALUES(1,999);
 THROW 52705,N'Der synthetische Constraintfehler blieb aus.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=52705 THROW;
 IF XACT_STATE()<>-1 THROW 52706,N'Der Caller ist nicht uncommittable.',1;
 EXEC toolbelt_core.USP_WriteEvent @EventName='test.uncommittable',@EventLevel='ERROR',@Message=N'Doomed caller';
 ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;
DROP TABLE dbo.TbxEventChild;
DROP TABLE dbo.TbxEventParent;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.uncommittable' AND CallerXactState=-1) THROW 52707,N'Event aus uncommittable Caller fehlt.',1;

BEGIN TRY EXEC toolbelt_core.USP_WriteEvent @EventName='INVALID'; THROW 52708,N'Ungültiger EventName blieb aus.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52708 OR ERROR_NUMBER()<>51700 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_WriteEvent @EventName='test.invalid-level',@EventLevel='PANIC'; THROW 52709,N'Ungültiges Level blieb aus.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52709 OR ERROR_NUMBER()<>51701 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_WriteEvent @EventName='test.invalid-json',@DataJson=N'[]'; THROW 52710,N'Ungültige DataJson blieb aus.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52710 OR ERROR_NUMBER()<>51703 THROW; END CATCH;

EXEC toolbelt_core.USP_WriteEvent @EventName='test.retention.old',@OccurredAtUtc='2000-01-01T00:00:00';
EXEC toolbelt_core.USP_WriteEvent @EventName='test.retention.new',@OccurredAtUtc='2099-01-01T00:00:00';
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2010-01-01T00:00:00',@BatchSize=10,@MaxBatches=2,@DeletedRows=@Deleted OUTPUT;
IF @Deleted<>1 OR EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.retention.old') OR NOT EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.retention.new') THROW 52711,N'Retention ist inkonsistent.',1;

PRINT N'Event Log Contract: erfolgreich';
GO
