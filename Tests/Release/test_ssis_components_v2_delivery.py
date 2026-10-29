"""V2 package tampering and output-boundary controls; no SQL or DLL loading."""
import contextlib
import copy
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import new_ssis_components_v2_package as composer
import new_ssis_components_v2_standalone_tsql as installer_renderer
import validate_ssis_components_v2_package as guard


class PrivateTemporary(unittest.TestCase):
    def setUp(self):
        runtime = ROOT / ".runtime"
        if runtime.is_symlink():
            raise ValueError("V2_TEST_RUNTIME_REPARSE")
        runtime.mkdir(exist_ok=True)
        self.context = tempfile.TemporaryDirectory(prefix="ssis-v2-delivery-", dir=runtime)
        self.temp = Path(self.context.name).resolve()
        if self.temp.parent != runtime.resolve() or not self.temp.is_relative_to(ROOT.resolve()):
            raise ValueError("V2_TEST_CLEANUP_SCOPE")
        self.addCleanup(self.context.cleanup)


class OutputBoundary(PrivateTemporary):
    def test_absent_output(self):
        path = self.temp / "synthetic.zip"
        output, sidecar = composer.validate_output(path)
        self.assertEqual(output, path)
        self.assertEqual(sidecar, path.with_suffix(".zip.sha256"))

    def test_existing_sidecar_is_preserved(self):
        path = self.temp / "synthetic.zip"
        sidecar = path.with_suffix(".zip.sha256")
        sidecar.write_text("synthetic-existing", encoding="ascii")
        with self.assertRaisesRegex(ValueError, "output already exists"):
            composer.validate_output(path)
        self.assertEqual(sidecar.read_text(encoding="ascii"), "synthetic-existing")
        self.assertFalse(path.exists())

    def test_existing_archive_is_preserved(self):
        path = self.temp / "synthetic.zip"
        path.write_bytes(b"synthetic-existing")
        with self.assertRaisesRegex(ValueError, "output already exists"):
            composer.validate_output(path)
        self.assertEqual(path.read_bytes(), b"synthetic-existing")

    def test_parent_traversal_rejected(self):
        with self.assertRaisesRegex(ValueError, "repository boundary"):
            composer.validate_output(ROOT / ".." / "synthetic.zip")


