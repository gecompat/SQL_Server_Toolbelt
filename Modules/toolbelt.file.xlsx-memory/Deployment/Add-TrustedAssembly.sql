:On Error exit
SET NOCOUNT ON;
-- Separate administrator opt-in, exact hash only; no instance setting changes.
IF IS_SRVROLEMEMBER(N'sysadmin')<>1 THROW 51531,N'Trust-Opt-in benötigt sysadmin.',1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
 OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THROW 51531,N'CLR und strict security müssen aktiviert sein.',1;
DECLARE @Hash varbinary(max)=TRY_CONVERT(varbinary(max),N'$(AssemblyHash)',1),
 @Description nvarchar(4000)=N'$(AssemblyDescription)';
IF @Hash IS NULL OR DATALENGTH(@Hash)<>64 OR NULLIF(@Description,N'') IS NULL
 THROW 51531,N'Exakter SHA2-512-Hash und Beschreibung benötigt.',1;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash)
 EXEC sys.sp_add_trusted_assembly @hash=@Hash,@description=@Description;
GO
