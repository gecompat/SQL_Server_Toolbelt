"""Prüft die eng gebundene DDL-Hilfeprojektion des Base64-Moduls."""
from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import base64_ddl_help as transition

class Base64DdlHelpTransitionTests(unittest.TestCase):
    def inputs(self):
        report = json.loads((ROOT / transition.BASELINE_REPORT_PATH).read_bytes())
        with zipfile.ZipFile(ROOT / transition.BASELINE_ARCHIVE_PATH) as archive:
            old = {
                path: archive.read(transition.BASELINE_PREFIX + path)
                for path in transition.SOURCE_PATHS
            }
        current = {path: (ROOT / path).read_bytes() for path in transition.SOURCE_PATHS}
        return report, old, current

    def test_exact_comment_only_projection_is_archive_bound(self):
        report, old, current = self.inputs()
        transition.validate_transition(ROOT, report, old, current)

    def test_projection_rejects_sql_and_baseline_pin_drift(self):
        report, old, current = self.inputs()
        drifted_sql = dict(current)
        path = transition.SOURCE_PATHS[0]
        drifted_sql[path] = drifted_sql[path].replace(
            b"@UrlSafe bit=0", b"@UrlSafe bit=1", 1
        )
        with self.assertRaises(transition.Base64HelpTransitionError):
            transition.validate_transition(ROOT, report, old, drifted_sql)

        drifted_old = dict(old)
        drifted_old[path] += b"unexpected baseline byte"
        with self.assertRaises(transition.Base64HelpTransitionError):
            transition.validate_transition(ROOT, report, drifted_old, current)

    def test_missing_help_and_unapproved_scope_are_rejected(self):
        report, old, current = self.inputs()
        path = transition.SOURCE_PATHS[3]
        block, anchor, _label = transition.INSERTIONS[path][0]
        without_help = dict(current)
        without_help[path] = without_help[path].replace(block, b"", 1)
        with self.assertRaises(transition.Base64HelpTransitionError):
            transition.validate_transition(ROOT, report, old, without_help)

        with self.assertRaises(transition.Base64HelpTransitionError):
            transition.validate_historical_source(ROOT, "Modules/unknown.sql", "0" * 64)

        record = json.loads((ROOT / transition.RECORD_PATH).read_bytes())
        record["publication_authorized"] = 0
        with self.assertRaises(transition.Base64HelpTransitionError):
            transition._validate_record(record)

        record = json.loads((ROOT / transition.RECORD_PATH).read_bytes())
        record["comment_insertions"].append("Modules/unknown.sql#Injected")
        with self.assertRaises(transition.Base64HelpTransitionError):
            transition._validate_record(record)


if __name__ == "__main__":
    unittest.main()
