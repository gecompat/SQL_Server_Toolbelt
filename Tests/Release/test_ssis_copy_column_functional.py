"""SQL-freie Gegenproben für die vollständige aktuelle ZIP-Abnahme."""
from pathlib import Path
import copy
import base64
import os
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
DRIVER=AREA+'Tests/Runtime/Invoke-CopyColumnFunctionalLab.ps1'
ARCHIVE=AREA+'InstallPackages/SSIS-Debug-CopyColumnV1-Install-Windows.zip'


@unittest.skipUnless(shutil.which('pwsh'),'PowerShell required; no SQL fallback')
class FunctionalAdmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        runtime=ROOT/'.runtime';runtime.mkdir(exist_ok=True)
        cls.temporary=tempfile.TemporaryDirectory(prefix='f-',dir=runtime)
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
        files=[ROOT/DRIVER,ROOT/ARCHIVE,qualified,framework,cls.package/'PACKAGE-MANIFEST.json',
               ROOT/AREA/'Tests/Qualification/CopyColumn.Delivery.20261115.json']
        files += [ROOT/AREA/f'Tests/Runtime/{p}' for p in ('Invoke-LabContract.ps1','Invoke-PackageInstallCases.ps1',
                   'Invoke-ComponentsV2Lab.ps1','Invoke-ComponentsV2Audit.ps1')]
        files += [ROOT/'Tests/CI'/p for p in ('run-lab-local.ps1','LabQualifiedContract.ps1')]
        files += [p for p in cls.package.rglob('*') if p.is_file()]
        files += [p for p in (ROOT/AREA/'Clr').iterdir() if p.suffix in ('.cs','.csproj')]
        files += list((ROOT/AREA/'Exchange/Core').glob('*.cs'))
        files += [ROOT/'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs']
        files += [p for p in (ROOT/AREA/'Tests/Runtime').rglob('*') if p.is_file()]
        files += [p for p in (ROOT/AREA/'Tests/Fixtures').rglob('*') if p.is_file()]
        pins=[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest().upper()} for p in sorted(set(files))]
        cases=[]
        for version,patch,levels in [('2019','CU32',[150]),('2022','CU26',[150,160]),('2025','CU8',[150,160,170])]:
            for cl in levels:
                for mode in ('local','central'):
                    journal=cls.stage/f'case-{len(cases)}'
                    cases.append({'version':version,'patch':patch,'cl':cl,'mode':mode,
                                  'targetKey':'synthetic-selected-target','journal':str(journal)})
        now=datetime.now(timezone.utc)
        cls.base={'schema':'ssis-copy-column-functional/1','approved':True,'cases':cases,'pins':pins,
                  'startedUtc':now.isoformat(),'deadlineUtc':(now+timedelta(minutes=180)).isoformat(),
                  'archive':str(ROOT/ARCHIVE),'framework':str(framework),'packageRoot':str(cls.package),
                  'packageManifestSha256':hashlib.sha256((cls.package/'PACKAGE-MANIFEST.json').read_bytes()).hexdigest().upper(),
                  'providerSha512':record['qualified_assembly_sha512'].upper(),'contractSha256':'0'*64,
                  'rightsScope':'synthetic-api-user-and-procedure-login-v1','rightsApproved':True}

    def invoke(self,record=None,index=0,describe=False,legacy_encoding=False):
        path=self.stage/'test-runset.json';path.write_text(json.dumps(record or self.base),encoding='utf-8')
        # Andere Frameworktests können die geerbte Windows-Konsolencodepage
        # ändern. Der eigene Reader bekommt explizit UTF-8, unabhängig davon.
        script=("[Console]::OutputEncoding=[Text.Encoding]::GetEncoding(850);\n" if legacy_encoding else '')
        script+="""[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$call=@{RunsetPath=$env:TB_DELIVERY_RUNSET;ExpectedRunsetSha256=$env:TB_DELIVERY_SUM;CaseIndex=[int]$env:TB_DELIVERY_INDEX}
if($env:TB_DELIVERY_DESCRIBE -eq '1'){$call.DescribeOnly=$true}else{$call.ValidateOnly=$true}
& $env:TB_DELIVERY_DRIVER @call
"""
        env=dict(os.environ,TB_DELIVERY_DRIVER=str(ROOT/DRIVER),TB_DELIVERY_RUNSET=str(path),
                 TB_DELIVERY_SUM=hashlib.sha256(path.read_bytes()).hexdigest().upper(),
                 TB_DELIVERY_INDEX=str(index),TB_DELIVERY_DESCRIBE='1' if describe else '0')
        encoded=base64.b64encode(script.encode('utf-16le')).decode('ascii')
        return subprocess.run([shutil.which('pwsh'),'-NoProfile','-EncodedCommand',encoded],
                              capture_output=True,text=True,encoding='utf-8',env=env,timeout=30)

    def reject(self,change,code):
        r=copy.deepcopy(self.base);change(r);p=self.invoke(r)
        self.assertNotEqual(p.returncode,0)
        self.assertIn(code,p.stdout+p.stderr)

    def test_actual_archive_and_last_context_admitted_without_sql(self):
        for index in (0,11):
            with self.subTest(index=index):
                p=self.invoke(index=index);self.assertEqual(p.returncode,0,p.stderr)
                self.assertIn('SSIS_COPY_FUNCTIONAL_ADMISSION_PASS; no SQL',p.stdout)

    def test_existing_journal_is_rejected_before_native_entry(self):
        journal=Path(self.base['cases'][0]['journal'])
        journal.mkdir()
        try:
            p=self.invoke();self.assertNotEqual(p.returncode,0)
            self.assertIn('SSIS_COPY_FUNCTIONAL_JOURNAL_COLLISION',p.stdout+p.stderr)
            original=(ROOT/AREA/'Tests/Runtime/Invoke-LabContract.ps1').read_text(encoding='utf-8')
            self.assertLess(original.index("if(Test-Path -LiteralPath $journalRoot)"),
                            original.index('[void](Invoke-LabPreflight'))
        finally:
            journal.rmdir()

    def test_strict_boolean_authority(self):
        self.reject(lambda r:r.update(approved='true'),'SSIS_COPY_FUNCTIONAL_DECLARED_SCOPE')

    def test_missing_and_wrong_context(self):
        self.reject(lambda r:r['cases'].pop(),'SSIS_COPY_FUNCTIONAL_DECLARED_SCOPE')
        self.reject(lambda r:r['cases'][0].update(cl=160),'SSIS_COPY_FUNCTIONAL_ROSTER')

    def test_expired_window_cannot_be_renewed(self):
        self.reject(lambda r:r.update(deadlineUtc=(datetime.now(timezone.utc)+timedelta(minutes=120)).isoformat()),'SSIS_COPY_FUNCTIONAL_ADMISSION_CLOSED')

    def test_changed_file_pin_and_missing_archive_pin(self):
        self.reject(lambda r:r['pins'][0].update(sha256='0'*64),'SSIS_COPY_FUNCTIONAL_INPUT_DRIFT')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=r['archive']]),'SSIS_COPY_FUNCTIONAL_REQUIRED_PIN')

    def test_product_source_pin_cannot_be_omitted(self):
        source=str(ROOT/AREA/'Clr/Translator.cs')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=source]),'SSIS_COPY_FUNCTIONAL_PRODUCT_SOURCE')

    def test_unqualified_dll_cannot_be_substituted(self):
        self.reject(lambda r:r.update(providerSha512='0'*128),'SSIS_COPY_FUNCTIONAL_QUALIFIED_ARTIFACT')

    def test_delivery_record_and_extracted_manifest_must_match_actual_archive(self):
        target=str(ROOT/AREA/'Tests/Qualification/CopyColumn.Delivery.20261115.json')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=target]),'SSIS_COPY_FUNCTIONAL_DELIVERY_PIN')
        self.reject(lambda r:r.update(packageManifestSha256='0'*64),'SSIS_COPY_FUNCTIONAL_DELIVERY_BINDING')

    def test_utf8_description_after_legacy_console_encoding(self):
        p=self.invoke(describe=True,legacy_encoding=True)
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertIn('Änderungen',p.stdout)
        self.assertEqual(p.stdout.count('Invoke-PackageInstallCases.ps1'),1)

    def test_full_shape_preserves_package_lowpriv_oracles_and_shared_deadline(self):
        for index in (0,11):
            with self.subTest(index=index):
                p=self.invoke(index=index,describe=True);self.assertEqual(p.returncode,0,p.stderr)
                self.assertEqual(p.stdout.count('Invoke-PackageInstallCases.ps1'),1)
                self.assertEqual(p.stdout.count('Invoke-CurrentBuildCases.ps1'),1)
                self.assertIn("$package.packageName -cne 'SSIS-Debug-CopyColumnV1-Install-Windows'",p.stdout)
                self.assertIn("$deadline=if($ssisNativeCleanupPhase){960}else{900}",p.stdout)
                self.assertIn("-QualificationPhase 'Full'",p.stdout)
        source=(ROOT/DRIVER).read_text(encoding='utf-8')
        self.assertIn("QualificationPhase='Full'",source)
        self.assertNotIn('-ApiOnly -CompatibilityLevel',source)

    def test_missing_rights_authority_cannot_enter_native(self):
        for value in (False,'true'):
            with self.subTest(value=value):
                self.reject(lambda r:r.update(rightsApproved=value),'SSIS_COPY_FUNCTIONAL_RIGHTS_NOT_APPROVED')
        self.reject(lambda r:r.update(rightsScope='synthetic-api-only'),'SSIS_COPY_FUNCTIONAL_RIGHTS_NOT_APPROVED')

    def test_nested_method_closure_is_required(self):
        target=str(ROOT/AREA/'Tests/Runtime/Invoke-ProcedureBoundaryCases.ps1')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=target]),'SSIS_COPY_FUNCTIONAL_METHOD_CLOSURE')

    def test_historical_methods_unchanged_and_login_audit_preserved(self):
        record=json.loads((ROOT/AREA/'Tests/Qualification/Current.Build.20261104.json').read_bytes())
        rel=AREA+'Tests/Runtime/Invoke-CurrentBuildLab.ps1'
        self.assertEqual(hashlib.sha256((ROOT/rel).read_bytes()).hexdigest(),record['source_sha256'][rel])
        audit=(ROOT/AREA/'Tests/Runtime/Invoke-ProcedureDefinitionLab.ps1').read_text(encoding='utf-8')
        self.assertIn('SSIS_PROCEDURE_AUDIT_OWN_LOGIN_REMAINS',audit)
        self.assertIn('ExpectedJournalSha256',audit)

    def test_expired_exact_window_and_audit_reserve_reject_run(self):
        for remaining in (-1,16):
            with self.subTest(remaining=remaining):
                end=datetime.now(timezone.utc)+timedelta(minutes=remaining)
                self.reject(lambda r:r.update(startedUtc=(end-timedelta(minutes=180)).isoformat(),
                                              deadlineUtc=end.isoformat()),
                            'SSIS_COPY_FUNCTIONAL_ADMISSION_CLOSED')



# Historische C7-Quellenbindung bleibt von der aktuellen Korrektur getrennt.
import sys
sys.path.insert(0,str(ROOT/'Scripts/Release'))
from ssis_historical_scope import copy_column_v1_scope
def setUpModule():
    global _historical_scope, _original_paths
    _historical_scope=copy_column_v1_scope(ROOT)
    snapshot=_historical_scope.__enter__()
    _original_paths={key:value for key,value in list(globals().items())
                     if isinstance(value,Path) and value.is_relative_to(ROOT)}
    original=ROOT
    for key,value in _original_paths.items():
        globals()[key]=snapshot/value.relative_to(original)
def tearDownModule():
    globals().update(_original_paths)
    _historical_scope.__exit__(None,None,None)

if __name__=='__main__':
    unittest.main()
