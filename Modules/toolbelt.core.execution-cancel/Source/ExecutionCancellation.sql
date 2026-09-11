SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.ExecutionCancellation', N'U') IS NULL
BEGIN
CREATE TABLE [toolbelt_core].[ExecutionCancellation]
(
      [ExecutionId] uniqueidentifier NOT NULL
    , [RequestedAtUtc] datetime2(7) NOT NULL
        CONSTRAINT [DF_ExecutionCancellation_RequestedAtUtc] DEFAULT (SYSUTCDATETIME())
    , [RequestedBy] sysname NOT NULL
    , [CancellationReason] nvarchar(512) NULL
    , [RowVersion] rowversion NOT NULL
    , CONSTRAINT [PK_ExecutionCancellation] PRIMARY KEY CLUSTERED ([ExecutionId])
);
END;
GO
