"""Derive the current Schema upgrade oracle without changing frozen witnesses."""
from pathlib import Path
import argparse
import hashlib
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import parameter_help_transition as transition

SOURCE = "Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql"
ORIGINAL = "Modules/toolbelt.json.schema/Tests/Runtime/UpgradeVerify.sql"
ORIGINAL_SHA256 = "2e1a0452d29f0fbb665847666c1aedd990aebc81b203352df96a4debadf40706"
TARGET = "Modules/toolbelt.json.schema/Tests/Runtime/UpgradeHelpVerify.sql"
ANCHOR = " AND s.PublicDefinition=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@PublicId)))"


def current_definition_hash(root=ROOT):
    # This assertion rejects changes outside the canonical Help branch before
    # deriving an expectation. Historical evidence is never repinned.
    transition.predecessor_source(root, SOURCE)
    text = transition.normalize((Path(root) / SOURCE).read_bytes())
    declaration = "CREATE OR ALTER PROCEDURE toolbelt_json.USP_ValidateJsonSchema"
    if text.count(declaration) != 1:
        raise ValueError("Schema declaration differs")
    batch = re.split(r"^\s*GO\s*$", text[text.index(declaration):], flags=re.M | re.I)
    if len(batch) != 2 or batch[1].strip():
        raise ValueError("Schema definition batch differs")
    body = batch[0][len("CREATE OR ALTER PROCEDURE "):].strip(" \t\r\n")
    return hashlib.sha256(body.encode("utf-16-le")).hexdigest().upper()


def current_fixture(root=ROOT):
    data = (Path(root) / ORIGINAL).read_bytes()
    if hashlib.sha256(data).hexdigest() != ORIGINAL_SHA256:
        raise ValueError("Schema frozen upgrade oracle differs")
    original = data.decode("utf-8")
    if original.count(ANCHOR) != 1:
        raise ValueError("Schema historical definition oracle differs")
    digest = current_definition_hash(root)
    replacement = """ AND ((@ExpectedVersion=N'1.0.0'
  AND s.PublicDefinition=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@PublicId))))
  OR (@ExpectedVersion=N'1.0.1'
  AND CHARINDEX(N'PROCEDURE toolbelt_json.USP_ValidateJsonSchema',OBJECT_DEFINITION(@PublicId) COLLATE Latin1_General_100_BIN2)>0
  AND HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),
   TRIM(NCHAR(9)+NCHAR(10)+N' ' FROM REPLACE(SUBSTRING(OBJECT_DEFINITION(@PublicId),
    CHARINDEX(N'PROCEDURE toolbelt_json.USP_ValidateJsonSchema',OBJECT_DEFINITION(@PublicId) COLLATE Latin1_General_100_BIN2)+10,
    2147483647),NCHAR(13)+NCHAR(10),NCHAR(10)))))=0x""" + digest + "))"
    return original.replace(ANCHOR, replacement)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    expected = current_fixture()
    if args.write:
        (ROOT / TARGET).write_text(expected, encoding="utf-8", newline="\n")
    elif (ROOT / TARGET).read_text(encoding="utf-8") != expected:
        raise ValueError("Schema current Help-aware upgrade fixture is stale")
    print("PASS SCHEMA_HELP_UPGRADE_FIXTURE")
