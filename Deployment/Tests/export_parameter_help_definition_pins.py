"""Bind frozen export-fixture declarations through the exact Help-only delta.

This does not qualify current populated upgrades: their historical fixture and
driver bytes remain immutable. Current executable exports/Help have own tests.
"""
from pathlib import Path
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import parameter_help_transition as transition


def definition_pins():
    fixture = (ROOT / "Deployment/Tests/Runtime/ExportQueue11.Assert.sql").read_text(encoding="utf-8")
    block = fixture.split("CREATE TABLE #ExpectedDefinitions", 1)[1].split("IF (SELECT COUNT(*) FROM #ExpectedDefinitions", 1)[0]
    declarations = re.findall(r"\(1,N'([^']+)',0x([A-F0-9]{64})\)", block)
    if len(declarations) != 8: raise ValueError("Historical definition set differs")
    result = {}
    for name, expected in declarations:
        if not re.fullmatch(r"(?:USP|VW)_\w+", name): raise ValueError("Unsafe historical object name")
        path = "Modules/toolbelt.core.work-queue/Source/" + name + ".sql"
        data = transition.predecessor_source(ROOT, path) if path in transition.PATHS else (ROOT / path).read_bytes()
        text = transition.normalize(data)
        identifier = "[toolbelt_core].[" + name + "]"
        batches = [batch for batch in re.split(r"^\s*GO\s*$", text, flags=re.M|re.I)
                   if re.search(r"CREATE OR ALTER (?:PROCEDURE|VIEW)\s+" + re.escape(identifier), batch, re.I)]
        if len(batches) != 1: raise ValueError("Historical definition batch differs")
        body = batches[0][batches[0].index(identifier):].strip(" \t\r\n")
        digest = hashlib.sha256(body.encode("utf-16-le")).hexdigest().upper()
        if digest != expected: raise ValueError("Historical definition pin differs")
        result[name] = digest
    return result


if __name__ == "__main__": print(json.dumps(definition_pins(), sort_keys=True))
