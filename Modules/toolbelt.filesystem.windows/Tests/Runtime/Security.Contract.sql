EXECUTE AS USER=N'ContosoFilesystemSecurity';
BEGIN TRY
EXEC toolbelt_filesystem.USP_WriteBinaryFile @RootAlias=N'ContosoOwn',@RelativePath=N'binary.bin',@Content=0x01020304,@ExecutionIdentity='ServiceAccount';
CREATE TABLE #SecurityChunk(Content varbinary(max) NULL,BytesRead int NOT NULL,NextByteOffset bigint NOT NULL,EndOfFile bit NOT NULL);
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @RootAlias=N'ContosoOwn',@RelativePath=N'binary.bin',@ByteOffset=0,@MaxBytes=16,@ExecutionIdentity='ServiceAccount',@ResultTable=N'#SecurityChunk';
IF NOT EXISTS(SELECT 1 FROM #SecurityChunk WHERE Content=0x01020304 AND BytesRead=4 AND EndOfFile=1) THROW 52991,N'Native binary roundtrip.',3;
EXEC toolbelt_filesystem.USP_WriteTextFile @RootAlias=N'ContosoOwn',@RelativePath=N'text.txt',@Content=N'Contoso €',@EncodingName=N'utf-8',@WriteBom=0,@ExecutionIdentity='ServiceAccount';
CREATE TABLE #SecurityText(Content nvarchar(max) NULL,BytesRead int NOT NULL,NextByteOffset bigint NOT NULL,EndOfFile bit NOT NULL,EncodingName nvarchar(128) NOT NULL);
EXEC toolbelt_filesystem.USP_ReadTextFileChunk @RootAlias=N'ContosoOwn',@RelativePath=N'text.txt',@ByteOffset=0,@MaxBytes=64,@EncodingName=N'utf-8',@ExecutionIdentity='ServiceAccount',@ResultTable=N'#SecurityText';
IF NOT EXISTS(SELECT 1 FROM #SecurityText WHERE Content=N'Contoso €' AND EndOfFile=1) THROW 52991,N'Native text roundtrip.',4;
EXEC toolbelt_filesystem.USP_TranscodeTextFile @SourceRootAlias=N'ContosoOwn',@SourceRelativePath=N'text.txt',@SourceEncodingName=N'utf-8',@TargetRootAlias=N'ContosoOwn',@TargetRelativePath=N'converted.txt',@TargetEncodingName=N'utf-16',@WriteBom=1,@ExecutionIdentity='ServiceAccount';
EXEC toolbelt_filesystem.USP_CreateDirectory @RootAlias=N'ContosoOwn',@RelativePath=N'child',@ExecutionIdentity='ServiceAccount';
EXEC toolbelt_filesystem.USP_ListDirectory @RootAlias=N'ContosoOwn',@RelativePath=N'',@Recursive=1,@MaxDepth=1,@MaxEntries=8,@ExecutionIdentity='ServiceAccount';
EXEC toolbelt_filesystem.USP_RemoveFile @RootAlias=N'ContosoOwn',@RelativePath=N'binary.bin',@ExecutionIdentity='ServiceAccount';
EXEC toolbelt_filesystem.USP_RemoveDirectory @RootAlias=N'ContosoOwn',@RelativePath=N'child',@Recursive=0,@MaxDepth=0,@MaxEntries=1,@ExecutionIdentity='ServiceAccount';
REVERT;
END TRY BEGIN CATCH REVERT; THROW; END CATCH;
