IF OBJECT_ID(N'toolbelt_filesystem.FileSystemRoot', N'U') IS NULL
BEGIN
CREATE TABLE [toolbelt_filesystem].[FileSystemRoot]
(
      RootAlias            sysname         NOT NULL
    , RootPath             nvarchar(4000)  NOT NULL
    , WorkPath             nvarchar(4000)  NULL
    , AllowRead            bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowRead] DEFAULT (1)
    , AllowWrite           bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowWrite] DEFAULT (0)
    , AllowList            bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowList] DEFAULT (1)
    , AllowDelete          bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowDelete] DEFAULT (0)
    , AllowCreateDirectory bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowCreateDirectory] DEFAULT (0)
    , IsActive             bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_IsActive] DEFAULT (1)
    , CONSTRAINT [PK_FileSystemRoot] PRIMARY KEY CLUSTERED (RootAlias)
    , CONSTRAINT [CK_FileSystemRoot_RootAlias] CHECK (RootAlias NOT LIKE N'%[^A-Za-z0-9_-]%')
    , CONSTRAINT [CK_FileSystemRoot_WorkPathRelative] CHECK (WorkPath IS NULL OR (WorkPath NOT LIKE N'%:%' AND WorkPath NOT LIKE N'/%' AND WorkPath NOT LIKE N'\\%'))
);
END;
GO
