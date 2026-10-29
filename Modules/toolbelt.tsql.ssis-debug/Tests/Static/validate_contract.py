"""Quellkopplung des aktuellen SSIS-API-Vertrags; kein SQL-/Runtime-Nachweis."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
api = json.loads((ROOT / "Contracts/Api.json").read_text(encoding="utf-8-sig"))
public = (ROOT / "Source/USP_ExplainSsisDataFlow.sql").read_text(encoding="utf-8")
internal = (ROOT / "Source/USP_ExplainSsisDataFlowInternal.sql").read_text(encoding="utf-8")
assert re.findall(r"^\s*@(\w+)\s+", public.split("AS\nBEGIN", 1)[0], re.M) == [p["name"][1:] for p in api["parameters"]], "ordered public signature"
assert [p["name"] for p in api["parameters"]][-4:] == ["@ResultTable", "@KeepData", "@Debug", "@Hilfe"], "canonical common tail"
assert len([p for p in api["parameters"] if p["name"].startswith("@Max")]) == 24, "named resource parameters"
adapter = (ROOT / "Clr/SqlAdapter.cs").read_text(encoding="utf-8")
signature = re.search(r"public static void ExplainSsisDataFlow\((.*?)\)\s*\{", adapter, re.S)
assert signature, "CLR provider signature"
clr_names = re.findall(r"\bSql(?:Bytes|String|Int16|Int64|Boolean|Byte)\s+(\w+)\b", signature.group(1))
expected_clr_names = [p["name"][1:2].lower() + p["name"][2:] for p in api["parameters"]]
assert clr_names == expected_clr_names, "ordered CLR provider signature"
before = {p: p.read_bytes() for p in [ROOT / "Source/USP_ExplainSsisDataFlow.sql", ROOT / "Source/USP_ExplainSsisDataFlowInternal.sql", ROOT / "Clr/HelpContract.Generated.cs"]}
subprocess.run([sys.executable, str(ROOT / "Scripts/New-ContractSources.py")], check=True)
assert all(p.read_bytes() == content for p, content in before.items()), "generated contract drift"
assert public.index("IF @Hilfe=1") < public.index("SET XACT_ABORT OFF") < public.index("EXEC toolbelt_tsql.USP_ExplainSsisDataFlowInternal")
assert "AS EXTERNAL NAME" in internal and "@Hilfe" in internal
assert re.search(r"@Operation\s+nvarchar\(32\)", internal)
assert re.search(r"@TargetFlow\s+nvarchar\(64\)", internal)
assert re.search(r"@InspectStage\s+nvarchar\(64\)", internal)
pins = json.loads((ROOT / "Contracts/DependencyPins.json").read_text())
assert pins["parserVersion"] == "2.0.1" and len(pins["parserSha512"]) == 128
for token in [pins["parserSha512"], pins["scriptDomSha512"], "WITH (NOLOCK)", "USP_PrepareResultTable"]:
    assert token in (ROOT / "Deployment/DependencyPreflight.sql").read_text()
code = "\n".join(p.read_text(encoding="utf-8") for folder in ("Clr", "Exchange/Core") for p in (ROOT / folder).glob("*.cs"))
for forbidden in ["File.ReadAll", "WebClient", "HttpClient", "Process.Start", "new Thread", "Assembly.Load", "Package.Execute", "Microsoft.SqlServer.Dts.Runtime"]:
    assert forbidden not in code, forbidden
assert 'new GuardProfile(4096, 65536, 32, 16, 256, 64)' in code
assert 'new SqlConnection("context connection=true")' in code
assert "SqlParameters.Mappings" in code and "ROW_NUMBER() OVER (PARTITION BY" in code
assert "TBX_SSISDBG_cache_ownership" in code and "TBX_SSISDBG_cache_context_changed" in code
for name in ["Deploy.sql", "Uninstall.sql"]:
    ddl = (ROOT / "Deployment" / name).read_text()
    assert ddl.index("IF @@TRANCOUNT<>") < ddl.index("SET XACT_ABORT ON")
    assert ddl.count("sp_getapplock") == 2
    assert "sp_add_trusted_assembly" not in ddl and "TRUSTWORTHY ON" not in ddl
    assert "ASSEMBLY_ID(" not in ddl
assert "ASSEMBLY_ID(" not in code
projection = (ROOT / "Clr/PackageModel.cs").read_text(encoding="utf-8")
assert not any(token in projection for token in ("System.Xml", "XElement", "XDocument", ".Descendants(", ".Elements(")), "generator must project the shared typed model"
assert 'Exchange\\Core\\*.cs' in (ROOT / "Clr/Toolbelt.Tsql.SsisDebug.csproj").read_text(), "CLR must compile the canonical core"
objects = json.loads((ROOT / "Contracts/ReleaseObjects.1.0.0.json").read_text())
assert "USP_ExplainSsisDataFlowInternal" in json.dumps(objects)
print("SSIS_STATIC_PASS signature/generation/dependencies/lifecycle; no SQL executed")
