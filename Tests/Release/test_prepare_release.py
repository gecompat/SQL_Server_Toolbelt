"""Deterministische Releasegrenzen; kein SQL, Build, Tag oder Netzwerk."""
import copy
import importlib.util
import io
import json
from pathlib import Path
import stat
import unittest
import warnings
import zipfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("prepare_release", ROOT / "Scripts/Release/prepare_release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class PreparationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plan = json.loads((ROOT / release.PLAN).read_bytes())
        _, cls.files = release.snapshot("HEAD")
        cls.files[release.PLAN] = (ROOT / release.PLAN).read_bytes()
        cls.files[release.MATRIX] = (ROOT / release.MATRIX).read_bytes()

    def test_complete_current_plan_and_matrix(self):
        self.assertEqual(release.make_plan(self.files, self.plan["product_commit"]), self.plan)
        self.assertEqual(release.matrix(self.plan), (ROOT / release.MATRIX).read_bytes())
        self.assertEqual(len(self.plan["modules"]), 45)
        self.assertEqual(sum(m["proposed_channel"] == "stable" for m in self.plan["modules"]), 19)

    def test_publication_stays_unauthorized(self):
        self.assertIs(self.plan["publication_authorized"], False)
        self.assertEqual(self.plan["state"], "prepared_not_published")
        self.assertTrue(all(m["current_release_status"] == "unreleased" for m in self.plan["modules"]))

    def test_product_and_foundation_bindings(self):
        release.validate_plan(self.files, self.plan)

    def test_dependency_demotion_is_transitive(self):
        graph = {"a": {"validation_status": "validated", "dependencies": ["b"]},
                 "b": {"validation_status": "validated", "dependencies": ["c"]},
                 "c": {"validation_status": "partially validated", "dependencies": []}}
        self.assertEqual(release.channels(graph), {"a": "preview", "b": "preview", "c": "preview"})
        rows = {m["module_id"]: m for m in self.plan["modules"]}
        for mid in ("toolbelt.core.second-session", "toolbelt.core.event-log"):
            self.assertEqual(rows[mid]["validation_status"], "validated")
            self.assertEqual(rows[mid]["proposed_channel"], "preview")

    def test_missing_dependency_and_cycles_fail(self):
        for graph in ({"a": {"validation_status": "validated", "dependencies": ["missing"]}},
                      {"a": {"validation_status": "validated", "dependencies": ["a"]}}):
            with self.assertRaises(release.ReleaseError):
                release.channels(graph)

    def test_no_stable_module_depends_on_preview(self):
        rows = {m["module_id"]: m for m in self.plan["modules"]}
        for m in rows.values():
            if m["proposed_channel"] == "stable":
                self.assertEqual(m["validation_status"], "validated")
                self.assertTrue(all(rows[d]["proposed_channel"] == "stable" for d in m["dependencies"]))

    def test_forged_channel_or_approval_is_rejected(self):
        files = dict(self.files)
        files[release.MATRIX] = release.matrix(self.plan)
        for change in ("approval", "channel"):
            plan = copy.deepcopy(self.plan)
            if change == "approval":
                plan["publication_authorized"] = True
            else:
                next(m for m in plan["modules"] if m["proposed_channel"] == "preview")["proposed_channel"] = "stable"
            with self.assertRaises(release.ReleaseError):
                release.validate_plan(files, plan)

    def test_version_and_matrix_drift_fail(self):
        files = dict(self.files)
        files[release.MATRIX] = release.matrix(self.plan)
        key = "Modules/toolbelt.core.result-table/module.yaml"
        files[key] = files[key].replace(b'version: "1.0.0"', b'version: "9.0.0"', 1)
        with self.assertRaises(release.ReleaseError):
            release.validate_plan(files, self.plan)
        files = dict(self.files)
        files[release.MATRIX] = b"stale"
        with self.assertRaises(release.ReleaseError):
            release.validate_plan(files, self.plan)

    def test_private_and_windows_alias_paths_fail(self):
        for name in ("../outside", "/absolute", "C:/private", "a\\b", "a/../b", ".git/config",
                     ".runtime/private.json", "module/obj/output", "private.pfx", "private.pdb",
                     ".env", "a/secrets.json", "a/nul.txt", "a/aux", "a./file", "a/file ", "a//b"):
            with self.subTest(path=name), self.assertRaises(release.ReleaseError):
                release.safe_path(name)

    def test_archive_duplicate_and_symlink_fail(self):
        for names, symlink in ((["a", "A"], False), (["link"], True)):
            data = io.BytesIO()
            with warnings.catch_warnings(), zipfile.ZipFile(data, "w") as archive:
                warnings.simplefilter("ignore", UserWarning)
                for name in names:
                    entry = zipfile.ZipInfo(name)
                    entry.create_system = 3
                    entry.external_attr = ((stat.S_IFLNK if symlink else stat.S_IFREG) | 0o644) << 16
                    archive.writestr(entry, b"target")
            with self.assertRaises(release.ReleaseError):
                release.read_zip(data.getvalue())

    def test_zip_is_repeatable_and_preserves_bytes(self):
        payload = {"LICENSE.md": b"synthetic license", "Modules/example.sql": b"SELECT 1;\r\n"}
        first = release.write_zip(payload)
        self.assertEqual(first, release.write_zip(dict(reversed(list(payload.items())))))
        actual = release.read_zip(first)
        self.assertEqual(actual[release.NAME + "/Modules/example.sql"], payload["Modules/example.sql"])

    def test_root_entrypoint_links_are_rebased(self):
        data = {f"{release.DIRECTORY}/START-HERE.md":
                b"[guide](README.md) [matrix](FREIGABEMATRIX.md) [deployment](../../Deployment/README.md)"}
        actual = release.start_here(data).decode()
        self.assertIn(f"({release.DIRECTORY}/README.md)", actual)
        self.assertIn(f"({release.DIRECTORY}/FREIGABEMATRIX.md)", actual)
        self.assertIn("(Deployment/README.md)", actual)


if __name__ == "__main__":
    unittest.main()
