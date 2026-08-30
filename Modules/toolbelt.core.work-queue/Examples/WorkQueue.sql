-- Synthetisches E1a-Beispiel. Der Work Type muss zuvor registriert sein.
DECLARE @Enqueued TABLE
(
      WorkItemId bigint NOT NULL
    , WorkTypeName varchar(128) NOT NULL
    , Status varchar(16) NOT NULL
    , EnqueuedAtUtc datetime2(7) NOT NULL
    , EnqueuedBy sysname NOT NULL
    , ClaimedAtUtc datetime2(7) NULL
    , ClaimedBy sysname NULL
    , CompletedAtUtc datetime2(7) NULL
    , CompletedBy sysname NULL
    , FailedAtUtc datetime2(7) NULL
    , FailedBy sysname NULL
    , FailureCode varchar(64) NULL
    , FailureMessage nvarchar(1000) NULL
    , RowVersion binary(8) NOT NULL
);

INSERT INTO @Enqueued
EXEC toolbelt_core.USP_EnqueueWork
      @WorkTypeName = 'demo.json'
    , @PayloadJson = N'{"value":1}';

EXEC toolbelt_core.USP_ClaimWork;
