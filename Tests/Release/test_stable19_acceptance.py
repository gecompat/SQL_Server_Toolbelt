"""Negative Vor-SQL-Gates des aktuellen Stable-19-Labtreibers."""
from pathlib import Path
import copy
import hashlib
import json
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / "Tests/Release/Invoke-Stable19AcceptanceLab.ps1"
RECORD = ROOT / "Releases/1.0.0/stable19-acceptance.json"


def validate_record(record):
    expected = {m["module_id"]: m["module_version"] for m in json.loads(
        (ROOT / "Releases/1.0.0/release-plan.json").read_text())["modules"] if m["proposed_channel"] == "stable"}
    if (record["schema_version"] != "toolbelt-stable19-acceptance/v1"
            or record["result"] != "PASS_BOUNDED_INTEGRATION"
            or record["publication_authorized"] is not False or record["stable_release_approved"] is not False
            or record["module_status_changed"] is not False or record["support_scope_changed"] is not False
            or record["authenticated_tls"] != "not executed" or record["test_purpose"] != "Functional"
            or len(record["modules"]) != 19
            or {m["module_id"]: m["module_version"] for m in record["modules"]} != expected):
        raise ValueError("Stable cohort or scope differs")
    native = record["native_execution"]
    cases = native["cases"]
    required = {(p, v, c) for p in ("windows", "linux") for v, cls in
                (("2019", [150]), ("2022", [150, 160]), ("2025", [150, 160, 170])) for c in cls}
    if (len(cases) != 12 or {(c["platform"], c["sql_version"], c["compatibility_level"]) for c in cases} != required
            or {c["index"] for c in cases} != set(range(12))
            or any(c["result"] != "PASS" or c["independent_audit"] != "PASS"
                   or c["modes"] != ["local", "central"] or c["own_databases_removed"] != 3 for c in cases)
            or native["context_count"] != 12 or native["deployment_paths"] != 24
            or native["independent_audits"] != 12 or native["own_databases_removed"] != 36
            or native["failed_native_attempts"] != 0
            or native["help_calls"] != sum(c["help_calls"] for c in cases) or native["help_calls"] != 576
            or native["help_assertions"] != sum(c["help_assertions"] for c in cases) or native["help_assertions"] != 36576
            or len(record["public_objects"]) != 56
            or len({(o["schema"], o["name"]) for o in record["public_objects"]}) != 56):
        raise ValueError("Incomplete native matrix or counters")
    # Originalbytes am Ausführungscommit prüfen; neuere Quellen werden nicht
    # stillschweigend als historische Ausführung ausgegeben.
    commit = record["source_commit"]
    pins = record["source_sha256"]
    requests = "".join(commit + ":" + p + "\n" for p in pins).encode()
    result = subprocess.run(["git", "cat-file", "--batch"], input=requests, cwd=ROOT,
                            capture_output=True, timeout=30,
                            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    if result.returncode or result.stderr:
        raise ValueError("Qualification source commit unavailable")
    offset = 0
    for path, digest in pins.items():
        end = result.stdout.index(b"\n", offset)
        header = result.stdout[offset:end].split()
        if len(header) != 3 or header[1] != b"blob":
            raise ValueError("Missing qualification input")
        size = int(header[2]); data = result.stdout[end + 1:end + 1 + size]
        if hashlib.sha256(data).hexdigest().upper() != digest:
            raise ValueError("Qualification input differs: " + path)
        offset = end + size + 2
    if offset != len(result.stdout):
        raise ValueError("Unexpected qualification input")


class Stable19AcceptanceTests(unittest.TestCase):
    def test_actual_record_is_bound_to_complete_matrix_and_source_commit(self):
        validate_record(json.loads(RECORD.read_text(encoding="utf-8")))

    def test_partial_matrix_and_publication_upgrade_are_rejected(self):
        record = json.loads(RECORD.read_text(encoding="utf-8"))
        missing = copy.deepcopy(record)
        missing["native_execution"]["cases"].pop()
        with self.assertRaisesRegex(ValueError, "Incomplete"):
            validate_record(missing)
        upgraded = copy.deepcopy(record)
        upgraded["stable_release_approved"] = True
        with self.assertRaisesRegex(ValueError, "scope"):
            validate_record(upgraded)

    def rejected(self, change, expected, outside=False):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=None if outside else ROOT / ".runtime") as temp:
            folder = Path(temp)
            record = dict(schema_version="toolbelt-stable19-acceptance/v1", source_commit="1" * 40,
                          cases=[dict(Platform="linux", Version="2019", Patch="latest", CL=150)] * 12,
                          modules=[dict(module_id="toolbelt.test." + str(i), module_version="1.0.0") for i in range(19)],
                          pins=[], exports=dict(local="unused", central="unused"), fixture="unused")
            change(record, folder)
            runset = folder / "runset.json"
            runset.write_text(json.dumps(record), encoding="utf-8")
            result = subprocess.run(["pwsh", "-NoProfile", "-NonInteractive", "-File", str(DRIVER),
                                     "-RunsetPath", str(runset), "-CaseIndex", "0"],
                                    cwd=ROOT, capture_output=True, text=True, timeout=25,
                                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
            self.assertEqual(result.returncode, 1)
            self.assertIn(expected, result.stdout)
            self.assertEqual(result.stderr, "")
            self.assertFalse(list(folder.glob("case-*.json")), "No native attempt may begin")

    def test_outside_private_directory_rejected(self):
        self.rejected(lambda r, d: None, "RELEASE_PRIVATE_PATH_REQUIRED", outside=True)

    def test_unsupported_engine_cl_rejected(self):
        self.rejected(lambda r, d: r["cases"][0].update(CL=170), "STABLE19_CASE")

    def test_missing_driver_and_payload_pins_rejected(self):
        self.rejected(lambda r, d: None, "STABLE19_REQUIRED_PIN")

    def test_changed_pinned_input_rejected(self):
        def change(record, folder):
            source = folder / "source.sql"
            source.write_text("SELECT 42;", encoding="utf-8")
            record["pins"] = [dict(path=str(source), sha256="0" * 64)]
        self.rejected(change, "RELEASE_INPUT_DRIFT")


if __name__ == "__main__":
    unittest.main()
