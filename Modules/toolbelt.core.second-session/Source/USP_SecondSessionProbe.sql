SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_SecondSessionProbe]
      @RemoteSessionId   int     OUTPUT
    , @RemoteDatabaseName sysname OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @RemoteSessionId = @@SPID;
    SET @RemoteDatabaseName = DB_NAME();
    RETURN 0;
END;
GO
