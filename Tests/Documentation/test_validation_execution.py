"""Coverage-preserving scheduling and bounded, truthful failure diagnostics."""
import contextlib
import importlib
import io
from pathlib import Path
import subprocess
import sys
from types import SimpleNamespace
import unittest
from unittest import mock

import run_release_validation as runner
import validate_documentation as validator


def case_types():
    class CsvCase(unittest.TestCase):
        def runTest(self):
            pass
    class OtherCase(unittest.TestCase):
        def runTest(self):
            pass
    return CsvCase, OtherCase

class ExecutionTests(unittest.TestCase):
    def setUp(self):
        self.csv, self.other = case_types()

    def test_only_known_double_registration_is_removed(self):
        first = self.csv()
        other = self.other()
        suite = unittest.TestSuite([first, unittest.TestSuite([self.csv(), other])])
        unique, discovered, removed = runner.unique_checks(suite, self.csv)
        self.assertEqual((discovered, removed), (3, 1))
        self.assertEqual(list(runner.flatten(unique)), [first, other])

    def test_unreviewed_and_triple_repetitions_are_not_silently_dropped(self):
        for tests in ([self.other(), self.other()], [self.csv(), self.csv(), self.csv()]):
            with self.subTest(count=len(tests)), self.assertRaisesRegex(ValueError, 'UNREVIEWED_VALIDATION_REPETITION'):
                runner.unique_checks(unittest.TestSuite(tests), self.csv)

    def test_suite_with_no_duplicates_is_unchanged(self):
        tests = [self.csv(), self.other()]
        unique, count, removed = runner.unique_checks(unittest.TestSuite(tests), self.csv)
        self.assertEqual((count, removed), (2, 0))
        self.assertEqual(list(runner.flatten(unique)), tests)

    def test_actual_suite_preserves_every_unique_case_and_only_collapses_csv(self):
        sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'Release'))
        module = importlib.import_module('test_prepare_release')
        suite = unittest.defaultTestLoader.loadTestsFromModule(module)
        before = list(runner.flatten(suite))
        unique, discovered, removed = runner.unique_checks(suite, module.CsvMetadataTests)
        after = list(runner.flatten(unique))
        self.assertEqual({test.id() for test in before}, {test.id() for test in after})
        self.assertEqual(len(after), len({test.id() for test in after}))
        self.assertEqual(discovered - len(after), removed)
        self.assertEqual(removed, len(unittest.defaultTestLoader.getTestCaseNames(module.CsvMetadataTests)))

    def test_progress_precedes_execution_and_failure_is_not_success(self):
        class Fails(unittest.TestCase):
            def runTest(self):
                self.fail('synthetic failure')
        progress, summary = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(progress):
            result = unittest.TextTestRunner(stream=summary, resultclass=runner.ProgressResult).run(unittest.TestSuite([Fails()]))
        self.assertIn('VALIDATION_TEST_START ', progress.getvalue())
        self.assertFalse(result.wasSuccessful())
        self.assertEqual(len(result.failures), 1)

    def test_entry_point_returns_failure_instead_of_a_green_exit(self):
        class Fails(unittest.TestCase):
            def runTest(self):
                self.fail('synthetic failure')
        with mock.patch.object(runner.sys, 'path', list(sys.path)), mock.patch.object(runner.importlib, 'import_module', return_value=SimpleNamespace(CsvMetadataTests=self.csv)), mock.patch.object(runner.unittest.defaultTestLoader, 'loadTestsFromModule', return_value=unittest.TestSuite([Fails()])), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(runner.main(), 1)

    def test_fixture_stdout_redirection_does_not_hide_progress(self):
        progress, redirected, summary = io.StringIO(), io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(progress):
            result = runner.ProgressResult(unittest.runner._WritelnDecorator(summary), True, 0)
        with contextlib.redirect_stdout(redirected):
            result.startTest(self.csv())
        self.assertIn('VALIDATION_TEST_START ', progress.getvalue())
        self.assertEqual(redirected.getvalue(), '')

    def test_timeout_is_failure_with_last_test_even_after_large_output(self):
        output = b'VALIDATION_TEST_START synthetic.last\n' + b'x' * 20000
        timeout = subprocess.TimeoutExpired(['python', 'synthetic.py'], 1200, output=output, stderr=b'bounded error')
        with mock.patch.object(validator.subprocess, 'run', side_effect=timeout) as run:
            with self.assertRaises(validator.ValidationError) as caught:
                validator.run_hidden(['python', 'synthetic.py'], timeout=1200, text=True, encoding='utf-8')
        message = str(caught.exception)
        self.assertIn('synthetic.last', message)
        self.assertIn('1200 Sekunden', message)
        self.assertIn('synthetic.py', message)
        self.assertIn('nicht abgeschlossen', message)
        self.assertIn('bounded error', message)
        self.assertLess(len(message), 9000)
        self.assertEqual(run.call_args.kwargs['timeout'], 1200)

    def test_missing_or_non_utf8_timeout_output_still_reports_failure(self):
        for output in (None, b'\xff'):
            with self.subTest(output=output):
                with mock.patch.object(validator.subprocess, 'run', side_effect=subprocess.TimeoutExpired('synthetic', 30, output=output)):
                    with self.assertRaisesRegex(validator.ValidationError, '30 Sekunden'):
                        validator.run_hidden(['synthetic'], timeout=30)

    def test_success_and_windows_hidden_flags_are_preserved(self):
        completed = subprocess.CompletedProcess(['synthetic'], 0, 'ok', '')
        with mock.patch.object(validator.sys, 'platform', 'win32'), mock.patch.object(validator.subprocess, 'CREATE_NO_WINDOW', 0x08000000, create=True), mock.patch.object(validator.subprocess, 'run', return_value=completed) as run:
            actual = validator.run_hidden(['synthetic'], timeout=12, creationflags=16)
        self.assertIs(actual, completed)
        self.assertEqual(run.call_args.kwargs['creationflags'], 16 | 0x08000000)
        self.assertEqual(run.call_args.kwargs['timeout'], 12)


if __name__ == '__main__':
    unittest.main()
