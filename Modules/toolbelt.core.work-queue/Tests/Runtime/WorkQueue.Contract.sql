:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT OFF;

DELETE wi FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId WHERE wt.WorkTypeName LIKE 'test.queue.%';
DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName LIKE 'test.queue.%';
GO
CREATE OR ALTER PROCEDURE dbo.USP_TbxQueueNone AS BEGIN SET NOCOUNT ON; END;
GO
CREATE OR ALTER PROCEDURE dbo.USP_TbxQueueJson @PayloadJson nvarchar(max) AS BEGIN SET NOCOUNT ON; END;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.none',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueueNone',@ParameterMode='NONE';
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.json',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueueJson',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}';

DECLARE @Help TABLE(HelpContractVersion varchar(16),SchemaName sysname,ObjectName sysname,Section varchar(32),Ordinal int,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max),ExampleSql nvarchar(max) NULL);
INSERT INTO @Help EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;
INSERT INTO @Help EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;
INSERT INTO @Help EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;
INSERT INTO @Help EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;
INSERT INTO @Help EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;
INSERT INTO @Help EXEC toolbelt_core.USP_FailWork @Hilfe=1;
INSERT INTO @Help EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;
IF (SELECT COUNT(DISTINCT ObjectName) FROM @Help)<>7 OR EXISTS
(
    SELECT n.ObjectName FROM (VALUES(N'USP_EnqueueWork'),(N'USP_ClaimWork'),(N'USP_RenewWorkLease'),(N'USP_RecoverExpiredWork'),(N'USP_CompleteWork'),(N'USP_FailWork'),(N'USP_GetWorkStatus'))n(ObjectName)
    WHERE EXISTS(SELECT 1 FROM (VALUES('DESCRIPTION'),('PARAMETER'),('RESULT_COLUMN'),('EXAMPLE'))s(Section) WHERE NOT EXISTS(SELECT 1 FROM @Help h WHERE h.ObjectName=n.ObjectName AND h.Section=s.Section))
)
    THROW 52900,N'Der Help-Vertrag ist unvollständig.',1;

