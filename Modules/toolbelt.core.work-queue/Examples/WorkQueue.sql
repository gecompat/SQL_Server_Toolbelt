-- Synthetisches E1b-Beispiel. Der Work Type muss zuvor registriert sein.
DECLARE @Enqueued TABLE
(
      WorkItemId bigint NOT NULL,WorkTypeName varchar(128) NOT NULL,Status varchar(16) NOT NULL
    , EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL
    , ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL
    , CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL
    , FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL
    , FailureCode varchar(64) NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL
    , ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL
    , LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NOT NULL,RecoveryCount bigint NOT NULL
    , LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL
);
INSERT INTO @Enqueued
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='demo.json',@PayloadJson=N'{"value":1}';

DECLARE @Claim TABLE
(
      WorkItemId bigint NOT NULL,WorkTypeName varchar(128) NOT NULL,PayloadJson nvarchar(max) NULL
    , ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL
    , ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL
);
INSERT INTO @Claim EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;

DECLARE @WorkItemId bigint=(SELECT WorkItemId FROM @Claim);
DECLARE @ClaimToken uniqueidentifier=(SELECT ClaimToken FROM @Claim);
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken;
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken;

-- Ein Supervisor ruft Recovery ausdrücklich und getrennt auf.
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
