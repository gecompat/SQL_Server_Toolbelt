"""Gegenproben für native Trustabnahme und Manipulation vor jedem SQL-Zugriff."""
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("ssis_administrative_trust", ROOT / "Scripts/Release/validate_ssis_administrative_trust.py")
trust = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(trust)


class AdministrativeTrustEvidence(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((ROOT / trust.REPORT).read_text("utf-8"))

    def reject(self, mutation, *, files=False):
        record = copy.deepcopy(self.record)
        mutation(record)
        with self.assertRaises(ValueError):
            trust.validate(ROOT, record, check_files=files)

    def test_native_record_and_current_sources(self):
        trust.validate(ROOT)

    def test_missing_version(self):
        self.reject(lambda r: r["cases"].pop())

    def test_wrong_patch(self):
        self.reject(lambda r: r["cases"][0].update(patch="base"))

    def test_boolean_is_not_assertion_count(self):
        self.reject(lambda r: r["cases"][0].update(assertions=True))

    def test_original_failures_are_retained(self):
        self.reject(lambda r: r["attempt_history"].update(failed_cleaned=0))

    def test_original_calls_not_reset(self):
        self.reject(lambda r: r["attempt_history"].update(total_driver_calls=6))

    def test_insert_path_required(self):
        self.reject(lambda r: r["cases"][1].update(insert_executed=False))

    def test_independent_audit_required(self):
        self.reject(lambda r: r["cases"][2].update(independent_audit="not executed"))

    def test_cleanup_required(self):
        self.reject(lambda r: r["cases"][0].update(trust_restored=False))

    def test_no_unknown_hash_trust(self):
        self.reject(lambda r: r["attempt_history"].update(unknown_hash_trusted=True))

    def test_no_permission_or_configuration_grants(self):
        self.reject(lambda r: r["scope"].update(permission_grants=True))
        self.reject(lambda r: r["scope"].update(configuration_changes=0))

    def test_null_and_overlong_oracles_cannot_be_removed(self):
        self.reject(lambda r: r["cases"][0]["checks"].pop("null_rejected_by_public_guard"))
        self.reject(lambda r: r["cases"][0]["checks"].update(overlong_rejected_by_public_guard=False))

    def test_source_drift(self):
        self.reject(lambda r: r["source_sha256"].update({trust.SCRIPT: "0" * 64}), files=True)

    def test_snapshot_recognizes_only_original_archive_bytes(self):
        current = (ROOT / trust.SCRIPT).read_bytes()
        previous = trust.snapshot_predecessor_source(ROOT, trust.SCRIPT, current)
        self.assertEqual(trust.sha(previous), trust.HISTORICAL_SCRIPT_SHA256)
        self.assertNotEqual(current, previous)

    def test_snapshot_never_accepts_unknown_current_guard(self):
        with self.assertRaises(ValueError):
            trust.snapshot_predecessor_source(ROOT, trust.SCRIPT, b"unknown source")

    def test_snapshot_no_generic_source_override(self):
        with self.assertRaises(ValueError):
            trust.snapshot_predecessor_source(ROOT, "../private", b"")

    def test_no_scope_expansion(self):
        self.reject(lambda r: r["separate_boundaries"].clear())

    def test_duplicate_key(self):
        with self.assertRaises(ValueError):
            json.loads('{"result":"FAIL","result":"PASS"}', object_pairs_hook=trust.unique)

    def test_help_archive_path_is_rejected_before_read(self):
        spec = importlib.util.spec_from_file_location("help_archive_boundary", ROOT / "Tests/Release/test_parameter_help_package.py")
        helpcheck = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(helpcheck)
        with zipfile.ZipFile(ROOT / trust.PACKAGE) as archive:
            payload = {i.filename: archive.read(i) for i in archive.infolist()}
        with tempfile.TemporaryDirectory(prefix="ToolbeltTrustBoundary-") as temporary:
            outside = Path(temporary) / "synthetic-private.bin"
            outside.write_bytes(b"synthetic private value")
            build = json.loads(payload["SSIS-BUILD.json"])
            build["sourceFiles"] = [str(outside) + ":" + hashlib.sha256(b"synthetic private value").hexdigest().upper()]
            payload["SSIS-BUILD.json"] = json.dumps(build).encode()
            metadata = json.loads(payload["PACKAGE.json"])
            metadata["files"] = {p: helpcheck.package.sha(b) for p, b in payload.items() if p not in ("PACKAGE.json", "SHA256SUMS")}
            payload["PACKAGE.json"] = json.dumps(metadata).encode()
            payload["SHA256SUMS"] = "".join(helpcheck.package.sha(b) + "  " + p + "\n" for p, b in payload.items() if p != "SHA256SUMS").encode()
            archive_double = mock.MagicMock()
            archive_double.__enter__.return_value = archive_double
            infos = []
            for name, data in payload.items():
                info = zipfile.ZipInfo(name)
                info.file_size = len(data)
                infos.append(info)
            archive_double.infolist.return_value = infos
            archive_double.read.side_effect = lambda name: payload[name.filename if isinstance(name, zipfile.ZipInfo) else name]
            original_read = Path.read_bytes

            def guarded_read(path):
                if path.resolve() == outside.resolve():
                    self.fail("archive path was read before the repository boundary check")
                return original_read(path)

            original_archive = zipfile.ZipFile

            def selected_archive(path, *args, **kwargs):
                if isinstance(path, (str, Path)) and Path(path).resolve() == (ROOT / trust.PACKAGE).resolve():
                    return archive_double
                return original_archive(path, *args, **kwargs)

            with mock.patch.object(helpcheck.zipfile, "ZipFile", side_effect=selected_archive), mock.patch.object(Path, "read_bytes", guarded_read):
                with self.assertRaisesRegex(ValueError, "escapes root"):
                    helpcheck.validate(ROOT)


class BeforeSqlInputGuards(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pwsh = shutil.which("pwsh")
        if not cls.pwsh:
            raise RuntimeError("PowerShell 7.5 required for the pre-SQL guards")
        cls.temporary = tempfile.TemporaryDirectory(prefix="ToolbeltSsisTrustGuards-")
        cls.stage = Path(cls.temporary.name)
        with zipfile.ZipFile(ROOT / trust.PACKAGE) as archive:
            build = json.loads(archive.read("SSIS-BUILD.json"))
            candidates = [bytes.fromhex(m.group(1)) for m in re.finditer(
                r"0x([0-9A-Fa-f]{4096,})", archive.read("Install-Windows-local.sql").decode("utf-8-sig"))]
        binary = next(b for b in candidates if hashlib.sha512(b).hexdigest().upper() == build["sha512"])
        cls.dll = cls.stage / "approved-current.dll"
        cls.dll.write_bytes(binary)
        record = json.loads((ROOT / trust.REPORT).read_text("utf-8"))
        cls.original = {"contract": "ssis-administrative-trust-plan/1", "package": trust.PACKAGE,
                        "files": record["source_sha256"], "dllPath": str(cls.dll),
                        "dllSha256": hashlib.sha256(binary).hexdigest().upper(), "approvedHash": build["sha512"],
                        "targets": [{"version": v, "patch": p, "key": "Contoso" + v} for v, p in
                                    zip(("2019", "2022", "2025"), ("CU32", "CU26", "CU8"))]}

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def invoke(self, change=None, expected=None, wrong_seal=False):
        plan = copy.deepcopy(self.original)
        if change:
            change(plan)
        path = self.stage / "plan.json"
        path.write_text(json.dumps(plan), "utf-8")
        digest = "0" * 64 if wrong_seal else hashlib.sha256(path.read_bytes()).hexdigest().upper()
        environment = dict(os.environ, SQL_SERVER_LAB_TEST_ENV_FILE=str(self.stage / "must-never-be-opened.json"))
        result = subprocess.run([self.pwsh, "-NoProfile", "-File", str(ROOT / trust.METHOD),
                                 "-Mode", "Qualify", "-PlanPath", str(path), "-ExpectedPlanSha256", digest,
                                 "-ValidateOnly"], capture_output=True, text=True, encoding="utf-8", timeout=30,
                                env=environment, creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        if expected:
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(expected, result.stderr)
        else:
            self.assertEqual(result.returncode, 0, "valid source-bound plan rejected")
            self.assertIn("SSIS_TRUST_INPUTS_VALIDATED; no SQL", result.stdout)

    def test_valid_plan_without_lab_discovery_or_sql(self):
        self.invoke()

    def test_changed_plan_seal(self):
        self.invoke(wrong_seal=True, expected="SSIS_TRUST_PLAN_CHANGED")

    def test_changed_source_before_open(self):
        self.invoke(lambda p: p["files"].update({trust.SCRIPT: "0" * 64}), expected="SSIS_TRUST_INPUT_CHANGED")

    def test_missing_source_before_open(self):
        self.invoke(lambda p: p["files"].pop(trust.METHOD), expected="SSIS_TRUST_INPUT_CLOSURE")

    def test_changed_explicit_target_before_open(self):
        self.invoke(lambda p: p["targets"][0].update(patch="CU31"), expected="SSIS_TRUST_PLAN_TARGET_MATRIX")

    def test_resealed_unknown_binary_is_not_authorized(self):
        unknown = self.stage / "synthetic-unapproved.dll"
        data = b"synthetic unapproved binary"
        unknown.write_bytes(data)
        self.invoke(lambda p: p.update(dllPath=str(unknown), dllSha256=hashlib.sha256(data).hexdigest().upper(),
                                      approvedHash=hashlib.sha512(data).hexdigest().upper()),
                    expected="SSIS_TRUST_APPROVED_RELEASE_ORIGIN_MISMATCH")

    def test_forged_binary_digest_before_open(self):
        self.invoke(lambda p: p.update(dllSha256="0" * 64), expected="SSIS_TRUST_APPROVED_BINARY_CHANGED")


if __name__ == "__main__":
    unittest.main()