CREATE TABLE #Status(Dummy int NULL);
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.json',@PayloadJson=N'{"value":1}',@ResultTable=N'#Status';
IF COL_LENGTH(N'tempdb..#Status',N'WorkItemId') IS NULL OR COL_LENGTH(N'tempdb..#Status',N'ClaimToken') IS NOT NULL OR (SELECT COUNT(*) FROM #Status)<>1
    THROW 52901,N'Der Enqueue-ResultTable-Vertrag ist inkonsistent.',1;
DECLARE @JsonId bigint=(SELECT WorkItemId FROM #Status);

EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none',@ResultTable=N'#Status';
DECLARE @NoneId bigint=(SELECT WorkItemId FROM #Status);
IF @JsonId>=@NoneId THROW 52902,N'WorkItemId bildet die Einreihungsreihenfolge nicht ab.',1;

BEGIN TRY EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none',@PayloadJson=N'{}'; THROW 52903,N'NONE akzeptierte Payload.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52903 OR ERROR_NUMBER()<>51903 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.json',@PayloadJson=N'[]'; THROW 52904,N'JSON_PAYLOAD akzeptierte ein Array.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52904 OR ERROR_NUMBER()<>51904 THROW; END CATCH;
DECLARE @OversizedPayload nvarchar(max)=N'{"v":"'+REPLICATE(CONVERT(nvarchar(max),N'x'),33000)+N'"}';
BEGIN TRY EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.json',@PayloadJson=@OversizedPayload; THROW 52905,N'Die 64-KiB-Grenze fehlte.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52905 OR ERROR_NUMBER()<>51905 THROW; END CATCH;

DECLARE @BeforeRollback int=(SELECT COUNT(*) FROM toolbelt_core.WorkItem);
BEGIN TRANSACTION;
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none';
ROLLBACK TRANSACTION;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>@BeforeRollback THROW 52906,N'Enqueue überlebte den Caller-Rollback.',1;

CREATE TABLE #Claim(Dummy int NULL);
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF (SELECT COUNT(*) FROM #Claim)<>1 OR (SELECT WorkItemId FROM #Claim)<>@JsonId OR COL_LENGTH(N'tempdb..#Claim',N'ClaimToken') IS NULL
    THROW 52907,N'Der erste FIFO-Claim ist inkonsistent.',1;
DECLARE @JsonToken uniqueidentifier=(SELECT ClaimToken FROM #Claim);
IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_core.VW_WorkQueue') AND name IN(N'ClaimToken',N'PayloadJson'))
    THROW 52908,N'Die Statussicht legt ClaimToken oder Payload offen.',1;

BEGIN TRY EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@JsonId,@ClaimToken='00000000-0000-0000-0000-000000000001'; THROW 52909,N'Fremder Token wurde akzeptiert.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52909 OR ERROR_NUMBER()<>51923 THROW; END CATCH;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@JsonId AND Status='CLAIMED') THROW 52910,N'Der abgelehnte Token änderte den Zustand.',1;

BEGIN TRANSACTION;
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@JsonId,@ClaimToken=@JsonToken,@ResultTable=N'#Status';
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@JsonId AND Status='COMPLETED') THROW 52911,N'Complete mutierte nicht innerhalb der Caller-Transaktion.',1;
ROLLBACK TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@JsonId AND Status='CLAIMED') THROW 52912,N'Complete überlebte den Caller-Rollback.',1;
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@JsonId,@ClaimToken=@JsonToken,@ResultTable=N'#Status';

EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF (SELECT WorkItemId FROM #Claim)<>@NoneId THROW 52913,N'Der zweite Claim übersprang FIFO.',1;
DECLARE @NoneToken uniqueidentifier=(SELECT ClaimToken FROM #Claim);
BEGIN TRY EXEC toolbelt_core.USP_FailWork @WorkItemId=@NoneId,@ClaimToken=@NoneToken,@FailureCode='bad code'; THROW 52914,N'Ungültiger FailureCode wurde akzeptiert.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52914 OR ERROR_NUMBER()<>51926 THROW; END CATCH;
DECLARE @OversizedFailureMessage nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),1001);
BEGIN TRY EXEC toolbelt_core.USP_FailWork @WorkItemId=@NoneId,@ClaimToken=@NoneToken,@FailureCode='DEMO.ERROR',@FailureMessage=@OversizedFailureMessage; THROW 52914,N'Überlange FailureMessage wurde akzeptiert.',2; END TRY BEGIN CATCH IF ERROR_NUMBER()=52914 OR ERROR_NUMBER()<>51927 THROW; END CATCH;
EXEC toolbelt_core.USP_FailWork @WorkItemId=@NoneId,@ClaimToken=@NoneToken,@FailureCode='DEMO.ERROR',@FailureMessage=N'Synthetische bereinigte Meldung.',@ResultTable=N'#Status';
IF NOT EXISTS(SELECT 1 FROM #Status WHERE WorkItemId=@NoneId AND Status='FAILED' AND FailureCode='DEMO.ERROR') THROW 52915,N'Fail-Ergebnis ist inkonsistent.',1;

EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF EXISTS(SELECT 1 FROM #Claim) THROW 52916,N'Terminale Items wurden erneut geclaimt.',1;

EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none',@ResultTable=N'#Status';
DECLARE @DisabledId bigint=(SELECT WorkItemId FROM #Status),@Rv binary(8)=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='test.queue.none');
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='test.queue.none',@ExpectedRowVersion=@Rv;
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF EXISTS(SELECT 1 FROM #Claim) THROW 52917,N'Ein deaktivierter Work Type wurde geclaimt.',1;
SET @Rv=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='test.queue.none');
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.none',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueueNone',@ParameterMode='NONE',@AllowUpdate=1,@Reactivate=1,@ExpectedRowVersion=@Rv;
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF (SELECT WorkItemId FROM #Claim)<>@DisabledId THROW 52918,N'Reaktivierter Work Type blieb unclaimbar.',1;
DECLARE @DisabledToken uniqueidentifier=(SELECT ClaimToken FROM #Claim);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@DisabledId,@ClaimToken=@DisabledToken,@ResultTable=N'#Status';

EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none',@ResultTable=N'#Status';
DECLARE @MissingHandlerId bigint=(SELECT WorkItemId FROM #Status);
DROP PROCEDURE dbo.USP_TbxQueueNone;
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF EXISTS(SELECT 1 FROM #Claim) THROW 52919,N'Ein Item ohne Handler wurde geclaimt.',1;
EXEC(N'CREATE OR ALTER PROCEDURE dbo.USP_TbxQueueNone AS BEGIN SET NOCOUNT ON; END;');
CREATE TABLE #ClaimAfterRestore(Dummy int NULL);
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#ClaimAfterRestore';
IF NOT EXISTS(SELECT 1 FROM #ClaimAfterRestore) THROW 52920,N'Das Item blieb nach Handler-Wiederherstellung unclaimbar.',1;
DECLARE @RestoredId bigint=(SELECT WorkItemId FROM #ClaimAfterRestore),@RestoredToken uniqueidentifier=(SELECT ClaimToken FROM #ClaimAfterRestore);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@RestoredId,@ClaimToken=@RestoredToken;

BEGIN TRANSACTION;
BEGIN TRY EXEC toolbelt_core.USP_ClaimWork; THROW 52921,N'Claim akzeptierte eine Caller-Transaktion.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()=52921 OR ERROR_NUMBER()<>51910 BEGIN IF XACT_STATE()<>0 ROLLBACK; THROW; END; END CATCH;
IF XACT_STATE()<>1 BEGIN IF XACT_STATE()<>0 ROLLBACK; THROW 52922,N'Der abgelehnte Claim beschädigte die Caller-Transaktion.',1; END;
ROLLBACK TRANSACTION;

EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=@JsonId,@ResultTable=N'#Status';
IF NOT EXISTS(SELECT 1 FROM #Status WHERE WorkItemId=@JsonId AND Status='COMPLETED') THROW 52923,N'Die Statusabfrage ist inkonsistent.',1;

EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none',@ResultTable=N'#Status';
DECLARE @FailRollbackId bigint=(SELECT WorkItemId FROM #Status);
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
DECLARE @FailRollbackToken uniqueidentifier=(SELECT ClaimToken FROM #Claim);
BEGIN TRANSACTION;
EXEC toolbelt_core.USP_FailWork @WorkItemId=@FailRollbackId,@ClaimToken=@FailRollbackToken,@FailureCode='DEMO.ROLLBACK';
ROLLBACK TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@FailRollbackId AND Status='CLAIMED') THROW 52924,N'Fail überlebte den Caller-Rollback.',1;
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@FailRollbackId,@ClaimToken=@FailRollbackToken;

-- E1b: Lease-Grenzen, Heartbeat, keine implizite Recovery und Token-Invaliderung.
BEGIN TRY EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=4; THROW 52940,N'Eine zu kurze Lease wurde akzeptiert.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=52940 OR ERROR_NUMBER()<>51911 THROW; END CATCH;

EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none',@ResultTable=N'#Status';
DECLARE @LeaseId bigint=(SELECT WorkItemId FROM #Status);
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=5,@ResultTable=N'#Claim';
DECLARE @LeaseToken uniqueidentifier=(SELECT ClaimToken FROM #Claim),@LeaseGeneration bigint=(SELECT ClaimGeneration FROM #Claim),@FirstLeaseUntil datetime2(7)=(SELECT LeaseUntilUtc FROM #Claim);
IF @LeaseGeneration<>1 OR (SELECT LastHeartbeatAtUtc FROM #Claim)<>(SELECT ClaimedAtUtc FROM #Claim) THROW 52941,N'Der erste Lease-Claim ist inkonsistent.',1;

WAITFOR DELAY '00:00:01';
CREATE TABLE #Lease(Dummy int NULL);
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=@LeaseId,@ClaimToken=@LeaseToken,@ResultTable=N'#Lease';
IF (SELECT LeaseUntilUtc FROM #Lease)<=@FirstLeaseUntil OR (SELECT ClaimGeneration FROM #Lease)<>1 THROW 52942,N'Der Heartbeat verlängerte die Lease nicht korrekt.',1;

BEGIN TRANSACTION;
BEGIN TRY EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=@LeaseId,@ClaimToken=@LeaseToken; THROW 52943,N'Heartbeat akzeptierte eine Caller-Transaktion.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=52943 OR ERROR_NUMBER()<>51950 BEGIN ROLLBACK; THROW; END; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_RecoverExpiredWork; THROW 52944,N'Recovery akzeptierte eine Caller-Transaktion.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=52944 OR ERROR_NUMBER()<>51960 BEGIN ROLLBACK; THROW; END; END CATCH;
ROLLBACK TRANSACTION;

EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none',@ResultTable=N'#Status';
DECLARE @LaterQueuedId bigint=(SELECT WorkItemId FROM #Status);
WAITFOR DELAY '00:00:05.200';

-- Claim darf den abgelaufenen Claim nicht implizit übernehmen, sondern nimmt das nächste QUEUED-Item.
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF (SELECT WorkItemId FROM #Claim)<>@LaterQueuedId THROW 52945,N'Claim führte implizite Recovery aus oder verletzte FIFO unter QUEUED-Items.',1;
DECLARE @LaterToken uniqueidentifier=(SELECT ClaimToken FROM #Claim);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@LaterQueuedId,@ClaimToken=@LaterToken;

BEGIN TRY EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@LeaseId,@ClaimToken=@LeaseToken; THROW 52946,N'Complete akzeptierte eine abgelaufene Lease.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=52946 OR ERROR_NUMBER()<>51922 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_FailWork @WorkItemId=@LeaseId,@ClaimToken=@LeaseToken,@FailureCode='DEMO.EXPIRED'; THROW 52947,N'Fail akzeptierte eine abgelaufene Lease.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=52947 OR ERROR_NUMBER()<>51928 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=@LeaseId,@ClaimToken=@LeaseToken; THROW 52948,N'Heartbeat belebte eine abgelaufene Lease wieder.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=52948 OR ERROR_NUMBER()<>51953 THROW; END CATCH;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@LeaseId AND Status='CLAIMED' AND IsLeaseExpired=1) THROW 52949,N'Der abgelaufene Claim ist nicht beobachtbar.',1;

CREATE TABLE #Recovery(Dummy int NULL);
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=1,@ResultTable=N'#Recovery';
IF NOT EXISTS(SELECT 1 FROM #Recovery WHERE WorkItemId=@LeaseId AND Status='QUEUED' AND ClaimGeneration=1 AND RecoveryCount=1) THROW 52950,N'Die explizite Recovery ist inkonsistent.',1;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@LeaseId AND ClaimToken IS NOT NULL) THROW 52951,N'Die Recovery invalidierte den alten ClaimToken nicht.',1;
BEGIN TRY EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@LeaseId,@ClaimToken=@LeaseToken; THROW 52952,N'Ein invalidierter Token blieb verwendbar.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=52952 OR ERROR_NUMBER()<>51922 THROW; END CATCH;

EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
IF (SELECT WorkItemId FROM #Claim)<>@LeaseId OR (SELECT ClaimGeneration FROM #Claim)<>2 OR (SELECT ClaimToken FROM #Claim)=@LeaseToken THROW 52953,N'Der Claim nach Recovery besitzt keine neue Ownership.',1;
DECLARE @RecoveredToken uniqueidentifier=(SELECT ClaimToken FROM #Claim);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@LeaseId,@ClaimToken=@RecoveredToken;
DROP TABLE #Recovery;
DROP TABLE #Lease;

DROP TABLE IF EXISTS dbo.TbxQueueChild;
DROP TABLE IF EXISTS dbo.TbxQueueParent;
CREATE TABLE dbo.TbxQueueParent(Id int NOT NULL CONSTRAINT PK_TbxQueueParent PRIMARY KEY);
CREATE TABLE dbo.TbxQueueChild(Id int NOT NULL,ParentId int NOT NULL,CONSTRAINT FK_TbxQueueChild_Parent FOREIGN KEY(ParentId) REFERENCES dbo.TbxQueueParent(Id));
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.TbxQueueChild(Id,ParentId) VALUES(1,999);
    THROW 52925,N'Der synthetische Constraintfehler blieb aus.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=52925 THROW;
    IF XACT_STATE()<>-1 THROW 52926,N'Der Caller ist nicht uncommittable.',1;
    BEGIN TRY EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.none'; THROW 52927,N'Enqueue akzeptierte einen uncommittable Caller.',1; END TRY
    BEGIN CATCH IF ERROR_NUMBER()=52927 OR ERROR_NUMBER()<>51906 BEGIN ROLLBACK TRANSACTION; THROW; END; END CATCH;
    ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;
DROP TABLE dbo.TbxQueueChild;
DROP TABLE dbo.TbxQueueParent;

DROP TABLE #ClaimAfterRestore;
DROP TABLE #Claim;
DROP TABLE #Status;
DELETE wi FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId WHERE wt.WorkTypeName LIKE 'test.queue.%';
DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName LIKE 'test.queue.%';
DROP PROCEDURE dbo.USP_TbxQueueNone;
DROP PROCEDURE dbo.USP_TbxQueueJson;
PRINT N'Work Queue Contract: erfolgreich';
GO
