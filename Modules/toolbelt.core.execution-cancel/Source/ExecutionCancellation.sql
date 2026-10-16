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

-- Legacyanforderungen behalten ihre bisherige Zuordnung. Neue Quoten binden
-- den tatsächlichen DBprincipal, niemals einen übergebenen Namen.
IF COL_LENGTH(N'toolbelt_core.ExecutionCancellation', N'RequestedByPrincipalId') IS NULL
BEGIN
    ALTER TABLE toolbelt_core.ExecutionCancellation ADD
        RequestedByPrincipalId int NULL,
        RequestedByPrincipalSid varbinary(85) NULL,
        RequestedByPrincipalCreatedAt datetime NULL;
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.ExecutionCancellation') AND name=N'IX_ExecutionCancellation_Requester')
    CREATE INDEX IX_ExecutionCancellation_Requester ON toolbelt_core.ExecutionCancellation
        (RequestedByPrincipalId,RequestedByPrincipalSid,RequestedByPrincipalCreatedAt);
GO
