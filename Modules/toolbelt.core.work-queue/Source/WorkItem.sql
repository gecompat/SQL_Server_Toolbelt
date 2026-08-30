SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.WorkItem', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[WorkItem]
    (
          [WorkItemId] bigint IDENTITY(1,1) NOT NULL
        , [WorkTypeId] bigint NOT NULL
        , [PayloadJson] nvarchar(max) NULL
        , [Status] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_WorkItem_Status] DEFAULT ('QUEUED')
        , [EnqueuedAtUtc] datetime2(7) NOT NULL CONSTRAINT [DF_WorkItem_EnqueuedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [EnqueuedBy] sysname NOT NULL CONSTRAINT [DF_WorkItem_EnqueuedBy] DEFAULT (ORIGINAL_LOGIN())
        , [ClaimedAtUtc] datetime2(7) NULL
        , [ClaimedBy] sysname NULL
        , [ClaimToken] uniqueidentifier NULL
        , [ClaimGeneration] bigint NOT NULL CONSTRAINT [DF_WorkItem_ClaimGeneration] DEFAULT (0)
        , [LeaseDurationSeconds] int NULL
        , [LeaseUntilUtc] datetime2(7) NULL
        , [LastHeartbeatAtUtc] datetime2(7) NULL
        , [RecoveryCount] bigint NOT NULL CONSTRAINT [DF_WorkItem_RecoveryCount] DEFAULT (0)
        , [LastRecoveredAtUtc] datetime2(7) NULL
        , [LastRecoveredBy] sysname NULL
        , [CompletedAtUtc] datetime2(7) NULL
        , [CompletedBy] sysname NULL
        , [FailedAtUtc] datetime2(7) NULL
        , [FailedBy] sysname NULL
        , [FailureCode] varchar(64) COLLATE Latin1_General_100_BIN2 NULL
        , [FailureMessage] nvarchar(1000) NULL
        , [RowVersion] rowversion NOT NULL
        , CONSTRAINT [PK_WorkItem] PRIMARY KEY CLUSTERED ([WorkItemId])
        , CONSTRAINT [FK_WorkItem_WorkType] FOREIGN KEY ([WorkTypeId]) REFERENCES [toolbelt_core].[WorkType] ([WorkTypeId])
        , CONSTRAINT [CK_WorkItem_Status] CHECK ([Status] IN ('QUEUED', 'CLAIMED', 'COMPLETED', 'FAILED'))
        , CONSTRAINT [CK_WorkItem_PayloadJson] CHECK
          (
              [PayloadJson] IS NULL OR
              (DATALENGTH([PayloadJson]) <= 65536 AND ISJSON([PayloadJson]) = 1 AND LEFT(LTRIM([PayloadJson]), 1) = N'{')
          )
        , CONSTRAINT [CK_WorkItem_FailureCode] CHECK
          (
              [FailureCode] IS NULL OR
              (LEN([FailureCode]) BETWEEN 1 AND 64
               AND [FailureCode] LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2
               AND [FailureCode] NOT LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2)
          )
        , CONSTRAINT [CK_WorkItem_RecoveryMetadata] CHECK
          (
              ([RecoveryCount] = 0 AND [LastRecoveredAtUtc] IS NULL AND [LastRecoveredBy] IS NULL)
              OR ([RecoveryCount] > 0 AND [LastRecoveredAtUtc] IS NOT NULL AND [LastRecoveredBy] IS NOT NULL)
          )
        , CONSTRAINT [CK_WorkItem_StateMetadata] CHECK
          (
              ([Status] = 'QUEUED'
               AND [ClaimedAtUtc] IS NULL AND [ClaimedBy] IS NULL AND [ClaimToken] IS NULL
               AND [LeaseDurationSeconds] IS NULL AND [LeaseUntilUtc] IS NULL AND [LastHeartbeatAtUtc] IS NULL
               AND [CompletedAtUtc] IS NULL AND [CompletedBy] IS NULL
               AND [FailedAtUtc] IS NULL AND [FailedBy] IS NULL
               AND [FailureCode] IS NULL AND [FailureMessage] IS NULL)
              OR
              ([Status] = 'CLAIMED'
               AND [ClaimedAtUtc] IS NOT NULL AND [ClaimedBy] IS NOT NULL AND [ClaimToken] IS NOT NULL
               AND [ClaimGeneration] > 0 AND [LeaseDurationSeconds] BETWEEN 5 AND 86400
               AND [LeaseUntilUtc] IS NOT NULL AND [LastHeartbeatAtUtc] IS NOT NULL
               AND [CompletedAtUtc] IS NULL AND [CompletedBy] IS NULL
               AND [FailedAtUtc] IS NULL AND [FailedBy] IS NULL
               AND [FailureCode] IS NULL AND [FailureMessage] IS NULL)
              OR
              ([Status] = 'COMPLETED'
               AND [ClaimedAtUtc] IS NOT NULL AND [ClaimedBy] IS NOT NULL AND [ClaimToken] IS NOT NULL
               AND [ClaimGeneration] > 0 AND [LeaseDurationSeconds] BETWEEN 5 AND 86400
               AND [LeaseUntilUtc] IS NOT NULL AND [LastHeartbeatAtUtc] IS NOT NULL
               AND [CompletedAtUtc] IS NOT NULL AND [CompletedBy] IS NOT NULL
               AND [FailedAtUtc] IS NULL AND [FailedBy] IS NULL
               AND [FailureCode] IS NULL AND [FailureMessage] IS NULL)
              OR
              ([Status] = 'FAILED'
               AND [ClaimedAtUtc] IS NOT NULL AND [ClaimedBy] IS NOT NULL AND [ClaimToken] IS NOT NULL
               AND [ClaimGeneration] > 0 AND [LeaseDurationSeconds] BETWEEN 5 AND 86400
               AND [LeaseUntilUtc] IS NOT NULL AND [LastHeartbeatAtUtc] IS NOT NULL
               AND [CompletedAtUtc] IS NULL AND [CompletedBy] IS NULL
               AND [FailedAtUtc] IS NOT NULL AND [FailedBy] IS NOT NULL
               AND [FailureCode] IS NOT NULL)
          )
    );

    CREATE NONCLUSTERED INDEX [IX_WorkItem_Status_WorkItemId]
        ON [toolbelt_core].[WorkItem] ([Status], [WorkItemId]) INCLUDE ([WorkTypeId]);
    CREATE NONCLUSTERED INDEX [IX_WorkItem_WorkTypeId_Status_WorkItemId]
        ON [toolbelt_core].[WorkItem] ([WorkTypeId], [Status], [WorkItemId]);
    CREATE NONCLUSTERED INDEX [IX_WorkItem_Status_LeaseUntilUtc_WorkItemId]
        ON [toolbelt_core].[WorkItem] ([Status], [LeaseUntilUtc], [WorkItemId]);
