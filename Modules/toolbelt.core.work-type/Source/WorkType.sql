SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[WorkType]
    (
          [WorkTypeId]             bigint IDENTITY(1,1) NOT NULL
        , [WorkTypeName]           varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [HandlerSchema]          sysname NOT NULL
        , [HandlerProcedure]       sysname NOT NULL
        , [ParameterMode]          varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_WorkType_ParameterMode] DEFAULT ('NONE')
        , [PayloadContractJson]    nvarchar(4000) NULL
        , [DefaultTimeoutSeconds]  int NOT NULL CONSTRAINT [DF_WorkType_DefaultTimeoutSeconds] DEFAULT (300)
        , [IsIdempotent]           bit NOT NULL CONSTRAINT [DF_WorkType_IsIdempotent] DEFAULT (0)
        , [IsEnabled]              bit NOT NULL CONSTRAINT [DF_WorkType_IsEnabled] DEFAULT (1)
        , [Description]            nvarchar(1000) NULL
        , [CreatedAtUtc]           datetime2(7) NOT NULL CONSTRAINT [DF_WorkType_CreatedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [CreatedBy]              sysname NOT NULL CONSTRAINT [DF_WorkType_CreatedBy] DEFAULT (ORIGINAL_LOGIN())
        , [ModifiedAtUtc]          datetime2(7) NOT NULL CONSTRAINT [DF_WorkType_ModifiedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [ModifiedBy]             sysname NOT NULL CONSTRAINT [DF_WorkType_ModifiedBy] DEFAULT (ORIGINAL_LOGIN())
        , [DisabledAtUtc]          datetime2(7) NULL
        , [DisabledBy]             sysname NULL
        , [DisabledReason]         nvarchar(1000) NULL
        , [RowVersion]             rowversion NOT NULL
        , CONSTRAINT [PK_WorkType]
            PRIMARY KEY CLUSTERED ([WorkTypeId])
        , CONSTRAINT [UQ_WorkType_WorkTypeName]
            UNIQUE NONCLUSTERED ([WorkTypeName])
        , CONSTRAINT [CK_WorkType_WorkTypeName]
            CHECK
            (
                LEN([WorkTypeName]) BETWEEN 3 AND 128
                AND [WorkTypeName] = LOWER([WorkTypeName]) COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] NOT LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
                AND [WorkTypeName] NOT LIKE '%.'
                AND [WorkTypeName] NOT LIKE '.%'
                AND [WorkTypeName] NOT LIKE '%..%'
            )
        , CONSTRAINT [CK_WorkType_ParameterMode]
            CHECK ([ParameterMode] IN ('NONE', 'JSON_PAYLOAD'))
        , CONSTRAINT [CK_WorkType_PayloadContract]
            CHECK
            (
                ([ParameterMode] = 'NONE' AND [PayloadContractJson] IS NULL)
                OR
                (
                    [ParameterMode] = 'JSON_PAYLOAD'
                    AND [PayloadContractJson] IS NOT NULL
                    AND ISJSON([PayloadContractJson]) = 1
                    AND LEFT(LTRIM([PayloadContractJson]), 1) = N'{'
                )
            )
        , CONSTRAINT [CK_WorkType_DefaultTimeoutSeconds]
            CHECK ([DefaultTimeoutSeconds] BETWEEN 1 AND 86400)
        , CONSTRAINT [CK_WorkType_DisabledMetadata]
            CHECK
            (
                ([IsEnabled] = 1 AND [DisabledAtUtc] IS NULL AND [DisabledBy] IS NULL AND [DisabledReason] IS NULL)
                OR
                ([IsEnabled] = 0 AND [DisabledAtUtc] IS NOT NULL AND [DisabledBy] IS NOT NULL)
            )
    );

    CREATE NONCLUSTERED INDEX [IX_WorkType_IsEnabled_WorkTypeName]
        ON [toolbelt_core].[WorkType] ([IsEnabled], [WorkTypeName])
        INCLUDE
        (
              [HandlerSchema]
            , [HandlerProcedure]
            , [ParameterMode]
            , [DefaultTimeoutSeconds]
            , [IsIdempotent]
        );
END;
GO
