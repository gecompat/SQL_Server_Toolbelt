"""Leitet die atomaren CREATE-Payloads ausschließlich aus kanonischen Source-Dateien ab."""
from pathlib import Path
import argparse
import hashlib
import re

MODULE = Path(__file__).resolve().parents[1]
NAMES = ("TVF_TryCastBigInt", "TVF_TryCastDecimal", "TVF_TryCastDate",
         "TVF_TryCastDateTime2", "TVF_TryCastBit", "TVF_TryCastUniqueIdentifier")


def render():
    expected = {name + ".sql" for name in NAMES}
    if {p.name for p in (MODULE / "Source").glob("*.sql")} != expected:
        raise ValueError("SAFE_CAST_CANONICAL_SIX_SOURCE_FILES_REQUIRED")
    chunks = ["-- Generiert mit Scripts/generate-deployment.py --write; niemals Fachlogik hier editieren.\n"
              "-- Source-Hashes sind rein diagnostisch, kein installierter Lifecycle-Gate.\n"
              "SET ANSI_NULLS ON;\nSET QUOTED_IDENTIFIER ON;\n"]
    for name in NAMES:
        text = (MODULE / "Source" / (name + ".sql")).read_text(encoding="utf-8-sig")
        create = re.search(r"(?im)^\s*CREATE\s+(?:OR\s+ALTER\s+)?FUNCTION\s+", text)
        if create is None:
            raise ValueError("SAFE_CAST_SOURCE_CREATE_REQUIRED")
        prefix = re.sub(r"/\*.*?\*/|--[^\n]*", "", text[:create.start()], flags=re.S)
        prefix = re.sub(r"(?im)^\s*(?:SET\s+(?:ANSI_NULLS|QUOTED_IDENTIFIER)\s+ON\s*;?|GO)\s*$", "", prefix)
        if prefix.strip():
            raise ValueError("SAFE_CAST_SOURCE_PREAMBLE_UNSUPPORTED")
        text = text[create.start():]
        # GO ist nur als abschließender Batchtrenner zulässig; CREATE bleibt ein eigener dynamischer Batch.
        text = re.sub(r"(?im)^\s*GO\s*(?:--[^\n]*)?\s*\Z", "", text).strip() + "\n"
        if re.search(r"(?im)^\s*(GO\b|:)", text):
            raise ValueError("SAFE_CAST_SOURCE_SINGLE_BATCH_REQUIRED")
        if len(re.findall(r"(?im)^\s*CREATE\s+(?:OR\s+ALTER\s+)?FUNCTION\s+", text)) != 1:
            raise ValueError("SAFE_CAST_SOURCE_SINGLE_CREATE_REQUIRED")
        if not re.search(r"(?i)CREATE\s+(?:OR\s+ALTER\s+)?FUNCTION\s+(?:\[toolbelt_conversion\]|toolbelt_conversion)\s*\.\s*(?:\[" + re.escape(name) + r"\]|" + re.escape(name) + r")\s*\(", text):
            raise ValueError("SAFE_CAST_SOURCE_SLOT_NAME_REQUIRED")
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest().upper()
        chunks.append(f"-- {name}.sql; SHA256(normalisierter Payload)={digest}\n"
                      "EXEC sys.sp_executesql N'" + text.replace("'", "''") + "';\n")
    return "".join(chunks)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    output = MODULE / "Deployment" / "CreateObjects.sql"
    expected = render()
    if args.write:
        output.write_text(expected, encoding="utf-8", newline="\n")
    elif not output.is_file() or output.read_text(encoding="utf-8") != expected:
        raise SystemExit("SAFE_CAST_GENERATED_DEPLOYMENT_STALE")
    print("PASS: SAFE_CAST_CANONICAL_DEPLOYMENT_PAYLOADS")
