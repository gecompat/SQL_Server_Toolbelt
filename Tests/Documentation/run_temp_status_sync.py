#!/usr/bin/env python3
"""Temporärer Runner für die einmalige Repository-Statussynchronisierung."""

from __future__ import annotations

import re
from pathlib import Path


WORKFLOW = Path(".github/workflows/temp-sync-repository-status.yml")


def main() -> int:
    workflow = WORKFLOW.read_text(encoding="utf-8")
    match = re.search(
        r"python3 - <<'PY'\n(?P<script>.*?)\n          PY\n",
        workflow,
        flags=re.DOTALL,
    )
    if match is None:
        raise RuntimeError("Eingebettetes Synchronisierungsskript wurde nicht gefunden.")

    script = "\n".join(
        line[10:] if line.startswith("          ") else line
        for line in match.group("script").splitlines()
    )

    # Eine bestehende Kandidatenzeile besitzt keinen abschließenden Tabellenstrich.
    # Die Aktualisierung normalisiert die gesamte Feldzeile unabhängig davon.
    script = script.replace(
        r'field_pattern = rf"^\| \*\*{re.escape(field)}\*\* \|.*?\|$"',
        r'field_pattern = rf"^\| \*\*{re.escape(field)}\*\* \|.*$"',
    )

    inbox_lines = [
        "# Research-Inbox erhält die tatsächlich formalisierten Providerstände.",
        'inbox = "Backlog/TOOLBELT_RESEARCH_INBOX.md"',
        "text = load(inbox)",
        "rows = (",
        '    ("RI-2026-113", "TC-2026-034", "ZIP-Archive kontrolliert extrahieren und erzeugen", status_034),',
        '    ("RI-2026-107", "TC-2026-037", "Kontrolliertes Lesen und Schreiben von Text- und Binärdateien", status_037),',
        '    ("RI-2026-108", "TC-2026-038", "Kontrolliertes Directory Listing", status_038),',
        ")",
        'insertion_marker = "\\n## Bereits vorhandene Kandidaten – zusätzliche Fundstellen\\n"',
        "for research_id, candidate, title, status in rows:",
        '    row = f"| `{research_id}` | `{candidate}` – {title} | {status} |"',
        '    pattern = rf"^\\| `{re.escape(research_id)}` \\| `{re.escape(candidate)}`.*$"',
        "    if re.search(pattern, text, flags=re.MULTILINE):",
        "        text = re.sub(pattern, row, text, count=1, flags=re.MULTILINE)",
        "    else:",
        "        if insertion_marker not in text:",
        '            raise RuntimeError("Research-Inbox-Einfügemarke fehlt.")',
        '        text = text.replace(insertion_marker, "\\n" + row + insertion_marker, 1)',
        "save(inbox, text)",
        "",
    ]
    inbox_replacement = "\n".join(inbox_lines)
    script, changes = re.subn(
        r"# Research-Inbox muss exakt.*?save\(inbox, text\)\n",
        lambda _match: inbox_replacement,
        script,
        count=1,
        flags=re.DOTALL,
    )
    if changes != 1:
        raise RuntimeError("Research-Inbox-Transformationsblock wurde nicht gefunden.")

    exec(compile(script, str(WORKFLOW), "exec"), {"__name__": "__main__"})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
