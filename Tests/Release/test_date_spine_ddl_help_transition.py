"""Prüft die enge DDL-Hilfeprojektion für die drei Date-Spine-Wrapper."""
from __future__ import annotations

from io import BytesIO
from pathlib import Path
import sys
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import date_spine_ddl_help as transition


class DateSpineDdlHelpTransitionTests(unittest.TestCase):
    def inputs(self):
        archive_bytes = transition._archive_bytes(ROOT)
        with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
            historical = {
                path: archive.read(transition.ARCHIVE_PREFIX + path)
                for path in transition.SOURCE_PATHS
            }
        current = {path: (ROOT / path).read_bytes() for path in transition.SOURCE_PATHS}
        return archive_bytes, historical, current

    def test_exact_comment_projection_preserves_shared_date_report_and_core_pin(self):
        archive_bytes, historical, current = self.inputs()
        import caller_metadata
        import json

        report = json.loads((ROOT / transition.REPORT_PATH).read_bytes())
        self.assertEqual(
            report["source_sha256"][transition.CORE_PATH], transition.CORE_SHA256
        )
        for path in transition.SOURCE_PATHS:
            caller_metadata.validate_source(ROOT, path, report["source_sha256"][path])
        transition.validate_transition(
            ROOT, historical, current, archive_bytes=archive_bytes
        )

    def test_sql_drift_and_missing_saved_help_are_rejected(self):
        _archive_bytes, historical, current = self.inputs()
        path = transition.SOURCE_PATHS[0]
        sql_drift = dict(current)
        old = b"(@RangeStart, @RangeEndExclusive, 'day')"
        changed = b"(@RangeEndExclusive, @RangeStart, 'day')"
        self.assertEqual(sql_drift[path].count(old), 1)
        sql_drift[path] = sql_drift[path].replace(old, changed, 1)
        with self.assertRaises(transition.DateSpineHelpTransitionError):
            transition.validate_transition(ROOT, historical, sql_drift)

        missing_help = dict(current)
        block = transition.INSERTIONS[path][0].encode("utf-8")
        self.assertEqual(missing_help[path].count(block), 1)
        missing_help[path] = missing_help[path].replace(block, b"", 1)
        with self.assertRaises(transition.DateSpineHelpTransitionError):
            transition.validate_transition(ROOT, historical, missing_help)

    def test_unknown_path_and_historical_pin_are_rejected(self):
        with self.assertRaises(transition.DateSpineHelpTransitionError):
            transition.validate_historical_source(ROOT, "Modules/unknown.sql", "0" * 64)
        with self.assertRaises(transition.DateSpineHelpTransitionError):
            transition.validate_historical_source(ROOT, transition.SOURCE_PATHS[0], "0" * 64)


if __name__ == "__main__":
    unittest.main()
