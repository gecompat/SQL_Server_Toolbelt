SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* Internal CLR entry points. The public T-SQL facade owns Help and ResultTable. */
CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_ReadBinaryFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[ReadBinaryFileChunk];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_ReadTextFileChunk]
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

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_WriteBinaryFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content varbinary(max)
  , @Overwrite bit = 0
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[WriteBinaryFile];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_WriteTextFile]
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

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_TranscodeTextFile]
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

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_ListDirectory]
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

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_CreateDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[CreateDirectory];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_RemoveFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
AS EXTERNAL NAME [Toolbelt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[RemoveFile];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_RemoveDirectory]
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
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 1, N'@ExecutionIdentity', 'varchar(16)', CAST(0 AS bit), CAST(1 AS bit), N'''Caller''', N'Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verlangt die dbo-eigene Rolle toolbelt_filesystem_service_account und AllowServiceAccount=1 am Root, dann verwendet es das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 2, N'@ResultTable', 'sysname', CAST(0 AS bit), CAST(1 AS bit), N'NULL', N'Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 3, N'@KeepData', 'bit', CAST(0 AS bit), CAST(1 AS bit), N'0', N'Gilt ausschließlich mit @ResultTable.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 4, N'@Debug', 'tinyint', CAST(0 AS bit), CAST(1 AS bit), N'0', N'Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 5, N'@Hilfe', 'bit', CAST(0 AS bit), CAST(1 AS bit), N'0', N'1 liefert ausschließlich dieses Help-Resultset.', NULL
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_ReadBinaryFileChunk' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.bin'', @ByteOffset=0, @MaxBytes=1024, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'Content', N'varbinary(max)', NULL, 1, NULL, CAST(N'Content.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'BytesRead', N'int', NULL, 0, NULL, CAST(N'BytesRead.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'NextByteOffset', N'bigint', NULL, 0, NULL, CAST(N'NextByteOffset.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EndOfFile', N'bit', NULL, 0, NULL, CAST(N'EndOfFile.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ByteOffset', N'bigint', 0, 0, N'0', CAST(N'Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxBytes', N'int', 0, 0, N'1048576', CAST(N'Ganzzahl 1..16777216 Rohbytes pro Chunk, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF kürzer sein; kein Gesamtdateilimit.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte den Binaer-Chunk nicht lesen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_ReadTextFileChunk' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest einen begrenzten Text-Chunk mit expliziter Codepage und liefert die nächste Byte-Position.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadTextFileChunk
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.txt'', @ByteOffset=0, @MaxBytes=1024, @EncodingName=N''utf-8'', @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'Content', N'nvarchar(max)', NULL, 1, NULL, CAST(N'Content.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'BytesRead', N'int', NULL, 0, NULL, CAST(N'BytesRead.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'NextByteOffset', N'bigint', NULL, 0, NULL, CAST(N'NextByteOffset.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EndOfFile', N'bit', NULL, 0, NULL, CAST(N'EndOfFile.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'EncodingName', N'nvarchar(128)', NULL, 0, NULL, CAST(N'EncodingName.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ByteOffset', N'bigint', 0, 0, N'0', CAST(N'Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxBytes', N'int', 0, 0, N'1048576', CAST(N'Ganzzahl 4..16777216 Rohbytes pro Leseversuch, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF oder zum Erhalt einer vollständigen Decodergrenze kürzer sein; kein Gesamtdateilimit.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@EncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. BOM wird als Datenzeichen behandelt; Offset/NextByteOffset zählen weiterhin Bytes.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte den Text-Chunk nicht lesen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_WriteBinaryFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schreibt Binärdaten gestreamt in eine atomar veröffentlichte Zieldatei.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteBinaryFile
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.bin'', @Content=0x4869, @Overwrite=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'BytesWritten', N'bigint', NULL, 0, NULL, CAST(N'BytesWritten.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Content', N'varbinary(max)', 1, 0, N'NULL', CAST(N'Binärer Bytepuffer varbinary(max), etwa 0x0102; keine Text-/Base64-Dekodierung. Leer 0x schreibt eine leere Datei. NULL (technischer Help-Default) ungültig. SQL-LOB wird in begrenzten Blöcken gelesen, kein zusätzliches öffentliches Gesamtbytebudget.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Overwrite', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Binaerdatei nicht schreiben. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_WriteTextFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schreibt Text gestreamt mit expliziter Codepage und optionalem BOM.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteTextFile
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.txt'', @Content=N''Contoso'', @EncodingName=N''utf-8'', @WriteBom=0, @Overwrite=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'BytesWritten', N'bigint', NULL, 0, NULL, CAST(N'BytesWritten.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Content', N'nvarchar(max)', 1, 0, N'NULL', CAST(N'Unicode-Text nvarchar(max), leer schreibt nur eine gegebenenfalls gewählte BOM. NULL (technischer Help-Default) ungültig. Zeichen werden mit explizitem Encoding strikt kodiert; unvertretbare Zeichen/ungültige Surrogate sind Fehler, kein stiller Ersatz. Kein Append oder zusätzliches Gesamttextbudget.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@EncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@WriteBom', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Overwrite', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Textdatei nicht schreiben. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_TranscodeTextFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_TranscodeTextFile
 @SourceRootAlias=N''ExampleRoot'', @SourceRelativePath=N''input.txt'', @SourceEncodingName=N''utf-8'', @TargetRootAlias=N''ExampleRoot'', @TargetRelativePath=N''output.txt'', @TargetEncodingName=N''utf-16'', @Overwrite=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'BytesWritten', N'bigint', NULL, 0, NULL, CAST(N'BytesWritten.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@SourceRootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Quelle benötigt AllowRead.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@SourceRelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; vorhandene Quelldatei.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@SourceEncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Explizites Sourceencoding; keine BOM-Autoerkennung. StreamReader entfernt gegebenenfalls eine zu diesem Encoding passende Präambel.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@TargetRootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@TargetRelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Ausgabe erfolgt über Staging/Publish.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@TargetEncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Bestimmt ausschließlich die Ausgabeencoding.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@WriteBom', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Overwrite', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Textdatei nicht transkodieren. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_ListDirectory' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Listet Verzeichniseinträge unter einem freigegebenen Root mit harten Grenzen.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ListDirectory
 @RootAlias=N''ExampleRoot'', @RelativePath=N'''', @Recursive=0, @MaxEntries=100, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'EntryOrdinal', N'bigint', NULL, 0, NULL, CAST(N'EntryOrdinal.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'EntryType', N'varchar(16)', NULL, 0, NULL, CAST(N'EntryType.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'SizeBytes', N'bigint', NULL, 0, NULL, CAST(N'SizeBytes.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'LastWriteTimeUtc', N'datetime2', NULL, 0, NULL, CAST(N'LastWriteTimeUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'IsReparsePoint', N'bit', NULL, 0, NULL, CAST(N'IsReparsePoint.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'N''''', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer (Default) wählt den Root selbst; NULL bleibt ungültig. Kein Suchmuster.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Recursive', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxDepth', N'int', 0, 0, N'32', CAST(N'Ganzzahl 0..64, Default 32; Startdirectory hat Tiefe 0. Bei Recursive=1 führt ein nötiger Abstieg über die Grenze zum Fehler, nicht zu einer still gekürzten Ausgabe; bei 0 ist bereits Abstieg in ein Unterverzeichnis verboten. Auch ohne Rekursion muss das Budget gültig sein. NULL/negativ/>64 ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxEntries', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..10000 Verzeichniseinträge (Dateien und Unterverzeichnisse), Default 10000. NULL/außerhalb ungültig; Überschreitung verwirft die vollständig gepufferte Ausgabe, kein TOP-Teilresultat. Zusätzlich gilt ein internes Pfadbytebudget.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) =
        CASE
          WHEN ERROR_MESSAGE() LIKE N'%TBXFS:EntryLimitExceeded%'
            THEN N'Die Verzeichnisausgabe ueberschreitet @MaxEntries = '
               + CONVERT(nvarchar(12), @MaxEntries)
              + N'. Erhoehen Sie @MaxEntries oder grenzen Sie @RelativePath weiter ein.'
          ELSE REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%')
        END;
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_CreateDirectory' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erstellt ein Verzeichnis unter einem freigegebenen Root.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_CreateDirectory
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example-dir'', @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer ist erlaubt und bezeichnet den Root; normale fehlende Unterverzeichnisse werden innerhalb der freigegebenen Rootkette angelegt. NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte das Verzeichnis nicht erstellen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_RemoveFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Entfernt eine Datei unter einem freigegebenen Root.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveFile
 @RootAlias=N''ExampleRoot'', @RelativePath=N''own-example.bin'', @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer, muss eine vorhandene reguläre Datei adressieren, keine Verzeichnisse/Mehrfachauswahl. Löscht genau die handlegebundene Datei; kein Recycle-Bin-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Datei nicht entfernen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_RemoveDirectory' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Entfernt ein Verzeichnis; rekursives Entfernen ist explizit und begrenzt.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveDirectory
 @RootAlias=N''ExampleRoot'', @RelativePath=N''own-example-dir'', @Recursive=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer kann syntaktisch aufgelöst werden, aber der Root selbst darf niemals gelöscht werden. Muss ein vorhandenes Verzeichnis sein; keine Wildcard-/Mehrfachauswahl.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Recursive', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default. Bei 0 muss das Verzeichnis leer sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxDepth', N'int', 0, 0, N'32', CAST(N'Ganzzahl 0..2147483647, Default 32; der Remove-Pfad besitzt anders als List keine zusätzliche 64er-Obergrenze. Startdirectory hat Tiefe 0. Bei Recursive=1 wird jeder nötige Abstieg über das Budget vor der ersten Löschmutation abgewiesen. NULL/negativ ungültig; nicht still trunciert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxEntries', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..2147483647, Default 10000; der Remove-Pfad besitzt anders als List keine zusätzliche 10000er-Obergrenze. Zählt sämtliche Kinder im vollständigen Vorab-Löschplan, ohne das Startdirectory selbst. NULL/0/negativ ungültig; Überschreitung vor erster Mutation. Keine automatische unbegrenzte Löschung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte das Verzeichnis nicht entfernen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO
