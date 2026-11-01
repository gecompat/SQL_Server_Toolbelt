"""Gegenproben verhindern unzulässige Aufwertung der Linux-Hostabnahme."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("ssis_linux_export", ROOT / "Scripts/Release/validate_ssis_linux_export.py")
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)


class LinuxExportEvidence(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((ROOT / evidence.REPORT).read_text("utf-8"))

    def reject(self, change, *, files=False):
        record = copy.deepcopy(self.record)
        change(record)
        with self.assertRaises(ValueError):
            evidence.validate(ROOT, record, check_files=files)

    def test_original_record_and_current_source_binding(self):
        evidence.validate(ROOT)

    def test_missing_native_linux_run(self):
        self.reject(lambda r: r["runs"].pop())

    def test_windows_is_not_linux_evidence(self):
        self.reject(lambda r: r["runs"][1].update(platform="Windows"))

    def test_different_binary(self):
        self.reject(lambda r: r["runs"][1].update(host_sha256="0" * 64))

    def test_different_model_output(self):
        self.reject(lambda r: r["runs"][1]["cases"][0].update(output_sha256="0" * 64))

    def test_source_drift(self):
        key = next(iter(self.record["runs"][0]["source_sha256"]))
        self.reject(lambda r: [run["source_sha256"].update({key: "0" * 64}) for run in r["runs"]], files=True)

    def test_missing_source(self):
        self.reject(lambda r: r["runs"][1]["source_sha256"].popitem())

    def test_unknown_or_escape_source_path(self):
        self.reject(lambda r: r["runs"][1]["source_sha256"].update({"../private": "0" * 64}))

    def test_missing_cli_case(self):
        self.reject(lambda r: r["runs"][1]["cases"].pop())

    def test_partial_output_on_error(self):
        self.reject(lambda r: [run["cases"][-1].update(output_sha256="0" * 64) for run in r["runs"]])

    def test_boolean_is_not_exit_code_or_count(self):
        self.reject(lambda r: r["runs"][1]["cases"][0].update(exit_code=False))
        self.reject(lambda r: r["runs"][1].update(case_count=True))

    def test_sql_is_outside_host_proof(self):
        self.reject(lambda r: r["runs"][1].update(sql_executed=0))
        self.reject(lambda r: r["runs"][1].update(sql_executed=True))

    def test_no_scope_expansion(self):
        self.reject(lambda r: r["separate_boundaries"].remove("SQL CLR on Linux"))

    def test_runtime_origin(self):
        self.reject(lambda r: r["runtime"].update(archive_url="https://example.com/runtime.tar.gz"))

    def test_runtime_archive_hash(self):
        self.reject(lambda r: r["runtime"].update(archive_sha512="0" * 128))

    def test_product_commit(self):
        self.reject(lambda r: [run.update(source_commit="0" * 40) for run in r["runs"]])

    def test_duplicate_json_key(self):
        with self.assertRaises(ValueError):
            json.loads('{"platform":"Windows","platform":"Linux"}', object_pairs_hook=evidence.unique)


if __name__ == "__main__":
    unittest.main()
