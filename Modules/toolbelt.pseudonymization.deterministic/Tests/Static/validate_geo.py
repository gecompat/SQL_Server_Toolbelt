"""Geo-Scope-/Freezeprüfung; keine native Methoden-/Optimizer-Evidenz."""
from pathlib import Path
import re
import subprocess
from reference_geo import INPUTS, mapped, run

MODULE = Path(__file__).resolve().parents[2]
ROOT = MODULE.parents[1]
BASE = "76851e45f407089e062792c010176ae35a0ee77b"
OLD = ("TVF_DeterministicIntegerBytes.sql", "TVF_DeterministicRangeCore.sql",
       "TVF_DeterministicRange.sql", "TVF_DeterministicDateShift.sql",
       "USP_DeterministicLookupCore.sql", "USP_DeterministicLookup.sql", "DeterministicTranslate.sql")


def main():
    for name in OLD:
        file = MODULE / "Source" / name
        old = subprocess.check_output(["git", "show", f"{BASE}:{file.relative_to(ROOT).as_posix()}"], cwd=ROOT)
        # Git-Checkoutrepräsentation LF/CRLF ist ausdrücklich kein Source-Drift.
        assert file.read_bytes().replace(b"\r\n", b"\n") == old.replace(b"\r\n", b"\n"), name
    source = (MODULE / "Source/DeterministicGeoJitter.sql").read_text(encoding="utf-8")
    assert len(re.findall(r"CREATE\s+OR\s+ALTER\s+FUNCTION", source, re.I)) == 1
    assert re.search(r"RETURNS\s+TABLE\s+AS\s+RETURN\s*\(", source, re.I)
    assert len(re.findall(r"\bTVF_DeterministicRangeCore\]?\s*\(", source)) == 2
    assert "6416001" in source
    assert not re.search(r"\b(HASHBYTES|RAND|NEWID|CRYPT_GEN_RANDOM|MakeValid)\s*\(", source, re.I)
    for name in ("GeoJitter.Contract.sql", "GeoJitter.Safety.sql"):
        fixture = (MODULE / "Tests/Runtime" / name).read_text(encoding="utf-8")
        for batch in re.split(r"(?im)^\s*GO\s*$", fixture):
            assert len(re.findall(r"\bTVF_DeterministicGeoJitter\s*\(", batch)) <= 1, name
    fixture = (MODULE / "Tests/Runtime/GeoJitter.Contract.sql").read_text(encoding="utf-8")
    for args in INPUTS:
        lat, lon = mapped(*args)
        assert f"{lat:.15f}" in fixture and f"{lon:.15f}" in fixture
    print(f"PASS: Geo-Scope/7 historische Sources/Festvektoren; {run()} Referenzassertions; SQL not executed")


if __name__ == "__main__":
    main()
