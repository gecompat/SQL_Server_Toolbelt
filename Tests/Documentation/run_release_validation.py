"""Documentation entry point: preserve unique release checks and report progress.

Historical verifier bytes remain in their immutable archives. The current suite
checks recorded sources separately from current applicability. Its load_tests
hook has one known duplicate CSV registration, collapsed without losing checks.
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
    for module_name in ("test_evidence_sources", "test_current_qualification_overview",
                        "test_worker_terminal_qualification", "test_constructor_caller_contract",
                        "test_copy_targets_contract", "test_json_schema_target_scope", "test_zip_archive_limit", "test_zip_entry_limits",
                        "test_constructor_client_metadata", "test_constructor_aggregate_caller", "test_geo129_contract",
                        "test_constructor_acl_contract", "test_table_clone_planner_contract",
                        "test_table_clone_waves_contract", "test_table_clone_trigger_contract", "test_table_clone_client_contract", "test_table_clone_sqlcmd_caller_contract", "test_table_clone_genuine_contract", "test_table_clone_planner_rights_contract", "test_table_clone_known_predecessors_contract"):
        source_tests = importlib.import_module(module_name)
        source_suite = unittest.defaultTestLoader.loadTestsFromModule(source_tests)
        discovered += source_suite.countTestCases()
        unique.addTests(source_suite)
    print(f"VALIDATION_DISCOVERY discovered={discovered} unique={unique.countTestCases()} duplicate_registrations={removed}", flush=True)
    result = unittest.TextTestRunner(resultclass=ProgressResult).run(unique)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
