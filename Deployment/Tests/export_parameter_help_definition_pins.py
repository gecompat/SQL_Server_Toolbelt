"""Bind frozen export-fixture declarations through the exact Help-only delta.

Historical fixtures remain immutable. The current post-upgrade fixture replaces
only the eight definition expectations, after proving the exact Help-only delta.
"""
from pathlib import Path
import hashlib
import json
import re
import sys
import argparse

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import parameter_help_transition as transition


def fixture_text():
    return (ROOT / "Deployment/Tests/Runtime/ExportQueue11.Assert.sql").read_text(encoding="utf-8")


def definition_hash(data, name):
    text = transition.normalize(data)
    identifier = "[toolbelt_core].[" + name + "]"
    batches = [batch for batch in re.split(r"^\s*GO\s*$", text, flags=re.M|re.I)
               if re.search(r"CREATE OR ALTER (?:PROCEDURE|VIEW)\s+" + re.escape(identifier), batch, re.I)]
    if len(batches) != 1: raise ValueError("Definition batch differs")
    body = batches[0][batches[0].index(identifier):].strip(" \t\r\n")
    return hashlib.sha256(body.encode("utf-16-le")).hexdigest().upper()


def definition_pins():
    fixture = fixture_text()
    block = fixture.split("CREATE TABLE #ExpectedDefinitions", 1)[1].split("IF (SELECT COUNT(*) FROM #ExpectedDefinitions", 1)[0]
    declarations = re.findall(r"\(1,N'([^']+)',0x([A-F0-9]{64})\)", block)
    if len(declarations) != 8: raise ValueError("Historical definition set differs")
    result = {}
    for name, expected in declarations:
        if not re.fullmatch(r"(?:USP|VW)_\w+", name): raise ValueError("Unsafe historical object name")
        path = "Modules/toolbelt.core.work-queue/Source/" + name + ".sql"
        data = transition.predecessor_source(ROOT, path) if path in transition.PATHS else (ROOT / path).read_bytes()
        digest = definition_hash(data, name)
        if digest != expected: raise ValueError("Historical definition pin differs")
        result[name] = digest
    return result


def current_fixture():
    result=fixture_text()
    for name, old in definition_pins().items():
        current=definition_hash((ROOT/('Modules/toolbelt.core.work-queue/Source/'+name+'.sql')).read_bytes(),name)
        before=f"(1,N'{name}',0x{old})"
        if result.count(before)!=1: raise ValueError("Historical definition anchor differs")
        result=result.replace(before,f"(1,N'{name}',0x{current})",1)
    return result


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write',action='store_true')
    parser.add_argument('--check-current',action='store_true')
    args=parser.parse_args()
    target=ROOT/'Deployment/Tests/Runtime/ExportQueue11Help.Assert.sql'
    if args.write: target.write_text(current_fixture(),encoding='utf-8',newline='\n')
    if args.check_current and target.read_text(encoding='utf-8')!=current_fixture():
        raise ValueError('Current Help-aware export fixture is stale')
    print(json.dumps(definition_pins(),sort_keys=True))
