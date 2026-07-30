SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52930, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52931, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_file.USP_LoadBinaryFile', N'P') IS NULL
    THROW 52932, N'USP_LoadBinaryFile fehlt oder besitzt den falschen Typ.', 1;
IF OBJECT_ID(N'toolbelt_file.USP_LoadTextFile', N'P') IS NULL
    THROW 52932, N'USP_LoadTextFile fehlt oder besitzt den falschen Typ.', 1;
IF OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U') IS NULL
    THROW 52932, N'FileContentRootAllowlist fehlt oder besitzt den falschen Typ.', 1;

PRINT N'File Content Lifecycle-Contract: erfolgreich';
