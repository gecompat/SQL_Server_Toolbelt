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

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.assemblies AS a
       INNER JOIN sys.assembly_files AS af ON af.assembly_id = a.assembly_id AND af.file_id = 1
       WHERE a.name = N'Toolbelt_Tsql_ScriptParser'
         AND HASHBYTES(N'SHA2_512', af.content) =
             0xE03C6099E2E919F3F930E2CCB5A753C47F16DABFC18B608F8BC33DEA5E93ED10D9A937CF599427FADED4EBBB11653E80D2C8BA23C49E5AAEEB0A80C60D51EDBF
   )
 OR NOT EXISTS
   (
       SELECT 1
       FROM sys.assemblies AS a
       INNER JOIN sys.assembly_files AS af ON af.assembly_id = a.assembly_id AND af.file_id = 1
       WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom'
         AND HASHBYTES(N'SHA2_512', af.content) =
             0x459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7
   )
    THROW 53123, N'Die installierten Parser-Binaries stimmen nicht mit dem qualifizierten Pin überein.', 5;

-- SQL-Defaults werden tatsächlich aufgerufen, nicht allein als Textmarker geprüft.
IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
 OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
 OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
 OR EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1;', DEFAULT, DEFAULT, DEFAULT, DEFAULT))
    THROW 53123, N'Der SQL-Default-Aufruf verletzt den Vertrag.', 4;

PRINT N'ScriptParser-Lifecycle-Contract erfolgreich.';
