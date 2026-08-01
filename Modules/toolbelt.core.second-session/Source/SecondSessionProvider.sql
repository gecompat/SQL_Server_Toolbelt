SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NULL
BEGIN
    CREATE TABLE [toolbelt_core].[SecondSessionProvider]
    (
          [ProviderName]     varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL
        , [LinkedServerName] sysname NOT NULL
        , [IsEnabled]        bit NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_IsEnabled] DEFAULT (1)
        , [CreatedAtUtc]     datetime2(7) NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_CreatedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [CreatedBy]        sysname NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_CreatedBy] DEFAULT (ORIGINAL_LOGIN())
        , [ModifiedAtUtc]    datetime2(7) NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_ModifiedAtUtc] DEFAULT (SYSUTCDATETIME())
        , [ModifiedBy]       sysname NOT NULL
            CONSTRAINT [DF_SecondSessionProvider_ModifiedBy] DEFAULT (ORIGINAL_LOGIN())
        , [RowVersion]       rowversion NOT NULL
        , CONSTRAINT [PK_SecondSessionProvider]
            PRIMARY KEY CLUSTERED ([ProviderName])
        , CONSTRAINT [UQ_SecondSessionProvider_LinkedServerName]
            UNIQUE NONCLUSTERED ([LinkedServerName])
        , CONSTRAINT [CK_SecondSessionProvider_ProviderName]
            CHECK ([ProviderName] = 'loopback')
    );
END;
GO
