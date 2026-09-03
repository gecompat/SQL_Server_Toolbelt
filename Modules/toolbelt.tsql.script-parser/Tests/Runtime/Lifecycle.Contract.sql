SET NOCOUNT ON;

IF TRY_CONVERT(nvarchar(64), DATABASEPROPERTYEX(DB_NAME(), N'Updateability')) <> N'READ_WRITE'
    THROW 53120, N'Die Testdatenbank ist nicht schreibbar.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
    THROW 53121, N'Der Modulversionsmarker fehlt.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.assemblies
       WHERE name = N'Toolbelt_Tsql_ScriptParser'
         AND permission_set_desc = N'UNSAFE_ACCESS'
   )
    THROW 53122, N'Die ScriptParser-Assembly fehlt oder besitzt nicht UNSAFE_ACCESS.', 1;

IF (SELECT COUNT(*) FROM sys.objects
    WHERE schema_id = SCHEMA_ID(N'toolbelt_tsql')
      AND name IN (
            N'TVF_ParseScriptNodes',
            N'TVF_ParseScriptNodeProperties',
            N'TVF_TokenizeScript',
            N'TVF_ParseScriptErrors'
      )
      AND type = N'FT') <> 4
    THROW 53123, N'Das öffentliche Funktionsinventar ist unvollständig.', 1;

PRINT N'ScriptParser-Lifecycle-Contract erfolgreich.';
