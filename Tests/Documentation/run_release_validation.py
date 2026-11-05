"""Documentation entry point: preserve unique release checks and report progress.

The historically pinned standalone release suite is not modified. Its load_tests
hook registers CsvMetadataTests a second time after unittest discovers the same
imported class. Only that known double registration is collapsed here.
"""
from collections import Counter
import importlib
from pathlib import Path
import sys
import unittest


def flatten(suite):
    for test in suite:
        if isinstance(test, unittest.TestSuite):
            yield from flatten(test)
        else:
            yield test


def unique_checks(suite, csv_metadata_type):
    tests = list(flatten(suite))
    counts = Counter(test.id() for test in tests)
    seen = {}
    unique = []
    for test in tests:
        identity = test.id()
        if counts[identity] > 1:
            if type(test) is not csv_metadata_type or counts[identity] != 2:
                raise ValueError("UNREVIEWED_VALIDATION_REPETITION: " + identity)
        if identity in seen:
            if type(seen[identity]) is not type(test):
                raise ValueError("VALIDATION_ID_COLLISION: " + identity)
            continue
        seen[identity] = test
        unique.append(test)
    return unittest.TestSuite(unique), len(tests), len(tests) - len(unique)


class ProgressResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.progress_stream = sys.stdout

    def startTest(self, test):
        print("VALIDATION_TEST_START " + test.id(), file=self.progress_stream, flush=True)
        super().startTest(test)


def main():
    release_tests = Path(__file__).resolve().parents[1] / "Release"
    sys.path.insert(0, str(release_tests))
    module = importlib.import_module("test_prepare_release")
    suite = unittest.defaultTestLoader.loadTestsFromModule(module)
    unique, discovered, removed = unique_checks(suite, module.CsvMetadataTests)
    print(f"VALIDATION_DISCOVERY discovered={discovered} unique={unique.countTestCases()} duplicate_registrations={removed}", flush=True)
    result = unittest.TextTestRunner(resultclass=ProgressResult).run(unique)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
