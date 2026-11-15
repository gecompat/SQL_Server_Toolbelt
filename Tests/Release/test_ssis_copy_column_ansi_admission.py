"""ANSI-Sicherheitsdelta: ausschließlich SQL-freie Admission-Gegenproben."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest
ROOT=Path(__file__).resolve().parents[2]
MODULE=ROOT/'Modules/toolbelt.tsql.ssis-debug'
DRIVER=MODULE/'Tests/Runtime/Invoke-CopyColumnAnsiLab.ps1'
@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class CopyColumnAdmission(unittest.TestCase):
    def setUp(self):
        (ROOT/'.runtime').mkdir(exist_ok=True)
        self.temp=tempfile.TemporaryDirectory(dir=ROOT/'.runtime',prefix='copy-admission-')
        self.directory=Path(self.temp.name)
        framework=self.directory/'framework.json'
        framework.write_text(json.dumps(dict(result='PASS',scope='offline-framework',profile='Full',cases=29,sqlExecuted=False,providerSha512='A'*128)),encoding='utf-8')
        files=[framework,DRIVER]
        files.extend(MODULE/'Tests/Runtime'/p for p in ['Invoke-LabContract.ps1','Invoke-CopyColumnAnsiCases.ps1','Invoke-CurrentCases.ps1','Invoke-ComponentsV2Lab.ps1','Invoke-ComponentsV2Audit.ps1'])
        files.extend(ROOT/'Tests/CI'/p for p in ['run-lab-local.ps1','LabQualifiedContract.ps1'])
        for folder in ['Clr','Exchange/Core']:
            files.extend(p for p in (MODULE/folder).iterdir() if p.is_file() and p.suffix in ['.cs','.csproj'])
        for fmt in [6,8]:
            for kind in ['ansi-1252','ansi-65001']:
                fixture=self.directory/f'format-{fmt}/copy-column-{kind}/package.dtsx'
                fixture.parent.mkdir(parents=True);fixture.write_bytes(b'<synthetic/>');files.append(fixture)
        cases=[]
        for version,patch,levels in [('2019','CU32',[150]),('2025','CU8',[170])]:
            for cl in levels:
                for mode in ['local','central']:
                    cases.append(dict(version=version,patch=patch,cl=cl,mode=mode,journal=str(self.directory/f'case-{len(cases)}'),targetKey='synthetic'))
        started=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema='ssis-copy-column-ansi-security',approved=True,startedUtc=started.isoformat(),deadlineUtc=(started+timedelta(minutes=45)).isoformat(),
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
        for case in [0,3]:
            result=self.admission(case=case)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn('no SQL',result.stdout)

    def test_stale_or_modified_runset_is_rejected(self):
        self.assertNotEqual(self.admission(digest='0'*64).returncode,0)

    def test_authority_target_window_and_pins_cannot_be_widened(self):
        changes=[lambda r:r.update(approved='true'),lambda r:r.update(approved=False),lambda r:r['cases'][0].update(patch='base'),
            lambda r:r['cases'][3].update(cl=160),lambda r:r['cases'].pop(),lambda r:r['pins'].pop(1),
            lambda r:r.update(providerSha512='B'*128),lambda r:r.update(deadlineUtc=(datetime.now(timezone.utc)+timedelta(hours=3)).isoformat()),
            lambda r:r['pins'][0].update(sha256='0'*64),lambda r:r['cases'][0].update(journal=str(ROOT.parent/'outside')),
            lambda r:r.update(caseProfile='procedure-guard-only')]
        for change in changes:
            record=copy.deepcopy(self.record);change(record)
            self.assertNotEqual(self.admission(record).returncode,0)


if __name__=='__main__':unittest.main()
