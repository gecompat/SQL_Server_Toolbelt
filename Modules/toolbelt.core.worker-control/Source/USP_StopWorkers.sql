-- Objekt: toolbelt_core.USP_StopWorkers
-- Zweck: Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_StopWorkers
 @WorkersTable sysname=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_StopWorkers' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen.',NULL),
 ('PARAMETER',1,N'@WorkersTable',N'sysname',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkersTable',NULL),
 ('PARAMETER',2,N'@ResultTable',N'sysname',0,1,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',3,N'@KeepData',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',4,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',5,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'WorkerId',N'uniqueidentifier',0,0,NULL,N'WorkerId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'WorkerGeneration',N'bigint',0,0,NULL,N'WorkerGeneration gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'SlotReservationId',N'uniqueidentifier',0,1,NULL,N'SlotReservationId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'StopStatus',N'varchar(24)',0,0,NULL,N'StopStatus gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',5,N'HoldVersion',N'binary(8)',0,1,NULL,N'HoldVersion gemäß Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 CREATE TABLE #tbx_USP_StopWorkers_Result(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,SlotReservationId uniqueidentifier NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NULL);
 -- Prozedurscope: SQL Server restauriert SET-Optionen bei Return/THROW.
 -- Kein dynamisches SET kann den Aufruferkontext restaurieren.
 SET LOCK_TIMEOUT 0;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 BEGIN THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;END;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkersTable IS NULL OR LEFT(@WorkersTable,1)<>N'#' OR LEFT(@WorkersTable,2)=N'##' THROW 54226,N'WorkersTable muss caller-lokal sein.',1;
 DECLARE @WorkersObjectId int=OBJECT_ID(N'tempdb..'+@WorkersTable,N'U');
 IF @WorkersObjectId IS NULL OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@WorkersObjectId)<>2
 OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@WorkersObjectId AND name=N'WorkerId' AND system_type_id=36 AND user_type_id=36 AND is_nullable=0)
 OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@WorkersObjectId AND name=N'WorkerGeneration' AND system_type_id=127 AND user_type_id=127 AND is_nullable=0) THROW 54226,N'Die WorkersTable besitzt keine exakte zweispaltige Form.',2;
 CREATE TABLE #tbx_StopWorkersSelection(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,PRIMARY KEY(WorkerId,WorkerGeneration));
 DECLARE @SelectionSql nvarchar(max)=N'INSERT #tbx_StopWorkersSelection(WorkerId,WorkerGeneration) SELECT WorkerId,WorkerGeneration FROM '+QUOTENAME(@WorkersTable);
 EXEC sys.sp_executesql @SelectionSql;
 IF (SELECT COUNT_BIG(*) FROM #tbx_StopWorkersSelection)>1000 OR EXISTS(SELECT 1 FROM #tbx_StopWorkersSelection WHERE WorkerGeneration<=0) THROW 54226,N'Die eingefrorene Workerselektion ist ungültig.',3;
 IF EXISTS(SELECT 1 FROM #tbx_StopWorkersSelection s WHERE NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration w WHERE w.WorkerId=s.WorkerId AND w.WorkerGeneration=s.WorkerGeneration)) THROW 54226,N'Eine ausgewählte exakte Generation fehlt.',4;
 CREATE TABLE #tbx_StopWorkersReservations(SlotReservationId uniqueidentifier NOT NULL PRIMARY KEY,WorkItemId bigint NOT NULL,WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
 INSERT #tbx_StopWorkersReservations SELECT r.SlotReservationId,r.WorkItemId,r.WorkerId,r.WorkerGeneration FROM toolbelt_core.WorkerSlotReservation r JOIN #tbx_StopWorkersSelection s ON s.WorkerId=r.WorkerId AND s.WorkerGeneration=r.WorkerGeneration WHERE r.IsOccupied=1;
 IF (SELECT COUNT_BIG(*) FROM #tbx_StopWorkersReservations)>100000 THROW 54226,N'Das explizite Reservationselektionslimit ist überschritten.',5;
 -- Alle Gates ohne Warten gewinnen oder atomar vollständig abbrechen: globale Locks
 -- werden niemals beim Warten auf einen privaten äußeren Commit festgehalten.
 DECLARE @Reservation uniqueidentifier,@Resource nvarchar(255),@Lock int;
 DECLARE stop_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT SlotReservationId FROM #tbx_StopWorkersReservations ORDER BY SlotReservationId;
 OPEN stop_cursor;FETCH NEXT FROM stop_cursor INTO @Reservation;
 WHILE @@FETCH_STATUS=0 BEGIN
 SET @Resource=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@Reservation);
 EXEC @Lock=sys.sp_getapplock @Resource=@Resource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @Lock<0 BEGIN CLOSE stop_cursor;DEALLOCATE stop_cursor;THROW 54222,N'Die atomare Stopselektion kollidiert mit einem privaten Completionpfad.',4;END;
 FETCH NEXT FROM stop_cursor INTO @Reservation; END;
 CLOSE stop_cursor;DEALLOCATE stop_cursor;
 CREATE TABLE #tbx_StopWorkersCommitted(SlotReservationId uniqueidentifier NOT NULL PRIMARY KEY);
 DECLARE @CommittedReservation uniqueidentifier;
 DECLARE committed_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT r.SlotReservationId FROM #tbx_StopWorkersReservations r JOIN toolbelt_core.WorkItem wi ON wi.WorkItemId=r.WorkItemId AND wi.Status='COMPLETED' AND wi.ManagedReservationId=r.SlotReservationId;
 OPEN committed_cursor;FETCH NEXT FROM committed_cursor INTO @CommittedReservation;
 WHILE @@FETCH_STATUS=0 BEGIN
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(READCOMMITTEDLOCK) WHERE SlotReservationId=@CommittedReservation)
 INSERT #tbx_StopWorkersCommitted VALUES(@CommittedReservation);
 FETCH NEXT FROM committed_cursor INTO @CommittedReservation;END;
 CLOSE committed_cursor;DEALLOCATE committed_cursor;
 UPDATE reservation SET State='COMMITTED',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) FROM toolbelt_core.WorkerSlotReservation reservation JOIN #tbx_StopWorkersCommitted committed ON committed.SlotReservationId=reservation.SlotReservationId;
 UPDATE d SET StopStatus='ALREADY_COMMITTED',IsHeld=0 FROM toolbelt_core.WorkerExecutionDisposition d JOIN #tbx_StopWorkersCommitted committed ON committed.SlotReservationId=d.SlotReservationId;
 UPDATE w SET AdmissionPaused=1 FROM toolbelt_core.WorkerRegistration w WHERE EXISTS(SELECT 1 FROM #tbx_StopWorkersSelection s WHERE s.WorkerId=w.WorkerId);
 UPDATE w SET State=CASE WHEN State IN('CLOSED','UNREACHABLE') THEN State ELSE 'PAUSED' END FROM toolbelt_core.WorkerRegistration w JOIN #tbx_StopWorkersSelection s ON s.WorkerId=w.WorkerId AND s.WorkerGeneration=w.WorkerGeneration;
 UPDATE d SET IsHeld=1,StopStatus='REQUESTED' FROM toolbelt_core.WorkerExecutionDisposition d JOIN #tbx_StopWorkersReservations r ON r.SlotReservationId=d.SlotReservationId WHERE NOT EXISTS(SELECT 1 FROM #tbx_StopWorkersCommitted committed WHERE committed.SlotReservationId=r.SlotReservationId);
 UPDATE wi SET ManagedHold=1 FROM toolbelt_core.WorkItem wi JOIN #tbx_StopWorkersReservations r ON r.WorkItemId=wi.WorkItemId WHERE wi.ManagedReservationId=r.SlotReservationId AND NOT EXISTS(SELECT 1 FROM #tbx_StopWorkersCommitted committed WHERE committed.SlotReservationId=r.SlotReservationId);
 UPDATE r SET State='STOP_REQUESTED' FROM toolbelt_core.WorkerSlotReservation r JOIN #tbx_StopWorkersReservations s ON s.SlotReservationId=r.SlotReservationId WHERE r.IsOccupied=1;
 INSERT #tbx_USP_StopWorkers_Result SELECT s.WorkerId,s.WorkerGeneration,r.SlotReservationId,ISNULL(d.StopStatus,'NO_ACTIVE_EXECUTION'),d.HoldVersion FROM #tbx_StopWorkersSelection s LEFT JOIN #tbx_StopWorkersReservations r ON r.WorkerId=s.WorkerId AND r.WorkerGeneration=s.WorkerGeneration LEFT JOIN toolbelt_core.WorkerExecutionDisposition d ON d.SlotReservationId=r.SlotReservationId;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_StopWorkers_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkerId,WorkerGeneration,SlotReservationId,StopStatus,HoldVersion) SELECT WorkerId,WorkerGeneration,SlotReservationId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkers_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;

 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION;  THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkerId,WorkerGeneration,SlotReservationId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkers_Result;
 RETURN 0;
END;
GO
