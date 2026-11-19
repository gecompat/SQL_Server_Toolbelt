"""Paketierung darf Code/Nachweis nicht ändern oder neue Erfolgsaussagen erfinden."""
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import prepare_one_call_bundle as bundle


class OneCallBundleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = bundle.payload("857383be62543e9c918b518dec5c841148368897")

    def test_entrypoint_inner_archive_and_native_record_are_exact_git_bytes(self):
        record = bundle.verify_payload(self.files)
        for name in (bundle.ENTRY, bundle.INNER, bundle.EVIDENCE):
            self.assertEqual(self.files[name], bundle.git_file(record["source_commit"], name))
        self.assertEqual(bundle.sha(self.files[bundle.INNER]), bundle.INNER_SHA)
        self.assertEqual(record["native_evidence"]["reused_profiles"], 12)
        self.assertFalse(record["new_sql_tls_execution"])

    def mutated(self, operation):
        files = dict(self.files)
        manifest = json.loads(files[bundle.MANIFEST])
        operation(files, manifest)
        manifest["files"] = {p: {"bytes": len(b), "sha256": bundle.sha(b)}
                             for p, b in files.items() if p not in (bundle.MANIFEST, bundle.SUMS)}
        files[bundle.MANIFEST] = bundle.encoded(manifest)
        files[bundle.SUMS] = "".join(bundle.sha(b)+"  "+p+"\n" for p,b in sorted(files.items()) if p != bundle.SUMS).encode()
        return files

    def test_self_consistent_modified_entrypoint_is_rejected(self):
        files = self.mutated(lambda f,m: f.update({bundle.ENTRY: f[bundle.ENTRY]+b"\n# changed\n"}))
        with self.assertRaises(ValueError): bundle.verify_payload(files)

    def test_self_consistent_foreign_inner_zip_is_rejected(self):
        files = self.mutated(lambda f,m: f.update({bundle.INNER: b"foreign bytes"}))
        with self.assertRaises(ValueError): bundle.verify_payload(files)

    def test_missing_layout_member_or_invented_tls_claim_is_rejected(self):
        for change in (lambda f,m:f.pop(bundle.INNER), lambda f,m:m.update(new_sql_tls_execution=True),
                       lambda f,m:m.update(source_commit="0"*40)):
            with self.subTest(change=change), self.assertRaises((ValueError, bundle.source.ReleaseError)):
                bundle.verify_payload(self.mutated(change))

    def test_duplicate_and_traversal_zip_members_are_rejected(self):
        for names in (("../escape",), ("A", "a")):
            stream=io.BytesIO()
            with zipfile.ZipFile(stream,"w") as z:
                for name in names:z.writestr(name,b"synthetic")
            with self.subTest(names=names), self.assertRaises((ValueError,bundle.source.ReleaseError)):
                bundle.read_zip(stream.getvalue())

    def test_checksums_and_protected_license_bytes(self):
        inner=bundle.read_zip(self.files[bundle.INNER])
        for name,data in inner.items():
            if name == "LICENSE.md" or name.startswith("ThirdParty/"):
                self.assertEqual(self.files[name],data)
        for line in self.files[bundle.SUMS].decode().splitlines():
            digest,name=line.split("  ",1)
            self.assertEqual(bundle.sha(self.files[name]),digest)

    def test_all_local_document_links_exist_and_external_links_are_pinned(self):
        import posixpath,re
        for name,data in self.files.items():
            if not name.endswith(".md"):continue
            for target in re.findall(rb"(?<=\]\()([^\s)]+)(?=\))",data):
                target=target.decode()
                if target.startswith(("#","/")) or ":" in target:continue
                path=posixpath.normpath(posixpath.join(posixpath.dirname(name),target.split("#")[0]))
                self.assertIn(path,self.files,(name,target))
        commit=json.loads(self.files[bundle.MANIFEST])["source_commit"]
        self.assertIn(("/blob/"+commit+"/").encode(),self.files["Deployment/ONE-CALL-INSTALL.md"])

    def test_all_four_profiles_from_unpacked_bundle_need_no_download(self):
        pwsh=shutil.which("pwsh")
        self.assertIsNotNone(pwsh,"PowerShell is required by the packaging gate")
        with tempfile.TemporaryDirectory(prefix="toolbelt-bundle-test-") as directory:
            for name,data in self.files.items():
                path=Path(directory)/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            result=subprocess.run([pwsh,"-NoProfile","-NonInteractive","-File",
                str(ROOT/"Deployment/Tests/Test-OneCallBundle.ps1"),"-BundleRoot",directory],
                capture_output=True,text=True,encoding="utf-8",timeout=120)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn("PASS ONE_CALL_BUNDLE_CONTEXT",result.stdout)

    def test_new_archive_roundtrip_sidecar_and_no_overwrite(self):
        with tempfile.TemporaryDirectory(prefix="toolbelt-bundle-archive-") as directory:
            output=Path(directory)/"install.zip"
            bundle.build("857383be62543e9c918b518dec5c841148368897",output)
            self.assertEqual(bundle.verify(output)["project_prerelease"],bundle.TAG)
            with self.assertRaises(ValueError):bundle.build("HEAD",output)
            Path(str(output)+".sha256").write_text("0"*64+"  install.zip\n")
            with self.assertRaises(ValueError):bundle.verify(output)

    def test_committed_delivery_and_source_archives_are_verified(self):
        relative="Releases/1.0.0/Builds/rc3/"
        # Der Vorbereitungscommit enthält noch keine zukünftigen Ausgaben.
        # Sobald sie integriert sind, prüft CI die tatsächlich gelieferten
        # Archive zusätzlich zur Roundtrip-/Negativprüfung des Generators.
        tracked=subprocess.run(["git","cat-file","-e","HEAD:"+relative+"BUILD-RECEIPT.json"],
                               cwd=ROOT,capture_output=True).returncode == 0
        if not tracked:self.skipTest("preparation commit; delivery artifacts not integrated yet")
        path=ROOT/relative
        manifest=bundle.verify(path/"SQL-Server-Toolbelt-v1.0.0-rc.3-Install.zip")
        import prepare_current_candidate as candidate
        candidate.verify(path/"SQL-Server-Toolbelt-v1.0.0-rc.3-source.zip")
        receipt=json.loads((path/"BUILD-RECEIPT.json").read_bytes())
        self.assertEqual(manifest["source_commit"],receipt["source_commit"])
        commit=manifest["source_commit"]
        standalone=bundle.relocate_doc(bundle.git_file(commit,bundle.GUIDE),bundle.GUIDE,"START-HERE.md",set(),commit)
        # Das separate Asset/Repositoryblatt hat keinen entpackten Deployment-
        # Nachbarn. Es braucht eigene commitfeste Links; die ZIP-Seite behält
        # hingegen ihre funktionierenden lokalen Verweise.
        self.assertEqual((path/"START-HERE.md").read_bytes(),standalone)
        for line in (path/"SHA256SUMS.txt").read_text().splitlines():
            digest,name=line.split("  ",1)
            self.assertEqual(bundle.sha((path/name).read_bytes()),digest)
