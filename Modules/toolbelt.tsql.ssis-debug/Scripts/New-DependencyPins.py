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
dom = "634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813"
if manifest["scriptDomSha512"] != dom or sha(release / "tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll") != dom:
    raise SystemExit("SCRIPT_DOM_PIN_MISMATCH")
pins = {"schemaVersion": 1, "parserVersion": "2.0.1", "parserSha512": manifest["sha512"], "scriptDomSha512": dom}
(root / "Contracts/DependencyPins.json").write_text(json.dumps(pins, indent=2) + "\n", encoding="utf-8")
from DependencyContract import dependency_sql
sql = dependency_sql()
(root / "Clr/DependencyPins.Generated.cs").write_text('// Generiert aus dem gebundenen Release; keine Runtimepfade.\nnamespace Toolbelt.Tsql.SsisDebug\n{\n    internal static class DependencyPins\n    {\n        internal const string Sql = @"' + sql.replace('"', '""') + '";\n    }\n}\n', encoding="utf-8")
(root / "Deployment").mkdir(exist_ok=True)
(root / "Deployment/DependencyPreflight.sql").write_text(sql + "\n", encoding="utf-8")
