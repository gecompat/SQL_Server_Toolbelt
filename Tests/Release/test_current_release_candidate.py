"""Aktueller Quellkandidat: Herkunft, Nutzdaten und unveränderte Schutzgates."""
from pathlib import Path
import io
import json
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import prepare_current_candidate as candidate
import prepare_release as release


class CurrentReleaseCandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.commit, cls.sources = release.snapshot("HEAD")

    def test_current_dependencies_and_qualification_boundary_are_preserved(self):
        plan = candidate.current_plan(self.sources, self.commit)
        modules = {m["module_id"]: m for m in plan["modules"]}
        self.assertEqual(len(modules), 45)
        self.assertEqual(plan["channels"], {"stable": 19, "preview": 26})
        self.assertIn("toolbelt.core.result-table", modules["toolbelt.file.content"]["dependencies"])
        self.assertIs(plan["publication_authorized"], False)
        self.assertEqual(plan["full_module_qualification"], "not established")
        self.assertIn("no full business requalification", plan["installer"]["scope"])

    def test_changed_installer_source_is_rejected(self):
        files = dict(self.sources)
        name = "Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql"
        files[name] += b"\n-- synthetic changed source\n"
        with self.assertRaisesRegex(release.ReleaseError, "Quellbindung"):
            candidate.installer_inputs(files)

    def test_qualification_cannot_be_relabelled_as_full_or_published(self):
        for change in ({"publication_authorized": True}, {"scope": "full module qualification"},
                       {"result": "PENDING"}):
            files = dict(self.sources)
            record = json.loads(files[candidate.EVIDENCE])
            record.update(change)
            files[candidate.EVIDENCE] = release.encoded(record)
            with self.subTest(change=change), self.assertRaises(release.ReleaseError):
                candidate.installer_inputs(files)

    def test_package_profiles_must_still_match_current_modules(self):
        original = release.read_zip
        def changed(data):
            result = original(data)
            metadata = json.loads(result["PACKAGE.json"])
            metadata["profiles"][0]["modules"].remove("toolbelt.file.content")
            result["PACKAGE.json"] = release.encoded(metadata)
            result["SHA256SUMS"] = "".join(release.sha(b) + "  " + p + "\n"
                                            for p, b in sorted(result.items()) if p != "SHA256SUMS").encode()
            return result
        with patch.object(release, "read_zip", side_effect=changed):
            with self.assertRaisesRegex(release.ReleaseError, "Modulprofile"):
                candidate.installer_inputs(self.sources)

    def test_failed_native_case_or_changed_compiled_source_is_rejected(self):
        files = dict(self.sources)
        record = json.loads(files[candidate.EVIDENCE])
        record["cases"][0]["result"] = "FAILED"
        files[candidate.EVIDENCE] = release.encoded(record)
        with self.assertRaisesRegex(release.ReleaseError, "Help-Kontexte"):
            candidate.installer_inputs(files)
        files = dict(self.sources)
        files["Modules/toolbelt.tsql.ssis-debug/Clr/Core.cs"] += b"\n// synthetic drift\n"
        with self.assertRaisesRegex(release.ReleaseError, "SSIS-Buildquelle"):
            candidate.installer_inputs(files)

    def test_exact_head_roundtrip_and_self_consistent_tampering(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "current.zip"
            candidate.build(self.commit, path)
            candidate.verify(path)
            original = release.read_zip(path.read_bytes())
            prefix = candidate.NAME + "/"
            for target in (prefix + candidate.PLAN, prefix + "Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql",
                           prefix + candidate.MANIFEST):
                mutated = dict(original)
                if target.endswith(candidate.MANIFEST):
                    metadata = json.loads(mutated[target])
                    metadata["publication_authorized"] = True
                    mutated[target] = release.encoded(metadata)
                else:
                    mutated[target] += b"\n"
                self._write_archive(path, mutated)
                with self.subTest(target=target), self.assertRaisesRegex(release.ReleaseError, "Quellcommit"):
                    candidate.verify(path)
            self._write_archive(path, {**original, prefix + ".runtime/private-synthetic.txt": b"synthetic"})
            with self.assertRaisesRegex(release.ReleaseError, "Lokale oder administrative"):
                candidate.verify(path)

    def test_incomplete_archive_fails_even_with_matching_outer_checksum(self):
        sources = {candidate.MANIFEST: release.encoded({"source_commit": self.commit})}
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "false.zip"
            self._write_archive(path, {candidate.NAME + "/" + p: b for p, b in sources.items()})
            with self.assertRaises(release.ReleaseError):
                candidate.verify(path)

    def test_wrong_checksum_fails_before_archive_processing(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "invalid.zip"
            path.write_bytes(b"synthetic, not a ZIP")
            Path(str(path) + ".sha256").write_text("0" * 64 + "  invalid.zip\n")
            with self.assertRaisesRegex(release.ReleaseError, "prüfsumme"):
                candidate.verify(path)

    def test_duplicate_and_traversal_entries_are_rejected(self):
        for names in ((candidate.NAME + "/../outside",),
                      (candidate.NAME + "/same", candidate.NAME + "/SAME")):
            with tempfile.TemporaryDirectory() as temp:
                path = Path(temp) / "invalid.zip"
                self._write_archive(path, {name: b"synthetic" for name in names})
                with self.subTest(names=names), self.assertRaises(release.ReleaseError):
                    candidate.verify(path)

    def test_existing_output_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "existing.zip"
            path.write_bytes(b"keep synthetic fixture")
            with self.assertRaises(release.ReleaseError):
                candidate.build(self.commit, path)
            self.assertEqual(path.read_bytes(), b"keep synthetic fixture")

    def test_historical_plan_gate_is_not_weakened(self):
        historical = json.loads(self.sources[release.PLAN])
        historical["modules"][0]["manifest_sha256"] = "0" * 64
        with self.assertRaisesRegex(release.ReleaseError, "Releaseplan"):
            release.validate_plan(self.sources, historical)

    @staticmethod
    def _write_archive(path, members):
        members = dict(members)
        prefix = candidate.NAME + "/"
        manifest_path = prefix + candidate.MANIFEST
        if manifest_path in members:
            metadata = json.loads(members[manifest_path])
            if "files" in metadata:
                # Auch ein vollständig neu gehashtes Archiv darf nicht vom
                # unabhängigen Quellcommit abweichen.
                metadata["files"] = {p[len(prefix):]: {"bytes": len(b), "sha256": release.sha(b)}
                                     for p, b in members.items()
                                     if p not in (manifest_path, prefix + candidate.SUMS)}
                members[manifest_path] = release.encoded(metadata)
                members[prefix + candidate.SUMS] = "".join(
                    release.sha(b) + "  " + p[len(prefix):] + "\n"
                    for p, b in sorted(members.items()) if p != prefix + candidate.SUMS).encode()
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_STORED) as archive:
            for name, data in members.items():
                archive.writestr(name, data)
        path.write_bytes(buffer.getvalue())
        Path(str(path) + ".sha256").write_text(release.sha(path.read_bytes()) + "  " + path.name + "\n")


if __name__ == "__main__":
    unittest.main()