class PackageIntegrity(PrivateTemporary):
    @classmethod
    def setUpClass(cls):
        cls.archive = ROOT / composer.MODULE / "InstallPackages" / (composer.NAME + ".zip")
        if not cls.archive.is_file():
            raise ValueError("V2_QUALIFIED_PACKAGE_REQUIRED")

    def test_original(self):
        with contextlib.redirect_stdout(io.StringIO()):
            guard.validate(self.archive)

    def altered(self, mutation, reason):
        with zipfile.ZipFile(self.archive) as archive:
            payload = {name[len(composer.NAME) + 1:]: archive.read(name) for name in archive.namelist()}
        mutation(payload)
        manifest = json.loads(payload["PACKAGE-MANIFEST.json"])
        manifest["files"] = [{"path": path, "bytes": len(data), "sha256": composer.sha(data)}
                             for path, data in sorted(payload.items())
                             if path not in ("PACKAGE-MANIFEST.json", "SHA256SUMS.txt")]
        payload["PACKAGE-MANIFEST.json"] = composer.encoded(manifest)
        payload["SHA256SUMS.txt"] = "".join(composer.sha(data) + "  " + path + "\n"
                                            for path, data in sorted(payload.items())
                                            if path != "SHA256SUMS.txt").encode("ascii")
        path = self.temp / self.archive.name
        with zipfile.ZipFile(path, "x", zipfile.ZIP_DEFLATED) as archive:
            for name, data in payload.items():
                info = zipfile.ZipInfo(composer.NAME + "/" + name)
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(info, data)
        path.with_suffix(".zip.sha256").write_text(composer.sha(path.read_bytes()) + "  " + path.name + "\n", encoding="ascii")
        with self.assertRaisesRegex(ValueError, reason):
            guard.validate(path)

    def test_self_consistent_wrong_binary(self):
        self.altered(lambda payload: payload.__setitem__(composer.MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.dll", b"synthetic-wrong"), "qualified candidate bytes")

    def test_self_consistent_wrong_uninstall(self):
        self.altered(lambda payload: payload.__setitem__(composer.MODULE + "Artifacts/Uninstall.Expanded.sql", b"SELECT 1;"), "qualified candidate bytes")

    def test_removed_guide_and_attribution(self):
        self.altered(lambda payload: payload.__setitem__("START-HERE.txt", b"synthetic"), "preserved installation guide and attribution")

    def test_self_consistent_rewritten_source_manifest(self):
        def mutate(payload):
            key = composer.MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json"
            manifest = json.loads(payload[key])
            manifest["sourceFingerprintSha256"] = "0" * 64
            payload[key] = composer.encoded(manifest)
        self.altered(mutate, "native-qualified original trust manifest")

    def test_rewritten_qualification(self):
        def mutate(payload):
            name = json.loads(payload["PACKAGE-MANIFEST.json"])["nativeBinaryQualification"]
            record = json.loads(payload[name]); record["result"] = "FAIL"
            payload[name] = composer.encoded(record)
        self.altered(mutate, "canonical native qualification")

    def test_traversal_payload(self):
        self.altered(lambda payload: payload.__setitem__("../synthetic-escape.txt", b"synthetic"), "unsafe ZIP path")


class InstallQualification(unittest.TestCase):
    def setUp(self):
        self.package_sha = "a" * 64
        self.record = {
            "schema_version": "1.0",
            "kind": "ssis_components_v2_install_package_qualification",
            "profile": "ssis-debug-components-v2",
            "result": "PASS",
            "publication_authorized": False,
            "package_sha256": self.package_sha,
            "cases": [
                {"platform": "windows", "sql_version": "2019",
                 "compatibility_level": 150, "deployment_mode": "local",
                 "result": "PASS", "final_independent_audit": "PASS"},
                {"platform": "windows", "sql_version": "2025",
                 "compatibility_level": 170, "deployment_mode": "central",
                 "result": "PASS", "final_independent_audit": "PASS"},
            ],
            "final_audit": {
                "case_audits": 2,
                "owned_database_names_absent": 4,
                "trust_states_restored": 8,
                "configuration_baselines_restored": True,
                "input_pins_unchanged": True,
                "failed_package_attempts": 0,
            },
        }

    def encoded(self, record=None):
        value = self.record if record is None else record
        return json.dumps(value, separators=(",", ":")).encode("utf-8")

    def validate(self, record=None):
        raw = self.encoded(record)
        return installer_renderer.validate_install_package_qualification(
            raw, hashlib.sha256(raw).hexdigest().upper(), self.package_sha)

    def test_complete_bound_local_and_central_qualification(self):
        self.assertEqual(self.validate()["package_sha256"], self.package_sha)

    def test_record_hash_is_required(self):
        raw = self.encoded()
        with self.assertRaisesRegex(ValueError, "exact package qualification source"):
            installer_renderer.validate_install_package_qualification(raw, "0" * 64, self.package_sha)

    def test_schema_kind_profile_result_and_authorization_are_required(self):
        mutations = (
            ("schema_version", "2.0"),
            ("kind", "standalone_tsql_installer_runtime_qualification"),
            ("profile", "ssis-debug-v1"),
            ("result", "FAIL"),
            ("publication_authorized", True),
        )
        for key, value in mutations:
            with self.subTest(key=key):
                changed = copy.deepcopy(self.record)
                changed[key] = value
                with self.assertRaises(ValueError):
                    self.validate(changed)

    def test_package_hash_must_match(self):
        changed = copy.deepcopy(self.record)
        changed["package_sha256"] = "b" * 64
        with self.assertRaisesRegex(ValueError, "exact qualified package hash"):
            self.validate(changed)

    def test_exact_local_and_central_cases_with_independent_audits_are_required(self):
        mutations = []
        changed = copy.deepcopy(self.record)
        changed["cases"].pop()
        mutations.append(changed)
        changed = copy.deepcopy(self.record)
        changed["cases"][1]["deployment_mode"] = "local"
        mutations.append(changed)
        changed = copy.deepcopy(self.record)
        changed["cases"][0]["compatibility_level"] = 160
        mutations.append(changed)
        changed = copy.deepcopy(self.record)
        changed["cases"][1]["final_independent_audit"] = "FAIL"
        mutations.append(changed)
        for changed in mutations:
            with self.subTest(cases=changed["cases"]):
                with self.assertRaises(ValueError):
                    self.validate(changed)

    def test_final_cleanup_audit_is_required(self):
        changed = copy.deepcopy(self.record)
        changed["final_audit"]["configuration_baselines_restored"] = False
        with self.assertRaisesRegex(ValueError, "final independent cleanup audit"):
            self.validate(changed)
        changed = copy.deepcopy(self.record)
        changed["final_audit"]["case_audits"] = 1
        with self.assertRaisesRegex(ValueError, "final independent cleanup audit"):
            self.validate(changed)
        changed = copy.deepcopy(self.record)
        changed["final_audit"]["failed_package_attempts"] = False
        with self.assertRaisesRegex(ValueError, "final independent cleanup audit"):
            self.validate(changed)


if __name__ == "__main__":
    unittest.main()
