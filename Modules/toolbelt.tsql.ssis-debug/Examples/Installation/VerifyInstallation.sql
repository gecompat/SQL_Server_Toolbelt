/*
Nach der lokalen Installation in SSMS ausführen; USE bei Bedarf anpassen.
Prüft Modulmarker und instanzweiten Trust, lädt den CLR-Parser tatsächlich
und zeigt die beiden Hilfen. Der spätere DTSX-Vorlagenaufruf im Walkthrough
prüft zusätzlich den tatsächlichen CLR-Einstieg des SSIS-Debug-Moduls.
*/
USE [ContosoSsisDebug];

IF (SELECT COUNT_BIG(*) FROM sys.extended_properties WITH (NOLOCK)
    WHERE class = 0 AND major_id = 0 AND minor_id = 0
      AND ((name = N'Toolbelt.Module.toolbelt.core.result-table.Version' AND CONVERT(nvarchar(64),value) = N'1.0.0')
        OR (name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version' AND CONVERT(nvarchar(64),value) = N'2.0.1')
        OR (name = N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version' AND CONVERT(nvarchar(64),value) = N'1.0.0'))) <> 3
    THROW 50000, N'Erwartete Modulmarker für ResultTable, Parser und SSIS-Debug fehlen.', 1;

IF (SELECT COUNT_BIG(*) FROM sys.assemblies AS a WITH (NOLOCK)
    JOIN sys.assembly_files AS f WITH (NOLOCK) ON f.assembly_id = a.assembly_id AND f.file_id = 1
    JOIN sys.trusted_assemblies AS t WITH (NOLOCK) ON t.hash = HASHBYTES('SHA2_512', f.content)
    WHERE a.permission_set = 3 AND a.name IN
      (N'Microsoft.SqlServer.TransactSql.ScriptDom',N'Toolbelt_Tsql_ScriptParser',N'Toolbelt_Tsql_SsisDebug')) <> 3
    THROW 50000, N'Drei UNSAFE-Assemblies mit exaktem Hash-Trust erforderlich.', 1;

SELECT name, CONVERT(nvarchar(64),value) AS ModuleVersion
FROM sys.extended_properties WITH (NOLOCK)
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name IN (N'Toolbelt.Module.toolbelt.core.result-table.Version',
               N'Toolbelt.Module.toolbelt.tsql.script-parser.Version',
               N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version');

SELECT a.name, a.permission_set_desc, CONVERT(bit,1) AS HashIsTrusted
FROM sys.assemblies AS a WITH (NOLOCK)
JOIN sys.assembly_files AS f WITH (NOLOCK) ON f.assembly_id = a.assembly_id AND f.file_id = 1
JOIN sys.trusted_assemblies AS t WITH (NOLOCK) ON t.hash = HASHBYTES('SHA2_512', f.content)
WHERE a.name IN (N'Microsoft.SqlServer.TransactSql.ScriptDom',N'Toolbelt_Tsql_ScriptParser',N'Toolbelt_Tsql_SsisDebug');

IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1;',150,1,DEFAULT,DEFAULT))
    THROW 50000, N'Der CLR-Parser lieferte unerwartete Syntaxfehler.', 1;
EXEC toolbelt_core.USP_PrepareResultTable @Hilfe = 1;
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe = 1;
