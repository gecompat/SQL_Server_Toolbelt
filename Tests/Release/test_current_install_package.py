"""Integrität des aktuellen Verbundinstallers, einschließlich konsistenter Fälschungen."""
from pathlib import Path
import copy
import json
import re
import sys
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import current_install_package as current
import new_parameter_help_package as base

class CurrentInstallTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with zipfile.ZipFile(ROOT/current.OUTPUT) as archive:
            cls.payload={n:archive.read(n) for n in archive.namelist()}

    def altered(self, change):
        payload=dict(self.payload)
        metadata=json.loads(payload['PACKAGE.json'])
        change(payload,metadata)
        metadata['files']={n:base.sha(b) for n,b in payload.items() if n not in ('PACKAGE.json','SHA256SUMS')}
        payload['PACKAGE.json']=base.encoded(metadata)
        payload['SHA256SUMS']=''.join(base.sha(b)+'  '+n+'\n' for n,b in sorted(payload.items()) if n!='SHA256SUMS').encode()
        return payload

    def test_current_four_profiles_and_exact_binaries(self):
        metadata,_=current.validate_payload(self.payload)
        self.assertEqual(len(metadata['profiles']),4)
        self.assertEqual(len(metadata['binary_sha512']),13)
        self.assertEqual(len(next(p for p in metadata['profiles'] if p['name']=='Windows-local')['modules']),45)

    def test_missing_or_relabelled_profile_is_rejected(self):
        for change in (lambda p,m:m['profiles'].pop(),lambda p,m:m['profiles'][0].update(platform='Portable')):
            with self.subTest(change=change),self.assertRaises(ValueError):
                current.validate_payload(self.altered(change))

    def test_self_consistent_foreign_binary_is_rejected(self):
        def change(p,m):
            name='Install-Windows-local.sql'
            match=re.search(rb'0x(4d5a[0-9a-f]{512,})',p[name])
            self.assertIsNotNone(match)
            blob=bytearray(bytes.fromhex(match[1].decode()));blob[-1]^=1
            p[name]=p[name][:match.start(1)]+blob.hex().encode()+p[name][match.end(1):]
        with self.assertRaisesRegex(ValueError,'embedded binary set'):
            current.validate_payload(self.altered(change))

    def test_omitted_source_or_unknown_binary_pin_is_rejected(self):
        for change in (lambda p,m:m['source_sha256'].pop(next(iter(m['source_sha256']))),
                       lambda p,m:m['binary_sha512'].update({'Toolbelt.Tsql.ScriptParser.dll':'0'*128})):
            with self.subTest(change=change),self.assertRaises(ValueError):
                current.validate_payload(self.altered(change))

    def test_publication_claim_cannot_be_rehashed_to_success(self):
        with self.assertRaises(ValueError):
            current.validate_payload(self.altered(lambda p,m:m.update(publication_authorized=True)))

    def test_changed_compiler_projection_cannot_be_rehashed_to_success(self):
        def change(p,m):
            provenance=json.loads(p['BINARY-PROVENANCE.json'])
            provenance['compiled_source_sha256'].pop(next(iter(provenance['compiled_source_sha256'])))
            p['BINARY-PROVENANCE.json']=base.encoded(provenance)
        with self.assertRaisesRegex(ValueError,'compiler closure'):
            current.validate_payload(self.altered(change))

if __name__=='__main__':unittest.main()
