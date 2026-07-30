#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
objects = (
    "TVF_LeftShiftBigInt",
    "TVF_RightShiftBigInt",
    "TVF_BitCountBigInt",
    "TVF_GetBitBigInt",
    "TVF_SetBitBigInt",
)
required = [
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/BitOperations.sql",
    "README.md",
    "Tests/BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/BitOperations.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "module.yaml",
]
required += [f"Source/{name}.sql" for name in objects]
required += [f"Documentation/{name}.md" for name in objects]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

source = "\n".join((root / f"Source/{name}.sql").read_text("utf-8") for name in objects)
if source.count("RETURNS TABLE") != 5:
    raise SystemExit("Alle fünf Bit-Objekte müssen Inline TVFs sein.")
for marker in (
    "18446744073709551616",
    "9223372036854775808",
    "ValidationCode",
    "binary(8)",
):
    if marker not in source:
        raise SystemExit(f"Bit-Vertragsmarker fehlt: {marker}")

print("Bigint Bit Operations statische Vertragsprüfung: erfolgreich")
