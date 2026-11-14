"""Admission counterexamples without Lab discovery, SQL or native claims."""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import copy
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest
import sys

ROOT=Path(__file__).resolve().parents[2]
MODULE=ROOT/'Modules/toolbelt.tsql.ssis-debug'
DRIVER=MODULE/'Tests/Runtime/Invoke-CopyColumnLab.ps1'
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_ssis_copy_column as evidence


class CopyColumnEvidence(unittest.TestCase):
    def test_original_and_current_builds_are_explicitly_bound(self):
        record=evidence.validate()
        self.assertNotEqual(record['native_explain_assembly_sha256'],record['qualified_assembly_sha256'])

    def test_missing_audit_context_guard_or_projection_is_rejected(self):
        changes=[lambda r:r['cases'].pop(),lambda r:r['cases'][0].update(cleanup_audit='not executed'),
            lambda r:r['cases'][1].update(deployment_mode='local'),lambda r:r['procedure_guard_cases'].pop(),
            lambda r:r.update(pre_guard_product_sha256={}),lambda r:r.update(reuse_method='same version'),
            lambda r:r['procedure_guard_cases'][0].update(assembly_sha256=r['native_explain_assembly_sha256'])]
        for change in changes:
            record=copy.deepcopy(evidence.validate());change(record)
            with self.assertRaises(ValueError):evidence.validate(record,check_files=False)

    def test_partial_delta_cannot_become_full_module_or_fresh_transport(self):
        for key in ['publication_authorized','full_module_qualification','fresh_zip_matrix']:
            record=copy.deepcopy(evidence.validate());record[key]=True
            with self.assertRaises(ValueError):evidence.validate(record,check_files=False)
        for key in ['fresh_ssms','fresh_authenticated_tls','actual_ssis_runtime_executed','new_principals_or_grants']:
            record=copy.deepcopy(evidence.validate());record['scope'][key]=True
            with self.assertRaises(ValueError):evidence.validate(record,check_files=False)

    def test_changed_current_source_or_reused_product_is_rejected(self):
        record=copy.deepcopy(evidence.validate());record['source_sha256'][evidence.MODULE+'Clr/Translator.cs']='0'*64
        with self.assertRaises(ValueError):evidence.validate(record)
        record=copy.deepcopy(evidence.validate());record['pre_guard_product_sha256'][evidence.MODULE+'Clr/Translator.cs']='0'*64
        with self.assertRaises(ValueError):evidence.validate(record)


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class CopyColumnAdmission(unittest.TestCase):
    def setUp(self):
        (ROOT/'.runtime').mkdir(exist_ok=True)
        self.temp=tempfile.TemporaryDirectory(dir=ROOT/'.runtime',prefix='copy-admission-')
        self.directory=Path(self.temp.name)
        framework=self.directory/'framework.json'
        framework.write_text(json.dumps(dict(result='PASS',scope='offline-framework',profile='Full',cases=29,sqlExecuted=False,providerSha512='A'*128)),encoding='utf-8')
        files=[framework,DRIVER]
        files.extend(MODULE/'Tests/Runtime'/p for p in ['Invoke-LabContract.ps1','Invoke-CopyColumnCases.ps1','Invoke-CurrentCases.ps1','Invoke-ComponentsV2Lab.ps1','Invoke-ComponentsV2Audit.ps1'])
        files.extend(ROOT/'Tests/CI'/p for p in ['run-lab-local.ps1','LabQualifiedContract.ps1'])
        for folder in ['Clr','Exchange/Core']:
            files.extend(p for p in (MODULE/folder).iterdir() if p.is_file() and p.suffix in ['.cs','.csproj'])
        for fmt in [6,8]:
            for kind in ['int','text']:
                fixture=self.directory/f'format-{fmt}/copy-column-{kind}/package.dtsx'
                fixture.parent.mkdir(parents=True);fixture.write_bytes(b'<synthetic/>');files.append(fixture)
        cases=[]
        for version,patch,levels in [('2019','CU32',[150]),('2022','CU26',[150,160]),('2025','CU8',[150,160,170])]:
            for cl in levels:
                for mode in ['local','central']:
                    cases.append(dict(version=version,patch=patch,cl=cl,mode=mode,journal=str(self.directory/f'case-{len(cases)}'),targetKey='synthetic'))
        started=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema='ssis-copy-column-v1',approved=True,startedUtc=started.isoformat(),deadlineUtc=(started+timedelta(minutes=60)).isoformat(),
            fixtureRoot=str(self.directory),framework=str(framework),providerSha512='A'*128,cases=cases,
            pins=[dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in dict.fromkeys(files)])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self,record=None,case=0,digest=None):
        path=self.directory/'runset.json';path.write_text(json.dumps(record or self.record),encoding='utf-8')
        result=subprocess.run(['pwsh','-NoProfile','-File',str(DRIVER),'-RunsetPath',str(path),'-ExpectedRunsetSha256',digest or hashlib.sha256(path.read_bytes()).hexdigest().upper(),'-CaseIndex',str(case),'-ValidateOnly'],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertFalse(any(self.directory.glob('case-*')))
        return result

    def test_exact_roster_and_bound_receipt_before_any_lab_discovery(self):
        for case in [0,11]:
            result=self.admission(case=case)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn('no SQL',result.stdout)

    def test_stale_or_modified_runset_is_rejected(self):
        self.assertNotEqual(self.admission(digest='0'*64).returncode,0)

    def test_authority_target_window_and_pins_cannot_be_widened(self):
        changes=[lambda r:r.update(approved='true'),lambda r:r.update(approved=False),lambda r:r['cases'][0].update(patch='base'),
            lambda r:r['cases'][11].update(cl=160),lambda r:r['cases'].pop(),lambda r:r['pins'].pop(1),
            lambda r:r.update(providerSha512='B'*128),lambda r:r.update(deadlineUtc=(datetime.now(timezone.utc)+timedelta(hours=3)).isoformat()),
            lambda r:r['pins'][0].update(sha256='0'*64),lambda r:r['cases'][0].update(journal=str(ROOT.parent/'outside')),
            lambda r:r.update(caseProfile='procedure-guard-only')]
        for change in changes:
            record=copy.deepcopy(self.record);change(record)
            self.assertNotEqual(self.admission(record).returncode,0)


if __name__=='__main__':unittest.main()
