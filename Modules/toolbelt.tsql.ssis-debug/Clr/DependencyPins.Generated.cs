// Generiert aus dem gebundenen Release; keine Runtimepfade.
namespace Toolbelt.Tsql.SsisDebug
{
    internal static class DependencyPins
    {
        internal const string Sql = @"IF NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=0 AND ep.major_id=0 AND ep.minor_id=0 AND ep.name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version' AND SQL_VARIANT_PROPERTY(ep.value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'2.0.1'))
 OR NOT EXISTS(SELECT 1 FROM sys.assemblies AS a WITH (NOLOCK) JOIN sys.assembly_files AS f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 JOIN sys.extended_properties AS ep WITH (NOLOCK) ON ep.class=5 AND ep.major_id=a.assembly_id AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' WHERE a.name=N'Toolbelt_Tsql_ScriptParser' AND a.permission_set=3 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.tsql.script-parser') AND HASHBYTES('SHA2_512',f.content)=0x7F34D0472DBE5913C8D019A72B2684D89CB4CA79590B599DD5B06154D6A40C5494334D8F46218E10E9D1BC5DB983A8750BA77A685D68865D9BCDF30C3D853506)
 OR NOT EXISTS(SELECT 1 FROM sys.assemblies AS a WITH (NOLOCK) JOIN sys.assembly_files AS f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 JOIN sys.extended_properties AS ep WITH (NOLOCK) ON ep.class=5 AND ep.major_id=a.assembly_id AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' WHERE a.name=N'Microsoft.SqlServer.TransactSql.ScriptDom' AND a.permission_set=3 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.tsql.script-parser') AND HASHBYTES('SHA2_512',f.content)=0x459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7)
 OR OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=0 AND ep.major_id=0 AND ep.minor_id=0 AND ep.name=N'Toolbelt.Module.toolbelt.core.result-table.Version' AND CONVERT(nvarchar(64),ep.value)=N'1.0.0')
 OR EXISTS(SELECT 1 FROM (VALUES(N'TVF_ParseScriptNodes'),(N'TVF_ParseScriptNodeProperties'),(N'TVF_TokenizeScript'),(N'TVF_ParseScriptErrors')) AS expected(name) WHERE NOT EXISTS(SELECT 1 FROM sys.assembly_modules AS m WITH (NOLOCK) JOIN sys.objects AS o WITH (NOLOCK) ON o.object_id=m.object_id JOIN sys.assemblies AS a WITH (NOLOCK) ON a.assembly_id=m.assembly_id WHERE o.schema_id=SCHEMA_ID(N'toolbelt_tsql') AND o.name=expected.name AND o.type=N'FT' AND a.name=N'Toolbelt_Tsql_ScriptParser'))
 THROW 50000,N'TBX_SSISDBG_unresolved_dependency: Exakte Parser-/ScriptDom-/ResultTable-Dependency fehlt oder ist abweichend.',1;";
    }
}
