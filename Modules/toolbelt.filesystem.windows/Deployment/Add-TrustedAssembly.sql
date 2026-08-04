:On Error exit
DECLARE @AssemblyBits varbinary(max) = $(AssemblyBits), @AssemblyHash varbinary(64), @Description nvarchar(4000) = N'Toolbelt.Filesystem.Windows 1.0.0';
IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024 THROW 51537, N'AssemblyBits enthält kein plausibles CLR-Release-Binary.', 1;
SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);
EXEC sys.sp_add_trusted_assembly @hash = @AssemblyHash, @description = @Description;
GO
