"""V2 package tampering and output-boundary controls; no SQL or DLL loading."""
import contextlib
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
                archive.writestr(composer.NAME + "/" + name, data)
        path.with_suffix(".zip.sha256").write_text(composer.sha(path.read_bytes()) + "  " + path.name + "\n", encoding="ascii")
        with self.assertRaisesRegex(ValueError, reason):
            guard.validate(path)

    def test_self_consistent_wrong_binary(self):
        self.altered(lambda payload: payload.__setitem__(composer.MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.dll", b"synthetic-wrong"), "qualified candidate bytes")

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


if __name__ == "__main__":
    unittest.main()
