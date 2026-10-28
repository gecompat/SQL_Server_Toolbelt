"""Prüft die enge archivgebundene DDL-Hilfeprojektion für Generate Series."""
from __future__ import annotations

from io import BytesIO
import json
from pathlib import Path
import sys
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import generate_series_ddl_help as transition


class GenerateSeriesDdlHelpTransitionTests(unittest.TestCase):
    def inputs(self):
        archive_bytes = transition._validated_archive_bytes(ROOT)
        with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
            historical = {
                path: archive.read(transition.ARCHIVE_PREFIX + path)
                for path in transition.SOURCE_PATHS
            }
        current = {path: (ROOT / path).read_bytes() for path in transition.SOURCE_PATHS}
        return archive_bytes, historical, current

    def test_exact_comment_projection_preserves_all_three_report_pins(self):
        _archive_bytes, historical, current = self.inputs()
        import caller_metadata
        for index, report_path in enumerate(transition.BASELINE_REPORTS):
            report = json.loads((ROOT / report_path).read_bytes())
            path = transition.SOURCE_PATHS[index % len(transition.SOURCE_PATHS)]
            caller_metadata.validate_source(ROOT, path, report["source_sha256"][path])
        transition.validate_transition(ROOT, historical, current)

    def test_sql_and_missing_comment_drift_are_rejected(self):
        _archive_bytes, historical, current = self.inputs()
        sql_drift = dict(current)
        path = transition.SOURCE_PATHS[0]
        original = b"\n      @Start bigint\n"
        changed = b"\n      @Start int\n"
        self.assertEqual(sql_drift[path].count(original), 1)
        sql_drift[path] = sql_drift[path].replace(original, changed, 1)
        with self.assertRaises(transition.SeriesHelpTransitionError):
            transition.validate_transition(ROOT, historical, sql_drift)

        missing_help = dict(current)
        block = transition.INSERTIONS[path][0][0].encode("utf-8")
        self.assertEqual(missing_help[path].count(block), 1)
        missing_help[path] = missing_help[path].replace(block, b"", 1)
        with self.assertRaises(transition.SeriesHelpTransitionError):
            transition.validate_transition(ROOT, historical, missing_help)

    def test_unknown_path_and_historical_digest_are_rejected(self):
        with self.assertRaises(transition.SeriesHelpTransitionError):
            transition.validate_historical_source(ROOT, "Modules/unknown.sql", "0" * 64)
        with self.assertRaises(transition.SeriesHelpTransitionError):
            transition.validate_historical_source(
                ROOT, transition.SOURCE_PATHS[0], "0" * 64
            )


if __name__ == "__main__":
    unittest.main()
