#!/usr/bin/env python3
"""Ergänzt das zentrale W4b-Testmatrix-Inventar."""

import os
from pathlib import Path

path = Path("Tests/README.md")
text = path.read_text(encoding="utf-8")
evidence_url = os.environ["EVIDENCE_URL"]
row = (
    "| `toolbelt.core.work-type` | "
    "[WORK_TYPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-type/Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md) | "
    "`partially validated`; Registrierung, RowVersion, Savepoints, Concurrency, Redeploy, Central und Data-Loss-Uninstall-Schutz auf SQL Server 2025 Linux CL150/160/170, "
    f"Evidence {evidence_url} |\n"
)
marker = "| `toolbelt.file.content` |"
if "| `toolbelt.core.work-type` |" not in text:
    if text.count(marker) != 1:
        raise RuntimeError("Testinventar-Marke wurde nicht eindeutig gefunden.")
    text = text.replace(marker, row + marker, 1)
path.write_text(text, encoding="utf-8", newline="\n")
