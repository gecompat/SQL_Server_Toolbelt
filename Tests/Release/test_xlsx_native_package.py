"""Neue Paket-/Adapterguards; historische Prüfquellen bleiben unverändert."""
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import new_xlsx_install_package as package


class XlsxNativePackageTests(unittest.TestCase):
    def test_current_qualified_candidate_binding(self):
        old=json.loads((ROOT/'Releases/1.0.0/xlsx-sst-budget-correction.json').read_bytes())
        with zipfile.ZipFile(ROOT/old['candidate_bundle']['path']) as archive:
            for name, expected in old['candidate_bundle']['files'].items():
                self.assertEqual(package.digest(archive.read(name)),expected)
        for path in package.source_files():
            self.assertTrue(path.startswith('Deployment/') or any(path.startswith('Modules/'+m+'/') for m in package.MODULES))
            self.assertNotIn('/bin/',path)
            self.assertNotIn('/obj/',path)

    def test_native_oracle_and_cleanup_source_binding(self):
        old=(ROOT/'Tests/Release/Invoke-XlsxSharedStringBoundaryLab.ps1').read_text(encoding='utf-8')
        new=(ROOT/'Tests/Release/Invoke-XlsxFullSizeLab.ps1').read_text(encoding='utf-8')
        marker='} finally {\n    foreach ($connection in $script:connections)'
        a=old[old.index(marker):old.index('\nif ($failure) { Write-Output')]
        b=new[new.index(marker):new.index('\nif ($failure) { Write-Output')]
        self.assertEqual(a.replace('XLSX_SST','XLSX_FULL_SIZE'),b)
        for token in ("$caught.Number -ne 51520",'$caught.Message -cne $ExpectedError',
                      '$rowCount -ne 0',"@('Uninstall','UninstallAbsent')",'XLSX_FULL_SIZE_REPEAT_ASSEMBLY_DRIFT',
                      'XLSX_FULL_SIZE_AUDIT_RESULT_SET','XLSX_FULL_SIZE_AUDIT_LIFECYCLE_SET'):
            self.assertIn(token,new)

    def test_preparation_uses_actual_package_and_exact_framework_inputs(self):
        text=(ROOT/'Tests/Release/Prepare-XlsxFullSizeRunset.ps1').read_text(encoding='utf-8')
        for token in ('XLSX_FULL_SIZE_PORTABLE_BYTES_DRIFT','XLSX_FULL_SIZE_QUALIFIED_FIXTURE_DRIFT',
                      "'Releases/1.0.0/XLSX-FULL-SIZE-FRAMEWORK.json'",'Resolve-LabContract -TestPurpose Functional',
                      'XLSX_FULL_SIZE_MATRIX_TARGET_UNAVAILABLE'):
            self.assertIn(token,text)
        self.assertNotIn('& $deployAll',text)
        self.assertNotIn('New-Lab',text)

    def test_current_package_and_tamper_rejection(self):
        path=ROOT/'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-XLSX-Install.zip'
        if not path.exists():
            self.skipTest('Final package not frozen yet; pre-native source checks only')
        package.verify(path)
        with zipfile.ZipFile(path) as archive:
            payload={n:archive.read(n) for n in archive.namelist()}
        key=package.PREFIX+'SQL/Install-Windows-local.sql'
        payload[key]+=b'-- changed\n'
        with tempfile.TemporaryDirectory() as temp:
            bad=Path(temp)/path.name
            with zipfile.ZipFile(bad,'w') as archive:
                for name,data in payload.items():archive.writestr(name,data)
            Path(str(bad)+'.sha256').write_text(package.digest(bad.read_bytes())+'  '+bad.name+'\n')
            with self.assertRaisesRegex(ValueError,'file drift'):
                package.verify(bad)


if __name__=='__main__':unittest.main()
