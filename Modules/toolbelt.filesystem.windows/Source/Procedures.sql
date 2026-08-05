SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* Internal CLR entry points. The public T-SQL facade owns Help and ResultTable. */
CREATE PROCEDURE [toolbelt_filesystem].[CLR_ReadBinaryFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[ReadBinaryFileChunk];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_ReadTextFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @EncodingName nvarchar(128) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[ReadTextFileChunk];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_WriteBinaryFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content varbinary(max)
  , @Overwrite bit = 0
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[WriteBinaryFile];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_WriteTextFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content nvarchar(max)
  , @EncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[WriteTextFile];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_TranscodeTextFile]
(
    @SourceRootAlias sysname = NULL
  , @SourceRelativePath nvarchar(4000) = NULL
  , @SourceEncodingName nvarchar(128) = NULL
  , @TargetRootAlias sysname = NULL
  , @TargetRelativePath nvarchar(4000) = NULL
  , @TargetEncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[TranscodeTextFile];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_ListDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = N''
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[ListDirectory];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_CreateDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[CreateDirectory];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_RemoveFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[RemoveFile];
GO

CREATE PROCEDURE [toolbelt_filesystem].[CLR_RemoveDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[RemoveDirectory];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalEmitHelp]
      @ObjectName sysname
    , @Description nvarchar(max)
    , @ExampleSql nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion, CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName, @ObjectName AS ObjectName, CAST('DESCRIPTION' AS varchar(32)) AS Section, 1 AS Ordinal, CAST(NULL AS sysname) AS ItemName, CAST(NULL AS varchar(256)) AS SqlDataType, CAST(NULL AS bit) AS IsRequired, CAST(NULL AS bit) AS IsNullable, CAST(NULL AS nvarchar(4000)) AS DefaultValue, @Description AS Description, @ExampleSql AS ExampleSql
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 1, N'@ExecutionIdentity', 'varchar(16)', 0, 1, N'''Caller''', N'Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verwendet das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 2, N'@ResultTable', 'sysname', 0, 1, N'NULL', N'Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 3, N'@KeepData', 'bit', 0, 1, N'0', N'Gilt ausschließlich mit @ResultTable.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 4, N'@Debug', 'tinyint', 0, 1, N'0', N'Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 5, N'@Hilfe', 'bit', 0, 1, N'0', N'1 liefert ausschließlich dieses Help-Resultset.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, N'Windows-only; Linux ist nicht anwendbar. Absolute Pfade, UNC, Reparse Points und Root-Löschung sind gesperrt.', NULL;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalRouteResult]
      @ResultTable sysname = NULL
    , @KeepData bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF @ResultTable IS NULL
    BEGIN
        SELECT * FROM #tbx_fs_result;
        RETURN 0;
    END;
    SELECT TOP (0) * INTO #tbx_fs_shape FROM #tbx_fs_result;
    EXEC [toolbelt_core].[USP_PrepareResultTable]
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_fs_shape'
        , @KeepData = @KeepData;
    DECLARE @RouteSql nvarchar(max) = N'INSERT INTO ' + QUOTENAME(@ResultTable) + N' SELECT * FROM #tbx_fs_result;';
    EXEC sys.sp_executesql @RouteSql;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_ReadBinaryFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_ReadBinaryFileChunk'
            , @Description = N'Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([Content] varbinary(max) NULL, [BytesRead] int NOT NULL, [NextByteOffset] bigint NOT NULL, [EndOfFile] bit NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_ReadBinaryFileChunk]
              @RootAlias
          , @RelativePath
          , @ByteOffset
          , @MaxBytes
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_ReadTextFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @EncodingName nvarchar(128) = NULL
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_ReadTextFileChunk'
            , @Description = N'Liest einen begrenzten Text-Chunk mit expliziter Codepage und liefert die nächste Byte-Position.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_ReadTextFileChunk @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([Content] nvarchar(max) NULL, [BytesRead] int NOT NULL, [NextByteOffset] bigint NOT NULL, [EndOfFile] bit NOT NULL, [EncodingName] nvarchar(128) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_ReadTextFileChunk]
              @RootAlias
          , @RelativePath
          , @ByteOffset
          , @MaxBytes
          , @EncodingName
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_WriteBinaryFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content varbinary(max) = NULL
  , @Overwrite bit = 0
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_WriteBinaryFile'
            , @Description = N'Schreibt Binärdaten gestreamt in eine atomar veröffentlichte Zieldatei.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_WriteBinaryFile @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([BytesWritten] bigint NOT NULL, [RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_WriteBinaryFile]
              @RootAlias
          , @RelativePath
          , @Content
          , @Overwrite
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_WriteTextFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content nvarchar(max) = NULL
  , @EncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_WriteTextFile'
            , @Description = N'Schreibt Text gestreamt mit expliziter Codepage und optionalem BOM.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_WriteTextFile @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([BytesWritten] bigint NOT NULL, [RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_WriteTextFile]
              @RootAlias
          , @RelativePath
          , @Content
          , @EncodingName
          , @WriteBom
          , @Overwrite
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_TranscodeTextFile]
(
    @SourceRootAlias sysname = NULL
  , @SourceRelativePath nvarchar(4000) = NULL
  , @SourceEncodingName nvarchar(128) = NULL
  , @TargetRootAlias sysname = NULL
  , @TargetRelativePath nvarchar(4000) = NULL
  , @TargetEncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_TranscodeTextFile'
            , @Description = N'Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([BytesWritten] bigint NOT NULL, [RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_TranscodeTextFile]
              @SourceRootAlias
          , @SourceRelativePath
          , @SourceEncodingName
          , @TargetRootAlias
          , @TargetRelativePath
          , @TargetEncodingName
          , @WriteBom
          , @Overwrite
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_ListDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = N''
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_ListDirectory'
            , @Description = N'Listet Verzeichniseinträge unter einem freigegebenen Root mit harten Grenzen.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([EntryOrdinal] bigint NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [EntryType] varchar(16) NOT NULL, [SizeBytes] bigint NOT NULL, [LastWriteTimeUtc] datetime2 NOT NULL, [IsReparsePoint] bit NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_ListDirectory]
              @RootAlias
          , @RelativePath
          , @Recursive
          , @MaxDepth
          , @MaxEntries
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_CreateDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_CreateDirectory'
            , @Description = N'Erstellt ein Verzeichnis unter einem freigegebenen Root.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_CreateDirectory @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_CreateDirectory]
              @RootAlias
          , @RelativePath
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_RemoveFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_RemoveFile'
            , @Description = N'Entfernt eine Datei unter einem freigegebenen Root.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_RemoveFile @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_RemoveFile]
              @RootAlias
          , @RelativePath
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_RemoveDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        EXEC [toolbelt_filesystem].[USP_InternalEmitHelp]
              @ObjectName = N'USP_RemoveDirectory'
            , @Description = N'Entfernt ein Verzeichnis; rekursives Entfernen ist explizit und begrenzt.'
            , @ExampleSql = N'EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe = 1;';
        RETURN 0;
    END;
    CREATE TABLE #tbx_fs_result ([RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_RemoveDirectory]
              @RootAlias
          , @RelativePath
          , @Recursive
          , @MaxDepth
          , @MaxEntries
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
        DECLARE @ProviderError nvarchar(2048) = REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO
