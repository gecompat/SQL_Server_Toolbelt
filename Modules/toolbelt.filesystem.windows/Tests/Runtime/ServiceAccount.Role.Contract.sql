CREATE USER ContosoFilesystemSecurity WITHOUT LOGIN;
GRANT EXECUTE ON SCHEMA::toolbelt_filesystem TO ContosoFilesystemSecurity;
GRANT SELECT ON toolbelt_filesystem.FileSystemRoot TO ContosoFilesystemSecurity;
GRANT EXECUTE ON toolbelt_core.USP_PrepareResultTable TO ContosoFilesystemSecurity;
INSERT toolbelt_filesystem.FileSystemRoot(RootAlias,RootPath,AllowWrite,AllowDelete,AllowCreateDirectory)
VALUES(N'ContosoBootstrap',N'C:\Windows\Temp',1,1,1);
DECLARE @Failure nvarchar(4000);
EXECUTE AS USER=N'ContosoFilesystemSecurity';
BEGIN TRY EXEC toolbelt_filesystem.CLR_ListDirectory @RootAlias=N'ContosoBootstrap',@RelativePath=N'__tbx_absent_probe__',@ExecutionIdentity=N'ServiceAccount'; END TRY
BEGIN CATCH SET @Failure=ERROR_MESSAGE(); END CATCH;
REVERT;
IF @Failure IS NULL OR CHARINDEX(N'ServiceAccountNotAuthorized',@Failure)=0 THROW 52991,N'ServiceAccount role guard failed.',1;
ALTER ROLE toolbelt_filesystem_service_account ADD MEMBER ContosoFilesystemSecurity;
SET @Failure=NULL;
EXECUTE AS USER=N'ContosoFilesystemSecurity';
BEGIN TRY EXEC toolbelt_filesystem.CLR_ListDirectory @RootAlias=N'ContosoBootstrap',@RelativePath=N'__tbx_absent_probe__',@ExecutionIdentity=N'ServiceAccount'; END TRY
BEGIN CATCH SET @Failure=ERROR_MESSAGE(); END CATCH;
REVERT;
IF @Failure IS NULL OR CHARINDEX(N'RootNotAuthorized',@Failure)=0 THROW 52991,N'ServiceAccount root default failed.',2;
UPDATE toolbelt_filesystem.FileSystemRoot SET AllowServiceAccount=1 WHERE RootAlias=N'ContosoBootstrap';

-- Role membership alone must not authorize an attacker-controlled policy role.
ALTER AUTHORIZATION ON ROLE::toolbelt_filesystem_service_account TO ContosoFilesystemSecurity;
SET @Failure=NULL;
EXECUTE AS USER=N'ContosoFilesystemSecurity';
BEGIN TRY EXEC toolbelt_filesystem.CLR_ListDirectory @RootAlias=N'ContosoBootstrap',@RelativePath=N'__tbx_absent_probe__',@ExecutionIdentity=N'ServiceAccount'; END TRY
BEGIN CATCH SET @Failure=ERROR_MESSAGE(); END CATCH;
REVERT;
IF @Failure IS NULL OR CHARINDEX(N'ServiceAccountNotAuthorized',@Failure)=0 THROW 52991,N'ServiceAccount role owner guard failed.',8;
ALTER AUTHORIZATION ON ROLE::toolbelt_filesystem_service_account TO dbo;
