"""Geo-Scope-/Freezeprüfung; keine native Methoden-/Optimizer-Evidenz."""
from pathlib import Path
import re
import math
import subprocess
from reference_geo import INPUTS, mapped, run

MODULE = Path(__file__).resolve().parents[2]
ROOT = MODULE.parents[1]
BASE = "76851e45f407089e062792c010176ae35a0ee77b"
OLD = ("TVF_DeterministicIntegerBytes.sql", "TVF_DeterministicRangeCore.sql",
       "TVF_DeterministicRange.sql", "TVF_DeterministicDateShift.sql",
       "USP_DeterministicLookupCore.sql", "USP_DeterministicLookup.sql", "DeterministicTranslate.sql")


COORDINATE_TOLERANCE = 1e-9
NUMBER = r"-?\d+(?:\.\d+)?"
KEY = r"(?:0x[0-9a-fA-F]+|CONVERT\(varbinary\(max\),REPLICATE\(CONVERT\(varchar\(max\),'x'\),8000\)\))"
VECTOR = re.compile(
    rf"\((\d+),({NUMBER}),({NUMBER}),(\d+),({KEY}),(\d+),"
    rf"CONVERT\(bigint,'(-?\d+)'\),({NUMBER}),({NUMBER})\)"
)


def validate_golden_vectors(fixture):
    # Nur das eingefrorene VALUES-Feld lesen, nicht beliebige Koordinaten im Text.
    declaration = "DECLARE @Vectors TABLE(Id int,Lat float,Lon float,Radius int,[Key] varbinary(max),Version int,Seed bigint,ExpectedLat float,ExpectedLon float);"
    assert fixture.count(declaration) == 1
    block = fixture.split(declaration, 1)[1].split("DECLARE @Actual TABLE", 1)[0]
    assert block.lstrip().startswith("INSERT @Vectors VALUES")
    rows = VECTOR.findall(block)
    assert len(rows) == len(INPUTS) == 10
    remainder = VECTOR.sub("", block.removeprefix("\n").strip().removeprefix("INSERT @Vectors VALUES"))
    assert re.fullmatch(r"[\s,]*;", remainder), "Unbekannte Vektorstruktur"
    for ordinal, (row, args) in enumerate(zip(rows, INPUTS), 1):
        identity, lat, lon, radius, key, version, seed, expected_lat, expected_lon = row
        actual_key = bytes.fromhex(key[2:]) if key.startswith("0x") else b"x" * 8000
        assert int(identity) == ordinal
        assert (float(lat), float(lon), int(radius), actual_key, int(version), int(seed)) == args
        reference_lat, reference_lon = mapped(*args)
        golden_lat, golden_lon = float(expected_lat), float(expected_lon)
        assert math.isfinite(golden_lat) and math.isfinite(golden_lon)
        assert -90 <= golden_lat <= 90 and -180 <= golden_lon < 180
        assert abs(golden_lat - reference_lat) <= COORDINATE_TOLERANCE
        difference = golden_lon - reference_lon
        assert abs(difference - 360 * math.floor((difference + 180) / 360)) <= COORDINATE_TOLERANCE


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
    validate_golden_vectors(fixture)
    print(f"PASS: Geo-Scope/7 historische Sources/Festvektoren; {run()} Referenzassertions; SQL not executed")


if __name__ == "__main__":
    main()
