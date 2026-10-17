"""Bindet den SSIS-Build an ein tatsächliches, aktuelles Parser-2.0.1-Artefakt."""
from pathlib import Path
import hashlib
import json
import sys

root = Path(__file__).resolve().parents[1]
parser = root.parent / "toolbelt.tsql.script-parser"
release = Path(sys.argv[1])
manifest = json.loads((release / "Toolbelt.Tsql.ScriptParser.trust-manifest.json").read_text(encoding="utf-8-sig"))
sha = lambda path: hashlib.sha512(path.read_bytes()).hexdigest().upper()
sources = sorted(p for p in (parser / "Clr").rglob("*") if p.suffix in (".cs", ".csproj") and not {"bin", "obj"} & set(p.relative_to(parser / "Clr").parts))
fingerprint = hashlib.sha256("\n".join(p.relative_to(parser).as_posix() + ":" + hashlib.sha256(p.read_bytes()).hexdigest().upper() for p in sources).encode()).hexdigest().upper()
if manifest["moduleVersion"] != "2.0.1" or manifest["sourceFingerprintSha256"] != fingerprint or manifest["sha512"] != sha(release / "Toolbelt.Tsql.ScriptParser.dll"):
    raise SystemExit("PARSER_RELEASE_BINDING_MISMATCH")
dom = "459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7"
if manifest["scriptDomSha512"] != dom or sha(release / "Microsoft.SqlServer.TransactSql.ScriptDom.dll") != dom:
    raise SystemExit("SCRIPT_DOM_PIN_MISMATCH")
pins = {"schemaVersion": 1, "parserVersion": "2.0.1", "parserSha512": manifest["sha512"], "scriptDomSha512": dom}
(root / "Contracts/DependencyPins.json").write_text(json.dumps(pins, indent=2) + "\n", encoding="utf-8")
sql = """IF NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=0 AND ep.major_id=0 AND ep.minor_id=0 AND ep.name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version' AND SQL_VARIANT_PROPERTY(ep.value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'2.0.1'))
 OR NOT EXISTS(SELECT 1 FROM sys.assemblies AS a WITH (NOLOCK) JOIN sys.assembly_files AS f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 JOIN sys.extended_properties AS ep WITH (NOLOCK) ON ep.class=5 AND ep.major_id=a.assembly_id AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' WHERE a.name=N'Toolbelt_Tsql_ScriptParser' AND a.permission_set=3 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.tsql.script-parser') AND HASHBYTES('SHA2_512',f.content)=0xPARSER_HASH)
 OR NOT EXISTS(SELECT 1 FROM sys.assemblies AS a WITH (NOLOCK) JOIN sys.assembly_files AS f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 JOIN sys.extended_properties AS ep WITH (NOLOCK) ON ep.class=5 AND ep.major_id=a.assembly_id AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' WHERE a.name=N'Microsoft.SqlServer.TransactSql.ScriptDom' AND a.permission_set=3 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.tsql.script-parser') AND HASHBYTES('SHA2_512',f.content)=0xDOM_HASH)
 OR OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=0 AND ep.major_id=0 AND ep.minor_id=0 AND ep.name=N'Toolbelt.Module.toolbelt.core.result-table.Version' AND CONVERT(nvarchar(64),ep.value)=N'1.0.0')
 OR EXISTS(SELECT 1 FROM (VALUES(N'TVF_ParseScriptNodes'),(N'TVF_ParseScriptNodeProperties'),(N'TVF_TokenizeScript'),(N'TVF_ParseScriptErrors')) AS expected(name) WHERE NOT EXISTS(SELECT 1 FROM sys.assembly_modules AS m WITH (NOLOCK) JOIN sys.objects AS o WITH (NOLOCK) ON o.object_id=m.object_id JOIN sys.assemblies AS a WITH (NOLOCK) ON a.assembly_id=m.assembly_id WHERE o.schema_id=SCHEMA_ID(N'toolbelt_tsql') AND o.name=expected.name AND o.type=N'FT' AND a.name=N'Toolbelt_Tsql_ScriptParser'))
 THROW 50000,N'TBX_SSISDBG_unresolved_dependency: Exakte Parser-/ScriptDom-/ResultTable-Dependency fehlt oder ist abweichend.',1;""".replace("PARSER_HASH", pins["parserSha512"]).replace("DOM_HASH", dom)
(root / "Clr/DependencyPins.Generated.cs").write_text('// Generiert aus dem gebundenen Release; keine Runtimepfade.\nnamespace Toolbelt.Tsql.SsisDebug\n{\n    internal static class DependencyPins\n    {\n        internal const string Sql = @"' + sql.replace('"', '""') + '";\n    }\n}\n', encoding="utf-8")
(root / "Deployment").mkdir(exist_ok=True)
(root / "Deployment/DependencyPreflight.sql").write_text(sql + "\n", encoding="utf-8")
