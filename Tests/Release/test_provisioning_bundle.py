"""Neue Vorbereitung separat binden; keine Aufwertung historischer Clientbelege."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import prepare_provisioning_bundle as bundle
base=bundle.base


class ProvisioningBundleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if subprocess.run(['git','cat-file','-e','HEAD:'+bundle.EVIDENCE],cwd=ROOT,capture_output=True).returncode:
            raise unittest.SkipTest('preparation evidence not committed yet')
        cls.files=bundle.payload('HEAD')

    def test_current_and_historical_sources_are_separate(self):
        manifest=json.loads(self.files[base.MANIFEST])
        self.assertEqual(manifest['project_prerelease'],bundle.TAG)
        self.assertEqual(self.files[bundle.ENTRY],base.git_file(manifest['source_commit'],bundle.ENTRY))
        self.assertEqual(self.files[bundle.HELPER],base.git_file(manifest['source_commit'],bundle.HELPER))
        original=base.payload('857383be62543e9c918b518dec5c841148368897')
        self.assertEqual(self.files[base.INNER],original[base.INNER])
        self.assertEqual(self.files[base.EVIDENCE],original[base.EVIDENCE])
        self.assertNotEqual(self.files[bundle.ENTRY],original[base.ENTRY])

    def test_roundtrip_and_consistently_rehashed_tampering(self):
        with tempfile.TemporaryDirectory() as root:
            path=Path(root)/'install.zip';bundle.build('HEAD',path)
            self.assertEqual(bundle.verify(path)['project_prerelease'],bundle.TAG)
            for member in (bundle.ENTRY,bundle.HELPER,bundle.EVIDENCE):
                files=dict(self.files);files[member]+=b' '
                manifest=json.loads(files[base.MANIFEST]);manifest['files'][member]={'bytes':len(files[member]),'sha256':base.sha(files[member])}
                files[base.MANIFEST]=base.encoded(manifest)
                files[base.SUMS]=''.join(base.sha(b)+'  '+p+'\n' for p,b in sorted(files.items()) if p!=base.SUMS).encode()
                data=base.write_zip(files);path.write_bytes(data)
                Path(str(path)+'.sha256').write_text(base.sha(data)+'  '+path.name+'\n')
                with self.assertRaises(ValueError):bundle.verify(path)

    def test_extracted_bundle_actual_entry_and_preparation(self):
        with tempfile.TemporaryDirectory() as root:
            for name,data in self.files.items():
                path=Path(root)/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            for test in ('Test-OneCallBundle.ps1','Test-InstallerProvisioning.ps1'):
                result=subprocess.run([shutil.which('pwsh'),'-NoProfile','-File',str(ROOT/'Deployment/Tests'/test),'-BundleRoot',root],
                    capture_output=True,text=True,encoding='utf-8',timeout=180)
                self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_native_summary_cannot_promote_failed_case_or_expand_scope(self):
        from unittest.mock import patch
        original=base.git_file
        for scenario in ('failed','modules','scope','promotion','safety'):
            evidence=json.loads(self.files[bundle.EVIDENCE])
            if scenario=='failed':evidence['cases'][0]['profile_sources'][0]['native_state']='COMPLETE'
            elif scenario=='modules':evidence['cases'][0]['profile_sources'][0]['modules']=1
            elif scenario=='scope':evidence['scope']['native_windows_integrated_login']='PASS'
            elif scenario=='promotion':evidence['history']['failed_coordinator_promoted_to_pass']=True
            else:evidence['safety']['audit']='not executed'
            def replaced(commit,path):
                return base.encoded(evidence) if path==bundle.EVIDENCE else original(commit,path)
            with patch.object(base,'git_file',side_effect=replaced):
                with self.assertRaises(ValueError,msg=scenario):bundle.payload('HEAD')

    def test_checksums_licenses_and_local_links(self):
        import re,posixpath
        for line in self.files[base.SUMS].decode().splitlines():
            digest,name=line.split('  ',1);self.assertEqual(base.sha(self.files[name]),digest)
        original=base.read_zip(self.files[base.INNER])
        for name,data in original.items():
            if name=='LICENSE.md' or name.startswith('ThirdParty/'):self.assertEqual(self.files[name],data)
        for name,data in self.files.items():
            if not name.endswith('.md'):continue
            for target in re.findall(rb'(?<=\]\()([^\s)]+)(?=\))',data):
                target=target.decode()
                if target.startswith(('#','/')) or ':' in target:continue
                self.assertIn(posixpath.normpath(posixpath.join(posixpath.dirname(name),target.split('#')[0])),self.files)

    def test_actual_committed_delivery(self):
        relative='Releases/1.0.0/Builds/rc4/'
        if subprocess.run(['git','cat-file','-e','HEAD:'+relative+'BUILD-RECEIPT.json'],cwd=ROOT,capture_output=True).returncode:
            self.skipTest('delivery not committed yet')
        path=ROOT/relative
        record=bundle.verify(path/'SQL-Server-Toolbelt-v1.0.0-rc.4-Install.zip')
        import prepare_current_candidate as candidate
        candidate.verify(path/'SQL-Server-Toolbelt-v1.0.0-rc.4-source.zip')
        standalone=base.relocate_doc(base.git_file(record['source_commit'],bundle.GUIDE),bundle.GUIDE,'START-HERE.md',set(),record['source_commit'],bundle.DOCS)
        self.assertEqual((path/'START-HERE.md').read_bytes(),standalone)


if __name__=='__main__':unittest.main()
