SET NOCOUNT ON;

IF TRY_CONVERT(nvarchar(64), DATABASEPROPERTYEX(DB_NAME(), N'Updateability')) <> N'READ_WRITE'
    THROW 52082, N'Die Testdatenbank ist nicht schreibbar.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.string.regex.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
    THROW 52083, N'Der Modulversionsmarker fehlt.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.assemblies
       WHERE name = N'Toolbelt_String_Regex'
         AND permission_set_desc = N'SAFE_ACCESS'
   )
    THROW 52084, N'Die SAFE-Regex-Assembly fehlt.', 1;

IF (SELECT COUNT(*) FROM sys.objects
    WHERE schema_id = SCHEMA_ID(N'toolbelt_string')
      AND name IN (N'SVF_RegexIsMatch', N'SVF_RegexInstr', N'SVF_RegexCount')
      AND type = N'FS') <> 3
    THROW 52085, N'Das öffentliche Funktionsinventar ist unvollständig.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.objects AS o
       WHERE o.schema_id = SCHEMA_ID(N'toolbelt_string')
         AND o.name IN (N'SVF_RegexIsMatch', N'SVF_RegexInstr', N'SVF_RegexCount')
         AND NOT EXISTS
             (
                 SELECT 1 FROM sys.extended_properties AS ep
                 WHERE ep.class = 1 AND ep.major_id = o.object_id
                   AND ep.name = N'Toolbelt.ModuleVersion'
                   AND TRY_CONVERT(nvarchar(64), ep.value) = N'1.0.0'
             )
   )
    THROW 52086, N'Das versionierte Objektmanifest ist unvollständig.', 1;

PRINT N'Regex-Lifecycle-Contract erfolgreich.';
