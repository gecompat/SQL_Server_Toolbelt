:On Error exit
DECLARE @AssemblyBits varbinary(max) = $(AssemblyBits), @Description nvarchar(4000) = N'Toolbelt.Filesystem.Windows 1.0.0';
IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024 THROW 51537, N'AssemblyBits enthält kein plausibles CLR-Release-Binary.', 1;
EXEC sys.sp_add_trusted_assembly @hash = HASHBYTES(N'SHA2_512', @AssemblyBits), @description = @Description;
GO
