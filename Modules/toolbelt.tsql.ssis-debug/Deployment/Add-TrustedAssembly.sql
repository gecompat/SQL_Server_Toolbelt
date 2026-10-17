:On Error exit
-- Getrenntes administratives Opt-in; niemals vom Deploy automatisch aufgerufen.
DECLARE @Hash varbinary(64)=$(AssemblySha512);
IF DATALENGTH(@Hash)<>64 THROW 50000,N'TBX_SSISDBG_lifecycle_trust: Exakter SHA2-512-Releasehash erforderlich.',1;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=@Hash)
 EXEC sys.sp_add_trusted_assembly @hash=@Hash,@description=N'SQL Server Toolbelt toolbelt.tsql.ssis-debug 1.0.0';
