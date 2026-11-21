"""Delivery boundaries with synthetic SQL only; no server or publication."""
from pathlib import Path
import importlib.util
import hashlib
import json
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'Scripts/Install'))
spec=importlib.util.spec_from_file_location('install_set',ROOT/'Scripts/Install/New-InstallSet.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
COMMIT='a'*40


class InstallSetTests(unittest.TestCase):
    def test_embedded_assembly_bytes_and_declared_names_are_bound(self):
        selected=[{'objects':[{'type':'ASSEMBLY','name':'tlblt_Contoso'}]}]
        data=(b'DECLARE @bits0 varbinary(max)=0xCAFE;\n'
              b"IF NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'tlblt_Contoso')"
              b" BEGIN DECLARE @ddl0 nvarchar(max)=CAST(N'CREATE ASSEMBLY [tlblt_Contoso]\n"
              b"FROM '+CONVERT(nvarchar(max),@bits0,1)+N' WITH PERMISSION_SET=SAFE;'; EXEC sys.sp_executesql @ddl0; END;\n")
        hashes={'tlblt_Contoso':hashlib.sha512(bytes.fromhex('CAFE')).hexdigest()}
        module.payload.validate_assemblies(data,hashes,selected)
        for changed in (data.replace(b'CAFE',b'CEFE'),data.replace(b'@ddl0',b'@ddl1'),
                        data.replace(b'@bits0,1',b'@bits1,1'),
                        data.replace(b'tlblt_Contoso',b'tlblt_Fabrikam')):
            with self.assertRaises(ValueError): module.payload.validate_assemblies(changed,hashes,selected)
        with self.assertRaises(ValueError): module.payload.validate_assemblies(data,{},selected)

    def test_source_inventory_rejects_missing_or_changed_entries(self):
        payload=module.payload
        original=b'SELECT 1;\n'
        with patch.object(payload.common,'source_files',return_value=([],{'Contoso.sql':None})), patch.object(
                payload.common,'build_source_bindings',return_value={}), patch.object(
                payload,'source_file',return_value=original):
            names={'Contoso.sql',*payload.common.LICENSE_FILES}
            names.update(path.relative_to(ROOT).as_posix() for path in (ROOT/'Modules').glob('*/module.yaml'))
            bindings=dict.fromkeys(names,payload.sha(original))
            payload.validate_sources(COMMIT,bindings,[],{})
            del bindings['Contoso.sql']
            with self.assertRaisesRegex(ValueError,'complete profile source inventory'):
                payload.validate_sources(COMMIT,bindings,[],{})
            bindings['Contoso.sql']=payload.sha(b'SELECT 2;\n')
            with self.assertRaisesRegex(ValueError,'profile does not bind declared source'):
                payload.validate_sources(COMMIT,bindings,[],{})

    def inner(self,path,tamper=False,duplicate=False):
        files={'Sql/Install-'+p+'-'+m+'.sql':b'USE [ContosoToolbelt];\nSELECT 1;\n'
               for p in ('Windows','Portable') for m in ('local','central')}
        manifest={'schema':'toolbelt-install-package/v2','source_commit':COMMIT,'lifecycle':'create-only',
                  'release':'v1.0.0-rc.5','runtime_qualification':'not executed for this exact package',
                  'files':{k:module.payload.sha(v) for k,v in files.items()}}
        if tamper: files[next(iter(files))]=b'SELECT 2;'
        with zipfile.ZipFile(path,'w') as z:
            for k,v in files.items(): z.writestr(k,v)
            z.writestr('PACKAGE.json',json.dumps(manifest))
            if duplicate: z.writestr('extra.sql',b'SELECT 3;')

    def test_links_resolve_to_exact_source_without_rewriting_external_or_anchors(self):
        result=module.documentation(b'[Build](../Scripts/Install/README.md) [Here](#x) [Web](https://example.com)',
                                    'Deployment/README.md',COMMIT).decode()
        self.assertIn('/blob/'+COMMIT+'/Scripts/Install/README.md',result)
        self.assertIn('[Here](#x)',result);self.assertIn('[Web](https://example.com)',result)
        with self.assertRaises(ValueError): module.documentation(b'[Bad](../../outside)','INSTALL.md',COMMIT)

    def test_bound_client_and_all_four_sql_files_are_packaged(self):
        with tempfile.TemporaryDirectory() as d:
            path=Path(d)/'inner.zip';self.inner(path)
            with patch.object(module.payload,'git',return_value=COMMIT.encode()), patch.object(
                    module.payload,'source_file',side_effect=lambda c,p:(ROOT/p).read_bytes()):
                files,record=module.install_set(path,COMMIT)
            self.assertTrue(set(module.CLIENT)<=set(files))
            self.assertEqual(len([n for n in files if n.startswith('Sql/')]),4)
            self.assertEqual(files['LICENSE.md'],(ROOT/'LICENSE.md').read_bytes())
            self.assertIn(b'not published',files['START-HERE.txt'])
            self.assertEqual(record['runtime_qualification'],'not executed for this exact package')
            self.assertEqual(files['Package/Toolbelt-Install-Payload.zip'],path.read_bytes())

    def test_tampered_or_extra_inner_entries_are_rejected(self):
        for tamper,extra in ((True,False),(False,True)):
            with self.subTest(tamper=tamper,extra=extra),tempfile.TemporaryDirectory() as d:
                path=Path(d)/'inner.zip';self.inner(path,tamper,extra)
                with patch.object(module.payload,'git',return_value=COMMIT.encode()),self.assertRaises(ValueError):
                    module.install_set(path,COMMIT)

    def test_zip_bytes_are_reproducible_and_existing_output_is_preserved(self):
        with tempfile.TemporaryDirectory() as d:
            first=Path(d)/'first.zip';second=Path(d)/'second.zip'
            module.payload.write_zip(first,{'b.txt':b'B','a.txt':b'A'})
            module.payload.write_zip(second,{'a.txt':b'A','b.txt':b'B'})
            self.assertEqual(first.read_bytes(),second.read_bytes())
            with self.assertRaises(ValueError): module.payload.write_zip(first,{'a.txt':b'changed'})
            self.assertEqual(first.read_bytes(),second.read_bytes())


if __name__=='__main__': unittest.main()
