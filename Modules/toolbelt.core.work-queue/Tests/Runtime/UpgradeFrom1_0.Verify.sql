:On Error exit
SET NOCOUNT ON;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.0.0')
    THROW 52970,N'Der Upgrade-Marker fehlt.',1;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>2 THROW 52971,N'Der Upgrade verlor persistente Items.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='QUEUED' AND ClaimGeneration=0 AND RecoveryCount=0 AND LeaseUntilUtc IS NULL)
    THROW 52972,N'Das QUEUED-Vorgängeritem wurde falsch migriert.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='COMPLETED' AND ClaimGeneration=1 AND LeaseDurationSeconds=300 AND LastHeartbeatAtUtc=ClaimedAtUtc)
    THROW 52973,N'Das terminale Vorgängeritem wurde falsch migriert.',1;
IF OBJECT_ID(N'toolbelt_core.USP_RenewWorkLease',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_RecoverExpiredWork',N'P') IS NULL
    THROW 52974,N'Die E1b-Objekte fehlen nach dem Upgrade.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE ExecutionGroup='default' AND Priority=0 AND MaxAttempts=3 AND RetryBaseDelaySeconds=60 AND RetryMaxDelaySeconds=3600)
    THROW 52975,N'Die W6c-Default-Policy fehlt nach dem Upgrade.',1;
IF OBJECT_ID(N'toolbelt_core.USP_EnqueueWorkWithPolicy',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_EnqueueBarrierWork',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_ScheduleWorkRetry',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_RequeueDeadLetter',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.VW_WorkQueueBarrierBlockers',N'V') IS NULL
    THROW 52976,N'Die W6c-Objekte fehlen nach dem Upgrade.',1;
PRINT N'Work Queue Upgrade 1.0.0 auf 2.0.0: erfolgreich';
GO
