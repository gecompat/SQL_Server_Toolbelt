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
import zipfile

ROOT=Path(__file__).resolve().parents[2]
MODULE=ROOT/'Modules/toolbelt.tsql.ssis-debug'
DRIVER=MODULE/'Tests/Runtime/Invoke-CopyColumnLab.ps1'
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_ssis_copy_column as evidence
import validate_ssis_current_package as package_guard
from new_ssis_current_package import COPY_COLUMN_PROFILE,COPY_COLUMN_NAME


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


class CopyColumnPackage(unittest.TestCase):
    archive=MODULE/'InstallPackages'/(COPY_COLUMN_NAME+'.zip')

    def test_exact_native_sources_and_corrected_dll_are_packaged(self):
        manifest,release,payload=package_guard.validate(self.archive,profile=COPY_COLUMN_PROFILE)
        record=evidence.validate()
        self.assertEqual(release['sha512'],record['qualified_assembly_sha512'])
        self.assertEqual(manifest['componentProfile'],COPY_COLUMN_PROFILE)
        for name,digest in record['source_sha256'].items():
            self.assertEqual(hashlib.sha256(payload[name]).hexdigest(),digest)

    def test_self_consistent_rehashed_fixture_cannot_replace_native_input(self):
        prefix=COPY_COLUMN_NAME+'/'
        with zipfile.ZipFile(self.archive) as archive:
            payload={name[len(prefix):]:archive.read(name) for name in archive.namelist()}
        selected=evidence.MODULE+'Tests/Fixtures/copy-column-6-int.dtsx'
        original=payload[selected]
        self.assertIn(b'\r\n',original)
        payload[selected]=original.replace(b'\r\n',b'\n')
        # The candidate ZIP remains internally self-consistent. Its source
        # receipt must still reject the unexecuted replacement input bytes.
        manifest=json.loads(payload['PACKAGE-MANIFEST.json'])
        for row in manifest['files']:
            if row['path']==selected:
                row['bytes']=len(payload[selected]);row['sha256']=hashlib.sha256(payload[selected]).hexdigest().upper()
        payload['PACKAGE-MANIFEST.json']=(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode('utf-8')
        payload['SHA256SUMS.txt']=''.join(hashlib.sha256(data).hexdigest().upper()+'  '+name+'\n' for name,data in sorted(payload.items()) if name!='SHA256SUMS.txt').encode('ascii')
        with tempfile.TemporaryDirectory(dir=ROOT/'.runtime',prefix='copy-package-') as directory:
            path=Path(directory)/self.archive.name
            with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as archive:
                for name,data in payload.items():
                    entry=zipfile.ZipInfo(prefix+name);entry.create_system=3;entry.external_attr=0o100644<<16;entry.compress_type=zipfile.ZIP_DEFLATED
                    archive.writestr(entry,data)
            path.with_suffix('.zip.sha256').write_text(hashlib.sha256(path.read_bytes()).hexdigest().upper()+'  '+path.name+'\n',encoding='ascii')
            with self.assertRaisesRegex(ValueError,'Copy Column qualification source payload'):
                package_guard.validate(path,profile=COPY_COLUMN_PROFILE)


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

if __name__=='__main__':unittest.main()