END
ELSE
BEGIN
    /* Aktive V1-Claims wurden vor der ersten Mutation durch Deploy.sql ausgeschlossen. */
    IF COL_LENGTH(N'toolbelt_core.WorkItem', N'ClaimGeneration') IS NULL
    BEGIN
        ALTER TABLE toolbelt_core.WorkItem ADD
              ClaimGeneration bigint NULL
            , LeaseDurationSeconds int NULL
            , LeaseUntilUtc datetime2(7) NULL
            , LastHeartbeatAtUtc datetime2(7) NULL
            , RecoveryCount bigint NULL
            , LastRecoveredAtUtc datetime2(7) NULL
            , LastRecoveredBy sysname NULL;

        EXEC sys.sp_executesql N'
            UPDATE toolbelt_core.WorkItem
            SET
                  ClaimGeneration = CASE WHEN Status = ''QUEUED'' THEN 0 ELSE 1 END
                , LeaseDurationSeconds = CASE WHEN Status = ''QUEUED'' THEN NULL ELSE 300 END
                , LeaseUntilUtc = CASE WHEN Status = ''QUEUED'' THEN NULL ELSE DATEADD(SECOND, 300, ClaimedAtUtc) END
                , LastHeartbeatAtUtc = CASE WHEN Status = ''QUEUED'' THEN NULL ELSE ClaimedAtUtc END
                , RecoveryCount = 0;
            ALTER TABLE toolbelt_core.WorkItem ALTER COLUMN ClaimGeneration bigint NOT NULL;
            ALTER TABLE toolbelt_core.WorkItem ALTER COLUMN RecoveryCount bigint NOT NULL;
            ALTER TABLE toolbelt_core.WorkItem ADD
                  CONSTRAINT DF_WorkItem_ClaimGeneration DEFAULT (0) FOR ClaimGeneration
                , CONSTRAINT DF_WorkItem_RecoveryCount DEFAULT (0) FOR RecoveryCount;';
    END;

    IF OBJECT_ID(N'toolbelt_core.CK_WorkItem_StateMetadata', N'C') IS NOT NULL
        ALTER TABLE toolbelt_core.WorkItem DROP CONSTRAINT CK_WorkItem_StateMetadata;
    IF OBJECT_ID(N'toolbelt_core.CK_WorkItem_RecoveryMetadata', N'C') IS NOT NULL
        ALTER TABLE toolbelt_core.WorkItem DROP CONSTRAINT CK_WorkItem_RecoveryMetadata;

    EXEC sys.sp_executesql N'
    ALTER TABLE toolbelt_core.WorkItem WITH CHECK ADD CONSTRAINT CK_WorkItem_RecoveryMetadata CHECK
    (
        (RecoveryCount = 0 AND LastRecoveredAtUtc IS NULL AND LastRecoveredBy IS NULL)
        OR (RecoveryCount > 0 AND LastRecoveredAtUtc IS NOT NULL AND LastRecoveredBy IS NOT NULL)
    );
    ALTER TABLE toolbelt_core.WorkItem WITH CHECK ADD CONSTRAINT CK_WorkItem_StateMetadata CHECK
    (
        (Status = ''QUEUED''
         AND ClaimedAtUtc IS NULL AND ClaimedBy IS NULL AND ClaimToken IS NULL
         AND LeaseDurationSeconds IS NULL AND LeaseUntilUtc IS NULL AND LastHeartbeatAtUtc IS NULL
         AND CompletedAtUtc IS NULL AND CompletedBy IS NULL
         AND FailedAtUtc IS NULL AND FailedBy IS NULL
         AND FailureCode IS NULL AND FailureMessage IS NULL)
        OR
        (Status = ''CLAIMED''
         AND ClaimedAtUtc IS NOT NULL AND ClaimedBy IS NOT NULL AND ClaimToken IS NOT NULL
         AND ClaimGeneration > 0 AND LeaseDurationSeconds BETWEEN 5 AND 86400
         AND LeaseUntilUtc IS NOT NULL AND LastHeartbeatAtUtc IS NOT NULL
         AND CompletedAtUtc IS NULL AND CompletedBy IS NULL
         AND FailedAtUtc IS NULL AND FailedBy IS NULL
         AND FailureCode IS NULL AND FailureMessage IS NULL)
        OR
        (Status = ''COMPLETED''
         AND ClaimedAtUtc IS NOT NULL AND ClaimedBy IS NOT NULL AND ClaimToken IS NOT NULL
         AND ClaimGeneration > 0 AND LeaseDurationSeconds BETWEEN 5 AND 86400
         AND LeaseUntilUtc IS NOT NULL AND LastHeartbeatAtUtc IS NOT NULL
         AND CompletedAtUtc IS NOT NULL AND CompletedBy IS NOT NULL
         AND FailedAtUtc IS NULL AND FailedBy IS NULL
         AND FailureCode IS NULL AND FailureMessage IS NULL)
        OR
        (Status = ''FAILED''
         AND ClaimedAtUtc IS NOT NULL AND ClaimedBy IS NOT NULL AND ClaimToken IS NOT NULL
         AND ClaimGeneration > 0 AND LeaseDurationSeconds BETWEEN 5 AND 86400
         AND LeaseUntilUtc IS NOT NULL AND LastHeartbeatAtUtc IS NOT NULL
         AND CompletedAtUtc IS NULL AND CompletedBy IS NULL
         AND FailedAtUtc IS NOT NULL AND FailedBy IS NOT NULL
         AND FailureCode IS NOT NULL)
    );';

    IF NOT EXISTS
       (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'toolbelt_core.WorkItem')
        AND name = N'IX_WorkItem_Status_LeaseUntilUtc_WorkItemId')
        EXEC sys.sp_executesql N'CREATE NONCLUSTERED INDEX IX_WorkItem_Status_LeaseUntilUtc_WorkItemId
            ON toolbelt_core.WorkItem (Status, LeaseUntilUtc, WorkItemId);';
END;
GO
