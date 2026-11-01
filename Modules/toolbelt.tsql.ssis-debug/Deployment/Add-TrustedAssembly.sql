:On Error exit
-- Getrenntes administratives Opt-in; niemals vom Deploy automatisch aufgerufen.
-- Erst ungekürzt prüfen: varbinary(64) würde überlange Literale bereits bei
-- der Zuweisung abschneiden. NULL muss denselben öffentlichen Guard auslösen.
DECLARE @Hash varbinary(max)=$(AssemblySha512);
IF @Hash IS NULL OR DATALENGTH(@Hash)<>64 THROW 50000,N'TBX_SSISDBG_lifecycle_trust: Exakter SHA2-512-Releasehash erforderlich.',1;
-- Die Systemprozedur erhält erst nach der Prüfung ihren festen Binärtyp.
DECLARE @ValidatedHash varbinary(64)=@Hash;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=@Hash)
 EXEC sys.sp_add_trusted_assembly @hash=@ValidatedHash,@description=N'SQL Server Toolbelt toolbelt.tsql.ssis-debug 1.0.0';
