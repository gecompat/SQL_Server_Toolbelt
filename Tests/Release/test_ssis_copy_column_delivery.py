"""SQL-freie Zulassungsgegenproben für den eigenen ZIP-Lieferumfang."""
from pathlib import Path
import copy
from datetime import datetime,timedelta,timezone
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[2]
AREA='Modules/toolbelt.tsql.ssis-debug/'
DRIVER=AREA+'Tests/Runtime/Invoke-CopyColumnDeliveryLab.ps1'
ARCHIVE=AREA+'InstallPackages/SSIS-Debug-CopyColumnV1-Install-Windows.zip'


@unittest.skipUnless(shutil.which('pwsh'),'PowerShell required; no SQL fallback')
class DeliveryAdmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        runtime=ROOT/'.runtime';runtime.mkdir(exist_ok=True)
        cls.temporary=tempfile.TemporaryDirectory(prefix='copy-delivery-admission-',dir=runtime)
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.stage=Path(cls.temporary.name)
        with zipfile.ZipFile(ROOT/ARCHIVE) as z:
            # Das eingecheckte Archiv ist ein bekannter rein synthetischer Testinput.
            for name in z.namelist():
                target=cls.stage/name
                if not target.resolve().is_relative_to(cls.stage.resolve()):
                    raise AssertionError('test archive escapes private root')
                if name.endswith('/'):target.mkdir(parents=True,exist_ok=True)
                else:target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(name))
        cls.package=cls.stage/'SSIS-Debug-CopyColumnV1-Install-Windows'
        qualified=ROOT/AREA/'Tests/Qualification/CopyColumn.V1.20261114.json'
        record=json.loads(qualified.read_bytes())
        framework=cls.stage/'synthetic-framework.json'
        # Nur Validatorinput; dieser synthetische Receipt wird nie nativ ausgeführt.
        framework.write_text(json.dumps({'result':'PASS','scope':'offline-framework','profile':'Full',
            'cases':29,'sqlExecuted':False,'providerSha512':record['qualified_assembly_sha512'].upper()}),encoding='utf-8')
        files=[ROOT/DRIVER,ROOT/ARCHIVE,qualified,framework,cls.package/'PACKAGE-MANIFEST.json']
        files += [ROOT/AREA/f'Tests/Runtime/{p}' for p in ('Invoke-LabContract.ps1','Invoke-PackageInstallCases.ps1',
                   'Invoke-ComponentsV2Lab.ps1','Invoke-ComponentsV2Audit.ps1')]
        files += [ROOT/'Tests/CI'/p for p in ('run-lab-local.ps1','LabQualifiedContract.ps1')]
        files += [p for p in cls.package.rglob('*') if p.is_file()]
        files += [p for p in (ROOT/AREA/'Clr').iterdir() if p.suffix in ('.cs','.csproj')]
        files += list((ROOT/AREA/'Exchange/Core').glob('*.cs'))
        files += [ROOT/'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs']
        pins=[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest().upper()} for p in sorted(set(files))]
        cases=[]
        for version,patch,levels in [('2019','CU32',[150]),('2022','CU26',[150,160]),('2025','CU8',[150,160,170])]:
            for cl in levels:
                for mode in ('local','central'):
                    journal=cls.stage/f'case-{len(cases)}';journal.mkdir()
                    cases.append({'version':version,'patch':patch,'cl':cl,'mode':mode,
                                  'targetKey':'synthetic-selected-target','journal':str(journal)})
        now=datetime.now(timezone.utc)
        cls.base={'schema':'ssis-copy-column-zip-delivery/1','approved':True,'cases':cases,'pins':pins,
                  'startedUtc':now.isoformat(),'deadlineUtc':(now+timedelta(minutes=60)).isoformat(),
                  'archive':str(ROOT/ARCHIVE),'framework':str(framework),'packageRoot':str(cls.package),
                  'packageManifestSha256':hashlib.sha256((cls.package/'PACKAGE-MANIFEST.json').read_bytes()).hexdigest().upper(),
                  'providerSha512':record['qualified_assembly_sha512'].upper(),'contractSha256':'0'*64}

    def invoke(self,record=None,index=0,describe=False):
        path=self.stage/'test-runset.json';path.write_text(json.dumps(record or self.base),encoding='utf-8')
        args=[shutil.which('pwsh'),'-NoProfile','-File',str(ROOT/DRIVER),'-RunsetPath',str(path),
              '-ExpectedRunsetSha256',hashlib.sha256(path.read_bytes()).hexdigest().upper(),'-CaseIndex',str(index)]
        args+=['-DescribeOnly'] if describe else ['-ValidateOnly']
        return subprocess.run(args,capture_output=True,text=True,encoding='utf-8',timeout=30)

    def reject(self,change,code):
        r=copy.deepcopy(self.base);change(r);p=self.invoke(r)
        self.assertNotEqual(p.returncode,0)
        self.assertIn(code,p.stdout+p.stderr)

    def test_actual_archive_and_last_context_admitted_without_sql(self):
        for index in (0,11):
            with self.subTest(index=index):
                p=self.invoke(index=index);self.assertEqual(p.returncode,0,p.stderr)
                self.assertIn('SSIS_COPY_DELIVERY_ADMISSION_PASS; no SQL',p.stdout)

    def test_strict_boolean_authority(self):
        self.reject(lambda r:r.update(approved='true'),'SSIS_COPY_DELIVERY_DECLARED_SCOPE')

    def test_missing_and_wrong_context(self):
        self.reject(lambda r:r['cases'].pop(),'SSIS_COPY_DELIVERY_DECLARED_SCOPE')
        self.reject(lambda r:r['cases'][0].update(cl=160),'SSIS_COPY_DELIVERY_ROSTER')

    def test_expired_window_cannot_be_renewed(self):
        self.reject(lambda r:r.update(deadlineUtc=(datetime.now(timezone.utc)+timedelta(minutes=120)).isoformat()),'SSIS_COPY_DELIVERY_ADMISSION_CLOSED')

    def test_changed_file_pin_and_missing_archive_pin(self):
        self.reject(lambda r:r['pins'][0].update(sha256='0'*64),'SSIS_COPY_DELIVERY_INPUT_DRIFT')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=r['archive']]),'SSIS_COPY_DELIVERY_REQUIRED_PIN')

    def test_product_source_pin_cannot_be_omitted(self):
        source=str(ROOT/AREA/'Clr/Translator.cs')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=source]),'SSIS_COPY_DELIVERY_PRODUCT_SOURCE')

    def test_unqualified_dll_cannot_be_substituted(self):
        self.reject(lambda r:r.update(providerSha512='0'*128),'SSIS_COPY_DELIVERY_QUALIFIED_ARTIFACT')

    def test_bound_shape_preserves_archive_checker_and_removes_old_api(self):
        p=self.invoke(describe=True);self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(p.stdout.count('Invoke-PackageInstallCases.ps1'),1)
        self.assertNotIn('Invoke-ApiCases.ps1',p.stdout)
        self.assertIn("$package.packageName -cne 'SSIS-Debug-CopyColumnV1-Install-Windows'",p.stdout)
        self.assertIn("$deadline=if($ssisNativeCleanupPhase){360}else{300}",p.stdout)
        source=(ROOT/DRIVER).read_text(encoding='utf-8')
        self.assertIn('-ApiOnly -CompatibilityLevel',source)
        self.assertNotIn('-ReleaseRights -',source)
        self.assertNotIn('-Full -',source)


if __name__=='__main__':
    unittest.main()
