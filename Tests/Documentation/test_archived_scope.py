"""Actual owned-process deadlines with synthetic children; no SQL access."""
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

from run_archived_release_validation import run_owned


class ArchivedProcessTests(unittest.TestCase):
    def test_unicode_and_failure_exit_are_preserved(self):
        result = run_owned([sys.executable, "-X", "utf8", "-c",
                            "import sys;print('Ä𐐀');print('failure',file=sys.stderr);sys.exit(7)"],
                           capture_output=True, text=True, encoding="utf-8", timeout=5)
        self.assertEqual(result.returncode, 7)
        self.assertEqual(result.stdout.strip(), "Ä𐐀")
        self.assertEqual(result.stderr.strip(), "failure")

    def test_timeout_stops_owned_descendant_and_keeps_progress(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / "should-not-exist.txt"
            child = "import time;from pathlib import Path;time.sleep(2);Path(" + repr(str(marker)) + ").write_text('late')"
            parent = ("import subprocess,sys,time;subprocess.Popen([sys.executable,'-c'," + repr(child)
                      + "]);print('VALIDATION_TEST_START synthetic',flush=True);time.sleep(30)")
            started = time.monotonic()
            with self.assertRaises(subprocess.TimeoutExpired) as raised:
                run_owned([sys.executable, "-c", parent], capture_output=True,
                          text=True, encoding="utf-8", timeout=0.7)
            self.assertLess(time.monotonic() - started, 10)
            self.assertIn("VALIDATION_TEST_START synthetic", raised.exception.stdout)
            time.sleep(2)
            self.assertFalse(marker.exists(), "Owned descendant survived the suite deadline")


if __name__ == "__main__":
    unittest.main()
