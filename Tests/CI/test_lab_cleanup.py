"""Prüft den echten Lab-Cleanup mit synthetischen SQL-/Dateiantworten."""

from pathlib import Path
import io
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / "Tests/CI/run-lab-target.sh").read_text(encoding="utf-8")
START = SOURCE.index("cleanup_lab_run() {\n")
FUNCTION = SOURCE[START:SOURCE.index("\n}\n", START) + 3]
GIT_BASH = Path("C:/Program Files/Git/bin/bash.exe")
BASH = str(GIT_BASH) if GIT_BASH.is_file() else shutil.which("bash")


class LabCleanupTests(unittest.TestCase):
    def call(self, original=0, failure="none", clr=False, unchanged=False):
        if BASH is None:
            self.fail("LAB_CLEANUP_NOT_EXECUTED_BASH_REQUIRED")
        # Alle Effekte sind Funktionsdoubles; weder SQL noch rm wird ausgeführt.
        setup = r'''set -euo pipefail
TBX_TEST_DB_SUFFIX=012345abcdef
lab_work_dir=synthetic-private-directory
clr_adapter=plain
clr_hash=0x01 clr_dependency_hash=0x02
trust_before=0 clr_dependency_trust_before=0
clr_enabled_before=0 show_advanced_before=0
SQLCMDPASSWORD=synthetic
calls=0
run_control_query() {
    calls=$((calls + 1))
    printf 'QUERY=%s\n' "$calls"
    if [[ "$failure" == "sql$calls" ]]; then return 17; fi
}
rm() { printf 'PRIVATE_CLEANUP QUERIES=%s\n' "$calls"; [[ "$failure" != private ]]; }
'''
        script = (setup + f"failure={failure}\n"
                  + ("clr_adapter=run-regex-linux.sh\n" if clr else "")
                  + ("trust_before=1 clr_dependency_trust_before=1 clr_enabled_before=1 show_advanced_before=1\n"
                     if unchanged else "")
                  + FUNCTION + f"\ntrap cleanup_lab_run EXIT INT TERM\nexit {original}\n")
        return subprocess.run([BASH, "-s"], input=script, text=True,
                              capture_output=True, timeout=10)

    def test_success_requires_complete_cleanup(self):
        for clr, query_count in ((False, 2), (True, 6)):
            result = self.call(clr=clr)
            self.assertEqual(result.returncode, 0, result.stderr)
            # Die echten SQL-Aufrufe unterdrücken stdout; der Zähler wird
            # beim synthetischen Datei-Cleanup sichtbar gemacht.
            self.assertIn(f"QUERIES={query_count}", result.stdout)
            self.assertEqual(result.stdout.count("PRIVATE_CLEANUP"), 1)

    def test_every_sql_cleanup_failure_blocks_success(self):
        for query in range(1, 7):
            with self.subTest(query=query):
                result = self.call(failure=f"sql{query}", clr=True)
                self.assertEqual(result.returncode, 1)
                self.assertIn("LAB_CLEANUP_UNVERIFIED", result.stderr)
                self.assertIn("QUERIES=6", result.stdout)
                self.assertIn("PRIVATE_CLEANUP", result.stdout)

    def test_private_cleanup_failure_blocks_success(self):
        result = self.call(failure="private")
        self.assertEqual(result.returncode, 1)
        self.assertIn("LAB_CLEANUP_UNVERIFIED", result.stderr)

    def test_preexisting_trust_and_configuration_are_not_restored(self):
        result = self.call(clr=True, unchanged=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("QUERIES=2", result.stdout)

    def test_original_failure_is_preserved(self):
        for failure in ("none", "sql1", "private"):
            result = self.call(original=7, failure=failure)
            self.assertEqual(result.returncode, 7)
            self.assertIn("PRIVATE_CLEANUP", result.stdout)

    def test_optional_measurement_cannot_hide_failed_cleanup(self):
        self.assertEqual(self.call(original=75).returncode, 75)
        for failure in ("sql1", "private"):
            self.assertEqual(self.call(original=75, failure=failure).returncode, 1)

    def test_cleanup_checks_absence_and_disarms_traps(self):
        self.assertIn("trap - EXIT INT TERM", FUNCTION)
        self.assertIn("LAB_OWNED_RESOURCES_REMAIN", FUNCTION)
        self.assertIn("LAB_TRUST_RESTORE_UNVERIFIED", FUNCTION)
        self.assertIn("LAB_CONFIGURATION_RESTORE_UNVERIFIED", FUNCTION)
        self.assertIn("trap cleanup_lab_run EXIT INT TERM", SOURCE)
        # EXEC-Prozedurparameter akzeptieren keine direkten CONVERT-Aufrufe.
        self.assertNotIn("@hash = CONVERT(", FUNCTION)


if __name__ == "__main__":
    result = unittest.TextTestRunner(stream=io.StringIO()).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(LabCleanupTests))
    print(f"{'PASS' if result.wasSuccessful() else 'FAILED'} LAB_CLEANUP_TESTS "
          f"TESTS={result.testsRun} FAILURES={len(result.failures) + len(result.errors)}")
    if not result.wasSuccessful():
        for test, _ in result.failures + result.errors:
            print(f"FAILED_METHOD={test.id().split('.')[-1]}")
    raise SystemExit(0 if result.wasSuccessful() else 1)
