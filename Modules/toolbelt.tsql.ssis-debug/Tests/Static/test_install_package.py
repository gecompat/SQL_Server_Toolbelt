"""Offline-Gegenproben: auch selbstkonsistent umgehashte falsche Inputs ablehnen."""
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock
import zipfile
import sys

import validate_install_package as guard


class PackageIntegrity(unittest.TestCase):
    def setUp(self):
        sys.path.insert(0, str(guard.ROOT / "Tests/Release"))
        from ssis_historical_context import historical_root
        snapshot=historical_root(guard.ROOT,"75d42047557d06b82777ba0c860e90f44247920e")
        self.enterContext(mock.patch.object(guard,"ROOT",snapshot))
        self.enterContext(mock.patch.object(guard,"MODULE",snapshot/"Modules/toolbelt.tsql.ssis-debug"))

    def altered(self, mutation, reason):
        with zipfile.ZipFile(guard.ARCHIVE) as z:
            payload = {n.split('/', 1)[1]: z.read(n) for n in z.namelist()}
        mutation(payload)
        manifest = json.loads(payload['PACKAGE-MANIFEST.json'])
        manifest['files'] = [{'path':p, 'bytes':len(b), 'sha256':guard.sha(b)}
                             for p,b in sorted(payload.items()) if p not in ('PACKAGE-MANIFEST.json','SHA256SUMS.txt')]
        payload['PACKAGE-MANIFEST.json'] = (json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode()
        payload['SHA256SUMS.txt'] = ''.join(guard.sha(b)+'  '+p+'\n' for p,b in sorted(payload.items())
                                          if p != 'SHA256SUMS.txt').encode()
        runtime = guard.MODULE.parents[1] / '.runtime'
        runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='ssis-package-test-',dir=runtime) as temp:
            root = Path(temp).resolve()
            self.assertEqual(root.parent, runtime.resolve())
            path = root / guard.ARCHIVE.name
            with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
                for p,b in payload.items():
                    z.writestr(guard.NAME+'/'+p,b)
            path.with_suffix('.zip.sha256').write_text(guard.sha(path.read_bytes())+'  '+path.name+'\n',encoding='ascii')
            with self.assertRaisesRegex(ValueError,reason):
                guard.main(path)

    def test_original(self):
        with contextlib.redirect_stdout(io.StringIO()):
            guard.main()

    def test_self_consistent_source_drift(self):
        def mutation(p):
            key='Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs'
            p[key]=(p[key].replace(b'\r\n',b'\n') if b'\r\n' in p[key] else p[key].replace(b'\n',b'\r\n'))
        self.altered(mutation,'qualified build source hash')

    def test_self_consistent_manifest_drift(self):
        def mutation(p):
            key='Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json'
            data=json.loads(p[key]);data['sha512']='0'*128;p[key]=json.dumps(data).encode()
        self.altered(mutation,'original qualified release manifests')

    def test_self_consistent_wrong_binary(self):
        self.altered(lambda p:p.__setitem__('Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.dll',b'wrong synthetic binary'),
                     'assembly hash')

    def test_noncanonical_evidence(self):
        def mutation(p):
            key=json.loads(p['PACKAGE-MANIFEST.json'])['nativeBinaryQualification']
            data=json.loads(p[key]);data['total_native_assertions']=0;p[key]=json.dumps(data).encode()
        self.altered(mutation,'canonical native qualification')

    def test_unsafe_path(self):
        self.altered(lambda p:p.__setitem__('../synthetic-escape.txt',b'synthetic'),'unsafe ZIP path')


if __name__ == '__main__':
    unittest.main()
