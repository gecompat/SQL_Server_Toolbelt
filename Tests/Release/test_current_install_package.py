"""Integrität des aktuellen Verbundinstallers, einschließlich konsistenter Fälschungen."""
from pathlib import Path
import copy
import json
import re
import sys
import unittest
from unittest import mock
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import current_install_package as current
import new_parameter_help_package as base
from ssis_historical_context import historical_root


def original_install_context(test):
    snapshot=historical_root(ROOT,'75d42047557d06b82777ba0c860e90f44247920e')
    test.enterContext(mock.patch.object(current,'ROOT',snapshot))
    test.enterContext(mock.patch.object(base,'ROOT',snapshot))
    test.enterContext(mock.patch(__name__+'.ROOT',snapshot))

class CurrentInstallTests(unittest.TestCase):
    def setUp(self):
        original_install_context(self)
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

    def test_inventory_respects_the_two_existing_version_only_contracts(self):
        modules=sorted(p.parent.name for p in (ROOT/'Modules').glob('*/module.yaml'))
        no_mode=[]
        for module in modules:
            closure={}
            base.source_closure(ROOT/'Modules'/module/'Deployment/Deploy.sql',closure)
            text='\n'.join((ROOT/p).read_text(encoding='utf-8-sig') for p in closure)
            if 'Toolbelt.Module.'+module+'.DeploymentMode' not in text:
                no_mode.append(module)
                self.assertIn('Toolbelt.Module.'+module+'.Version',text)
        self.assertEqual(no_mode,['toolbelt.filesystem.windows','toolbelt.tsql.ssis-debug'])

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

class BindingHistoryTests(unittest.TestCase):
    def setUp(self):
        original_install_context(self)
    def test_three_originals_remain_exact_and_current_delta_is_only_the_pin(self):
        from ssis_parser_binding_history import historical_dependency_source, OLD_HASHES, OLD_PARSER, NEW_PARSER
        import hashlib
        for path, expected in OLD_HASHES.items():
            original=historical_dependency_source(ROOT,path)
            self.assertEqual(hashlib.sha256(original).hexdigest(),expected)
            self.assertEqual((ROOT/path).read_bytes(),original.replace(OLD_PARSER.encode(),NEW_PARSER.encode()))

    def test_extra_source_change_and_corrupt_archive_are_rejected(self):
        from ssis_parser_binding_history import historical_dependency_source, OLD_HASHES, ARCHIVE
        import tempfile
        import shutil
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            path=next(iter(OLD_HASHES))
            (root/path).parent.mkdir(parents=True)
            (root/path).write_bytes((ROOT/path).read_bytes()+b'\n-- unapproved extra change')
            (root/ARCHIVE).parent.mkdir(parents=True)
            shutil.copyfile(ROOT/ARCHIVE,root/ARCHIVE)
            with self.assertRaisesRegex(ValueError,'Unapproved'):
                historical_dependency_source(root,path)
            (root/path).write_bytes((ROOT/path).read_bytes())
            (root/ARCHIVE).write_bytes((root/ARCHIVE).read_bytes()+b'corrupt')
            with self.assertRaisesRegex(ValueError,'archive drift'):
                historical_dependency_source(root,path)

if __name__=='__main__':unittest.main()
