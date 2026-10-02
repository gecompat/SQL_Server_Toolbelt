SET NOCOUNT ON;

IF TRY_CONVERT(nvarchar(64), DATABASEPROPERTYEX(DB_NAME(), N'Updateability')) <> N'READ_WRITE'
    THROW 53120, N'Die Testdatenbank ist nicht schreibbar.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'2.0.0'
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

IF EXISTS
   (SELECT 1 FROM sys.objects AS o
    LEFT JOIN sys.extended_properties AS managed
      ON managed.class = 1 AND managed.major_id = o.object_id AND managed.minor_id = 0 AND managed.name = N'Toolbelt.Managed'
    LEFT JOIN sys.extended_properties AS moduleId
      ON moduleId.class = 1 AND moduleId.major_id = o.object_id AND moduleId.minor_id = 0 AND moduleId.name = N'Toolbelt.ModuleId'
    LEFT JOIN sys.extended_properties AS version
      ON version.class = 1 AND version.major_id = o.object_id AND version.minor_id = 0 AND version.name = N'Toolbelt.ModuleVersion'
    WHERE o.schema_id = SCHEMA_ID(N'toolbelt_tsql')
      AND o.name IN (N'TVF_ParseScriptNodes', N'TVF_ParseScriptNodeProperties', N'TVF_TokenizeScript', N'TVF_ParseScriptErrors')
      AND (TRY_CONVERT(int, managed.value) IS NULL OR TRY_CONVERT(int, managed.value) <> 1
           OR TRY_CONVERT(nvarchar(128), moduleId.value) IS NULL OR TRY_CONVERT(nvarchar(128), moduleId.value) <> N'toolbelt.tsql.script-parser'
           OR TRY_CONVERT(nvarchar(64), version.value) IS NULL OR TRY_CONVERT(nvarchar(64), version.value) <> N'2.0.0'))
    THROW 53123, N'Die Funktionsmarker sind nicht kohärent.', 2;

IF NOT EXISTS
   (SELECT 1 FROM sys.assemblies AS a
    INNER JOIN sys.extended_properties AS managed
      ON managed.class = 5 AND managed.major_id = a.assembly_id AND managed.minor_id = 0 AND managed.name = N'Toolbelt.Managed'
    INNER JOIN sys.extended_properties AS moduleId
      ON moduleId.class = 5 AND moduleId.major_id = a.assembly_id AND moduleId.minor_id = 0 AND moduleId.name = N'Toolbelt.ModuleId'
    WHERE a.name = N'Toolbelt_Tsql_ScriptParser'
      AND TRY_CONVERT(int, managed.value) = 1 AND TRY_CONVERT(nvarchar(128), moduleId.value) = N'toolbelt.tsql.script-parser')
    THROW 53123, N'Die Provider-Ownership ist nicht kohärent.', 3;

-- SQL-Defaults werden tatsächlich aufgerufen, nicht allein als Textmarker geprüft.
IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
 OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
 OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
 OR EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
    THROW 53123, N'Der SQL-Default-Aufruf verletzt den Vertrag.', 4;

PRINT N'ScriptParser-Lifecycle-Contract erfolgreich.';
