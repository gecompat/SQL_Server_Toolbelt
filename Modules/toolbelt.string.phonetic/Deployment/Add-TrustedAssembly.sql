:On Error exit
-- Getrennter administrativer, ausdrücklicher Hash-Opt-in; kein regulärer Deploy.
SET NOCOUNT ON;
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 55271,N'Trust-Opt-in benötigt sysadmin.',1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
 THROW 55272,N'CLR ist nicht aktiviert; keine Optionsänderung.',1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THROW 55273,N'clr strict security muss aktiviert bleiben.',1;
DECLARE @Text nvarchar(max)=N'$(AssemblyHash)',@Hash varbinary(64),@Description nvarchar(max)=N'$(AssemblyDescription)';
IF @Text IS NULL OR DATALENGTH(@Text)<>260
 OR CONVERT(varbinary(max),LEFT(@Text,2))<>CONVERT(varbinary(max),N'0x')
 OR SUBSTRING(@Text,3,128) COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9A-Fa-f]%'
 OR TRY_CONVERT(varbinary(max),@Text,1) IS NULL OR DATALENGTH(TRY_CONVERT(varbinary(max),@Text,1))<>64
 THROW 55274,N'AssemblyHash benötigt exakt 64 Bytes SHA2-512.',1;
SET @Hash=TRY_CONVERT(varbinary(64),@Text,1);
IF @Description IS NULL OR DATALENGTH(@Description)=0 OR DATALENGTH(@Description)>8000
 THROW 55275,N'AssemblyDescription muss 1 bis 4000 UTF16-Einheiten enthalten.',1;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash)
 EXEC sys.sp_add_trusted_assembly @hash=@Hash,@description=@Description;
GO