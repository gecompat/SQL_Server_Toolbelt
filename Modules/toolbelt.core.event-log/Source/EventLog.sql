SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.EventLog', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[EventLog]
    (
          [EventId] bigint IDENTITY(1,1) NOT NULL
        , [OccurredAtUtc] datetime2(7) NOT NULL
        , [RecordedAtUtc] datetime2(7) NOT NULL CONSTRAINT [DF_EventLog_RecordedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [EventName] varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [EventLevel] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [Category] varchar(128) COLLATE Latin1_General_100_BIN2 NULL
        , [Message] nvarchar(4000) NULL
        , [DataJson] nvarchar(max) NULL
        , [ExecutionId] uniqueidentifier NOT NULL
        , [CorrelationId] uniqueidentifier NOT NULL
        , [Actor] nvarchar(256) NULL
        , [Tenant] nvarchar(256) NULL
        , [SourceDatabaseName] sysname NOT NULL
        , [SourceSchemaName] sysname NULL
        , [SourceObjectName] sysname NULL
        , [CallerSessionId] int NOT NULL
        , [CallerXactState] smallint NOT NULL
        , [CallerTransactionCount] int NOT NULL
        , [RemoteSessionId] int NOT NULL
        , [ErrorNumber] int NULL
        , [ErrorSeverity] int NULL
        , [ErrorState] int NULL
        , [ErrorProcedure] sysname NULL
        , [ErrorLine] int NULL
        , CONSTRAINT [PK_EventLog] PRIMARY KEY CLUSTERED ([EventId])
        , CONSTRAINT [CK_EventLog_EventName] CHECK
          (
              LEN([EventName]) BETWEEN 3 AND 128
              AND [EventName] = LOWER([EventName]) COLLATE Latin1_General_100_BIN2
              AND [EventName] LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
              AND [EventName] NOT LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
          )
        , CONSTRAINT [CK_EventLog_EventLevel] CHECK ([EventLevel] IN ('TRACE','DEBUG','INFO','WARNING','ERROR','CRITICAL'))
        , CONSTRAINT [CK_EventLog_DataJson] CHECK ([DataJson] IS NULL OR (ISJSON([DataJson]) = 1 AND LEFT(LTRIM([DataJson]), 1) = N'{'))
        , CONSTRAINT [CK_EventLog_CallerXactState] CHECK ([CallerXactState] IN (-1,0,1))
        , CONSTRAINT [CK_EventLog_ErrorSeverity] CHECK ([ErrorSeverity] IS NULL OR [ErrorSeverity] BETWEEN 0 AND 25)
        , CONSTRAINT [CK_EventLog_ErrorState] CHECK ([ErrorState] IS NULL OR [ErrorState] BETWEEN 0 AND 255)
        , CONSTRAINT [CK_EventLog_ErrorLine] CHECK ([ErrorLine] IS NULL OR [ErrorLine] > 0)
    );

    CREATE INDEX [IX_EventLog_OccurredAtUtc_EventId]
        ON [toolbelt_core].[EventLog]([OccurredAtUtc], [EventId]);
    CREATE INDEX [IX_EventLog_CorrelationId_OccurredAtUtc]
        ON [toolbelt_core].[EventLog]([CorrelationId], [OccurredAtUtc])
        INCLUDE ([EventName], [EventLevel], [Category]);
    CREATE INDEX [IX_EventLog_ExecutionId_OccurredAtUtc]
        ON [toolbelt_core].[EventLog]([ExecutionId], [OccurredAtUtc])
        INCLUDE ([EventName], [EventLevel], [Category]);
END;
GO
