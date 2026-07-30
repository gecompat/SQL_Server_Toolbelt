SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_file.USP_LoadBinaryFile', N'P') IS NULL
    THROW 52932, N'USP_LoadBinaryFile fehlt oder besitzt den falschen Typ.', 1;
IF OBJECT_ID(N'toolbelt_file.USP_LoadTextFile', N'P') IS NULL
    THROW 52932, N'USP_LoadTextFile fehlt oder besitzt den falschen Typ.', 1;
IF OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U') IS NULL
    THROW 52932, N'FileContentRootAllowlist fehlt oder besitzt den falschen Typ.', 1;

PRINT N'File Content Lifecycle-Contract: erfolgreich';
